module aexm_ctrl (/*AUTOARG*/
   // Outputs
   rMXDST, rMXDST_use_combined, MEMOP_MXDST, xMXSRC, xMXTGT, xMXALT,
   rMXALU, rRW, dSTRLOD, dLOD, aexm_dcache_precycle_we,
   aexm_dcache_force_miss, fSTALL,
   // Inputs
   xSKIP, rIMM, rALT, rOPC, rRD, rRA, rRB, xIREG,
   cpu_interrupt, gclk, d_en, x_en
   );
   // INTERNAL
   output [1:0]  rMXDST, xMXSRC, xMXTGT, xMXALT;
   output [2:0]  rMXALU;
   output [4:0]  rRW;
  output 	 rMXDST_use_combined;
  output 	 fSTALL;
  output 	 MEMOP_MXDST;

  input 	 xSKIP;
   input [15:0]  rIMM;
   input [10:0]  rALT;
   input [5:0] 	 rOPC;
   input [4:0] 	 rRD, rRA, rRB;
   input [31:0]  xIREG;
  input 	 cpu_interrupt;

   // MCU
  output 	 dSTRLOD, dLOD;
   output aexm_dcache_precycle_we;
  output  aexm_dcache_force_miss;

   // SYSTEM
   input 	 gclk, d_en, x_en;

   // --- DECODE INSTRUCTIONS
   // TODO: Simplify

   wire [5:0] 	 wOPC;
   wire [4:0] 	 wRD, wRA, wRB;
   wire [10:0] 	 wALT;

   assign 	 {wOPC, wRD, wRA, wRB, wALT} = xIREG; // FIXME: Endian

  reg fSFT, fLOG, fMUL, fBSF, fDIV, fRTD, fBCC, fBRU, fIMM, fMOV, fLOD,
      fSTR, fLOD_r, fLDST, fPUT, fGET;

   wire 	 wSFT = (wOPC == 6'o44);
   wire 	 wLOG = ({wOPC[5:4],wOPC[2]} == 3'o4);

   wire 	 wMUL = (wOPC == 6'o20) | (wOPC == 6'o30);
   wire 	 wBSF = (wOPC == 6'o21) | (wOPC == 6'o31);
   wire 	 wDIV = (wOPC == 6'o22);

   wire 	 wRTD = (wOPC == 6'o55);
   wire 	 wBCC = ((wOPC == 6'o47) | (wOPC == 6'o57)) &&
		        !cpu_interrupt;
   wire 	 wBRU = ((wOPC == 6'o46) | (wOPC == 6'o56)) ||
		        cpu_interrupt;
   wire 	 wBRA = (wBRU & wRA[3]) || cpu_interrupt;

   wire 	 wIMM = (wOPC == 6'o54);
   wire 	 wMOV = (wOPC == 6'o45);

   wire 	 wLOD = ({wOPC[5:4],wOPC[2]} == 3'o6);
   wire 	 wSTR = ({wOPC[5:4],wOPC[2]} == 3'o7);
  wire 		 wLOD_r = (wOPC == 6'o62);
   wire 	 wLDST = (&wOPC[5:4]);

   wire          wPUT = (wOPC == 6'o33) & wRB[4];
   wire 	 wGET = (wOPC == 6'o33) & !wRB[4];

  assign         fSTALL = wBSF;

   // --- BRANCH SLOT REGISTERS ---------------------------

   reg [1:0] 	 rMXDST, xMXDST;
   reg [4:0] 	 rRW, xRW;

   reg [1:0] 	 xMXSRC;
   reg [1:0] 	 xMXTGT;
   reg [1:0] 	 xMXALT;


   // --- OPERAND SELECTOR ---------------------------------

  reg 		 xRW_valid, rRW_valid;
  wire 		 dRW_valid;

  assign dRW_valid = (!(wBRU || wBCC || wBRA)) && !fSTALL;

   wire 	 wRDWE = |xRW;
   wire		 late_forward_A = (rRW == wRA) && rRW_valid;
   wire		 late_forward_B = (rRW == wRB) && rRW_valid;
   wire 	 wAFWD_M = (xRW == wRA) & (xMXDST == 2'o2) & wRDWE;
   wire 	 wBFWD_M = (xRW == wRB) & (xMXDST == 2'o2) & wRDWE;
   wire 	 wAFWD_R = (xRW == wRA) & (xMXDST == 2'o0) & wRDWE;
   wire 	 wBFWD_R = (xRW == wRB) & (xMXDST == 2'o0) & wRDWE;

   always @(wAFWD_M or wAFWD_R or wBCC or wBFWD_M or wBFWD_R or
	    wBRU or wOPC or late_forward_A or late_forward_B)
     begin
	xMXSRC <= (wBRU | wBCC) ? 2'o3 : // PC
		  (wAFWD_M) ? 2'o2 : // RAM
		  (wAFWD_R) ? 2'o1 : // FWD
		  (late_forward_A) ? 2'o2 :
		  2'o0; // REG
	xMXTGT <= (wOPC[3]) ? 2'o3 : // IMM
		  (wBFWD_M) ? 2'o2 : // RAM
		  (wBFWD_R) ? 2'o1 : // FWD
		  (late_forward_B) ? 2'o2 :
		  2'o0; // REG
	xMXALT <= (wAFWD_M) ? 2'o2 : // RAM
		  (wAFWD_R) ? 2'o1 : // FWD
		  (late_forward_A) ? 2'o2 :
		  2'o0; // REG
     end

   // --- ALU CONTROL ---------------------------------------

   reg [2:0]     rMXALU, xMXALU;

   always @(/*AUTOSENSE*/wBRA or wBSF or wDIV or wLOG or wMOV
	    or wMUL or wSFT)
     begin
	xMXALU <= (wBRA | wMOV) ? 3'o3 :
		  (wSFT) ? 3'o2 :
		  (wLOG) ? 3'o1 :
		  (wMUL) ? 3'o4 :
		  (wBSF) ? 3'o5 :
		  (wDIV) ? 3'o6 :
		  3'o0;
     end

   // --- DELAY SLOT REGISTERS ------------------------------

  reg  rMXDST_use_combined;
  wire MEMOP_MXDST;

   always @(fBCC or fBRU or fGET or fLOD or fRTD or xSKIP
	    or fSTR or rRD)
     if (xSKIP) begin
	xMXDST <= 2'h0;
	xRW <= 5'h0;
     end else begin
	xMXDST <= (fSTR | fRTD | fBCC) ? 2'o3 :
		  (fLOD | fGET) ? 2'o2 :
		  (fBRU) ? 2'o1 :
		  2'o0;
	xRW <= rRD;
     end

  assign MEMOP_MXDST = (fLOD | fGET) && !xSKIP;

   // --- DATA MEMORY INTERFACE ----------------------------------

  assign dSTRLOD = wLOD || wSTR;
  assign dLOD = wLOD;

  assign aexm_dcache_precycle_we = fSTR;
  assign aexm_dcache_force_miss  = fLOD_r && (rALT[0]);

   // --- PIPELINE CONTROL DELAY ----------------------------

  initial
    begin
      rMXALU = 3'h0; rMXDST = 2'h0; rRW = 5'h0;
      xRW_valid = 0; rRW_valid = 0; rMXDST_use_combined = 0;

      fSFT = 0; fLOG = 0; fMUL = 0; fBSF = 0; fDIV = 0; fRTD = 0;
      fBCC = 0; fBRU = 0; fIMM = 0; fMOV = 0; fLOD = 0; fSTR = 0;
      fLOD_r = 0; fLDST = 0; fPUT = 0; fGET = 0;
    end

   always @(posedge gclk)
     if (d_en) begin
	rMXDST <= xMXDST;
	rMXALU <= xMXALU;
	rRW <= xRW;
	xRW_valid <= dRW_valid;
	rRW_valid <= xRW_valid && !xSKIP;

       fSFT <= wSFT; fLOG <= wLOG; fMUL <= wMUL; fBSF <= wBSF;
       fDIV <= wDIV; fRTD <= wRTD; fBCC <= wBCC; fBRU <= wBRU;
       fIMM <= wIMM; fMOV <= wMOV; fLOD <= wLOD; fSTR <= wSTR;
       fLOD_r <= wLOD_r; fLDST <= wLDST; fPUT <= wPUT; fGET <= wGET;

       rMXDST_use_combined <= (xMXDST != 2'h0);
     end


endmodule // aexm_ctrl
