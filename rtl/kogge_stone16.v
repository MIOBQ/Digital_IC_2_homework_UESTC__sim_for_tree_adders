`timescale 1ns/1ps

module ks_prefix_cell (
    input  G_high,
    input  P_high,
    input  G_low,
    input  P_low,
    output G_out,
    output P_out
);
    assign G_out = G_high | (P_high & G_low);
    assign P_out = P_high & P_low;
endmodule

// 16-bit radix-2 Kogge-Stone adder with Cin fixed at zero.
module kogge_stone16 (
    input  [15:0] A,
    input  [15:0] B,
    output [16:0] SUM
);
    wire [15:0] G0;
    wire [15:0] P0;
    wire [15:0] G1;
    wire [15:0] P1;
    wire [15:0] G2;
    wire [15:0] P2;
    wire [15:0] G3;
    wire [15:0] P3;
    wire [15:0] G4;
    wire [15:0] P4;
    wire [16:0] C;

    // Single-bit generate/propagate preprocessing.
    assign G0 = A & B;
    assign P0 = A ^ B;
    assign C[0] = 1'b0;

    // Stage 1: radix-2 prefix distance = 1 (15 prefix cells).
    genvar s1;
    generate
        for (s1 = 0; s1 < 16; s1 = s1 + 1) begin : stage1
            if (s1 < 1) begin : pass
                assign G1[s1] = G0[s1];
                assign P1[s1] = P0[s1];
            end else begin : prefix
                ks_prefix_cell u_prefix (
                    .G_high(G0[s1]),   .P_high(P0[s1]),
                    .G_low (G0[s1-1]), .P_low (P0[s1-1]),
                    .G_out (G1[s1]),   .P_out (P1[s1])
                );
            end
        end
    endgenerate

    // Stage 2: radix-2 prefix distance = 2 (14 prefix cells).
    genvar s2;
    generate
        for (s2 = 0; s2 < 16; s2 = s2 + 1) begin : stage2
            if (s2 < 2) begin : pass
                assign G2[s2] = G1[s2];
                assign P2[s2] = P1[s2];
            end else begin : prefix
                ks_prefix_cell u_prefix (
                    .G_high(G1[s2]),   .P_high(P1[s2]),
                    .G_low (G1[s2-2]), .P_low (P1[s2-2]),
                    .G_out (G2[s2]),   .P_out (P2[s2])
                );
            end
        end
    endgenerate

    // Stage 3: radix-2 prefix distance = 4 (12 prefix cells).
    genvar s3;
    generate
        for (s3 = 0; s3 < 16; s3 = s3 + 1) begin : stage3
            if (s3 < 4) begin : pass
                assign G3[s3] = G2[s3];
                assign P3[s3] = P2[s3];
            end else begin : prefix
                ks_prefix_cell u_prefix (
                    .G_high(G2[s3]),   .P_high(P2[s3]),
                    .G_low (G2[s3-4]), .P_low (P2[s3-4]),
                    .G_out (G3[s3]),   .P_out (P3[s3])
                );
            end
        end
    endgenerate

    // Stage 4: radix-2 prefix distance = 8 (8 prefix cells).
    genvar s4;
    generate
        for (s4 = 0; s4 < 16; s4 = s4 + 1) begin : stage4
            if (s4 < 8) begin : pass
                assign G4[s4] = G3[s4];
                assign P4[s4] = P3[s4];
            end else begin : prefix
                ks_prefix_cell u_prefix (
                    .G_high(G3[s4]),   .P_high(P3[s4]),
                    .G_low (G3[s4-8]), .P_low (P3[s4-8]),
                    .G_out (G4[s4]),   .P_out (P4[s4])
                );
            end
        end
    endgenerate

    // With Cin=0, each group-generate output is the next carry.
    genvar carry_index;
    generate
        for (carry_index = 1; carry_index <= 16;
             carry_index = carry_index + 1) begin : carry_output
            assign C[carry_index] = G4[carry_index-1];
        end
    endgenerate

    assign SUM[15:0] = P0 ^ C[15:0];
    assign SUM[16] = C[16];
endmodule
