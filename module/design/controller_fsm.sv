////////////////////////////////////////////////////////
// Module: Controller FSM for UART Debugger
// Author: Trevor McKay
// Version: v0.5
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
    output logic rf_rd,
    output logic mem_rd,
    output logic rf_wr,
    output logic mem_wr,
    output logic mem_rw_byte,

    // controller -> sdec
    output logic ctrlr_busy
);
    
    // keep track of mcu state
    reg r_mcu_paused = 0;
    logic l_mcu_paused_in;

    // breakpoints
    logic [31:0] break_pts[8];
    initial
        for (int i = 0; i < 8; i++)
            break_pts[i] = 'Z;
    reg [2:0] r_num_break_pts = 0;
    logic l_bp_add, l_hit;
    
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

    // states for controller
    typedef enum logic [3:0] {
        S_IDLE,
        S_WAIT_PAUSE,
        S_WAIT_RESUME,
        S_WAIT_MEM_RD,
        S_WAIT_MEM_WR,
        S_WAIT_REG_RD,
        S_WAIT_REG_WR,
        S_WAIT_STEP,
        S_BREAK_HIT
    } STATE;
    
    STATE r_ps = S_IDLE, l_ns; 
    
    always_ff @(posedge clk) begin
        // update paused state
        r_mcu_paused <= l_mcu_paused_in; 

        // compare pc to all breakpoints
        l_hit = 0;
        if (!r_mcu_paused) begin
            for (int i = 0; i < 8; i++) begin
                if ((pc + 4) == break_pts[i]) begin
                    r_ps <= S_BREAK_HIT;
                    l_hit = 1;
                end
            end
        end
        if (!l_hit) r_ps <= l_ns;
        
        // load in new breakpoints
        if (l_bp_add) begin
            break_pts[r_num_break_pts] <= addr;
            r_num_break_pts <= r_num_break_pts + 1;
        end
    end // always_ff @(posedge clk)
    
    always_comb begin
        pause = 0;
        reset = 0;
        resume = 0;
        l_bp_add= 0;
        rf_rd = 0;
        rf_wr = 0;
        mem_rd = 0;
        mem_wr = 0;
        mem_rw_byte = 0;
        l_ns  = S_IDLE;

        /* controller will output no commands and
        * accept no input in its default state */
        
        // output is invalid unless specified
        out_valid = 0;
        // busy unless specified
        ctrlr_busy = 1;

        // keep these values by default
        l_mcu_paused_in = r_mcu_paused;

        case(r_ps)

            S_IDLE: begin
                // check for valid from sdec high
                if (in_valid) begin
                    case(cmd)
                        FN_PAUSE: begin
                            pause = 1;
                            out_valid = 1;
                            l_ns = S_WAIT_PAUSE;
                        end
                        FN_RESUME: begin
                            resume = 1;
                            out_valid = 1;
                            l_ns = S_WAIT_RESUME;
                        end
                        FN_STEP: begin
                            // step only supported if MCU is paused
                            if (r_mcu_paused) begin
                                resume = 1;
                                out_valid = 1;
                                l_ns = S_WAIT_STEP;
                               end
                            else begin
                                ctrlr_busy = 0;
                                l_ns = S_IDLE;
                            end
                        end
                        FN_BR_PT_ADD: begin
                            ctrlr_busy = 0;
                            l_bp_add = 1;
                            l_ns = S_IDLE;
                        end
                        FN_MEM_RD_WORD: begin
                            mem_rd = 1;
                            l_ns = S_WAIT_MEM_RD;
                        end
                        FN_MEM_WR_WORD: begin
                            mem_wr = 1;
                            l_ns = S_WAIT_MEM_WR;
                        end
                        FN_MEM_RD_BYTE: begin
                            mem_rd = 1;
                            mem_rw_byte = 1;
                            l_ns = S_WAIT_MEM_RD;
                        end
                        FN_MEM_WR_BYTE: begin
                            mem_wr = 1;
                            mem_rw_byte = 1;
                            l_ns = S_WAIT_MEM_WR;
                        end

                    endcase // case(debug_fn)
                end            
                // no command given, stay idle
                else begin
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end
            end
            
            S_WAIT_PAUSE: begin
                if (mcu_busy) begin
                    pause = 1;
                    l_ns = S_WAIT_PAUSE;
                end
                else begin
                    l_mcu_paused_in = 1;
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end
            end

            S_WAIT_RESUME: begin
                if (mcu_busy) begin
                    resume = 1;
                    l_ns = S_WAIT_RESUME;
                end
                else begin
                    l_mcu_paused_in = 0;
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end
            end

            S_WAIT_STEP: begin
                out_valid = 1;
                // wait for resume
                if (mcu_busy) begin
                    resume = 1;
                    l_ns = S_WAIT_STEP;
                end
                // pause on next cycle
                else begin
                    pause = 1;
                    l_ns = S_WAIT_PAUSE;
                end
            end

            S_WAIT_MEM_RD: begin
                if (mcu_busy) begin
                    mem_rd = 1;
                    l_ns = S_WAIT_MEM_RD;
                end
                else begin
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end
            end

            S_WAIT_MEM_WR: begin
                if (mcu_busy) begin
                    mem_wr = 1;
                    l_ns = S_WAIT_MEM_RD;
                end
                else begin
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end
            end

            S_WAIT_REG_RD: begin
                if (mcu_busy) begin
                    rf_rd = 1;
                    l_ns = S_WAIT_REG_RD;
                end
                else begin
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end
            end

            S_WAIT_REG_WR: begin
                if (mcu_busy) begin
                    rf_wr = 1;
                    l_ns = S_WAIT_REG_WR;
                end
                else begin
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end
            end

            S_BREAK_HIT: begin
                pause = 1;
                out_valid = 1;
                l_ns = S_WAIT_PAUSE;
            end

            default: l_ns = S_IDLE;
        endcase // case(r_ps)

    end // always_comb

endmodule // module controller_fsm

