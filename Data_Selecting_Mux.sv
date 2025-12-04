//==============================================================
// Data_Selecting_Mux
// -------------------------------------------------------------
// Purpose:
//   Selects which measurement source (XADC / PWM / R2R) is
//   forwarded to the display or output subsystem.
// 
// Functionality:
//   source_select = 00 → Select XADC measurement (16-bit)
//   source_select = 01 → Select PWM measurement (12-bit → zero-extended to 16-bit)
//   source_select = 10 → Select R2R measurement (12-bit → zero-extended to 16-bit)
//   source_select = 11 → Output zeros (blank display)
//
// Notes:
//   - All outputs are standardized to 16 bits for uniform display handling.
//   - Used by Menu_Subsystem to route selected data to Menu_OUT.
//==============================================================
module Data_Selecting_Mux(
    input  logic [1:0]  source_select,     // Selects XADC / PWM / R2R
    input  logic [15:0] xadc_measurment,   // 16-bit XADC measurement
    input  logic [11:0] pwm_measurment,    // 12-bit PWM measurement
    input  logic [11:0] r2r_measurment,    // 12-bit R2R measurement
    output logic [15:0] selected_data      // Unified 16-bit output
);
    
    //==========================================================
    // Source selection logic
    // ---------------------------------------------------------
    // Chooses which subsystem's data is routed to output.
    //==========================================================
    always_comb begin
        case (source_select)
            2'b00: selected_data = xadc_measurment;                  // XADC
            2'b01: selected_data = {4'b0000, pwm_measurment};        // PWM (8→12→16 bits)
            2'b10: selected_data = {4'b0000, r2r_measurment};        // R2R (8→12→16 bits)
            2'b11: selected_data = 16'b0000_0000_0000_0000;          // OFF / blank
            default: selected_data = 16'b0000_0000_0000_0000;        // Safe default
        endcase
    end            

endmodule
