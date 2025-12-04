//==============================================================
// Lab7_Top_Level
// -------------------------------------------------------------
// Top-level integration for Lab 7:
// - XADC + PWM ADC + R2R ADC (each with ramp/SAR modes)
// - Menu-selectable display on 7-seg
// - Auto-calibration for PWM_scaled and R2R_scaled using XADC_scaled
//   * cal_button  : capture offset (XADC_scaled - ADC_scaled)
//   * cal_switch  : 0 = raw scaled, 1 = calibrated scaled
//==============================================================
module Lab7_Top_Level(
    // ----------------------
    // Clock & Reset
    // ----------------------
    input  logic        clk,              // System clock
    input  logic        reset,            // Active-high reset (BTNC)

    // ----------------------
    // Mode control / ADC comparators
    // ----------------------
    input  logic [3:0]  mode_select,      // Mode / menu select
    input  logic        compare1,         // Comparator for PWM-based ADC
    input  logic        compare2,         // Comparator for R2R-based ADC
    output logic        PWM_out,          // PWM output waveform
    output logic [7:0]  R2R_output,       // 8-bit R2R DAC output

    // ----------------------
    // User input controls
    // ----------------------
    input  logic        decimal_selection,// Button for decimal format
    input  logic [11:0] switches_inputs,  // General slide switches

    // Calibration controls
    input  logic        cal_button,       // Pushbutton: trigger calibration
    input  logic        cal_switch,       // Switch: 0=raw scaled, 1=calibrated

    // ----------------------
    // Seven-segment display outputs
    // ----------------------
    output logic CA, CB, CC, CD, CE, CF, CG, DP,
    output logic AN1, AN2, AN3, AN4,

    // ----------------------
    // XADC analog input ports (aux channel 15)
    // ----------------------
    input  logic        vauxp15,          // XADC auxiliary positive input
    input  logic        vauxn15           // XADC auxiliary negative input
);

    //==========================================================
    // Internal Signals
    //==========================================================
    // XADC measurement data
    logic [15:0] XADC_raw;
    logic [15:0] XADC_averaged;
    logic [15:0] XADC_scaled;

    // PWM ADC measurement data
    logic [15:0] PWM_raw;
    logic [11:0] PWM_ave_core;            // 12-bit average from PWM subsystem
    logic [15:0] PWM_averaged;            // 16-bit zero-extended average
    logic [11:0] PWM_scaled_core;         // 12-bit scaled from PWM subsystem
    logic [15:0] PWM_scaled_raw;          // zero-extended raw scaled
    logic [15:0] PWM_scaled_cal;          // calibrated scaled

    // R2R ADC measurement data
    logic [15:0] R2R_raw;
    logic [11:0] R2R_ave_core;            // 12-bit average from R2R subsystem
    logic [15:0] R2R_averaged;            // 16-bit zero-extended average
    logic [11:0] R2R_scaled_core;         // 12-bit scaled from R2R subsystem
    logic [15:0] R2R_scaled_raw;          // zero-extended raw scaled
    logic [15:0] R2R_scaled_cal;          // calibrated scaled

    // Menu output and BCD
    logic [15:0] Menu_OUT;
    logic [15:0] BCD_OUT;

    // Decimal point control
    logic [3:0] decimal_pt;

    // SAR mode control
    logic       sar_mode_r2r;
    logic       sar_mode_pwm;

    // Calibration button sync & edge detect
    logic cal_btn_sync0, cal_btn_sync1, cal_btn_prev;
    logic cal_trig_pulse;

    //==========================================================
    // Mode / SAR Control Assignments
    //==========================================================
    assign sar_mode_r2r = switches_inputs[0]; // e.g. SW0: R2R SAR mode
    assign sar_mode_pwm = switches_inputs[1]; // e.g. SW1: PWM SAR mode

    //==========================================================
    // PWM Subsystem (Ramp + SAR)
    //==========================================================
    PWM_subsystem PWM_subsystem_inst (
        .clk                      (clk),
        .reset                    (reset),
        .compare1                 (compare1),
        .sar_mode                 (sar_mode_pwm),            // 0 = Ramp, 1 = SAR
        .pwm_out                  (PWM_out),
        .sawtooth_ave_data        (PWM_ave_core),            // 12-bit averaged PWM data
        .sawtooth_scaled_adc_data (PWM_scaled_core),         // 12-bit scaled PWM data
        .adc_value                (PWM_raw[7:0])             // Raw 8-bit PWM data
    );

    // Zero-extend PWM raw to 16 bits
    assign PWM_raw[15:8] = 8'd0;

    //==========================================================
    // XADC Subsystem
    //==========================================================
    XADC_Subsystem XADC_subsystem_inst (
        .clk             (clk),
        .reset           (reset),
        .vauxp15         (vauxp15),
        .vauxn15         (vauxn15),
        .scaled_adc_data (XADC_scaled),    // scaled XADC (e.g., mV)
        .raw_data        (XADC_raw),
        .ave_data        (XADC_averaged)
    );

    //==========================================================
    // R2R Subsystem (Ramp + SAR)
    //==========================================================
    R2R_subsystem R2R_subsystem_inst (
        .clk         (clk),
        .reset       (reset),
        .compare2    (compare2),
        .sar_mode    (sar_mode_r2r),        // 0 = Ramp, 1 = SAR
        .scaled_data (R2R_scaled_core),     // 12-bit scaled R2R data
        .ave_data    (R2R_ave_core),        // 12-bit averaged R2R data
        .raw_data    (R2R_raw[7:0]),        // 8-bit raw R2R data
        .R2R_output  (R2R_output)
    );

    // Zero-extend R2R raw to 16 bits
    assign R2R_raw[15:8] = 8'd0;

    //==========================================================
    // Build 16-bit averages (uncalibrated) for Menu
    //==========================================================
    assign PWM_averaged = {4'b0000, PWM_ave_core}; // 12 -> 16
    assign R2R_averaged = {4'b0000, R2R_ave_core}; // 12 -> 16

    //==========================================================
    // Build 16-bit scaled_raw values for calibration
    //==========================================================
    assign PWM_scaled_raw = {4'b0000, PWM_scaled_core}; // 12 -> 16
    assign R2R_scaled_raw = {4'b0000, R2R_scaled_core}; // 12 -> 16

    //==========================================================
    // Calibration button synchronizer & edge detector
    // cal_button -> 1-clock cal_trig_pulse
    //==========================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cal_btn_sync0 <= 1'b0;
            cal_btn_sync1 <= 1'b0;
            cal_btn_prev  <= 1'b0;
        end else begin
            cal_btn_sync0 <= cal_button;   // async → sync stage 1
            cal_btn_sync1 <= cal_btn_sync0;// sync stage 2
            cal_btn_prev  <= cal_btn_sync1;// store previous
        end
    end

    assign cal_trig_pulse = cal_btn_sync1 & ~cal_btn_prev; // rising edge

    //==========================================================
    // Auto-calibration blocks (scaled-domain) for PWM & R2R
    //==========================================================

    // PWM scaled auto-cal
    auto_cal #(
        .WIDTH(16)
    ) PWM_auto_cal (
        .clk          (clk),
        .reset        (reset),
        .cal_trig     (cal_trig_pulse),   // one-shot from cal_button
        .cal_switch   (cal_switch),       // 1 = calibrated, 0 = raw
        .xadc_scaled  (XADC_scaled),      // reference (scaled)
        .adc_scaled   (PWM_scaled_raw),   // PWM scaled (raw)
        .display_code (PWM_scaled_cal)    // PWM scaled (raw or calibrated)
    );

    // R2R scaled auto-cal
    auto_cal #(
        .WIDTH(16)
    ) R2R_auto_cal (
        .clk          (clk),
        .reset        (reset),
        .cal_trig     (cal_trig_pulse),   // same calibration event
        .cal_switch   (cal_switch),       // same switch
        .xadc_scaled  (XADC_scaled),      // reference (scaled)
        .adc_scaled   (R2R_scaled_raw),   // R2R scaled (raw)
        .display_code (R2R_scaled_cal)    // R2R scaled (raw or calibrated)
    );

    //==========================================================
    // Menu / Data Selection Subsystem
    //  - It now receives calibrated scaled values for
    //    PWM_scaled and R2R_scaled (when cal_switch=1).
    //==========================================================
    Menu_Subsystem Menu_Subsystem_inst (
        .clk               (clk),
        .reset             (reset),
        .R2R_raw           (R2R_raw),
        .R2R_averaged      (R2R_averaged),
        .R2R_scaled        (R2R_scaled_cal),   // <-- calibrated scaled
        .XADC_raw          (XADC_raw),
        .XADC_averaged     (XADC_averaged),
        .XADC_scaled       (XADC_scaled),
        .PWM_raw           (PWM_raw),
        .PWM_averaged      (PWM_averaged),
        .PWM_scaled        (PWM_scaled_cal),   // <-- calibrated scaled
        .Menu_OUT          (Menu_OUT),
        .mode_select       (mode_select),
        .switches_inputs   (switches_inputs),
        .decimal_selection (decimal_selection),
        .decimal_pt        (decimal_pt)
    );

    //==========================================================
    // Binary to BCD Converter
    //==========================================================
    bin_to_bcd BIN_TO_BCD_inst (
        .clk               (clk),
        .reset             (reset),
        .bin_in            (Menu_OUT),
        .bcd_out           (BCD_OUT),
        .decimal_selection (decimal_selection)
    );

    //==========================================================
    // Seven-Segment Display Subsystem
    //==========================================================
    seven_segment_display_subsystem SEVEN_SEGMENT_DISPLAY_inst (
        .clk           (clk),
        .reset         (reset),
        .sec_dig1      (BCD_OUT[3:0]),
        .sec_dig2      (BCD_OUT[7:4]),
        .min_dig1      (BCD_OUT[11:8]),
        .min_dig2      (BCD_OUT[15:12]),
        .decimal_point (decimal_pt),
        .CA            (CA),
        .CB            (CB),
        .CC            (CC),
        .CD            (CD),
        .CE            (CE),
        .CF            (CF),
        .CG            (CG),
        .DP            (DP),
        .AN1           (AN1),
        .AN2           (AN2),
        .AN3           (AN3),
        .AN4           (AN4)
    );

endmodule
