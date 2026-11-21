`timescale 1ns/1ps

module hc_black_cell #(
    parameter NODE_ID=-1, parameter HIGH_SOURCE_ID=-1,
    parameter LOW_SOURCE_ID=-1, parameter HIGH_INDEX=0,
    parameter LOW_INDEX=0, parameter STAGE=0
) (input G_high, input P_high, input G_low, input P_low,
   output G_out, output P_out);
    assign G_out = G_high | (P_high & G_low);
    assign P_out = P_high & P_low;
endmodule

module hc_gray_cell #(
    parameter NODE_ID=-1, parameter HIGH_SOURCE_ID=-1,
    parameter LOW_SOURCE_ID=-1, parameter HIGH_INDEX=0,
    parameter LOW_INDEX=0, parameter STAGE=0
) (input G_high, input P_high, input G_low, output G_out);
    assign G_out = G_high | (P_high & G_low);
endmodule

module han_carlson16 (
    input [15:0] A, input [15:0] B, output [16:0] SUM
);
    wire [15:0] G0, P0;
    wire [7:0] G1, P1, G2, P2, G3, P3, G4;
    wire [16:0] C;
    assign G0=A&B;
    assign P0=A^B;
    assign C[0]=1'b0;
    assign C[1]=G0[0];

    // Stage 1: adjacent bit pairs. Group 0 needs only G downstream.
    genvar s1;
    generate for(s1=0;s1<8;s1=s1+1) begin: stage1
        if(s1==0) begin: gray
            hc_gray_cell #(.NODE_ID(s1),.HIGH_INDEX(2*s1+1),.LOW_INDEX(2*s1),.STAGE(1)) u_cell
              (G0[2*s1+1],P0[2*s1+1],G0[2*s1],G1[s1]);
        end else begin: black
            hc_black_cell #(.NODE_ID(s1),.HIGH_INDEX(2*s1+1),.LOW_INDEX(2*s1),.STAGE(1)) u_cell
              (G0[2*s1+1],P0[2*s1+1],G0[2*s1],P0[2*s1],G1[s1],P1[s1]);
        end
    end endgenerate

    assign G2[0]=G1[0];
    // Stage 2: group distance 1. Index 1 is low-only downstream.
    genvar s2;
    generate for(s2=1;s2<8;s2=s2+1) begin: stage2
        if(s2==1) begin: gray
            hc_gray_cell #(.NODE_ID(7+s2),.HIGH_SOURCE_ID(s2),.LOW_SOURCE_ID(s2-1),
              .HIGH_INDEX(s2),.LOW_INDEX(s2-1),.STAGE(2)) u_cell
              (G1[s2],P1[s2],G1[s2-1],G2[s2]);
        end else begin: black
            hc_black_cell #(.NODE_ID(7+s2),.HIGH_SOURCE_ID(s2),.LOW_SOURCE_ID(s2-1),
              .HIGH_INDEX(s2),.LOW_INDEX(s2-1),.STAGE(2)) u_cell
              (G1[s2],P1[s2],G1[s2-1],P1[s2-1],G2[s2],P2[s2]);
        end
    end endgenerate

    assign G3[0]=G2[0];
    assign G3[1]=G2[1];
    // Stage 3: group distance 2. Indices 2 and 3 are low-only downstream.
    genvar s3;
    generate for(s3=2;s3<8;s3=s3+1) begin: stage3
        if(s3<4) begin: gray
            hc_gray_cell #(.NODE_ID(13+s3),
              .HIGH_SOURCE_ID(7+s3),.LOW_SOURCE_ID((s3-2)==0?0:7+s3-2),
              .HIGH_INDEX(s3),.LOW_INDEX(s3-2),.STAGE(3)) u_cell
              (G2[s3],P2[s3],G2[s3-2],G3[s3]);
        end else begin: black
            hc_black_cell #(.NODE_ID(13+s3),
              .HIGH_SOURCE_ID(7+s3),.LOW_SOURCE_ID((s3-2)==0?0:7+s3-2),
              .HIGH_INDEX(s3),.LOW_INDEX(s3-2),.STAGE(3)) u_cell
              (G2[s3],P2[s3],G2[s3-2],P2[s3-2],G3[s3],P3[s3]);
        end
    end endgenerate

    assign G4[0]=G3[0]; assign G4[1]=G3[1];
    assign G4[2]=G3[2]; assign G4[3]=G3[3];
    // Stage 4: group distance 4; final group prefixes need G only.
    genvar s4;
    generate for(s4=4;s4<8;s4=s4+1) begin: stage4
        hc_gray_cell #(.NODE_ID(17+s4),
          .HIGH_SOURCE_ID(13+s4),
          .LOW_SOURCE_ID((s4-4)==0?0:((s4-4)==1?8:13+s4-4)),
          .HIGH_INDEX(s4),.LOW_INDEX(s4-4),.STAGE(4)) u_cell
          (G3[s4],P3[s4],G3[s4-4],G4[s4]);
    end endgenerate

    assign C[2]=G4[0]; assign C[4]=G4[1];
    assign C[6]=G4[2]; assign C[8]=G4[3];
    assign C[10]=G4[4]; assign C[12]=G4[5];
    assign C[14]=G4[6]; assign C[16]=G4[7];

    // Stage 5: explicit gray cells fill odd-index carries.
    generate begin: stage5
        hc_gray_cell #(.NODE_ID(25),.LOW_SOURCE_ID(0), .HIGH_INDEX(2), .LOW_INDEX(1), .STAGE(5)) u_c3  (G0[2], P0[2], C[2], C[3]);
        hc_gray_cell #(.NODE_ID(26),.LOW_SOURCE_ID(8), .HIGH_INDEX(4), .LOW_INDEX(3), .STAGE(5)) u_c5  (G0[4], P0[4], C[4], C[5]);
        hc_gray_cell #(.NODE_ID(27),.LOW_SOURCE_ID(15),.HIGH_INDEX(6), .LOW_INDEX(5), .STAGE(5)) u_c7  (G0[6], P0[6], C[6], C[7]);
        hc_gray_cell #(.NODE_ID(28),.LOW_SOURCE_ID(16),.HIGH_INDEX(8), .LOW_INDEX(7), .STAGE(5)) u_c9  (G0[8], P0[8], C[8], C[9]);
        hc_gray_cell #(.NODE_ID(29),.LOW_SOURCE_ID(21),.HIGH_INDEX(10),.LOW_INDEX(9), .STAGE(5)) u_c11 (G0[10],P0[10],C[10],C[11]);
        hc_gray_cell #(.NODE_ID(30),.LOW_SOURCE_ID(22),.HIGH_INDEX(12),.LOW_INDEX(11),.STAGE(5)) u_c13 (G0[12],P0[12],C[12],C[13]);
        hc_gray_cell #(.NODE_ID(31),.LOW_SOURCE_ID(23),.HIGH_INDEX(14),.LOW_INDEX(13),.STAGE(5)) u_c15 (G0[14],P0[14],C[14],C[15]);
    end endgenerate

    assign SUM[15:0]=P0^C[15:0];
    assign SUM[16]=C[16];
endmodule
