//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly, SLO
// Engineer: Trevor McKay
// 
// Module Name: Otter General Purpose Controller (OGPC)
// Description: Hardware module to add support for remote debugging, programming,
// etc. via low-level control of a target MCU.
// 
// Revision: 0.20
//
// Revision  0.01 - File Created
// Revision  0.10 - Controller first rev.
// Revision  0.11 - Increase project scope
// Revision  0.20 - First rev. serial module, byte granularity
//
// TODO:
//   - serial decoder
//   - MCU integration
//   - testing
//   - write documentation
/////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

typedef enum logic [3:0] {
    // arguments: 0 bytes
    FN_NONE        = 4'h0,
    FN_PAUSE       = 4'h1,
    FN_RESUME      = 4'h2,
    FN_STEP        = 4'h3,
    FN_RESET       = 4'h4,
    FN_STATUS      = 4'h5, // reply

    // arguments: 4 bytes
    FN_MEM_RD_BYTE = 4'h6, // reply
    FN_MEM_RD_WORD = 4'h7, // reply
    FN_REG_RD      = 4'h8, // reply
    FN_BR_PT_ADD   = 4'h9,
    FN_BR_PT_RM    = 4'hA,

    // arguments: 4 bytes + 4 bytes
    FN_MEM_WR_BYTE = 4'hB, // recieves whole word for simplicity
    FN_MEM_WR_WORD = 4'hC,
    FN_REG_WR      = 4'hD
} DEBUG_FN;

