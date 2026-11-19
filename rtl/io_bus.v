module io_bus #(
    parameter NN_ENABLE = 1,
    parameter NN_POSTED = 0
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [7:0]  io_port,
    input  wire [7:0]  io_wdata,
    output wire [7:0]  io_rdata,
    input  wire        io_rd,
    input  wire        io_wr,
    output wire        io_ready,

    input  wire [7:0]  switches,
    input  wire [4:0]  buttons,
    output reg  [7:0]  leds,
    output reg  [7:0]  seg_value,
    output reg  [7:0]  seg_enable,

    output wire [7:0]  periph_port,
    output wire [7:0]  periph_wdata,
    input  wire [7:0]  periph_rdata,
    output wire        periph_rd,
    output wire        periph_wr,
    input  wire        periph_ready
);

    wire request = io_rd | io_wr;
    wire nn_hit = NN_ENABLE && (io_port >= 8'h50) && (io_port <= 8'h5F);
    wire is_local  = (io_port < 8'h20);
    wire is_periph = (io_port >= 8'h20) && !nn_hit;
    wire is_sw     = (io_port == 8'h00);
    wire is_btn    = (io_port == 8'h01);
    wire is_led    = (io_port == 8'h02);
    wire is_seg_v  = (io_port == 8'h10);
    wire is_seg_e  = (io_port == 8'h11);

    reg local_ready;
    reg [7:0] local_rdata;

    always @(*) begin
        local_ready = 1'b0;
        local_rdata = 8'h00;
        if (request && is_local) begin
            local_ready = 1'b1;
            if (io_rd) begin
                if (is_sw)       local_rdata = switches;
                else if (is_btn) local_rdata = {3'b000, buttons};
                else             local_rdata = 8'h00;
            end
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            leds       <= 8'h00;
            seg_value  <= 8'h00;
            seg_enable <= 8'h00;
        end else if (request && is_local && io_wr) begin
            if (is_led)        leds       <= io_wdata;
            else if (is_seg_v) seg_value  <= io_wdata;
            else if (is_seg_e) seg_enable <= io_wdata;
        end
    end

    wire [7:0] nn_rdata;
    wire       nn_ready;

    nn_accel #(.POSTED(NN_POSTED)) nn (
        .clk(clk), .rst_n(rst_n),
        .io_port(io_port), .io_wdata(io_wdata), .io_rdata(nn_rdata),
        .io_rd(io_rd), .io_wr(io_wr), .io_ready(nn_ready)
    );

    assign periph_port  = io_port;
    assign periph_wdata = io_wdata;
    assign periph_rd    = request && is_periph && io_rd;
    assign periph_wr    = request && is_periph && io_wr;

    assign io_rdata  = nn_hit ? nn_rdata : (is_local ? local_rdata : periph_rdata);
    assign io_ready  = !request ? 1'b0 : (nn_hit ? nn_ready : (is_local ? local_ready : periph_ready));

endmodule
