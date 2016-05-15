// $Id: aeMB_bpcu.v,v 1.4 2007-11-14 22:14:34 sybreon Exp $
//
// AEMB BRANCH PROGRAMME COUNTER UNIT
//
// Copyright (C) 2004-2007 Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
//
// This file is part of AEMB.
//
// AEMB is free software: you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// AEMB is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
// Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with AEMB. If not, see <http://www.gnu.org/licenses/>.
//
// $Log: not supported by cvs2svn $
// Revision 1.3  2007/11/10 16:39:38  sybreon
// Upgraded license to LGPLv3.
// Significant performance optimisations.
//
// Revision 1.2  2007/11/02 19:20:58  sybreon
// Added better (beta) interrupt support.
// Changed MSR_IE to disabled at reset as per MB docs.
//
// Revision 1.1  2007/11/02 03:25:39  sybreon
// New EDK 3.2 compatible design with optional barrel-shifter and multiplier.
// Fixed various minor data hazard bugs.
// Code compatible with -O0/1/2/3/s generated code.
//

module aexm_bpcu (/*AUTOARG*/
   // Outputs
   aexm_icache_precycle_addr, rPC, rPCLNK,
   rSKIP,
   // Inputs
   rMXALT, rOPC, rRD, rRA, xRESULT, rRESULT, rDWBDI, rREGA,
   gclk, grst, x_en
   );
   parameter IW = 24;

   // INST WISHBONE
  output [31:0] aexm_icache_precycle_addr;

   // INTERNAL
   output [31:2]   rPC, rPCLNK;
  output 	   rSKIP;
   //output [1:0]    rATOM;
   //output [1:0]    xATOM;

   input [1:0] 	   rMXALT;
   input [5:0] 	   rOPC;
   input [4:0] 	   rRD, rRA;
   input [31:0]    xRESULT; // ALU
   input [31:0]    rRESULT; // ALU
   input [31:0]    rDWBDI; // RAM
   input [31:0]    rREGA;
   //input [1:0] 	   rXCE;

   // SYSTEM
   input 	   gclk, grst, x_en;

   // --- BRANCH CONTROL --------------------------------------------
   // Controls the branch and delay flags

   wire 	   fRTD = (rOPC == 6'o55);
   wire 	   fBCC = (rOPC == 6'o47) | (rOPC == 6'o57);
   wire 	   fBRU = (rOPC == 6'o46) | (rOPC == 6'o56);

   wire [31:0] 	   wREGA;
   assign 	   wREGA = (rMXALT == 2'o2) ? rDWBDI :
			   (rMXALT == 2'o1) ? rRESULT :
			   rREGA;

   wire 	   wBEQ = (wREGA == 32'd0);
   wire 	   wBNE = ~wBEQ;
   wire 	   wBLT = wREGA[31];
   wire 	   wBLE = wBLT | wBEQ;
   wire 	   wBGE = ~wBLT;
   wire 	   wBGT = ~wBLE;

   reg 		   xXCC;
   always @(/*AUTOSENSE*/rRD or wBEQ or wBGE or wBGT or wBLE or wBLT
	    or wBNE)
     case (rRD[2:0])
       3'o0: xXCC <= wBEQ;
       3'o1: xXCC <= wBNE;
       3'o2: xXCC <= wBLT;
       3'o3: xXCC <= wBLE;
       3'o4: xXCC <= wBGT;
       3'o5: xXCC <= wBGE;
       default: xXCC <= 1'bX;
     endcase // case (rRD[2:0])

   reg 		   rBRA, xBRA;
   reg 		   rDLY, xDLY;
  reg 		   rSKIP;
   wire 	   fSKIP = (xBRA && !xDLY) || (rBRA/* && !rDLY*/);

   always @(fBCC or fBRU or fRTD or rRA or rRD or xXCC)
     begin
       xDLY <= (fBRU & rRA[4]) | (fBCC & rRD[4]) | fRTD;
       xBRA <= (fRTD | fBRU) ? 1'b1 :
	       (fBCC) ? xXCC :
	       1'b0;
     end

   // --- PC PIPELINE ------------------------------------------------
   // PC and related changes

   reg [31:2] 	   pre_rIPC, rIPC, xIPC;
   reg [31:2] 	   rPC, xPC;
   reg [31:2] 	   rPCLNK, xPCLNK;

   assign          aexm_icache_precycle_addr = xIPC;

   always @(xBRA or rIPC or rPC or xRESULT or pre_rIPC)
     begin
       xPCLNK <= rPC;
       xPC <= rIPC;
       // This is totaly doable if you hack the living daylight
       // out of carry chains. :)
       xIPC <= (xBRA) ? xRESULT[31:2] : (pre_rIPC + 1);
     end

   // --- ATOMIC CONTROL ---------------------------------------------
   // This is used to indicate 'safe' instruction borders.

   wire 	wIMM = (rOPC == 6'o54) & !fSKIP;
   wire 	wRTD = (rOPC == 6'o55) & !fSKIP;
   wire 	wBCC = xXCC & ((rOPC == 6'o47) | (rOPC == 6'o57)) & !fSKIP;
   wire 	wBRU = ((rOPC == 6'o46) | (rOPC == 6'o56)) & !fSKIP;

   wire 	fATOM = ~(wIMM | wRTD | wBCC | wBRU | rBRA);
   reg [1:0] 	rATOM, xATOM;

   always @(/*AUTOSENSE*/fATOM or rATOM)
     xATOM <= {rATOM[0], (rATOM[0] ^ fATOM)};


   // --- SYNC PIPELINE ----------------------------------------------

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rATOM <= 2'h0;
	rBRA <= 1'h0;
	rDLY <= 1'h0;
	rIPC <= 30'h0;
        pre_rIPC <= 30'h0;
	rPC <= 30'h0;
	rPCLNK <= 30'h0;
       rSKIP <= 0;
	// End of automatics
     end else if (x_en) begin
	pre_rIPC <= #1 xIPC;
        rIPC <= #1 pre_rIPC;
	rBRA <= #1 xBRA;
	rPC <= #1 xPC;
	rPCLNK <= #1 xPCLNK;
	rDLY <= #1 xDLY;
	rATOM <= #1 xATOM;
       rSKIP <= #1 fSKIP;
     end

endmodule // aexm_bpcu
