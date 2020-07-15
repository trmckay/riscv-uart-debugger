`timescale 1ns / 1ps

typedef enum logic [3:0] {
    PAUSE,
    RESUME,
    STEP,
    RESET,
    STATUS,
    BR_PT_ADD,
    BR_PT_RM,
    MEM_RD,
    MEM_WR,
    REG_RD,
    REG_WR
} DEBUG_FN;


module debugger(
    input clk,

    // user <-> debugger (via serial)
    input srx,
    output stx,

    // MCU -> debugger
    input [31:0] pc,
    input mcu_busy,
    input [31:0] d_rd,
    input error,

    // debugger -> MCU
    output [31:0] d_in,
    output [31:0] addr,
    output rf_wr,
    output mem_wr,
    output pause,
    output resume,
    output reset,
    output valid
);

    DEBUG_FN debug_fn;
    logic sdec_ctrlr_valid;
    logic [31:0] decoded_addr;
    logic [31:0] decoded_d_in;
    logic ctrlr_busy;
    logic mcu_paused;

    logic ctrlr_mcu_valid;

//    serial SDEC(
//        .clk(clk),
//        .srx(srx),
//        .stx(stx),
//        .debug_fn(debug_fn),
//        .addr(decoded_addr),
//        .d_in(decoded_d_in),
//        .out_valid(sdec_ctrlr_valid),
//        .ctrlr_busy(ctrlr_busy),
//        .d_rd(d_rd)
//    );

    controller CTRLR(
        // inputs
        .clk(clk),
        .addr(decoded_addr),
        .debug_fn(debug_fn),
        .in_valid(sdec_ctrlr_valid),
        .pc(pc),
        .mcu_busy(mcu_busy),
        // outputs
        .pause(pause),
        .reset(reset),
        .resume(resume),
        .out_valid(ctrlr_mcu_valid),
        .ctrlr_busy(ctrlr_busy)
    );

endmodule


//module serial(
//    input clk,
//    input reset,

//    // user <-> serial
//    input srx,
//    output stx,

//    // controller -> sdec
//    input ctrlr_busy,
//    input [31:0] d_rd,

//    // sdec -> controller
//    output DEBUG_FN debug_fn,
//    output [31:0] addr,
//    output [31:0] d_in,
//    output out_valid
//);

//endmodule


module controller(
    // INPUTS
    input clk,

    // sdec -> controller
    input DEBUG_FN debug_fn,
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

    // controller -> sdec
    output logic [31:0] ctlr_sdec_d_rd,
    output logic ctrlr_busy
    );
    
    reg mcu_paused = 0;
    logic mcu_paused_in;

    logic [31:0] break_pts[8];
    initial for (int i = 0; i < 8; i++) break_pts[i] = 'Z;
    reg [2:0] num_break_pts = 0;
    logic bp_add, hit;

    typedef enum logic [3:0] {
        IDLE,
        WAIT_FOR_PAUSE,
        WAIT_FOR_RESUME,
        WAIT_FOR_READ,
        WAIT_FOR_WRITE,
        WAIT_FOR_STEP,
        BREAK_HIT
    } STATE;
    
    STATE ps = IDLE, ns; 
    
    always_ff @(posedge clk) begin
        // update paused state
        mcu_paused <= mcu_paused_in; 

        // compare pc to all breakpoints
        hit = 0;
        if (!mcu_paused) begin
            for (int i = 0; i < 8; i++) begin
                if ((pc + 4) == break_pts[i]) begin
                    ps <= BREAK_HIT;
                    hit = 1;
                end
            end
        end
        if (!hit) ps <= ns;
        
        // load in new breakpoints
        if (bp_add) begin
            break_pts[num_break_pts] <= addr;
            num_break_pts <= num_break_pts + 1;
        end
    end
    
    always_comb begin
        pause = 'Z;
        reset = 'Z;
        resume = 'Z;
        bp_add = 0;
        ns = IDLE;

        /* controller will output no commands and
        * accept no input in its default state */
        
        // output is invalid unless specified
        out_valid = 0;
        // busy unless specified
        ctrlr_busy = 1;

        // keep these values by default
        mcu_paused_in = mcu_paused;

        /* CURRENTLY SUPPORTS:
            * pause
            * resume
            * step
            * add break point
            * pause on break point
        */

        /* NOT YET IMPLEMENTED:
            * remove breakpoint
            * status
            * read memory
            * write memory
            * read register
            * write register
        */

        case(ps)

            IDLE: begin
                // check for valid from sdec high
                if (in_valid) begin
                    case(debug_fn)
                        PAUSE: begin
                            pause = 1;
                            out_valid = 1;
                            ns = WAIT_FOR_PAUSE;
                        end
                        RESUME: begin
                            resume = 1;
                            out_valid = 1;
                            ns = WAIT_FOR_RESUME;
                        end
                        STEP: begin
                            // step only supported if MCU is paused
                            if (mcu_paused) begin
                                resume = 1;
                                out_valid = 1;
                                ns = WAIT_FOR_STEP;
                               end
                            else begin
                                ctrlr_busy = 0;
                                ns = IDLE;
                            end
                        end
                        BR_PT_ADD: begin
                            ctrlr_busy = 0;
                            bp_add = 1;
                            ns = IDLE;
                        end
                    endcase
                end
                // no command given, stay idle
                else begin
                    ctrlr_busy = 0;
                    ns = IDLE;
                end
            end
            
            WAIT_FOR_PAUSE: begin
                if (mcu_busy) begin
                    out_valid = 1;
                    pause = 1;
                    ns = WAIT_FOR_PAUSE;
                end
                else begin
                    mcu_paused_in = 1;
                    ctrlr_busy = 0;
                    ns = IDLE;
                end
            end

            WAIT_FOR_RESUME: begin
                if (mcu_busy) begin
                    resume = 1;
                    out_valid = 1;
                    ns = WAIT_FOR_RESUME;
                end
                else begin
                    mcu_paused_in = 0;
                    ctrlr_busy = 0;
                    ns = IDLE;
                end
            end

            WAIT_FOR_STEP: begin
                // wait for resume
                if (mcu_busy) begin
                    resume = 1;
                    out_valid = 1;
                    ns = WAIT_FOR_STEP;
                end
                // pause on next cycle
                else begin
                    pause = 1;
                    out_valid = 1;
                    ns = WAIT_FOR_PAUSE;
                end
            end

            WAIT_FOR_READ: begin
            end

            WAIT_FOR_WRITE: begin
            end

            BREAK_HIT: begin
                pause = 1;
                out_valid = 1;
                ns = WAIT_FOR_PAUSE;
            end
            
            default: ns = IDLE;
        endcase
    end

endmodule
