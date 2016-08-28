module aexm_edk32 (/*AUTOARG*/
   // Outputs
   aexm_icache_precycle_addr,
   aexm_dcache_precycle_addr,
   aexm_dcache_datao, aexm_dcache_precycle_we,
   aexm_dcache_precycle_enable, aexm_icache_precycle_enable,
   aexm_dcache_we_tlb, aexm_icache_we_tlb,
   aexm_dcache_force_miss,
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

  output 	aexm_dcache_force_miss;

  input 	aexm_icache_cache_busy;
  input 	aexm_dcache_cache_busy;

   /*AUTOINPUT*/
   input		sys_int_i;		// To ibuf of aexm_ibuf.v
   // End of automatics
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [10:0]		rALT;			// From ibuf of aexm_ibuf.v
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
   wire [31:2]		rPC;			// From bpcu of aexm_bpcu.v
   wire [31:2]		rPCLNK;			// From bpcu of aexm_bpcu.v
   wire [4:0]		rRA;			// From ibuf of aexm_ibuf.v
   wire [4:0]		rRB;			// From ibuf of aexm_ibuf.v
   wire [4:0]		rRD;			// From ibuf of aexm_ibuf.v
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
	   .aexm_dcache_force_miss      (aexm_dcache_force_miss),
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
