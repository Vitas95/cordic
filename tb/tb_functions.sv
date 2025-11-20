
task apply_theta ();
integer fd;
string line;
int data;
int line_cnt;

// Read and apply phase from the test_data
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

function real fmod(real num, real den);
  // Implement the logic for floating-point modulo operation here.
  return num - (den * $floor(num / den));
endfunction

function automatic real calc_phase_radians(
    input longint iteration_step,
    input real frequency_hz
);
    real t;
    real phase;
    real phase_wrap;

    // Time step
    t = iteration_step / SYSTEM_CLK_FREQ_HZ;

    // Calculate the phase in radians
    phase = 2.0 * PI * frequency_hz * t;

    // Modulo the phase to keep it within the [-PI, PI) range
    phase_wrap = fmod(phase + PI, 2 * PI) - PI;
    return phase_wrap;
endfunction

task apply_theta_calc (
  input real frequency_hz,
  input int n_of_samples
);
    real data;
    int line_cnt;

    // Apply calculated phase at the CORDIC DUT input
    phase_valid <= 1;
    while (line_cnt <= n_of_samples) begin
        data = calc_phase_radians(line_cnt, frequency_hz);
        phase = shortint'(data*2**(PHASE_WIDTH-3));
        #(CLK_PERIOD);
        line_cnt++;
    end
    phase_valid <= 0;
endtask