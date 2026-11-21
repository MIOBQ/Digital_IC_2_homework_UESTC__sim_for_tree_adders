`timescale 1ns/1ps

module bk_black_cell (
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

module bk_gray_cell (
    input  G_high,
    input  P_high,
    input  G_low,
    output G_out
);
    assign G_out = G_high | (P_high & G_low);
endmodule

// 16-bit radix-2 Brent-Kung prefix adder with Cin fixed at zero.
module brent_kung16 (
    input  [15:0] A,
    input  [15:0] B,
    output [16:0] SUM
);
    wire [15:0] G0;
    wire [15:0] P0;
    wire [16:0] C;

    assign G0 = A & B;
    assign P0 = A ^ B;
    assign C[0] = 1'b0;

    // Up-Sweep stage 1: eight adjacent two-bit groups.
    wire g_1_0;
    wire g_3_2,   p_3_2;
    wire g_5_4,   p_5_4;
    wire g_7_6,   p_7_6;
    wire g_9_8,   p_9_8;
    wire g_11_10, p_11_10;
    wire g_13_12, p_13_12;
    wire g_15_14, p_15_14;

    generate begin : up_sweep_stage1
        bk_gray_cell  u_1_0   (G0[1],  P0[1],  G0[0],  g_1_0);
        bk_black_cell u_3_2   (G0[3],  P0[3],  G0[2],  P0[2],  g_3_2,   p_3_2);
        bk_black_cell u_5_4   (G0[5],  P0[5],  G0[4],  P0[4],  g_5_4,   p_5_4);
        bk_black_cell u_7_6   (G0[7],  P0[7],  G0[6],  P0[6],  g_7_6,   p_7_6);
        bk_black_cell u_9_8   (G0[9],  P0[9],  G0[8],  P0[8],  g_9_8,   p_9_8);
        bk_black_cell u_11_10 (G0[11], P0[11], G0[10], P0[10], g_11_10, p_11_10);
        bk_black_cell u_13_12 (G0[13], P0[13], G0[12], P0[12], g_13_12, p_13_12);
        bk_black_cell u_15_14 (G0[15], P0[15], G0[14], P0[14], g_15_14, p_15_14);
    end endgenerate

    // Up-Sweep stage 2: four four-bit groups.
    wire g_3_0;
    wire g_7_4,   p_7_4;
    wire g_11_8,  p_11_8;
    wire g_15_12, p_15_12;

    generate begin : up_sweep_stage2
        bk_gray_cell  u_3_0   (g_3_2,   p_3_2,   g_1_0,   g_3_0);
        bk_black_cell u_7_4   (g_7_6,   p_7_6,   g_5_4,   p_5_4,   g_7_4,   p_7_4);
        bk_black_cell u_11_8  (g_11_10, p_11_10, g_9_8,   p_9_8,   g_11_8,  p_11_8);
        bk_black_cell u_15_12 (g_15_14, p_15_14, g_13_12, p_13_12, g_15_12, p_15_12);
    end endgenerate

    // Up-Sweep stage 3: two eight-bit groups.
    wire g_7_0;
    wire g_15_8, p_15_8;

    generate begin : up_sweep_stage3
        bk_gray_cell  u_7_0  (g_7_4,   p_7_4,   g_3_0,  g_7_0);
        bk_black_cell u_15_8 (g_15_12, p_15_12, g_11_8, p_11_8, g_15_8, p_15_8);
    end endgenerate

    // Up-Sweep stage 4: complete sixteen-bit prefix.
    wire g_15_0;

    generate begin : up_sweep_stage4
        bk_gray_cell u_15_0 (g_15_8, p_15_8, g_7_0, g_15_0);
    end endgenerate

    // Down-Sweep stage 5: fill prefix ending at bit 11.
    wire g_11_0;

    generate begin : down_sweep_stage5
        bk_gray_cell u_11_0 (g_11_8, p_11_8, g_7_0, g_11_0);
    end endgenerate

    // Down-Sweep stage 6: fill prefixes ending at bits 5, 9, and 13.
    wire g_5_0;
    wire g_9_0;
    wire g_13_0;

    generate begin : down_sweep_stage6
        bk_gray_cell u_5_0  (g_5_4,   p_5_4,   g_3_0,  g_5_0);
        bk_gray_cell u_9_0  (g_9_8,   p_9_8,   g_7_0,  g_9_0);
        bk_gray_cell u_13_0 (g_13_12, p_13_12, g_11_0, g_13_0);
    end endgenerate

    // Down-Sweep stage 7: fill the seven remaining even-index prefixes.
    wire g_2_0;
    wire g_4_0;
    wire g_6_0;
    wire g_8_0;
    wire g_10_0;
    wire g_12_0;
    wire g_14_0;

    generate begin : down_sweep_stage7
        bk_gray_cell u_2_0  (G0[2],  P0[2],  g_1_0,  g_2_0);
        bk_gray_cell u_4_0  (G0[4],  P0[4],  g_3_0,  g_4_0);
        bk_gray_cell u_6_0  (G0[6],  P0[6],  g_5_0,  g_6_0);
        bk_gray_cell u_8_0  (G0[8],  P0[8],  g_7_0,  g_8_0);
        bk_gray_cell u_10_0 (G0[10], P0[10], g_9_0,  g_10_0);
        bk_gray_cell u_12_0 (G0[12], P0[12], g_11_0, g_12_0);
        bk_gray_cell u_14_0 (G0[14], P0[14], g_13_0, g_14_0);
    end endgenerate

    assign C[1]  = G0[0];
    assign C[2]  = g_1_0;
    assign C[3]  = g_2_0;
    assign C[4]  = g_3_0;
    assign C[5]  = g_4_0;
    assign C[6]  = g_5_0;
    assign C[7]  = g_6_0;
    assign C[8]  = g_7_0;
    assign C[9]  = g_8_0;
    assign C[10] = g_9_0;
    assign C[11] = g_10_0;
    assign C[12] = g_11_0;
    assign C[13] = g_12_0;
    assign C[14] = g_13_0;
    assign C[15] = g_14_0;
    assign C[16] = g_15_0;

    assign SUM[15:0] = P0 ^ C[15:0];
    assign SUM[16] = C[16];
endmodule
