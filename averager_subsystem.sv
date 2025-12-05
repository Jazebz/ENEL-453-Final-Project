//==============================================================
// Averager Subsystem for PWM-Based ADC
// -------------------------------------------------------------
// - Averages incoming 8-bit samples over 2^power samples
// - Produces:
//     * sawtooth_ave_data        : averaged 12-bit code
//     * sawtooth_scaled_adc_data : averaged code scaled to mV
// - Uses an internal averager_pwm module configured for 256
//   samples (power = 8) and 12-bit output width.
//==============================================================
module averager_subsystem(
    input  logic        clk,                       // System clock
    input  logic        reset,                     // Active-high reset
    input  logic        EN,                        // Enable for averaging/scaling
    input  logic [7:0]  Din,                       // 8-bit input sample
    
    output logic [11:0] sawtooth_ave_data,         // Averaged 12-bit ADC code
    output logic [11:0] sawtooth_scaled_adc_data,  // Averaged code scaled to mV
    output logic        ready                      // (Reserved for future use)
);

    //==========================================================
    // Internal signals
    //==========================================================
    logic [11:0] sawtooth_sout;    // Output of averager_pwm (12-bit)
    logic [11:0] ave_in;           // Internal copy of input (width-matched)

    // Simple zero-extended mapping of 8-bit Din to 12 bits.
    // Note: ave_in is provided for clarity/extension; current
    //       averager_pwm instance still uses Din directly.
    assign ave_in = Din;

    //==========================================================
    // Averager: 2^power samples, N-bit data
    // ---------------------------------------------------------
    // Configuration:
    //   power = 8  -> 256 samples averaged
    //   N     = 12 -> 12-bit output width (sawtooth_sout)
    // Input:
    //   Din   : 8-bit input sample
    //==========================================================
    averager_pwm #(
        .power (8),    // 256-sample moving average
        .N     (12)
    ) PWM_AVERAGER (
        .reset (reset),
        .clk   (clk),
        .EN    (EN),
        .Din   (Din),
        .Q     (sawtooth_sout)
    );

    //==========================================================
    // Scaling to Millivolts
    // ---------------------------------------------------------
    // Assumes:
    //   - Full-scale code corresponds to 3.3 V (3300 mV)
    //   - sawtooth_sout is scaled such that:
    //        scaled[mV] = (code * 3300) >> 8
    //
    // Note:
    //   Right-shift by 8 is consistent with the effective
    //   resolution used here and avoids overflow.
    //==========================================================
    always_ff @(posedge clk) begin
        if (reset) begin
            sawtooth_scaled_adc_data <= 12'd0;
        end else if (EN) begin
            sawtooth_scaled_adc_data <= (sawtooth_sout * 3300) >> 8;
        end
    end

    //==========================================================
    // Output assignment
    // ---------------------------------------------------------
    // Expose the averaged 12-bit code directly.
    //==========================================================
    assign sawtooth_ave_data = sawtooth_sout;

endmodule
