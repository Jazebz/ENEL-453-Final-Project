//==============================================================
// averager_subsystem2
// -------------------------------------------------------------
// R2R averaging and scaling subsystem
//
// Function:
//   - Averages incoming 8-bit raw_data over 2^power samples
//     using the shared averager_pwm module.
//   - Produces:
//       * ave_data   : averaged 12-bit code
//       * scaled_data: averaged code scaled to millivolts
//
// Notes:
//   - Configuration is fixed to 256 samples (power = 8)
//   - Scaling assumes full-scale corresponds to ~3.3 V, using:
//         scaled[mV] ≈ (code * 3300) >> 8
//==============================================================
module averager_subsystem2(
    input  logic        clk,          // System clock
    input  logic        reset,        // Active-high reset
    input  logic        EN,           // Enable for averaging and scaling
    input  logic [7:0]  raw_data,     // 8-bit input sample from R2R ADC
    
    output logic [11:0] scaled_data,  // Averaged result scaled to mV
    output logic [11:0] ave_data      // Averaged 12-bit code
);

    //==========================================================
    // Internal averaged output from averager_pwm
    //==========================================================
    logic [11:0] out;                 // 12-bit averaged output

    //==========================================================
    // Averager: 2^power samples, N-bit data
    // ---------------------------------------------------------
    // Configuration:
    //   power = 8  -> 256-sample average
    //   N     = 12 -> 12-bit output width
    //
    // Input:
    //   raw_data (8-bit) is accumulated/averaged into 'out'
    //==========================================================
    averager_pwm #(
        .power (8),    // 256 samples
        .N     (12)
    ) R2R_AVERAGER (
        .reset (reset),
        .clk   (clk),
        .EN    (EN),
        .Din   (raw_data),
        .Q     (out)
    );

    //==========================================================
    // Scaling to millivolts
    // ---------------------------------------------------------
    // Approximate scaling:
    //   scaled_data ≈ (out * 3300) / 256
    // Implemented as:
    //   (out * 3300) >> 8
    // to avoid division and keep logic simple.
    //==========================================================
    always_ff @(posedge clk) begin
        if (reset) begin
            scaled_data <= 12'd0;
        end else if (EN) begin
            scaled_data <= (out * 3300) >> 8;
        end
    end
    
    //==========================================================
    // Output assignment
    // ---------------------------------------------------------
    // Expose averaged code directly as ave_data.
    //==========================================================
    assign ave_data = out;
    
endmodule
