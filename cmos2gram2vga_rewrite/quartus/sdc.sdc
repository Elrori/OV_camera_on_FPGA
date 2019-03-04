create_clock -period 20 [get_ports _clk_]
create_clock -period 40 [get_ports cmos_pclk]

derive_pll_clocks
derive_clock_uncertainty