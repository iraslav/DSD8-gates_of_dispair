// nn_accel.v -- NN accelerator peripheral: decode, lock gate, hazards, stats
// Ports 0x50-0x5F. Locked after reset; write 0xA5 to 0x5F to unlock.
module nn_accel #(
    parameter POSTED = 0
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  io_port,
    input  wire [7:0]  io_wdata,
    output reg  [7:0]  io_rdata,
    input  wire        io_rd,
    input  wire        io_wr,
    output reg         io_ready
);

    reg [7:0]  a_reg, lut_idx;
    reg [3:0]  shift;
    reg [1:0]  bank;
    reg        unlocked;
    reg [7:0]  skipcnt, maccnt;

    wire hit = (io_port >= 8'h50) && (io_port <= 8'h5F);
    wire request = io_rd | io_wr;
    wire zero = (a_reg == 8'h00) || (io_wdata == 8'h00);
    wire acc_clr;
    wire mac_start;

    wire        busy;
    wire [23:0] acc;
    wire [7:0]  qout, act, lut_val;

    assign mac_start = unlocked && io_wr && io_ready && (io_port == 8'h51) && !zero;
    assign acc_clr   = unlocked && io_wr && io_ready && (io_port == 8'h52) && io_wdata[0];

    nn_mac_pipe mac (
        .clk(clk), .rst_n(rst_n), .clr(acc_clr),
        .start(mac_start), .a(a_reg), .w(io_wdata),
        .busy(busy), .acc(acc)
    );

    nn_act act_unit (
        .acc(acc), .shift(shift), .bank(bank), .lut_idx(lut_idx),
        .qout(qout), .act(act), .lut_val(lut_val)
    );

    always @(*) begin
        io_ready = 1'b0;
        if (hit && request) begin
            if (!unlocked) begin
                io_ready = 1'b1;
            end else begin
                case (io_port)
                    8'h50: io_ready = 1'b1;
                    8'h51: io_ready = POSTED ? 1'b1 : (zero ? 1'b1 : !busy);
                    8'h52: io_ready = !busy;
                    8'h53, 8'h54, 8'h55, 8'h56, 8'h57, 8'h59: io_ready = !busy;
                    8'h58, 8'h5A, 8'h5B, 8'h5C, 8'h5D, 8'h5E, 8'h5F: io_ready = 1'b1;
                    default: io_ready = 1'b1;
                endcase
            end
        end
    end

    always @(*) begin
        io_rdata = 8'h00;
        if (unlocked && io_rd) begin
            case (io_port)
                8'h53: io_rdata = acc[7:0];
                8'h54: io_rdata = acc[15:8];
                8'h55: io_rdata = acc[23:16];
                8'h57: io_rdata = qout;
                8'h59: io_rdata = act;
                8'h5B: io_rdata = lut_val;
                8'h5C: io_rdata = skipcnt;
                8'h5D: io_rdata = maccnt;
                8'h5F: io_rdata = {6'b000000, busy, unlocked};
                default: io_rdata = 8'h00;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            a_reg    <= 8'h00;
            lut_idx  <= 8'h00;
            shift    <= 4'h0;
            bank     <= 2'b00;
            unlocked <= 1'b0;
            skipcnt  <= 8'h00;
            maccnt   <= 8'h00;
        end else begin
            if (io_wr && io_ready && (io_port == 8'h5F)) begin
                unlocked <= (io_wdata == 8'hA5);
            end else if (unlocked && io_wr && io_ready) begin
                case (io_port)
                    8'h50: a_reg <= io_wdata;
                    8'h51: begin
                        if (zero)
                            skipcnt <= (skipcnt == 8'hFF) ? 8'hFF : skipcnt + 8'h01;
                        else
                            maccnt <= (maccnt == 8'hFF) ? 8'hFF : maccnt + 8'h01;
                    end
                    8'h52: begin
                        if (io_wdata[1]) begin
                            skipcnt <= 8'h00;
                            maccnt  <= 8'h00;
                        end
                    end
                    8'h56: shift <= io_wdata[3:0];
                    8'h58: bank  <= io_wdata[1:0];
                    8'h5A: lut_idx <= io_wdata;
                    default: ;
                endcase
            end
        end
    end

endmodule
