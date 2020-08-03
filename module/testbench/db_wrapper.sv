
module db_wrapper(
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
    reg [31:0] r_addr, r_d_in;
    logic [31:0] addr, d_in;
    logic [31:0] counter = 0;
    reg [31:0] r_rand = 0;
    reg [15:0] r_sseg_data;
    logic pause, resume;
    reg [15:0] r_led = 0;
    reg paused = 0;

    assign led = r_led;
    assign busy = valid || (counter > 0);

    sseg_disp sseg(
        .DATA_IN(r_sseg_data),
        .CLK(clk),
        .MODE(1'b0),
        .CATHODES(seg),
        .ANODES(an)
    );

    mcu_controller ctrlr(
        .clk(clk),
        .srx(srx),
        .stx(stx),
        .mcu_busy(busy),
        .d_rd(r_rand),
        .error(0),
        .addr(addr),
        .d_in(d_in),
        .valid(valid),
        .pause(pause),
        .resume(resume)
    );

    // create 50 MHz clock
    always_ff @(posedge clk_100MHz) begin
        clk = ~clk;
    end // always_ff
    
    always_ff @(posedge clk) begin
        if (!paused)
            r_rand <= r_rand + 1;
        if (valid) begin
            r_led[15] <= 1;
            counter <= 50000000;
            if (pause) begin
                r_led[0] <= 1;
                paused <= 1;
            end
            if (resume)
                r_led[0] <= 0;
            r_d_in <= d_in;
            r_addr <= addr;
        end
        if (counter > 0)
            counter <= counter - 1;

    end // always_ff

endmodule // serial_hw_testbench
