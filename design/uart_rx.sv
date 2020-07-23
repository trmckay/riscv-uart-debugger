`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////
//
// File Downloaded from http://www.nandland.com
//
//////////////////////////////////////////////////////////////////////
//
// Changes by Keefe Johnson:
//   Upgraded to SystemVerilog with minor changes.
//   Made counter size dynamic to handle low baud with fast clock.
//   NOTE: Not adding a reset, to avoid garbage (starting mid-byte).
//
// Changes by Trevor McKay:
//   Some formatting and documentation.
//
//////////////////////////////////////////////////////////////////////
//
// This file contains the UART Receiver.  This receiver is able to
// receive 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  When receive is complete o_rx_dv will be
// driven high for one clock cycle.
// 
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87
//
/////////////////////////////////////////////////////////////////////

// TODO: overwrite CLKS_PER_BIT

module uart_rx #(parameter CLKS_PER_BIT = -1)(
    input        i_Clock,
    input        i_Rx_Serial,

    output       o_Rx_DV,
    output [7:0] o_Rx_Byte
);

    localparam CNT_SIZE = $clog2(CLKS_PER_BIT);  // can count up to CLKS_PER_BIT-1
    
    // states for fsm
    localparam s_IDLE         = 3'b000;
    localparam s_RX_START_BIT = 3'b001;
    localparam s_RX_DATA_BITS = 3'b010;
    localparam s_RX_STOP_BIT  = 3'b011;
    localparam s_CLEANUP      = 3'b100;
       

    reg r_Rx_Data_R = 1'b1;
    reg r_Rx_Data   = 1'b1;
   
    logic [CNT_SIZE-1:0]  r_Clock_Count = 0;
    logic [2:0]           r_Bit_Index   = 0; //8 bits total
    logic [7:0]           r_Rx_Byte     = 0;
    logic                 r_Rx_DV       = 0;
    logic [2:0]           r_SM_Main     = 0;
   
    // Purpose: Double-register the incoming data.
    // This allows it to be used in the UART RX Clock Domain.
    // (It removes problems caused by metastability)
    always_ff @(posedge i_Clock) begin
        r_Rx_Data_R <= i_Rx_Serial;
        r_Rx_Data   <= r_Rx_Data_R;
    end
   
   
    /* Purpose: Control RX state machine
    *
    * s_IDLE:
    *   Wait here until start bit detected.
    *   When start bit detected, transition to
    *   s_RX_START_BIT.
    *
    * s_RX_START_BIT:
    *   Make sure start bit stays low, then
    *   transition to s_RX_DATA_BITS.
    *   Otherwise, go to s_RX_IDLE.
    *
    * s_RX_DATA_BITS:
    *   Poll data after each delay to
    *   assemble the byte. Then, go to
    *   s_RX_STOP_BIT.
    *
    * s_RX_STOP_BIT:
    *   Wait for stop bit, then go to
    *   s_RX_CLEANUP.
    *
    * s_RX_CLEANUP:
    *   Stay for one clock cycle then return
    *   to s_RX_IDLE.
    */

    always_ff @(posedge i_Clock) begin
       
        case (r_SM_Main)
        
            s_IDLE: begin
                r_Rx_DV       <= 1'b0;
                r_Clock_Count <= 0;
                r_Bit_Index   <= 0;
            
                // start bit detected
                if (r_Rx_Data == 1'b0)          
                    r_SM_Main <= s_RX_START_BIT;
                else
                    r_SM_Main <= s_IDLE;
            end // s_IDLE
        

            // Check middle of start bit to make sure it's still low
            s_RX_START_BIT: begin
                if (r_Clock_Count == (CLKS_PER_BIT-1)/2) begin
                    if (r_Rx_Data == 1'b0)
                    begin
                        r_Clock_Count <= 0;  // reset counter, found the middle
                        r_SM_Main     <= s_RX_DATA_BITS;
                    end
                    else
                        r_SM_Main <= s_IDLE;
                end
                else begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    r_SM_Main     <= s_RX_START_BIT;
                end
            end // s_RX_START_BIT
         
         
            // wait CLKS_PER_BIT-1 clock cycles to sample serial data
            s_RX_DATA_BITS: begin
                // need to wait more
                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    // stay in state
                    r_SM_Main     <= s_RX_DATA_BITS;
                end
                // done waiting
                else begin
                    // reset counter
                    r_Clock_Count          <= 0;
                    // read a bit
                    r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
                     
                    // check if we have received all bits
                    if (r_Bit_Index < 7) begin
                        // next bit 
                        r_Bit_Index <= r_Bit_Index + 1;
                        // stay in state to keep recieving
                        r_SM_Main   <= s_RX_DATA_BITS;
                    end
                    else begin
                        r_Bit_Index <= 0;
                        r_SM_Main   <= s_RX_STOP_BIT;
                    end
                end // else
            end // s_RX_DATA_BITS
         
         
            // Receive Stop bit.  Stop bit = 1
            s_RX_STOP_BIT: begin
                // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    r_SM_Main     <= s_RX_STOP_BIT;
                end
                else begin
                    r_Rx_DV       <= 1'b1;
                    r_Clock_Count <= 0;
                    r_SM_Main     <= s_CLEANUP;
                end
            end // s_RX_STOP_BIT 
            

            // Stay here 1 clock
            s_CLEANUP: begin
                r_SM_Main <= s_IDLE;
                r_Rx_DV   <= 1'b0;
            end // s_Cleanup
     
             
            default: r_SM_Main <= s_IDLE;
         
        endcase // case(r_SM_Main) 
    end // always_ff @(posedge clk)
   
    assign o_Rx_DV   = r_Rx_DV;
    assign o_Rx_Byte = r_Rx_Byte;
   
endmodule // uart_rx
