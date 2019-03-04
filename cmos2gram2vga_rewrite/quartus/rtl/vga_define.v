/**********************************************************************
*  Name:vga_define.v
*  Origin:190119
*  Author:
*  http://tinyvga.com/vga-timing
**********************************************************************/

`ifndef _VGA_DEFINE_
`define _VGA_DEFINE_

`define VIDEO_640_480
// 60Hz standard

//480x272 9Mhz
`ifdef  VIDEO_480_272
`define H_ACTIVE 16'd480    //horizontal active time (pixels)   
`define H_FP     16'd2      //horizontal front porch (pixels)      
`define H_SYNC   16'd41     //horizontal sync time(pixels)    
`define H_BP     16'd2      //horizontal back porch (pixels)      
`define V_ACTIVE 16'd272    //vertical active Time (lines)  
`define V_FP     16'd2      //vertical front porch (lines)    
`define V_SYNC   16'd10     //vertical sync time (lines)   
`define V_BP     16'd2      //vertical back porch (lines)    
`define HS_POL   1'b0       //horizontal sync polarity, 1 : POSITIVE,0 : NEGATIVE
`define VS_POL   1'b0       //vertical sync polarity, 1 : POSITIVE,0 : NEGATIVE     
`endif
//640x480 25.175Mhz.√
`ifdef  VIDEO_640_480
`define H_ACTIVE 16'd640      
`define H_FP     16'd16           
`define H_SYNC   16'd96         
`define H_BP     16'd48           
`define V_ACTIVE 16'd480      
`define V_FP     16'd10         
`define V_SYNC   16'd2         
`define V_BP     16'd33         
`define HS_POL   1'b0     
`define VS_POL   1'b0     
`endif
//800x480 33Mhz.√
`ifdef  VIDEO_800_480
`define H_ACTIVE 16'd800      
`define H_FP     16'd40           
`define H_SYNC   16'd128        
`define H_BP     16'd88           
`define V_ACTIVE 16'd480      
`define V_FP     16'd1          
`define V_SYNC   16'd3         
`define V_BP     16'd21         
`define HS_POL   1'b0     
`define VS_POL   1'b0     
`endif
//800x600 40Mhz.√
`ifdef  VIDEO_800_600
`define H_ACTIVE 16'd800      
`define H_FP     16'd40           
`define H_SYNC   16'd128        
`define H_BP     16'd88           
`define V_ACTIVE 16'd600      
`define V_FP     16'd1          
`define V_SYNC   16'd4         
`define V_BP     16'd23         
`define HS_POL   1'b1     
`define VS_POL   1'b1     
`endif
//1024x768 65Mhz.√
`ifdef  VIDEO_1024_768
`define H_ACTIVE 16'd1024     
`define H_FP     16'd24           
`define H_SYNC   16'd136        
`define H_BP     16'd160          
`define V_ACTIVE 16'd768      
`define V_FP     16'd3           
`define V_SYNC   16'd6         
`define V_BP     16'd29          
`define HS_POL   1'b0     
`define VS_POL   1'b0     
`endif
//1440x900 105Mhz (106.47 MHz).√
`ifdef  VIDEO_1440_900
`define H_ACTIVE 16'd1440   
`define H_FP     16'd80           
`define H_SYNC   16'd152        
`define H_BP     16'd252         
`define V_ACTIVE 16'd900      
`define V_FP     16'd1           
`define V_SYNC   16'd3         
`define V_BP     16'd28          
`define HS_POL   1'b0     
`define VS_POL   1'b1     
`endif
//1280x1024 105Mhz (108.0Mhz).√
`ifdef  VIDEO_1280_1024
`define H_ACTIVE 16'd1280     
`define H_FP     16'd48          
`define H_SYNC   16'd112        
`define H_BP     16'd248         
`define V_ACTIVE 16'd1024      
`define V_FP     16'd1           
`define V_SYNC   16'd3         
`define V_BP     16'd38          
`define HS_POL   1'b1     
`define VS_POL   1'b1     
`endif
//1920x1080 148.5Mhz
`ifdef  VIDEO_1920_1080
`define H_ACTIVE 16'd1920     
`define H_FP     16'd88     
`define H_SYNC   16'd44     
`define H_BP     16'd148      
`define V_ACTIVE 16'd1080     
`define V_FP     16'd4     
`define V_SYNC   16'd5     
`define V_BP     16'd36     
`define HS_POL   1'b1     
`define VS_POL   1'b1     
`endif

`endif