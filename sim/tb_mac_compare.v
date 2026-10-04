`timescale 1ns / 1ps

module tb_mac_compare();

    reg                          clk;
    reg                          rst_n;
    reg                          clr;
    reg                          valid_in;
    reg  signed [15:0]           a;
    reg  signed [15:0]           b;

    wire signed [39:0]           accum_out;
    wire                         valid_out;

    // Toggle between approx_mac_unit and exact_mac_unit here:
    // --------------------------------------------------------
//    approx_mac_unit #(.APPROX_BIT(5'd14)) uut (
     exact_mac_unit uut (
        .clk(clk),
        .rst_n(rst_n),
        .clr(clr),
        .valid_in(valid_in),
        .a(a),
        .b(b),
        .accum_out(accum_out),
        .valid_out(valid_out)
    );

    always #5 clk = ~clk; // 100 MHz clock

    integer i, j;

    initial begin
        clk      = 0;
        rst_n    = 0;
        clr      = 0;
        valid_in = 0;
        a        = 0;
        b        = 0;

        #25;
        rst_n    = 1;
        #15;

        // Run 10 consecutive dot-product windows of 10 MAC operations each
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge clk);
            clr      = 1; // Clear at start of each window
            valid_in = 1;
            a        = $random % 2000;
            b        = $random % 512;

            for (j = 1; j < 10; j = j + 1) begin
                @(posedge clk);
                clr      = 0;
                valid_in = 1;
                a        = $random % 2000;
                b        = $random % 512;
            end

            @(posedge clk);
            valid_in = 0;
            #20;
        end

        #100;
        $finish;
    end

endmodule