`timescale 1ns/1ps

module sparse2_prefix_cell #(
    parameter PREFIX_DEPTH = 0,
    parameter DISTANCE = 0
) (
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

// Sparse-2 definition used here:
// 2-bit groups + 8-group Kogge-Stone prefix + local within-group carry.
module sparse2_16 (
    input  [15:0] A,
    input  [15:0] B,
    output [16:0] SUM
);
    wire [15:0] G0;
    wire [15:0] P0;
    wire [7:0] group_g;
    wire [7:0] group_p;
    wire [7:0] stage1_g;
    wire [7:0] stage1_p;
    wire [7:0] stage2_g;
    wire [7:0] stage2_p;
    wire [7:0] stage3_g;
    wire [7:0] stage3_p;
    wire [16:0] C;

    assign G0 = A & B;
    assign P0 = A ^ B;
    assign C[0] = 1'b0;

    // Eight 2-bit group preprocessing prefix cells.
    genvar group_index;
    generate
        for (group_index = 0; group_index < 8;
             group_index = group_index + 1) begin : group_preprocess
            sparse2_prefix_cell #(
                .PREFIX_DEPTH(1),
                .DISTANCE(1)
            ) u_group_prefix (
                .G_high(G0[2*group_index+1]),
                .P_high(P0[2*group_index+1]),
                .G_low (G0[2*group_index]),
                .P_low (P0[2*group_index]),
                .G_out (group_g[group_index]),
                .P_out (group_p[group_index])
            );
        end
    endgenerate

    // Eight-group Kogge-Stone stage 1: adjacent-group distance = 1.
    genvar stage1_index;
    generate
        for (stage1_index = 0; stage1_index < 8;
             stage1_index = stage1_index + 1) begin : intergroup_stage1
            if (stage1_index < 1) begin : pass
                assign stage1_g[stage1_index] = group_g[stage1_index];
                assign stage1_p[stage1_index] = group_p[stage1_index];
            end else begin : prefix
                sparse2_prefix_cell #(
                    .PREFIX_DEPTH(2),
                    .DISTANCE(1)
                ) u_prefix (
                    .G_high(group_g[stage1_index]),
                    .P_high(group_p[stage1_index]),
                    .G_low (group_g[stage1_index-1]),
                    .P_low (group_p[stage1_index-1]),
                    .G_out (stage1_g[stage1_index]),
                    .P_out (stage1_p[stage1_index])
                );
            end
        end
    endgenerate

    // Eight-group Kogge-Stone stage 2: group distance = 2.
    genvar stage2_index;
    generate
        for (stage2_index = 0; stage2_index < 8;
             stage2_index = stage2_index + 1) begin : intergroup_stage2
            if (stage2_index < 2) begin : pass
                assign stage2_g[stage2_index] = stage1_g[stage2_index];
                assign stage2_p[stage2_index] = stage1_p[stage2_index];
            end else begin : prefix
                sparse2_prefix_cell #(
                    .PREFIX_DEPTH(3),
                    .DISTANCE(2)
                ) u_prefix (
                    .G_high(stage1_g[stage2_index]),
                    .P_high(stage1_p[stage2_index]),
                    .G_low (stage1_g[stage2_index-2]),
                    .P_low (stage1_p[stage2_index-2]),
                    .G_out (stage2_g[stage2_index]),
                    .P_out (stage2_p[stage2_index])
                );
            end
        end
    endgenerate

    // Eight-group Kogge-Stone stage 3: group distance = 4.
    genvar stage3_index;
    generate
        for (stage3_index = 0; stage3_index < 8;
             stage3_index = stage3_index + 1) begin : intergroup_stage3
            if (stage3_index < 4) begin : pass
                assign stage3_g[stage3_index] = stage2_g[stage3_index];
                assign stage3_p[stage3_index] = stage2_p[stage3_index];
            end else begin : prefix
                sparse2_prefix_cell #(
                    .PREFIX_DEPTH(4),
                    .DISTANCE(4)
                ) u_prefix (
                    .G_high(stage2_g[stage3_index]),
                    .P_high(stage2_p[stage3_index]),
                    .G_low (stage2_g[stage3_index-4]),
                    .P_low (stage2_p[stage3_index-4]),
                    .G_out (stage3_g[stage3_index]),
                    .P_out (stage3_p[stage3_index])
                );
            end
        end
    endgenerate

    // Group boundary carries come from the complete group prefixes.
    // Odd-bit carries use only local single-bit G/P plus the group input carry.
    genvar carry_group;
    generate
        for (carry_group = 0; carry_group < 8;
             carry_group = carry_group + 1) begin : local_carry
            assign C[2*carry_group+1] =
                G0[2*carry_group] |
                (P0[2*carry_group] & C[2*carry_group]);
            assign C[2*carry_group+2] = stage3_g[carry_group];
        end
    endgenerate

    assign SUM[15:0] = P0 ^ C[15:0];
    assign SUM[16] = C[16];
endmodule
