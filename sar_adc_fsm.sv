//==============================================================
// r2r_sar_adc_simple.sv
// -------------------------------------------------------------
// Simple, slow, and stable N-bit SAR controller for an R2R ladder.
//
// Summary:
//   - Performs a successive-approximation (SAR) conversion using an
//     external comparator and R2R ladder DAC.
//   - Uses a clock divider to generate a slow SAR step rate.
//   - Waits SETTLE_TICKS ticks after each code update before sampling
//     the comparator, to allow analog settling.
//
// Parameters:
//   N_BITS        : Resolution of the SAR converter.
//   CLK_DIV       : Clock division factor to set SAR step rate.
//   SETTLE_TICKS  : Number of SAR ticks to wait after each DAC update.
//
// Assumptions:
//   - comp_in = 1 when Vin > Vdac
//   - dac_code drives an external R2R ladder whose output is compared
//     to the input voltage Vin.
//==============================================================
module r2r_sar_adc_simple #(
    parameter int N_BITS       = 8,
    parameter int CLK_DIV      = 100_000, // 100 MHz / 100_000 ≈ 1 kHz SAR step
    parameter int SETTLE_TICKS = 2        // Number of slow ticks to wait after code change
)(
    input  logic                 clk,
    input  logic                 reset,
    input  logic                 enable,      // 1 = run conversions when SAR "tick" occurs

    // Analog comparator input:
    //   comp_in = 1 when Vin > Vdac (i.e., input is above DAC output)
    input  logic                 comp_in,

    // Digital codes:
    //   dac_code : current trial code driving the R2R ladder
    //   adc_code : final, stable conversion result
    output logic [N_BITS-1:0]    dac_code,
    output logic [N_BITS-1:0]    adc_code
);

    //==========================================================
    // Clock Divider: Generate Slow SAR Tick
    // ---------------------------------------------------------
    // Produces a single-cycle 'tick' pulse at a rate of:
    //   f_tick = f_clk / CLK_DIV
    // The SAR state machine advances only on this 'tick'.
    //==========================================================
    logic [$clog2(CLK_DIV)-1:0] div_cnt;
    logic                       tick;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            div_cnt <= '0;
            tick    <= 1'b0;
        end else begin
            if (div_cnt == CLK_DIV-1) begin
                div_cnt <= '0;
                tick    <= 1'b1;
            end else begin
                div_cnt <= div_cnt + 1;
                tick    <= 1'b0;
            end
        end
    end

    //==========================================================
    // SAR State Machine
    // ---------------------------------------------------------
    // States:
    //   S_IDLE         : Wait for 'enable' to start conversion
    //   S_INIT         : Initialize trial code and bit index
    //   S_SET_BIT      : Set current bit = 1 and start settle wait
    //   S_WAIT_SETTLE  : Wait SETTLE_TICKS SAR ticks for analog to settle
    //   S_SAMPLE       : Read comparator and keep/clear current bit
    //   S_DONE         : Hold result, then optionally start next conversion
    //==========================================================
    typedef enum logic [2:0] {
        S_IDLE,
        S_INIT,
        S_SET_BIT,
        S_WAIT_SETTLE,
        S_SAMPLE,
        S_DONE
    } sar_state_t;

    sar_state_t state;

    // Trial and result codes
    logic [N_BITS-1:0] trial_code;   // Current SAR trial code driving the DAC
    logic [N_BITS-1:0] result_code;  // Latched final conversion result

    // Bit index and settle counter
    logic [$clog2(N_BITS)-1:0]       bit_index;   // Bit currently under test
    logic [$clog2(SETTLE_TICKS)-1:0] settle_cnt;  // Counts slow ticks for analog settling

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state       <= S_IDLE;
            trial_code  <= '0;
            result_code <= '0;
            bit_index   <= '0;
            settle_cnt  <= '0;
        end else begin
            // Advance SAR only on the slow 'tick'
            if (tick) begin
                case (state)
                    //--------------------------------------------------
                    // Idle: wait for enable to start a conversion
                    //--------------------------------------------------
                    S_IDLE: begin
                        if (enable) begin
                            state <= S_INIT;
                        end
                    end

                    //--------------------------------------------------
                    // Initialize trial code and bit index
                    //--------------------------------------------------
                    S_INIT: begin
                        trial_code <= '0;
                        bit_index  <= N_BITS-1;  // Start from MSB
                        settle_cnt <= '0;
                        state      <= S_SET_BIT;
                    end

                    //--------------------------------------------------
                    // Set current bit to 1 and begin settle wait
                    //--------------------------------------------------
                    S_SET_BIT: begin
                        trial_code[bit_index] <= 1'b1;
                        settle_cnt            <= '0;
                        state                 <= S_WAIT_SETTLE;
                    end

                    //--------------------------------------------------
                    // Wait SETTLE_TICKS ticks for analog to settle
                    //--------------------------------------------------
                    S_WAIT_SETTLE: begin
                        if (settle_cnt == SETTLE_TICKS-1) begin
                            state <= S_SAMPLE;
                        end else begin
                            settle_cnt <= settle_cnt + 1;
                        end
                    end

                    //--------------------------------------------------
                    // Sample comparator and decide bit value
                    //--------------------------------------------------
                    S_SAMPLE: begin
                        // If Vin <= Vdac, clear this bit; otherwise keep it at 1
                        if (!comp_in) begin
                            trial_code[bit_index] <= 1'b0;
                        end

                        if (bit_index == 0) begin
                            // Finished LSB: latch final result
                            result_code <= trial_code;
                            state       <= S_DONE;
                        end else begin
                            bit_index <= bit_index - 1;
                            state     <= S_SET_BIT;   // Test next lower bit
                        end
                    end

                    //--------------------------------------------------
                    // Done: hold result; optionally start a new conversion
                    //--------------------------------------------------
                    S_DONE: begin
                        if (enable) begin
                            // Continuous conversions while enabled
                            state <= S_INIT;
                        end else begin
                            // Wait in IDLE if not enabled
                            state <= S_IDLE;
                        end
                    end

                    default: state <= S_IDLE;
                endcase
            end
        end
    end

    //==========================================================
    // Outputs
    // ---------------------------------------------------------
    // dac_code : Drives the external R2R ladder (current trial code)
    // adc_code : Stable converted result, held until next conversion
    //==========================================================
    assign dac_code = trial_code;
    assign adc_code = result_code;

endmodule
