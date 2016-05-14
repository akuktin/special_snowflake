// $Id: aeMB_regf.v,v 1.3 2007-11-10 16:39:38 sybreon Exp $
//
// AEMB REGISTER FILE
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
// Revision 1.2  2007/11/09 20:51:52  sybreon
// Added GET/PUT support through a FSL bus.
//
// Revision 1.1  2007/11/02 03:25:41  sybreon
// New EDK 3.2 compatible design with optional barrel-shifter and multiplier.
// Fixed various minor data hazard bugs.
// Code compatible with -O0/1/2/3/s generated code.
//

module aexm_regf (/*AUTOARG*/
   // Outputs
   rREGA, rREGB, rDWBDI, aexm_dcache_datao,
   // Inputs
   rOPC, rRA, rRB, rRW, rRD, rMXDST, rPCLNK, rRESULT, rDWBSEL,
   aexm_dcache_datai, gclk, grst, x_en
   );
   // INTERNAL
   output [31:0] rREGA, rREGB;
   output [31:0] rDWBDI;
   input [5:0] 	 rOPC;
   input [4:0] 	 rRA, rRB, rRW, rRD;
   input [1:0] 	 rMXDST;
   input [31:2]  rPCLNK;
   input [31:0]  rRESULT;
   input [3:0] 	 rDWBSEL;

   // MCU interface
   output [31:0] aexm_dcache_datao;
   input [31:0]  aexm_dcache_datai;

   // SYSTEM
   input 	 gclk, grst, x_en;

   // --- LOAD SIZER ----------------------------------------------
   // Moves the data bytes around depending on the size of the
   // operation.

   wire [31:0] 	 wDWBDI = aexm_dcache_datai;

   reg [31:0] 	 rDWBDI;

   always @(/*AUTOSENSE*/rDWBSEL or wDWBDI) begin
      // 52.0
      case (rDWBSEL)
	// 8'bit
	4'h8: rDWBDI <= {24'd0, wDWBDI[31:24]};
	4'h4: rDWBDI <= {24'd0, wDWBDI[23:16]};
	4'h2: rDWBDI <= {24'd0, wDWBDI[15:8]};
	4'h1: rDWBDI <= {24'd0, wDWBDI[7:0]};
	// 16'bit
	4'hC: rDWBDI <= {16'd0, wDWBDI[31:16]};
	4'h3: rDWBDI <= {16'd0, wDWBDI[15:0]};
	// 32'bit
	4'hF: rDWBDI <= wDWBDI;
	// Undefined
	default: rDWBDI <= 32'hX;
      endcase
   end

   // --- GENERAL PURPOSE REGISTERS (R0-R31) -----------------------
   // LUT RAM implementation is smaller and faster. R0 gets written
   // during reset with 0x00 and doesn't change after.

   reg [31:0] 	 mARAM[0:31],
		 mBRAM[0:31],
		 mDRAM[0:31];

   wire [31:0] 	 rREGW = mDRAM[rRW];
   wire [31:0] 	 rREGD = mDRAM[rRD];
   assign 	 rREGA = mARAM[rRA];
   assign 	 rREGB = mBRAM[rRB];

   wire 	 fRDWE = |rRW;

   reg [31:0] 	 xWDAT;

   always @(/*AUTOSENSE*/rDWBDI or rMXDST or rPCLNK or rREGW
	    or rRESULT)
     case (rMXDST)
       2'o2: xWDAT <= rDWBDI;
       2'o1: xWDAT <= {rPCLNK, 2'o0};
       2'o0: xWDAT <= rRESULT;
       2'o3: xWDAT <= rREGW; // No change
     endcase // case (rMXDST)

   always @(posedge gclk)
     if ((grst | fRDWE) && x_en) begin
	mARAM[rRW] <= xWDAT;
	mBRAM[rRW] <= xWDAT;
	mDRAM[rRW] <= xWDAT;
     end

   // --- STORE SIZER ---------------------------------------------
   // Replicates the data bytes across depending on the size of the
   // operation.

   reg [31:0] 	 rDWBDO, xDWBDO;

   wire [31:0] 	 xDST;
   wire 	 fDFWD_M = (rRW == rRD) & (rMXDST == 2'o2) & fRDWE;
   wire 	 fDFWD_R = (rRW == rRD) & (rMXDST == 2'o0) & fRDWE;

   assign 	 aexm_dcache_datao = xDWBDO;
   assign 	 xDST = (fDFWD_M) ? rDWBDI :
			(fDFWD_R) ? rRESULT :
			rREGD;

   always @(/*AUTOSENSE*/rOPC or xDST)
     case (rOPC[1:0])
       // 8'bit
       2'h0: xDWBDO <= {(4){xDST[7:0]}};
       // 16'bit
       2'h1: xDWBDO <= {(2){xDST[15:0]}};
       // 32'bit
       2'h2: xDWBDO <= xDST;
       default: xDWBDO <= 32'hX;
     endcase // case (rOPC[1:0])

   // --- SIMULATION ONLY ------------------------------------------
   // Randomise memory to simulate real-world memory
   // synopsys translate_off

   integer i;
   initial begin
      for (i=0; i<32; i=i+1) begin
	 mARAM[i] <= $random;
	 mBRAM[i] <= $random;
	 mDRAM[i] <= $random;
      end
    mARAM[31] <= 32'd1;
    mBRAM[31] <= 32'd1;
    mDRAM[31] <= 32'd1;
   end

   // synopsys translate_on


endmodule // aexm_regf
