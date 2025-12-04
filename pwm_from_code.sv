//==============================================================
// pwm_from_code
// -------------------------------------------------------------
// Purpose:
//   Simple parameterizable PWM generator.
//
// Description:
//   - Generates a PWM signal based on an N-bit input 'duty' value.
//   - Uses an up-counting counter that resets on overflow.
//   - Output pwm_out is HIGH while counter < duty, LOW otherwise.
//
// Parameters:
//   WIDTH : Bit-width of the counter and duty input (default = 8)
//
// Inputs:
//   clk     : System clock
//   reset   : Active-high synchronous reset
//   duty    : Duty cycle control (0 → 0%, max → 100%)
//
// Output:
//   pwm_out : PWM output waveform
//==============================================================
module pwm_from_code #(
    parameter int WIDTH = 8
)(
    input  logic              clk,       // System clock
    input  logic              reset,     // Active-high reset
    input  logic [WIDTH-1:0]  duty,      // Duty cycle value
    output logic              pwm_out    // PWM output signal
);

    //==========================================================
    // Counter logic
    // ---------------------------------------------------------
    // Free-running counter that wraps on overflow.
    // The PWM duty cycle is determined by comparing the counter
    // value against the input 'duty' value each clock cycle.
    //==========================================================
    logic [WIDTH-1:0] counter;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= '0;
            pwm_out <= 1'b0;
        end else begin
            counter <= counter + 1'b1;
            pwm_out <= (counter < duty);
        end
    end

endmodule
