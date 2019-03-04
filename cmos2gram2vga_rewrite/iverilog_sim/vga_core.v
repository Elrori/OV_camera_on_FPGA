
/************************************************************************************
*   Name         :vga_core.v
*   Description  :
*   Origin       :190118
*   Author       :helrori
*   Reference    :
************************************************************************************/
`include "vga_define.v" 
module vga_core
(
  input  wire        clk,    // pixel clock signal
  input  wire        rst_n,  // reset_n
  output wire        hs,     // HSYNC
  output wire        vs,     // VSYNC
  output wire        en,     // RGB generation circuit enable
  output wire [11:0] x,      // Current X position being displayed,when en == 1
  output wire [11:0] y       // Current Y position being displayed,when en == 1
);

`define H_TOTAL   (`H_ACTIVE + `H_FP + `H_SYNC + `H_BP)//horizontal total time (pixels)
`define V_TOTAL   (`V_ACTIVE + `V_FP + `V_SYNC + `V_BP)//vertical total time (lines)
reg[11:0] h_cnt;                 //horizontal counter
reg[11:0] v_cnt;                 //vertical counter
wire line_pulse = (h_cnt == `H_TOTAL - 1);
/*
*   fixed counter
*/
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        h_cnt <= 'd0;
        v_cnt <= 'd0;
    end else begin 
        h_cnt <= (line_pulse)?('d0):(h_cnt + 1'd1);
        v_cnt <= (line_pulse)?(
                 (v_cnt == `V_TOTAL - 1)?('d0):
                 (v_cnt + 1'd1         )
                 ):
                 (v_cnt     );
    end
end
/*
*   产生 en,hs,vs
*/
wire hs_en      = (h_cnt < `H_ACTIVE);
wire vs_en      = (v_cnt < `V_ACTIVE);
assign en = (vs_en & hs_en);
assign x  = h_cnt;//从零开始
assign y  = v_cnt;//从零开始

reg    hs_b,vs_b;
assign hs = hs_b;
assign vs = vs_b;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        hs_b <= ~(`HS_POL);
        vs_b <= ~(`VS_POL);
    end else begin 
        hs_b <= (h_cnt == `H_ACTIVE + `H_FP - 1          )?(`HS_POL):
                (h_cnt == `H_ACTIVE + `H_FP + `H_SYNC - 1)?(~hs_b  ):
                (hs_b);
        vs_b <= (line_pulse)?(
                (v_cnt == `V_ACTIVE + `V_FP - 1          )?(`VS_POL):
                (v_cnt == `V_ACTIVE + `V_FP + `V_SYNC - 1)?(~vs_b  ):
                (vs_b)
                ):
                (vs_b);
    end 
end

endmodule
