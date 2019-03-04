/*-------------------------------------------------------------------------
This confidential and proprietary software may be only used as authorized
by a licensing agreement from CrazyBingo.
(C) COPYRIGHT 2012 CrazyBingo. ALL RIGHTS RESERVED
Filename			:		uart_top.v
Author				:		CrazyBingo
Data				:		2011-11-27
Version				:		1.0
Description			:		uart control top module.
Modification History	:
Data			By			Version			Change Description
===========================================================================
11/11/27		CrazyBingo	1.0				Original
12/03/12		CrazyBingo	1.0				Modification
--------------------------------------------------------------------------*/

`timescale 1 ns / 1 ns
module uart_top
(
	input				clk,		//global clk 50Mhz
	input				clk_100,
	input				rst_n,		//global reset
	output			rxd_flag,	//receive over
	output	[7:0]	rxd_data,	//receice data
	input				uart_rxd,	//uart rxd
		
	input				txd_en,		//enable transfer
	input		[7:0]	txd_data,	//transfer data
	output			txd_flag,	//transfer over
	output			uart_txd,	//uart txd	
	output			clk_bps,
//	output	reg 	[19:0]counter,
	output	reg	[15:0]data_out,
	output	reg 	fifo_write_en,
	output	reg	[7:0]bit_8_buff,
	output	clk_out

);
//----------------------
//wire			clk_bps;
wire			clk_smp;
assign clk_out = clk;
clk_generator	U_clk_generator
(
	.clk		(clk),
	.rst_n		(rst_n),
	.clk_bps	(clk_bps),
	.clk_smp	(clk_smp)
);

uart_receiver U_uart_receiver
(
	.clk		(clk),
	.clk_smp	(clk_smp),
	.rst_n		(rst_n),	

	.rxd_data	(rxd_data),	
	.rxd_flag	(rxd_flag),
	.rxd		(uart_rxd)
);

uart_transfer	U_uart_transfer
(
	.clk		(clk),
	.clk_bps	(clk_bps),
	.rst_n		(rst_n),
	
	.txd_en		(txd_en),
	.txd_data	(txd_data),
	.txd_flag	(txd_flag),
	.txd		(uart_txd)

);
reg bit_2_counter;
always @(posedge rxd_flag)
begin
	bit_2_counter <= ~bit_2_counter;
end
always @(posedge clk)
begin
	if(rxd_flag)
	begin
		if(bit_2_counter)
			bit_8_buff <= rxd_data;
		else
			data_out <= {rxd_data,bit_8_buff};
	end
end

reg buff0,buff1;
always @(posedge clk)
begin
	buff0 <= bit_2_counter;
	buff1 <= buff0;
	if(buff1&~buff0)
		fifo_write_en <= 1'b1;
	else	
		fifo_write_en <= 1'b0;
end

endmodule
