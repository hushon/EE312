module Control (
	input wire CLK,
	input wire RSTn,
	input wire [6:0] opcode,
	input wire [2:0] funct3,

	output reg RegDst,
	output reg Jump,
	output reg Branch,
	output reg MemRead,
	output reg MemtoReg,
	output reg [6:0] ALUOp,
	output reg MemWrite,
	output reg ALUSrc1,
	output reg ALUSrc2,
	output reg RegWrite,
	output reg JALorJALR,
	output reg [3:0] BE,
	output reg [2:0] Concat_control,
	output reg PCWrite
	);

	// flags
	reg isLUI, isAUIPC, isRtype, isItype, isLW, isSW, isBranch, isJAL, isJALR;

	always @(*) begin
		if (~RSTn) begin
			isLUI = 0;
			isAUIPC = 0;
			isRtype = 0;
			isItype = 0;
			isLW = 0;
			isSW = 0;
			isBranch = 0;
			isJAL = 0;
			isJALR = 0;
		end
		else begin
			isLUI = (opcode==7'b0110111)?1:0;
			isAUIPC = (opcode==7'b0010111)?1:0;
			isRtype = (opcode==7'b0110011)?1:0;
			isItype = (opcode==7'b0010011)?1:0;
			isLW = (opcode==7'b0000011)?1:0;
			isSW = (opcode==7'b0100011)?1:0;
			isBranch = (opcode==7'b1100011)?1:0;
			isJAL = (opcode==7'b1101111)?1:0;
			isJALR = (opcode==7'b1100111)?1:0;
		end
	end


	/* transition table implementation */
	reg [3:0] currentState = 4'b0000;
	reg isFirstCycle = 1;

	always @(posedge CLK) begin
		if (~RSTn) currentState = 4'b0000;
		else begin
			if (currentState == 4'b0000) begin // state 0
				//$display("currentState: %d", currentState);
				//$display("opcode: %b", opcode);
				if (isJAL) currentState = 4'b1001;
				else currentState = 4'b0001;
				if (isFirstCycle) isFirstCycle=0;
			end
			else if (currentState == 4'b0001) begin // state 1
				//$display("currentState: %d", currentState);
				if (isLW || isSW) currentState = 4'b0010;
				else if (isRtype) currentState = 4'b0110;
				else if (isBranch) currentState = 4'b1000;
				else if (isJALR) currentState = 4'b1010;
				else if (isItype) currentState = 4'b1100;
				else if (isAUIPC || isLUI) currentState = 4'b1101;
			end
			else if (currentState == 4'b0010) begin // state 2
				//$display("currentState: %d", currentState);
				if (isLW) currentState = 4'b0011;
				else if (isSW) currentState = 4'b0101;
			end
			else if (currentState == 4'b0011) begin // state 3
				//$display("currentState: %d", currentState);
				currentState = 4'b0100;
			end
			else if (currentState == 4'b0100) begin // state 4
				//$display("currentState: %d", currentState);
				currentState = 4'b0000;
			end
			else if (currentState == 4'b0101) begin // state 5
				//$display("currentState: %d", currentState);
				currentState = 4'b0000;
			end
			else if (currentState == 4'b0110) begin // state 6
				//$display("currentState: %d", currentState);
				currentState = 4'b0111;
			end
			else if (currentState == 4'b0111) begin // state 7
				//$display("currentState: %d", currentState);
				currentState = 4'b0000;
			end
			else if (currentState == 4'b1000) begin // state 8
				//$display("currentState: %d", currentState);
				currentState = 4'b0000;
			end
			else if (currentState == 4'b1001) begin // state 9
				//$display("currentState: %d", currentState);
				currentState = 4'b1011;
			end
			else if (currentState == 4'b1010) begin // state 10
				//$display("currentState: %d", currentState);
				currentState = 4'b1011;
			end
			else if (currentState == 4'b1011) begin // state 11
				//$display("currentState: %d", currentState);
				currentState = 4'b0000;
			end
			else if (currentState == 4'b1100) begin // state 12
				//$display("currentState: %d", currentState);
				currentState = 4'b0111;
			end
			else if (currentState == 4'b1101) begin // state 13
				//$display("currentState: %d", currentState);
				if (isLUI) currentState = 4'b1110;
				else if (isAUIPC) currentState = 4'b1111;
			end
			else if (currentState == 4'b1110) begin // state 14
				//$display("currentState: %d", currentState);
				currentState = 4'b0000;
			end
			else if (currentState == 4'b1111) begin // state 15
				//$display("currentState: %d", currentState);
				currentState = 4'b0000;
			end
		end
	end
	/* ---------------- */


	/* control signal for each stage */
	always @(*) begin
		if (currentState == 4'b0000) begin // state 0 
			// IF stage (common)
			// initialize control signals
			RegDst=0;
			Jump=0;
			Branch=0;
			MemRead=1;
			MemtoReg=1'bx;
			ALUOp=opcode;
			MemWrite=0;
			ALUSrc1=1'bx;
			ALUSrc2=1'bx;
			RegWrite=0;
			JALorJALR=1'bx;
			BE=4'bxxxx;
			Concat_control=3'b000;
			if (isFirstCycle) begin PCWrite=0; end
			else PCWrite=1;
		end
		else if (currentState == 4'b0001) begin // state 1
			// ID stage (common)
			// do nothing since RegRead is always yes
			PCWrite=0;
		end
		else if (currentState == 4'b0010) begin // state 2
			// LW or SW EX
			ALUSrc1=0;
			ALUSrc2=1;
			// this needs to be fixed soon
			if(isLW) Concat_control=3'b101;
			else if(isSW) Concat_control=3'b011;
			PCWrite=0;
		end
		else if (currentState == 4'b0011) begin // state 3
			// LW MEM
			MemWrite=0;
			MemRead=1;
			case (funct3)
				3'b000, 3'b100: BE=4'b0001; // LB or LBU
				3'b001, 3'b101: BE=4'b0011; // LH or LHU
				3'b010: BE=4'b1111; // LW
				default: ; 
			endcase
			PCWrite=0;
		end
		else if (currentState == 4'b0100) begin // state 4
			// LW WB
			RegDst=1;
			RegWrite=1;
			MemtoReg=1;

			//PCWrite=1;
			PCWrite=0;
		end
		else if (currentState == 4'b0101) begin // state 5
			// SW MEM
			MemWrite=1;
			MemRead=0;

			case (funct3)
				3'b000: BE=4'b0001; // SB
				3'b001: BE=4'b0011; // SH
				3'b010: BE=4'b1111; // SW
				default: ; 
			endcase

			//PCWrite=1;
			PCWrite=0;
		end
		else if (currentState == 4'b0110) begin // state 6
			// Rtype EX
			ALUSrc1=0;
			ALUSrc2=0;
			ALUOp=opcode;
			PCWrite=0;
		end
		else if (currentState == 4'b0111) begin // state 7
			// Rtype or Itype WB
			RegDst=1;
			RegWrite=1;
			MemtoReg=0;

			//PCWrite=1;
			PCWrite=0;
		end
		else if (currentState == 4'b1000) begin // state 8
			// Branch EX
			ALUSrc1=0;
			ALUSrc2=0;
			ALUOp=opcode;
			Branch=1;
			Jump=0;
			Concat_control=3'b100;
			
			//PCWrite=1;
			PCWrite=0;
		end
		else if (currentState == 4'b1001) begin // state 9
			// JAL EX
			ALUSrc1=1;
			ALUSrc2=1;
			ALUOp=opcode;
			Jump=1;
			JALorJALR=0;
			Concat_control=3'b010;
			PCWrite=0;
		end
		else if (currentState == 4'b1010) begin // state 10
			// JALR EX
			ALUSrc1=0;
			ALUSrc2=1;
			ALUOp=opcode;
			Jump=1;
			JALorJALR=1;
			Concat_control=3'b011;
			PCWrite=0;
		end
		else if (currentState == 4'b1011) begin // state 11
			// JAL or JALR WB
			RegDst=1;
			RegWrite=1;
			MemtoReg=0;
			
			//PCWrite=1;
			PCWrite=0;
		end
		else if (currentState == 4'b1100) begin // state 12
			// Itype EX
			ALUSrc1=0;
			ALUSrc2=1;
			ALUOp=opcode;
			// this needs to be fixed soon
			if (funct3 == 3'b001 || funct3 == 3'b101) Concat_control=3'b110; // SLLI or SRLI or SRAI
			else Concat_control=3'b011;
			PCWrite=0;
		end
		else if (currentState == 4'b1101) begin // state 13
			// AUIPC or LUI EX
			ALUSrc1=1;
			ALUSrc2=1;
			ALUOp=opcode;
			Jump=0;
			Concat_control=3'b001;
			PCWrite=0;
		end
		else if (currentState == 4'b1110) begin // state 14
			// LUI WB
			RegDst=1;
			MemtoReg=0;
			RegWrite=1;

			//PCWrite=1;
			PCWrite=0;
		end
		else if (currentState == 4'b1110) begin // state 15
			// AUIPC WB
			RegDst=1;
			MemtoReg=0;
			RegWrite=1;
			
			//PCWrite=1;
			PCWrite=0;
		end
	end
	/* -------------- */

endmodule