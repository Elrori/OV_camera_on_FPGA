module	vga_superimposed
(
	input		clk,
	input		rst_n,
	input		[14:0]address_in,
	input		[15:0]rgbin,
	
	output 	[15:0]rgbout
);
/************************************************************************************************************************
*VGA字符叠加时间计数 顶层。4位8段码。
*by_helrori_170329
*************************************************************************************************************************/

/************************************************************************************************************************
*定位显示核心 4位8段码。
*************************************************************************************************************************/
vga_superimposed_core vga_superimposed_core
(
	.clk(clk),
	.address_in(address_in),
	.rgbin(rgbin),
	.rgbout(rgbout),
	.BCD_0(counter_3),
	.BCD_1(counter_2),
	.BCD_2(counter_1),
	.BCD_3(counter_0)
);
/************************************************************************************************************************
*BCD码时间计数器 效果 12:12 ...
*************************************************************************************************************************/

reg [3:0]counter_0,counter_1,counter_2,counter_3;
reg [31:0]counter_big;

always @(posedge clk or negedge rst_n)
	if(!rst_n)			
			counter_big <= 32'd0;
	else if(counter_big >= 32'd25_000_000)
			counter_big <= 32'd0;
	else
			counter_big <= counter_big + 32'd1;

always	@(posedge clk or negedge	rst_n)
	if(!rst_n)
		begin
			counter_0		<= 4'd0;
			counter_1		<= 4'd0;
			counter_2		<= 4'd0;
			counter_3		<= 4'd0;
		end
	else	if(counter_big == 32'd25_000_000 - 32'd1)
		begin
			if(counter_0 == 4'd9)begin
				counter_0 <= 4'd0;
				counter_1 <= counter_1 + 4'd1;
				end
			else
				counter_0 <= counter_0 + 4'd1;
			if(counter_1 == 4'd5 && counter_0 ==4'd9)begin
				counter_1 <= 4'd0;
				if(counter_2 != 4'd9)
					counter_2 <= counter_2 + 4'd1;
				end
			if(counter_2 == 4'd9 && counter_1 == 4'd5 && counter_0 ==4'd9)begin
				counter_2 <= 4'd0;
				if(counter_3 != 4'd9)
					counter_3 <= counter_3 + 4'd1;
				end
			if(counter_3 == 4'd9 && counter_2 == 4'd9 && counter_1 == 4'd5 && counter_0 ==4'd9)begin
				counter_3 <= 4'd0;
				end
		end
	

endmodule
