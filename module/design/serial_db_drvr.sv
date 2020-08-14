////////////////////////////////////////////////////////
// Module: Serial Driver for UART Debugger
// Author: Trevor McKay
// Version: v1.2
////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module serial_driver #(
    // parameters
    CLK_RATE = 50,  // input clk speed in MHz
    BAUD = 115200,  // baud rate for UART connections in bit/s
    TIMEOUT = 200   // timeout in ms
    )(
    // INPUTS
    input clk,
    input reset,

    // user <-> serial
    input srx,
    output stx,

    // controller -> sdec
    input ctrlr_busy,

    // mcu -> sdec
    input [31:0] d_rd,
    input error,

    // OUTPUTS
    // sdrv -> controller
    output [3:0]  cmd,
    output [31:0] addr,
    output [31:0] d_in,
    output out_valid
);

    // used to escape normal recieve-echo routine and enter programming mode
    localparam PROGRAM        = 4'h000F;
    localparam FN_MEM_WR_WORD = 4'h000C;

    // TIMEOUT_COUNT = (TIMEOUT * 10^-3 sec)(CLK_RATE * 10^6 clk/sec)
    localparam TIMEOUT_COUNT  = TIMEOUT*CLK_RATE*'d1000;

    logic [31:0] l_rx_word;
    logic l_rx_ready;

    uart_rx_word #(.CLK_RATE(CLK_RATE), .BAUD(BAUD)) rx(
        .clk(clk),
        .srx(srx),
        .rst(1'b0),
        .ready(l_rx_ready),
        .rx_word(l_rx_word)
    );

    reg [31:0] r_tx_word;
    reg r_tx_start = 0; // one-shot
    logic l_tx_idle;

    uart_tx_word #(.CLK_RATE(CLK_RATE), .BAUD(BAUD)) tx(
        .clk(clk),
        .rst(1'b0),
        .start(r_tx_start),
        .tx_word(r_tx_word),
        .stx(stx),
        .idle(l_tx_idle)
    );

    typedef enum logic [3:0] {
        S_WAIT_CMD,
        S_ECHO_CMD,
        S_WAIT_ADDR,
        S_ECHO_ADDR,
        S_WAIT_DATA,
        S_ECHO_DATA,
        S_CTRLR,
        S_REPLY,
        S_PROG_RCV,
        S_PROG_WR
    } STATE;

    STATE r_ps = S_WAIT_CMD;

    reg [31:0] r_addr, r_d_in;
    reg [3:0] r_cmd;
    reg r_out_valid = 0;
    reg [31:0] r_time = 0;

    assign out_valid = r_out_valid;
    assign cmd = r_cmd;
    assign d_in = r_d_in;
    assign addr = r_addr;

    always_ff @(posedge clk) begin

        case(r_ps)

            S_WAIT_CMD: begin
                // recieve ready
                if (l_rx_ready) begin
                    // enter special programming mode that minimizes echoes
                    if (l_rx_word[3:0] == PROGRAM) begin
                        r_ps  <= S_PROG_RCV;
                        // programming uses write word command
                        r_cmd <= FN_MEM_WR_WORD;
                        r_addr <= 0;
                    end
                    else begin
                        // save cmd
                        r_cmd <= l_rx_word[3:0];
                        // start echo cmd
                        r_ps <= S_ECHO_CMD;
                        r_tx_start <= 1;
                        r_tx_word <= {28'b0, l_rx_word[3:0]};
                    end
                end
            end // S_IDLE

            S_ECHO_CMD: begin
                r_tx_start <= 0;
                // transmit done
                if (l_tx_idle && !r_tx_start) begin
                    // wait for address
                    r_ps <= S_WAIT_ADDR;
                end
            end // S_ECHO_CMD

            S_WAIT_ADDR: begin
                // recieve ready
                if (l_rx_ready) begin
                    // save address
                    r_addr <= l_rx_word;
                    // start echo address
                    r_ps <= S_ECHO_ADDR;
                    r_tx_start <= 1;
                    r_tx_word <= l_rx_word;
                end
            end // S_WAIT

            S_ECHO_ADDR: begin
                r_tx_start <= 0;
                // transmit done
                if (l_tx_idle && !r_tx_start) begin
                    // wait for data
                    r_ps <= S_WAIT_DATA;
                end
            end // S_FINISH

            S_WAIT_DATA: begin
                // recieve ready
                if (l_rx_ready) begin
                    // save data
                    r_d_in <= l_rx_word;
                    // start echo data
                    r_ps <= S_ECHO_DATA;
                    r_tx_start <= 1;
                    r_tx_word <= l_rx_word;
                end
            end // S_WAIT_DATA

            S_ECHO_DATA: begin
                r_tx_start <= 0;
                // transmit done
                if (l_tx_idle && !r_tx_start) begin
                    // issue command to controller
                    r_ps <= S_CTRLR;
                    r_out_valid <= 1;
                end
            end // S_ECHO_DATA

            S_CTRLR: begin
                r_out_valid <= 0;
                if (!ctrlr_busy && !r_out_valid) begin
                    // stop issue
                    r_ps <= S_REPLY;
                    // start reply
                    r_tx_word <= d_rd;
                    r_tx_start <= 1;
                end
            end // S_CTRLR

            S_REPLY: begin
                r_tx_start <= 0;
                if (l_tx_idle && !r_tx_start) begin
                    r_ps <= S_WAIT_CMD;
                end
            end // S_REPLY

            S_PROG_RCV: begin
                if (l_rx_ready) begin
                    r_d_in <= l_rx_word;
                    r_out_valid <= 1;
                    r_time <= 0;
                    r_ps <= S_PROG_WR;
                end
                else if (r_time >= TIMEOUT_COUNT) begin
                    r_time     <= 0;
                    r_ps       <= S_WAIT_CMD;
                end
                else begin
                    r_time <= r_time + 1;
                end
            end
            
            S_PROG_WR: begin
                r_out_valid <= 0;
                r_addr <= r_addr + 4;
                r_ps <= S_PROG_RCV;
            end

        endcase // r_ps
    end // always_ff

endmodule // module serial
