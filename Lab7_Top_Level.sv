//==============================================================
// Lab7_Top_Level
// -------------------------------------------------------------
// Top-level integration for Lab 7:
//   - Interfaces with XADC, PWM ramp/SAR, and R2R ramp/SAR subsystems
//   - Selects which measurement to display via a menu FSM
//   - Converts selected data to BCD
//   - Drives the 4-digit seven-segment display
//==============================================================

module Lab7_Top_Level(

    // ----------------------
    // Clock & Reset
    // ----------------------
    input  logic        clk,                // System clock
    input  logic        reset,             // Active-high synchronous reset
    
    // ----------------------
    // Mode control / PWM
    // ----------------------
    input  logic [3:0]  mode_select,       // Menu selection / mode control for data display
    input  logic        compare1,          // Comparator output for PWM-based ADC (ramp/SAR)
    input  logic        compare2,          // Comparator output for R2R-based ADC (ramp/SAR)
    output logic        PWM_out,           // PWM output waveform
    output logic [7:0]  R2R_output,        // 8-bit R2R DAC output
    
    // ----------------------
    // User input controls
    // ----------------------
    input  logic        decimal_selection, // Pushbutton: controls BIN/BCD or decimal format behavior
    input  logic [11:0] switches_inputs,   // 12-bit slide switch input bus (includes SAR mode controls, etc.)
    
    // ----------------------
    // Seven-segment display outputs
    // ----------------------
    output logic        CA, CB, CC, CD, CE, CF, CG, DP,   // Segment outputs (active-low or active-high per board)
    output logic        AN1, AN2, AN3, AN4,               // Digit enable lines
    
    // ----------------------
    // XADC analog input ports (aux channel 15)
    // ----------------------
    input               vauxp15,          // XADC auxiliary positive input (channel 15)
    input               vauxn15           // XADC auxiliary negative input (channel 15)
);

    //==========================================================
    // Internal Signals
    //==========================================================

    // XADC measurement data (raw, averaged, scaled)
    logic [15:0] XADC_raw;                // Unprocessed raw XADC measurement
    logic [15:0] XADC_averaged;           // Averaged XADC measurement for noise reduction
    logic [15:0] XADC_scaled;             // XADC measurement scaled to engineering units / range

    // PWM ADC measurement data (raw, averaged, scaled)
    logic [15:0] PWM_raw;                 // Raw digital result from PWM-based ADC
    logic [15:0] PWM_averaged;            // Averaged PWM-based measurement
    logic [15:0] PWM_scaled;              // Scaled PWM-based measurement

    // R2R ADC measurement data (raw, averaged, scaled)
    logic [15:0] R2R_raw;                 // Raw digital result from R2R-based ADC
    logic [15:0] R2R_averaged;            // Averaged R2R-based measurement
    logic [15:0] R2R_scaled;              // Scaled R2R-based measurement

    // Selected data from menu subsystem to be displayed
    logic [15:0] Menu_OUT;                // 16-bit value routed to BIN-to-BCD + 7-seg

    // Decimal point control for each of the four 7-segment digits
    logic [3:0]  decimal_pt;              // Per-digit decimal point enables

    // BCD output of bin_to_bcd (4 digits × 4 bits = 16 bits)
    logic [15:0] BCD_OUT;                 // BCD representation of Menu_OUT

    // SAR mode controls (derived from slide switches)
    logic sar_mode_r2r;                   // SW0: R2R SAR enable (0 = ramp, 1 = SAR)
    logic sar_mode_pwm;                   // SW1: PWM SAR enable (0 = ramp, 1 = SAR)

    //==========================================================
    // Mode / SAR Control Assignments
    //==========================================================
    // Assign slide switches to SAR mode configuration.
    // Note: Only the least significant switches are used here; higher bits
    //       may be used by the menu subsystem or left for user expansion.
    assign sar_mode_r2r = switches_inputs[0];   // Rightmost switch: R2R SAR mode select
    assign sar_mode_pwm = switches_inputs[1];   // Next switch: PWM SAR mode select

    //==========================================================
    // PWM Subsystem (Ramp + SAR)
    // ---------------------------------------------------------
    // Implements:
    //   - Sawtooth (ramp) generation
    //   - PWM-based ADC (ramp and SAR modes)
    //   - Outputs the PWM drive waveform and measurement results
    //==========================================================
    PWM_subsystem PWM_subsystem (
        .clk                      (clk),
        .reset                    (reset),
        .compare1                 (compare1),
        .sar_mode                 (sar_mode_pwm),           // 0 = Ramp, 1 = SAR
        .pwm_out                  (PWM_out),
        .sawtooth_ave_data        (PWM_averaged[11:0]),     // Averaged PWM data (12-bit subset)
        .sawtooth_scaled_adc_data (PWM_scaled[11:0]),       // Scaled PWM data (12-bit subset)
        .adc_value                (PWM_raw[7:0])            // Raw PWM data (8-bit subset)
    );
    
    //==========================================================
    // XADC Subsystem
    // ---------------------------------------------------------
    // Interfaces with the on-chip XADC block:
    //   - Samples the external analog input at vauxp15/vauxn15
    //   - Provides raw, averaged, and scaled 16-bit results
    //==========================================================
    XADC_Subsystem XADC_subsystem (
        .clk             (clk),
        .reset           (reset),
        .vauxp15         (vauxp15),
        .vauxn15         (vauxn15),
        .scaled_adc_data (XADC_scaled),
        .raw_data        (XADC_raw),
        .ave_data        (XADC_averaged)
    );   
    
    //==========================================================
    // R2R Subsystem (Ramp + SAR)
    // ---------------------------------------------------------
    // Implements:
    //   - R2R DAC driving ramp/SAR conversion
    //   - Comparator-based measurement using compare2
    //   - Outputs R2R DAC code, raw, averaged, and scaled results
    //==========================================================
    R2R_subsystem R2R_subsystem (
        .clk         (clk),
        .reset       (reset),
        .compare2    (compare2),
        .sar_mode    (sar_mode_r2r),            // 0 = Ramp, 1 = SAR
        .scaled_data (R2R_scaled[11:0]),        // Scaled R2R data (12-bit subset)
        .ave_data    (R2R_averaged[11:0]),      // Averaged R2R data (12-bit subset)
        .raw_data    (R2R_raw[7:0]),            // Raw R2R data (8-bit subset)
        .R2R_output  (R2R_output)               // 8-bit DAC output
    );
    
    //==========================================================
    // Data Selection (Menu) Subsystem
    // ---------------------------------------------------------
    // Central "router" for measurement data:
    //   - Receives raw/averaged/scaled values from:
    //       * R2R subsystem
    //       * XADC subsystem
    //       * PWM subsystem
    //   - Uses mode_select and switches_inputs to choose which
    //     signal is routed to Menu_OUT
    //   - Controls decimal point placement for the 7-seg display
    //==========================================================
    Menu_Subsystem Menu_Subsystem(
        .clk               (clk),
        .reset             (reset),
        
        .R2R_raw           (R2R_raw),
        .R2R_averaged      (R2R_averaged),
        .R2R_scaled        (R2R_scaled),
        
        .XADC_raw          (XADC_raw),
        .XADC_averaged     (XADC_averaged),
        .XADC_scaled       (XADC_scaled),
        
        .PWM_raw           (PWM_raw),
        .PWM_averaged      (PWM_averaged),
        .PWM_scaled        (PWM_scaled),
        
        .Menu_OUT          (Menu_OUT),
        .mode_select       (mode_select),
        .switches_inputs   (switches_inputs),
        
        .decimal_selection (decimal_selection),
        .decimal_pt        (decimal_pt)
    );    
    
    //==========================================================
    // Binary to BCD Converter
    // ---------------------------------------------------------
    // Converts the selected 16-bit binary value (Menu_OUT) into
    // four BCD digits for display.
    // decimal_selection may influence the conversion format
    // (e.g., integer vs. fixed-point style).
    //==========================================================
    bin_to_bcd BIN_TO_BCD_inst (
        .clk                (clk),
        .reset              (reset),
        .bin_in             (Menu_OUT),
        .bcd_out            (BCD_OUT),
        .decimal_selection  (decimal_selection)
    );
    
    //==========================================================
    // Seven-Segment Display Subsystem
    // ---------------------------------------------------------
    // Drives the 4-digit seven-segment display:
    //   - Multiplexes the digits
    //   - Accepts four BCD digits and per-digit decimal point
    //   - Generates segment and anode control signals
    //==========================================================
    seven_segment_display_subsystem SEVEN_SEGMENT_DISPLAY_inst (
        .clk            (clk), 
        .reset          (reset), 

        // BCD digits (least significant digit = sec_dig1)
        .sec_dig1       (BCD_OUT[3:0]),      // Least significant digit
        .sec_dig2       (BCD_OUT[7:4]),      // Second digit
        .min_dig1       (BCD_OUT[11:8]),     // Third digit
        .min_dig2       (BCD_OUT[15:12]),    // Most significant digit

        .decimal_point  (decimal_pt),        // Per-digit decimal point control

        // Seven-segment and digit enable outputs
        .CA             (CA),
        .CB             (CB),
        .CC             (CC),
        .CD             (CD), 
        .CE             (CE),
        .CF             (CF),
        .CG             (CG),
        .DP             (DP), 
        .AN1            (AN1),
        .AN2            (AN2),
        .AN3            (AN3),
        .AN4            (AN4)
    );

endmodule
