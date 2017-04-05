`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    vga_driver 
//////////////////////////////////////////////////////////////////////////////////
module vga_driver2(
	 input clk_vga,                 //vga的时钟输入
	 input vga_rst,                 
	 input key1,                    //按键1控制LCD显示模式
 
//	 output [4:0] vga_r,
//    output [5:0] vga_g,
//    output [4:0] vga_b,
	 output	[15:0]rgbout,
    output reg vga_hsync,
    output reg vga_vsync,
    output vga_de,

	 input [15:0] vga_data,        //SDR中的图像数据	 
	 output reg sdr_addr_set,       //Sdr读地址复位信号
	 output vga_framesync,
	 output vga_rden
);

//-----------------------------------------------------------//
// 水平扫描参数的设定1024*768 60Hz VGA
//-----------------------------------------------------------//
parameter H_ACTIVE = 16'd640;   //行数据显示宽度
parameter H_FP = 16'd16;        //行最后黑色区
parameter H_SYNC = 16'd96;      //行同步信号麦冲宽度
parameter H_BP = 16'd48;        //行开始黑色区
parameter V_ACTIVE = 16'd480;   //列数据显示宽度
parameter V_FP 	= 16'd10;     //列最后黑色区
parameter V_SYNC  = 16'd2;      //列同步信号脉冲宽度
parameter V_BP	= 16'd33;        //列开始黑色区
parameter H_TOTAL = 800 ;//行周期数1344
parameter V_TOTAL = 525;//列周期数806  

wire [4:0] vga_r;
wire [5:0] vga_g;
wire [4:0] vga_b;
assign	rgbout = {vga_r,vga_g,vga_b};
reg [3:0] vga_dis_mode;

reg [4:0] vga_r_reg;
reg [5:0] vga_g_reg;
reg [4:0] vga_b_reg;

reg [15:0] hcount;            // 行输出counter
reg [15:0] vcount;            // 列输出counter

reg h_active, v_active/*synthesis noprune*/;


reg [5:0] grid_data_1;        //格子1图像数据
reg [5:0] grid_data_2;        //格子2图像数据
reg [5:0] h_htl_data;         //水平渐变图像数据
reg [5:0] v_htl_data;         //垂直渐变图像数据

reg vga_vsync_buf1;
reg vga_vsync_buf2; 

reg [15:0] key1_counter;                 //按键检测寄存器


//LCD输出信号赋值

assign vga_r=vga_de ? vga_r_reg : 5'd0;
assign vga_g=vga_de ? vga_g_reg : 6'd0;
assign vga_b=vga_de ? vga_b_reg : 5'd0;

assign vga_rden=vga_de;
  
assign vga_framesync=v_active;


	
 //行计数
 always @(posedge clk_vga) 
 begin
 if (!vga_rst) 
	       hcount<=0; 
 else 
     if (hcount==H_TOTAL-1)                 //一行928点
            hcount<=0;
     else
            hcount<=hcount+1'b1;
end

 //列计数
 always @(posedge clk_vga) 
 begin
 if (!vga_rst) 
	       vcount<=0; 
 else 
     if (hcount==H_TOTAL-1)                
			begin
				if(vcount == V_TOTAL - 1)
					vcount <= 0;
				else
					vcount <= vcount + 1'b1;
			end
 end


 //产生同步信号
always @ (posedge	clk_vga)
begin
 	vga_hsync <= (hcount < H_TOTAL - 1) && (hcount >= H_SYNC);
 	h_active	<= (hcount < H_TOTAL - H_FP) && (hcount >= H_SYNC + H_BP); 
	          
 	vga_vsync <= (vcount < V_TOTAL -1) && (vcount >= V_SYNC);
 	v_active	<= (vcount < V_TOTAL - V_FP ) && (vcount >= V_SYNC + V_BP); 

end
assign vga_de = h_active && v_active;

 
  //LCD图像产生程序 
 always @(negedge clk_vga)   
   begin
     if ((hcount[3]==1'b1) ^ (vcount[3]==1'b1))         //产生格子1图像
			    grid_data_1<= 6'b000000;
	  else
				 grid_data_1<=6'b111111; 
				 
	  if ((hcount[5]==1'b1) ^ (vcount[5]==1'b1))         //产生格子1图像 
			    grid_data_2<=6'b000000;
	  else
				 grid_data_2<=6'b111111; 
				 
     h_htl_data<=hcount[5:0];                             //行渐变数据
	  v_htl_data<=vcount[5:0];                             //列渐变数据
   
	end
  

 //LCD数据信号选择 
 always @(negedge clk_vga)  
   if (!vga_rst) begin 
	    vga_r_reg<=0; 
	    vga_g_reg<=0;
	    vga_b_reg<=0;		 
	end
   else
     case(vga_dis_mode)
         4'b0000:begin
			        vga_r_reg<=vga_data[15:11];          //LCD显示sdr数据
                 vga_g_reg<=vga_data[10:5];
                 vga_b_reg<=vga_data[4:0];
					  end
			4'b0001:begin
			        vga_r_reg<=5'b11111;             //LCD显示全白
                 vga_g_reg<=6'b111111;
                 vga_b_reg<=5'b11111;
					  end
			4'b0010:begin
			        vga_r_reg<=5'b11111;             //LCD显示全红
                 vga_g_reg<=0;
                 vga_b_reg<=0;  
                 end			  
	      4'b0011:begin
			        vga_r_reg<=0;                     //LCD显示全绿
                 vga_g_reg<=6'b111111;
                 vga_b_reg<=0; 
                 end					  
         4'b0100:begin     
			        vga_r_reg<=0;                     //LCD显示全蓝
                 vga_g_reg<=0;
                 vga_b_reg<=5'b11111;
					  end
         4'b0101:begin     
			        vga_r_reg<=grid_data_1;           // LCD显示方格1
                 vga_g_reg<=grid_data_1;
                 vga_b_reg<=grid_data_1;
                 end					  
         4'b0110:begin     
			        vga_r_reg<=grid_data_2;           // LCD显示方格2
                 vga_g_reg<=grid_data_2;
                 vga_b_reg<=grid_data_2;
					  end
		   4'b0111:begin     
			        vga_r_reg<=h_htl_data;           //LCD显示水平渐变色
                 vga_g_reg<={h_htl_data[4:0],1'b0};
                 vga_b_reg<=h_htl_data;
					  end
		   4'b1000:begin     
			        vga_r_reg<=v_htl_data;           //LCD显示垂直渐变色
                 vga_g_reg<={v_htl_data[4:0],1'b0};
                 vga_b_reg<=v_htl_data;
					  end
		   4'b1001:begin     
			        vga_r_reg<=h_htl_data;           //LCD显示红水平渐变色
                 vga_g_reg<=0;
                 vga_b_reg<=0;
					  end
		   4'b1010:begin     
			        vga_r_reg<=0;                   //LCD显示绿水平渐变色
                 vga_g_reg<=h_htl_data;
                 vga_b_reg<=0;
					  end
		   4'b1011:begin     
			        vga_r_reg<=0;                   //LCD显示蓝水平渐变色
                 vga_g_reg<=0;
                 vga_b_reg<=h_htl_data;
					  end
		   4'b1100:begin     
			        vga_r_reg<=vga_data[15:11];          //LCD显示sdr数据
                 vga_g_reg<=vga_data[10:5];
                 vga_b_reg<=vga_data[4:0];
					  end
		   default:begin
			        vga_r_reg<=5'b11111;             //LCD显示全白
                 vga_g_reg<=6'b111111;
                 vga_b_reg<=5'b11111;
					  end					  
         endcase
			
 //按钮处理程序	
  always @(posedge clk_vga)
   if (!vga_rst) begin
	    key1_counter<=0;
	    vga_dis_mode<=4'b1100;
	end
	else begin
	    if (key1==1'b1)                                      //如果按钮没有按下，寄存器为0
	       key1_counter<=0;
	    else if ((key1==1'b0) & (key1_counter<=16'hc350))    //如果按钮按下并按下时间少于1ms,计数      
          key1_counter<=key1_counter+1'b1;
  	  
       if (key1_counter==16'hc349) begin                    //一次按钮有效，改变显示模式   
		      if(vga_dis_mode==4'b1100)
			      vga_dis_mode<=4'b0000;
			   else
			      vga_dis_mode<=vga_dis_mode+1'b1; 
       end				 
     end 

 //ddr地址复位处理程序	
  always @(posedge clk_vga)
   if (!vga_rst) begin
	    vga_vsync_buf1<=1'b0;
		 vga_vsync_buf2<=1'b0;
	    sdr_addr_set<=1'b0;
     end
   else begin
		 vga_vsync_buf1<=vga_vsync;
		 vga_vsync_buf2<=vga_vsync_buf1;
       if (vga_vsync_buf2&~vga_vsync_buf1)      //检测vsync的下降沿,sdr的地址复位
		   sdr_addr_set<=1'b1;
		 else
		   sdr_addr_set<=1'b0;		   
	end


			
endmodule
