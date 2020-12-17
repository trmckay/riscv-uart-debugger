`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly, SLO
// Engineer: Trevor McKay
//
// Module Name: Otter General Purpose Controller (OGPC)
// Description: Hardware module to add support for remote debugging, programming,
// etc. via low-level control of a target MCU.
//
// Version: v1.4
//
// Revision  0.01 - File Created
// Revision  0.10 - Controller first rev.
// Revision  0.11 - Increase project scope
// Revision  0.20 - First rev. serial module, byte granularity
// Revision  0.50 - Tentative working
// Revision  1.0  - Tested, working
// Revision  1.1  - Exchange mem_rw_byte for byte mask, parameters
// Revision  1.2  - byte mask -> mem_size
// Revision  1.3  - fast programming
// Revision  1.4  - error reporting, get pc on pause
//
// TODO:
//   - serial decoder
//   - MCU integration
//   - testing
//   - write documentation
/////////////////////////////////////////////////////////////////////////////////

module debug_controller #(
    BAUD = 115200,   // baud rate (bit/s)
    CLK_RATE = 50,   // clock rate (MHz)
    TIMEOUT  = 200   // timeout (ms)
    )(
    input var clk,

    // user <-> debugger (via serial)
    input var srx,
    output var stx,

    // MCU -> debugger
    input var [31:0] pc,
    input var mcu_busy,
    input var [31:0] d_rd,
    input var error,

    // debugger -> MCU
    output var [31:0] d_in,
    output var [31:0] addr,
    output var pause,
    output var resume,
    output var reset,
    output var reg_rd,
    output var reg_wr,
    output var mem_rd,
    output var mem_wr,
    output var [1:0] mem_size,
    output var valid
);

    localparam ERR_TIMEOUT = 2;
    localparam ERR_MCU = 1;
    localparam ERR_NONE = 0;

    logic l_ctrlr_busy, l_serial_valid, l_ctrlr_error;
    logic [3:0] r_cmd;
    logic [31:0] r_addr, r_d_in;
    logic [3:0] l_cmd;
    logic [31:0] l_addr, l_d_in;
    logic [1:0] r_ec;

    assign addr = l_addr;
    assign d_in = l_d_in;
    assign cmd  = l_cmd;

    always_ff @(posedge clk) begin
        if (l_serial_valid) begin
            r_cmd <= l_cmd;
            r_addr <= l_addr;
            r_d_in <= l_d_in;
            r_ec <= ERR_NONE;
        end
        if (l_ctrlr_error) begin
            r_ec <= ERR_TIMEOUT;
        end
        if (error) begin
            r_ec <= ERR_MCU;
        end
    end

    // error code to be transmitted back to client
    // 0 = no error
    // 1 = timeout from controller
    // 2 = error reported by MCU

    serial_driver #(
        .BAUD(BAUD),
        .CLK_RATE(CLK_RATE),
        .TIMEOUT(TIMEOUT)
    ) serial(
        .clk(clk),
        .reset(1'b0),
        .srx(srx),
        .error(r_ec),
        .ctrlr_busy(l_ctrlr_busy),
        .d_rd(d_rd),
        .stx(stx),
        .cmd(l_cmd),
        .addr(l_addr),
        .d_in(l_d_in),
        .out_valid(l_serial_valid)
    );

    controller_fsm #(
        .CLK_RATE(CLK_RATE),
        .TIMEOUT(TIMEOUT)
    ) fsm(
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
        .error(l_ctrlr_error),
        .ctrlr_busy(l_ctrlr_busy)
    );

endmodule // module mcu_controller
