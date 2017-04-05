module	vga_superimposed_core
(
	input		clk,
	input		[14:0]address_in,
	input		[15:0]rgbin,
	input		[3:0]BCD_0,
	input		[3:0]BCD_1,
	input		[3:0]BCD_2,
	input		[3:0]BCD_3,

	output	reg [15:0]rgbout
);
/************************************************************************************************************************
*定位显示核心(4位8断码)
*************************************************************************************************************************/
BCD_to_LedBit U1
(
	.BCD(BCD_0),
	.Point(),
	.LedBit(bit_8_buff_0)
);
BCD_to_LedBit U2
(
	.BCD(BCD_1),
	.Point(),
	.LedBit(bit_8_buff_1)
);
BCD_to_LedBit U3
(
	.BCD(BCD_2),
	.Point(),
	.LedBit(bit_8_buff_2)
);
BCD_to_LedBit U4
(
	.BCD(BCD_3),
	.Point(),
	.LedBit(bit_8_buff_3)
);

wire [7:0]bit_8_buff_0,bit_8_buff_1,bit_8_buff_2,bit_8_buff_3;
reg 	[31:0]a_h_0;				//{h0,g0,f0,e0,d0,c0,b0,a0}
always	@(posedge clk)
	if(a_h_0 != 32'd0)
		rgbout <= 16'hffff;
	else
		rgbout <= rgbin;
always @(posedge clk)begin	
	if(address_in ==160*5+10	||address_in ==160*5+11				)
		a_h_0[0] <= bit_8_buff_0[0];
	else
		a_h_0[0] <= 0;
	if(address_in ==160*6+12	||address_in ==160*7+12				)
		a_h_0[1] <= bit_8_buff_0[1];
	else
		a_h_0[1] <= 0;
	if(address_in ==160*9+12	||address_in ==160*10+12			)
		a_h_0[2] <= bit_8_buff_0[2];
	else
		a_h_0[2] <= 0;
	if(address_in ==160*11+10	||address_in ==160*11+11			)
		a_h_0[3] <= bit_8_buff_0[3];
	else
		a_h_0[3] <= 0;
	if(address_in ==160*9+9		||address_in ==160*10+9				)
		a_h_0[4] <= bit_8_buff_0[4];
	else
		a_h_0[4] <= 0;
	if(address_in ==160*6+9		||address_in ==160*7+9				)
		a_h_0[5] <= bit_8_buff_0[5];
	else
		a_h_0[5] <= 0;
	if(address_in ==160*8+10	||address_in ==160*8+11				)
		a_h_0[6] <= bit_8_buff_0[6];
	else
		a_h_0[6] <= 0;
	if(address_in ==160*11+14)
		a_h_0[7] <= bit_8_buff_0[7];
	else
		a_h_0[7] <= 0;
		
	if(address_in ==160*5+10+7	||address_in ==160*5+11+7			)
		a_h_0[8] <= bit_8_buff_1[0];
	else
		a_h_0[8] <= 0;
	if(address_in ==160*6+12+7	||address_in ==160*7+12+7			)
		a_h_0[9] <= bit_8_buff_1[1];
	else
		a_h_0[9] <= 0;
	if(address_in ==160*9+12+7	||address_in ==160*10+12+7			)
		a_h_0[10] <= bit_8_buff_1[2];
	else
		a_h_0[10] <= 0;
	if(address_in ==160*11+10+7	||address_in ==160*11+11+7		)
		a_h_0[11] <= bit_8_buff_1[3];
	else
		a_h_0[11] <= 0;
	if(address_in ==160*9+9+7		||address_in ==160*10+9+7		)
		a_h_0[12] <= bit_8_buff_1[4];
	else
		a_h_0[12] <= 0;
	if(address_in ==160*6+9	+7	||address_in ==160*7+9+7			)
		a_h_0[13] <= bit_8_buff_1[5];
	else
		a_h_0[13] <= 0;
	if(address_in ==160*8+10+7	||address_in ==160*8+11+7			)
		a_h_0[14] <= bit_8_buff_1[6];
	else
		a_h_0[14] <= 0;
	if(address_in ==160*6+14+7 || address_in ==160*10+14+7		)//分号
		a_h_0[15] <= 1;//bit_8_buff_1[7];
	else
		a_h_0[15] <= 0;

		
	if(address_in ==160*5+10+7+7	||address_in ==160*5+11+7+7	)
		a_h_0[16] <= bit_8_buff_2[0];
	else
		a_h_0[16] <= 0;
	if(address_in ==160*6+12+7+7	||address_in ==160*7+12+7+7	)
		a_h_0[17] <= bit_8_buff_2[1];
	else
		a_h_0[17] <= 0;
	if(address_in ==160*9+12+7+7	||address_in ==160*10+12+7+7	)
		a_h_0[18] <= bit_8_buff_2[2];
	else
		a_h_0[18] <= 0;
	if(address_in ==160*11+10+7+7	||address_in ==160*11+11+7+7	)
		a_h_0[19] <= bit_8_buff_2[3];
	else
		a_h_0[19] <= 0;
	if(address_in ==160*9+9+7+7	||address_in ==160*10+9+7+7	)
		a_h_0[20] <= bit_8_buff_2[4];
	else
		a_h_0[20] <= 0;
	if(address_in ==160*6+9	+7+7	||address_in ==160*7+9+7+7		)
		a_h_0[21] <= bit_8_buff_2[5];
	else
		a_h_0[21] <= 0;
	if(address_in ==160*8+10+7+7	||address_in ==160*8+11+7+7	)
		a_h_0[22] <= bit_8_buff_2[6];
	else
		a_h_0[22] <= 0;
	if(address_in ==160*11+14+7+7)
		a_h_0[23] <= bit_8_buff_2[7];
	else
		a_h_0[23] <= 0;

		
	if(address_in ==160*5+10+7+7+7	||address_in ==160*5+11+7+7+7	)
		a_h_0[24] <= bit_8_buff_3[0];
	else
		a_h_0[24] <= 0;
	if(address_in ==160*6+12+7+7+7	||address_in ==160*7+12+7+7+7	)
		a_h_0[25] <= bit_8_buff_3[1];
	else
		a_h_0[25] <= 0;
	if(address_in ==160*9+12+7+7+7	||address_in ==160*10+12+7+7+7)
		a_h_0[26] <= bit_8_buff_3[2];
	else
		a_h_0[26] <= 0;
	if(address_in ==160*11+10+7+7+7	||address_in ==160*11+11+7+7+7)
		a_h_0[27] <= bit_8_buff_3[3];
	else
		a_h_0[27] <= 0;
	if(address_in ==160*9+9+7+7+7		||address_in ==160*10+9+7+7+7	)
		a_h_0[28] <= bit_8_buff_3[4];
	else
		a_h_0[28] <= 0;
	if(address_in ==160*6+9	+7+7+7	||address_in ==160*7+9+7+7+7	)
		a_h_0[29] <= bit_8_buff_3[5];
	else
		a_h_0[29] <= 0;
	if(address_in ==160*8+10+7+7+7	||address_in ==160*8+11+7+7+7	)
		a_h_0[30] <= bit_8_buff_3[6];
	else
		a_h_0[30] <= 0;
	if(address_in ==160*11+14+7+7+7)
		a_h_0[31] <= bit_8_buff_3[7];
	else
		a_h_0[31] <= 0;

end
/************************************************************************************************************************
*************************************************************************************************************************/

endmodule
