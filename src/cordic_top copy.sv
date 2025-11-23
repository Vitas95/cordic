module cordic_top #(
    parameter STAGES = 4,
    parameter DATA_WIDTH = 16,
    parameter PHASE_WIDTH = 16
) (
    input clk,
    input rst,

    input  logic [DATA_WIDTH-1:0]  X_in,
    input  logic [DATA_WIDTH-1:0]  Y_in,
    output logic [DATA_WIDTH-1:0]  X_out,
    output logic [DATA_WIDTH-1:0]  Y_out,
    output logic                   valid,
    output logic [PHASE_WIDTH-1:0] error,
    input  logic [PHASE_WIDTH-1:0] phase_in,
    input  logic                   phase_valid_in
);
// TODO: wrap input and output ports as axi stream;

// Local parameters
localparam COUNT_WIDTH = $clog2(STAGES);
localparam VALID_DELAY = STAGES + 1;
localparam real PI = 3.141592653589793;
    
logic signed [PHASE_WIDTH-1:0] phase;
logic                          phase_valid;
typedef struct packed {
    logic signed [DATA_WIDTH-1:0] x;
    logic signed [DATA_WIDTH-1:0] y;
} complex;

complex init;

// Input piplining
always_ff @(posedge clk) begin
    if (rst) phase_valid <= 0;
    else begin 
        phase_valid <= phase_valid_in;
        phase       <= phase_in;
        init.x      <= X_in;
        init.y      <= Y_in;
    end
end

// atan(2^-stage) memory
logic signed [PHASE_WIDTH-1:0] atan [0:STAGES-1];
initial begin
    for (int i = 0; i < STAGES; i++)
        atan[i] = shortint'(($atan($pow(2,-i))/PI)*$pow(2,PHASE_WIDTH-3));
end

// Theta preprocessing from -pi:pi to -pi/2:pi/2
logic signed [PHASE_WIDTH-1:0] phase_wrapped;
logic second_quad, third_quad, unwrap;
assign second_quad = phase > shortint'($pow(2,PHASE_WIDTH-4));
assign third_quad = phase < shortint'(-$pow(2,PHASE_WIDTH-4));
assign unwrap = second_quad | third_quad;
always_ff @(posedge clk) begin
    if (second_quad)        phase_wrapped <= phase - shortint'(1 * $pow(2,PHASE_WIDTH-3));
    else if (third_quad)    phase_wrapped <= phase + shortint'(1 * $pow(2,PHASE_WIDTH-3));
    else                    phase_wrapped <= phase;
end

// Cordic core
complex                        stage [0:STAGES-1];
logic signed [PHASE_WIDTH-1:0] theta [0:STAGES-1];

always_ff @(posedge clk) begin
    if (~(phase_wrapped[PHASE_WIDTH-1])) begin
        stage[0].x <= init.x + init.y;
        stage[0].y <= init.y - init.x;
        theta[0]   <= phase_wrapped - atan[0];
    end else if ((phase_wrapped[PHASE_WIDTH-1])) begin
        stage[0].x <= init.x - init.y;
        stage[0].y <= init.y + init.x;
        theta[0]   <= phase_wrapped + atan[0];      
    end
end

generate
    always_ff @(posedge clk) begin
        for (int i = 1; i < STAGES; i++) begin
            if (~(theta[i-1][PHASE_WIDTH-1])) begin
                stage[i].x <= stage[i-1].x + (stage[i-1].y >>> i);
                stage[i].y <= stage[i-1].y - (stage[i-1].x >>> i);
                theta[i]   <= theta[i-1] - atan[i];
            end else if ((theta[i-1][PHASE_WIDTH-1])) begin
                stage[i].x <= stage[i-1].x - (stage[i-1].y >>> i);
                stage[i].y <= stage[i-1].y + (stage[i-1].x >>> i);
                theta[i]   <= theta[i-1] + atan[i];      
            end
        end    
    end
endgenerate

// Valid and unwrap signals delay
logic [VALID_DELAY-1:0] valid_delay, unwrap_delay;
always_ff @(posedge clk) begin
    if (rst) begin 
        valid_delay  <= {valid_delay[VALID_DELAY-2:0],0};
        unwrap_delay <= {unwrap_delay[VALID_DELAY-2:0],0};
    end else begin
        valid_delay <= {valid_delay[VALID_DELAY-2:0],phase_valid};
        unwrap_delay <= {unwrap_delay[VALID_DELAY-2:0],unwrap};
    end
end

// Output piplining
always_ff @(posedge clk) begin
    valid <= valid_delay[VALID_DELAY-1];
    if (valid_delay[VALID_DELAY-1]) begin
        if (unwrap_delay[VALID_DELAY-1]) begin
            X_out <= -stage[STAGES-1].x;
            Y_out <= -stage[STAGES-1].y;
        end else begin
            X_out <= stage[STAGES-1].x;
            Y_out <= stage[STAGES-1].y;
        end
        error <= theta[STAGES-1];
    end 
end

endmodule