`timescale 1ns/1ps

// 16-bit unsigned ripple-carry adder.
// Cin is fixed at zero; SUM[16] is the final carry-out.
module rca16 (
    input  [15:0] A,
    input  [15:0] B,
    output [16:0] SUM
);
    wire [15:0] G;
    wire [15:0] P;
    wire [16:0] C;

    assign G    = A & B;
    assign P    = A ^ B;
    assign C[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_rca_stage
            assign SUM[i] = P[i] ^ C[i];
            assign C[i+1] = G[i] | (P[i] & C[i]);
        end
    endgenerate

    assign SUM[16] = C[16];
endmodule
