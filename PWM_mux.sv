//==============================================================
// PWM_Data_mux
// -------------------------------------------------------------
// Purpose:
//   Selects which version of the PWM-based ADC data is output
//   to the display system based on the 2-bit data_select input.
//
// Functionality:
//   data_select = 00 → Output zeros (blank display)
//   data_select = 01 → Output raw 8-bit PWM data (zero-extended to 12 bits)
//   data_select = 10 → Output 12-bit averaged PWM data
//   data_select = 11 → Output 12-bit scaled PWM data
//
// Notes:
//   - Zero-extension ensures consistent 12-bit output width.
//   - Used by Menu_Subsystem to route selected PWM measurement
//     (RAW / AVERAGED / SCALED) to the display subsystem.
//==============================================================
module PWM_Data_mux(
    input  logic [1:0]  data_select,     // 2-bit select: RAW / AVG / SCALED
    input  logic [7:0]  pwm_raw,         // Raw 8-bit PWM ADC result
    input  logic [11:0] pwm_averaged,    // 12-bit averaged PWM result
    input  logic [11:0] pwm_scaled,      // 12-bit scaled PWM result
    output logic [11:0] pwm_measurment   // Selected 12-bit output value
);
    
    //==========================================================
    // Data selection logic
    // ---------------------------------------------------------
    // Select which PWM signal to output based on data_select.
    //==========================================================
    always_comb begin
        case (data_select)
            2'b00: pwm_measurment = 12'b0000_0000_0000;          // OFF / blank
            2'b01: pwm_measurment = {4'b0000, pwm_raw};          // RAW (8-bit → 12-bit)
            2'b10: pwm_measurment = pwm_averaged;                // AVERAGED (12-bit)
            2'b11: pwm_measurment = pwm_scaled;                  // SCALED (12-bit)
            default: pwm_measurment = 12'b0000_0000_0000;        // Default safe output
        endcase
    end        

endmodule
