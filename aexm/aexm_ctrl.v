module aexm_ctrl (/*AUTOARG*/
   // Outputs
   rMXDST, rMXSRC, rMXTGT, rMXALT, rMXALU, rRW, dSTRLOD, dLOD,
   aexm_dcache_precycle_we, aexm_dcache_force_miss,
   // Inputs
   rSKIP, rIMM, rALT, rOPC, rRD, rRA, rRB, xIREG,
   gclk, grst, d_en, x_en
   );
   // INTERNAL
   output [1:0]  rMXDST;
   output [1:0]  rMXSRC, rMXTGT, rMXALT;
   output [2:0]  rMXALU;
   output [4:0]  rRW;

  input 	 rSKIP;
   input [15:0]  rIMM;
   input [10:0]  rALT;
   input [5:0] 	 rOPC;
   input [4:0] 	 rRD, rRA, rRB;
   input [31:0]  xIREG;

   // MCU
  output 	 dSTRLOD, dLOD;
   output aexm_dcache_precycle_we;
  output  aexm_dcache_force_miss;

   // SYSTEM
   input 	 gclk, grst, d_en, x_en;

   // --- DECODE INSTRUCTIONS
   // TODO: Simplify

   wire [5:0] 	 wOPC;
   wire [4:0] 	 wRD, wRA, wRB;
   wire [10:0] 	 wALT;

   assign 	 {wOPC, wRD, wRA, wRB, wALT} = xIREG; // FIXME: Endian

   wire 	 fSFT = (rOPC == 6'o44);
   wire 	 fLOG = ({rOPC[5:4],rOPC[2]} == 3'o4);

   wire 	 fMUL = (rOPC == 6'o20) | (rOPC == 6'o30);
   wire 	 fBSF = (rOPC == 6'o21) | (rOPC == 6'o31);
   wire 	 fDIV = (rOPC == 6'o22);

   wire 	 fRTD = (rOPC == 6'o55);
   wire 	 fBCC = (rOPC == 6'o47) | (rOPC == 6'o57);
   wire 	 fBRU = (rOPC == 6'o46) | (rOPC == 6'o56);

   wire 	 fIMM = (rOPC == 6'o54);
   wire 	 fMOV = (rOPC == 6'o45);

   wire 	 fLOD = ({rOPC[5:4],rOPC[2]} == 3'o6);
   wire 	 fSTR = ({rOPC[5:4],rOPC[2]} == 3'o7);
  wire 		 fLOD_r = (rOPC == 6'o62);
   wire 	 fLDST = (&rOPC[5:4]);

   wire          fPUT = (rOPC == 6'o33) & rRB[4];
   wire 	 fGET = (rOPC == 6'o33) & !rRB[4];


   wire 	 wSFT = (wOPC == 6'o44);
   wire 	 wLOG = ({wOPC[5:4],wOPC[2]} == 3'o4);

   wire 	 wMUL = (wOPC == 6'o20) | (wOPC == 6'o30);
   wire 	 wBSF = (wOPC == 6'o21) | (wOPC == 6'o31);
   wire 	 wDIV = (wOPC == 6'o22);

   wire 	 wBCC = (wOPC == 6'o47) | (wOPC == 6'o57);
   wire 	 wBRU = (wOPC == 6'o46) | (wOPC == 6'o56);
   wire 	 wBRA = wBRU & wRA[3];

   wire 	 wIMM = (wOPC == 6'o54);
   wire 	 wMOV = (wOPC == 6'o45);

   wire 	 wLOD = ({wOPC[5:4],wOPC[2]} == 3'o6);
   wire 	 wSTR = ({wOPC[5:4],wOPC[2]} == 3'o7);
   wire 	 wLDST = (&wOPC[5:4]);

   wire          wPUT = (wOPC == 6'o33) & wRB[4];
   wire 	 wGET = (wOPC == 6'o33) & !wRB[4];

   // --- BRANCH SLOT REGISTERS ---------------------------

   reg [1:0] 	 rMXDST, xMXDST;
   reg [4:0] 	 rRW, xRW;

   reg [1:0] 	 rMXSRC, xMXSRC;
   reg [1:0] 	 rMXTGT, xMXTGT;
   reg [1:0] 	 rMXALT, xMXALT;


   // --- OPERAND SELECTOR ---------------------------------

   wire 	 wRDWE = |xRW;
   wire 	 wAFWD_M = (xRW == wRA) & (xMXDST == 2'o2) & wRDWE;
   wire 	 wBFWD_M = (xRW == wRB) & (xMXDST == 2'o2) & wRDWE;
   wire 	 wAFWD_R = (xRW == wRA) & (xMXDST == 2'o0) & wRDWE;
   wire 	 wBFWD_R = (xRW == wRB) & (xMXDST == 2'o0) & wRDWE;

   always @(/*AUTOSENSE*/wAFWD_M or wAFWD_R or wBCC or wBFWD_M
	    or wBFWD_R or wBRU or wOPC)
     begin
	xMXSRC <= (wBRU | wBCC) ? 2'o3 : // PC
		  (wAFWD_M) ? 2'o2 : // RAM
		  (wAFWD_R) ? 2'o1 : // FWD
		  2'o0; // REG
	xMXTGT <= (wOPC[3]) ? 2'o3 : // IMM
		  (wBFWD_M) ? 2'o2 : // RAM
		  (wBFWD_R) ? 2'o1 : // FWD
		  2'o0; // REG
	xMXALT <= (wAFWD_M) ? 2'o2 : // RAM
		  (wAFWD_R) ? 2'o1 : // FWD
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

   always @(/*AUTOSENSE*/fBCC or fBRU or fGET or fLOD or fRTD or rSKIP
	    or fSTR or rRD)
     if (rSKIP) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xMXDST <= 2'h0;
	xRW <= 5'h0;
	// End of automatics
     end else begin
	xMXDST <= (fSTR | fRTD | fBCC) ? 2'o3 :
		  (fLOD | fGET) ? 2'o2 :
		  (fBRU) ? 2'o1 :
		  2'o0;
	xRW <= rRD;
     end // else: !if(fSKIP)


   // --- DATA MEMORY INTERFACE ----------------------------------

  assign dSTRLOD = wLOD || wSTR;
  assign dLOD = wLOD;

  assign aexm_dcache_precycle_we = fSTR;
  assign aexm_dcache_force_miss  = fLOD_r && (rALT[0]);

   // --- PIPELINE CONTROL DELAY ----------------------------

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMXALT <= 2'h0;
	rMXALU <= 3'h0;
	rMXDST <= 2'h0;
	rMXSRC <= 2'h0;
	rMXTGT <= 2'h0;
	rRW <= 5'h0;
	// End of automatics
     end else if (d_en) begin // if (grst)
	rMXDST <= #1 xMXDST;
	rRW <= #1 xRW;
	rMXSRC <= #1 xMXSRC;
	rMXTGT <= #1 xMXTGT;
	rMXALT <= #1 xMXALT;
	rMXALU <= #1 xMXALU;
     end


endmodule // aexm_ctrl
