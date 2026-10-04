`timescale 1ns / 1ps
module tb_top(  );
reg [15:0] mul_A;
reg [15:0] mul_B;
reg [15:0] temp[999:0];
//reg [2*n-1:0] out_temp[225:0];
wire [31:0] result;

integer i;
integer j;
integer fp;	

//acc_adder testmul_multi8(
top test(
    .a(mul_A),
    .b(mul_B),
    
    .product(result)
    );

initial begin
fp = $fopen("out_result.txt","w");

$readmemb("C:/Project/FABM/16x16/sim/random_signed_16bit_numbers.txt", temp);
$display("------ Simulation Started ------");

        // Test with the first 50x50 = 2500 samples first (quick verification)
        // You can change 50 back to 1000 for full 1-million pattern generation later
        for(i = 0; i < 50; i = i + 1) begin
            mul_A = temp[i];
            for(j = 0; j < 50; j = j + 1) begin
                mul_B = temp[j];
                #10;
                $fdisplay(fp, "%d %d %d", mul_A, mul_B, result);
                $display("Time=%0t ps | A=%d | B=%d | Approx Product=%d | Exact Product=%d", 
                         $time, mul_A, mul_B, result, (mul_A * mul_B));
            end
        end

        $fclose(fp);
        $display("------ Simulation Finished Successfully! ------");
        $finish;
    end

endmodule
