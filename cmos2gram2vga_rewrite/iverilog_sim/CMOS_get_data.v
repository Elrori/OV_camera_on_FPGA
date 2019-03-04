module CMOS_get_data
(
	input clk,
	input rst_n,
	
	input	vs_in,
	input	href_in,
	input	pclk_in,
	input	[7:0]data_in/*synthesis noprune*/,
	
	input	system_init_done,
	input	xclk_in,
	
	output	reg led2,
	output	led3_pclk_cnt,
	output	fifo_write_clk,
	output	reg fifo_write_en,
	output	reg [15:0]data_out,
	
	output	reg CMOS_VALID,
	output	xclk
);
assign	xclk = xclk_in;
assign	fifo_write_clk = pclk_in;
/*****************************************************************************************
******************************************************************************************/
//
//reg [31:0]counter;
//always @(posedge href_in or negedge	vs_in)begin
//	if(!vs_in)
//		counter <= 0;
//	else
//		counter <= counter + 1;
//end
////always @(posedge pclk_in)begin
////	if(href_in)
////		counter <= counter + 1;
////	else
////		counter <= 0;
////end
//
//assign led3_pclk_cnt = (counter>610)?1'b1:1'b0;
//
reg buff000,buff111;
always @(posedge clk or negedge rst_n)
	if(!rst_n)begin
		buff000 <= 0;
		buff111 <= 0;
		end
	else
		begin
			buff000 <= vs_in;
			buff111 <= buff000;
			if(buff000&~buff111)//posedge   of init_ov
				led2 <= ~led2;//next clk will set send_buff to 1
//			else
//				led2 <= 1'b0;
		end
		
/*****************************************************************************************
******************************************************************************************/
reg	[3:0] 	Frame_Cont;
reg 		Frame_valid;
always@(posedge pclk_in or negedge rst_n)
begin
	if(!rst_n)
		begin
		Frame_Cont <= 0;
		Frame_valid <= 0;
		end
	else if(system_init_done)					//CMOS I2C初始化完毕
		begin
		if(CMOS_VSYNC_over == 1'b1)		//VS上升沿，1帧写入完毕
			begin
			if(Frame_Cont < 12)
				begin
				Frame_Cont	<=	Frame_Cont + 1'b1;
				Frame_valid <= 1'b0;
				end
			else
				begin
				Frame_Cont	<=	Frame_Cont;
				Frame_valid <= 1'b1;		//数据输出有效
				end
			end
		end
end
//----------------------------------------------
reg		mCMOS_VSYNC;
always@(posedge pclk_in or negedge rst_n)
begin
	if(!rst_n)
		mCMOS_VSYNC <= 1;
	else
		mCMOS_VSYNC <= vs_in;		//场同步：低电平有效
end
wire	CMOS_VSYNC_over = ({mCMOS_VSYNC,vs_in} == 2'b01) ? 1'b1 : 1'b0;	//VSYNC上升沿结束

/*****************************************************************************************
******************************************************************************************/
//Change the sensor data from 8 bits to 16 bits.
reg			byte_state;		//byte state count
reg [7:0]  	Pre_CMOS_iDATA;
always@(posedge pclk_in or negedge rst_n)
begin
	if(!rst_n)
		begin
		byte_state <= 0;
		Pre_CMOS_iDATA <= 8'd0;
		data_out <= 16'd0;
		end
	else
		begin
		if(~vs_in & href_in)			//行场有效，{first_byte, second_byte} 
			begin
			byte_state <= byte_state + 1'b1;	//（RGB565 = {first_byte, second_byte}）
			case(byte_state)
			1'b0 :	Pre_CMOS_iDATA[7:0] <= data_in;
			1'b1 : 	data_out[15:0] <= {Pre_CMOS_iDATA[7:0], data_in[7:0]};
			endcase
			end
		else
			begin
			byte_state <= 0;
			Pre_CMOS_iDATA <= 8'd0;
			data_out <= data_out;
			end
		end
end
//-----------------------------------------------------
//CMOS_DATA数据同步输出使能时钟
always@(posedge pclk_in or negedge rst_n)
begin
	if(!rst_n)
		fifo_write_en <= 0;
	else if(Frame_valid == 1'b1 && byte_state)//(X_Cont >= 12'd1 && X_Cont <= H_DISP))
		fifo_write_en <= ~fifo_write_en;
	else
		fifo_write_en <= 0;
end

//----------------------------------------------------
//数据输出有效CMOS_VALID
always@(posedge pclk_in or negedge rst_n)
begin
	if(!rst_n)
		CMOS_VALID <= 0;
	else if(Frame_valid == 1'b1)
		CMOS_VALID <= ~vs_in;
	else
		CMOS_VALID <= 0;
end
//----------------------------------------------------

endmodule	