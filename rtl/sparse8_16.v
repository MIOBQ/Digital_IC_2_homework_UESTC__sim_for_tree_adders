`timescale 1ns/1ps

module sparse8_prefix_cell #(
    parameter NODE_ID = -1,
    parameter HIGH_SOURCE_ID = -1,
    parameter LOW_SOURCE_ID = -1,
    parameter HIGH_INDEX = 0,
    parameter LOW_INDEX = 0,
    parameter DISTANCE = 0
) (
    input G_high, input P_high, input G_low, input P_low,
    output G_out, output P_out
);
    assign G_out = G_high | (P_high & G_low);
    assign P_out = P_high & P_low;
endmodule

module sparse8_local_carry_cell #(
    parameter NODE_ID = -1,
    parameter PREV_LOCAL_ID = -1,
    parameter BOUNDARY_PREFIX_ID = -1,
    parameter BIT_INDEX = 0
) (
    input G, input P, input C_in, output C_out
);
    assign C_out = G | (P & C_in);
endmodule

module sparse8_16 (
    input [15:0] A,
    input [15:0] B,
    output [16:0] SUM
);
    wire [15:0] G0;
    wire [15:0] P0;
    wire [7:0] pair_g, pair_p;
    wire [3:0] quad_g, quad_p;
    wire [1:0] group_g, group_p;
    wire full_group_g, full_group_p;
    wire [16:0] C;

    assign G0 = A & B;
    assign P0 = A ^ B;
    assign C[0] = 1'b0;

    genvar group_index;
    genvar pair_index;
    generate
        for (group_index = 0; group_index < 2;
             group_index = group_index + 1) begin : group_tree
            for (pair_index = 0; pair_index < 4;
                 pair_index = pair_index + 1) begin : level1
                sparse8_prefix_cell #(
                    .NODE_ID(7*group_index+pair_index),
                    .HIGH_SOURCE_ID(-1), .LOW_SOURCE_ID(-1),
                    .HIGH_INDEX(8*group_index+2*pair_index+1),
                    .LOW_INDEX(8*group_index+2*pair_index),
                    .DISTANCE(1)
                ) u_prefix (
                    G0[8*group_index+2*pair_index+1],
                    P0[8*group_index+2*pair_index+1],
                    G0[8*group_index+2*pair_index],
                    P0[8*group_index+2*pair_index],
                    pair_g[4*group_index+pair_index],
                    pair_p[4*group_index+pair_index]
                );
            end
        end
    endgenerate

    genvar quad_group;
    genvar quad_index;
    generate
        for (quad_group = 0; quad_group < 2;
             quad_group = quad_group + 1) begin : group_level2
            for (quad_index = 0; quad_index < 2;
                 quad_index = quad_index + 1) begin : node
                sparse8_prefix_cell #(
                    .NODE_ID(7*quad_group+4+quad_index),
                    .HIGH_SOURCE_ID(7*quad_group+2*quad_index+1),
                    .LOW_SOURCE_ID(7*quad_group+2*quad_index),
                    .HIGH_INDEX(8*quad_group+4*quad_index+3),
                    .LOW_INDEX(8*quad_group+4*quad_index+1),
                    .DISTANCE(2)
                ) u_prefix (
                    pair_g[4*quad_group+2*quad_index+1],
                    pair_p[4*quad_group+2*quad_index+1],
                    pair_g[4*quad_group+2*quad_index],
                    pair_p[4*quad_group+2*quad_index],
                    quad_g[2*quad_group+quad_index],
                    quad_p[2*quad_group+quad_index]
                );
            end
        end
    endgenerate

    genvar octet_group;
    generate
        for (octet_group = 0; octet_group < 2;
             octet_group = octet_group + 1) begin : group_level3
            sparse8_prefix_cell #(
                .NODE_ID(7*octet_group+6),
                .HIGH_SOURCE_ID(7*octet_group+5),
                .LOW_SOURCE_ID(7*octet_group+4),
                .HIGH_INDEX(8*octet_group+7),
                .LOW_INDEX(8*octet_group+3),
                .DISTANCE(4)
            ) u_prefix (
                quad_g[2*octet_group+1], quad_p[2*octet_group+1],
                quad_g[2*octet_group], quad_p[2*octet_group],
                group_g[octet_group], group_p[octet_group]
            );
        end
    endgenerate

    generate begin : intergroup_stage1
        sparse8_prefix_cell #(
            .NODE_ID(14), .HIGH_SOURCE_ID(13), .LOW_SOURCE_ID(6),
            .HIGH_INDEX(15), .LOW_INDEX(7), .DISTANCE(1)
        ) u_prefix (
            group_g[1], group_p[1], group_g[0], group_p[0],
            full_group_g, full_group_p
        );
    end endgenerate

    assign C[8] = group_g[0];
    assign C[16] = full_group_g;

    genvar carry_group;
    genvar carry_step;
    generate
        for (carry_group = 0; carry_group < 2;
             carry_group = carry_group + 1) begin : local_ripple
            for (carry_step = 0; carry_step < 7;
                 carry_step = carry_step + 1) begin : step
                sparse8_local_carry_cell #(
                    .NODE_ID(7*carry_group+carry_step),
                    .PREV_LOCAL_ID((carry_step == 0) ? -1 :
                                   7*carry_group+carry_step-1),
                    .BOUNDARY_PREFIX_ID((carry_step == 0 && carry_group == 1) ?
                                        6 : -1),
                    .BIT_INDEX(8*carry_group+carry_step)
                ) u_carry (
                    G0[8*carry_group+carry_step],
                    P0[8*carry_group+carry_step],
                    C[8*carry_group+carry_step],
                    C[8*carry_group+carry_step+1]
                );
            end
        end
    endgenerate

    assign SUM[15:0] = P0 ^ C[15:0];
    assign SUM[16] = C[16];
endmodule
