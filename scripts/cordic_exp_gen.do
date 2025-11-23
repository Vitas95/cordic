vlib work

# IQ player files
vlog -incr ../src/cordic_top.sv

# Testbench
vlog -incr ../tb/cordic_exp_gen_tb.sv

vsim -voptargs=+acc work.cordic_exp_gen_tb

set WildcardFilter [lsearch -not -all -inline $WildcardFilter Memory]

# TB
set obj cordic_exp_gen_tb
add wave -group TB sim:/$obj/*

# DUT
set obj cordic_exp_gen_tb/dut
add wave -group DUT sim:/$obj/*

run 1500ns

configure wave -signalnamewidth 1
configure wave -namecolwidth 300
configure wave -valuecolwidth 100