
module XADC_Subsystem #(
) (
    input  logic clk,
    input  logic reset,
    input  logic vauxp15,   // Analog input (positive) - JXAC4:N2 PMOD pin (XADC4)
    input  logic vauxn15,   // Analog input (negative) - JXAC10:N1 PMOD pin (XADC4)

    // Expose the same names your top level used:
    output logic        ready_pulse,        // 1-clk strobe derived from DRDY
    output logic [15:0] raw_data,               // raw XADC data (use [15:4] for 12-bit)
    output logic [15:0] ave_data,           // averaged ADC data (16-bit)
    output logic [15:0] scaled_adc_data
);

    // Internal signal declarations
    logic        ready;              // Data ready from XADC (DRDY)
    logic [6:0]  daddr_in;           // XADC address (localparam below)
    logic        enable;             // EOC -> DEN handshake
    logic        eos_out;            // End of sequence (unused)
    logic        busy_out;           // Busy (unused)
    logic        ready_r;            // for pulse edge detect

    // Constants
    localparam CHANNEL_ADDR = 7'h1f;     // XA4/AD15 (for XADC4)

    // XADC Instantiation
    xadc_wiz_0 XADC_INST (
        .di_in      (16'h0000),        // Not used for reading
        .daddr_in   (CHANNEL_ADDR),    // Channel address
        .den_in     (enable),          // Enable read on EOC
        .dwe_in     (1'b0),            // Not writing
        .drdy_out   (ready),           // Data ready pulse (valid DO)
        .do_out     (raw_data),            // ADC data output
        .dclk_in    (clk),             // System clock
        .reset_in   (reset),           // Active-high reset
        .vp_in      (1'b0),            // Not used
        .vn_in      (1'b0),            // Not used
        .vauxp15    (vauxp15),         // Aux analog input (positive)
        .vauxn15    (vauxn15),         // Aux analog input (negative)
        .channel_out(),                // Unused
        .eoc_out    (enable),          // End of conversion -> DEN
        .alarm_out  (),                // Unused
        .eos_out    (eos_out),         // Unused
        .busy_out   (busy_out)         // Unused
    );

    // ----- ready_pulse generation -----
    always_ff @(posedge clk) begin
        if (reset)
            ready_r <= 1'b0;
        else
            ready_r <= ready;
    end
    assign ready_pulse = ~ready_r & ready; // 1-clk pulse on DRDY rising edge

    // ----- Averager instantiation  -----
    averager  
    #( .power(8),   
       .N(16)        // # of bits to take the average of
     ) 
    AVERAGER
     ( .reset (reset),
       .clk   (clk),
       .EN    (ready_pulse),
       .Din   (raw_data),
       .Q     (ave_data)
     );

    // ----- Scaling  -----
    always_ff @(posedge clk) begin
        if (reset) begin
            scaled_adc_data <= 16'd0;
        end
        else if (ready_pulse) begin
            scaled_adc_data <= (ave_data * 415) >> 13;
        end
    end

endmodule
