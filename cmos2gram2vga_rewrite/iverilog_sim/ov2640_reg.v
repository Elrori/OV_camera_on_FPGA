module ov2640_reg //以下为ov7670配置数据
(
        input clk,
        input [7:0] addr,
        output reg [7:0] reg_addr,
        output reg [7:0] value
);

    wire [15:0] rom[199:0];

    always @(posedge clk) begin
        {reg_addr, value} = rom[addr];
    end

	assign rom[0] 	 		= 	{8'h12,8'h04};	//复位，VGA，RGB565 (00:YUV,04:RGB)(8x全局复位)
	assign rom[1] 	 		= 	{8'h40,8'hd0};	//RGB565, 00-FF(d0)（YUV下要改01-FE(80)）
	assign rom[2] 	 		= 	{8'h3a,8'h04};	//TSLB(TSLB[3], COM13[0])00:YUYV, 01:YVYU, 10:UYVY(CbYCrY), 11:VYUY
	assign rom[3] 		 	=	{8'h3d,8'hc8};	//COM13(TSLB[3], COM13[0])00:YUYV, 01:YVYU, 10:UYVY(CbYCrY), 11:VYUY
	assign rom[4] 		 	= 	{8'h1e,8'h31};	//默认01，Bit[5]水平镜像，Bit[4]竖直镜像
	assign rom[5] 		 	= 	{8'h6b,8'h0a};	//旁路PLL倍频；0x0A：关闭内部LDO；0x00：打开LDO
	assign rom[6] 	 		= 	{8'h32,8'hb6};	//8'hREF 控制(80)
	assign rom[7] 	 		= 	{8'h17,8'h13};	//8'hSTART 输出格式-行频开始高8位(11)  
	assign rom[8] 	 		= 	{8'h18,8'h01};	//8'hSTOP  输出格式-行频结束高8位(61)
	assign rom[9] 	 		= 	{8'h19,8'h02};	//VSTART 输出格式-场频开始高8位(03)
	assign rom[10] 	 	= 	{8'h1a,8'h7a};	//VSTOP  输出格式-场频结束高8位(7b)
	assign rom[11] 	 	= 	{8'h03,8'h0a};	//VREF	 帧竖直方向控制(00)
	assign rom[12] 	 	= 	{8'h0c,8'h00};	//DCW使能 禁止(00)
	assign rom[13] 	 	= 	{8'h3e,8'h00};	//PCLK分频00 Normal，10（1分频）,11（2分频）,12（4分频）,13（8分频）14（16分频）
	assign rom[14] 	 	= 	{8'h70,8'h00};	//00:Normal, 80:移位1, 00:彩条, 80:渐变彩条
	assign rom[15] 	 	= 	{8'h71,8'h00};	//00:Normal, 00:移位1, 80:彩条, 80：渐变彩条
	assign rom[16] 	 	= 	{8'h72,8'h11};	//默认 水平，垂直8抽样(11)	        
	assign rom[17] 	 	= 	{8'h73,8'h00};	//DSP缩放时钟分频00 Normal，10（1分频）,11（2分频）,12（4分频）,13（8分频）14（16分频）
	assign rom[18] 	 	= 	{8'ha2,8'h02};	//默认 像素始终延迟	(02)
	assign rom[19] 	 	= 	{8'h11,8'h80};	//内部工作时钟设置，直接使用外部时钟源(80)
