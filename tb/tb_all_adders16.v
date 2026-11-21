`timescale 1ns/1ps

module tb_all_adders16;
    reg  [15:0] A;
    reg  [15:0] B;
    wire [16:0] sum_rca;
    wire [16:0] sum_ks;
    wire [16:0] sum_bk;
    wire [16:0] sum_sparse2;
    wire [16:0] sum_sparse4;
    wire [16:0] sum_sparse8;
    wire [16:0] sum_hc;
    reg  [16:0] expected;

    integer seed;
    integer random_index;
    integer directed_count;
    integer random_count;
    integer total_vectors;
    integer total_dut_checks;
    integer total_errors;
    integer consistency_errors;
    integer rca_error_count;
    integer kogge_stone_error_count;
    integer brent_kung_error_count;
    integer sparse2_error_count;
    integer sparse4_error_count;
    integer sparse8_error_count;
    integer han_carlson_error_count;
    integer negative_mode;

    rca16          dut_rca          (.A(A), .B(B), .SUM(sum_rca));
    kogge_stone16  dut_kogge_stone  (.A(A), .B(B), .SUM(sum_ks));
    brent_kung16   dut_brent_kung   (.A(A), .B(B), .SUM(sum_bk));
    sparse2_16     dut_sparse2      (.A(A), .B(B), .SUM(sum_sparse2));
    sparse4_16     dut_sparse4      (.A(A), .B(B), .SUM(sum_sparse4));
    sparse8_16     dut_sparse8      (.A(A), .B(B), .SUM(sum_sparse8));
    han_carlson16  dut_han_carlson  (.A(A), .B(B), .SUM(sum_hc));

    task report_mismatch;
        input [8*16-1:0] dut_name;
        input [16:0] actual;
        begin
            $display("ERROR vector=%0d DUT=%0s A=%h B=%h expected=%h actual=%h",
                     total_vectors, dut_name, A, B, expected, actual);
        end
    endtask

    task check_case;
        input [15:0] test_a;
        input [15:0] test_b;
        input is_random;
        begin
            A = test_a;
            B = test_b;
            expected = {1'b0, test_a} + {1'b0, test_b};
            if ((negative_mode != 0) && (total_vectors == 0))
                expected = expected ^ 17'h00001;
            #1;

            total_vectors = total_vectors + 1;
            total_dut_checks = total_dut_checks + 7;
            if (is_random) random_count = random_count + 1;
            else           directed_count = directed_count + 1;

            if (sum_rca !== expected) begin
                rca_error_count = rca_error_count + 1;
                total_errors = total_errors + 1;
                report_mismatch("RCA", sum_rca);
            end
            if (sum_ks !== expected) begin
                kogge_stone_error_count = kogge_stone_error_count + 1;
                total_errors = total_errors + 1;
                report_mismatch("Kogge-Stone", sum_ks);
            end
            if (sum_bk !== expected) begin
                brent_kung_error_count = brent_kung_error_count + 1;
                total_errors = total_errors + 1;
                report_mismatch("Brent-Kung", sum_bk);
            end
            if (sum_sparse2 !== expected) begin
                sparse2_error_count = sparse2_error_count + 1;
                total_errors = total_errors + 1;
                report_mismatch("Sparse-2", sum_sparse2);
            end
            if (sum_sparse4 !== expected) begin
                sparse4_error_count = sparse4_error_count + 1;
                total_errors = total_errors + 1;
                report_mismatch("Sparse-4", sum_sparse4);
            end
            if (sum_sparse8 !== expected) begin
                sparse8_error_count = sparse8_error_count + 1;
                total_errors = total_errors + 1;
                report_mismatch("Sparse-8", sum_sparse8);
            end
            if (sum_hc !== expected) begin
                han_carlson_error_count = han_carlson_error_count + 1;
                total_errors = total_errors + 1;
                report_mismatch("Han-Carlson", sum_hc);
            end

            if ((sum_rca !== sum_ks) || (sum_rca !== sum_bk) ||
                (sum_rca !== sum_sparse2) || (sum_rca !== sum_sparse4) ||
                (sum_rca !== sum_sparse8) || (sum_rca !== sum_hc)) begin
                consistency_errors = consistency_errors + 1;
                $display("CONSISTENCY_ERROR vector=%0d A=%h B=%h RCA=%h KS=%h BK=%h S2=%h S4=%h S8=%h HC=%h",
                         total_vectors, A, B, sum_rca, sum_ks, sum_bk,
                         sum_sparse2, sum_sparse4, sum_sparse8, sum_hc);
            end
        end
    endtask

    initial begin
        A = 16'h0000; B = 16'h0000;
        seed = 32'h13579bdf;
        directed_count = 0; random_count = 0;
        total_vectors = 0; total_dut_checks = 0; total_errors = 0;
        consistency_errors = 0;
        rca_error_count = 0; kogge_stone_error_count = 0;
        brent_kung_error_count = 0; sparse2_error_count = 0;
        sparse4_error_count = 0; sparse8_error_count = 0;
        han_carlson_error_count = 0;
        negative_mode = $test$plusargs("NEGATIVE_TEST");

        $display("ALL_ADDERS16_TEST_START negative_mode=%0d seed=%h", negative_mode, seed);

        check_case(16'h0000, 16'h0000, 1'b0);
        check_case(16'h0000, 16'hffff, 1'b0);
        check_case(16'hffff, 16'h0000, 1'b0);
        check_case(16'hffff, 16'h0001, 1'b0);
        check_case(16'hffff, 16'hffff, 1'b0);
        check_case(16'h7fff, 16'h0001, 1'b0);
        check_case(16'h8000, 16'h8000, 1'b0);
        check_case(16'h5555, 16'haaaa, 1'b0);
        check_case(16'h1234, 16'h4321, 1'b0);
        check_case(16'h00ff, 16'h0001, 1'b0);
        check_case(16'h0fff, 16'h0001, 1'b0);
        check_case(16'hfffe, 16'h0001, 1'b0);
        $display("DIRECTED_TESTS_COMPLETE count=%0d", directed_count);

        for (random_index = 0; random_index < 10000; random_index = random_index + 1) begin
            A = $random(seed);
            B = $random(seed);
            check_case(A, B, 1'b1);
        end

        $display("RANDOM_TESTS_COMPLETE count=%0d", random_count);
        $display("ALL_ADDERS_COUNTS directed_count=%0d random_count=%0d total_vectors=%0d total_dut_checks=%0d",
                 directed_count, random_count, total_vectors, total_dut_checks);
        $display("DUT_ERRORS RCA=%0d KOGGE_STONE=%0d BRENT_KUNG=%0d SPARSE2=%0d SPARSE4=%0d SPARSE8=%0d HAN_CARLSON=%0d",
                 rca_error_count, kogge_stone_error_count, brent_kung_error_count,
                 sparse2_error_count, sparse4_error_count, sparse8_error_count,
                 han_carlson_error_count);
        $display("ALL_ADDERS_RESULT total_errors=%0d consistency_errors=%0d",
                 total_errors, consistency_errors);
        if ((total_errors == 0) && (consistency_errors == 0))
            $display("ALL_ADDERS16_TEST_PASS");
        else
            $display("ALL_ADDERS16_TEST_FAIL");
        $finish;
    end
endmodule
