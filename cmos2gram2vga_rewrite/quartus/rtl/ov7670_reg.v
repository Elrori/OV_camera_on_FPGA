/*******************************************************************************************
*  Name         :ov7670_reg.v
*  Description  :注意:readmemh 不是所有工具都可综合!
*  Origin       :190127
*  Author       :helrori2011@gmail.com
*  Reference    :
********************************************************************************************/

module ov7670_reg
#(
   parameter datafile = "./rtl/ov7670_reg.txt"
)
(
   input  wire        clk,
   input  wire  [7:0] addr,
   output reg   [7:0] reg_addr,
   output reg   [7:0] value
);
reg [15:0] rom[170:0];
initial
begin
$readmemh(datafile,rom,0,170);
end

always @(posedge clk) begin
  {reg_addr, value} = rom[addr];
end

endmodule
