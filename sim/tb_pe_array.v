`timescale 1ns / 1ps

module tb_pe_array();

    parameter NUM_PES = 32;

    reg                                      clk;
    reg                                      rst_n;
    reg                                      start_conv;
    reg                                      pixel_valid;
    reg  signed [15:0]                       pixel_in;
    reg  signed [15:0]                       weight_in;
    reg  signed [15:0]                       bias_in;

    wire [(NUM_PES*16)-1:0]                  features_out;
    wire [NUM_PES-1:0]                       features_valid;

    // Toggle between exact_pe_array and approx_pe_array for simulation
    // Currently testing: approx_pe_array
    exact_pe_array #(.NUM_PES(NUM_PES)) uut (
        .clk(clk),
        .rst_n(rst_n),
        .start_conv(start_conv),
        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),
        .weight_in(weight_in),
        .bias_in(bias_in),
        .features_out(features_out),
        .features_valid(features_valid)
    );

    always #5 clk = ~clk; // 100 MHz clock

    integer step, window;

    initial begin
        clk         = 0;
        rst_n       = 0;
        start_conv  = 0;
        pixel_valid = 0;
        pixel_in    = 0;
        weight_in   = 0;
        bias_in     = 16'sd256;

        #25;
        rst_n = 1;
        #15;

        // Run multiple 3x3 convolution windows to generate active data transitions
        for (window = 0; window < 5; window = window + 1) begin
            @(posedge clk);
            start_conv  = 1;
            pixel_valid = 1;
            pixel_in    = $random % 2000;
            weight_in   = $random % 512;

            for (step = 1; step < 9; step = step + 1) begin
                @(posedge clk);
                start_conv  = 0;
                pixel_valid = 1;
                pixel_in    = $random % 2000;
                weight_in   = $random % 512;
            end

            @(posedge clk);
            pixel_valid = 0;
            #30;
        end

        #100;
        $finish;
    end

endmodule