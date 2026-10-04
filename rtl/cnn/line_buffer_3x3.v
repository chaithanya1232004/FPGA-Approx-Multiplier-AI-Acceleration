`timescale 1ns / 1ps

module line_buffer_3x3 #(
    parameter DATA_WIDTH  = 16,
    parameter IMAGE_WIDTH = 28   // e.g., 28 for MNIST, 32 for CIFAR
)(
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire                           pixel_valid,
    input  wire signed [DATA_WIDTH-1:0]   pixel_in,
    
    // 9 parallel window outputs for 3x3 convolution
    output wire signed [DATA_WIDTH-1:0]   win_00, win_01, win_02,
    output wire signed [DATA_WIDTH-1:0]   win_10, win_11, win_12,
    output wire signed [DATA_WIDTH-1:0]   win_20, win_21, win_22,
    output reg                            window_valid
);

    // Line Buffers to store previous rows
    reg signed [DATA_WIDTH-1:0] line_buf0 [0:IMAGE_WIDTH-1];
    reg signed [DATA_WIDTH-1:0] line_buf1 [0:IMAGE_WIDTH-1];
    
    // 3x3 Window Registers
    reg signed [DATA_WIDTH-1:0] r00, r01, r02;
    reg signed [DATA_WIDTH-1:0] r10, r11, r12;
    reg signed [DATA_WIDTH-1:0] r20, r21, r22;

    integer i;
    reg [10:0] col_cnt, row_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_cnt      <= 0;
            row_cnt      <= 0;
            window_valid <= 0;
            r00 <= 0; r01 <= 0; r02 <= 0;
            r10 <= 0; r11 <= 0; r12 <= 0;
            r20 <= 0; r21 <= 0; r22 <= 0;
            for (i = 0; i < IMAGE_WIDTH; i = i + 1) begin
                line_buf0[i] <= 0;
                line_buf1[i] <= 0;
            end
        end else if (pixel_valid) begin
            // Shift Line Buffers (Row delays)
            line_buf1[col_cnt] <= pixel_in;
            line_buf0[col_cnt] <= line_buf1[col_cnt];

            // Update 3x3 sliding window registers
            r22 <= pixel_in;
            r21 <= r22;
            r20 <= r21;

            r12 <= line_buf1[col_cnt];
            r11 <= r12;
            r10 <= r11;

            r02 <= line_buf0[col_cnt];
            r01 <= r02;
            r00 <= r01;

            // Tracking coordinates
            if (col_cnt == IMAGE_WIDTH - 1) begin
                col_cnt <= 0;
                row_cnt <= row_cnt + 1;
            end else begin
                col_cnt <= col_cnt + 1;
            end

            // Window valid once first 2 rows and 2 columns are loaded
            if (row_cnt >= 2 && col_cnt >= 2)
                window_valid <= 1'b1;
            else
                window_valid <= 1'b0;
        end else begin
            window_valid <= 1'b0;
        end
    end

    // Assign window outputs
    assign win_00 = r00; assign win_01 = r01; assign win_02 = r02;
    assign win_10 = r10; assign win_11 = r11; assign win_12 = r12;
    assign win_20 = r20; assign win_21 = r21; assign win_22 = r22;

endmodule