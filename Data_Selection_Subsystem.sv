//==============================================================
// Menu_Subsystem
// -------------------------------------------------------------
// Purpose:
//   Central menu / data-selection block for the display system.
//
// Responsibilities:
//   - Receives raw / averaged / scaled data from:
//       * XADC
//       * PWM-based ADC
//       * R2R-based ADC
//   - Uses mode_select to:
//       * Choose which source to display (XADC / PWM / R2R)
//       * Choose which data type to display (RAW / AVERAGED / SCALED)
//   - Implements decimal point control based on:
//       * Selected data type
//       * decimal_selection pushbutton
//   - Passes switch values through a small helper block.
//   - Drives decimal_pt outputs for the 7-segment subsystem.
//
// Notes:
//   - Menu_OUT is the 16-bit value that will be sent to the
//     BIN→BCD converter in the top-level design.
//   - output_mode_fsm, *_Data_mux modules, Data_Selecting_Mux,
//     and switch_logic are assumed to be defined somewhere else.
//==============================================================
module Menu_Subsystem(
    input  logic        clk,
    input  logic        reset,
    
    // ----------------------
    // XADC measurements
    // ----------------------
    input  logic [11:0] XADC_raw,        // 12-bit raw XADC code
    input  logic [15:0] XADC_averaged,   // 16-bit averaged XADC value
    input  logic [15:0] XADC_scaled,     // 16-bit scaled XADC value (e.g., mV)
    
    // ----------------------
    // PWM measurements
    // ----------------------
    input  logic [7:0]  PWM_raw,         // 8-bit raw PWM-based ADC code
    input  logic [11:0] PWM_averaged,    // 12-bit averaged PWM-based value
    input  logic [11:0] PWM_scaled,      // 12-bit scaled PWM-based value
    
    // ----------------------
    // R2R measurements
    // ----------------------
    input  logic [7:0]  R2R_raw,         // 8-bit raw R2R-based ADC code
    input  logic [11:0] R2R_averaged,    // 12-bit averaged R2R-based value
    input  logic [11:0] R2R_scaled,      // 12-bit scaled R2R-based value
    
    // ----------------------
    // Output to BIN→BCD
    // ----------------------
    output logic [15:0] Menu_OUT,        // Selected 16-bit value to display
    
    // ----------------------
    // Mode / UI controls
    // ----------------------
    input  logic [3:0]  mode_select,     // Menu mode / display selection
    input  logic [11:0] switches_inputs, // 12-bit slide switches
    input  logic        decimal_selection, // Pushbutton to enable decimal point
    output logic [3:0]  decimal_pt       // Per-digit decimal point control
);

    //==========================================================
    // Internal control signals from FSM
    //==========================================================
    logic [1:0] display_source;          // Source select: XADC / PWM / R2R
    logic [1:0] display_data;            // Data type: RAW / AVG / SCALED
    logic       zero_enable;             // Additional control from FSM (usage external)

    //==========================================================
    // Internal data signals
    //==========================================================
    logic [15:0] xadc_measurment;        // Selected XADC measurement (width 16)
    logic [11:0] pwm_measurment;         // Selected PWM measurement  (width 12)
    logic [11:0] r2r_measurment;         // Selected R2R measurement  (width 12)
    logic [15:0] mux_selected_data;      // Combined/selected data from source MUX
    logic [11:0] switches_value;         // Processed switch value

    logic        decimal_pt_en;          // Enables decimal point under certain conditions

    //==========================================================
    // Mode decode FSM
    // ---------------------------------------------------------
    // output_mode_fsm:
    //   - Interprets mode_select and generates:
    //       * display_source : XADC / PWM / R2R
    //       * display_data   : RAW / AVERAGED / SCALED
    //       * zero_enable    : extra control (e.g., zeroing / offset)
    //==========================================================
    output_mode_fsm Menu_Module (
        .clk            (clk),
        .reset          (reset),
        .mode_select    (mode_select),
        .display_source (display_source),
        .display_data   (display_data),
        .zero_enable    (zero_enable)
    );   

    //==========================================================
    // PWM data selection (RAW / AVERAGED / SCALED)
    // ---------------------------------------------------------
    // PWM_Data_mux:
    //   - Selects which PWM measurement is used based on display_data
    //==========================================================
    PWM_Data_mux PWM_mux (
        .data_select     (display_data),
        .pwm_raw         (PWM_raw),
        .pwm_averaged    (PWM_averaged),
        .pwm_scaled      (PWM_scaled),
        .pwm_measurment  (pwm_measurment)
    );

    //==========================================================
    // XADC data selection (RAW / AVERAGED / SCALED)
    // ---------------------------------------------------------
    // XADC_Data_mux:
    //   - Selects which XADC measurement is used based on display_data
    //==========================================================
    XADC_Data_mux XADC_mux (
        .data_select      (display_data),
        .xadc_raw         (XADC_raw),
        .xadc_averaged    (XADC_averaged),
        .xadc_scaled      (XADC_scaled),
        .xadc_measurment  (xadc_measurment)
    );            
    
    //==========================================================
    // R2R data selection (RAW / AVERAGED / SCALED)
    // ---------------------------------------------------------
    // R2R_Data_mux:
    //   - Selects which R2R measurement is used based on display_data
    //==========================================================
    R2R_Data_mux R2R_mux (
        .data_select     (display_data),
        .R2R_raw         (R2R_raw),
        .R2R_averaged    (R2R_averaged),
        .R2R_scaled      (R2R_scaled),
        .r2r_measurment  (r2r_measurment)
    );                
    
    //==========================================================
    // Source selection: XADC / PWM / R2R
    // ---------------------------------------------------------
    // Data_Selecting_Mux:
    //   - Chooses which subsystem's measurement is sent forward
    //     based on display_source.
    //   - Produces a unified 16-bit mux_selected_data signal.
    //==========================================================
    Data_Selecting_Mux Data_output_mux (
        .source_select   (display_source),
        .xadc_measurment (xadc_measurment),
        .pwm_measurment  (pwm_measurment),
        .r2r_measurment  (r2r_measurment),
        .selected_data   (mux_selected_data)
    );    

    //==========================================================
    // Simple switch passthrough
    // ---------------------------------------------------------
    // switch_logic:
    //   - Maps 12-bit switches_inputs to switches_value for use
    //     elsewhere in the menu system or top-level logic.
    //==========================================================
    switch_logic SWITCHES (
        .switches_inputs  (switches_inputs),
        .switches_outputs (switches_value)
    );
    
    //==========================================================
    // Decimal point control
    // ---------------------------------------------------------
    // decimal_pt_en:
    //   - Active when displaying SCALED data (e.g., in mV or V)
    //     AND when decimal_selection pushbutton is asserted.
    //
    // decimal_pt:
    //   - When enabled, activates a single decimal point pattern
    //     (here 4'b1000) on the 4-digit 7-seg display.
    //==========================================================
    assign decimal_pt_en = (display_data[1] & display_data[0]) & decimal_selection;
    assign Menu_OUT = mux_selected_data;
    always_ff @(posedge clk) begin
        if (reset) begin
            decimal_pt <= 4'b0000;
        end else if (decimal_pt_en) begin
            decimal_pt <= 4'b1000;
        end else begin
            decimal_pt <= 4'b0000;
        end
    end        

    //==========================================================
    // Menu_OUT
    // ---------------------------------------------------------
    // NOTE:
    //   Menu_OUT should be driven by a combination of
    //   mux_selected_data, switches_value, and zero_enable
    //   according to the desired UI behavior.
    //
    //   The specific assignment is left to the surrounding
    //   design requirements and is not modified here.
    //==========================================================
    // (Intentionally left for integration logic elsewhere.)

endmodule
