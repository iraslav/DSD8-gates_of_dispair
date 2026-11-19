module alu (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [3:0] op,
    output reg  [7:0] result,
    output reg        flag_z,
    output reg        flag_n,
    output reg        flag_c,
    output reg        flag_v
);

    wire [8:0] add9 = {1'b0, a} + {1'b0, b};
    wire [8:0] sub9 = {1'b0, a} + {1'b0, ~b} + 9'h001;

    always @(*) begin
        result = 8'h00;
        flag_z = 1'b0;
        flag_n = 1'b0;
        flag_c = 1'b0;
        flag_v = 1'b0;
        case (op)
            4'h4: begin
                result = add9[7:0];
                flag_c = add9[8];
                flag_v = (a[7] == b[7]) && (result[7] != a[7]);
            end
            4'h5, 4'hB: begin
                result = sub9[7:0];
                flag_c = sub9[8];
                flag_v = (a[7] != b[7]) && (result[7] != a[7]);
            end
            4'h6: begin
                result = a & b;
            end
            4'h7: begin
                result = a | b;
            end
            4'h8: begin
                result = a ^ b;
            end
            4'h9: begin
                result = {a[6:0], 1'b0};
                flag_c = a[7];
            end
            4'hA: begin
                result = {1'b0, a[7:1]};
                flag_c = a[0];
            end
            default: begin
                result = 8'h00;
            end
        endcase
        flag_z = (result == 8'h00);
        flag_n = result[7];
    end

endmodule
