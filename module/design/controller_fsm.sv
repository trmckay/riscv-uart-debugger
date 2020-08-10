////////////////////////////////////////////////////////
// Module: Controller FSM for UART Debugger
// Author: Trevor McKay
// Version: v1.1b
///////////////////////////////////////////////////////

`timescale 1ns / 1ps

module controller_fsm(
    // INPUTS
    input clk,

    // sdec -> controller
    input logic [3:0] cmd,
    input logic [31:0] addr,
    input logic in_valid,

    // MCU -> controller
    input logic [31:0] pc,
    input logic mcu_busy,

    // OUTPUTS
    // controller -> MCU
    output logic pause,
    output logic reset,
    output logic resume,
    output logic out_valid,
    output logic reg_rd,
    output logic mem_rd,
    output logic reg_wr,
    output logic mem_wr,
    output logic [3:0] mem_be,

    // controller -> sdec
    output logic ctrlr_busy
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

    // keep track of mcu paused state
    reg r_mcu_paused = 0;
    logic l_mcu_paused_in;

    // breakpoints
    localparam MAX_BREAK_PTS = 8;
    // [32]=valid; [31:0]=pc
    logic [32:0] break_pts[MAX_BREAK_PTS];
    initial for (int i = 0; i < MAX_BREAK_PTS; i++)
        break_pts[i] = 0;
    logic l_bp_add, l_bp_rm, l_bp_hit, l_bp_en;
    reg r_bp_en = 1;

    // states for controller
    typedef enum logic [3:0] {
        S_IDLE,
        S_WAIT_PAUSE,
        S_WAIT_RESUME,
        S_WAIT_MEM_RD,
        S_WAIT_MEM_WR,
        S_WAIT_REG_RD,
        S_WAIT_REG_WR,
        S_WAIT_STEP
    } STATE;

    // start in idle
    STATE r_ps = S_IDLE, l_ns;

    always_ff @(posedge clk) begin
        // update paused state
        r_mcu_paused <= l_mcu_paused_in;

        // next state
        r_ps <= l_ns;

        // load in new breakpoints
        if (l_bp_add) begin
            // load into first available slot, mimics client algo
            for (int i = 0; i < MAX_BREAK_PTS; i++) begin
                if (break_pts[i][32] == 0) begin
                    break_pts[i][31:0] <= addr;
                    break_pts[i][32]   <= 1'b1;
                    break;
                end
            end
        end
        // set MSB to 0 to indicate unused
        if (l_bp_rm) begin
            break_pts[addr][32] <= 0;
        end
        r_bp_en <= l_bp_en;
    end // always_ff @(posedge clk)

    always_comb begin

        // defaults
        pause           = 0;
        reset           = 0;
        resume          = 0;
        reg_rd          = 0;
        reg_wr          = 0;
        mem_rd          = 0;
        mem_wr          = 0;
        mem_be          = 0;
        out_valid       = 0;
        ctrlr_busy      = 1;
        l_bp_add        = 0;
        l_bp_rm         = 0;
        l_bp_hit        = 0;
        l_bp_en         = r_bp_en;
        l_mcu_paused_in = r_mcu_paused;
        l_ns            = S_IDLE;

        // watch for breakpoints
        for (int i = 0; i < MAX_BREAK_PTS; i++) begin
            if ((break_pts[i][32] == 1) && (break_pts[i][31:0] == pc))
                l_bp_hit = 1;
        end

        case(r_ps)
            S_IDLE: begin
                // check for valid from serial high
                if (in_valid) begin
                    // issue relevent command
                    case(cmd)
                        FN_PAUSE: begin
                            pause = 1;
                            out_valid = 1;
                            l_mcu_paused_in = 1;
                            l_ns = S_WAIT_PAUSE;
                        end
                        FN_RESUME: begin
                            resume = 1;
                            out_valid = 1;
                            l_ns = S_WAIT_RESUME;
                        end
                        FN_RESET: begin
                            reset = 1;
                            out_valid = 1;
                            l_ns = S_IDLE;
                        end
                        FN_STEP: begin
                            resume = 1;
                            out_valid = 1;
                            l_ns = S_WAIT_STEP;
                        end
                        FN_BR_PT_ADD: begin
                            ctrlr_busy = 0;
                            l_bp_add = 1;
                            l_ns = S_IDLE;
                        end
                        FN_BR_PT_RM: begin
                            l_bp_rm  = 1;
                            l_ns = S_IDLE;
                        end
                        FN_MEM_RD_WORD: begin
                            mem_rd = 1;
                            mem_be = 4'b1111;
                            out_valid = 1;
                            l_ns = S_WAIT_MEM_RD;
                        end
                        FN_MEM_WR_WORD: begin
                            mem_wr = 1;
                            mem_be = 4'b1111;
                            out_valid = 1;
                            l_ns = S_WAIT_MEM_WR;
                        end
                        FN_MEM_RD_BYTE: begin
                            mem_rd = 1;
                            mem_be = 1'b1 << addr[1:0];
                            out_valid = 1;
                            l_ns = S_WAIT_MEM_RD;
                        end
                        FN_MEM_WR_BYTE: begin
                            mem_wr = 1;
                            mem_be = 1'b1 << addr[1:0];
                            out_valid = 1;
                            l_ns = S_WAIT_MEM_WR;
                        end
                        FN_REG_RD: begin
                            reg_rd = 1;
                            out_valid = 1;
                            l_ns = S_WAIT_REG_RD;
                        end
                        FN_REG_WR: begin
                            reg_wr = 1;
                            out_valid = 1;
                            l_ns = S_WAIT_REG_WR;
                        end
                    endcase // case(cmd)
                end // if (in_valid)

                // stay in idle, indicate not busy
                else begin
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end

                if (!r_mcu_paused && l_bp_hit && r_bp_en)
                begin
                    // issue a pause
                    pause = 1;
                    out_valid = 1;
                    // save paused state early
                    l_mcu_paused_in = 1;
                    // disable breakpoints
                    l_bp_en = 0;
                    l_ns = S_WAIT_PAUSE;
                end
            end // S_IDLE

            S_WAIT_PAUSE: begin
                pause = 1;
                l_bp_en = 0;
                if (mcu_busy) begin
                    l_ns = S_WAIT_PAUSE;
                end
                else begin
                    l_ns = S_IDLE;
                end
            end // S_WAIT_PAUSE

            S_WAIT_RESUME: begin
                resume = 1;
                if (mcu_busy) begin
                    l_ns = S_WAIT_RESUME;
                    out_valid = 1;
                end
                else begin
                    l_mcu_paused_in = 0;
                    l_bp_en = 1;
                    l_ns = S_IDLE;
                end
            end // S_WAIT_RESUME

            S_WAIT_STEP: begin
                // wait for resume
                if (mcu_busy) begin
                    resume = 1;
                    l_ns = S_WAIT_STEP;
                end
                // use r_mcu_paused to wait one cycle of execute
                else if (!r_mcu_paused) begin
                    l_mcu_paused_in = 0;
                end
                else begin
                    pause = 1;
                    out_valid = 1;
                    l_ns = S_WAIT_PAUSE;
                end
            end // S_WAIT_STEP

            S_WAIT_MEM_RD: begin
                if (mcu_busy) begin
                    mem_rd = 1;
                    mem_be = ((cmd == FN_MEM_RD_BYTE) ? (1'b1 << addr[1:0]) : 4'b1111);
                    l_ns = S_WAIT_MEM_RD;
                end
                else begin
                    l_ns = S_IDLE;
                end
            end // S_WAIT_MEM_RD

            S_WAIT_MEM_WR: begin
                if (mcu_busy) begin
                    mem_wr = 1;
                    mem_be = ((cmd == FN_MEM_RD_BYTE) ? (1'b1 << addr[1:0]) : 4'b1111);
                    l_ns = S_WAIT_MEM_RD;
                end
                else begin
                    l_ns = S_IDLE;
                end
            end // S_WAIT_MEM_WR

            S_WAIT_REG_RD: begin
                if (mcu_busy) begin
                    reg_rd = 1;
                    l_ns = S_WAIT_REG_RD;
                end
                else begin
                    l_ns = S_IDLE;
                end
            end // S_WAIT_REG_RD

            S_WAIT_REG_WR: begin
                if (mcu_busy) begin
                    reg_wr = 1;
                    l_ns = S_WAIT_REG_WR;
                end
                else begin
                    l_ns = S_IDLE;
                end
            end // S_WAIT_REG_WR

            default:
                l_ns = S_IDLE;

        endcase // case(r_ps)
    end // always_comb
endmodule // module controller_fsm
