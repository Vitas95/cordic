//-------------------------------------------------------------------------
// Top-level testbench module: cordic_exp_gen_tb
//
// This module serves as the verification environment for the Coordinatoinal 
// Rotation Computer (CORDIC), which is expected to generate an exponent with 
// a specified frequency. In "generator mode," this testbench is simply 
// a phase counter fully written as a System Verilog function. 
//-------------------------------------------------------------------------

`timescale 1ns/1ps

module cordic_piplined_tb ();

// Simulation parameters
parameter      CLK_PERIOD = 12.5;           // 80 MHz clock
parameter real SYS_CLK_FREQ_HZ = 80.0e6; // 80 MHz clock
parameter real PI = 3.141592653589793;
parameter      PHASE_WIDTH = 16;

// Common wires
bit clk, rst;
always #(CLK_PERIOD/2) clk = ~clk;

logic [15:0]            X_out, Y_out;
logic [PHASE_WIDTH-1:0] phase, error;
logic                   valid, phase_valid;

`include "tb_functions.sv";

// DUT
cordic_top #(
    .STAGES(8),
    .DATA_WIDTH(16),
    .PHASE_WIDTH(PHASE_WIDTH),
    .PIPLINED(1)
) dut (
    .clk(clk),
    .rst(rst),

    .X_in(16'd4974),
    .Y_in(16'd0),
    .X_out(X_out),
    .Y_out(Y_out),
    .valid(valid),
    .error(error),
    .phase_in(phase),
    .phase_valid_in(phase_valid)
);

initial begin
clk <= 0;
rst <= 1;
phase_valid <= 0;
#(3*CLK_PERIOD);
rst <= 0;
#(CLK_PERIOD);
calculate_freq_error(11.453e6);
apply_phase(11.453e6, 100, 1);
#2000 $stop;
end

endmodule