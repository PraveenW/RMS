////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 2000 - 2014 SYNOPSYS INC.
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
// AUTHOR:    Reto Zimmermann		May 10, 2000
//
// VERSION:   Verilog Simulation Architecture
//
// DesignWare_version: 6600f416
// DesignWare_release: I-2013.12-DWBB_201312.5
//
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT:  Verilog Simulation Models for Combinational Square Root
//            - Uses modeling functions from DW_sqrt_function.inc.
//
// MODIFIED:
//
//-----------------------------------------------------------------------------

module DW_sqrt (a, root);

  parameter width   = 8;
  parameter tc_mode = 0;

  input  [width-1 : 0]       a;
  output [(width+1)/2-1 : 0] root;
  
  // include modeling functions
//`include "DW_sqrt_function.inc"

  
 
  initial begin : parameter_check
    integer param_err_flg;

    param_err_flg = 0;
    
    
    if (width < 2) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter width (lower bound: 2)",
	width );
    end
    
    if ( (tc_mode < 0) || (tc_mode > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter tc_mode (legal range: 0 to 1)",
	tc_mode );
    end
  
    if ( param_err_flg == 1) begin
      $display(
        "%m :\n  Simulation aborted due to invalid parameter value(s)");
      $finish;
    end

  end // parameter_check 



  assign root = (tc_mode == 0)? 
		  DWF_sqrt_uns (a) 
                :
		  DWF_sqrt_tc (a);




//--------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 2000 - 2014 SYNOPSYS INC.
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
// AUTHOR:    Reto Zimmermann		May 10, 2000
//
// VERSION:   Verilog Simulation Functions
//
// NOTE:      This is a subentity.
//            This file is for internal use only.
//
// DesignWare_version: fef7d9c0
// DesignWare_release: I-2013.12-DWBB_201312.5
//
////////////////////////////////////////////////////////////////////////////////
//
// ABSTRACT: Verilog Function Descriptions for Combinational Square Root
//
//           Function descriptions for square root computation
//           used for synthesis inference of function calls
//           and for behavioral Verilog simulation.
//
//           The following functions are declared:
//
//           DWF_sqrt_uns (a, b)
//           DWF_sqrt_tc (a, b)
//
// MODIFIED: 
//
//-----------------------------------------------------------------------------

  function [(width+1)/2-1 : 0] DWF_sqrt_uns;
    // Function to compute the unsigned square root
    
    // synopsys map_to_operator SQRT_UNS_OP
    // synopsys return_port_name ROOT

    input [width-1 : 0] A;

    reg [(width+1)/2-1 : 0] ROOT_v;
    reg A_x;
    integer i;

    begin
// synopsys translate_off
      A_x = ^A;
      if (A_x === 1'bx) begin
	ROOT_v = {(width+1)/2{1'bx}};
      end
      else begin
	ROOT_v = {(width+1)/2{1'b0}};
	for (i = (width+1)/2-1; i >= 0; i = i-1) begin
	  ROOT_v[i] = 1'b1;
	  if (ROOT_v*ROOT_v > {1'b0,A})
	    ROOT_v[i] = 1'b0;
	end
      end
      DWF_sqrt_uns = ROOT_v;
// synopsys translate_on
    end
  endfunction // DWF_sqrt_uns

  
  function [(width+1)/2-1 : 0] DWF_sqrt_tc;
    // Function to compute the signed square root
    
    // synopsys map_to_operator SQRT_TC_OP
    // synopsys return_port_name ROOT

    input [width-1 : 0] A;

    reg [(width+1)/2-1 : 0] ROOT_v;
    reg [width-1 : 0] A_v, A_x;
    integer i;

    begin
// synopsys translate_off
      A_x = ^A;
      if (A_x === 1'bx) begin
	ROOT_v = {(width+1)/2{1'bx}};
      end
      else begin
	if (A[width-1] == 1'b1) A_v = ~A + 1'b1;
	else A_v = A;
	ROOT_v = DWF_sqrt_uns (A_v);
      end
      DWF_sqrt_tc = ROOT_v;
// synopsys translate_on
    end
  endfunction // DWF_sqrt_tc

//-----------------------------------------------------------------------------











endmodule

//-----------------------------------------------------------------------------

