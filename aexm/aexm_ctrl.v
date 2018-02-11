module aexm_ctrl (
   // Outputs
   rMXDST, rMXDST_use_combined, MEMOP_MXDST, dMXSRC, dMXTGT, dMXALT,
   xMXALU, rRW, rRDWE, dSTRLOD, dLOD, aexm_dcache_precycle_we,
   aexm_dcache_force_miss, fSTALL, late_forward_D,
   // Inputs
   xSKIP, xALT, xRD, dINST, gclk, d_en, x_en
   );
   // INTERNAL
   output [1:0]  rMXDST, dMXSRC, dMXTGT, dMXALT;
   output [2:0]  xMXALU;
   output [4:0]  rRW;
  output 	 rRDWE;
  output 	 rMXDST_use_combined;
  output 	 fSTALL;
  output 	 MEMOP_MXDST;
  output 	 late_forward_D;

  input 	 xSKIP;
   input [10:0]  xALT;
   input [4:0] 	 xRD;
   input [31:0]  dINST;

   // MCU
  output 	 dSTRLOD, dLOD;
   output aexm_dcache_precycle_we;
  output  aexm_dcache_force_miss;

   // SYSTEM
   input 	 gclk, d_en, x_en;

   // --- DECODE INSTRUCTIONS
   // TODO: Simplify

   wire [5:0] 	 dOPC;
   wire [4:0] 	 dRD, dRA, dRB;
   wire [10:0] 	 dALT;

   assign 	 {dOPC, dRD, dRA, dRB, dALT} = dINST;

  reg xSFT = 1'b0, xLOG = 1'b0, xBSF = 1'b0,
      xRTD = 1'b0, xBCC = 1'b0, xBRU = 1'b0, xIMM = 1'b0, xMOV = 1'b0,
      xLOD = 1'b0, xSTR = 1'b0, xLOD_r = 1'b0;

   wire 	 dSFT = (dOPC == 6'o44);
   wire 	 dLOG = ({dOPC[5:4],dOPC[2]} == 3'o4);

   wire 	 dBSF = (dOPC == 6'o21) | (dOPC == 6'o31);

   wire 	 dRTD = (dOPC == 6'o55);
   wire 	 dBCC = ((dOPC == 6'o47) | (dOPC == 6'o57));
   wire 	 dBRU = ((dOPC == 6'o46) | (dOPC == 6'o56));
   wire 	 dBRA = (dBRU & dRA[3]);

   wire 	 dIMM = (dOPC == 6'o54);
   wire 	 dMOV = (dOPC == 6'o45);

   wire 	 dLOD = ({dOPC[5:4],dOPC[2]} == 3'o6);
   wire 	 dSTR = ({dOPC[5:4],dOPC[2]} == 3'o7);
  wire 		 dLOD_r = (dOPC == 6'o62);

  assign         fSTALL = dBSF;

   // --- BRANCH SLOT REGISTERS ---------------------------

   reg [1:0] 	 rMXDST = 2'h0, xMXDST;
   reg [4:0] 	 rRW = 5'h0, xRW;

   reg [1:0] 	 dMXSRC;
   reg [1:0] 	 dMXTGT;
   reg [1:0] 	 dMXALT;


   // --- OPERAND SELECTOR ---------------------------------

  reg 		 xRW_valid = 1'b0, rRW_valid = 1'b0;
  wire 		 dRW_valid;

  assign dRW_valid = (!(dBRU || dBCC || dBRA || dSTR)) && !fSTALL;

  reg 		 rRDWE = 1'b0;
   wire 	 xRDWE = |xRW; // this can be a redister, using dRW instead
   wire		 late_forward_A = (rRW == dRA) && rRW_valid;
   wire		 late_forward_B = (rRW == dRB) && rRW_valid;
   wire		 late_forward_D = (rRW == dRD) && rRW_valid;
   wire 	 wAFWD_M = (xRW == dRA) & (xMXDST == 2'o2) & xRDWE;
   wire 	 wBFWD_M = (xRW == dRB) & (xMXDST == 2'o2) & xRDWE;
   wire 	 wAFWD_R = (xRW == dRA) & (xMXDST == 2'o0) & xRDWE;
   wire 	 wBFWD_R = (xRW == dRB) & (xMXDST == 2'o0) & xRDWE;

   always @(wAFWD_M or wAFWD_R or dBCC or wBFWD_M or wBFWD_R or
	    dBRU or dOPC or late_forward_A or late_forward_B)
     begin
	dMXSRC <= (dBRU | dBCC) ? 2'o3 : // PC
		  (wAFWD_M) ? 2'o2 : // RAM
		  (wAFWD_R) ? 2'o1 : // FWD
		  (late_forward_A) ? 2'o2 :
		  2'o0; // REG
	dMXTGT <= (dOPC[3]) ? 2'o3 : // IMM
		  (wBFWD_M) ? 2'o2 : // RAM
		  (wBFWD_R) ? 2'o1 : // FWD
		  (late_forward_B) ? 2'o2 :
		  2'o0; // REG
	dMXALT <= (wAFWD_M) ? 2'o2 : // RAM
		  (wAFWD_R) ? 2'o1 : // FWD
		  (late_forward_A) ? 2'o2 :
		  2'o0; // REG
     end

   // --- ALU CONTROL ---------------------------------------

   reg [2:0]     xMXALU = 3'h0, dMXALU;

   always @(dBRA or dBSF or dLOG or dMOV or dSFT)
     begin
	dMXALU <= (dBRA | dMOV) ? 3'o3 :
		  (dSFT) ? 3'o2 :
		  (dLOG) ? 3'o1 :
		  (dBSF) ? 3'o5 :
		  3'o0;
     end

   // --- DELAY SLOT REGISTERS ------------------------------

  reg  rMXDST_use_combined = 1'b0;
  wire MEMOP_MXDST;

   always @(xBCC or xBRU or xLOD or xRTD or xSKIP
	    or xSTR or xRD)
     if (xSKIP) begin
	xMXDST <= 2'h0;
	xRW <= 5'h0;
     end else begin
	xMXDST <= (xSTR | xRTD | xBCC) ? 2'o3 :
		  (xLOD) ? 2'o2 :
		  (xBRU) ? 2'o1 :
		  2'o0;
	xRW <= xRD;
     end

  assign MEMOP_MXDST = xLOD && !xSKIP;

   // --- DATA MEMORY INTERFACE ----------------------------------

  assign dSTRLOD = dLOD || dSTR;

  assign aexm_dcache_precycle_we = xSTR;
  assign aexm_dcache_force_miss  = xLOD_r && (xALT[0]);

   // --- PIPELINE CONTROL DELAY ----------------------------

   always @(posedge gclk)
     if (d_en) begin
       rMXDST <= xMXDST; xMXALU <= dMXALU;
       rRW <= xRW; rRDWE <= xRDWE;
       xRW_valid <= dRW_valid;
       rRW_valid <= xRW_valid && xRDWE && !xSKIP;

       xSFT <= dSFT; xLOG <= dLOG; xBSF <= dBSF;
       xRTD <= dRTD; xBCC <= dBCC; xBRU <= dBRU;
       xIMM <= dIMM; xMOV <= dMOV; xLOD <= dLOD; xSTR <= dSTR;
       xLOD_r <= dLOD_r;

       rMXDST_use_combined <= (xMXDST != 2'h0);
     end


endmodule // aexm_ctrl
