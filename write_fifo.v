module	write_fifo
(
	input		clk_ref,
	input		reset,
	input		write_one_signal,//下降沿触发一次写fifo操作
	output	reg	[15:0]data_out,
	output	reg	fifo_write_en,
	output	reset_WriteAddress
);
reg buff0,buff1,fifo_write_en_signal;
always @(posedge clk_ref)
begin
	buff0 <= write_one_signal;
	buff1 <= buff0;
	if(buff1&~buff0)begin
		fifo_write_en_signal <= 1;
		NN <= NN + 1'b1;
		end
	else
		fifo_write_en_signal <= 0;
end
//assign reset_WriteAddress = fifo_write_en_signal;
reg NN;
/****************************************************************************
*三段状态机,产生fifo_write_en，在其间根据基准时钟写data_out
*基准时钟	clk_ref
*唯一敏感信号fifo_write_en_signal为高电平瞬间进入写fifo模式
*****************************************************************************/
`define	CHARACTER 256	//要写入fifo的字数
parameter	wait_station = 2'd0,write_station = 2'd1;
reg [1:0]state,next_state;
reg [15:0]counter;
always @(posedge clk_ref or negedge reset)
begin
	if(!reset)
		state <= wait_station;
	else	
		state <= next_state;
end
always @(state or fifo_write_en_signal or reset or counter)
begin
	if(!reset)
		next_state = wait_station;
	else if(fifo_write_en_signal)
		next_state = write_station;
	else
		case(state)
			wait_station: 	next_state = wait_station;
			write_station:	begin
								if(counter >=`CHARACTER)
									next_state = wait_station;
								else
									next_state = write_station;
								end
			default:			next_state = wait_station;
		endcase
end

always @(negedge clk_ref or negedge reset)
begin
	if(!reset)
	begin
		counter <= 16'b0;
		fifo_write_en <= 1'b0;
	end
	else 
		case(next_state)
			wait_station:	begin
								fifo_write_en <= 1'b0;
								counter <= 16'b0;
								data_out <= 16'b0;
								end
			write_station:	begin
								fifo_write_en <= 1'b1;
								counter <= counter + 1'b1;
								if(NN)
									data_out <= 16'hffff;
								else	
									data_out <= 16'h0000000000011111;
								end
		default:;
		endcase
end
/*****************************************************************************/
/*****************************************************************************/
endmodule
