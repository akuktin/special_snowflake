module aexm_bpcu (/*AUTOARG*/
   // Outputs
   aexm_icache_precycle_addr, rPC, rPCLNK,
   dSKIP, xSKIP,
   // Inputs
   rMXALT, rOPC, rRD, rRA, xRESULT, rRESULT, rDWBDI, rREGA,
   cpu_mode_memop, xIREG,
   gclk, grst, x_en, d_en
   );
   parameter IW = 24;

   // INST WISHBONE
  output [31:0] aexm_icache_precycle_addr;

   // INTERNAL
   output [31:2]   rPC, rPCLNK;
  output 	   dSKIP;
  output 	   xSKIP;
   //output [1:0]    rATOM;
   //output [1:0]    xATOM;

   input [1:0] 	   rMXALT;
   input [5:0] 	   rOPC;
   input [4:0] 	   rRD, rRA;
   input [31:0]    xRESULT; // ALU
   input [31:0]    rRESULT; // ALU
   input [31:0]    rDWBDI; // RAM
   input [31:0]    rREGA;
  input [31:0] 	   xIREG;
   //input [1:0] 	   rXCE;

  input 	   cpu_mode_memop;

   // SYSTEM
   input 	   gclk, grst, x_en, d_en;

   wire [5:0] 	 wOPC;
   wire [4:0] 	 wRD, wRA, wRB;
   wire [10:0] 	 wALT;

   assign 	 {wOPC, wRD, wRA, wRB, wALT} = xIREG; // FIXME: Endian

   // --- BRANCH CONTROL --------------------------------------------
   // Controls the branch and delay flags

   wire [31:0] 	   wREGA; // a thorn in my side
   assign 	   wREGA = (rMXALT == 2'o2) ? rDWBDI :
			   (rMXALT == 2'o1) ? rRESULT :
			   rREGA;


  reg 		   careof_equal_n, careof_ltgt, expect_equal, expect_ltgt,
		   xDLY;
  wire 		   reg_equal_null_n, ltgt_true, expect_reg_equal, xBRA,
		   wBCC, wBRU;

  always @(posedge gclk)
    if (grst) begin
      careof_equal_n <= 1;
      careof_ltgt <= 1;
      expect_equal <= 0;
      expect_ltgt <= 0;
      xDLY <= 0;
    end else if (d_en) begin
      careof_equal_n <= !(wBCC &&
			  ((wRD[2:0] == 3'h0) ||
			   (wRD[2:0] == 3'h1) ||
			   (wRD[2:0] == 3'h3) ||
			   (wRD[2:0] == 3'h5)));
      careof_ltgt <= wBCC &&
		     ((wRD[2:0] == 3'h2) ||
		      (wRD[2:0] == 3'h3) ||
		      (wRD[2:0] == 3'h4) ||
		      (wRD[2:0] == 3'h5));
      expect_equal <= !wBRU;
      expect_ltgt <= ((wRD[2:0] == 3'h2) ||
		      (wRD[2:0] == 3'h3)) ? 1 : 0;
      xDLY <= (wBRU && wRA[4]) || (wBCC && wRD[4]);

      $display("ere %x ren_ %x ce_ %x cl %x lt %x ee %x wRA %x xIREG %x",
	       expect_reg_equal, reg_equal_null_n, careof_equal_n,
	       careof_ltgt, ltgt_true, expect_equal, wREGA, xIREG);
      $display("xBRA %x !xDLY %x", xBRA, !xDLY);
    end // if (d_en)

  // careof_equal_n asserted: only the mixin is 1, producing the real
  //   result
  // careof_equal_n deasserted: both the mixin and the terminal inject
  //   are 1, the result is guarrantied to be 1
  assign reg_equal_null_n = ((wREGA ^ 32'd0) == 0) ? careof_equal_n : 1;

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

  assign xBRA = expect_reg_equal ? !reg_equal_null_n : 1;

  assign wBCC = (wOPC == 6'o47) | (wOPC == 6'o57);
  assign wBRU = (wOPC == 6'o46) | (wOPC == 6'o56);

  wire 		   fSKIP, dSKIP;
  reg 		   rSKIP, xSKIP;

  assign fSKIP = (xBRA && !xDLY);
  assign dSKIP = fSKIP || rSKIP;

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
       rSKIP <= 0;
       xSKIP <= 0;
	// End of automatics
     end else if (x_en) begin
	pre_rIPC <= #1 xIPC;
        rIPC <= #1 pre_rIPC;
	rPC <= #1 xPC;
	rPCLNK <= #1 xPCLNK;
	rATOM <= #1 xATOM;
       rSKIP <= #1 fSKIP;
       xSKIP <= #1 dSKIP;
     end

endmodule // aexm_bpcu
