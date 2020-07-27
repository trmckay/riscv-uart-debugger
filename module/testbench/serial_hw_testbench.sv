
module serial_hw_testbench(
    input clk,
    input [7:0] sw,
    input srx,
    output [7:0] ca,
    output [3:0] an,
    output [8:0] leds,
    output stx
);

    logic [31:0] addr, d_in;
    logic pause, resume, reset,
          reg_rd, reg_wr,
          mem_rd, mem_wr, mem_rw_byte,
          valid;

    logic error, mcu_busy;
    logic [31:0] pc, d_rd;

    reg [31:0] counter = 0;
    reg [2:0] last_cmd = 0;

    mcu_controller controller(.*);
    sseg_disp sseg(
        .CLK(clk),
        .MODE(1'b0),
        .DATA_IN(last_cmd),
        .CATHODES(ca),
        .ANODES(an)
    );
    
    assign d_rd = {sw, sw, sw, sw};
    assign mcu_busy = (counter > 0);
    assign leds = {7'b0, mcu_busy};
    
    always_ff @(posedge clk) begin
        if ((reg_rd || reg_wr || mem_rd || mem_wr || pause) && valid)
            counter <= 'h10;

        if (valid) begin
            if (pause)
                last_cmd <= 1;
            else if (resume)
                last_cmd <= 2;
            else if (reg_rd)
                last_cmd <= 3;
            else if (reg_wr)
                last_cmd <= 4;
            else if (mem_rd)
                last_cmd <= 5;
            else if (mem_wr)
                last_cmd <= 6;
        end
    end // always_ff @(posedge clk)

endmodule // serial_hw_testbench
