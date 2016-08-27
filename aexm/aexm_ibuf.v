module aexm_ibuf (/*AUTOARG*/
   // Outputs
   rIMM, rRA, rRD, rRB, rALT, rOPC, rSIMM, xIREG, fSTALL,
   // Inputs
   rMSR_IE, aexm_icache_datai, sys_int_i, gclk,
   grst, d_en, oena
   );
   // INTERNAL
   output [15:0] rIMM;
   output [4:0]  rRA, rRD, rRB;
   output [10:0] rALT;
   output [5:0]  rOPC;
   output [31:0] rSIMM;
   output [31:0] xIREG;
   output 	 fSTALL;

   input 	 rMSR_IE;

   // INST WISHBONE
   input [31:0]  aexm_icache_datai;

   // SYSTEM
   input 	 sys_int_i;
   input 	 gclk, grst, d_en, oena;

   reg [15:0] 	 rIMM;
   reg [4:0] 	 rRA, rRD;
   reg [5:0] 	 rOPC;

   // FIXME: Endian
   wire [31:0] 	 wIDAT = aexm_icache_datai;
   assign 	 {rRB, rALT} = rIMM;

   reg [31:0] 	rSIMM, xSIMM;
   reg 		rSTALL;

   wire [31:0] 	wXCEOP = 32'hBA2D0008; // Vector 0x08
   wire [31:0] 	wINTOP = 32'hB9CE0010; // Vector 0x10
   wire [31:0] 	wBRKOP = 32'hBA0C0018; // Vector 0x18
   wire [31:0] 	wBRAOP = 32'h88000000; // NOP for branches

   wire [31:0] 	wIREG = {rOPC, rRD, rRA, rRB, rALT};
   reg [31:0] 	xIREG;

   // --- INTERRUPT LATCH --------------------------------------
   // Debounce and latch onto the positive level. This is independent
   // of the pipeline so that stalls do not affect it.

   reg 		rFINT;
   reg [1:0] 	rDINT;
   wire 	wSHOT = rDINT[0];

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rDINT <= 2'h0;
	rFINT <= 1'h0;
	// End of automatics
     end else begin
	if (rMSR_IE)
	  rDINT <= #1
		   {rDINT[0], sys_int_i};

	rFINT <= #1
		 //(wIREG == wINTOP) ? 1'b0 :
		 (rFINT | wSHOT) & rMSR_IE;
     end

   wire 	fIMM = (rOPC == 6'o54);
   wire 	fRTD = (rOPC == 6'o55);
   wire 	fBRU = ((rOPC == 6'o46) | (rOPC == 6'o56));
   wire 	fBCC = ((rOPC == 6'o47) | (rOPC == 6'o57));

   // --- DELAY SLOT -------------------------------------------

   always @(/*AUTOSENSE*/fBCC or fBRU or fIMM or fRTD or rFINT
	    or wIDAT or wINTOP) begin
      xIREG <= (!fIMM & rFINT & !fRTD & !fBRU & !fBCC) ? wINTOP :
	       wIDAT;
   end

   always @(/*AUTOSENSE*/fIMM or rIMM or wIDAT or xIREG) begin
      xSIMM <= (!fIMM) ? { {(16){xIREG[15]}}, xIREG[15:0]} :
	       {rIMM, wIDAT[15:0]};
   end

   // --- PIPELINE --------------------------------------------

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rIMM <= 16'h0;
	rOPC <= 6'h0;
	rRA <= 5'h0;
	rRD <= 5'h0;
	rSIMM <= 32'h0;
	// End of automatics
     end else if (d_en) begin
	{rOPC, rRD, rRA, rIMM} <= #1 xIREG;
	rSIMM <= #1 xSIMM;
     end

   // --- STALL FOR MUL/BSF -----------------------------------

   wire       fMUL = (dOPC == 6'o20) | (dOPC == 6'o30);
   wire       fBSF = (dOPC == 6'o21) | (dOPC == 6'o31);
   wire 	 rLOD = ({rOPC[5:4],rOPC[2]} == 3'o6);
   wire 	 rSTR = ({rOPC[5:4],rOPC[2]} == 3'o7);
  reg 		 rSTALL_prev;
  wire 		 fSTALL;
  assign fSTALL = rSTALL || rSTALL_prev;

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
       rSTALL_prev <= 0;
	rSTALL <= 1'h0;
	// End of automatics
     end else begin
       rSTALL_prev <= rSTALL;
       if (oena)
	 rSTALL <= #1 (!rSTALL & (fMUL | fBSF));
       else
	 rSTALL <= #1 0;
     end

endmodule // aexm_ibuf
