
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// auto_cal.sv  (scaled-domain calibration)
// -----------------------------------------------------------------------------
// Automatic offset calibration using XADC as reference, in the same numeric
// domain as your displayed values (e.g., mV).
//
// Behaviour:
//   - On a 1-clock cal_trig pulse, capture:
//         offset = xadc_scaled - adc_scaled
//   - On every cycle, output = adc_scaled + offset, with saturation.
//   - cal_switch = 0 -> output is raw adc_scaled
//                 1 -> output is calibrated (adc_scaled + offset)
//
// This way, if you calibrate while both paths see the same input, their
// *scaled* values will match closely when cal_switch = 1.
//
//////////////////////////////////////////////////////////////////////////////////

module auto_cal #(
    parameter int WIDTH = 16
)(
    input  logic                 clk,
    input  logic                 reset,

    // 1-clock-wide pulse to capture / update the offset
    input  logic                 cal_trig,

    // 1 = show calibrated, 0 = show raw
    input  logic                 cal_switch,

    // Measurements in the same numeric domain (e.g., mV)
    input  logic [WIDTH-1:0]     xadc_scaled,   // trusted XADC (scaled)
    input  logic [WIDTH-1:0]     adc_scaled,    // discrete ADC (scaled)

    // Output towards display / menu
    output logic [WIDTH-1:0]     display_code
);

    // Signed offset (one extra bit)
    logic signed [WIDTH:0] offset_reg;

    //==================================================================
    // 1) Capture / update offset when cal_trig is asserted
    //==================================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            offset_reg <= '0;
        end else if (cal_trig) begin
            // offset = XADC_scaled - ADC_scaled (both in same units)
            offset_reg <=
                $signed({1'b0, xadc_scaled}) -
                $signed({1'b0, adc_scaled});
        end
    end

    //==================================================================
    // 2) Apply offset with simple saturation
    //==================================================================
    logic signed [WIDTH:0] adc_ext;
    logic signed [WIDTH:0] sum;
    logic [WIDTH-1:0]      cal_data;

    always_comb begin
        adc_ext = $signed({1'b0, adc_scaled});  // extend
        sum     = adc_ext + offset_reg;         // apply offset

        // Saturate to 0 .. (2^WIDTH - 1)
        if (sum <= 0)
            cal_data = '0;
        else if (sum >= $signed({1'b0, {WIDTH{1'b1}}}))
            cal_data = {WIDTH{1'b1}};
        else
            cal_data = sum[WIDTH-1:0];
    end

    //==================================================================
    // 3) Choose raw vs calibrated for output
    //==================================================================
    always_comb begin
        if (cal_switch)
            display_code = cal_data;   // calibrated
        else
            display_code = adc_scaled; // raw
    end

endmodule
