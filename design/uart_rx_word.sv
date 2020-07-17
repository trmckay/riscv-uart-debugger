`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Keefe Johnson
// 
// Create Date: 03/18/2019 09:21:15 PM
// Design Name: 
// Module Name: uart_rx_word
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


module uart_rx_word #(
    parameter CLK_RATE = -1,     // rate of clk in MHz (must override)
    parameter BAUD = 115200,     // raw serial rate in bits/s
    parameter IB_TIMEOUT = 200  // max time between bytes in ms
    )(
    input clk,
    input rst,
    input srx,
    output ready,  // one-shot
    output [31:0] rx_word
    );

    localparam TIMEOUT_CLKS = CLK_RATE * IB_TIMEOUT * 1000;

    enum {WAIT_RX_BYTE, OUTPUT_WORD} state = WAIT_RX_BYTE;
    logic [$clog2(TIMEOUT_CLKS+1)-1:0] timeout_counter = 0;
    logic [1:0] num_bytes_recvd = 0;
    logic [23:0] r_rx_bytes = 0;  // shift first 3 bytes into here 
    logic [31:0] r_rx_word = 0;  // but don't change output until full word

    wire rx_byte_ready;
    wire [7:0] rx_byte;

    uart_rx #(.CLKS_PER_BIT(CLK_RATE*1_000_000/BAUD))
        uart_rx(.i_Clock(clk), .i_Rx_Serial(srx), .o_Rx_DV(rx_byte_ready),
                .o_Rx_Byte(rx_byte));
    
    assign rx_word = r_rx_word;
    assign ready = (state == OUTPUT_WORD);
                
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= WAIT_RX_BYTE;
            timeout_counter <= 0;
            num_bytes_recvd <= 0;
            r_rx_bytes <= 0;
            r_rx_word <= 0;
        end else begin
            case (state)
                WAIT_RX_BYTE: begin
                    if (rx_byte_ready) begin
                        if (num_bytes_recvd == 3) begin  // just received 4th byte
                            r_rx_word <= {r_rx_bytes, rx_byte};  // big-endian
                            num_bytes_recvd <= 0; 
                            state <= OUTPUT_WORD;
                        end else begin
                            num_bytes_recvd <= num_bytes_recvd + 1;
                        end
                        r_rx_bytes <= {r_rx_bytes[15:0], rx_byte};  // big-endian
                        timeout_counter <= 0;
                    end else if (timeout_counter == TIMEOUT_CLKS) begin
                        num_bytes_recvd <= 0;  // discard old bytes
                    end else begin
                        timeout_counter <= timeout_counter + 1;
                    end
                end
                OUTPUT_WORD: begin  // one-shot state
                    state <= WAIT_RX_BYTE;
                end
                default: state <= WAIT_RX_BYTE;
            endcase
        end
    end
    
endmodule
