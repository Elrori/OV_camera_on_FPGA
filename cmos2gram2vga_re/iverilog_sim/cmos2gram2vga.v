/*******************************************************************************************
*  Name         :cmos2gram2vga.v top
*  Description  :cmos to gram to vga display, altera ip used,sdram:8192x512x4x16bits
*                cmos:ov7670 640x480
*  Origin       :190124
*  Author       :helrori2011@gmail.com,uart 引用了CrazyBingo
*  Reference    :
********************************************************************************************/
module cmos2gram2vga
(
    //CLOCK
    input   wire             _clk_,  //external osc 50Mhz
    input   wire             _rst_n_,//reset_n key
    //CMOS
`ifdef _DEBUG_
    input   wire             wr_clk,
    input   wire             wr_en,
    input   wire             wr_data,
`else
    output  wire             cmos_scl,
    output  wire             cmos_sda,
    input   wire    [7  :  0]cmos_data,
    input   wire             cmos_vs,
    input   wire             cmos_href,
    input   wire             cmos_pclk,
	output  wire             cmos_xclk,
	output  wire             cmos_rst, //not use
	output  wire             cmos_pwdn,//not use
`endif	 
	//UART
	input   wire             UART_TX, //PC->FPGA
	//TEST
	output  wire    [7  :  0]LED,	 
    //VGA
	output  wire             VGA_BLANK,
	output  wire             VGA_CLK,
    output  wire             VGA_HS,
    output  wire             VGA_VS,
	output  wire    [7  :  3]VGA_R,
	output  wire    [7  :  2]VGA_G,
	output  wire    [7  :  3]VGA_B,
    //SDRAM	 
    output  wire             S_CLK,
    output  wire    [12 :  0]S_ADDR,
    output  wire    [1  :  0]S_BA,
    output  wire             S_CAS_N,
    output  wire             S_CKE,
    output  wire             S_CS_N,
    inout   wire    [15 :  0]S_DQ,
    output  wire    [1  :  0]S_DQM,
    output  wire             S_RAS_N,
    output  wire             S_WE_N
	 
	 
);

assign VGA_CLK   = clk_25m;assign VGA_BLANK = 1;
wire rst_n,clk_100m,clk_100m_ref,clk_25m,clk_50m,clk_200m,en,cmos2fifo_wr_clk,cmos2fifo_wr_en;
wire init_ov_done,sdram_init_done;
wire [15:0]cmos2fifo_wr_data;
pll pll_0
(
	.areset(~_rst_n_)    ,
	.inclk0(_clk_)       ,
	.c0(clk_100m)        ,
	.c1(clk_100m_ref)    ,
	.c2(clk_25m)         ,
	.c3(clk_50m)         ,
	.c4(clk_200m)         ,
	.locked(rst_n)
);
/********************************************************************************************
*	VGA
********************************************************************************************/
vga_core vga_core_0
(
    .clk(clk_25m),    // 25Mhz clock signal
    .rst_n(rst_n),   // reset_n
    .hs(VGA_HS),    // HSYNC VGA control output
    .vs(VGA_VS),   // VSYNC VGA control output
    .en(en),      // Indicates when RGB generation circuit should enable (x,y valid)
    .x(),        // Current X position being displayed
    .y()        // Current Y position being displayed (top = 0)
);
/********************************************************************************************
*	CMOS,OV7670 use external clock from FPGA
********************************************************************************************/
CMOS_get_data CMOS_get_data_0
(
	.clk(clk_100m),
	.rst_n(rst_n),
	
	.vs_in(cmos_vs),
	.href_in(cmos_href),
	.pclk_in(cmos_pclk),
	.data_in(cmos_data),
	
	.system_init_done(init_ov_done & sdram_init_done),
	.xclk_in(clk_25m),
	
	.led2(LED[0]),
	.led3_pclk_cnt(LED[1]),//not use
	
	.fifo_write_clk(cmos2fifo_wr_clk),
	.fifo_write_en(cmos2fifo_wr_en),
	.data_out(cmos2fifo_wr_data),
	
	.CMOS_VALID(), //not use
	.xclk(cmos_xclk)
);
SCCB_top SCCB_top_0
(
	.init_ov(0),   //上升沿或下降沿触发一次OV2640初始化
	.clk(clk_50m), //50Mhz
	.rst_n(rst_n), //触发一次OV2640初始化
	
	.SCL(cmos_scl),
	.SDA(cmos_sda),
	.OV2640_PWDN(cmos_pwdn),
	.OV2640_RST(cmos_rst),
	
	.init_ov_done(init_ov_done)
);
/********************************************************************************************
*	UART,I use UART instead of CMOS,just for test on board,without ov7670
********************************************************************************************/
wire uart2fifo_en;
wire [15:0]uart2fifo_data;
uart_top uart_top_0     //Baud rate 1228800
(
	.clk(clk_50m),		//global clk 50Mhz
	.clk_100(),
	.rst_n(rst_n),		//global reset
	.rxd_flag(LED[2]),	//receive over
	.rxd_data(),	    //receice data
	.uart_rxd(UART_TX),	//uart rxd
		
	.txd_en(),		//enable transfer
	.txd_data(),	//transfer data
	.txd_flag(),	//transfer over
	.uart_txd(),	//uart txd	
	.clk_bps(),
	.data_out(uart2fifo_data),
	.fifo_write_en(uart2fifo_en),
	.bit_8_buff(),
	.clk_out()

);


/********************************************************************************************
*	GRAM
********************************************************************************************/
wire [15:0]fifo2vga_rgb_data;
assign {VGA_R,VGA_G,VGA_B} = {fifo2vga_rgb_data[7:0],fifo2vga_rgb_data[15:8]};
gram gram_0
(
    //CLOCK
    .clk(clk_100m)            ,//100Mhz
    .clk_ref(clk_100m_ref)    ,//sdram_clk 100Mhz -80 degrees
    .rst_n(rst_n)             ,
    //GDATA CMOS --> FIFO
`ifdef _DEBUG_                 //direct write to fifo in debug mode
    .wr_clk(wr_clk)     ,
    .wr_en(wr_en)       ,
    .wr_data(wr_data)   ,
`else
    .wr_clk(clk_50m),//(cmos2fifo_wr_clk)      ,//I use UART instead of CMOS
    .wr_en(uart2fifo_en),//(cmos2fifo_wr_en)        ,
    .wr_data(uart2fifo_data),//(cmos2fifo_wr_data)    ,
`endif  
    .wr_frame_sync()            ,    
  
    //FIFO --> GDATA VGA 
    .rd_clk(clk_25m)            ,    
    .rd_en(en)                  ,
    .rd_data(fifo2vga_rgb_data) ,
    .rd_frame_sync(VGA_VS)      ,
    
    //SDRAM
	 .sdram_init_done(sdram_init_done),
    .sdram_addr(S_ADDR)         ,//(init,read,write)
    .sdram_bkaddr(S_BA)         ,//(init,read,write)
    .sdram_data(S_DQ)           ,//仅支持16bits (read,write)
    .sdram_clk(S_CLK)           ,
    .sdram_cke(S_CKE)           ,//always 1
    .sdram_cs_n(S_CS_N)         ,//always 0
    .sdram_ras_n(S_RAS_N)       ,
    .sdram_cas_n(S_CAS_N)       ,
    .sdram_we_n(S_WE_N)         ,
    .sdram_dqml(S_DQM[0])       ,//not use,always 0
    .sdram_dqmh(S_DQM[1])        //not use,always 0
);

endmodule
