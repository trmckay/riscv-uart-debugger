`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly, SLO
// Engineer: Trevor McKay
// 
// Module Name: Otter General Purpose Controller (OGPC)
// Description: Hardware module to add support for remote debugging, programming,
// etc. via low-level control of a target MCU.
// 
// Version: v0.5
//
// Revision  0.01 - File Created
// Revision  0.10 - Controller first rev.
// Revision  0.11 - Increase project scope
// Revision  0.20 - First rev. serial module, byte granularity
// Revision  0.50 - Tentative release
//
// TODO:
//   - serial decoder
//   - MCU integration
//   - testing
//   - write documentation
/////////////////////////////////////////////////////////////////////////////////

module mcu_controller(
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
    output pause,
    output resume,
    output reset,
    output reg_rd,
    output reg_wr,
    output mem_rd,
    output mem_wr,
    output mem_rw_byte,
    output valid
);

    logic l_ctrlr_busy, l_serial_valid;
    logic [3:0] l_cmd;
    logic [31:0] l_addr;

    assign addr = l_addr;

    serial_driver #(
        .BAUD(115200),
        .CLK_RATE(50)
    ) serial(
        .clk(clk),
        .reset(1'b0),
        .srx(srx),
        .ctrlr_busy(l_ctrlr_busy),
        .d_rd(d_rd),
        .error(error),
        
        .stx(stx),
        .cmd(l_cmd),
        .addr(l_addr),
        .d_in(d_in),
        .out_valid(l_serial_valid)
    );
    
    controller_fsm fsm(
        .clk(clk),
        .cmd(l_cmd),
        .addr(l_addr),
        .in_valid(l_serial_valid),
        .pc(pc),
        .mcu_busy(mcu_busy),

        .pause(pause),
        .reset(reset),
        .resume(resume),
        .rf_rd(rf_rd),
        .rf_wr(rf_wr),
        .mem_rd(mem_rd),
        .mem_wr(mem_wr),
        .mem_rw_byte(mem_rw_byte),
        .out_valid(valid),
        .ctrlr_busy(l_ctrlr_busy)
    );
    
endmodule // module mcu_controller
