module sawtooth_generator2 #(
    parameter int  WIDTH       = 8,             // PWM bit-width
    parameter int  CLOCK_FREQ  = 100_000_000,   // System clock (Hz)
    parameter real WAVE_FREQ   = 1.0            // Sawtooth frequency (Hz)
)(
    input  logic               clk,
    input  logic               reset,
    input  logic               enable,
    output logic [WIDTH-1:0]   R2R_output
);

    // Derived constants
    localparam int MAX_DUTY_CYCLE     = (1 << WIDTH) - 1;
    localparam int TOTAL_STEPS        = MAX_DUTY_CYCLE * 2;
    localparam int DOWNCOUNTER_PERIOD = integer'(CLOCK_FREQ / (WAVE_FREQ * TOTAL_STEPS));

    // Internal signals
    logic zero;
    logic [WIDTH-1:0] duty_cycle;

    assign R2R_output = duty_cycle;

    // Step-rate downcounter
    downcounter_waveform #(
        .PERIOD(DOWNCOUNTER_PERIOD)
    ) downcounter_inst (
        .clk    (clk),
        .reset  (reset),
        .enable (enable),
        .zero   (zero)
    );

    // Upward ramp for sawtooth
    always_ff @(posedge clk) begin
        if (reset) begin
            duty_cycle <= 0;
        end else if (enable) begin
            if (zero) begin
                if (duty_cycle == MAX_DUTY_CYCLE)
                    duty_cycle <= 0;
                else
                    duty_cycle <= duty_cycle + 1;
            end
        end else begin
            duty_cycle <= 0;
        end
    end

endmodule
