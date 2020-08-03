
module serial_board_testbench(
    input clk_100MHz,
    input srx,
    output [15:0] led,
    output [7:0] seg,
    output [3:0] an,
    output stx
);
    logic [3:0] cmd;
    reg [3:0] r_last_cmd = 0;
    logic clk = 0;
    logic valid, busy;
    logic [31:0] addr, d_in;
    logic [7:0] counter = 0;

    assign led[1:0] = {stx, srx};
    assign led[15] = valid;
    
    assign busy = (counter > 0);

    sseg_disp sseg(
        .DATA_IN(r_last_cmd),
        .CLK(clk),
        .MODE(1'b0),
        .CATHODES(seg),
        .ANODES(an)
    );

    serial_driver #(
        .BAUD(115200), // baud   (bit/s)
        .CLK_RATE(50)  // clk rate (MHz)
    ) sdrv(
        .clk(clk),
        .reset(0),
        .srx(srx),
        .stx(stx),
        .ctrlr_busy(busy),
        .d_rd(0),
        .error(0),
        .cmd(cmd),
        .addr(addr),
        .d_in(d_in),
        .out_valid(valid)
    );

    // create 50 MHz clock
    always_ff @(posedge clk_100MHz) begin
        clk = ~clk;
    end // always_ff
    
    always_ff @(posedge clk) begin
        if (valid) begin
            counter <= 0;
            r_last_cmd <= cmd;
        end
        if (counter > 0)
             counter <= counter - 1;
    end // always_ff

endmodule // serial_hw_testbench
