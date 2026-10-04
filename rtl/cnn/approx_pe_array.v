`timescale 1ns / 1ps

module approx_pe_array #(
    parameter NUM_PES     = 32,
    parameter DATA_WIDTH  = 16,
    parameter ACCUM_WIDTH = 40
)(
    input  wire                                     clk,
    input  wire                                     rst_n,
    input  wire                                     start_conv,
    input  wire                                     pixel_valid,
    input  wire [1:0]                               precision_mode,
    input  wire signed [DATA_WIDTH-1:0]             pixel_in,
    input  wire signed [DATA_WIDTH-1:0]             weight_in,
    input  wire signed [DATA_WIDTH-1:0]             bias_in,
    
    output wire [(NUM_PES*DATA_WIDTH)-1:0]          features_out,
    output wire [NUM_PES-1:0]                       features_valid
);

    genvar i;
    generate
        for (i = 0; i < NUM_PES; i = i + 1) begin : PE_GEN
            cnn_conv_engine #(
                .DATA_WIDTH(DATA_WIDTH),
                .ACCUM_WIDTH(ACCUM_WIDTH)
            ) u_pe (
                .clk(clk),
                .rst_n(rst_n),
                .start_conv(start_conv),
                .pixel_valid(pixel_valid),
                .precision_mode(precision_mode),
                .pixel_in(pixel_in + i),
                .weight_in(weight_in),
                .bias_in(bias_in),
                .feature_out(features_out[((i+1)*DATA_WIDTH)-1 : i*DATA_WIDTH]),
                .feature_valid(features_valid[i])
            );
        end
    endgenerate

endmodule