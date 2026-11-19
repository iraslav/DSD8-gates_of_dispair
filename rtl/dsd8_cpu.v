module dsd8_cpu (
    input  wire        clk,
    input  wire        rst_n,

    output wire [8:0]  imem_addr,
    input  wire [15:0] imem_data,

    output wire [7:0]  io_port,
    output wire [7:0]  io_wdata,
    input  wire [7:0]  io_rdata,
    output wire        io_rd,
    output wire        io_wr,
    input  wire        io_ready,

    output wire        halted,
    output wire        retire,
    output wire [8:0]  retire_pc,
    output wire [15:0] retire_ir,
    output wire        retire_rf_we,
    output wire [2:0]  retire_rf_addr,
    output wire [7:0]  retire_rf_data,
    output wire        retire_mem_we,
    output wire [7:0]  retire_mem_addr,
    output wire [7:0]  retire_mem_data,
    output wire [3:0]  retire_flags
);

    reg [15:0] ir;
    reg [8:0]  ir_pc;
    wire [15:0] current_ir;

    wire [3:0] cur_opcode;
    wire [2:0] cur_rd, cur_rs1, cur_rs2;
    wire [7:0] cur_port;
    wire [7:0] dec_imm8;
    wire [8:0] dec_addr9;
    wire [2:0] dec_cond;
    wire       io_dir;

    wire       pc_en, pc_load;
    wire       rf_we;
    wire       mem_we;
    wire       flags_we;
    wire       ctrl_io_rd, ctrl_io_wr;
    wire [1:0] wb_sel;

    wire [8:0] pc;
    wire [8:0] branch_addr;

    wire [7:0] rd1, rd2;
    wire [7:0] alu_result;
    wire [3:0] alu_flags;
    wire       alu_flag_z, alu_flag_n, alu_flag_c, alu_flag_v;
    wire [3:0] flags_out;

    wire [7:0] dmem_rdata;
    wire [7:0] dmem_addr;
    wire [7:0] dmem_wdata;

    reg  [7:0] writeback_data;

    wire is_st  = (cur_opcode == 4'h3);
    wire is_io  = (cur_opcode == 4'hE);
    wire is_out = is_io && io_dir;
    wire is_sh  = (cur_opcode == 4'h9 || cur_opcode == 4'hA);

    wire [2:0] rf_ra2 = (is_st || is_out) ? cur_rd : (is_sh ? 3'b000 : cur_rs2);

    always @(posedge clk) begin
        if (!rst_n) begin
            ir <= 16'h0000;
            ir_pc <= 9'h000;
        end else if (pc_en) begin
            ir <= imem_data;
            ir_pc <= pc;
        end
    end

    assign current_ir = ir;

    instr_decoder dec_inst (
        .instr(current_ir),
        .opcode(cur_opcode),
        .rd(cur_rd), .rs1(cur_rs1), .rs2(cur_rs2),
        .imm8(dec_imm8), .addr9(dec_addr9),
        .cond(dec_cond), .port(cur_port), .io_dir(io_dir)
    );

    assign imem_addr = pc;
    assign branch_addr = dec_addr9;

    prog_counter pc_inst (
        .clk(clk), .rst_n(rst_n),
        .pc_en(pc_en), .pc_load(pc_load),
        .branch_addr(branch_addr),
        .pc(pc)
    );

    register_file rf_inst (
        .clk(clk), .rst_n(rst_n),
        .ra1(cur_rs1), .ra2(rf_ra2),
        .rd1(rd1), .rd2(rd2),
        .we(rf_we), .wa(cur_rd), .wd(writeback_data)
    );

    alu alu_inst (
        .a(rd1), .b(rd2), .op(cur_opcode),
        .result(alu_result),
        .flag_z(alu_flag_z), .flag_n(alu_flag_n),
        .flag_c(alu_flag_c), .flag_v(alu_flag_v)
    );

    assign alu_flags = {alu_flag_z, alu_flag_n, alu_flag_c, alu_flag_v};

    flags_reg flags_inst (
        .clk(clk), .rst_n(rst_n),
        .flags_we(flags_we),
        .flags_in(alu_flags),
        .flags_out(flags_out)
    );

    assign dmem_addr = rd1;
    assign dmem_wdata = rd2;

    data_memory dmem_inst (
        .clk(clk),
        .addr(dmem_addr), .we(mem_we),
        .wdata(dmem_wdata),
        .rdata(dmem_rdata)
    );

    assign io_port  = cur_port;
    assign io_wdata = rd2;

    assign halted    = ctrl_halted;
    assign retire_pc = ir_pc;
    assign retire_ir = current_ir;

    wire ctrl_halted, ctrl_retire, ctrl_rf_we, ctrl_mem_we;

    control_unit ctrl_inst (
        .clk(clk), .rst_n(rst_n),
        .opcode(cur_opcode), .cond(dec_cond), .flags(flags_out),
        .io_ready(io_ready), .io_dir(io_dir),
        .pc_en(pc_en), .pc_load(pc_load),
        .rf_we(ctrl_rf_we), .mem_we(ctrl_mem_we),
        .io_rd(ctrl_io_rd), .io_wr(ctrl_io_wr),
        .flags_we(flags_we),
        .wb_sel(wb_sel),
        .halted(ctrl_halted),
        .retire(ctrl_retire)
    );

    assign rf_we = ctrl_rf_we;
    assign mem_we = ctrl_mem_we;
    assign io_rd = ctrl_io_rd;
    assign io_wr = ctrl_io_wr;
    assign retire = ctrl_retire;

    reg [7:0] io_rdata_lat;

    always @(posedge clk) begin
        if (ctrl_io_rd && io_ready)
            io_rdata_lat <= io_rdata;
    end

    always @(*) begin
        case (wb_sel)
            2'b00: writeback_data = alu_result;
            2'b01: writeback_data = dmem_rdata;
            2'b10: writeback_data = dec_imm8;
            2'b11: writeback_data = io_rdata_lat;
            default: writeback_data = alu_result;
        endcase
    end

    assign retire_rf_we    = rf_we;
    assign retire_rf_addr  = rf_we ? cur_rd : 3'b000;
    assign retire_rf_data  = rf_we ? writeback_data : 8'h00;
    assign retire_mem_we   = mem_we;
    assign retire_mem_addr = mem_we ? dmem_addr : 8'h00;
    assign retire_mem_data = mem_we ? dmem_wdata : 8'h00;
    assign retire_flags    = flags_we ? alu_flags : flags_out;

endmodule
