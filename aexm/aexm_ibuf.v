/* $Id: aeMB_ibuf.v,v 1.10 2008-01-21 01:02:26 sybreon Exp $
**
** AEMB INSTRUCTION BUFFER
** Copyright (C) 2004-2007 Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
**
** This file is part of AEMB.
**
** AEMB is free software: you can redistribute it and/or modify it
** under the terms of the GNU Lesser General Public License as
** published by the Free Software Foundation, either version 3 of the
** License, or (at your option) any later version.
**
** AEMB is distributed in the hope that it will be useful, but WITHOUT
** ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
** or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
** Public License for more details.
**
** You should have received a copy of the GNU Lesser General Public
** License along with AEMB. If not, see <http://www.gnu.org/licenses/>.
*/

module aexm_ibuf (/*AUTOARG*/
   // Outputs
   rIMM, rRA, rRD, rRB, rALT, rOPC, rSIMM, xIREG, fSTALL,
         dRA, dRD, dRB, dALT, dOPC,
   // Inputs
   rMSR_IE, aexm_icache_datai, sys_int_i, gclk,
   grst, d_en, oena
   );
   // INTERNAL
   output [15:0] rIMM;
   output [4:0]  rRA, rRD, rRB, dRA, dRD, dRB;
   output [10:0] rALT, dALT;
   output [5:0]  rOPC, dOPC;
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

  wire [4:0] 	 dRA, dRD, dRB;
  wire [10:0] 	 dALT;
  wire [5:0] 	 dOPC;

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

  assign {dOPC, dRD, dRA, dRB, dALT} = xIREG;

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

/*
 $Log: not supported by cvs2svn $
 Revision 1.9  2008/01/19 16:01:22  sybreon
 Patched problem where memory access followed by dual cycle instructions were not stalling correctly (submitted by M. Ettus)

 Revision 1.8  2007/12/25 22:15:09  sybreon
 Stalls pipeline on MUL/BSF instructions results in minor speed improvements.

 Revision 1.7  2007/11/22 15:11:15  sybreon
 Change interrupt to positive level triggered interrupts.

 Revision 1.6  2007/11/14 23:39:51  sybreon
 Fixed interrupt signal synchronisation.

 Revision 1.5  2007/11/14 22:14:34  sybreon
 Changed interrupt handling system (reported by M. Ettus).

 Revision 1.4  2007/11/10 16:39:38  sybreon
 Upgraded license to LGPLv3.
 Significant performance optimisations.

 Revision 1.3  2007/11/03 08:34:55  sybreon
 Minor code cleanup.

 Revision 1.2  2007/11/02 19:20:58  sybreon
 Added better (beta) interrupt support.
 Changed MSR_IE to disabled at reset as per MB docs.

 Revision 1.1  2007/11/02 03:25:40  sybreon
 New EDK 3.2 compatible design with optional barrel-shifter and multiplier.
 Fixed various minor data hazard bugs.
 Code compatible with -O0/1/2/3/s generated code.
*/
