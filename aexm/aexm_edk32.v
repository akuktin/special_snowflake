module aexm_edk32 (
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

   input		sys_int_i;		// To ibuf of aexm_ibuf.v

   wire [10:0]		xALT;			// From ibuf of aexm_ibuf.v
   wire			dSKIP;
   wire			xSKIP;
   wire			rBRA;
   wire [31:0]		c_io_rg;		// From regf of aexm_regf.v
   wire [3:0]		rDWBSEL;		// From xecu of aexm_xecu.v
   wire [15:0]		xIMM;			// From ibuf of aexm_ibuf.v
   wire			rMSR_IE;		// From xecu of aexm_xecu.v
   wire [1:0]		dMXALT;			// From ctrl of aexm_ctrl.v
   wire [2:0]		xMXALU;			// From ctrl of aexm_ctrl.v
   wire [1:0]		rMXDST;			// From ctrl of aexm_ctrl.v
   wire 		rMXDST_use_combined;	// From ctrl of aexm_ctrl.v
   wire [1:0]		dMXSRC;			// From ctrl of aexm_ctrl.v
   wire [1:0]		dMXTGT;			// From ctrl of aexm_ctrl.v
   wire [5:0]		xOPC;			// From ibuf of aexm_ibuf.v
   wire [5:0]		dOPC;			// From ibuf of aexm_ibuf.v
   wire [31:2]		rIPC;			// From bpcu of aexm_bpcu.v
   wire [31:2]		rPC;			// From bpcu of aexm_bpcu.v
   wire 		MEMOP_MXDST;		// From ctrl of aexm_ctrl.v
   wire [4:0]		xRA;			// From ibuf of aexm_ibuf.v
   wire [4:0]		xRB;			// From ibuf of aexm_ibuf.v
   wire [4:0]		xRD;			// From ibuf of aexm_ibuf.v
   wire [4:0]		dRA;		// From ibuf of aexm_ibuf.v
   wire [4:0]		dRB;		// From ibuf of aexm_ibuf.v
   wire [4:0]		dRD;		// From ibuf of aexm_ibuf.v
   wire [31:0]		xREGA;			// From regf of aexm_regf.v
   wire [31:0]		xREGB;			// From regf of aexm_regf.v
   wire [31:0]		xRESULT;		// From xecu of aexm_xecu.v
   wire [31:0]		rRESULT;		// From xecu of aexm_xecu.v
   wire [4:0]		rRW;			// From ctrl of aexm_ctrl.v
   wire 		rRDWE;			// From ctrl of aexm_ctrl.v
   wire [31:0]		dIMMVAL;			// From ibuf of aexm_ibuf.v
   wire			fSTALL;			// From ibuf of aexm_ibuf.v
   wire [31:0]		dINST;			// From ibuf of aexm_ibuf.v
  wire 			late_forward_D;
  wire 			dSTRLOD;
  wire 			dLOD;
  wire 			cpu_enable;
  wire 			cpu_mode_memop;

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
		     .dSKIP(dSKIP),
		     .fSTALL(fSTALL),
		     .cpu_mode_memop(cpu_mode_memop),
		     .cpu_enable(cpu_enable),
		     .icache_enable(aexm_icache_precycle_enable),
		     .dcache_enable(aexm_dcache_precycle_enable));

   aexm_ibuf
     ibuf (// Outputs
	   .xIMM			(xIMM[15:0]),
	   .xRA				(xRA[4:0]),
	   .xRD				(xRD[4:0]),
	   .xRB				(xRB[4:0]),
	   .xALT			(xALT[10:0]),
	   .xOPC			(xOPC[5:0]),
	   .dOPC			(dOPC[5:0]),
	   .dIMMVAL			(dIMMVAL[31:0]),
	   .dINST			(dINST[31:0]),
	   .dRA                    (dRA),
	   .dRB                    (dRB),
	   .dRD                    (dRD),
	   // Inputs
	   .rMSR_IE			(rMSR_IE),
	   .rBRA			(rBRA),
	   .aexm_icache_datai           (aexm_icache_datai),
	   .sys_int_i			(sys_int_i),
	   .gclk			(gclk),
	   .d_en			(cpu_enable));

   aexm_ctrl
     ctrl (// Outputs
	   .rMXDST			(rMXDST[1:0]),
	   .rMXDST_use_combined		(rMXDST_use_combined),
	   .MEMOP_MXDST			(MEMOP_MXDST),
	   .dMXSRC			(dMXSRC[1:0]),
	   .dMXTGT			(dMXTGT[1:0]),
	   .dMXALT			(dMXALT[1:0]),
	   .xMXALU			(xMXALU[2:0]),
	   .rRW				(rRW[4:0]),
	   .rRDWE		        (rRDWE),
	   .dSTRLOD                     (dSTRLOD),
	   .dLOD                        (dLOD),
	   .fSTALL			(fSTALL),
	   .late_forward_D		(late_forward_D),
	   .aexm_dcache_precycle_we     (aexm_dcache_precycle_we),
	   .aexm_dcache_force_miss      (aexm_dcache_force_miss),
	   // Inputs
	   .xSKIP			(xSKIP),
	   .xALT			(xALT[10:0]),
	   .xRD				(xRD[4:0]),
	   .dINST			(dINST[31:0]),
	   .gclk			(gclk),
	   .d_en			(cpu_enable),
	   .x_en                        (cpu_enable));

   aexm_bpcu #(IW)
     bpcu (// Outputs
	   .aexm_icache_precycle_addr   (aexm_icache_precycle_addr),
	   .rIPC			(rIPC[31:2]),
	   .rPC				(rPC[31:2]),
	   .dSKIP			(dSKIP),
	   .xSKIP			(xSKIP),
	   .rBRA			(rBRA),
	   // Inputs
	   .cpu_mode_memop              (cpu_mode_memop),
	   .dMXALT			(dMXALT[1:0]),
	   .dINST			(dINST[31:0]),
	   .xRESULT			(xRESULT[31:0]),
	   .c_io_rg			(c_io_rg[31:0]),
	   .xREGA			(xREGA[31:0]),
	   .gclk			(gclk),
	   .d_en			(cpu_enable),
	   .x_en			(cpu_enable));

   aexm_regf
     regf (// Outputs
	   .xREGA			(xREGA[31:0]),
	   .xREGB			(xREGB[31:0]),
	   .c_io_rg			(c_io_rg[31:0]),
	   .aexm_dcache_datao           (aexm_dcache_datao),
	   // Inputs
	   .xOPC			(xOPC[5:0]),
	   .dRA				(dRA),
	   .dRB				(dRB),
	   .dRD				(dRD),
	   .rRW				(rRW[4:0]),
	   .rRDWE		        (rRDWE),
	   .xRD				(xRD[4:0]),
	   .rMXDST			(rMXDST[1:0]),
	   .rMXDST_use_combined		(rMXDST_use_combined),
	   .MEMOP_MXDST			(MEMOP_MXDST),
	   .late_forward_D		(late_forward_D),
	   .rPC				(rPC[31:2]),
	   .rRESULT			(rRESULT[31:0]),
	   .rDWBSEL			(rDWBSEL[3:0]),
	   .aexm_dcache_datai           (aexm_dcache_datai),
	   .gclk			(gclk),
	   .d_en			(cpu_enable),
	   .x_en			(cpu_enable));

   aexm_xecu #(DW, BSF)
     xecu (// Outputs
	   .aexm_dcache_precycle_addr   (aexm_dcache_precycle_addr),
	   .xRESULT			(xRESULT[31:0]),
	   .rRESULT			(rRESULT[31:0]),
	   .rDWBSEL			(rDWBSEL[3:0]),
	   .rMSR_IE			(rMSR_IE),
	   // Inputs
	   .xREGA			(xREGA[31:0]),
	   .xREGB			(xREGB[31:0]),
	   .dMXSRC			(dMXSRC[1:0]),
	   .dMXTGT			(dMXTGT[1:0]),
	   .xRA				(xRA[4:0]),
	   .xMXALU			(xMXALU[2:0]),
	   .xSKIP                       (xSKIP),
	   .xALT			(xALT[10:0]),
	   .dIMMVAL			(dIMMVAL[31:0]),
	   .xIMM			(xIMM[15:0]),
	   .xOPC			(xOPC[5:0]),
	   .dOPC			(dOPC[5:0]),
	   .xRD				(xRD[4:0]),
	   .c_io_rg			(c_io_rg[31:0]),
	   .rIPC			(rIPC[31:2]),
	   .rPC				(rPC[31:2]),
	   .gclk			(gclk),
	   .d_en			(cpu_enable),
	   .x_en			(cpu_enable));


endmodule // aexm_edk32
