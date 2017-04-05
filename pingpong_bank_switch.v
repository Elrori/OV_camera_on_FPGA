module	pingpong_bank_switch
(
	input 	clk,
	input 	reset,
	input		frame_read_done,
	input		frame_write_done,
	output	reg	[1:0]read_bank_address,
	output	reg	[1:0]write_bank_address,
	output	reg	read_address_set,
	output	reg	write_address_set,
	output	reg 	frame_read_done_buff
);
/*******************************************************************************************************
*乒乓操作切换BANK；当写入完一帧时（frame_write_done信号）立即无条件切换 写BANK 。 VGA读完一帧
*（frame_read_done信号）时判断写BANK是否与VGA读BANK一样，是则切换 读BANK，否则VGA继续读该BANK
********************************************************************************************************/
reg buff0,buff1;//,frame_read_done_buff;
always @(posedge clk )//posedge detection
begin
	buff0 <= frame_read_done;
	buff1 <= buff0;
	if(buff0&~buff1)
		frame_read_done_buff <= 1'b1;
	else	
		frame_read_done_buff <= 1'b0;
end
reg buff00,buff11,frame_write_done_buff;
always @(posedge clk )//posedge detection
begin
	buff00 <= frame_write_done;
	buff11 <= buff00;
	if(buff00&~buff11)
		frame_write_done_buff <= 1'b1;
	else	
		frame_write_done_buff <= 1'b0;
end

reg [2:0]state;
always @(posedge clk or negedge reset)//write_bank_address
begin
	if(!reset)
	begin
	state <= 3'd0;
	end
	else
	begin
		case(state)
			3'd0:begin	write_bank_address <= ~read_bank_address; state <= 3'd1;	end
			3'd1:begin	write_address_set <= 1'd0; state <= 3'd2;	end
			3'd2:begin	write_address_set <= 1'd1; state <= 3'd3;	end
			3'd3:begin	write_address_set <= 1'd0; state <= 3'd4;	end
			3'd4:begin	
						if(frame_write_done_buff)
							begin
								write_bank_address <= ~write_bank_address;//当写完一帧立即无条件变换地址！
								state <= 3'd1;
							end
					end
		default:;
		endcase
	end
end
reg [2:0]state2;
always @(posedge clk or negedge reset)//read_address_set
begin
	if(!reset)
	begin
	state2 <= 3'd0;
	end
	else
	begin
		case(state2)
			3'd0:begin	read_address_set <= 1'd0; state2 <= 3'd1;	end
			3'd1:begin	read_address_set <= 1'd1; state2 <= 3'd2;	end
			3'd2:begin	read_address_set <= 1'd0; state2 <= 3'd3;	end
			3'd3:begin	
						if(frame_read_done_buff)//VGA读完一帧进入
							begin
								if(write_bank_address == read_bank_address)
									begin
										read_bank_address <= ~read_bank_address;//当检测到读写BANK一样时，VGA读BANK切换到另一个（另一个必定满载数据）
										state2 <= 3'd0;
									end
								else
									begin
									read_bank_address <= read_bank_address;//当检测到读写BANK不一样时（另一边写BANK未完），VGA继续读此BANK
										state2 <= 3'd3;
									end
							end
						else	
							state2 <= 3'd3;
					end
		default:;
		endcase
	end
end

endmodule
