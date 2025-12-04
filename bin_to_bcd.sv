module bin_to_bcd(
    input  logic [15:0] bin_in,
    output logic [15:0] bcd_out,
    input  logic clk,
    input  logic reset,
    input  logic decimal_selection
);

    logic [31:0] scratch, next_scratch;
    logic [4:0]  clkcnt, next_clkcnt;
    logic        ready, next_ready,overflow_error;
    logic [15:0] next_bcd_out;
    logic [7:0]  bypass_out;  // New signal for direct passthrough

    always_ff @(posedge clk) begin
        if (reset) begin
            scratch <= '0;
            bcd_out <= '0;
            ready   <= 1'b1;
            clkcnt  <= '0;
        end else begin
            // If select is low, pass through input
            scratch <= next_scratch;
            bcd_out <= decimal_selection ? next_bcd_out : bin_in;
            ready   <= next_ready;
            clkcnt  <= next_clkcnt;
        end
    end

    always_comb begin
        next_scratch = scratch;
        next_bcd_out = bcd_out;
        next_ready   = ready;
        next_clkcnt  = clkcnt;

        // If select is low, prevent conversion logic
        if (!decimal_selection) begin
            next_scratch = '0;
            next_bcd_out = bin_in;
            next_ready   = 1'b1;
            next_clkcnt  = '0;
            overflow_error = 0;
        end else begin
            if (bin_in > 9999) begin
                next_bcd_out = 16'hEEEE;
                overflow_error = 1;
                next_ready   = 1'b0;
                next_clkcnt  = '0;
                next_scratch = '0;
            end else begin
                overflow_error = 0;
                case (clkcnt)
                    5'd0: begin
                        next_scratch = {16'b0, bin_in};
                        next_clkcnt = clkcnt + 1;
                        next_ready = 1'b0;
                    end
                    5'd1, 5'd2, 5'd3, 5'd4, 5'd5, 5'd6, 5'd7, 5'd8, 5'd9, 5'd10, 5'd11, 5'd12, 5'd13, 5'd14, 5'd15, 5'd16: begin
                        // Add 3 to columns >= 5
                        if (next_scratch[31:28] >= 5) next_scratch[31:28] = next_scratch[31:28] + 3;
                        if (next_scratch[27:24] >= 5) next_scratch[27:24] = next_scratch[27:24] + 3;
                        if (next_scratch[23:20] >= 5) next_scratch[23:20] = next_scratch[23:20] + 3;
                        if (next_scratch[19:16] >= 5) next_scratch[19:16] = next_scratch[19:16] + 3;
                        
                        // Shift left
                        next_scratch = {next_scratch[30:0], 1'b0};
                        next_clkcnt = clkcnt + 1;
                    end
                    5'd17: begin
                        next_bcd_out = next_scratch[31:16];
                        next_ready = 1'b1;
                        next_clkcnt = '0;
                    end
                    default: begin
                        next_clkcnt = '0;
                    end
                endcase
            end
        end
    end

endmodule