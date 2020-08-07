module db_wrapper(
    input clk_100MHz,
    input srx,
    output [15:0] led,
    output [7:0] seg,
    output [3:0] an,
    output stx
);

    localparam MEM_SIZE_WORDS = 4096;
    localparam MEM_SIZE = 4 * MEM_SIZE_WORDS;

    logic clk = 0;
    logic valid, busy;
    
    logic [31:0] counter = 0;
    reg [15:0] r_sseg_data;
    reg [15:0] r_led = 0;
    
    logic [31:0] addr, d_in, d_rd;
    reg [31:0] r_addr, r_d_in;

    assign led = r_led;
    assign busy = valid || (counter > 0);

    assign r_sseg_data = {r_addr[7:0], r_d_in[7:0]};

    reg [7:0] memory[MEM_SIZE_BYTES];
    reg [31:0] reg_file[31];

    // memory and register file reads
    always_comb begin
        // for reads, data should be ready when busy goes low, per protocol
        d_rd = 'hFFFF; // arbitrary value, but it sticks out

        if (!busy)
            if (mem_rd) begin
                if (mem_rw_byte) begin
                    // ready only the byte
                    d_rd = memory[addr]; 
                end
                else begin
                    d_rd = {memory[addr], memory[addr+1], memory[addr+2], memory[addr+3]};
                    // note: does not account for reads that are not aligned with a word
                    // (addr % 4 != 0)
                end
            end
            else if (reg_rd) begin
                if (addr == 0) begin
                    d_rd = 0;
                end
                else begin
                    d_rd = reg_file[addr - 1];
                end
            end
        end

    end

    // memory and reg file writes
    always_ff @(posedge clk) begin
        if (valid) begin
            if (mem_wr) begin
                if (mem_rw_byte) begin
                    memory[addr] <= d_in;
                end
                else begin
                    memory[addr] <= d_in[31:24];
                    memory[addr] <= d_in[23:16];
                    memory[addr] <= d_in[15:8];
                    memory[addr] <= d_in[7:0];
                end
            end
            else if (reg_wr) begin
                if (addr != 0)
                    reg_file[addr - 1] <= d_in;
            end
        end
    end

    sseg_disp sseg(
        .DATA_IN(r_sseg_data),
        .CLK(clk),
        .MODE(1'b0),
        .CATHODES(seg),
        .ANODES(an)
    );

    logic pause, resume, reset, red_rd, reg_wr, mem_rd, mem_wr, mem_rw_byte;
    logic [4:0] counter_pc;
    logic [31:0] counter_delay = 0;
    logic [31:0] pc;
    assign pc = {28'b0, counter_pc};
    reg paused = 0;
    
    mcu_controller(
        .clk(clk),
        .srx(srx),
        .stx(stx),
        .pc(pc),
        .mcu_busy(mcu_busy),
        .d_rd(d_rd),
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
        .mem_rw_byte(mem_rw_byte),
        .valid(valid)
    );
    
    // create 50 MHz clock
    always_ff @(posedge clk_100MHz) begin
        clk = ~clk;
    end // always_ff
    
    always_ff @(posedge clk) begin
        r_led[15] <= busy;
        counter_delay <= counter_delay + 1;
        
        if (!paused && (counter_delay == 5000000)) begin
            counter_pc <= counter_pc + 4;
            r_led[14:11] <= counter_pc + 4;
            counter_delay <= 0;
        end
         
        if (valid) begin
            // long delay
            counter <= 100000;
            r_d_in <= d_in;
            r_addr <= addr;
            r_led[0] <= 1;
            
            if (pause) begin
                r_led[4:1] <= 1;
                paused <= 1;
            end
            else if (resume)
                r_led[4:1] <= 2;
            else if (reset)
                r_led[4:1] <= 3;
            else if (reg_rd)
                r_led[4:1] <= 4;
            else if (reg_wr)
                r_led[4:1] <= 5;
            else if (mem_rd)
                r_led[4:1] <= 6;
            else if (mem_wr)
                r_led[4:1] <= 7;

        end
        if (counter > 0)
            counter <= counter - 1;
    end // always_ff

endmodule // serial_hw_testbench
