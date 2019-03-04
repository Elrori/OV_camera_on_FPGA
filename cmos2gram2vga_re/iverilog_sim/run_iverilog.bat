iverilog -D _DEBUG_ -y. -y.\uart_ip -o cmos2gram2vga.vvp .\cmos2gram2vga_tb.v D:\Quartus_17.1\quartus\eda\sim_lib\altera_mf.v
vvp cmos2gram2vga.vvp
gtkwave wave.vcd
#rdfifo.v wrfifo.v pll.v 需要使用 Altera 仿真模型