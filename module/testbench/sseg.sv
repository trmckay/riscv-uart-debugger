`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/29/2018 12:58:25 AM
// Design Name: 
// Module Name: SevSegDisp
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


module sseg_disp(
    input CLK,
    input MODE,
    input [15:0] DATA_IN,
    output [7:0] CATHODES,
    output [3:0] ANODES
    );

    logic [15:0] BCD_Val;
    logic [15:0] Hex_Val;
    
    BCD BCDMod (.HEX(DATA_IN), .THOUSANDS(BCD_Val[15:12]), 
                .HUNDREDS(BCD_Val[11:8]), .TENS(BCD_Val[7:4]),
                .ONES(BCD_Val[3:0]));
    
    CathodeDriver CathMod (.HEX(Hex_Val), .CLK(CLK), .CATHODES(CATHODES), 
                            .ANODES(ANODES));
    
    // MUX to switch between HEX and BCD input
    always_comb begin
        if (MODE == 1'b1)
            Hex_Val = BCD_Val;
        else
            Hex_Val = DATA_IN;
    end
    
    
endmodule


////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: Paul Hummel
//
// Create Date: 06/28/2018 11:50:35 PM
// Module Name: CathodeDriver
// Target Devices: Basys3, 4 digit 7 segment display
// Description: Display hex values on a 4 digit 7 segment display with common
//              anode and common cathode, both configured as negative logic so
//              0s in the CATHODE light up the segments for any digit
//              corresponding with a 0 in the ANODE
//
//              CATHODES = {dp,a,b,c,d,e,f,g}
//              ANODES = {d4, d3, d2, d1}
//
// Revision:
// Revision 0.01 - File Created
////////////////////////////////////////////////////////////////////////////////


module CathodeDriver(
    input CLK,
    input [15:0] HEX,
    output logic [7:0] CATHODES,
    output logic [3:0] ANODES
    );
    
    logic s_clk_500 = 1'b0;             // 250Hz refresh clock
    logic [1:0] r_disp_digit = 2'b00;   // current digit being displayed
    logic [19:0] clk_div_counter = 20'h00000;

    // Clock Divider to create 500 Hz refresh from 100 MHz clock
	always_ff @(posedge CLK) begin
        clk_div_counter = clk_div_counter + 1;
        
        // x186A0 = 1*10^5 = 1 ms toggle (x30D40)
        if ( clk_div_counter == 20'h186A0) begin
            clk_div_counter = 20'h00000;
            s_clk_500 = ~s_clk_500;   // toggle every 1 ms creates 500 Hz clock
        end
    end
    
    // Refresh Seven Segment Display every 240 Hz
    always_ff @(posedge s_clk_500) begin
        case (r_disp_digit)
            2'b00: begin
                ANODES= 4'b1110;
                case (HEX[3:0])
                    4'b0000: CATHODES = 8'b10000001; //0
                    4'b0001: CATHODES = 8'b11001111; //1
                    4'b0010: CATHODES = 8'b10010010; //2
                    4'b0011: CATHODES = 8'b10000110; //3
                    4'b0100: CATHODES = 8'b11001100; //4
                    4'b0101: CATHODES = 8'b10100100; //5
                    4'b0110: CATHODES = 8'b10100000; //6
                    4'b0111: CATHODES = 8'b10001111; //7
                    4'b1000: CATHODES = 8'b10000000; //8
                    4'b1001: CATHODES = 8'b10001100; //9
                    4'b1010: CATHODES = 8'b10001000; //a
                    4'b1011: CATHODES = 8'b11100000; //b
                    4'b1100: CATHODES = 8'b10110001; //c
                    4'b1101: CATHODES = 8'b11000010; //d
                    4'b1110: CATHODES = 8'b10110000; //e
                    4'b1111: CATHODES = 8'b10111000; //f
                    default: CATHODES = 8'b11111111; // failsafe turn off
                endcase
            end
            2'b01: begin
                ANODES= 4'b1101;
                case (HEX[7:4])
                    4'b0000: CATHODES = 8'b10000001;
                    4'b0001: CATHODES = 8'b11001111;
                    4'b0010: CATHODES = 8'b10010010;
                    4'b0011: CATHODES = 8'b10000110;
                    4'b0100: CATHODES = 8'b11001100;
                    4'b0101: CATHODES = 8'b10100100;
                    4'b0110: CATHODES = 8'b10100000;
                    4'b0111: CATHODES = 8'b10001111;
                    4'b1000: CATHODES = 8'b10000000;
                    4'b1001: CATHODES = 8'b10001100;
                    4'b1010: CATHODES = 8'b10001000; //a
                    4'b1011: CATHODES = 8'b11100000;
                    4'b1100: CATHODES = 8'b10110001;
                    4'b1101: CATHODES = 8'b11000010;
                    4'b1110: CATHODES = 8'b10110000;
                    4'b1111: CATHODES = 8'b10111000;
                    default: CATHODES = 8'b11111111; // all off on error
                endcase
            end
            2'b10: begin
                ANODES= 4'b1011;
                case (HEX[11:8])
                    4'b0000: CATHODES = 8'b10000001;
                    4'b0001: CATHODES = 8'b11001111;
                    4'b0010: CATHODES = 8'b10010010;
                    4'b0011: CATHODES = 8'b10000110;
                    4'b0100: CATHODES = 8'b11001100;
                    4'b0101: CATHODES = 8'b10100100;
                    4'b0110: CATHODES = 8'b10100000;
                    4'b0111: CATHODES = 8'b10001111;
                    4'b1000: CATHODES = 8'b10000000;
                    4'b1001: CATHODES = 8'b10001100;
                    4'b1010: CATHODES = 8'b10001000; //a
                    4'b1011: CATHODES = 8'b11100000;
                    4'b1100: CATHODES = 8'b10110001;
                    4'b1101: CATHODES = 8'b11000010;
                    4'b1110: CATHODES = 8'b10110000;
                    4'b1111: CATHODES = 8'b10111000;
                    default: CATHODES = 8'b11111111; // all off on error
                endcase
            end
            2'b11: begin
                ANODES= 4'b0111;
                case (HEX[15:12])
                    4'b0000: CATHODES = 8'b10000001;
                    4'b0001: CATHODES = 8'b11001111;
                    4'b0010: CATHODES = 8'b10010010;
                    4'b0011: CATHODES = 8'b10000110;
                    4'b0100: CATHODES = 8'b11001100;
                    4'b0101: CATHODES = 8'b10100100;
                    4'b0110: CATHODES = 8'b10100000;
                    4'b0111: CATHODES = 8'b10001111;
                    4'b1000: CATHODES = 8'b10000000;
                    4'b1001: CATHODES = 8'b10001100;
                    4'b1010: CATHODES = 8'b10001000; //a
                    4'b1011: CATHODES = 8'b11100000;
                    4'b1100: CATHODES = 8'b10110001;
                    4'b1101: CATHODES = 8'b11000010;
                    4'b1110: CATHODES = 8'b10110000;
                    4'b1111: CATHODES = 8'b10111000;
                    default: CATHODES = 8'b11111111; // all off on error
                endcase
            end
            default: begin      // digit error turn everything off
                ANODES = 4'hF;
                CATHODES = 8'hFF;
                r_disp_digit = 2'b00;
            end
        endcase
        
        r_disp_digit = r_disp_digit + 1;
    end
    
endmodule


//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: Paul Hummel
//
// Module Name: BCD
// Target Devices: Used for displaying decimal on a 4 digit 7 segment display
// Description: Conversts a 16-bit value into 4 digit binary coded decimal
//              The full 16-bit range intput cannot be converted because the
//              output is limited to 4 digiets. Anything above 4 digiets gets
//              truncated so 12345 is output as 2345
//
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////


module BCD(
    input [15:0] HEX,
    output logic [3:0] THOUSANDS,
    output logic [3:0] HUNDREDS,
    output logic [3:0] TENS,
    output logic [3:0] ONES
    );
    
    int i;
    
    /*
    logic block to convert binary to 4 digit BCD (0000 - 1001)
    start with MSB and shift each bit left to fit into each place value.
    THOUSANDS, HUNDREDS, TENS, and ONES.
    
    Each shift left is the equivalent of x 2, so if current value is 5 or
    greater, the next shift should increment the next place value.
    By adding 3 to the current place value will set this to occur on the
    next shift. See 2 examples below
            
    5 will shift a 1 to next place value and put 0 in the current place value
    to create 10 (5 x 2)
    0101 -> 1000 -> shift -> xxx1 000x
               
    7 will shift a 1 to the next place value and put 4 in current place value
    to create 14 (7 x 2)
    0111 -> 1010 -> shift -> xxx1 010x
    */
    
    always_comb begin
        THOUSANDS = 4'h0; // default all digits to 0
        HUNDREDS = 4'h0;
        TENS = 4'h0;
        ONES = 4'h0;
        
        // iterate through each bit, starting with MSB (bit 15)
        for (i=15; i>=0; i=i-1) begin
            
            // check for place values of 5 or greater
            if (THOUSANDS >= 5)
                THOUSANDS = THOUSANDS + 3;
            if (HUNDREDS >= 5)
                HUNDREDS = HUNDREDS + 3;
            if (TENS >= 5)
                TENS = TENS + 3;
            if (ONES >= 5)
                ONES = ONES + 3;
            
            // shift bits to the left
            THOUSANDS = {THOUSANDS[2:0],HUNDREDS[3]};
            HUNDREDS = {HUNDREDS[2:0],TENS[3]};
            TENS = {TENS[2:0],ONES[3]};
            ONES = {ONES[2:0],HEX[i]};
       end
   end
      
endmodule