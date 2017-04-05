module key_sdram_write
(
	input		key,
	input		clk,
	input		rst_n,
	output	clk_write,
	output	reg	fifo_write_enable,
	output	reg 	[15:0]data_to_write

);

assign clk_write = clk;

reg buff1;
reg buff2;
reg key_;
always @(posedge clk)
begin
	buff1 <= key;
	buff2 <= buff1;
	if(buff2&~buff1)
		key_ <= 1;
	else
		key_ <=0;
end

reg STATE,NEXT_STATE;
reg [11:0]bit_counter;
parameter WAIT = 1'b0,RUN = 1'b1;
/****************************************************/
always @(posedge clk	or negedge rst_n)
begin
	if(!rst_n)
		STATE <= WAIT;
	else
		STATE <= NEXT_STATE; 
end
/****************************************************/
always @(STATE or rst_n or key_ or bit_counter)
begin
	if(!rst_n)
		NEXT_STATE = WAIT;
	else if(key_)
		NEXT_STATE = RUN;
	else
		case(STATE)
			WAIT:	NEXT_STATE = WAIT;
			RUN:	begin
					if(bit_counter >= 12'd8)
						NEXT_STATE = WAIT;
					else
						NEXT_STATE = RUN;
					end
			default:	NEXT_STATE = WAIT;
		endcase
end
/****************************************************/
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			bit_counter <= 3'd0;
		end
	else
		case(NEXT_STATE)
			WAIT:	begin
					fifo_write_enable <= 1'b0;
					bit_counter			<= 1'b0;
					data_to_write 		<= 16'b0;
					end
			RUN:	begin
					bit_counter <= bit_counter + 1'b1;
					fifo_write_enable <= 1'b1;
					data_to_write	<= 16'b1111100000011111;
					end
			default:;
		endcase
end	
endmodule
