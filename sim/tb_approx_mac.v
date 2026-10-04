`timescale 1ns / 1ps

module tb_approx_mac();

    reg                          clk;
    reg                          rst_n;
    reg                          clr;
    reg                          valid_in;
    reg  signed [15:0]           a;
    reg  signed [15:0]           b;

    wire signed [39:0]           accum_out;
    wire                         valid_out;

    // Golden exact reference variables for comparison
    integer                      k;
    reg signed [39:0]            exact_accum;

    // Instantiate Approximate MAC Unit (f = 18)
    approx_mac_unit #(
        .APPROX_BIT(5'd14)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .clr(clr),
        .valid_in(valid_in),
        .a(a),
        .b(b),
        .accum_out(accum_out),
        .valid_out(valid_out)
    );

    // Clock Generation (100 MHz clock -> 10 ns period)
    always #5 clk = ~clk;

    initial begin
        // 1. Initialize Signals
        clk = 0;
        rst_n = 0;
        clr = 0;
        valid_in = 0;
        a = 0;
        b = 0;
        exact_accum = 0;

        #25;
        rst_n = 1;  // Release reset
        #10;

        $display("\n=======================================================");
        $display("   TEST 1: Simulating a 3x3 CNN Filter Dot-Product    ");
        $display("=======================================================");

        // Simulate 9 consecutive multiply-accumulate operations (3x3 kernel)
        for (k = 1; k <= 9; k = k + 1) begin
            @(posedge clk);
            valid_in = 1;
            
            // First operation of the dot-product asserts 'clr' to initialize
            if (k == 1) begin
                clr = 1;
                exact_accum = 0;
            end else begin
                clr = 0;
            end

            // Apply sample signed weights and activations
            a = $random % 1000;   // Feature map activation
            b = $random % 1000;   // Kernel weight
            
            exact_accum = exact_accum + (a * b);
            
            $display("[Cycle %0d] Input A=%d | Weight B=%d | Exact Partial Acc=%d", k, a, b, exact_accum);
        end

        // Finish inputs
        @(posedge clk);
        valid_in = 0;
        clr = 0;

        // Wait 3 cycles for pipeline to settle
        #30;

        $display("\n-------------------------------------------------------");
        $display("Final Approximate Accumulation Result: %d", accum_out);
        $display("Final Exact Reference Result         : %d", exact_accum);
        $display("Accumulation Error Distance          : %d", (accum_out > exact_accum) ? (accum_out - exact_accum) : (exact_accum - accum_out));
        $display("=======================================================\n");

        #50;
        $finish;
    end

endmodule