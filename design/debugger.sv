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

    // debugger -> MCU
    output [31:0] d_in,
    output [31:0] addr,
    output rf_wr,
    output mem_wr,
    output flush,
    output resume,
    output reset,
    output valid
);

    DEBUG_FN debug_fn;
    logic [31:0] d_rd;
    logic sdec_ctrlr_valid;
    logic ctrlr_busy;
    logic mcu_paused;

    logic ctrlr_mcu_valid;

//    serial SDEC(
//        .clk(clk),
//        .srx(srx),
//        .stx(stx),
//        .debug_fn(debug_fn),
//        .addr(addr),
//        .d_in(d_in),
//        .out_valid(sdec_ctrlr_valid),
//        .ctrlr_busy(ctrlr_busy),
//        .d_rd(d_rd)
//    );

    controller CTRLR(
        .clk(clk),
        .debug_fn(debug_fn),
        .in_valid(sdec_ctrlr_valid),
        .pc(pc),
        .mcu_busy(mcu_busy),
        .flush(flush),
        .reset(reset),
        .resume(resume),
        .out_valid(ctrlr_mcu_valid),
        .d_rd(d_rd),
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
    input clk,

    // sdec -> controller
    input DEBUG_FN debug_fn,
    input logic [31:0] addr,
    input logic in_valid,
    
    // MCU -> controller
    input logic [31:0] pc,
    input logic mcu_busy,
    
    // controller -> MCU
    output logic flush,
    output logic reset,
    output logic resume,
    output logic out_valid,
    output logic rf_rd,
    output logic mem_rd,
    output logic rf_wr,
    output logic mem_wr,

    // controller -> sdec
    output logic [31:0] d_rd,
    output logic ctrlr_busy
    );
    
    reg mcu_paused = 0;
    logic mcu_paused_in;

    logic [31:0] break_pts[8];
    initial for (int i = 0; i < 8; i++) break_pts[i] = 'Z;
    reg [2:0] num_break_pts = 0;
    logic [2:0] num_break_pts_in;

    typedef enum logic [2:0] {
        IDLE,
        WAIT_FOR_PAUSE,
        WAIT_FOR_READ,
        WAIT_FOR_WRITE,
        BREAK_HIT
    } STATE;
    
    STATE ps = IDLE, ns;
    
    
    always_ff @(posedge clk) begin 
        ps <= ns;
        // update paused state
        mcu_paused <= mcu_paused_in; 
        // update number of breakpoints
        num_break_pts <= num_break_pts_in;

        // compare pc to all breakpoints
        for (int i = 0; i < 8; i++) begin
            if ((pc + 4) == break_pts[i]) begin
                ns <= BREAK_HIT;
            end        
        end
    end
    
    always_comb begin
        // default values
        flush = 0;
        reset = 0;
        resume = 0;
        out_valid = 0;
        d_rd = 'Z;
        ctrlr_busy = 0;
        
        // keep these values by default
        num_break_pts_in = num_break_pts;
        mcu_paused_in = mcu_paused;

        // TODO: states
        case(ps)
            IDLE: begin
            end
            
            WAIT_FOR_PAUSE: begin
            end

            WAIT_FOR_READ: begin
            end

            WAIT_FOR_WRITE: begin
            end

            BREAK_HIT: begin
            end
        endcase
    end

endmodule
