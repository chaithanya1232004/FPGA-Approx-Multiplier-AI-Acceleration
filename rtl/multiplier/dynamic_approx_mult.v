`timescale 1ns / 1ps

module dynamic_approx_mult (
    input  wire [1:0]            precision_mode, // 00: Exact, 01: f=14, 10: f=18, 11: f=20
    input  wire signed [15:0]    a,
    input  wire signed [15:0]    b,
    output reg  signed [31:0]    product
);

    wire signed [31:0] prod_exact;
    wire signed [31:0] prod_f14;
    wire signed [31:0] prod_f18;
    wire signed [31:0] prod_f20;

    // Exact Softcore Multiplier (DSP-Free)
    (* use_dsp = "no" *) assign prod_exact = a * b;

    // Proposed Approximate Cores at different Pareto points
    Approxi_Multi #(.approximate_bit(5'd14)) u_f14 (.a(a), .b(b), .product(prod_f14));
    Approxi_Multi #(.approximate_bit(5'd18)) u_f18 (.a(a), .b(b), .product(prod_f18));
    Approxi_Multi #(.approximate_bit(5'd20)) u_f20 (.a(a), .b(b), .product(prod_f20));

    // Dynamic Run-time Selector
    always @(*) begin
        case (precision_mode)
            2'b00:   product = prod_exact; // Exact mode
            2'b01:   product = prod_f14;   // f=14 (99.2% accuracy)
            2'b10:   product = prod_f18;   // f=18 (Balanced)
            2'b11:   product = prod_f20;   // f=20 (Max hardware savings)
            default: product = prod_f14;
        endcase
    end

endmodule