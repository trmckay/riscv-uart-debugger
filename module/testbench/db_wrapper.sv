module db_wrapper #(
    CLK_RATE = 100,
    BAUD = 115200,
    MEM_SIZE = 64,
    RF_SIZE = 32,
    DELAY_CYCLES = 10
    )(
    input clk,
    input srx,
    output stx,
    output [15:0] led
);

    logic        valid,
                 busy,
                 pause,
                 resume,
                 reset,
                 reg_rd,
                 reg_wr,
                 mem_rd,
                 mem_wr;
    logic [3:0]  mem_be;
    logic [31:0] busy_counter = 0,
                 addr,
                 d_in,
                 d_rd,
                 word;
    reg          paused = 0;
    reg   [31:0] pc,
                 r_addr,
                 r_d_in,
                 r_d_rd = 0,
                 delay_counter = 0;
    reg   [31:0] mem[MEM_SIZE];
    reg   [31:0] rf[RF_SIZE];

    assign led  = pc[31:16];
    assign busy = valid || (busy_counter > 0);
    assign d_rd = r_d_rd;

    mcu_controller #(
        .CLK_RATE(CLK_RATE),
        .BAUD(BAUD)
        )(
        .clk(clk),
        .srx(srx),
        .stx(stx),
        .pc(pc),
        .mcu_busy(mcu_busy),
        .d_rd(r_d_rd),
        .error(1'b0),
        .d_in(d_in),
        .addr(addr),
        .pause(pause),
        .resume(resume),
        .reset(reset),
        .reg_rd(reg_rd),
        .reg_wr(reg_wr),
        .mem_rd(mem_rd),
        .mem_wr(mem_wr),
        .mem_be(mem_be),
        .valid(valid)
    );

    // initialize mem and rf
    initial begin
        for (int i = 0; i < MEM_SIZE; i++)
            mem[i] = 0;
        for (int i = 0; i < RF_SIZE;  i++)
            rf[i]  = 0;
    end

    // memory and reg file writes
    always_ff @(posedge clk) begin

        // valid: command recieced
        if (valid) begin

            // delay for N cycles (n * clock period must not exceed timeout)
            busy_counter <= DELAY_CYCLES;
            
            // save address and input data
            r_d_in <= d_in;
            r_addr <= addr;

            // reset
            if (reset) begin
                pc <= 0;
                paused <= 0;
            end

            // writes
            if (mem_wr) begin
                mem[addr]  <= d_in;
            end
            else if (reg_wr) begin
                if (addr != 0)
                    rf[addr] <= d_in;
            end

            // reads
            else if (mem_rd) begin
                r_d_rd     <= mem[addr];
            end
            else if (reg_rd) begin
                r_d_rd     <= rf[addr];
            end

            // pause
            else if (pause) begin
                paused     <= 1;
            end

            // resume
            else if (resume) begin
                paused     <= 0;
            end

        end // if (valid)

        // increment various counters
        if(!paused || (valid && resume)) begin
            pc <= pc + 4;
        end // if (!paused)
        if (busy_counter > 0)
            busy_counter <= busy_counter - 1;

    end // always_ff

endmodule // db_wrapper
