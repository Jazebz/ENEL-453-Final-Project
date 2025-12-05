//==============================================================
// R2R_Data_mux
// -------------------------------------------------------------
// Purpose:
//   Chooses which version of the R2R ladder ADC measurement is
//   forwarded to the display system, based on data_select.
//
// Functionality:
//   data_select = 00 → Output zeros (blank display)
//   data_select = 01 → Output raw 8-bit R2R data (zero-extended to 12 bits)
//   data_select = 10 → Output 12-bit averaged R2R data
//   data_select = 11 → Output 12-bit scaled R2R data
//
// Notes:
//   - Zero-extension ensures consistent 12-bit output width.
//   - Used in the Menu_Subsystem to route R2R ADC data
//     (RAW / AVERAGED / SCALED) to the display or BIN→BCD converter.
//==============================================================
module R2R_Data_mux(
    input  logic [1:0]  data_select,     // Select: RAW / AVG / SCALED
    input  logic [7:0]  R2R_raw,         // 8-bit raw R2R ADC code
    input  logic [11:0] R2R_averaged,    // 12-bit averaged value
    input  logic [11:0] R2R_scaled,      // 12-bit scaled value
    output logic [11:0] r2r_measurment   // 12-bit selected output
);
    
    //==========================================================
    // Data selection logic
    // ---------------------------------------------------------
    // Selects between the available R2R measurement values.
    //==========================================================
    always_comb begin
        case (data_select)
            2'b00: r2r_measurment = 12'b0000_0000_0000;  // OFF / blank
            2'b01: r2r_measurment = {4'b0000, R2R_raw};  // RAW (8-bit → 12-bit)
            2'b10: r2r_measurment = R2R_averaged;        // AVERAGED (12-bit)
            2'b11: r2r_measurment = R2R_scaled;          // SCALED (12-bit)
            default: r2r_measurment = 12'b0000_0000_0000; // Safe default
        endcase
    end        

endmodule
