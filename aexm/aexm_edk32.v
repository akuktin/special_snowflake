/* $Id: aeMB_edk32.v,v 1.14 2008-01-19 16:01:22 sybreon Exp $
**
** AEMB EDK 3.2 Compatible Core
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

module aexm_edk32 (/*AUTOARG*/
   // Outputs
   aexm_icache_precycle_addr,
   aexm_dcache_precycle_addr,
   aexm_dcache_datao, aexm_dcache_precycle_we,
   aexm_dcache_precycle_enable, aexm_icache_precycle_enable,
   aexm_dcache_we_tlb, aexm_icache_we_tlb,
   // Inputs
   aexm_icache_datai, aexm_dcache_datai,
   aexm_icache_cache_busy, aexm_dcache_cache_busy,
   sys_int_i, sys_clk_i, sys_rst_i
   );
   // Bus widths
   parameter IW = 32; /// Instruction bus address width
   parameter DW = 32; /// Data bus address width

   // Optional functions
   parameter MUL = 0; // Multiplier
   parameter BSF = 1; // Barrel Shifter

  output [31:0] aexm_icache_precycle_addr;
  input [31:0]  aexm_icache_datai;
  output 	aexm_icache_precycle_enable;

  output [31:0] aexm_dcache_precycle_addr;
  input [31:0] 	aexm_dcache_datai;
  output [31:0] aexm_dcache_datao;
  output        aexm_dcache_precycle_we;
  output        aexm_dcache_precycle_enable;

  output 	aexm_dcache_we_tlb;
  output 	aexm_icache_we_tlb;

  input 	aexm_icache_cache_busy;
  input 	aexm_dcache_cache_busy;

   /*AUTOINPUT*/
   input		sys_int_i;		// To ibuf of aexm_ibuf.v
   // End of automatics
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [10:0]		rALT;			// From ibuf of aexm_ibuf.v
   wire [10:0]		dALT;			// From ibuf of aexm_ibuf.v
   wire			rSKIP;			// From bpcu of aexm_bpcu.v
   wire [31:0]		rDWBDI;			// From regf of aexm_regf.v
   wire [3:0]		rDWBSEL;		// From xecu of aexm_xecu.v
   wire [15:0]		rIMM;			// From ibuf of aexm_ibuf.v
   wire			rMSR_IE;		// From xecu of aexm_xecu.v
   wire [1:0]		rMXALT;			// From ctrl of aexm_ctrl.v
   wire [2:0]		rMXALU;			// From ctrl of aexm_ctrl.v
   wire [1:0]		rMXDST;			// From ctrl of aexm_ctrl.v
   wire [1:0]		rMXSRC;			// From ctrl of aexm_ctrl.v
   wire [1:0]		rMXTGT;			// From ctrl of aexm_ctrl.v
   wire [5:0]		rOPC;			// From ibuf of aexm_ibuf.v
   wire [5:0]		dOPC;			// From ibuf of aexm_ibuf.v
   wire [31:2]		rPC;			// From bpcu of aexm_bpcu.v
   wire [31:2]		rPCLNK;			// From bpcu of aexm_bpcu.v
   wire [4:0]		rRA;			// From ibuf of aexm_ibuf.v
   wire [4:0]		rRB;			// From ibuf of aexm_ibuf.v
   wire [4:0]		rRD;			// From ibuf of aexm_ibuf.v
   wire [4:0]		dRA;			// From ibuf of aexm_ibuf.v
   wire [4:0]		dRB;			// From ibuf of aexm_ibuf.v
   wire [4:0]		dRD;			// From ibuf of aexm_ibuf.v
   wire [31:0]		rREGA;			// From regf of aexm_regf.v
   wire [31:0]		rREGB;			// From regf of aexm_regf.v
   wire [31:0]		xRESULT;		// From xecu of aexm_xecu.v
   wire [31:0]		rRESULT;		// From xecu of aexm_xecu.v
   wire [4:0]		rRW;			// From ctrl of aexm_ctrl.v
   wire [31:0]		rSIMM;			// From ibuf of aexm_ibuf.v
   wire			fSTALL;			// From ibuf of aexm_ibuf.v
   wire [31:0]		xIREG;			// From ibuf of aexm_ibuf.v
  wire 			dSTRLOD;
  wire 			dLOD;
  wire 			cpu_enable;
  wire 			cpu_mode_memop;
   // End of automatics

   input 		sys_clk_i;
   input 		sys_rst_i;

  assign aexm_dcache_we_tlb = 1'b0;
  assign aexm_icache_we_tlb = 1'b0;


   wire 		grst = sys_rst_i;
   wire 		gclk = sys_clk_i;


   // --- INSTANTIATIONS -------------------------------------

  aexm_enable enable(.CLK(gclk),
		     .grst(grst),
		     .icache_busy(aexm_icache_cache_busy),
		     .dcache_busy(aexm_dcache_cache_busy),
		     .dSTRLOD(dSTRLOD),
		     .dLOD(dLOD),
		     .cpu_mode_memop(cpu_mode_memop),
		     .cpu_enable(cpu_enable),
		     .icache_enable(aexm_icache_precycle_enable),
		     .dcache_enable(aexm_dcache_precycle_enable));

   aexm_ibuf
     ibuf (/*AUTOINST*/
	   // Outputs
	   .rIMM			(rIMM[15:0]),
	   .rRA				(rRA[4:0]),
	   .rRD				(rRD[4:0]),
	   .rRB				(rRB[4:0]),
	   .rALT			(rALT[10:0]),
	   .rOPC			(rOPC[5:0]),
	   .dRA				(dRA[4:0]),
	   .dRD				(dRD[4:0]),
	   .dRB				(dRB[4:0]),
	   .dALT			(dALT[10:0]),
	   .dOPC			(dOPC[5:0]),
	   .rSIMM			(rSIMM[31:0]),
	   .xIREG			(xIREG[31:0]),
	   .fSTALL			(fSTALL),
	   // Inputs
	   .rMSR_IE			(rMSR_IE),
	   .aexm_icache_datai           (aexm_icache_datai),
	   .sys_int_i			(sys_int_i),
	   .gclk			(gclk),
	   .grst			(grst),
	   .d_en			(cpu_enable),
	   .oena			(1'b0));

   aexm_ctrl
     ctrl (/*AUTOINST*/
	   // Outputs
	   .rMXDST			(rMXDST[1:0]),
	   .rMXSRC			(rMXSRC[1:0]),
	   .rMXTGT			(rMXTGT[1:0]),
	   .rMXALT			(rMXALT[1:0]),
	   .rMXALU			(rMXALU[2:0]),
	   .rRW				(rRW[4:0]),
	   .dSTRLOD                     (dSTRLOD),
	   .dLOD                        (dLOD),
	   .aexm_dcache_precycle_we     (aexm_dcache_precycle_we),
	   // Inputs
	   .rSKIP			(rSKIP),
	   .rIMM			(rIMM[15:0]),
	   .rALT			(rALT[10:0]),
	   .rOPC			(rOPC[5:0]),
	   .rRD				(rRD[4:0]),
	   .rRA				(rRA[4:0]),
	   .rRB				(rRB[4:0]),
	   .xIREG			(xIREG[31:0]),
	   .gclk			(gclk),
	   .grst			(grst),
	   .d_en			(cpu_enable),
	   .x_en                        (cpu_enable));

   aexm_bpcu #(IW)
     bpcu (/*AUTOINST*/
	   // Outputs
	   .aexm_icache_precycle_addr   (aexm_icache_precycle_addr),
	   .rPC				(rPC[31:2]),
	   .rPCLNK			(rPCLNK[31:2]),
	   .rSKIP			(rSKIP),
	   // Inputs
	   .cpu_mode_memop              (cpu_mode_memop),
	   .rMXALT			(rMXALT[1:0]),
	   .rOPC			(rOPC[5:0]),
	   .rRD				(rRD[4:0]),
	   .rRA				(rRA[4:0]),
	   .xRESULT			(xRESULT[31:0]),
	   .rRESULT			(rRESULT[31:0]),
	   .rDWBDI			(rDWBDI[31:0]),
	   .rREGA			(rREGA[31:0]),
	   .gclk			(gclk),
	   .grst			(grst),
	   .x_en			(cpu_enable));

   aexm_regf
     regf (/*AUTOINST*/
	   // Outputs
	   .rREGA			(rREGA[31:0]),
	   .rREGB			(rREGB[31:0]),
	   .rDWBDI			(rDWBDI[31:0]),
	   .aexm_dcache_datao           (aexm_dcache_datao),
	   // Inputs
	   .rOPC			(rOPC[5:0]),
	   .rRA				(rRA[4:0]),
	   .rRB				(rRB[4:0]),
	   .rRW				(rRW[4:0]),
	   .rRD				(rRD[4:0]),
	   .rMXDST			(rMXDST[1:0]),
	   .rPCLNK			(rPCLNK[31:2]),
	   .rRESULT			(rRESULT[31:0]),
	   .rDWBSEL			(rDWBSEL[3:0]),
	   .aexm_dcache_datai           (aexm_dcache_datai),
	   .gclk			(gclk),
	   .grst			(grst),
	   .x_en			(cpu_enable));

   aexm_xecu #(DW, MUL, BSF)
     xecu (/*AUTOINST*/
	   // Outputs
	   .aexm_dcache_precycle_addr   (aexm_dcache_precycle_addr),
	   .xRESULT			(xRESULT[31:0]),
	   .rRESULT			(rRESULT[31:0]),
	   .rDWBSEL			(rDWBSEL[3:0]),
	   .rMSR_IE			(rMSR_IE),
	   // Inputs
	   .rREGA			(rREGA[31:0]),
	   .rREGB			(rREGB[31:0]),
	   .rMXSRC			(rMXSRC[1:0]),
	   .rMXTGT			(rMXTGT[1:0]),
	   .rRA				(rRA[4:0]),
	   .rRB				(rRB[4:0]),
	   .rMXALU			(rMXALU[2:0]),
	   .rSKIP                       (rSKIP),
	   .rALT			(rALT[10:0]),
	   .fSTALL			(fSTALL),
	   .rSIMM			(rSIMM[31:0]),
	   .rIMM			(rIMM[15:0]),
	   .rOPC			(rOPC[5:0]),
	   .rRD				(rRD[4:0]),
	   .rDWBDI			(rDWBDI[31:0]),
	   .rPC				(rPC[31:2]),
	   .gclk			(gclk),
	   .grst			(grst),
	   .x_en			(cpu_enable));


endmodule // aexm_edk32

/*
 $Log: not supported by cvs2svn $
 Revision 1.13  2007/12/25 22:15:09  sybreon
 Stalls pipeline on MUL/BSF instructions results in minor speed improvements.

 Revision 1.12  2007/12/23 20:40:44  sybreon
 Abstracted simulation kernel (aeMB_sim) to split simulation models from synthesis models.

 Revision 1.11  2007/11/30 17:08:29  sybreon
 Moved simulation kernel into code.

 Revision 1.10  2007/11/16 21:52:03  sybreon
 Added fsl_tag_o to FSL bus (tag either address or data).

 Revision 1.9  2007/11/14 23:19:24  sybreon
 Fixed minor typo.

 Revision 1.8  2007/11/14 22:14:34  sybreon
 Changed interrupt handling system (reported by M. Ettus).

 Revision 1.7  2007/11/10 16:39:38  sybreon
 Upgraded license to LGPLv3.
 Significant performance optimisations.

 Revision 1.6  2007/11/09 20:51:52  sybreon
 Added GET/PUT support through a FSL bus.

 Revision 1.5  2007/11/08 17:48:14  sybreon
 Fixed data WISHBONE arbitration problem (reported by J Lee).

 Revision 1.4  2007/11/08 14:17:47  sybreon
 Parameterised optional components.

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
