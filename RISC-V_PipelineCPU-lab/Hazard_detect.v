	module Hazard_detect(
		input wire rd_ex,  //input
		input wire MemRead_ex,
		input wire rs1_id,
		input wire rs2_id,  
		
		output reg load_delay,   //output
		output reg PCWrite,
		output reg IF_ID_Write
		);

		initial begin
			load_delay = 1'bx;
			PCWrite = 1'bx;
			IF_ID_Write = 1'bx;
		end

		always @(*) begin
			if (((rs1_id==rd_ex)||(rs2_id==rd_ex)) && MemRead_ex) begin
				load_delay = 1;
				PCWrite = 0;
				IF_ID_Write = 0;
			end
			else begin
				load_delay = 0;
				PCWrite = 1;
				IF_ID_Write = 1;
			end
		end
		
	endmodule