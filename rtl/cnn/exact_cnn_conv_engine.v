`timescale 1ns / 1ps

module exact_cnn_conv_engine #(
    parameter DATA_WIDTH  = 16,
    parameter ACCUM_WIDTH = 40
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          start_conv,
    input  wire                          pixel_valid,
    input  wire signed [DATA_WIDTH-1:0]  pixel_in,
    input  wire signed [DATA_WIDTH-1:0]  weight_in,
    input  wire signed [DATA_WIDTH-1:0]  bias_in,
    
    output reg  signed [DATA_WIDTH-1:0]  feature_out,
    output reg                           feature_valid
);

    // 1. Exact Multiplier Stage
    // 1. Exact Multiplier Stage (Forced to LUT Softcore - No DSP)
    (* use_dsp = "no" *) wire signed [31:0] exact_mult_product;
    assign exact_mult_product = pixel_in * weight_in; // Full precision exact multiplication

    // Pipeline Register
    reg signed [31:0] reg_product;
    reg               reg_clr;
    reg               reg_valid;

    // FSM / Tap Counter
    reg [3:0] tap_count;
    reg       mac_clr;
    reg       mac_valid_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tap_count    <= 4'd0;
            mac_clr      <= 1'b0;
            mac_valid_in <= 1'b0;
        end else if (start_conv) begin
            tap_count    <= 4'd1;
            mac_clr      <= 1'b1;
            mac_valid_in <= pixel_valid;
        end else if (pixel_valid && (tap_count > 4'd0 && tap_count < 4'd9)) begin
            tap_count    <= tap_count + 1'b1;
            mac_clr      <= 1'b0;
            mac_valid_in <= 1'b1;
        end else if (tap_count == 4'd9) begin
            tap_count    <= 4'd0;
            mac_clr      <= 1'b0;
            mac_valid_in <= 1'b0;
        end else begin
            mac_valid_in <= 1'b0;
            mac_clr      <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_product <= 32'sd0;
            reg_clr     <= 1'b0;
            reg_valid   <= 1'b0;
        end else begin
            reg_product <= exact_mult_product;
            reg_clr     <= mac_clr;
            reg_valid   <= mac_valid_in;
        end
    end

    // 2. Accumulator Stage (40-bit with guard bits)
    reg signed [ACCUM_WIDTH-1:0] accum_out;
    wire signed [ACCUM_WIDTH-1:0] product_ext;
    assign product_ext = {{(ACCUM_WIDTH-32){reg_product[31]}}, reg_product};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum_out <= {ACCUM_WIDTH{1'b0}};
        end else if (reg_valid) begin
            if (reg_clr)
                accum_out <= product_ext;
            else
                accum_out <= accum_out + product_ext;
        end
    end

    // 3. Bias Addition and ReLU
    wire signed [ACCUM_WIDTH-1:0] biased_sum;
    assign biased_sum = accum_out + {{(ACCUM_WIDTH-DATA_WIDTH){bias_in[DATA_WIDTH-1]}}, bias_in};

    reg [1:0] output_delay_sr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feature_out     <= {DATA_WIDTH{1'b0}};
            feature_valid   <= 1'b0;
            output_delay_sr <= 2'b00;
        end else begin
            output_delay_sr <= {output_delay_sr[0], (tap_count == 4'd9)};
            if (output_delay_sr[1]) begin
                feature_valid <= 1'b1;
                if (biased_sum < 0)
                    feature_out <= 16'sd0;
                else if (biased_sum > 32767)
                    feature_out <= 16'sd32767;
                else
                    feature_out <= biased_sum[15:0];
            end else begin
                feature_valid <= 1'b0;
            end
        end
    end

endmodule