`timescale 1ns / 1ps

module serial_testbench();

    logic clk = 0;
    logic error = 0;
    logic srx = 1, stx;
    logic [3:0] cmd;
    logic reset, out_valid, ctrlr_busy=0, error;
    logic [31:0] addr, d_in, d_rd;
    logic [7:0] r_send_byte;

    localparam CLOCK_PERIOD_NS = 20;  // 50 MHz
    localparam BIT_PERIOD_NS = 86806; // 11520 baud
    
    serial sdec_UT(.*);

    // force clock
    always begin
        #(CLOCK_PERIOD_NS/2);
        clk = ~clk;
    end

    // sends the data in "r_send_byte" over serial
    `define send_byte \
        srx = 0; \
        for (int i = 0; i < 8; i++) begin \
            #(BIT_PERIOD_NS); \
            srx = r_send_byte[i]; \
        end \
        #BIT_PERIOD_NS; srx = 0; \
        #BIT_PERIOD_NS; srx = 1;

    `define wait_cycles(N) \
        #(N*CLOCK_PERIOD_NS);

    initial begin
    
        `wait_cycles(10);
        
        r_send_byte = 8'h0;
        `send_byte;
        #200
        `send_byte;
        #200
        `send_byte;
        #200
        `send_byte;
        
        #30
        ctrlr_busy = 1;
        `wait_cycles(10);
        ctrlr_busy = 0;
        
    end

endmodule // serial_testbench
