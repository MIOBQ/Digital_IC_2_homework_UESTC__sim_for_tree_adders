`timescale 1ns/1ps
module tb_han_carlson16;
 reg[15:0] A,B; wire[16:0] SUM; reg[16:0] expected;
 integer seed,test_count,error_count,random_index;
 han_carlson16 dut(.A(A),.B(B),.SUM(SUM));
 task check_case; input[15:0] test_a,test_b; begin
  A=test_a; B=test_b; expected={1'b0,test_a}+{1'b0,test_b}; #1;
  test_count=test_count+1;
  if(SUM!==expected) begin error_count=error_count+1;
   $display("ERROR test=%0d A=%h B=%h expected=%h actual=%h",test_count,test_a,test_b,expected,SUM); end
 end endtask
 initial begin
  A=0;B=0;seed=32'h13579bdf;test_count=0;error_count=0;
  $display("HAN_CARLSON16_TEST_START");
  check_case(16'h0000,16'h0000); check_case(16'h0000,16'hffff);
  check_case(16'hffff,16'h0000); check_case(16'hffff,16'h0001);
  check_case(16'hffff,16'hffff); check_case(16'h7fff,16'h0001);
  check_case(16'h8000,16'h8000); check_case(16'h5555,16'haaaa);
  check_case(16'h1234,16'h4321); check_case(16'h00ff,16'h0001);
  check_case(16'h0fff,16'h0001); check_case(16'hfffe,16'h0001);
  $display("DIRECTED_TESTS_COMPLETE count=%0d errors=%0d",test_count,error_count);
  for(random_index=0;random_index<10000;random_index=random_index+1) begin
   A=$random(seed);B=$random(seed);check_case(A,B);end
  $display("RANDOM_TESTS_COMPLETE count=10000");
  $display("HAN_CARLSON16_TEST_SUMMARY total=%0d errors=%0d",test_count,error_count);
  if(error_count==0)$display("HAN_CARLSON16_TEST_PASS");else $display("HAN_CARLSON16_TEST_FAIL");
  $finish;
 end
endmodule