//	assign rom[19] 	 	= 	{8'h11,8'h81};	//内部工作时钟设置，直接使用外部时钟源(80)
	assign rom[20] 	 	= 	{8'h7a,8'h20};
	assign rom[21] 	 	= 	{8'h7b,8'h1c};
	assign rom[22] 	 	= 	{8'h7c,8'h28};
	assign rom[23] 	 	= 	{8'h7d,8'h3c};
	assign rom[24] 	 	= 	{8'h7e,8'h55};
	assign rom[25] 	 	= 	{8'h7f,8'h68};
	assign rom[26] 	 	= 	{8'h80,8'h76};
	assign rom[27] 	 	= 	{8'h81,8'h80};
	assign rom[28] 	 	= 	{8'h82,8'h88};
	assign rom[29] 	 	= 	{8'h83,8'h8f};
	assign rom[30] 	 	= 	{8'h84,8'h96};
	assign rom[31] 	 	= 	{8'h85,8'ha3};
	assign rom[32] 	 	= 	{8'h86,8'haf};
	assign rom[33] 	 	= 	{8'h87,8'hc4};
	assign rom[34] 	 	= 	{8'h88,8'hd7};
	assign rom[35] 	 	= 	{8'h89,8'he8};
	assign rom[36] 	 	= 	{8'h13,8'he0};
	assign rom[37] 	 	= 	{8'h00,8'h00};
	assign rom[38] 	 	= 	{8'h10,8'h00};
	assign rom[39] 	 	= 	{8'h0d,8'h00};
	assign rom[40] 	 	= 	{8'h14,8'h28};	//
	assign rom[41] 	 	= 	{8'ha5,8'h05};
	assign rom[42] 	 	= 	{8'hab,8'h07};
	assign rom[43] 	 	= 	{8'h24,8'h75};
	assign rom[44] 	 	= 	{8'h25,8'h63};
	assign rom[45] 	 	= 	{8'h26,8'ha5};
	assign rom[46] 	 	= 	{8'h9f,8'h78};
	assign rom[47] 	 	= 	{8'ha0,8'h68};
	assign rom[48] 	 	= 	{8'ha1,8'h03};
	assign rom[49] 	 	= 	{8'ha6,8'hdf};
	assign rom[50] 	 	= 	{8'ha7,8'hdf};
	assign rom[51] 	 	= 	{8'ha8,8'hf0};
	assign rom[52] 	 	= 	{8'ha9,8'h90};
	assign rom[53] 	 	= 	{8'haa,8'h94};
	assign rom[54] 	 	= 	{8'h13,8'hef};	//
	assign rom[55] 	 	= 	{8'h0e,8'h61};
	assign rom[56] 	 	= 	{8'h0f,8'h4b};
	assign rom[57] 	 	= 	{8'h16,8'h02};

	
	assign rom[58] 	 	= 	{8'h21,8'h02};
	assign rom[59] 	 	= 	{8'h22,8'h91};
	assign rom[60] 	 	= 	{8'h29,8'h07};
	assign rom[61] 	 	= 	{8'h33,8'h0b};
	assign rom[62] 	 	= 	{8'h35,8'h0b};
	assign rom[63] 	 	= 	{8'h37,8'h1d};
	assign rom[64] 	 	= 	{8'h38,8'h71};
	assign rom[65] 	 	= 	{8'h39,8'h2a};
	assign rom[66] 	 	= 	{8'h3c,8'h78};
	assign rom[67] 	 	= 	{8'h4d,8'h40};
	assign rom[68] 	 	= 	{8'h4e,8'h20};
	assign rom[69] 	 	= 	{8'h69,8'h00};
	
	assign rom[70] 	 	= 	{8'h74,8'h19};
	assign rom[71] 	 	= 	{8'h8d,8'h4f};
	assign rom[72] 	 	= 	{8'h8e,8'h00};
	assign rom[73] 	 	= 	{8'h8f,8'h00};
	assign rom[74] 	 	= 	{8'h90,8'h00};
	assign rom[75] 	 	= 	{8'h91,8'h00};
	assign rom[76] 	 	= 	{8'h92,8'h00};
	assign rom[77] 	 	= 	{8'h96,8'h00};
	assign rom[78] 	 	= 	{8'h9a,8'h80};
	assign rom[79] 	 	= 	{8'hb0,8'h84};
	assign rom[80] 	 	= 	{8'hb1,8'h0c};
	assign rom[81] 	 	= 	{8'hb2,8'h0e};
	assign rom[82] 	 	= 	{8'hb3,8'h82};
	assign rom[83] 	 	= 	{8'hb8,8'h0a};

	assign rom[84]	 		=	{8'h43,8'h14};
	assign rom[85]	 		=	{8'h44,8'hf0};
	assign rom[86]	 		=	{8'h45,8'h34};
	assign rom[87]	 		=	{8'h46,8'h58};
	assign rom[88]	 		=	{8'h47,8'h28};
	assign rom[89]	 		=	{8'h48,8'h3a};
	assign rom[90]	 		=	{8'h59,8'h88};
	assign rom[91]	 		=	{8'h5a,8'h88};
	assign rom[92]	 		=	{8'h5b,8'h44};
	assign rom[93]	 		=	{8'h5c,8'h67};
	assign rom[94]	 		=	{8'h5d,8'h49};
	assign rom[95]	 		=	{8'h5e,8'h0e};
	assign rom[96]	 		=	{8'h64,8'h04};
	assign rom[97]	 		=	{8'h65,8'h20};
	assign rom[98]	 		=	{8'h66,8'h05};
	assign rom[99]	 		=	{8'h94,8'h04};
	assign rom[100]	 	=	{8'h95,8'h08};
	assign rom[101]	 	=	{8'h6c,8'h0a};
	assign rom[102]	 	=	{8'h6d,8'h55};
	assign rom[103]	 	=	{8'h6e,8'h11};
	assign rom[104]	 	=	{8'h6f,8'h9f};
	assign rom[105]	 	=	{8'h6a,8'h40};
	assign rom[106]	 	=	{8'h01,8'h40};
	assign rom[107]	 	=	{8'h02,8'h40};
	assign rom[108]	 	=	{8'h13,8'he7};
	assign rom[109]	 	=	{8'h15,8'h00};
	
	assign rom[110]	 	= 	{8'h4f,8'h80};
	assign rom[111]	 	= 	{8'h50,8'h80};
	assign rom[112]	 	= 	{8'h51,8'h00};
	assign rom[113]	 	= 	{8'h52,8'h22};
	assign rom[114]	 	= 	{8'h53,8'h5e};
	assign rom[115]	 	= 	{8'h54,8'h80};
	assign rom[116]	 	= 	{8'h58,8'h9e};
	
	assign rom[117] 	 	=	{8'h41,8'h08};
	assign rom[118] 	 	=	{8'h3f,8'h00};
	assign rom[119] 	 	=	{8'h75,8'h05};
	assign rom[120] 	 	=	{8'h76,8'he1};
	assign rom[121] 	 	=	{8'h4c,8'h00};
	assign rom[122] 	 	=	{8'h77,8'h01};
	
	assign rom[123] 	 	=	{8'h4b,8'h09};
	assign rom[124] 	 	=	{8'hc9,8'hF0};//{8'hc960};
	assign rom[125] 	 	=	{8'h41,8'h38};
	assign rom[126] 	 	=	{8'h56,8'h40};
	
	
	assign rom[127] 	 	=	{8'h34,8'h11};
	assign rom[128] 	 	=	{8'h3b,8'h0a};
	assign rom[129] 	 	=	{8'ha4,8'h89};
	assign rom[130] 	 	=	{8'h96,8'h00};
	assign rom[131] 	 	=	{8'h97,8'h30};
	assign rom[132] 	 	=	{8'h98,8'h20};
	assign rom[133] 	 	=	{8'h99,8'h30};
	assign rom[134] 	 	=	{8'h9a,8'h84};
	assign rom[135] 	 	=	{8'h9b,8'h29};
	assign rom[136] 	 	=	{8'h9c,8'h03};
	assign rom[137] 	 	=	{8'h9d,8'h4c};
	assign rom[138] 	 	=	{8'h9e,8'h3f};
	assign rom[139] 	 	=	{8'h78,8'h04};
	
	
	assign rom[140]	 	=	{8'h79,8'h01};
	assign rom[141]	 	= 	{8'hc8,8'hf0};
	assign rom[142]	 	= 	{8'h79,8'h0f};
	assign rom[143]	 	= 	{8'hc8,8'h00};
	assign rom[144]	 	= 	{8'h79,8'h10};
	assign rom[145]	 	= 	{8'hc8,8'h7e};
	assign rom[146]	 	= 	{8'h79,8'h0a};
	assign rom[147]	 	= 	{8'hc8,8'h80};
	assign rom[148]	 	= 	{8'h79,8'h0b};
	assign rom[149]	 	= 	{8'hc8,8'h01};
	assign rom[150]	 	= 	{8'h79,8'h0c};
	assign rom[151]	 	= 	{8'hc8,8'h0f};
	assign rom[152]	 	= 	{8'h79,8'h0d};
	assign rom[153]	 	= 	{8'hc8,8'h20};
	assign rom[154]	 	= 	{8'h79,8'h09};
	assign rom[155]	 	= 	{8'hc8,8'h80};
	assign rom[156]	 	= 	{8'h79,8'h02};
	assign rom[157]	 	= 	{8'hc8,8'hc0};
	assign rom[158]	 	= 	{8'h79,8'h03};
	assign rom[159]	 	= 	{8'hc8,8'h40};
	assign rom[160]	 	= 	{8'h79,8'h05};
	assign rom[161]	 	= 	{8'hc8,8'h30}; 
	assign rom[162]	 	= 	{8'h79,8'h26};
	
	assign rom[163]	 	= 	{8'h09,8'h03};
//	assign rom[164]	 	= 	{8'h3b,8'h42};
	assign rom[164]	 	= 	{8'h11,8'h01};
	assign rom[165]	 	= 	{8'h6b,8'h4a};
	assign rom[166]	 	= 	{8'h2a,8'h00};
	assign rom[167]	 	= 	{8'h2b,8'h00};
	assign rom[168]	 	= 	{8'h92,8'h2b};	
	assign rom[169]	 	= 	{8'h93,8'h00};
	assign rom[170]	 	= 	{8'h3b,8'h0a};		






endmodule