module downcounter_waveform #(
    parameter int PERIOD = 1000     // Downcount start value (>0)
)(
    input  logic clk,
    input  logic reset,
    input  logic enable,
    output logic zero               // High for 1 cycle when count hits zero
);

    localparam int COUNT_WIDTH = $clog2(PERIOD);
    logic [COUNT_WIDTH-1:0] count;

    always_ff @(posedge clk) begin
        if (reset) begin
            count <= PERIOD - 1;
            zero  <= 0;
        end else if (enable) begin
            if (count == 0) begin
                count <= PERIOD - 1;
                zero  <= 1;
            end else begin
                count <= count - 1;
                zero  <= 0;
            end
        end else begin
            zero <= 0;
        end
    end

endmodule
