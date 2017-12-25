module aexm_ibuf (/*AUTOARG*/
   // Outputs
   rIMM, rRA, rRD, rRB, rALT, rOPC, xOPC, xSIMM, xIREG,
   regf_rRA, regf_rRB, regf_rRD, cpu_interrupt,
   // Inputs
   rMSR_IE, aexm_icache_datai, sys_int_i, gclk,
   grst, d_en, oena
   );
   // INTERNAL
   output [15:0] rIMM;
   output [4:0]  rRA, rRD, rRB, regf_rRA, regf_rRB, regf_rRD;
   output [10:0] rALT;
   output [5:0]  rOPC, xOPC;
   output [31:0] xSIMM;
   output [31:0] xIREG;
  output 	 cpu_interrupt;

   input 	 rMSR_IE;

   // INST WISHBONE
   input [31:0]  aexm_icache_datai;

   // SYSTEM
   input 	 sys_int_i;
   input 	 gclk, grst, d_en, oena;

  wire [5:0] xOPC;
  assign xOPC = xIREG[31:26];

   reg [15:0] 	 rIMM;
   reg [4:0] 	 rRA, rRD;
   reg [5:0] 	 rOPC;

   // FIXME: Endian
   wire [31:0] 	 wIDAT = aexm_icache_datai;
   assign 	 {rRB, rALT} = rIMM;

   reg [31:0] 	rSIMM, xSIMM;

   wire [31:0] 	wXCEOP = 32'hBA2D0008; // Vector 0x08
   wire [31:0] 	wINTOP = {6'o56,5'h1e,5'h0c,16'h0060}; // register to be
                                                       // changed to 5'h00
   wire [31:0] 	wBRKOP = 32'hBA0C0018; // Vector 0x18
   wire [31:0] 	wBRAOP = 32'h88000000; // NOP for branches
  reg 		issued_interrupt, cpu_interrupt;

   wire [31:0] 	wIREG = {rOPC, rRD, rRA, rRB, rALT};
  wire [31:0] 	xIREG;
  reg [31:0] 	xNXTINST;
  assign xIREG = wIDAT;

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

	rFINT <= #1 // still needs some work
		 issued_interrupt ? 1'b0 :
		 (rFINT | wSHOT) & rMSR_IE;
     end

   wire 	fIMM = (rOPC == 6'o54);
   wire 	wIMM = (xOPC == 6'o54);
   wire 	wRTD = (xOPC == 6'o55);
   wire 	wBRU = ((xOPC == 6'o46) | (xOPC == 6'o56));
   wire 	wBCC = ((xOPC == 6'o47) | (xOPC == 6'o57));

   // --- DELAY SLOT -------------------------------------------

  assign do_interrupt = (rFINT && !issued_interrupt && !cpu_interrupt) &&
			!(wIMM || wRTD || wBRU || wBCC);

   always @(cpu_interrupt or wIDAT or wINTOP) begin
     xNXTINST <= cpu_interrupt ? wINTOP : wIDAT;
   end

   always @(/*AUTOSENSE*/fIMM or rIMM or wIDAT or xIREG) begin
      xSIMM <= (fIMM) ?
	       {rIMM, wIDAT[15:0]} :
	       { {(16){xIREG[15]}}, xIREG[15:0]};
   end

   // --- REGISTER FILE ---------------------------------------

  wire [4:0] regf_rRD, regf_rRA, regf_rRB;
  assign regf_rRD = xIREG[25:21];
  assign regf_rRA = xIREG[20:16];
  assign regf_rRB = xIREG[15:11];

   // --- PIPELINE --------------------------------------------

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
       issued_interrupt <= 0;
       cpu_interrupt <= 0;
	rIMM <= 16'h0;
	rOPC <= 6'h0;
	rRA <= 5'h0;
	rRD <= 5'h0;
	rSIMM <= 32'h0;
	// End of automatics
     end else if (d_en) begin // if (grst)
       issued_interrupt <= cpu_interrupt;
       cpu_interrupt <= do_interrupt;
	{rOPC, rRD, rRA, rIMM} <= #1 xNXTINST;
	rSIMM <= #1 xSIMM;
     end

endmodule // aexm_ibuf
