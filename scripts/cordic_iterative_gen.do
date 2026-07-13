vlib work

# IQ player files
vlog -incr ../src/cordic_top.sv

# Testbench
vlog -incr ../tb/cordic_iterative_tb.sv

vsim -voptargs=+acc work.cordic_iterative_tb

set WildcardFilter [lsearch -not -all -inline $WildcardFilter Memory]

# TB
set obj cordic_iterative_tb
add wave -group TB sim:/$obj/*

# DUT
set obj cordic_iterative_tb/dut
add wave -group DUT sim:/$obj/*
add wave -group DUT sim:/$obj/CORDIC_iter/*

run 1000ns

configure wave -signalnamewidth 1
configure wave -namecolwidth 300
configure wave -valuecolwidth 100