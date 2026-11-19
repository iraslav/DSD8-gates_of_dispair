`timescale 1ns/1ps

module tb_nn_mac;

    reg clk, rst_n, clr, start;
    reg [7:0] a, w;
    wire busy0, busy1;
    wire [23:0] acc0, acc1;
    integer errors;
    integer i, j;
    integer n_random;
    integer cov_a [0:4];
    integer cov_b [0:4];
    reg [7:0] corner [0:4];
    reg signed [23:0] model0, model1;

    nn_mac_pipe dut0 (
        .clk(clk), .rst_n(rst_n), .clr(clr), .start(start),
        .a(a), .w(w), .busy(busy0), .acc(acc0)
    );

    nn_mac_pipe dut1 (
        .clk(clk), .rst_n(rst_n), .clr(clr), .start(start),
        .a(a), .w(w), .busy(busy1), .acc(acc1)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task drain;
        begin
            while (busy0 || busy1) @(posedge clk);
            #1;
        end
    endtask

    task do_op;
        input [7:0] ta, tb;
        begin
            a = ta; w = tb; start = 1;
            @(posedge clk); #1;
            start = 0;
            if (ta != 8'h00 && tb != 8'h00) begin
                model0 = model0 + ($signed(ta) * $signed(tb));
                model1 = model1 + ($signed(ta) * $signed(tb));
            end
            drain;
            if (acc0 !== model0) begin
                errors = errors + 1;
                if (errors <= 20) $display("POSTED0 mismatch a=%02h w=%02h got=%06h exp=%06h", ta, tb, acc0, model0);
            end
            if (acc1 !== model1) begin
                errors = errors + 1;
                if (errors <= 20) $display("POSTED1 mismatch a=%02h w=%02h got=%06h exp=%06h", ta, tb, acc1, model1);
            end
        end
    endtask

    initial begin
        errors = 0;
        n_random = 0;
        model0 = 0;
        model1 = 0;
        for (i = 0; i < 5; i = i + 1) begin
            cov_a[i] = 0;
            cov_b[i] = 0;
        end
        corner[0] = 8'h00; corner[1] = 8'h01; corner[2] = 8'h7F;
        corner[3] = 8'h80; corner[4] = 8'hFF;

        rst_n = 0; clr = 0; start = 0; a = 0; w = 0;
        repeat (3) @(posedge clk);
        rst_n = 1;

        for (i = 0; i < 5; i = i + 1)
            for (j = 0; j < 5; j = j + 1)
                do_op(corner[i], corner[j]);

        for (i = 0; i < 10000; i = i + 1) begin
            a = $random; w = $random;
            do_op(a, w);
            n_random = n_random + 1;
            if (a == 8'h00) cov_a[0] = cov_a[0] + 1;
            if (a == 8'h01) cov_a[1] = cov_a[1] + 1;
            if (a == 8'h7F) cov_a[2] = cov_a[2] + 1;
            if (a == 8'h80) cov_a[3] = cov_a[3] + 1;
            if (a == 8'hFF) cov_a[4] = cov_a[4] + 1;
            if (w == 8'h00) cov_b[0] = cov_b[0] + 1;
            if (w == 8'h01) cov_b[1] = cov_b[1] + 1;
            if (w == 8'h7F) cov_b[2] = cov_b[2] + 1;
            if (w == 8'h80) cov_b[3] = cov_b[3] + 1;
            if (w == 8'hFF) cov_b[4] = cov_b[4] + 1;
        end

        clr = 1;
        @(posedge clk); #1;
        clr = 0;
        if (acc0 !== 24'sh000000 || acc1 !== 24'sh000000) begin
            errors = errors + 1;
            $display("clear failed");
        end

        $display("random vectors: %0d", n_random);
        $display("corner coverage a: %0d %0d %0d %0d %0d", cov_a[0], cov_a[1], cov_a[2], cov_a[3], cov_a[4]);
        $display("corner coverage b: %0d %0d %0d %0d %0d", cov_b[0], cov_b[1], cov_b[2], cov_b[3], cov_b[4]);

        if (errors == 0) $display("TESTBENCH: PASS");
        else             $display("TESTBENCH: FAIL (%0d errors)", errors);
        $finish;
    end

endmodule
