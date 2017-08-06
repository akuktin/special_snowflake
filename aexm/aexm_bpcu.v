module aexm_bpcu (/*AUTOARG*/
   // Outputs
   aexm_icache_precycle_addr, rIPC, rPC, rPCLNK,
   dSKIP, xSKIP,
   // Inputs
   xMXALT, rOPC, rRD, rRA, xRESULT, rDWBDI, xREGA,
   cpu_mode_memop, xIREG, cpu_interrupt,
   gclk, grst, x_en, d_en
   );
   parameter IW = 24;

   // INST WISHBONE
  output [31:0] aexm_icache_precycle_addr;

   // INTERNAL
   output [31:2]   rIPC, rPC, rPCLNK;
  output 	   dSKIP;
  output 	   xSKIP;
   //output [1:0]    rATOM;
   //output [1:0]    xATOM;

   input [1:0] 	   xMXALT;
   input [5:0] 	   rOPC;
   input [4:0] 	   rRD, rRA;
   input [31:0]    xRESULT; // ALU
   input [31:0]    rDWBDI; // RAM
   input [31:0]    xREGA;
  input [31:0] 	   xIREG;
   //input [1:0] 	   rXCE;

  input 	   cpu_mode_memop;
  input 	   cpu_interrupt;

   // SYSTEM
   input 	   gclk, grst, x_en, d_en;

   wire [5:0] 	 wOPC;
   wire [4:0] 	 wRD, wRA, wRB;
   wire [10:0] 	 wALT;

   assign 	 {wOPC, wRD, wRA, wRB, wALT} = xIREG; // FIXME: Endian

   // --- BRANCH CONTROL --------------------------------------------
   // Controls the branch and delay flags

   reg [31:0] 	   wREGA;
  always @(posedge gclk)
    if (grst)
      wREGA <= 0;
    else if (d_en)
      case (xMXALT)
	2'o2: wREGA <= rDWBDI;
	2'o1: wREGA <= xRESULT;
	default: wREGA <= xREGA;
      endcase // case (xMXALT)


  reg 		   careof_equal_n, careof_ltgt, expect_equal, expect_ltgt,
		   xDLY, xBRA, invert_answer, chain_endpoint, rSKIP_n, xSKIP,
		   fSKIP, dSKIP;
  wire 		   reg_equal_null_n, ltgt_true, expect_reg_equal,
		   wBCC, wBRU;

  always @(posedge gclk)
    if (grst || fSKIP) begin
      chain_endpoint <= 1;
      careof_equal_n <= 1;
      careof_ltgt <= 0;
      expect_equal <= 1;
      expect_ltgt <= 0;
      invert_answer <= 0;
      xDLY <= 0;
      if (grst)
	rSKIP_n <= 1;
      else
	rSKIP_n <= 1;
    end else if (d_en) begin
      if (dSKIP) begin
      rSKIP_n <= 0;
      end else begin // if (!dSKIP)
      chain_endpoint <= !(wBRU ||
			  (wBCC &&
			   ((wRD[2:0] == 3'h0) ||
			    (wRD[2:0] == 3'h1) ||
			    (wRD[2:0] == 3'h3) ||
			    // implement gt as an inverted le
			    (wRD[2:0] == 3'h4) ||
			    (wRD[2:0] == 3'h5))));
      careof_equal_n <= !(wBCC &&
			  ((wRD[2:0] == 3'h0) ||
			   (wRD[2:0] == 3'h1) ||
			   (wRD[2:0] == 3'h3) ||
			   // implement gt as an inverted le
			   (wRD[2:0] == 3'h4) ||
			   (wRD[2:0] == 3'h5)));
      careof_ltgt <= wBCC &&
		     ((wRD[2:0] == 3'h2) ||
		      (wRD[2:0] == 3'h3) ||
		      (wRD[2:0] == 3'h4) ||
		      (wRD[2:0] == 3'h5));
      expect_equal <= !wBRU;
      expect_ltgt <= ((wRD[2:0] == 3'h2) ||
		      (wRD[2:0] == 3'h3) ||
		      // implement gt as an inverted le
		      (wRD[2:0] == 3'h4)) ? 1 : 0;
      invert_answer <= wBRU ||
		       (wBCC &&
			((wRD[2:0] == 3'h1) ||
			 // implement gt as an inverted le
			 (wRD[2:0] == 3'h4)));
      rSKIP_n <= (wBRU && wRA[4]) || (wBCC && wRD[4]);

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
	dSKIP <= !rSKIP_n; fSKIP <= !rSKIP_n;
      end
      3'b001: begin
	xBRA <= 1; // BRU       // EXCEPTION!!!
	dSKIP <= !rSKIP_n; fSKIP <= !rSKIP_n;
      end
      3'b010: begin
	xBRA <= 1;
	dSKIP <= !rSKIP_n; fSKIP <= !rSKIP_n;
      end
      3'b011: begin
	xBRA <= 0; // inverted
	dSKIP <= 0; fSKIP <= 0;
      end
      3'b100: begin
	xBRA <= 1;
	dSKIP <= !rSKIP_n; fSKIP <= !rSKIP_n;
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
	dSKIP <= !rSKIP_n; fSKIP <= !rSKIP_n;
      end
    endcase // case ({expect_reg_equal,reg_equal_null_n,invert_answer})

  assign wBCC = ((wOPC == 6'o47) | (wOPC == 6'o57)) && !cpu_interrupt;
  assign wBRU = ((wOPC == 6'o46) | (wOPC == 6'o56)) || cpu_interrupt;

   // --- PC PIPELINE ------------------------------------------------
   // PC and related changes

   reg [31:2] 	   pre_rIPC, rIPC, xIPC;
   reg [31:2] 	   rPC, xPC;
   reg [31:2] 	   rPCLNK, xPCLNK;
  wire [31:2] 	   pc_inc;

   assign          aexm_icache_precycle_addr = xIPC;
  assign pc_inc = {{(29){1'b0}},cpu_mode_memop};

   always @(xBRA or rIPC or rPC or xRESULT or pre_rIPC or pc_inc)
     begin
       xPCLNK <= rPC;
       xPC <= rIPC;

       xIPC <= (xBRA) ? xRESULT[31:2] : (pre_rIPC + pc_inc);
     end

   // --- ATOMIC CONTROL ---------------------------------------------
   // This is used to indicate 'safe' instruction borders.

   wire 	wIMM = (rOPC == 6'o54) & !fSKIP;
   wire 	wRTD = (rOPC == 6'o55) & !fSKIP;
//   wire 	wBCC = xXCC & ((rOPC == 6'o47) | (rOPC == 6'o57)) & !fSKIP;
//   wire 	wBRU = ((rOPC == 6'o46) | (rOPC == 6'o56)) & !fSKIP;

   wire 	fATOM = ~(wIMM | wRTD | wBCC | wBRU);
   reg [1:0] 	rATOM, xATOM;

   always @(/*AUTOSENSE*/fATOM or rATOM)
     xATOM <= {rATOM[0], (rATOM[0] ^ fATOM)};


   // --- SYNC PIPELINE ----------------------------------------------

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rATOM <= 2'h0;
	rIPC <= 30'h0;
        pre_rIPC <= 30'h0;
	rPC <= 30'h0;
	rPCLNK <= 30'h0;
       xSKIP <= 0;
	// End of automatics
     end else if (x_en) begin
	pre_rIPC <= #1 xIPC;
        rIPC <= #1 pre_rIPC;
	rPC <= #1 xPC;
	rPCLNK <= #1 xPCLNK;
	rATOM <= #1 xATOM;
       xSKIP <= #1 dSKIP;
     end

endmodule // aexm_bpcu
