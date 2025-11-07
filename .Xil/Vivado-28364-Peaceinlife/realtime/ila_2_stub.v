// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2018.3" *)
module ila_2(clk, probe0, probe1, probe2, probe3, probe4, probe5);
  input clk;
  input [0:0]probe0;
  input [7:0]probe1;
  input [10:0]probe2;
  input [0:0]probe3;
  input [0:0]probe4;
  input [0:0]probe5;
endmodule
