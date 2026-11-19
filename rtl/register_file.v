module register_file (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] ra1,
    input  wire [2:0] ra2,
    output wire [7:0] rd1,
    output wire [7:0] rd2,
    input  wire       we,
    input  wire [2:0] wa,
    input  wire [7:0] wd
);

    reg [7:0] regs [0:7];
    integer i;

    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1)
                regs[i] <= 8'h00;
        end else if (we) begin
            regs[wa] <= wd;
        end
    end

    assign rd1 = regs[ra1];
    assign rd2 = regs[ra2];

endmodule
