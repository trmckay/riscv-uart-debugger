`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Keefe Johnson
// 
// Create Date: 05/09/2019 05:27:29 PM
// Design Name: 
// Module Name: debugger (originally programmer)
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.20 - Upgraded to debugger
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module debugger #(
    parameter CLK_RATE = -1,          // rate of clk in MHz (must override)
    parameter BAUD = 115200,          // raw serial rate in bits/s (may be overriden in parent)
    parameter IB_TIMEOUT = 200,       // timeout during word in ms (may be override in parent)
    parameter WAIT_TIMEOUT = 500,     // timeout during multi-word cmd in ms (may be override in parent)
    parameter MAX_HW_BREAKPOINTS = 8  // number of hardware breakpoint registers (may be override in parent)
    )(
    input clk,
    input rst,
    input srx,
    output stx,
    output mcu_reset,
    output cu_pause,
    input cu_pausable,
    input cu_paused,
    output logic [31:0] mem_addr,
    output logic [31:0] mem_din,
    input [31:0] mem_dout,
    output logic mem_en,
    output logic mem_we,
    output logic [4:0] rf_addr,
    output logic [31:0] rf_din,
    input [31:0] rf_dout,
    output logic rf_en,
    output logic rf_we,
    output logic [11:0] csr_addr,
    output logic [31:0] csr_din,
    input [31:0] csr_dout,
    output logic csr_en,
    output logic csr_we,
    output logic [31:0] pc_din,
    input [31:0] pc_dout,
    output logic pc_en,
    output logic pc_we,
    input [31:0] pc_next
    );

    // NOTE: the FSM here assumes that mem is 0-latency sync-read (data available cycle after addr/en) and rf/csr/pc is
    //   async-read, otherwise the FSM would need to be adjusted

    // communication format:
    // all communication is in 32-bit words
    //
    //   debugger                              <-->  PC
    //   -----------------------------------------------------------------
    //                                         <--   cmd (1 word)
    //   echo of cmd (1 word)                   -->
    //                                         <--   args+wdata (0+ words)
    //   rdata (0+ words)                       -->
    //   cksum of args+wdata+rdata (0/1 word)   -->
    //
    // if any failure occurs, the exchange is terminated early and an error code is sent to the PC, in which case the
    //   action may have been partially completed/committed
    // TODO: implement propagation of a signal (resulting in an error code to PC) for serial timeout mid-word
    // the cksum is sent if and only if the appropriate number of words are received/sent after the cmd echo
    // the cksum is currently a simple cumulative xor of all words
    // TODO: replace XOR with a more robust checksum algo (CRC32?)
    // TODO: prevent collision of cksum with error code(s)
    // the echo of cmd is sent immediately except for the pause command, where status is confirmed before echo
    // the cksum for args+wdata is sent only after the wdata has been committed to the MCU
    // registers include RF, CSR, and PC, with the addr distinguishing among them:
    //   0-31: RF
    //   32: PC
    //   65-4160: CSR (addr = CSR # + 65)
    //   others: undefined behavior

    localparam HB_IDX_WIDTH = $clog2(MAX_HW_BREAKPOINTS);

    // timeout if waiting for a serial word for too long
    localparam TIMEOUT_CLKS = CLK_RATE * WAIT_TIMEOUT * 1000;
    logic [$clog2(TIMEOUT_CLKS+1)-1:0] r_timeout_counter = 0;
    logic waiting;
    wire timed_out;
       
    // commands accepted
    localparam CMD_RESET_ON        = 24'h0FF000;  // no args, no wdata, no rdata
    localparam CMD_RESET_OFF       = 24'h0FF001;  // no args, no wdata, no rdata
    localparam CMD_WRITE_MEM_RANGE = 24'h0FF002;  // args = {addr, num_words}, wdata = 1+ words, no rdata
    localparam CMD_READ_MEM_RANGE  = 24'h0FF003;  // TODO: implement
    localparam CMD_VERSION         = 24'h0FF004;  // TODO: implement
    localparam CMD_PAUSE           = 24'h0FF005;  // no args, no wdata, no rdata 
    localparam CMD_STEP            = 24'h0FF006;  // no args, no wdata, no rdata 
    localparam CMD_CONTINUE        = 24'h0FF007;  // no args, no wdata, no rdata
    localparam CMD_STATUS          = 24'h0FF008;  // no args, no wdata, rdata = {bit1: pause, bit0: reset}
    localparam CMD_READ_MEM        = 24'h0FF009;  // args = {addr}, no wdata, rdata = 1 word
    localparam CMD_WRITE_MEM       = 24'h0FF00A;  // args = {addr}, wdata = 1 word, no rdata
    localparam CMD_READ_REG        = 24'h0FF00B;  // args = {addr}, no wdata, rdata = 1 word
    localparam CMD_WRITE_REG       = 24'h0FF00C;  // args = {addr}, wdata = 1 word, no rdata
    localparam CMD_SET_HW_BREAK    = 24'h0FF00D;  // args = {index}, wdata = {addr}, no rdata
    localparam CMD_CLR_HW_BREAK    = 24'h0FF00E;  // args = {index}, no wdata, no rdata
    
    // other constants
    localparam FAIL_RESPONSE = 32'hF00FF00F;  // invalid cmd/args or multi-word timeout
    
    // state
    typedef enum {
        IDLE, FAILED,
        WMR_WAIT_ADDR, WMR_WAIT_LEN, WMR_WAIT_DATA,
        S_PAUSE,
        WAIT_PAUSED,
        ST_SEND_STATUS,
        RM_WAIT_ADDR, RM_READ_DATA, RM_SEND_DATA,
        WM_WAIT_ADDR, WM_WAIT_DATA,
        RR_WAIT_ADDR, RR_SEND_DATA,
        WR_WAIT_ADDR, WR_WAIT_DATA,
        SHB_WAIT_INDEX, SHB_WAIT_ADDR,
        CHB_WAIT_INDEX, CHB_CLEAR,
        SEND_CKSUM
    } e_state;

    // tx_word mux select
    enum {ECHO, MEMD, REGD, STATUS, CKSUM, FAIL} sel_tx_word;

    // control signals between fsm and datapath 
    logic set_mcu_reset;
    logic clr_mcu_reset;
    logic set_cu_pause;
    logic clr_cu_pause;
    logic ld_addr;
    logic inc_addr;
    logic ld_words_remain;
    logic dec_words_remain;
    logic ld_idx;
    logic ld_hb;
    logic set_hb_valid;
    logic clr_hb_valid;
    logic clr_cksum;
    logic acc_cksum_rx;
    logic acc_cksum_tx;
    logic suppress_hb;

    // other signals
    e_state next_state;
    wire rx_ready;
    wire rx_valid;
    wire tx_idle;
    wire [31:0] rx_word;
    logic [31:0] tx_word;
    logic tx_send;
    logic [31:0] reg_dout;
    logic reg_en;
    logic we;
    logic hb_pause;

    // registers
    e_state r_state = IDLE;
    logic [31:0] r_words_remain = 0;
    logic [31:0] r_addr = 0;
    logic r_mcu_reset = 0;
    logic r_cu_pause = 0;
    logic [HB_IDX_WIDTH-1:0] r_idx = 0;
    logic [31:0] r_hb [0:MAX_HW_BREAKPOINTS-1] = '{default:0};
    logic r_hb_valid [0:MAX_HW_BREAKPOINTS-1] = '{default:0};
    logic [31:0] r_cksum = 0;

    // serial IO modules
    uart_rx_word #(
        .CLK_RATE(CLK_RATE), .BAUD(BAUD), .IB_TIMEOUT(IB_TIMEOUT)
    ) uart_rx_word (
        .clk(clk), .rst(rst), .srx(srx), .ready(rx_ready), .rx_word(rx_word)
    );
    uart_tx_word #(
        .CLK_RATE(CLK_RATE), .BAUD(BAUD)
    ) uart_tx_word (
        .clk(clk), .rst(rst), .start(tx_send), .tx_word(tx_word), .stx(stx), .idle(tx_idle)
    );
    
    // fixed combinational logic
    assign timed_out = (r_timeout_counter == TIMEOUT_CLKS);
    assign rx_valid = (rx_word[7:0] ^ rx_word[15:8] ^ rx_word[23:16] ^ rx_word[31:24]) == 0;
    assign mcu_reset = rst || r_mcu_reset;
    assign cu_pause = (r_cu_pause || hb_pause);
    assign mem_addr = r_addr;
    assign mem_din = rx_word;
    assign mem_we = we;
    assign rf_addr = r_addr;  // truncates high bits
    assign rf_din = rx_word;
    assign rf_we = we;
    assign csr_addr = r_addr - 65;  // truncates high bits
    assign csr_din = rx_word;
    assign csr_we = we;
    assign pc_din = rx_word;
    assign pc_we = we;

    // regs splitter
    always_comb begin
        rf_en = 0;
        csr_en = 0;
        pc_en = 0;
        if (r_addr < 32) begin
            rf_en = reg_en;
            reg_dout = rf_dout;
        end else if (r_addr == 32) begin
            pc_en = reg_en;
            reg_dout = pc_dout;
        end else begin
            csr_en = reg_en;
            reg_dout = csr_dout;
        end
    end

    // tx_word mux
    always_comb begin
        case (sel_tx_word)
            ECHO: tx_word = rx_word;
            MEMD: tx_word = mem_dout;
            REGD: tx_word = reg_dout;
            STATUS: tx_word = {30'b0, cu_pause, mcu_reset};
            CKSUM: tx_word = r_cksum;
            FAIL: tx_word = FAIL_RESPONSE;
            default: tx_word = FAIL_RESPONSE;
        endcase
    end
    
    // hardware breakpoint monitor
    always_comb begin
        bit hb_match;
        hb_match = 0;
        for (int i = 0; i < MAX_HW_BREAKPOINTS; i++) begin
            hb_match |= (r_hb_valid[i] && r_hb[i] == pc_next);
        end
        hb_pause = (cu_pausable && hb_match);
    end
    
    // next state and control logic
    always_comb begin
        next_state = r_state;
        waiting = 0;
        mem_en = 0;
        reg_en = 0;
        we = 0;
        set_mcu_reset = 0;
        clr_mcu_reset = 0;
        set_cu_pause = 0;
        clr_cu_pause = 0;
        ld_addr = 0;
        inc_addr = 0;
        ld_words_remain = 0;
        dec_words_remain = 0;
        ld_idx = 0;
        ld_hb = 0;
        set_hb_valid = 0;
        clr_hb_valid = 0;
        clr_cksum = 0;
        acc_cksum_rx = 0;
        acc_cksum_tx = 0;
        tx_send = 0;
        sel_tx_word = ECHO;

        case (r_state)

            IDLE: begin
                if (rx_ready && rx_valid && tx_idle) begin
                    case (rx_word[31:8]) 

                        CMD_RESET_ON: begin
                            set_mcu_reset = 1;
                            sel_tx_word = ECHO;
                            tx_send = 1;
                        end

                        CMD_RESET_OFF: begin
                            clr_mcu_reset = 1;
                            sel_tx_word = ECHO;
                            tx_send = 1;
                        end

                        CMD_WRITE_MEM_RANGE: begin
                            sel_tx_word = ECHO;
                            tx_send = 1;
                            clr_cksum = 1;
                            next_state = WMR_WAIT_ADDR;
                        end

                        CMD_PAUSE: begin
                            set_cu_pause = 1;  // pause signal will be high next cycle and beyond
                            next_state = WAIT_PAUSED;
                        end

                        CMD_STEP: begin
                            clr_cu_pause = 1;  // pause signal will be low next cycle
                            next_state = S_PAUSE;
                        end

                        CMD_CONTINUE: begin
                            clr_cu_pause = 1;  // pause signal will be low next cycle and beyond
                            sel_tx_word = ECHO;
                            tx_send = 1;
                        end

                        CMD_STATUS: begin
                            sel_tx_word = ECHO;
                            tx_send = 1;
                            clr_cksum = 1;
                            next_state = ST_SEND_STATUS;
                        end

                        CMD_READ_MEM: begin
                            sel_tx_word = ECHO;
                            tx_send = 1;
                            clr_cksum = 1;
                            next_state = RM_WAIT_ADDR;
                        end

                        CMD_WRITE_MEM: begin
                            sel_tx_word = ECHO;
                            tx_send = 1;
                            clr_cksum = 1;
                            next_state = WM_WAIT_ADDR;
                        end

                        CMD_READ_REG: begin
                            sel_tx_word = ECHO;
                            tx_send = 1;
                            clr_cksum = 1;
                            next_state = RR_WAIT_ADDR;
                        end

                        CMD_WRITE_REG: begin
                            sel_tx_word = ECHO;
                            tx_send = 1;
                            clr_cksum = 1;
                            next_state = WR_WAIT_ADDR;
                        end

                        CMD_SET_HW_BREAK: begin
                            sel_tx_word = ECHO;
                            tx_send = 1;
                            clr_cksum = 1;
                            next_state = SHB_WAIT_INDEX;
                        end

                        CMD_CLR_HW_BREAK: begin
                            sel_tx_word = ECHO;
                            tx_send = 1;
                            clr_cksum = 1;
                            next_state = CHB_WAIT_INDEX;
                        end

                    endcase   
                end
            end

            FAILED: begin
                if (tx_idle) begin
                    sel_tx_word = FAIL;
                    tx_send = 1;
                    next_state = IDLE;
                end
            end

            WMR_WAIT_ADDR: begin
                waiting = 1;
                if (timed_out) begin
                    next_state = FAILED;
                end else if (rx_ready) begin
                    waiting = 0;
                    ld_addr = 1;
                    acc_cksum_rx = 1;
                    next_state = WMR_WAIT_LEN;
                end
            end

            WMR_WAIT_LEN: begin
                waiting = 1;
                if (timed_out) begin
                    next_state = FAILED;
                end else if (rx_ready) begin
                    waiting = 0;
                    ld_words_remain = 1;
                    acc_cksum_rx = 1;
                    if (rx_word == 0) begin
                        next_state = SEND_CKSUM;
                    end else begin
                        next_state = WMR_WAIT_DATA;
                    end
                end
            end

            WMR_WAIT_DATA: begin
                waiting = 1;
                if (timed_out) begin
                    next_state = FAILED;
                end else if (rx_ready) begin
                    waiting = 0;
                    mem_en = 1;
                    we = 1;
                    acc_cksum_rx = 1;
                    inc_addr = 1;
                    dec_words_remain = 1;
                    if (r_words_remain == 1) begin
                        next_state = SEND_CKSUM;
                    end 
                end
            end

            WAIT_PAUSED: begin
                if (cu_paused || mcu_reset) begin  // if in reset state, control unit will pause on reset release
                    sel_tx_word = ECHO;
                    tx_send = 1;  // already waited for tx_idle in previous state
                    next_state = IDLE;
                end
            end
            
            S_PAUSE: begin
                set_cu_pause = 1;  // pause signal will be high next cycle and beyond
                next_state = WAIT_PAUSED;
            end

            ST_SEND_STATUS: begin
                if (tx_idle) begin
                    sel_tx_word = STATUS;
                    tx_send = 1;
                    acc_cksum_tx = 1;
                    next_state = SEND_CKSUM;
                end
            end
            
            RM_WAIT_ADDR: begin
                waiting = 1;
                if (timed_out) begin
                    next_state = FAILED;
                end else if (rx_ready) begin
                    waiting = 0;
                    ld_addr = 1;
                    acc_cksum_rx = 1;
                    next_state = RM_READ_DATA;
                end
            end

            RM_READ_DATA: begin
                if (tx_idle) begin  // wait for tx_idle now, since read data is valid for only 1 cycle
                    mem_en = 1;
                    next_state = RM_SEND_DATA;
                end
            end

            RM_SEND_DATA: begin
                sel_tx_word = MEMD;
                tx_send = 1;  // already waited for tx_idle in previous state
                acc_cksum_tx = 1;
                next_state = SEND_CKSUM;
            end

            WM_WAIT_ADDR: begin
                waiting = 1;
                if (timed_out) begin
                    next_state = FAILED;
                end else if (rx_ready) begin
                    waiting = 0;
                    ld_addr = 1;
                    acc_cksum_rx = 1;
                    next_state = WM_WAIT_DATA;
                end
            end

            WM_WAIT_DATA: begin
                waiting = 1;
                if (timed_out) begin
                    next_state = FAILED;
                end else if (rx_ready) begin
                    waiting = 0;
                    mem_en = 1;
                    we = 1;
                    acc_cksum_rx = 1;
                    next_state = SEND_CKSUM;
                end
            end

            RR_WAIT_ADDR: begin
                waiting = 1;
                if (timed_out) begin
                    next_state = FAILED;
                end else if (rx_ready) begin
                    waiting = 0;
                    ld_addr = 1;
                    acc_cksum_rx = 1;
                    next_state = RR_SEND_DATA;
                end
            end

            RR_SEND_DATA: begin
                if (tx_idle) begin
                    reg_en = 1;
                    sel_tx_word = REGD;
                    tx_send = 1;
                    acc_cksum_tx = 1;
                    next_state = SEND_CKSUM;
                end
            end

            WR_WAIT_ADDR: begin
                waiting = 1;
                if (timed_out) begin
                    next_state = FAILED;
                end else if (rx_ready) begin
                    waiting = 0;
                    ld_addr = 1;
                    acc_cksum_rx = 1;
                    next_state = WR_WAIT_DATA;
                end
            end

            WR_WAIT_DATA: begin
                waiting = 1;
                if (timed_out) begin
                    next_state = FAILED;
                end else if (rx_ready) begin
                    waiting = 0;
                    reg_en = 1;
                    we = 1;
                    acc_cksum_rx = 1;
                    next_state = SEND_CKSUM;
                end
            end

            SHB_WAIT_INDEX: begin
                waiting = 1;
                if (timed_out) begin
                    next_state = FAILED;
                end else if (rx_ready) begin
                    waiting = 0;
                    ld_idx = 1;
                    acc_cksum_rx = 1;
                    next_state = SHB_WAIT_ADDR;
                end
            end

            SHB_WAIT_ADDR: begin
                waiting = 1;
                if (timed_out) begin
                    next_state = FAILED;
                end else if (rx_ready) begin
                    waiting = 0;
                    ld_hb = 1;
                    set_hb_valid = 1;
                    acc_cksum_rx = 1;
                    next_state = SEND_CKSUM;
                end
            end

            CHB_WAIT_INDEX: begin
                waiting = 1;
                if (timed_out) begin
                    next_state = FAILED;
                end else if (rx_ready) begin
                    waiting = 0;
                    ld_idx = 1;
                    acc_cksum_rx = 1;
                    next_state = CHB_CLEAR;
                end
            end

            CHB_CLEAR: begin
                clr_hb_valid = 1;
                next_state = SEND_CKSUM;
            end

            SEND_CKSUM: begin
                if (tx_idle) begin
                    sel_tx_word = CKSUM;
                    tx_send = 1;
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    // update registers on clock ticks
    always_ff @(posedge clk) begin

        // r_state
        r_state <= next_state;

        // r_mcu_reset: set or clear
        if (set_mcu_reset) begin
            r_mcu_reset <= 1;
        end else if (clr_mcu_reset) begin
            r_mcu_reset <= 0;
        end
        
        // r_cu_pause: set or clear
        if (set_cu_pause || hb_pause) begin
            r_cu_pause <= 1;
        end else if (clr_cu_pause) begin
            r_cu_pause <= 0;
        end
        
        // r_addr: load or increment
        if (ld_addr) begin
            r_addr <= rx_word;
        end else if (inc_addr) begin
            r_addr <= r_addr + 4;
        end

        // r_words_remain: load or decrement
        if (ld_words_remain) begin
            r_words_remain <= rx_word;
        end else if (dec_words_remain) begin
            r_words_remain <= r_words_remain - 1;
        end

        // r_idx: load
        if (ld_idx) begin
            r_idx <= rx_word[HB_IDX_WIDTH-1:0];
        end

        // r_hb[]: load 
        if (ld_hb) begin
            r_hb[r_idx] <= rx_word;
        end

        // r_hb_valid[]: set or clear
        if (set_hb_valid) begin
            r_hb_valid[r_idx] <= 1;
        end else if (clr_hb_valid) begin
            r_hb_valid[r_idx] <= 0;
        end

        // r_cksum: clear or accumulate
        if (clr_cksum) begin
            r_cksum <= 0;
        end else if (acc_cksum_rx) begin
            r_cksum <= r_cksum ^ rx_word;
        end else if (acc_cksum_tx) begin
            r_cksum <= r_cksum ^ tx_word;
        end

        // r_timeout_counter: clear or increment until max
        if (waiting) begin
            if (!timed_out) begin
                r_timeout_counter <= r_timeout_counter + 1;
            end
        end else begin
            r_timeout_counter = 0;
        end

    end    
    
endmodule
