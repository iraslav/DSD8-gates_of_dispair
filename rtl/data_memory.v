module data_memory (
    input  wire       clk,
    input  wire [7:0] addr,
    input  wire       we,
    input  wire [7:0] wdata,
    output wire [7:0] rdata
);

    reg [7:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 8'h00;
    end

    always @(posedge clk) begin
        if (we) mem[addr] <= wdata;
    end

    assign rdata = mem[addr];

endmodule
