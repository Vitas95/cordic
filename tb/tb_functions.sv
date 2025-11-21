
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
    t = iteration_step / SYS_CLK_FREQ_HZ;

    // Calculate the phase in radians
    phase = 2.0 * PI * frequency_hz * t;

    // Modulo the phase to keep it within the [-PI, PI) range
    phase_wrap = fmod(phase + PI, 2 * PI) - PI;
    return phase_wrap;
endfunction

    // Function to calculate the integer phase step and the actual achievable frequency
    function automatic void calculate_freq_error(input real desired_frequency);
        real normalized_freq;
        real step_size_real;
        real actual_achieved_freq;
        logic [PHASE_WIDTH-1:0] calculated_step;

        // 1. Calculate the normalized frequency
        normalized_freq = desired_frequency / SYS_CLK_FREQ_HZ;

        // 2. Scale the normalized frequency to the full N_BITS range
        step_size_real = normalized_freq * $pow(2.0, PHASE_WIDTH);

        // 3. Convert the real value to an integer (truncation/floor)
        calculated_step = step_size_real;

        // 4. Calculate the real frequency that this integer step actually produces
        // Formula is the inverse: F_actual = (Phase_Step_Int / 2^N_Bits) * F_Clock
        actual_achieved_freq = (real'(calculated_step) / $pow(2.0, PHASE_WIDTH)) * SYS_CLK_FREQ_HZ;

        $display("--------------------------------------------------");
        $display("System Clock Frequency: %0f Hz", SYS_CLK_FREQ_HZ);
        $display("Accumulator Bits (N): %0d", PHASE_WIDTH);
        $display("--------------------------------------------------");
        $display("Desired Frequency Input: %0f Hz", desired_frequency);
        $display("Calculated Phase Step (Decimal): %0d", calculated_step);
        $display("--------------------------------------------------");
        $display("ACTUAL Achieved Frequency: %0f Hz", actual_achieved_freq);
        $display("Frequency Error: %0f Hz", desired_frequency - actual_achieved_freq);
        $display("--------------------------------------------------");
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