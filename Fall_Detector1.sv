//==============================================================
// Fall_Detector
// -------------------------------------------------------------
// Purpose:
//   Captures the current duty_cycle value whenever a falling
//   edge is detected on the input comparator signal.
//
// Description:
//   - Monitors compare1 each clock cycle.
//   - When a transition from HIGH → LOW occurs, the current
//     duty_cycle value is latched into raw_value1.
//   - Used in ramp-based ADC systems to record the PWM duty
//     corresponding to the analog voltage threshold crossing.
//
// Inputs:
//   clk          : System clock
//   reset        : Active-high synchronous reset
//   compare1     : Comparator output (1 when Vref < Vin)
//   duty_cycle   : Current PWM duty cycle value
//
// Output:
//   raw_value1   : Captured duty_cycle value at the moment of
//                  comparator falling edge
//==============================================================
module Fall_Detector (
    input  logic       clk,
    input  logic       reset,
    input  logic       compare1,       // Incoming comparator signal
    input  logic [7:0] duty_cycle,     // Current sawtooth duty value
    output logic [7:0] raw_value1      // Captured value on falling edge
);

    //==========================================================
    // Internal register to track previous comparator state
    //==========================================================
    logic compare_prev;   // Stores previous value of compare1

    //==========================================================
    // Edge detection and capture logic
    // ---------------------------------------------------------
    // - Detects falling edge (compare_prev=1, compare1=0)
    // - Latches duty_cycle into raw_value1 on falling edge
    //==========================================================
    always_ff @(posedge clk) begin
        if (reset) begin
            raw_value1   <= 8'd0;
            compare_prev <= 1'b1;   // Assume comparator starts high
        end else begin
            if (compare_prev && !compare1)
                raw_value1 <= duty_cycle;  // Capture duty at falling edge

            compare_prev <= compare1;      // Update stored comparator state
        end
    end

endmodule
