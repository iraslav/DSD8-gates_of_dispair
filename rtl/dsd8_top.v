module dsd8_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] switches,
    input  wire [4:0] buttons,
    output wire [7:0] leds,
    output wire [6:0] seg,
    output wire [3:0] an,
    output wire       halted
);

    wire [8:0]  imem_addr;
    wire [15:0] imem_data;
    wire [7:0]  io_port, io_wdata, io_rdata;
    wire        io_rd, io_wr, io_ready;
    wire [7:0]  seg_value, seg_enable;
    // verilator lint_off UNUSED
    wire [7:0]  periph_port, periph_wdata;
    wire        periph_rd, periph_wr;
    // verilator lint_on UNUSED
    wire [7:0]  periph_rdata = 8'h00;
    wire        periph_ready = 1'b1;

    // verilator lint_off UNUSED
    wire        retire;
    wire [8:0]  retire_pc;
    wire [15:0] retire_ir;
    wire        retire_rf_we;
    wire [2:0]  retire_rf_addr;
    wire [7:0]  retire_rf_data;
    wire        retire_mem_we;
    wire [7:0]  retire_mem_addr;
    wire [7:0]  retire_mem_data;
    wire [3:0]  retire_flags;
    // verilator lint_on UNUSED

    instr_memory imem (
        .clk(clk),
        .addr(imem_addr),
        .data(imem_data)
    );

    dsd8_cpu cpu (
        .clk(clk), .rst_n(rst_n),
        .imem_addr(imem_addr), .imem_data(imem_data),
        .io_port(io_port), .io_wdata(io_wdata),
        .io_rdata(io_rdata), .io_rd(io_rd), .io_wr(io_wr), .io_ready(io_ready),
        .halted(halted),
        .retire(retire), .retire_pc(retire_pc), .retire_ir(retire_ir),
        .retire_rf_we(retire_rf_we), .retire_rf_addr(retire_rf_addr),
        .retire_rf_data(retire_rf_data),
        .retire_mem_we(retire_mem_we), .retire_mem_addr(retire_mem_addr),
        .retire_mem_data(retire_mem_data),
        .retire_flags(retire_flags)
    );

    io_bus iobus (
        .clk(clk), .rst_n(rst_n),
        .io_port(io_port), .io_wdata(io_wdata),
        .io_rdata(io_rdata), .io_rd(io_rd), .io_wr(io_wr), .io_ready(io_ready),
        .switches(switches), .buttons(buttons),
        .leds(leds), .seg_value(seg_value), .seg_enable(seg_enable),
        .periph_port(periph_port), .periph_wdata(periph_wdata),
        .periph_rdata(periph_rdata), .periph_rd(periph_rd),
        .periph_wr(periph_wr), .periph_ready(periph_ready)
    );

    // verilator lint_off UNUSED
    wire unused_seg = seg_value[7];
    wire [3:0] unused_an = seg_enable[7:4];
    // verilator lint_on UNUSED

    assign seg = seg_value[6:0];
    assign an  = seg_enable[3:0];

endmodule
