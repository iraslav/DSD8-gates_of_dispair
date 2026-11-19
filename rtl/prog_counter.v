module prog_counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       pc_en,
    input  wire       pc_load,
    input  wire [8:0] branch_addr,
    output reg  [8:0] pc
);

    always @(posedge clk) begin
        if (!rst_n) begin
            pc <= 9'h000;
        end else if (pc_en) begin
            if (pc_load) pc <= branch_addr;
            else         pc <= pc + 9'h001;
        end
    end

endmodule
