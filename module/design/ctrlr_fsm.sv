////////////////////////////////////////////////////////
// Module: Controller FSM for UART Debugger
// Author: Trevor McKay
// Version: v1.4
///////////////////////////////////////////////////////

`timescale 1ns / 1ps

module controller_fsm #(
    // parameters
    CLK_RATE = 50,    // clock rate in MHz
    TIMEOUT  = 200   // timeout in ms
    )(
    // INPUTS
    input var clk,

    // sdec -> controller
    input var logic [3:0] cmd,
    input var logic [31:0] addr,
    input var logic in_valid,

    // MCU -> controller
    input var logic [31:0] pc,
    input var logic mcu_busy,

    // OUTPUTS
    // controller -> MCU
    output var logic pause = 0,
    output var logic reset = 0,
    output var logic resume = 0,
    output var logic out_valid = 0,
    output var logic reg_rd = 0,
    output var logic mem_rd = 0,
    output var logic reg_wr = 0,
    output var logic mem_wr = 0,
    output var logic [1:0] mem_size = 2,

    // controller -> sdec
    output var logic ctrlr_busy,
    output var logic error = 0
);

    // command codes
    localparam FN_NONE         = 4'h0;
    localparam FN_PAUSE        = 4'h1;
    localparam FN_RESUME       = 4'h2;
    localparam FN_STEP         = 4'h3;
    localparam FN_RESET        = 4'h4;
    localparam FN_STATUS       = 4'h5;
    localparam FN_MEM_RD_BYTE  = 4'h6;
    localparam FN_MEM_RD_WORD  = 4'h7;
    localparam FN_REG_RD       = 4'h8;
    localparam FN_BR_PT_ADD    = 4'h9;
    localparam FN_BR_PT_RM     = 4'hA;
    localparam FN_MEM_WR_BYTE  = 4'hB;
    localparam FN_MEM_WR_WORD  = 4'hC;
    localparam FN_REG_WR       = 4'hD;

    localparam TIMEOUT_COUNT  = TIMEOUT*CLK_RATE*'d1000;

    // keep track of mcu paused state
    logic r_mcu_paused = 0;
    logic r_ctrlr_busy = 0;
    assign ctrlr_busy = (r_ctrlr_busy || in_valid);

    logic [31:0] r_time = 0;

    // breakpoints
    localparam MAX_BREAK_PTS = 8;
    // [32]=valid; [31:0]=pc
    logic [32:0] break_pts[MAX_BREAK_PTS];
    initial begin
        for (int i = 0; i < MAX_BREAK_PTS; i++) begin
            break_pts[i] = 0;
        end
    end
    logic l_bp_hit;
    logic r_bp_en = 1;

    localparam S_IDLE = 1'b0;
    localparam S_WAIT = 1'b1;
    // start in idle
    logic r_ps = S_IDLE;

    // watch for breakpoints
    always_comb begin
        l_bp_hit = 0;
        for (int i = 0; i < MAX_BREAK_PTS; i++) begin
            if ((break_pts[i][32] == 1) && (break_pts[i][31:0] == pc)) begin
                l_bp_hit = 1;
            end
        end
    end

    always_ff @(posedge clk) begin

        case(r_ps)

            S_IDLE: begin
                // check for valid from serial high
                if (in_valid) begin
                    r_ctrlr_busy <= 1;

                    // issue relevent command
                    case(cmd)
                        FN_PAUSE: begin
                            pause        <= 1;
                            out_valid    <= 1;
                            r_mcu_paused <= 1;
                            r_ps         <= S_WAIT;
                        end

                        FN_RESUME: begin
                            resume       <= 1;
                            out_valid    <= 1;
                            r_bp_en      <= 1;
                            r_mcu_paused <= 0;
                            r_ps         <= S_WAIT;
                        end

                        // assumes 1-cycle completion for reset
                        FN_RESET: begin
                            reset        <= 1;
                            out_valid    <= 1;
                            r_mcu_paused <= 0;
                            r_ps         <= S_IDLE;
                        end

                        // add breakpoint - no delay
                        FN_BR_PT_ADD: begin
                            r_ps <= S_IDLE;
                            // load into first available slot, mimics client algo
                            for (int i = 0; i < MAX_BREAK_PTS; i++) begin
                                if (break_pts[i][32] == 0) begin
                                    break_pts[i][31:0] <= addr;
                                    break_pts[i][32]   <= 1'b1;
                                    break;
                                end
                            end
                        end

                        // remove breakpoint - no delay
                        FN_BR_PT_RM: begin
                            r_ps <= S_IDLE;
                            // set MSB to 0 to indicate unused
                            break_pts[addr][32] <= 0;
                        end

                        // read a word from memory, delay necessary
                        FN_MEM_RD_WORD: begin
                            mem_rd    <= 1;
                            mem_size  <= 2;
                            out_valid <= 1;
                            r_ps      <= S_WAIT;
                        end

                        // write a word to memory
                        FN_MEM_WR_WORD: begin
                            mem_wr    <= 1;
                            mem_size  <= 2;
                            out_valid <= 1;
                            r_ps      <= S_WAIT;
                        end

                        // read a byte from memory
                        FN_MEM_RD_BYTE: begin
                            mem_rd    <= 1;
                            mem_size  <= 0;
                            out_valid <= 1;
                            r_ps      <= S_WAIT;
                        end

                        // write a byte to memory
                        FN_MEM_WR_BYTE: begin
                            mem_wr    <= 1;
                            mem_size  <= 0;
                            out_valid <= 1;
                            r_ps      <= S_WAIT;
                        end

                        // read from the register file
                        FN_REG_RD: begin
                            reg_rd    <= 1;
                            out_valid <= 1;
                            r_ps      <= S_WAIT;
                        end

                        // write to the register file
                        FN_REG_WR: begin
                            reg_wr    <= 1;
                            out_valid <= 1;
                            r_ps      <= S_WAIT;
                        end

                        default: begin
                            reg_wr    <= 0;
                            mem_wr    <= 0;
                        end
                    endcase // case(cmd)
                end // if (in_valid)

                // breakpoint hit
                else if (!r_mcu_paused && l_bp_hit && r_bp_en) begin
                    pause        <= 1;
                    out_valid    <= 1;
                    r_mcu_paused <= 1;
                    r_bp_en      <= 0;
                    r_ps         <= S_WAIT;
                end

                // no cmd issued, clear cmd registers
                else begin
                    pause        <= 0;
                    resume       <= 0;
                    reset        <= 0;
                    mem_rd       <= 0;
                    mem_wr       <= 0;
                    reg_rd       <= 0;
                    reg_wr       <= 0;
                    out_valid    <= 0;
                    r_ctrlr_busy <= 0;
                    r_ps         <= S_IDLE;
                end
            end // S_IDLE // idle state

            S_WAIT: begin
                // out_valid is one-shot
                out_valid <= 0;
                r_time <= r_time + 1;
                // wait on MCU
                if (!mcu_busy) begin
                    // clear cmd registers
                    pause        <= 0;
                    resume       <= 0;
                    reset        <= 0;
                    mem_rd       <= 0;
                    mem_wr       <= 0;
                    reg_rd       <= 0;
                    reg_wr       <= 0;
                    error        <= 0;
                    r_time       <= 0;
                    r_ps         <= S_IDLE;
                end
                else if (r_time > TIMEOUT_COUNT) begin
                    error        <= 1;
                    r_time       <= 0;
                    r_ps         <= S_IDLE;
                end
            end
        endcase // case(r_ps)
    end // always_comb
endmodule // module controller_fsm
