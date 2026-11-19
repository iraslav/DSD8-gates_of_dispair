module flags_reg (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       flags_we,
    input  wire [3:0] flags_in,
    output reg  [3:0] flags_out
);

    always @(posedge clk) begin
        if (!rst_n) begin
            flags_out <= 4'b0000;
        end else if (flags_we) begin
            flags_out <= flags_in;
        end
    end

endmodule
