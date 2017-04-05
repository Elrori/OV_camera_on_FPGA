module CMOS_get_data
(
	input clk,
	input rst_n,
	
	input	vs_in,
	input	href_in,
	input	pclk_in,
	input	[7:0]data_in/*synthesis noprune*/,
	
	output	reg led2,
	output	reg led3_pclk_cnt,
	output	fifo_write_clk,
	output	fifo_write_en,
	output	reg [15:0]data_out

);
assign 	fifo_write_en = href_in;
assign	fifo_write_clk = ~bit_counter;

reg [31:0]counter;
always @(posedge pclk_in)begin
	if(href_in)begin
		counter <= counter + 32'b1;
	end
	else begin
		if(counter >= 32'd100)begin
			led3_pclk_cnt <= ~led3_pclk_cnt;
			counter <= 32'b0;
		end
	end
end


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
reg bit_counter_neg;		
always @(negedge pclk_in or negedge rst_n)begin
	if(!rst_n)
		bit_counter_neg <= 0;
	else if(href_in)begin
		bit_counter_neg <= ~bit_counter_neg;
	end
	else
		bit_counter_neg <= 1'b0;	
end
	

reg bit_counter;
always @(posedge pclk_in or negedge rst_n)begin
	if(!rst_n)
		bit_counter <= 0;
	else if(href_in)begin
		bit_counter <= ~bit_counter;
	end
	else
		bit_counter <= 1'b0;		
end
reg [7:0]data_in_buff;
always @(posedge pclk_in or negedge rst_n)begin
	if(!rst_n)
	;
	else if(href_in && (bit_counter_neg == 0))
		 data_in_buff 	<= data_in;
	else if(href_in && (bit_counter_neg == 1))
		data_out			<= {data_in_buff,data_in};
end

endmodule
