`timescale 1ns/1ps

module sparse4_prefix_cell #(
    parameter PREFIX_DEPTH = 0,
    parameter DISTANCE = 0,
    parameter HIGH_INDEX = 0,
    parameter LOW_INDEX = 0
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

module sparse4_local_carry_cell #(
    parameter LOCAL_DEPTH = 0
) (
    input  G,
    input  P,
    input  C_in,
    output C_out
);
    assign C_out = G | (P & C_in);
endmodule

// Sparse-4 definition used here:
// balanced 4-bit groups + 4-group Kogge-Stone + local ripple carry.
module sparse4_16 (
    input  [15:0] A,
    input  [15:0] B,
    output [16:0] SUM
);
    wire [15:0] G0;
    wire [15:0] P0;
    wire [3:0] low_pair_g;
    wire [3:0] low_pair_p;
    wire [3:0] high_pair_g;
    wire [3:0] high_pair_p;
    wire [3:0] group_g;
    wire [3:0] group_p;
    wire [3:0] stage1_g;
    wire [3:0] stage1_p;
    wire [3:0] stage2_g;
    wire [3:0] stage2_p;
    wire [16:0] C;

    assign G0 = A & B;
    assign P0 = A ^ B;
    assign C[0] = 1'b0;

    // Four balanced 4-bit group trees: two pair cells, then one group cell.
    genvar group_index;
    generate
        for (group_index = 0; group_index < 4;
             group_index = group_index + 1) begin : group_tree
            sparse4_prefix_cell #(
                .PREFIX_DEPTH(1), .DISTANCE(1),
                .HIGH_INDEX(4*group_index+1),
                .LOW_INDEX(4*group_index)
            ) u_low_pair (
                .G_high(G0[4*group_index+1]),
                .P_high(P0[4*group_index+1]),
                .G_low (G0[4*group_index]),
                .P_low (P0[4*group_index]),
                .G_out (low_pair_g[group_index]),
                .P_out (low_pair_p[group_index])
            );

            sparse4_prefix_cell #(
                .PREFIX_DEPTH(1), .DISTANCE(1),
                .HIGH_INDEX(4*group_index+3),
                .LOW_INDEX(4*group_index+2)
            ) u_high_pair (
                .G_high(G0[4*group_index+3]),
                .P_high(P0[4*group_index+3]),
                .G_low (G0[4*group_index+2]),
                .P_low (P0[4*group_index+2]),
                .G_out (high_pair_g[group_index]),
                .P_out (high_pair_p[group_index])
            );

            sparse4_prefix_cell #(
                .PREFIX_DEPTH(2), .DISTANCE(2),
                .HIGH_INDEX(4*group_index+3),
                .LOW_INDEX(4*group_index+1)
            ) u_group (
                .G_high(high_pair_g[group_index]),
                .P_high(high_pair_p[group_index]),
                .G_low (low_pair_g[group_index]),
                .P_low (low_pair_p[group_index]),
                .G_out (group_g[group_index]),
                .P_out (group_p[group_index])
            );
        end
    endgenerate

    // Four-group Kogge-Stone stage 1: adjacent-group distance = 1.
    genvar stage1_index;
    generate
        for (stage1_index = 0; stage1_index < 4;
             stage1_index = stage1_index + 1) begin : intergroup_stage1
            if (stage1_index < 1) begin : pass
                assign stage1_g[stage1_index] = group_g[stage1_index];
                assign stage1_p[stage1_index] = group_p[stage1_index];
            end else begin : prefix
                sparse4_prefix_cell #(
                    .PREFIX_DEPTH(3), .DISTANCE(1),
                    .HIGH_INDEX(stage1_index),
                    .LOW_INDEX(stage1_index-1)
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

    // Four-group Kogge-Stone stage 2: group distance = 2.
    genvar stage2_index;
    generate
        for (stage2_index = 0; stage2_index < 4;
             stage2_index = stage2_index + 1) begin : intergroup_stage2
            if (stage2_index < 2) begin : pass
                assign stage2_g[stage2_index] = stage1_g[stage2_index];
                assign stage2_p[stage2_index] = stage1_p[stage2_index];
            end else begin : prefix
                sparse4_prefix_cell #(
                    .PREFIX_DEPTH(4), .DISTANCE(2),
                    .HIGH_INDEX(stage2_index),
                    .LOW_INDEX(stage2_index-2)
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

    // Three local ripple steps per group. Group-end carry is prefix-derived.
    genvar carry_group;
    generate
        for (carry_group = 0; carry_group < 4;
             carry_group = carry_group + 1) begin : local_ripple
            sparse4_local_carry_cell #(.LOCAL_DEPTH(1)) u_carry1 (
                G0[4*carry_group], P0[4*carry_group],
                C[4*carry_group], C[4*carry_group+1]
            );
            sparse4_local_carry_cell #(.LOCAL_DEPTH(2)) u_carry2 (
                G0[4*carry_group+1], P0[4*carry_group+1],
                C[4*carry_group+1], C[4*carry_group+2]
            );
            sparse4_local_carry_cell #(.LOCAL_DEPTH(3)) u_carry3 (
                G0[4*carry_group+2], P0[4*carry_group+2],
                C[4*carry_group+2], C[4*carry_group+3]
            );
            assign C[4*carry_group+4] = stage2_g[carry_group];
        end
    endgenerate

    assign SUM[15:0] = P0 ^ C[15:0];
    assign SUM[16] = C[16];
endmodule
