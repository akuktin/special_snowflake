module aexm_bpcu (
   // Outputs
   aexm_icache_precycle_addr, rIPC, rPC,
   dSKIP, xSKIP,
   // Inputs
   dMXALT, xRESULT, c_io_rg, xREGA,
   cpu_mode_memop, dINST, gclk, x_en, d_en
   );
   parameter IW = 24;

   // INST WISHBONE
  output [31:0] aexm_icache_precycle_addr;

   // INTERNAL
   output [31:2]   rIPC, rPC;
  output 	   dSKIP;
  output 	   xSKIP;
   //output [1:0]    rATOM;
   //output [1:0]    xATOM;

   input [1:0] 	   dMXALT;
   input [31:0]    xRESULT; // ALU
   input [31:0]    c_io_rg;
   input [31:0]    xREGA;
  input [31:0] 	   dINST;
   //input [1:0] 	   rXCE;

  input 	   cpu_mode_memop;

   // SYSTEM
   input 	   gclk, x_en, d_en;

   wire [5:0] 	 dOPC;
   wire [4:0] 	 dRD, dRA, dRB;
   wire [10:0] 	 dALT;

   assign 	 {dOPC, dRD, dRA, dRB, dALT} = dINST;

   // --- BRANCH CONTROL --------------------------------------------
   // Controls the branch and delay flags

   reg [31:0] 	   wREGA = 32'd0;

  always @(posedge gclk)
    if (d_en)
      case (dMXALT)
	2'o2: wREGA <= c_io_rg;
	2'o1: wREGA <= xRESULT;
	default: wREGA <= xREGA;
      endcase // case (dMXALT)


  reg 		   chain_endpoint = 1'b1, careof_equal_n = 1'b1,
		   careof_ltgt = 1'b0, expect_equal = 1'b1,
		   expect_ltgt = 1'b0, invert_answer = 1'b0,
		   rSKIP_n = 1'b1,

		   xSKIP = 1'b0, xBRA, fSKIP, dSKIP;
  wire 		   reg_equal_null_n, ltgt_true, expect_reg_equal,
		   dBCC, dBRU;

  always @(posedge gclk)
    if (fSKIP) begin
      // MAKE SURE THIS IS IDENTICAL TO THE REGISTER INITIAL VALUES!
      chain_endpoint <= 1;
      careof_equal_n <= 1;
      careof_ltgt <= 0;
      expect_equal <= 1;
      expect_ltgt <= 0;
      invert_answer <= 0;
      rSKIP_n <= 1;
    end else if (d_en) begin
      if (dSKIP) begin
      rSKIP_n <= 0;
      end else begin // if (!dSKIP)
      chain_endpoint <= !(dBRU ||
			  (dBCC &&
			   ((dRD[2:0] == 3'h0) ||
			    (dRD[2:0] == 3'h1) ||
			    (dRD[2:0] == 3'h3) ||
			    // implement gt as an inverted le
			    (dRD[2:0] == 3'h4) ||
			    (dRD[2:0] == 3'h5))));
      careof_equal_n <= !(dBCC &&
			  ((dRD[2:0] == 3'h0) ||
			   (dRD[2:0] == 3'h1) ||
			   (dRD[2:0] == 3'h3) ||
			   // implement gt as an inverted le
			   (dRD[2:0] == 3'h4) ||
			   (dRD[2:0] == 3'h5)));
      careof_ltgt <= dBCC &&
		     ((dRD[2:0] == 3'h2) ||
		      (dRD[2:0] == 3'h3) ||
		      (dRD[2:0] == 3'h4) ||
		      (dRD[2:0] == 3'h5));
      expect_equal <= !dBRU;
      expect_ltgt <= ((dRD[2:0] == 3'h2) ||
		      (dRD[2:0] == 3'h3) ||
		      // implement gt as an inverted le
		      (dRD[2:0] == 3'h4)) ? 1 : 0;
      invert_answer <= dBRU ||
		       (dBCC &&
			((dRD[2:0] == 3'h1) ||
			 // implement gt as an inverted le
			 (dRD[2:0] == 3'h4)));
      rSKIP_n <= ((dBRU && dRA[4]) || (dBCC && dRD[4]));

      end // else: !if(dSKIP)
    end // if (d_en)

  // previous comment:
  // careof_equal_n asserted: only the mixin is 1, producing the real
  //   result
  // careof_equal_n deasserted: both the mixin and the terminal inject
  //   are 1, the result is guarrantied to be 1

  // current comment:
  // expect_equal is supposed to be wired to the mixin of the carry chain.
  // Therefore, if it is 1, as it almost always is, the chain operates
  // normally. The only exception is if br[i] (branch unconditional) comes
  // up. In that case, both the mixin and the endpoint are set to 0,
  // guarranteing the carry chain will output 0, enabling xBRA to be
  // properly set and enabling the signalling of fSKIP/dSKIP.
  assign reg_equal_null_n = expect_equal ?
			    (((wREGA ^ 32'd0) == 0) ? chain_endpoint : 1) :
			    0;

  assign ltgt_true = careof_ltgt && (expect_ltgt == wREGA[31]);

  assign expect_reg_equal = careof_equal_n ?
			    (careof_ltgt ?
			     !ltgt_true :
			     expect_equal) :
			    (careof_ltgt ?
			     (ltgt_true ?
			      0 :
			      expect_equal) :
			     expect_equal);

  always @(expect_reg_equal or reg_equal_null_n or invert_answer or
	   rSKIP_n)
    case ({expect_reg_equal,reg_equal_null_n,invert_answer})
      3'b000: begin
	xBRA <= 1;
	dSKIP <= !rSKIP_n; fSKIP <= 1;
      end
      3'b001: begin
	xBRA <= 1; // BRU       // EXCEPTION!!!
	dSKIP <= !rSKIP_n; fSKIP <= 1;
      end
      3'b010: begin
	xBRA <= 1;
	dSKIP <= !rSKIP_n; fSKIP <= 1;
      end
      3'b011: begin
	xBRA <= 0; // inverted
	dSKIP <= 0; fSKIP <= 0;
      end
      3'b100: begin
	xBRA <= 1;
	dSKIP <= !rSKIP_n; fSKIP <= 1;
      end
      3'b101: begin
	xBRA <= 0; // inverted
	dSKIP <= 0; fSKIP <= 0;
      end
      3'b110: begin
	xBRA <= 0; // no-branch hits here
	dSKIP <= rSKIP_n; fSKIP <= 0; // EXCEPTION!!! EXCEPTION!!!
      end
      3'b111: begin
	xBRA <= 1; // inverted
	dSKIP <= !rSKIP_n; fSKIP <= 1;
      end
    endcase // case ({expect_reg_equal,reg_equal_null_n,invert_answer})

  assign dBCC = ((dOPC == 6'o47) | (dOPC == 6'o57));
  assign dBRU = ((dOPC == 6'o46) | (dOPC == 6'o56));

   // --- PC PIPELINE ------------------------------------------------
   // PC and related changes

   reg [31:2] 	   pre_rIPC = 30'h0, rIPC = 30'h0, xIPC;
   reg [31:2] 	   rPC = 30'h0, xPC;
  wire [31:2] 	   pc_inc;

   assign          aexm_icache_precycle_addr = xIPC;
  assign pc_inc = {{(29){1'b0}},cpu_mode_memop};

   always @(xBRA or rIPC or rPC or xRESULT or pre_rIPC or pc_inc)
     begin
       xPC <= rIPC;

       xIPC <= (xBRA) ? xRESULT[31:2] : (pre_rIPC + pc_inc);
     end
/*
   // --- ATOMIC CONTROL ---------------------------------------------
   // This is used to indicate 'safe' instruction borders.

   wire 	wIMM = (xOPC == 6'o54) & !fSKIP;
   wire 	wRTD = (xOPC == 6'o55) & !fSKIP;
//   wire 	dBCC = xXCC & ((xOPC == 6'o47) | (xOPC == 6'o57)) & !fSKIP;
//   wire 	dBRU = ((xOPC == 6'o46) | (xOPC == 6'o56)) & !fSKIP;

   wire 	fATOM = ~(wIMM | wRTD | dBCC | dBRU);
   reg [1:0] 	rATOM = 2'h0, xATOM;

   always @(fATOM or rATOM)
     xATOM <= {rATOM[0], (rATOM[0] ^ fATOM)};
*/

   // --- SYNC PIPELINE ----------------------------------------------

   always @(posedge gclk)
     if (x_en) begin
	pre_rIPC <= xIPC;
        rIPC <= pre_rIPC;
	rPC <= xPC;
//	rATOM <= xATOM;
       xSKIP <= dSKIP;
     end

endmodule // aexm_bpcu
