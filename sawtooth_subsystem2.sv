// -------------------------------------------------------------
// R2R_subsystem
//  - R2R ladder subsystem supporting two ADC modes:
//
//    sar_mode = 0 : Ramp ADC mode
//      * Uses a sawtooth (ramp) code driving the R2R ladder
//      * A falling-edge detector captures the ramp code at the
//        comparator transition to form the raw ADC value.
//
//    sar_mode = 1 : SAR ADC mode
//      * Uses r2r_sar_adc_simple to run a slow, stable SAR
//        conversion driving the R2R ladder.
//      * The SAR controller outputs both the DAC drive code
//        and the raw ADC result.
//
//  - In both modes, the selected raw ADC value is passed through
//    an averaging/scaling subsystem to produce:
//      * ave_data   : averaged 12-bit code
//      * scaled_data: averaged result scaled to e.g. mV
//
//  - R2R_output always drives the external R2R ladder, either
//    from the ramp generator or the SAR DAC code.
//==============================================================
module R2R_subsystem(
    input  logic         clk,
    input  logic         reset,
    input  logic         compare2,     // Comparator output (Vin vs R2R ladder)
    input  logic         sar_mode,     // 0 = ramp ADC, 1 = SAR ADC

    output logic [11:0]  scaled_data,  // Scaled, averaged ADC result
    output logic [11:0]  ave_data,     // Averaged raw ADC code
    output logic [7:0]   raw_data,     // Selected raw ADC code (ramp or SAR)
    output logic [7:0]   R2R_output    // Code that drives the R2R ladder
);

    //==========================================================
    // Internal signals
    //==========================================================

    // Ramp-path signals
    logic [7:0] ramp_code;    // Ramp code driving ladder in ramp mode
    logic [7:0] raw_ramp;     // Captured raw code from ramp-based ADC

    // SAR-path signals
    logic [7:0] sar_dac_code; // DAC drive code from SAR controller
    logic [7:0] sar_raw_code; // Final SAR ADC result

    //==========================================================
    // SAR controller (slow & stable)
    // ---------------------------------------------------------
    // r2r_sar_adc_simple:
    //   - Performs N-bit SAR conversion using compare2 feedback
    //   - Provides:
    //       * sar_dac_code to drive the R2R ladder
    //       * sar_raw_code as the conversion result
    //   - Enabled only when sar_mode = 1
    //==========================================================
    r2r_sar_adc_simple #(
        .N_BITS       (8),
        .CLK_DIV      (100_000),  // 1 kHz SAR step at 100 MHz clk
        .SETTLE_TICKS (2)
    ) R2R_SAR (
        .clk      (clk),
        .reset    (reset),
        .enable   (sar_mode),     // Run only when SAR mode enabled
        .comp_in  (compare2),     // 1 when Vin > Vdac from R2R
        .dac_code (sar_dac_code),
        .adc_code (sar_raw_code)
    );

    //==========================================================
    // Original ramp generator (only in ramp mode)
    // ---------------------------------------------------------
    // sawtooth_generator2:
    //   - Generates an 8-bit ramp code at a specified frequency.
    //   - In ramp mode, this code is sent to the R2R ladder.
    //   - Disabled when sar_mode = 1.
    //==========================================================
    sawtooth_generator2 #(
        .WIDTH      (8),
        .CLOCK_FREQ (100_000_000),
        .WAVE_FREQ  (1.0)
    ) R2R_ramp (
        .clk        (clk),
        .reset      (reset),
        .enable     (!sar_mode),   // Disable when SAR is active
        .R2R_output (ramp_code)
    );

    //==========================================================
    // Ramp ADC comparator (edge-capture)
    // ---------------------------------------------------------
    // Fall_Detector2:
    //   - Monitors compare2 and captures the ramp_code value
    //     at the falling edge (transition of comparator).
    //   - This captured code becomes the raw ramp-based ADC
    //     measurement.
    //==========================================================
    Fall_Detector2 Fall_Detector2 (
        .clk        (clk),
        .reset      (reset),
        .compare2   (compare2),
        .R2R_output (ramp_code),
        .raw_data   (raw_ramp)
    );

    //==========================================================
    // Mode selection: Ramp vs SAR
    // ---------------------------------------------------------
    // R2R_output : Always drives the external R2R ladder
    // raw_data   : Raw ADC code chosen based on sar_mode
    //==========================================================
    assign R2R_output = sar_mode ? sar_dac_code : ramp_code;
    assign raw_data   = sar_mode ? sar_raw_code : raw_ramp;

    //==========================================================
    // Averager + scaler
    // ---------------------------------------------------------
    // averager_subsystem2:
    //   - Averages the selected raw_data over many samples
    //   - Produces:
    //       * ave_data    : averaged 12-bit code
    //       * scaled_data : averaged result scaled (e.g., to mV)
    //   - Always enabled with EN = 1'b1
    //==========================================================
    averager_subsystem2 R2R_averager_subsystem (
        .clk         (clk),
        .reset       (reset),
        .EN          (1'b1),
        .raw_data    (raw_data),
        .scaled_data (scaled_data),
        .ave_data    (ave_data)
    );

endmodule
