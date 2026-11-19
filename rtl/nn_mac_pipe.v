// nn_mac_pipe.v -- 3-stage signed int8 multiply-accumulate with zero-skip
module nn_mac_pipe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        clr,
    input  wire        start,
    input  wire [7:0]  a,
    input  wire [7:0]  w,
    output wire        busy,
    output wire [23:0] acc
);

    reg [7:0]  a_s1, w_s1;
    reg        v1, v2, v3;
    reg signed [15:0] prod_s2;
    reg signed [23:0] acc_r;

    wire zero = (a == 8'h00) || (w == 8'h00);

    assign busy = v1 | v2 | v3;
    assign acc  = acc_r;

    always @(posedge clk) begin
        if (!rst_n) begin
            v1 <= 1'b0;
            v2 <= 1'b0;
            v3 <= 1'b0;
            a_s1 <= 8'h00;
            w_s1 <= 8'h00;
            prod_s2 <= 16'sh0000;
            acc_r <= 24'sh000000;
        end else begin
            v1 <= start && !zero;
            if (start && !zero) begin
                a_s1 <= a;
                w_s1 <= w;
            end

            v2 <= v1;
            if (v1)
                prod_s2 <= $signed(a_s1) * $signed(w_s1);

            v3 <= v2;
            if (v2)
                acc_r <= acc_r + {{8{prod_s2[15]}}, prod_s2};

            if (clr)
                acc_r <= 24'sh000000;
        end
    end

endmodule
