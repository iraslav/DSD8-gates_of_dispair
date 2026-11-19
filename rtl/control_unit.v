module control_unit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] opcode,
    input  wire [2:0] cond,
    input  wire [3:0] flags,
    input  wire       io_ready,
    input  wire       io_dir,
    output reg        pc_en,
    output reg        pc_load,
    output reg        rf_we,
    output reg        mem_we,
    output reg        io_rd,
    output reg        io_wr,
    output reg        flags_we,
    output reg  [1:0] wb_sel,
    output reg        halted,
    output reg        retire
);

    localparam FETCH     = 4'd0;
    localparam DECODE    = 4'd1;
    localparam EXECUTE   = 4'd2;
    localparam MEM_IO    = 4'd3;
    localparam WRITEBACK = 4'd4;
    localparam HALTED_S  = 4'd5;

    reg [3:0] state, next_state;

    wire is_alu_r3   = (opcode >= 4'h4 && opcode <= 4'h8);
    wire is_alu_r2   = (opcode == 4'h9 || opcode == 4'hA);
    wire is_cmp      = (opcode == 4'hB);
    wire is_jmp      = (opcode == 4'hC);
    wire is_branch   = (opcode == 4'hD);
    wire is_io       = (opcode == 4'hE);
    wire is_hlt      = (opcode == 4'hF);
    wire is_ldi      = (opcode == 4'h1);
    wire is_ld       = (opcode == 4'h2);
    wire is_st       = (opcode == 4'h3);
    wire is_nop      = (opcode == 4'h0);

    wire z = flags[3];
    wire n = flags[2];
    wire c = flags[1];
    wire v = flags[0];

    reg  branch_taken;
    always @(*) begin
        case (cond)
            3'b000: branch_taken = z;
            3'b001: branch_taken = ~z;
            3'b010: branch_taken = c;
            3'b011: branch_taken = ~c;
            3'b100: branch_taken = n;
            3'b101: branch_taken = ~n;
            3'b110: branch_taken = v;
            3'b111: branch_taken = ~v;
            default: branch_taken = 1'b0;
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= FETCH;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = FETCH;
        pc_en    = 1'b0;
        pc_load  = 1'b0;
        rf_we    = 1'b0;
        mem_we   = 1'b0;
        io_rd    = 1'b0;
        io_wr    = 1'b0;
        flags_we = 1'b0;
        wb_sel   = 2'b00;
        halted   = 1'b0;
        retire   = 1'b0;

        case (state)
            FETCH: begin
                pc_en = 1'b1;
                next_state = DECODE;
            end

            DECODE: begin
                pc_en = 1'b0;
                if (is_nop) begin
                    retire = 1'b1;
                    next_state = FETCH;
                end else if (is_hlt) begin
                    retire = 1'b1;
                    next_state = HALTED_S;
                end else begin
                    next_state = EXECUTE;
                end
            end

            EXECUTE: begin
                if (is_ld || is_st || is_io) begin
                    next_state = MEM_IO;
                end else if (is_alu_r3 || is_alu_r2 || is_ldi) begin
                    flags_we = (is_alu_r3 || is_alu_r2);
                    next_state = WRITEBACK;
                end else if (is_cmp) begin
                    flags_we = 1'b1;
                    retire = 1'b1;
                    next_state = FETCH;
                end else if (is_jmp) begin
                    pc_load = 1'b1;
                    pc_en = 1'b1;
                    retire = 1'b1;
                    next_state = FETCH;
                end else if (is_branch) begin
                    pc_load = branch_taken;
                    pc_en = branch_taken;
                    retire = 1'b1;
                    next_state = FETCH;
                end else begin
                    retire = 1'b1;
                    next_state = FETCH;
                end
            end

            MEM_IO: begin
                if (is_ld) begin
                    next_state = WRITEBACK;
                end else if (is_st) begin
                    mem_we = 1'b1;
                    retire = 1'b1;
                    next_state = FETCH;
                end else if (is_io) begin
                    if (io_dir) begin
                        io_wr = 1'b1;
                        if (io_ready) begin
                            retire = 1'b1;
                            next_state = FETCH;
                        end else begin
                            next_state = MEM_IO;
                        end
                    end else begin
                        io_rd = 1'b1;
                        if (io_ready) begin
                            next_state = WRITEBACK;
                        end else begin
                            next_state = MEM_IO;
                        end
                    end
                end else begin
                    next_state = FETCH;
                end
            end

            WRITEBACK: begin
                if (is_ld) begin
                    wb_sel = 2'b01;
                end else if (is_io) begin
                    wb_sel = 2'b11;
                end else if (is_ldi) begin
                    wb_sel = 2'b10;
                end else begin
                    wb_sel = 2'b00;
                end
                rf_we = 1'b1;
                retire = 1'b1;
                next_state = FETCH;
            end

            HALTED_S: begin
                halted = 1'b1;
                next_state = HALTED_S;
            end

            default: begin
                next_state = FETCH;
            end
        endcase
    end

endmodule
