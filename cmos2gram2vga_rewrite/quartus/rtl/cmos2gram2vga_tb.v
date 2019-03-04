/*******************************************************************************************
*  Name         :cmos2gram2vga_tb.v
*  Description  :
*  Origin       :190124
*  Author       :helrori2011@gmail.com
*  Reference    :
********************************************************************************************/
`timescale 1 ns / 100 ps
`define TT_25m      40
`define TT_50m      20
`define TT_100m     10
module cmos2gram2vga_tb();
wire    sdram_clk,
        sdram_cke,
        sdram_cs_n,
        sdram_ras_n,
        sdram_cas_n,
        sdram_we_n,
        sdram_dqmh,
        sdram_dqml;
wire    [12:0]sdram_addr;
wire    [1:0 ]sdram_bkaddr;
wire    [15:0]sdram_data;
reg     _clk_,_rst_n_,wr_en,wr_clk;
reg     [15:0]wr_data;
wire    [15:0]rgb_out;
wire    hsync,vsync;
initial begin 
    $dumpfile("wave.vcd");              //for iverilog gtkwave.exe
    $dumpvars(0,cmos2gram2vga_tb);           //for iverilog select signal   
    
    _clk_ 		= 	1;
    
    _rst_n_ = 1; #(`TT_25m*5) _rst_n_ = 0; #(`TT_25m*5) _rst_n_ = 1;
    #(`TT_25m*50)

    
    #(`TT_25m*5)
    #(`TT_25m*7000)
    $finish;
end 
initial begin
    wr_clk      =   1;
    wr_data 	= 	16'h5555;
    wr_en = 0;
    #(`TT_25m*25)
    wr_en = 1;
end
always begin #(`TT_50m/2) _clk_ = ~_clk_; end
always begin #(`TT_25m/2) wr_clk = ~wr_clk; end

always@(posedge wr_clk)begin
    if(wr_en)begin
        wr_data <= ~wr_data;
    end
end
cmos2gram2vga cmos2gram2vga_0
(
    //CLOCK
    ._clk_(_clk_)                   ,//external osc 50Mhz
    ._rst_n_(_rst_n_)               ,//reset_n key
    //CMOS
    .wr_clk(wr_clk)                 ,
    .wr_en(wr_en)                   ,
    .wr_data(wr_data)               ,
    //VGA
    .hsync(hsync),
    .vsync(vsync),
    .rgb_out(rgb_out),
    //SDRAM
    .sdram_addr(sdram_addr)         ,//(init,read,write)
    .sdram_bkaddr(sdram_bkaddr)     ,//(init,read,write)
    .sdram_data(sdram_data)         ,//仅支持16bits (read,write)
    .sdram_clk(sdram_clk)           ,
    .sdram_cke(sdram_cke)           ,//always 1
    .sdram_cs_n(sdram_cs_n)         ,//always 0
    .sdram_ras_n(sdram_ras_n)       ,
    .sdram_cas_n(sdram_cas_n)       ,
    .sdram_we_n(sdram_we_n)         ,
    .sdram_dqml(sdram_dqml)         ,//not use,always 0
    .sdram_dqmh(sdram_dqmh)          //not use,always 0
);
mt48lc16m16a2 mt48lc16m16a2_0
(
    .Dq(sdram_data),
    .Addr(sdram_addr),
    .Ba(sdram_bkaddr),
    .Clk(sdram_clk),
    .Cke(sdram_cke),
    .Cs_n(sdram_cs_n),
    .Ras_n(sdram_ras_n),
    .Cas_n(sdram_cas_n),
    .We_n(sdram_we_n),
    .Dqm({sdram_dqmh,sdram_dqml})
);

endmodule
