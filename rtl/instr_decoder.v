module instr_decoder (
    input  wire [15:0] instr,
    output wire [3:0]  opcode,
    output wire [2:0]  rd,
    output wire [2:0]  rs1,
    output wire [2:0]  rs2,
    output wire [7:0]  imm8,
    output wire [8:0]  addr9,
    output wire [2:0]  cond,
    output wire [7:0]  port,
    output wire        io_dir
);

    assign opcode = instr[15:12];
    assign rd     = instr[11:9];
    assign rs1    = instr[8:6];
    assign rs2    = instr[5:3];
    assign imm8   = instr[7:0];
    assign addr9  = instr[8:0];
    assign cond   = instr[11:9];
    assign port   = instr[7:0];
    assign io_dir = instr[8];

endmodule
