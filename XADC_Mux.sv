//==============================================================
// XADC_Data_mux
// -------------------------------------------------------------
// Purpose:
//   Selects which version of the XADC measurement data is output
//   to the display or processing system based on the 2-bit
//   data_select input.
//
// Functionality:
//   data_select = 00 → Output zeros (blank display)
//   data_select = 01 → Output raw 12-bit XADC data (zero-extended to 16 bits)
//   data_select = 10 → Output 16-bit averaged XADC data
//   data_select = 11 → Output 16-bit scaled XADC data
//
// Notes:
//   - Zero-extension ensures all outputs have a consistent 16-bit width.
//   - Used by the Menu_Subsystem to route selected XADC data
//     (RAW / AVERAGED / SCALED) to the display subsystem.
//==============================================================
module XADC_Data_mux(
    input  logic [1:0]  data_select,      // Selects RAW / AVG / SCALED
    input  logic [11:0] xadc_raw,         // 12-bit raw XADC data
    input  logic [15:0] xadc_averaged,    // 16-bit averaged XADC data
    input  logic [15:0] xadc_scaled,      // 16-bit scaled XADC data
    output logic [15:0] xadc_measurment   // 16-bit selected XADC output
);
    
    //==========================================================
    // Data selection logic
    // ---------------------------------------------------------
    // Selects between the available XADC data representations.
    //==========================================================
    always_comb begin
        case (data_select)
            2'b00: xadc_measurment = 16'b0000_0000_0000_0000; // OFF / blank
            2'b01: xadc_measurment = {4'b0000, xadc_raw};     // RAW (12 → 16 bits)
            2'b10: xadc_measurment = xadc_averaged;           // AVERAGED (16 bits)
            2'b11: xadc_measurment = xadc_scaled;             // SCALED (16 bits)
            default: xadc_measurment = 16'b0000_0000_0000_0000; // Default safe output
        endcase
    end        

endmodule
