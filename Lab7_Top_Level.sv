`timescale 1ns / 1ps

//==============================================================
// Lab7_Top_Level
// -------------------------------------------------------------
// - XADC, PWM ADC, R2R ADC (ramp/SAR)
// - Auto-calibration for PWM_scaled + R2R_scaled vs XADC_scaled
// - Menu + BCD + seven-seg
// - Top level only has wiring + module instantiations
//   (no synchronizer logic here; it's in cal_button_pulse.sv)
//==============================================================
module Lab7_Top_Level(
    // Clock & reset
    input  logic        clk,
    input  logic        reset,

    // Mode control / comparators
    input  logic [3:0]  mode_select,
    input  logic        compare1,
    input  logic        compare2,
    output logic        PWM_out,
    output logic [7:0]  R2R_output,

    // User controls
    input  logic        decimal_selection,
    input  logic [11:0] switches_inputs,

    // Calibration controls
    input  logic        cal_button,   // BTNU
    input  logic        cal_switch,   // SW2

    // Seven-seg outputs
    output logic CA, CB, CC, CD, CE, CF, CG, DP,
    output logic AN1, AN2, AN3, AN4,

    // XADC analog pins
    input  logic        vauxp15,
    input  logic        vauxn15
);

    //==========================================================
    // Clocking Wizard / PLL
    // - Input:  100 MHz board clock (clk)
    // - Output: faster single system clock (clk_sys)
    // - locked: indicates PLL has achieved lock
    //==========================================================
    logic clk_sys;      // fast system clock from PLL
    logic pll_locked;   // PLL lock indicator

    clk_wiz_0 u_clk_wiz (
        .clk_in1 (clk),        // 100 MHz from board
        .reset   (reset),      // same reset as rest of system (OK for lab)
        .clk_out1(clk_sys),    // e.g. 125 MHz or 133 MHz
        .locked  (pll_locked)
    );

    //==========================================================
    // Internal signals
    //==========================================================
    // XADC
    logic [15:0] XADC_raw;
    logic [15:0] XADC_averaged;
    logic [15:0] XADC_scaled;

    // PWM ADC
    logic [7:0]  PWM_raw_8;
    logic [15:0] PWM_raw;
    logic [11:0] PWM_ave_core;
    logic [15:0] PWM_averaged;
    logic [11:0] PWM_scaled_core;
    logic [15:0] PWM_scaled_raw;
    logic [15:0] PWM_scaled_cal;

    // R2R ADC
    logic [7:0]  R2R_raw_8;
    logic [15:0] R2R_raw;
    logic [11:0] R2R_ave_core;
    logic [15:0] R2R_averaged;
    logic [11:0] R2R_scaled_core;
    logic [15:0] R2R_scaled_raw;
    logic [15:0] R2R_scaled_cal;

    // Calibration pulse
    logic        cal_trig_pulse;

    // Menu & BCD
    logic [15:0] Menu_OUT;
    logic [15:0] BCD_OUT;
    logic [3:0]  decimal_pt;

    // SAR mode control
    logic        sar_mode_r2r;
    logic        sar_mode_pwm;

    //==========================================================
    // Mode / SAR control
    //==========================================================
    assign sar_mode_r2r = switches_inputs[0]; // SW0
    assign sar_mode_pwm = switches_inputs[1]; // SW1

    //==========================================================
    // Calibration button pulse (sync + edge detect)
    //==========================================================
    cal_button_pulse cal_btn_inst (
        .clk       (clk_sys),
        .reset     (reset),
        .btn_in    (cal_button),
        .pulse_out (cal_trig_pulse)
    );

    //==========================================================
    // PWM Subsystem
    //==========================================================
    PWM_subsystem PWM_subsystem_inst (
        .clk                      (clk_sys),
        .reset                    (reset),
        .compare1                 (compare1),
        .sar_mode                 (sar_mode_pwm),        // 0 = Ramp, 1 = SAR
        .pwm_out                  (PWM_out),
        .sawtooth_ave_data        (PWM_ave_core),        // 12-bit average
        .sawtooth_scaled_adc_data (PWM_scaled_core),     // 12-bit scaled
        .adc_value                (PWM_raw_8)            // 8-bit raw
    );

    // Simple zero-extend in top level (no extender modules)
    assign PWM_raw[7:0]   = PWM_raw_8;
    assign PWM_raw[15:8]  = 8'd0;

    assign PWM_averaged   = {4'd0, PWM_ave_core};   // 12 -> 16
    assign PWM_scaled_raw = {4'd0, PWM_scaled_core}; // 12 -> 16

    //==========================================================
    // XADC Subsystem
    //==========================================================
    XADC_Subsystem XADC_subsystem_inst (
        .clk             (clk_sys),
        .reset           (reset),
        .vauxp15         (vauxp15),
        .vauxn15         (vauxn15),
        .scaled_adc_data (XADC_scaled),
        .raw_data        (XADC_raw),
        .ave_data        (XADC_averaged)
    );

    //==========================================================
    // R2R Subsystem
    //==========================================================
    R2R_subsystem R2R_subsystem_inst (
        .clk         (clk_sys),
        .reset       (reset),
        .compare2    (compare2),
        .sar_mode    (sar_mode_r2r),       // 0 = Ramp, 1 = SAR
        .scaled_data (R2R_scaled_core),    // 12-bit scaled
        .ave_data    (R2R_ave_core),       // 12-bit average
        .raw_data    (R2R_raw_8),          // 8-bit raw
        .R2R_output  (R2R_output)
    );

    assign R2R_raw[7:0]   = R2R_raw_8;
    assign R2R_raw[15:8]  = 8'd0;

    assign R2R_averaged   = {4'd0, R2R_ave_core};   // 12 -> 16
    assign R2R_scaled_raw = {4'd0, R2R_scaled_core}; // 12 -> 16

    //==========================================================
    // Auto-calibration (scaled-domain) for PWM & R2R
    //==========================================================
    auto_cal #(
        .WIDTH(16)
    ) PWM_auto_cal (
        .clk          (clk_sys),
        .reset        (reset),
        .cal_trig     (cal_trig_pulse),
        .cal_switch   (cal_switch),
        .xadc_scaled  (XADC_scaled),
        .adc_scaled   (PWM_scaled_raw),
        .display_code (PWM_scaled_cal)
    );

    auto_cal #(
        .WIDTH(16)
    ) R2R_auto_cal (
        .clk          (clk_sys),
        .reset        (reset),
        .cal_trig     (cal_trig_pulse),
        .cal_switch   (cal_switch),
        .xadc_scaled  (XADC_scaled),
        .adc_scaled   (R2R_scaled_raw),
        .display_code (R2R_scaled_cal)
    );

    //==========================================================
    // Menu / Data Selection Subsystem
    //==========================================================
    Menu_Subsystem Menu_Subsystem_inst (
        .clk               (clk_sys),
        .reset             (reset),
        .R2R_raw           (R2R_raw),
        .R2R_averaged      (R2R_averaged),
        .R2R_scaled        (R2R_scaled_cal),   // calibrated when cal_switch=1
        .XADC_raw          (XADC_raw),
        .XADC_averaged     (XADC_averaged),
        .XADC_scaled       (XADC_scaled),
        .PWM_raw           (PWM_raw),
        .PWM_averaged      (PWM_averaged),
        .PWM_scaled        (PWM_scaled_cal),   // calibrated when cal_switch=1
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
        .clk               (clk_sys),
        .reset             (reset),
        .bin_in            (Menu_OUT),
        .bcd_out           (BCD_OUT),
        .decimal_selection (decimal_selection)
    );

    //==========================================================
    // Seven-Segment Display Subsystem 
    //==========================================================
    seven_segment_display_subsystem SEVEN_SEGMENT_DISPLAY_inst (
        .clk           (clk_sys),
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
