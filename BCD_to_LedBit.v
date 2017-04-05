module BCD_to_LedBit
(
	input		[3:0]BCD,
	input		Point,			//暂未使用小数点
	output	reg [7:0]LedBit
);
/************************************************************************************************************************
*BCD码译成数码管断码
*************************************************************************************************************************/
always	@(*)
	case(BCD)
		4'd0:LedBit = 8'h3f;
		4'd1:LedBit = 8'h6;
		4'd2:LedBit = 8'h5b;
		4'd3:LedBit = 8'h4f;
		4'd4:LedBit = 8'h66;
		4'd5:LedBit = 8'h6d;
		4'd6:LedBit = 8'h7d;
		4'd7:LedBit = 8'h7;
		4'd8:LedBit = 8'h7f;
		4'd9:LedBit = 8'h6f;
		default:LedBit = 8'h3f;
	endcase
endmodule
