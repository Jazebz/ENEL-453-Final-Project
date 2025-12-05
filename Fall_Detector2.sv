//==============================================================
// Fall_Detector2
// -------------------------------------------------------------
// Purpose:
//   Captures the current R2R_output value whenever a falling edge
//   is detected on the comparator signal compare2.
//
// Description:
//   - Monitors compare2 on each clock edge.
//   - When a transition from HIGH → LOW transition is detected on compare2,
//     the current R2R_output value is latched into raw_data.
//   - Intended for use in ramp-based ADC operation with an R2R
//     ladder, where the captured code corresponds to the point
//     at which the ramp crosses the input voltage.
//
// Inputs:
//   clk         : System clock
//   reset       : Active-high synchronous reset
//   compare2    : Comparator output signal
//   R2R_output  : Current R2R DAC code (ramp value)
//
// Output:
//   raw_data    : Latched R2R_output value at the moment of the
//                 detected falling edge on compare2
//==============================================================
module Fall_Detector2 (
    input  logic       clk,
    input  logic       reset,
    input  logic       compare2,      // Incoming comparator signal
    input  logic [7:0] R2R_output,    // Current R2R DAC / ramp code
    output logic [7:0] raw_data       // Captured value on falling edge
);

    //==========================================================
    // Internal register to track previous comparator state
    //==========================================================
    logic compare_prev;   // Stores previous value of compare2

    //==========================================================
    // Edge detection and capture logic
    // ---------------------------------------------------------
    // - Detects a falling edge on compare2:
    //       compare_prev = 1, compare2 = 0
    // - On a falling edge, raw_data is updated with the current
    //   R2R_output value.
    //==========================================================
    always_ff @(posedge clk) begin
        if (reset) begin
            raw_data     <= 8'd0;
            compare_prev <= 1'b1;       // Assume comparator starts high
        end else begin
            // Detect falling edge: previous = 1, current = 0
            if (compare_prev && !compare2)
                raw_data <= R2R_output;

            // Update stored comparator state
            compare_prev <= compare2;
        end
    end

endmodule