/////////////////////////////////////////////////////////////////////////////////
// Module Name: Controller Wrapper
// Description: Link the serial decoder and controller FSM 
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
    output valid
);

    logic l_ctrlr_busy, l_serial_valid;
    DEBUG_FN l_debug_fn;
    logic [31:0] l_addr;

    assign addr = l_addr;

    serial serial(
        .clk(clk),
        .reset(1'b0),
        .srx(srx),
        .ctrlr_busy(l_ctrlr_busy),
        .d_rd(d_rd),
        .error(error),
        
        .stx(stx),
        .debug_fn(l_debug_fn),
        .addr(l_addr),
        .d_in(d_in),
        .out_valid(l_serial_valid)
    );
    
    controller_fsm fsm(
        .clk(clk),
        .debug_fn(l_debug_fn),
        .addr(l_addr),
        .in_valid(serial_valid),
        .pc(pc),
        .mcu_busy(mcu_busy),

        .pause(pause),
        .reset(reset),
        .resume(resume),
        .rf_rd(rf_rd),
        .rf_wr(rf_wr),
        .mem_rd(mem_rd),
        .mem_wr(mem_wr),
        .out_valid(valid),
        .ctrlr_busy(l_ctrlr_busy)
    );
    
endmodule // module mcu_controller


/////////////////////////////////////////////////////////////////////////////////
// Module Name: Serial Decoder
// Description: Decode incoming UART commands and encode responses
/////////////////////////////////////////////////////////////////////////////////

module serial(
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

    // sdec -> controller
        output DEBUG_FN debug_fn,
        output [31:0] addr,
        output [31:0] d_in,
        output out_valid
);

    typedef enum logic [2:0] {
        S_IDLE,
        S_RCV_ADDR,
        S_RCV_DATA,
        S_CTRLR,
        S_REPLY_SE,
        S_REPLY_DATA
    } STATE;

    STATE r_ps = S_IDLE;

    // Debug function is a register because the protocol
    // designates that this signal will remain steady while
    // the MCU is busy.
    reg [3:0] r_debug_fn;

    // Byte to be sent back to the host machine.
    reg [7:0] r_send_byte;

    // Hold onto data read from MCU
    reg [31:0] r_d_rd;

    // Byte read by the UART reciever. Only valid when
    // l_rx_done is high which will only be so
    // for one clock cycle.
    logic [7:0] l_rcv_byte;
    logic l_rx_done;

    // Various signals for UART transmitter. Drive l_tx_valid
    // when transmission begins. Drive l_tx_done
    // high when transmission is finished. The transmitter will
    // set l_tx_active high while transmission is occurring.
    logic l_tx_done, l_tx_active;
    reg r_tx_valid = 0;
    reg [31:0] r_d_in, r_addr;

    // Index for combining multiple bytes into one data.
    reg [1:0] r_index;

    // Drive r_out_valid high when debug_fn, addr, and d_in have
    // the necessary data for the desired function.
    reg r_out_valid = 0;

    // Connect outputs to their respective registers.
    assign out_valid = r_out_valid;
    assign d_in = r_d_in;
    assign addr = r_addr;
    assign debug_fn = DEBUG_FN'(r_debug_fn);

    always_ff @(posedge clk) begin

        case(r_ps)

            // Wait here before or during recieve phase
            S_IDLE: begin
                // UART reciever has a byte
                if (l_rx_done) begin
                    
                    // function is bottom 4 bits of recieved data
                    r_debug_fn <= l_rcv_byte[3:0];

                    // Check function to see if more data is needed
                    // Debug functions >5 need at least four more bytes of arguments
                    // for the address
                    if (l_rcv_byte[3:0] > 'h5) begin
                        r_ps <= S_RCV_ADDR;
                    end
                    // all other functions can immediately be issued
                    else begin
                        r_ps <= S_CTRLR;
                        r_out_valid <= 1;
                    end
                end // if (l_rx_done)
                else begin
                    r_ps <= S_IDLE;
                end
            end // S_IDLE

            S_RCV_ADDR: begin
                // if a byte is ready: shift register, then add new byte
                if (l_rx_done) begin
                    r_addr <= (r_addr << 8) + l_rcv_byte;
                    // 4 bytes have been recieved
                    if (r_index == 3) begin
                        // functions >A need data as well
                        if (r_debug_fn > 'hA) begin
                            r_ps <= S_RCV_DATA;
                            r_index <= 0;
                        end
                        // otherwise, send cmd to controller
                        else begin
                            r_ps <= S_CTRLR;
                            r_out_valid <= 1;
                        end
                    end // if (r_index == 3)
                    else begin
                        r_index <= r_index + 1;
                        r_ps <= S_RCV_ADDR;
                    end
                end // if (l_rx_done);
                else
                    r_ps <= S_RCV_ADDR;
            end // S_RCV_ADDR

            S_RCV_DATA: begin
                // if a byte is ready: shift register, then add new byte
                if (l_rx_done) begin
                    r_d_in <= (r_d_in << 8) + l_rcv_byte;
                    // 4 bytes have been recieved
                    if (r_index == 3) begin
                        r_ps <= S_CTRLR;

                        r_out_valid <= 1;
                    end
                    else begin
                        r_index <= r_index + 1;
                        r_ps <= S_RCV_DATA;
                    end
                end // if (l_rx_done);
                else begin
                    r_ps <= S_RCV_DATA;
                end
            end // S_RCV_DATA

            S_CTRLR: begin
                r_out_valid <= 0;
                if (ctrlr_busy)
                    r_ps <= S_CTRLR;
                else begin 
                    r_ps <= S_REPLY_SE;
                    // send 0 for success, 1 for error
                    r_send_byte <= error;
                    r_tx_valid <= 1;
                    r_d_rd <= d_rd;
                end
            end // S_CTRLR

            S_REPLY_SE: begin
                r_tx_valid <= 0;
                if (l_tx_done) begin
                    r_ps <= S_REPLY_SE;
                end
                // send first byte of word
                else begin
                    r_ps <= S_REPLY_DATA;
                    r_send_byte <= r_d_rd[7:0];
                    r_d_rd <= r_d_rd >> 8;
                    r_tx_valid <= 1;
                    r_index <= 1;
                end
            end // S_REPLY_SE

            S_REPLY_DATA: begin
                if (l_tx_done) begin
                    if (r_index == 3)
                        r_ps <= S_IDLE;
                    else begin
                        r_index <= r_index + 1;
                        r_send_byte <= r_d_rd[7:0];
                        r_d_rd <= r_d_rd >> 8;
                        r_tx_valid <= 1;
                        r_ps <= S_REPLY_DATA;
                    end
                end
                else begin
                    r_tx_valid <= 0;
                    r_ps <= S_REPLY_DATA;
                end
            end // S_REPLY_SE

        endcase // case(r_ps)
    end // always_ff @(posedge clk)

    uart_rx reciever(
        .i_Clock(clk),
        .i_Rx_Serial(srx),

        .o_Rx_DV(l_rx_done),
        .o_Rx_Byte(l_rcv_byte)
    );

    uart_tx transmitter(
        .i_Clock(clk),
        .i_Tx_DV(l_tx_valid),
        .i_Tx_Byte(r_send_byte),

        .o_Tx_Active(l_tx_active),
        .o_Tx_Serial(stx),
        .o_Tx_Done(l_tx_done)
    );

endmodule // module serial


/////////////////////////////////////////////////////////////////////////////////
// Module Name: Controller FSM
// Description: Issue relevent control signals for each debug function
/////////////////////////////////////////////////////////////////////////////////

module controller_fsm(
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
            output logic mem_rw_byte,

        // controller -> sdec
            output logic ctrlr_busy
    );
    
    // keep track of mcu state
    reg r_mcu_paused = 0;
    logic l_mcu_paused_in;

    // breakpoints
    logic [31:0] break_pts[8];
    initial
        for (int i = 0; i < 8; i++)
            break_pts[i] = 'Z;
    reg [2:0] r_num_break_pts = 0;
    logic l_bp_add, l_hit;

    // states for controller
    typedef enum logic [3:0] {
        S_IDLE,
        S_WAIT_PAUSE,
        S_WAIT_RESUME,
        S_WAIT_MEM_RD,
        S_WAIT_MEM_WR,
        S_WAIT_REG_RD,
        S_WAIT_REG_WR,
        S_WAIT_STEP,
        S_BREAK_HIT
    } STATE;
    
    STATE r_ps = S_IDLE, l_ns; 
    
    always_ff @(posedge clk) begin
        // update paused state
        r_mcu_paused <= l_mcu_paused_in; 

        // compare pc to all breakpoints
        l_hit = 0;
        if (!r_mcu_paused) begin
            for (int i = 0; i < 8; i++) begin
                if ((pc + 4) == break_pts[i]) begin
                    r_ps <= S_BREAK_HIT;
                    l_hit = 1;
                end
            end
        end
        if (!l_hit) r_ps <= l_ns;
        
        // load in new breakpoints
        if (l_bp_add) begin
            break_pts[r_num_break_pts] <= addr;
            r_num_break_pts <= r_num_break_pts + 1;
        end
    end // always_ff @(posedge clk)
    
    always_comb begin
        pause = 0;
        reset = 0;
        resume = 0;
        l_bp_add= 0;
        rf_rd = 0;
        rf_wr = 0;
        mem_rd = 0;
        mem_wr = 0;
        mem_rw_byte = 0;
        l_ns  = S_IDLE;

        /* controller will output no commands and
        * accept no input in its default state */
        
        // output is invalid unless specified
        out_valid = 0;
        // busy unless specified
        ctrlr_busy = 1;

        // keep these values by default
        l_mcu_paused_in = r_mcu_paused;

        case(r_ps)

            S_IDLE: begin
                // check for valid from sdec high
                if (in_valid) begin
                    case(debug_fn)
                        FN_PAUSE: begin
                            pause = 1;
                            out_valid = 1;
                            l_ns = S_WAIT_PAUSE;
                        end
                        FN_RESUME: begin
                            resume = 1;
                            out_valid = 1;
                            l_ns = S_WAIT_RESUME;
                        end
                        FN_STEP: begin
                            // step only supported if MCU is paused
                            if (r_mcu_paused) begin
                                resume = 1;
                                out_valid = 1;
                                l_ns = S_WAIT_STEP;
                               end
                            else begin
                                ctrlr_busy = 0;
                                l_ns = S_IDLE;
                            end
                        end
                        FN_BR_PT_ADD: begin
                            ctrlr_busy = 0;
                            l_bp_add = 1;
                            l_ns = S_IDLE;
                        end
                        FN_MEM_RD_WORD: begin
                            mem_rd = 1;
                            l_ns = S_WAIT_MEM_RD;
                        end
                        FN_MEM_WR_WORD: begin
                            mem_wr = 1;
                            l_ns = S_WAIT_MEM_WR;
                        end
                        FN_MEM_RD_BYTE: begin
                            mem_rd = 1;
                            mem_rw_byte = 1;
                            l_ns = S_WAIT_MEM_RD;
                        end
                        FN_MEM_WR_BYTE: begin
                            mem_wr = 1;
                            mem_rw_byte = 1;
                            l_ns = S_WAIT_MEM_WR;
                        end

                    endcase // case(debug_fn)
                end            
                // no command given, stay idle
                else begin
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end
            end
            
            S_WAIT_PAUSE: begin
                if (mcu_busy) begin
                    out_valid = 1;
                    pause = 1;
                    l_ns = S_WAIT_PAUSE;
                end
                else begin
                    l_mcu_paused_in = 1;
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end
            end

            S_WAIT_RESUME: begin
                if (mcu_busy) begin
                    resume = 1;
                    out_valid = 1;
                    l_ns = S_WAIT_RESUME;
                end
                else begin
                    l_mcu_paused_in = 0;
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end
            end

            S_WAIT_STEP: begin
                out_valid = 1;
                // wait for resume
                if (mcu_busy) begin
                    resume = 1;
                    l_ns = S_WAIT_STEP;
                end
                // pause on next cycle
                else begin
                    pause = 1;
                    l_ns = S_WAIT_PAUSE;
                end
            end

            S_WAIT_MEM_RD: begin
                if (mcu_busy) begin
                    out_valid = 1;
                    mem_rd = 1;
                    l_ns = S_WAIT_MEM_RD;
                end
                else begin
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end
            end

            S_WAIT_MEM_WR: begin
                if (mcu_busy) begin
                    out_valid = 1;
                    mem_wr = 1;
                    l_ns = S_WAIT_MEM_RD;
                end
                else begin
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end
            end

            S_WAIT_REG_RD: begin
                if (mcu_busy) begin
                    out_valid = 1;
                    rf_rd = 1;
                    l_ns = S_WAIT_REG_RD;
                end
                else begin
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end
            end

            S_WAIT_REG_WR: begin
                if (mcu_busy) begin
                    out_valid = 1;
                    rf_wr = 1;
                    l_ns = S_WAIT_REG_WR;
                end
                else begin
                    ctrlr_busy = 0;
                    l_ns = S_IDLE;
                end
            end

            S_BREAK_HIT: begin
                pause = 1;
                out_valid = 1;
                l_ns = S_WAIT_PAUSE;
            end

            default: l_ns = S_IDLE;
        endcase // case(r_ps)

    end // always_comb

endmodule // module controller_fsm
