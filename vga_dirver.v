module vga_dirver
(
	sdram_ReadAddress_reset,
	vs_active,
	reset,
	clk,
//	clk_high,
//	hcnt,
//	vcnt,
	hs,
	vs,
	rgbin,
	rgbout,
	data_put_ready,
//	ahead_data_put_ready,
	x_position,
	y_position,
	address_out
);
/************************************************************************************************************************
*VGA驱动。address_out可以输出4*4像素时钟为单位的坐标值计数(从1开始)
*by_helrori_170329
*************************************************************************************************************************/
	input clk;
//	input clk_high;
	input reset;
	input [15:0]rgbin;		//RGB565:{R,G,B} such as 00000 111111 00000
//	output [10:0] hcnt;		//								 M	  L M    L M   L
//	output [10:0] vcnt;		//									R		G		 B
	output reg sdram_ReadAddress_reset;
	output hs,vs;
	output [15:0]rgbout;
	output [14:0]address_out;
	
	reg [10:0] hcnt;
	reg [10:0] vcnt;
	reg hs,vs;
	//reg [15:0]rgbout;
	
	`include "vga_dirver_define.v"//CrazyBingo 源码
/*******************************************************************************************
*hcnt counter
*******************************************************************************************/
	always @(posedge clk,negedge reset)
		if(!reset)
		begin
			hcnt 	<= 11'd0;
		end
		else if(hcnt < `H_TOTAL-1)	
			hcnt <= hcnt+1'b1;
		else								
			hcnt <= 11'b0;
/*******************************************************************************************
*vcnt counter
*******************************************************************************************/

	always @(posedge clk,negedge reset)
		if(!reset)
			begin
				vcnt 	<= 11'b0;
			end
		else if(hcnt == `H_TOTAL-1)
			begin
				if(vcnt < `V_TOTAL-1)		vcnt <= vcnt + 1'b1;
				else							vcnt <= 11'b0;
			end
/*******************************************************************************************
*hs signal
*******************************************************************************************/
	always @(posedge clk)
		if(hcnt == 11'b0 )
			hs <= 1'b0;
		else if(hcnt == `H_SYNC)
			hs <= 1'b1;
/*******************************************************************************************
*vs signal
*******************************************************************************************/
	always @(posedge clk)
		if(vcnt == 11'b0 )
			vs <= 1'b0;
		else if(vcnt == `V_SYNC)
			vs <= 1'b1;
/*******************************************************************************************
*put the data on rgbout when possible
*******************************************************************************************/
	reg 	data_put_ready;
	reg	vs_active;
	output data_put_ready;
	output vs_active;
	output [10:0]x_position,y_position;
//	reg [10:0]x_position;
	always @(posedge clk)
		if((hcnt > `H_SYNC+`H_BACK-1'b1)&&(hcnt <`H_SYNC+`H_BACK+`H_DISP)&&(vcnt > `V_SYNC+`V_BACK-1'b1)&&(vcnt <`V_SYNC+`V_BACK+`V_DISP))
			data_put_ready <= 1'b1;
		else
			data_put_ready <= 1'b0;
	always @(posedge clk)
		if((vcnt > `V_SYNC+`V_BACK-1'b1)&&(vcnt <`V_SYNC+`V_BACK+`V_DISP))
			vs_active <= 1'b1;
		else
			vs_active <= 1'b0;
			
	assign rgbout = data_put_ready?rgbin:16'b0;
	
/*	always @(posedge clk)
		if((hcnt > `H_SYNC+`H_BACK-2'd2)&&(hcnt <`H_SYNC+`H_BACK+`H_DISP-1'b1)&&(vcnt > `V_SYNC+`V_BACK-2'd2)&&(vcnt <`V_SYNC+`V_BACK+`V_DISP-1'b1))
			ahead_data_put_ready <= 1'b1;
		else
			ahead_data_put_ready <= 1'b0;
*/
	
	wire [10:0]x,y;
/*******************************************************************************************
*以一个像素时钟为单位的坐标值
*******************************************************************************************/
	assign x = 	data_put_ready?(hcnt - `H_SYNC - `H_BACK):1'b0;
	assign y = 	data_put_ready?(vcnt - `V_SYNC - `V_BACK + 1'b1):1'b0;
//	assign address_out = data_put_ready?((y_position - 1'b1) * 640 + x_position):13'd0;


	/**********以4*4像素时钟为单位的坐标值**********/
/*
	always @(posedge clk_high)//使用clk_high用于减轻x_position毛刺
		begin
			x_position <= ((x - 1'b1)/4 + 1'b1);
		end
*/
	assign x_position = ((x - 1'b1)/4 + 1'b1);//data_put_ready?((x - 1'b1)/4 + 1'b1):11'b0;
	assign y_position = ((y - 1'b1)/4 + 1'b1);//data_put_ready?((y - 1'b1)/4 + 1'b1):11'b0;
	
	assign address_out = data_put_ready?((y_position - 1'b1) * 160 + x_position):13'd0;//首个像素地址为1!!!当地址为0时表示rgb不输出
/*******************************************************************************************
*sdram_ReadAddress_reset
*******************************************************************************************/
	reg vs_buff0;
	reg vs_buff1;
	always @(posedge clk or negedge reset)
	begin
		if(!reset)
			begin
//				vs <= 1'b0;//
				vs_buff0 <= 1'b0;
				vs_buff1 <= 1'b0;
			end
		else
			begin
				vs_buff0 <= vs;
				vs_buff1 <= vs_buff0;
				if(vs_buff1&~vs_buff0)//当vs下降沿进入,使sdram_ReadAddress_reset发生一次冲击
					sdram_ReadAddress_reset <= 1'b1;
				else
					sdram_ReadAddress_reset <= 1'b0;
			end
	end
endmodule 