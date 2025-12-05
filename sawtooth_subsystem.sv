//==============================================================
// PWM ADC subsystem with Ramp + SAR modes
// -------------------------------------------------------------
// sar_mode = 0 : Original ramp ADC behaviour
// sar_mode = 1 : SAR ADC operating on PWM duty cycle
//
// Functionality:
//   - Generates a PWM waveform either from a ramp (sawtooth) or
//     from a SAR-derived duty cycle
//   - Uses the selected ADC code (ramp or SAR) as input to an
//     averaging/scaling block
//   - Outputs:
//       * pwm_out                    : PWM waveform to analog filter
//       * sawtooth_ave_data          : averaged ADC result
//       * sawtooth_scaled_adc_data   : scaled ADC result
//       * adc_value                  : raw 8-bit ADC code (For menus, etc.)
//==============================================================
module PWM_subsystem(
    input  logic        clk,
    input  logic        reset,
    input  logic        compare1,     // Comparator output: PWM-based analog vs Vin
    input  logic        sar_mode,     // Mode select: 0 = Ramp ADC, 1 = SAR ADC

    output logic        pwm_out,      // PWM to external RC filter
    output logic [11:0] sawtooth_scaled_adc_data,
    output logic [11:0] sawtooth_ave_data,
    output logic [7:0]  adc_value     // Selected raw ADC code (ramp or SAR)
);

    //==========================================================
    // Internal signals
    //==========================================================
    logic        ready;               // Averager ready flag (not used externally)

    // Ramp-path signals
    logic [7:0] duty_sawtooth_out;    // Sawtooth PWM duty cycle
    logic [7:0] adc_ramp;             // Raw ADC code from ramp conversion
    logic       pwm_ramp;             // PWM output for ramp mode

    // SAR-path signals
    logic [7:0] sar_dac_code;         // DAC code driven by SAR logic (duty for PWM)
    logic [7:0] sar_raw_code;         // Raw ADC code from SAR conversion
    logic       pwm_sar;              // PWM output for SAR mode

    //==========================================================
    // Averager / scaler
    // ---------------------------------------------------------
    // Uses the currently selected adc_value (ramp or SAR),
    // providing:
    //   - sawtooth_ave_data          : averaged 12-bit value
    //   - sawtooth_scaled_adc_data   : scaled 12-bit value
    //==========================================================
    averager_subsystem PWM_averager_subsystem (
        .clk                      (clk),
        .reset                    (reset),
        .EN                       (1'b1),                // Always enabled
        .Din                      (adc_value),
        .sawtooth_ave_data        (sawtooth_ave_data),
        .sawtooth_scaled_adc_data (sawtooth_scaled_adc_data),
        .ready                    (ready)
    );

    //==========================================================
    // Ramp ADC path (original behaviour)
    // ---------------------------------------------------------
    // Generates a sawtooth-based PWM. The comparator measures
    // when the PWM ramp crosses Vin, producing a digital code.
    // This path is disabled when sar_mode = 1.
    //==========================================================
    PWM_Ramp #(
        .WIDTH      (8),
        .CLOCK_FREQ (100_000_000),
        .WAVE_FREQ  (1.0)
    ) PWM_Ramp (
        .clk               (clk),
        .reset             (reset),
        .duty_sawtooth_out (duty_sawtooth_out),
        .enable            (!sar_mode),      // Active only in ramp mode
        .pwm_out           (pwm_ramp)
    );

    Fall_Detector Fall_Detector (
        .clk        (clk),
        .reset      (reset),
        .compare1   (compare1),
        .duty_cycle (duty_sawtooth_out),
        .raw_value1 (adc_ramp)
    );

    //==========================================================
    // SAR ADC path on PWM duty cycle
    // ---------------------------------------------------------
    // r2r_sar_adc_simple:
    //   - Runs a SAR conversion based on comparator feedback
    //   - Produces:
    //       * sar_dac_code : the code that would reproduce Vin
    //       * sar_raw_code : final ADC code used digitally
    // The DAC code is then used to generate a PWM with the
    // corresponding duty cycle.
    //==========================================================
    r2r_sar_adc_simple #(
        .N_BITS       (8),
        .CLK_DIV      (100_000),     // ~1 kHz SAR step at 100 MHz
        .SETTLE_TICKS (2)
    ) PWM_SAR (
        .clk      (clk),
        .reset    (reset),
        .enable   (sar_mode),        // Active only in SAR mode
        .comp_in  (compare1),        // High when Vin > Vdac (filtered PWM)
        .dac_code (sar_dac_code),
        .adc_code (sar_raw_code)
    );

    // Generate PWM waveform from SAR-derived duty code
    pwm_from_code #(
        .WIDTH (8)
    ) PWM_SAR_CORE (
        .clk     (clk),
        .reset   (reset),
        .duty    (sar_dac_code),
        .pwm_out (pwm_sar)
    );

    //==========================================================
    // Mode selection: Ramp vs SAR
    // ---------------------------------------------------------
    // pwm_out   : PWM waveform sent to analog filter
    // adc_value : raw ADC code used by the digital system
    //==========================================================
    assign pwm_out   = sar_mode ? pwm_sar      : pwm_ramp;
    assign adc_value = sar_mode ? sar_raw_code : adc_ramp;

endmodule
