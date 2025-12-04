//==============================================================
// output_mode_fsm
// -------------------------------------------------------------
// Purpose:
//   Decodes the 4-bit mode_select input into:
//     - display_source : which subsystem to display (XADC / PWM / R2R)
//     - display_data   : which data type to display (RAW / AVG / SCALED)
//     - zero_enable    : used to blank / zero the display in OFF mode
//
// Behaviour:
//   - The FSM state encoding mirrors the mode_select codes directly.
//   - current_state simply tracks the requested mode_select value.
//   - Outputs are purely combinational functions of current_state.
//
// Mode Encoding (mode_select / current_state):
//   OFF_MODE : 0000  -> zero_enable = 1
//
//   XADC_RAW : 0001  -> display_source = XADC, display_data = RAW
//   XADC_AVG : 0010  -> display_source = XADC, display_data = AVG
//   XADC_SCL : 0011  -> display_source = XADC, display_data = SCALED
//
//   PWM_RAW  : 0101  -> display_source = PWM,  display_data = RAW
//   PWM_AVG  : 0110  -> display_source = PWM,  display_data = AVG
//   PWM_SCL  : 0111  -> display_source = PWM,  display_data = SCALED
//
//   R2R_RAW  : 1001  -> display_source = R2R,  display_data = RAW
//   R2R_AVG  : 1010  -> display_source = R2R,  display_data = AVG
//   R2R_SCL  : 1011  -> display_source = R2R,  display_data = SCALED
//==============================================================
module output_mode_fsm (
    input  logic       clk,
    input  logic       reset,
    input  logic [3:0] mode_select,     // 4-bit mode selection input

    output logic [1:0] display_source,  // Selects XADC / PWM / R2R
    output logic [1:0] display_data,    // Selects RAW / AVG / SCALED
    output logic       zero_enable      // Enables "zero" / blank display in OFF mode
);

    //==========================================================
    // State encoding (mirrors mode_select codes)
    // ---------------------------------------------------------
    // The enum values are chosen to match the 4-bit mode_select
    // directly, so the next-state logic can simply cast the
    // mode_select into statetype.
    //==========================================================
    typedef enum logic [3:0] {
        OFF_MODE = 4'b0000,
        
        XADC_RAW = 4'b0001,
        XADC_AVG = 4'b0010,
        XADC_SCL = 4'b0011,
        
        PWM_RAW  = 4'b0101,
        PWM_AVG  = 4'b0110,
        PWM_SCL  = 4'b0111,
         
        R2R_RAW  = 4'b1001,
        R2R_AVG  = 4'b1010,
        R2R_SCL  = 4'b1011
        
    } statetype;

    statetype current_state, next_state;

    //==========================================================
    // State register
    // ---------------------------------------------------------
    // Synchronous state update with asynchronous reset.
    //==========================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= OFF_MODE;
        else
            current_state <= next_state;
    end

    //==========================================================
    // Next-state logic
    // ---------------------------------------------------------
    // Directly follow the externally provided mode_select:
    //   - This effectively makes the FSM "mode-driven" rather
    //     than internally sequenced.
    //==========================================================
    always_comb begin
        next_state = statetype'(mode_select);
    end

    //==========================================================
    // Output decode logic
    // ---------------------------------------------------------
    // Based on current_state, determine:
    //   - display_source (XADC / PWM / R2R)
    //   - display_data   (RAW / AVG / SCALED)
    //   - zero_enable    (for OFF / invalid states)
//==========================================================
    always_comb begin
        // Default outputs
        display_source = 2'b00;
        display_data   = 2'b00;
        zero_enable    = 1'b0;
        
        case (current_state)
            OFF_MODE: begin
                zero_enable = 1'b1;
            end
            
            // XADC display modes
            XADC_RAW: begin
                display_source = 2'b00;
                display_data   = 2'b01;
            end  
            XADC_AVG: begin
                display_source = 2'b00;
                display_data   = 2'b10;
            end  
            XADC_SCL: begin
                display_source = 2'b00;
                display_data   = 2'b11;
            end  
            
            // PWM display modes
            PWM_RAW: begin
                display_source = 2'b01;
                display_data   = 2'b01;
            end  
            PWM_AVG: begin
                display_source = 2'b01;
                display_data   = 2'b10;
            end  
            PWM_SCL: begin
                display_source = 2'b01;
                display_data   = 2'b11;
            end  
                                                  
            // R2R display modes
            R2R_RAW: begin
                display_source = 2'b10;
                display_data   = 2'b01;
            end  
            R2R_AVG: begin
                display_source = 2'b10;
                display_data   = 2'b10;
            end  
            R2R_SCL: begin
                display_source = 2'b10;
                display_data   = 2'b11;
            end                                                                       
            
            // Any undefined state -> treat as OFF
            default: begin
                zero_enable = 1'b1;
            end
        endcase
    end

endmodule
