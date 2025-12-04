`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// cal_button_pulse.sv
// -----------------------------------------------------------------------------
// - Synchronizes an asynchronous pushbutton to clk
// - Generates a clean 1-clock-wide pulse on each rising edge
//////////////////////////////////////////////////////////////////////////////////

module cal_button_pulse(
    input  logic clk,
    input  logic reset,
    input  logic btn_in,       // raw pushbutton (e.g. BTNU)
    output logic pulse_out     // 1-clock pulse when button goes 0->1
);

    logic sync0, sync1, prev;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sync0 <= 1'b0;
            sync1 <= 1'b0;
            prev  <= 1'b0;
        end else begin
            sync0 <= btn_in;   // async → sync stage 1
            sync1 <= sync0;    // sync stage 2
            prev  <= sync1;    // store previous value
        end
    end

    // Rising edge detector
    assign pulse_out = sync1 & ~prev;

endmodule
