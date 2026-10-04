`timescale 1ns / 1ps

module approx_mac_unit #(
    parameter DATA_WIDTH  = 16,
    parameter PROD_WIDTH  = 32,
    parameter ACCUM_WIDTH = 40
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          clr,
    input  wire                          valid_in,
    input  wire [1:0]                    precision_mode, // 00:Exact, 01:f=14, 10:f=18, 11:f=20
    input  wire signed [DATA_WIDTH-1:0]  a,
    input  wire signed [DATA_WIDTH-1:0]  b,
    
    output reg  signed [ACCUM_WIDTH-1:0] accum_out,
    output reg                           valid_out
);

    // 1. Instantiate the Dynamic Multiplier Core
    wire signed [PROD_WIDTH-1:0] mult_product;

    dynamic_approx_mult u_dyn_mult (
        .precision_mode(precision_mode),
        .a(a),
        .b(b),
        .product(mult_product)
    );

    // 2. Pipeline Register Stage
    reg signed [PROD_WIDTH-1:0] reg_product;
    reg                         reg_clr;
    reg                         reg_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_product <= {PROD_WIDTH{1'b0}};
            reg_clr     <= 1'b0;
            reg_valid   <= 1'b0;
        end else begin
            reg_product <= mult_product;
            reg_clr     <= clr;
            reg_valid   <= valid_in;
        end
    end

    // 3. 40-bit Accumulator Stage with 8 Guard Bits
    wire signed [ACCUM_WIDTH-1:0] product_ext;
    assign product_ext = {{(ACCUM_WIDTH - PROD_WIDTH){reg_product[PROD_WIDTH-1]}}, reg_product};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum_out <= {ACCUM_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else if (reg_valid) begin
            if (reg_clr)
                accum_out <= product_ext;
            else
                accum_out <= accum_out + product_ext;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule