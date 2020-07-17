`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Keefe Johnson
// 
// Create Date: 03/18/2019 09:21:15 PM
// Design Name: 
// Module Name: uart_tx_word
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_tx_word #(
    parameter CLK_RATE = -1,  // rate of clk in MHz (must override)
    parameter BAUD = 115200   // raw serial rate in bits/s
    )(
    input clk,
    input rst,
    input start,  // one-shot
    input [31:0] tx_word,
    output stx,
    output idle  // (not one-shot) high while available, low while transmitting
    );

    enum {IDLE, WAIT_START, INIT_TX_BYTE, WAIT_TX_BYTE} state = IDLE;
    logic [1:0] sending_byte_num = 0;
    logic [31:0] r_tx_word = 0;

    wire byte_start;
    wire byte_busy;

    // note: sending big-endian
    uart_tx #(.CLKS_PER_BIT(CLK_RATE*1_000_000/BAUD))
        uart_tx(.i_Clock(clk), .i_Tx_DV(byte_start), .i_Tx_Byte(r_tx_word[31:24]),
                .o_Tx_Active(byte_busy), .o_Tx_Serial(stx), .o_Tx_Done());

    assign byte_start = (state == INIT_TX_BYTE);
    assign idle = (state == IDLE);

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            sending_byte_num <= 0;
            r_tx_word <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        r_tx_word <= tx_word;
                        sending_byte_num <= 0;
                        state <= WAIT_START;
                    end
                end
                WAIT_START: begin
                    // this prevents loss if uart_tx is still busy sending a
                    //   previous byte, e.g. after abrupt reset
                    if (!byte_busy) begin
                        state <= INIT_TX_BYTE;
                    end
                end
                INIT_TX_BYTE: begin
                    state <= WAIT_TX_BYTE;
                end
                WAIT_TX_BYTE: begin
                    if (!byte_busy) begin
                        if (sending_byte_num == 3) begin
                            sending_byte_num <= 0;
                            state <= IDLE;
                        end else begin
                            r_tx_word <= {r_tx_word[23:0], 8'd0};  // big-endian
                            sending_byte_num <= sending_byte_num + 1;
                            state <= INIT_TX_BYTE;
                        end
                    end
                end
            endcase
        end
    end
    
endmodule
