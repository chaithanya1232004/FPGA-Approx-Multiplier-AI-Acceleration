`timescale 1ns / 1ps

module cnn_conv_engine #(
    parameter DATA_WIDTH  = 16,
    parameter ACCUM_WIDTH = 40
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          start_conv,
    input  wire                          pixel_valid,
    input  wire [1:0]                    precision_mode,
    input  wire signed [DATA_WIDTH-1:0]  pixel_in,
    input  wire signed [DATA_WIDTH-1:0]  weight_in,
    input  wire signed [DATA_WIDTH-1:0]  bias_in,
    
    output reg  signed [DATA_WIDTH-1:0]  feature_out,
    output reg                           feature_valid
);

    reg [3:0] tap_count;
    reg       mac_clr;
    reg       mac_valid_in;
    
    wire signed [ACCUM_WIDTH-1:0] mac_accum_out;
    wire                          mac_valid_out;

    approx_mac_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) u_approx_mac (
        .clk(clk),
        .rst_n(rst_n),
        .clr(mac_clr),
        .valid_in(mac_valid_in),
        .precision_mode(precision_mode),
        .a(pixel_in),
        .b(weight_in),
        .accum_out(mac_accum_out),
        .valid_out(mac_valid_out)
    );

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

    wire signed [ACCUM_WIDTH-1:0] biased_sum;
    assign biased_sum = mac_accum_out + {{(ACCUM_WIDTH-DATA_WIDTH){bias_in[DATA_WIDTH-1]}}, bias_in};

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
                if (biased_sum < 0) begin
                    feature_out <= 16'sd0;
                end else if (biased_sum > 32767) begin
                    feature_out <= 16'sd32767;
                end else begin
                    feature_out <= biased_sum[15:0];
                end
            end else begin
                feature_valid <= 1'b0;
            end
        end
    end

endmodule