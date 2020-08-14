`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly, SLO
// Engineer: Trevor McKay
//
// Module Name: Otter General Purpose Controller (OGPC)
// Description: Hardware module to add support for remote debugging, programming,
// etc. via low-level control of a target MCU.
//
// Version: v1.2
//
// Revision  0.01 - File Created
// Revision  0.10 - Controller first rev.
// Revision  0.11 - Increase project scope
// Revision  0.20 - First rev. serial module, byte granularity
// Revision  0.50 - Tentative working
// Revision  1.0  - Tested, working
// Revision  1.1  - Exchange mem_rw_byte for byte mask, parameters
//
// TODO:
//   - serial decoder
//   - MCU integration
//   - testing
//   - write documentation
/////////////////////////////////////////////////////////////////////////////////

module debug_controller #(
    BAUD = 115200,
    CLK_RATE = 50
    )(
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
    output [1:0] mem_size,
    output valid
);

    logic l_ctrlr_busy, l_serial_valid;
    reg [3:0] r_cmd;
    reg [31:0] r_addr, r_d_in;
    logic [3:0] l_cmd;
    logic [31:0] l_addr, l_d_in;

    assign addr = l_addr;
    assign d_in = l_d_in;
    assign cmd  = l_cmd;

    always_ff @(posedge clk) begin
        if (l_serial_valid) begin
            r_cmd <= l_cmd;
            r_addr <= l_addr;
            r_d_in <= l_d_in;
        end
    end

    serial_driver #(
        .BAUD(BAUD),
        .CLK_RATE(CLK_RATE)
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
        .d_in(l_d_in),
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
        .reg_rd(reg_rd),
        .reg_wr(reg_wr),
        .mem_rd(mem_rd),
        .mem_wr(mem_wr),
        .mem_size(mem_size),
        .out_valid(valid),
        .ctrlr_busy(l_ctrlr_busy)
    );

endmodule // module mcu_controller
