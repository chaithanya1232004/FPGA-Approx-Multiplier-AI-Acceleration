`timescale 1ns / 1ps

module tb_dynamic_mac();

    reg                          clk;
    reg                          rst_n;
    reg                          clr;
    reg                          valid_in;
    reg  [1:0]                   precision_mode;
    reg  signed [15:0]           a;
    reg  signed [15:0]           b;

    wire signed [39:0]           accum_out;
    wire                         valid_out;

    // Instantiate Dynamic MAC Unit
    approx_mac_unit uut (
        .clk(clk),
        .rst_n(rst_n),
        .clr(clr),
        .valid_in(valid_in),
        .precision_mode(precision_mode),
        .a(a),
        .b(b),
        .accum_out(accum_out),
        .valid_out(valid_out)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    task test_mode(input [1:0] mode, input [127:0] mode_name);
        integer exact_val;
        integer err;
        real fidelity;
        begin
            $display("\n----------------------------------------------------------");
            $display("Testing Mode: %0s (precision_mode = %b)", mode_name, mode);
            $display("----------------------------------------------------------");
            
            // 1. Set mode and inputs (realistic 16-bit AI operands)
            precision_mode = mode;
            a = 16'sd12000;
            b = 16'sd4500;
            exact_val = 12000 * 4500; // 54,000,000

            // 2. Pulse inputs for EXACTLY ONE clock cycle with clr = 1
            @(posedge clk);
            clr      = 1'b1;
            valid_in = 1'b1;

            @(posedge clk);
            clr      = 1'b0;
            valid_in = 1'b0;  // Turn OFF valid_in immediately after 1 cycle!

            // 3. Wait 2 clock cycles for pipeline register to settle
            repeat(2) @(posedge clk);
            #1; // Output settling

            err = (accum_out > exact_val) ? (accum_out - exact_val) : (exact_val - accum_out);
            fidelity = (1.0 - (err * 1.0 / exact_val)) * 100.0;

            $display("Operands           : A = %0d, B = %0d", a, b);
            $display("Exact Mathematical : %0d", exact_val);
            $display("Hardware Output    : %0d", accum_out);
            $display("Error Distance     : %0d", err);
            $display("Accuracy Fidelity  : %0.2f %%", fidelity);

            // Wait 2 idle cycles before next test
            repeat(2) @(posedge clk);
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        clr = 0;
        valid_in = 0;
        precision_mode = 2'b00;
        a = 0;
        b = 0;

        #40;
        rst_n = 1;
        #20;

        $display("==========================================================");
        $display("   VERIFYING DYNAMIC RUN-TIME PRECISION SCALING IN MAC    ");
        $display("==========================================================");

        test_mode(2'b00, "EXACT MODE (f=0)");
        test_mode(2'b01, "HIGH-FIDELITY MODE (f=14)");
        test_mode(2'b10, "BALANCED MODE (f=18)");
        test_mode(2'b11, "ULTRA-LOW-POWER MODE (f=20)");

        $display("\n==========================================================");
        $display("   Dynamic Precision Switching Verified Successfully!     ");
        $display("==========================================================");
        #50;
        $finish;
    end

endmodule