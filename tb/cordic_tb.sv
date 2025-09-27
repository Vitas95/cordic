`timescale 1ns/1ps

module cordic_tb ();
    
parameter CLK_PERIOD = 1.0;

// Common wires
bit clk, rst;
always #(CLK_PERIOD/2) clk = ~clk;

logic [15:0] X_out, Y_out, phase;
logic valid, phase_valid;

cordic_top #(
    .STAGES(8),
    .DATA_WIDTH(16),
    .PHASE_WIDTH(16)
) dut (
    .clk(clk),
    .rst(rst),

    .X_in(16'd4974),
    .Y_in(16'd0),
    .X_out(X_out),
    .Y_out(Y_out),
    .valid(valid),
    .phase_in(phase),
    .phase_valid_in(phase_valid)
);

task apply_theta ();
integer fd;
string line;
int data;
int line_cnt;

fd = $fopen("../tb/test_data/theta_test.txt", "r");
  if (fd) begin
    phase_valid <= 1;
    while (!$feof(fd) & (line_cnt <= 100)) begin
      if ($fgets(line, fd)) begin
        data = line.atoi();
        phase = shortint'(data);
        #(CLK_PERIOD);
      end
      line_cnt++;
    end
    $fclose(fd);
    phase_valid <= 0;
  end
endtask

initial begin
clk <= 0;
rst <= 1;
#(CLK_PERIOD);
#(CLK_PERIOD);
#(CLK_PERIOD);
rst <= 0;
#(CLK_PERIOD);
apply_theta ();
#200 $stop;

end


endmodule