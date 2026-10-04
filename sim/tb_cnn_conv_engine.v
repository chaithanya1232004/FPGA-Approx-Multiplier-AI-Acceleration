`timescale 1ns / 1ps

module tb_cnn_conv_engine();

    reg         clk;
    reg         rst_n;
    reg         start_conv;
    reg         pixel_valid;
    reg  signed [15:0] pixel_in;
    reg  signed [15:0] weight_in;
    reg  signed [15:0] bias_in;

    wire signed [15:0] feature_out;
    wire               feature_valid;

    // ENHANCEMENT: Set to High-Accuracy Mode (f=14)
    exact_cnn_conv_engine uut (
        .clk(clk),
        .rst_n(rst_n),
        .start_conv(start_conv),
        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),
        .weight_in(weight_in),
        .bias_in(bias_in),
        .feature_out(feature_out),
        .feature_valid(feature_valid)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    // Sample 3x3 Image Patch (Pixels in range 500 to 2500)
    reg signed [15:0] image_patch [0:8];
    
    // Standard CNN Quantized Weights (Scaled by 256 for Fixed-Point Q8.8)
    // Represents a normalized vertical edge kernel: [-1.0, 0, +1.0; -2.0, 0, +2.0; -1.0, 0, +1.0]
    reg signed [15:0] conv_kernel [0:8];
    
    integer k;
    integer exact_sum;
    integer exact_relu;
    real relative_error;

    initial begin
        clk         = 0;
        rst_n       = 0;
        start_conv  = 0;
        pixel_valid = 0;
        pixel_in    = 0;
        weight_in   = 0;
        bias_in     = 16'sd256; // Fixed-point bias (+1.0)
        exact_sum   = 256;      // Start with bias

        // Realistic image pixels (normalized 16-bit range)
        image_patch[0] = 16'sd512;  image_patch[1] = 16'sd1024; image_patch[2] = 16'sd2048;
        image_patch[3] = 16'sd400;  image_patch[4] = 16'sd1200; image_patch[5] = 16'sd2400;
        image_patch[6] = 16'sd600;  image_patch[7] = 16'sd1100; image_patch[8] = 16'sd2200;

        // Sobel Filter Kernel in Q8.8 Fixed-Point (scaled by 256):
        // [-1.0,  0, +1.0]  -->  [-256,   0, +256]
        // [-2.0,  0, +2.0]  -->  [-512,   0, +512]
        // [-1.0,  0, +1.0]  -->  [-256,   0, +256]
        conv_kernel[0] = -16'sd256; conv_kernel[1] = 16'sd0;   conv_kernel[2] = 16'sd256;
        conv_kernel[3] = -16'sd512; conv_kernel[4] = 16'sd0;   conv_kernel[5] = 16'sd512;
        conv_kernel[6] = -16'sd256; conv_kernel[7] = 16'sd0;   conv_kernel[8] = 16'sd256;

        // Compute Golden Exact Mathematical Reference
        for (k = 0; k < 9; k = k + 1) begin
            exact_sum = exact_sum + (image_patch[k] * conv_kernel[k]);
        end
        exact_relu = (exact_sum < 0) ? 0 : exact_sum;

        #30;
        rst_n = 1;
        #15;

        $display("\n=======================================================");
        $display("   OPTIMIZED CNN 3x3 CONVOLUTION & ReLU EVALUATION    ");
        $display("=======================================================");

        // Stream 3x3 receptive field
        @(posedge clk);
        start_conv  = 1;
        pixel_valid = 1;
        pixel_in    = image_patch[0];
        weight_in   = conv_kernel[0];

        for (k = 1; k < 9; k = k + 1) begin
            @(posedge clk);
            start_conv  = 0;
            pixel_valid = 1;
            pixel_in    = image_patch[k];
            weight_in   = conv_kernel[k];
        end

        @(posedge clk);
        pixel_valid = 0;

        // Wait for feature output
        @(posedge feature_valid);
        #1;
        
        $display("Hardware Approximate Feature Output   : %0d", uut.biased_sum);
        $display("Golden Exact Mathematical Feature Sum : %0d", exact_relu);
        $display("Absolute Error Distance               : %0d", 
                 (uut.biased_sum > exact_relu) ? (uut.biased_sum - exact_relu) : (exact_relu - uut.biased_sum));
        
        relative_error = ((uut.biased_sum > exact_relu) ? 
                         (uut.biased_sum - exact_relu) : (exact_relu - uut.biased_sum)) * 100.0 / exact_relu;
        
        $display("Relative Accuracy Error (Percentage)  : %0.3f %%", relative_error);
        $display("=======================================================\n");

        #50;
        $finish;
    end

endmodule