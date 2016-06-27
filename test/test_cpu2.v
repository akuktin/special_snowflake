`timescale 1ns/1ps

`include "test_inc.v"

// Memory module
`include "commands.v"
`include "state.v"
`include "initializer.v"
`include "integration.v"

// Cache
`include "cpu_mcu2.v"

// CPU
`include "aexm/aexm_enable.v"
`include "aexm/aexm_bpcu.v"
`include "aexm/aexm_regf.v"
`include "aexm/aexm_ctrl.v"
`include "aexm/aexm_xecu.v"
`include "aexm/aexm_ibuf.v"
`include "aexm/aexm_edk32.v"
//`include "aexm/aexm_aux.v"

module GlaDOS;
  reg CLK_p, CLK_n, CLK_dp, CLK_dn, RST, CPU_CLK, RST_CPU, RST_CPU_pre;
  reg [31:0] counter, minicounter, readcount, readcount2, readcount_r;

  initial
    forever
      begin
        #1.5 CLK_n <= 0; CLK_p <= 1;
        #1.5 CLK_dp <= 1; CLK_dn <= 0;
        #1.5 CLK_n <= 1; CLK_p <= 0;
        #1.5 CLK_dp <= 0; CLK_dn <= 1;
      end
  initial
    forever
      begin
        #1.5;
        #4.5 CPU_CLK <= 1;
        #3   CPU_CLK <= 0;
      end

  wire        iCKE, iDQS, iDM, iCS;
  wire [2:0]  iCOMMAND;
  wire [12:0] iADDRESS;
  wire [1:0]  iBANK;
  wire [15:0] iDQ;
  wire        dCKE, dDQS, dDM, dCS;
  wire [2:0]  dCOMMAND;
  wire [12:0] dADDRESS;
  wire [1:0]  dBANK;
  wire [15:0] dDQ;
  wire [31:0]  i_user_req_address;
  wire         i_user_req_we, i_user_req;
  wire [31:0]  i_user_req_datain;
  wire 	       i_user_req_ack;
  wire [31:0]  i_user_req_dataout;
  wire [31:0]  d_user_req_address;
  wire         d_user_req_we, d_user_req;
  wire [31:0]  d_user_req_datain;
  wire 	       d_user_req_ack;
  wire [31:0]  d_user_req_dataout;

  reg 	       cache_vmem, cache_inhibit;

  ddr i_ddr_mem(.Clk(CLK_p),
              .Clk_n(CLK_n),
              .Cke(iCKE),
              .Cs_n(iCS),
              .Ras_n(iCOMMAND[2]),
              .Cas_n(iCOMMAND[1]),
              .We_n(iCOMMAND[0]),
              .Ba(iBANK),
              .Addr(iADDRESS),
              .Dm({iDM,iDM}),
              .Dq(iDQ),
              .Dqs({iDQS,iDQS}));
  ddr_memory_controler i_mcu(.CLK_n(CLK_n),
                             .CLK_p(CLK_p),
                             .CLK_dp(CLK_dp),
                             .CLK_dn(CLK_dn),
                             .RST(RST),
                             .CKE(iCKE),
                             .COMMAND(iCOMMAND),
                             .ADDRESS(iADDRESS),
                             .BANK(iBANK),
                             .DQ(iDQ),
                             .DQS(iDQS),
                             .DM(iDM),
                             .CS(iCS),
                             .user_req_address(i_user_req_address),
                             .user_req_we(i_user_req_we),
                             .user_req(i_user_req),
                             .user_req_datain(i_user_req_datain),
                             .user_req_ack(i_user_req_ack),
                             .user_req_dataout(i_user_req_dataout));

  ddr d_ddr_mem(.Clk(CLK_p),
              .Clk_n(CLK_n),
              .Cke(dCKE),
              .Cs_n(dCS),
              .Ras_n(dCOMMAND[2]),
              .Cas_n(dCOMMAND[1]),
              .We_n(dCOMMAND[0]),
              .Ba(dBANK),
              .Addr(dADDRESS),
              .Dm({dDM,dDM}),
              .Dq(dDQ),
              .Dqs({dDQS,dDQS}));
  ddr_memory_controler d_mcu(.CLK_n(CLK_n),
                             .CLK_p(CLK_p),
                             .CLK_dp(CLK_dp),
                             .CLK_dn(CLK_dn),
                             .RST(RST),
                             .CKE(dCKE),
                             .COMMAND(dCOMMAND),
                             .ADDRESS(dADDRESS),
                             .BANK(dBANK),
                             .DQ(dDQ),
                             .DQS(dDQS),
                             .DM(dDM),
                             .CS(dCS),
                             .user_req_address(d_user_req_address),
                             .user_req_we(d_user_req_we),
                             .user_req(d_user_req),
                             .user_req_datain(d_user_req_datain),
                             .user_req_ack(d_user_req_ack),
                             .user_req_dataout(d_user_req_dataout));

  wire 	       i_cache_enable, d_cache_enable;
  wire 	       i_cache_busy, d_cache_busy;
  wire [31:0]  d_cache_datao, d_cache_datai,
	       i_cache_datai;
  wire [31:0]  i_cache_pc_addr, i_cache_c_addr;
  wire [31:0]  d_cache_pc_addr, d_cache_c_addr;
  wire 	       i_cache_req;
  wire 	       d_cache_we, d_cache_req;
  wire 	       dcache_we_tlb, icache_we_tlb;

  wire 	       RST_CACHE;
  assign RST_CACHE = RST_CPU;

  snowball_cache i_cache(.CPU_CLK(CPU_CLK),
			 .MCU_CLK(CLK_n),
			 .RST(RST_CACHE),
			 .cache_precycle_addr(i_cache_pc_addr),
			 .cache_datao(), // CPU perspective
			 .cache_datai(i_cache_datai), // CPU perspective
			 .cache_precycle_we(1'b0),
			 .cache_busy(i_cache_busy),
			 .cache_precycle_enable(i_cache_enable),
//--------------------------------------------------
//--------------------------------------------------
			 .dma_mcu_access(1'b1),
			 .mem_addr(i_user_req_address),
			 .mem_we(i_user_req_we),
			 .mem_do_act(i_user_req),
			 .mem_dataintomem(i_user_req_datain),
			 .mem_ack(i_user_req_ack),
			 .mem_datafrommem(i_user_req_dataout),
//--------------------------------------------------
			 .VMEM_ACT(cache_vmem),
			 .cache_inhibit(cache_inhibit),
			 .fake_miss(1'b0),
//--------------------------------------------------
			 .MMU_FAULT(),
			 .WE_TLB(icache_we_tlb));

  snowball_cache d_cache(.CPU_CLK(CPU_CLK),
			 .MCU_CLK(CLK_n),
			 .RST(RST_CACHE),
			 .cache_precycle_addr({d_cache_pc_addr,2'b00}),
			 .cache_datao(d_cache_datao), // CPU perspective
			 .cache_datai(d_cache_datai), // CPU perspective
			 .cache_precycle_we(d_cache_we),
			 .cache_busy(d_cache_busy),
			 .cache_precycle_enable(d_cache_enable),
//--------------------------------------------------
//--------------------------------------------------
			 .dma_mcu_access(1'b1),
			 .mem_addr(d_user_req_address),
			 .mem_we(d_user_req_we),
			 .mem_do_act(d_user_req),
			 .mem_dataintomem(d_user_req_datain),
			 .mem_ack(d_user_req_ack),
			 .mem_datafrommem(d_user_req_dataout),
//--------------------------------------------------
			 .VMEM_ACT(cache_vmem),
			 .cache_inhibit(cache_inhibit),
			 .fake_miss(1'b0),
//--------------------------------------------------
			 .MMU_FAULT(),
			 .WE_TLB(dcache_we_tlb));

  aexm_edk32 cpu(.sys_clk_i(CPU_CLK),
		 .sys_rst_i(!RST_CPU),
		 .sys_int_i(1'b0),
		 // Outputs
		 .aexm_icache_precycle_addr(i_cache_pc_addr),
		 .aexm_dcache_precycle_addr(d_cache_pc_addr),
		 .aexm_dcache_datao(d_cache_datao),
		 .aexm_dcache_precycle_we(d_cache_we),
		 .aexm_dcache_precycle_enable(d_cache_enable),
		 .aexm_icache_precycle_enable(i_cache_enable),
		 .aexm_dcache_we_tlb(dcache_we_tlb),
		 .aexm_icache_we_tlb(icache_we_tlb),
		 // Inputs
		 .aexm_icache_datai(i_cache_datai),
		 .aexm_dcache_datai(d_cache_datai),
		 .aexm_icache_cache_busy(i_cache_busy),
		 .aexm_dcache_cache_busy(d_cache_busy));

  initial
    begin
      RST <= 0; RST_CPU <= 0; counter <= 0; readcount_r <= 0;
      RST_CPU_pre <= 0;
      #14.875 RST <= 1;
      #400000;
      RST_CPU_pre <= 1;


      #2000;
      #20 $display("timeout"); $finish;
    end

  initial
    begin
      cache_vmem <= 0; cache_inhibit <= 0;
    end

  always @(posedge CPU_CLK)
    begin
      RST_CPU <= RST_CPU_pre;
      if (cpu.regf.mDRAM[31] == 32'd0)
	begin
	  $display("halting");
	  $display(" r0: %x,  r1: %x,  r2: %x  r3: %x",
		   cpu.regf.mDRAM[0], cpu.regf.mDRAM[1],
		   cpu.regf.mDRAM[2], cpu.regf.mDRAM[3]);
	  $display(" r4: %x,  r5: %x,  r6: %x  r7: %x",
		   cpu.regf.mDRAM[4], cpu.regf.mDRAM[5],
		   cpu.regf.mDRAM[6], cpu.regf.mDRAM[7]);
	  $display(" r8: %x,  r9: %x, r10: %x r11: %x",
		   cpu.regf.mDRAM[8], cpu.regf.mDRAM[9],
		   cpu.regf.mDRAM[10], cpu.regf.mDRAM[11]);
	  $display("r12: %x, r13: %x, r14: %x r15: %x",
		   cpu.regf.mDRAM[12], cpu.regf.mDRAM[13],
		   cpu.regf.mDRAM[14], cpu.regf.mDRAM[15]);
	  $display("r16: %x, r17: %x, r18: %x r19: %x",
		   cpu.regf.mDRAM[16], cpu.regf.mDRAM[17],
		   cpu.regf.mDRAM[18], cpu.regf.mDRAM[19]);
	  $display("r20: %x, r21: %x, r22: %x r23: %x",
		   cpu.regf.mDRAM[20], cpu.regf.mDRAM[21],
		   cpu.regf.mDRAM[22], cpu.regf.mDRAM[23]);
	  $display("r24: %x, r25: %x, r26: %x r27: %x",
		   cpu.regf.mDRAM[24], cpu.regf.mDRAM[25],
		   cpu.regf.mDRAM[26], cpu.regf.mDRAM[27]);
	  $display("r28: %x, r29: %x, r30: %x r31: %x",
		   cpu.regf.mDRAM[28], cpu.regf.mDRAM[29],
		   cpu.regf.mDRAM[30], cpu.regf.mDRAM[31]);
	  $finish;
	end
/*
	  $display(" r0: %x,  r1: %x,  r2: %x  r3: %x",
		   cpu.regf.mDRAM[0], cpu.regf.mDRAM[1],
		   cpu.regf.mDRAM[2], cpu.regf.mDRAM[3]);
	  $display(" r4: %x,  r5: %x,  r6: %x  r7: %x",
		   cpu.regf.mDRAM[4], cpu.regf.mDRAM[5],
		   cpu.regf.mDRAM[6], cpu.regf.mDRAM[7]);
	  $display(" r8: %x,  r9: %x, r10: %x r11: %x",
		   cpu.regf.mDRAM[8], cpu.regf.mDRAM[9],
		   cpu.regf.mDRAM[10], cpu.regf.mDRAM[11]);
	  $display("r12: %x, r13: %x, r14: %x r15: %x",
		   cpu.regf.mDRAM[12], cpu.regf.mDRAM[13],
		   cpu.regf.mDRAM[14], cpu.regf.mDRAM[15]);
	  $display("r16: %x, r17: %x, r18: %x r19: %x",
		   cpu.regf.mDRAM[16], cpu.regf.mDRAM[17],
		   cpu.regf.mDRAM[18], cpu.regf.mDRAM[19]);
	  $display("r20: %x, r21: %x, r22: %x r23: %x",
		   cpu.regf.mDRAM[20], cpu.regf.mDRAM[21],
		   cpu.regf.mDRAM[22], cpu.regf.mDRAM[23]);
	  $display("r24: %x, r25: %x, r26: %x r27: %x",
		   cpu.regf.mDRAM[24], cpu.regf.mDRAM[25],
		   cpu.regf.mDRAM[26], cpu.regf.mDRAM[27]);
	  $display("r28: %x, r29: %x, r30: %x r31: %x",
		   cpu.regf.mDRAM[28], cpu.regf.mDRAM[29],
		   cpu.regf.mDRAM[30], cpu.regf.mDRAM[31]);
*/
      if (RST_CPU_pre)
	begin
//      $display("c_vld %x req_tag %x ^ rsp %x idx %x en %x/%x",
//	       i_cache.cachehit_vld, i_cache.req_tag,
//	       i_cache.vmem_rsp_tag, i_cache.tlb_idx_w,
//	       i_cache_enable,
//	       {i_cache_busy_n,(RST & (~RST_CPU)),1'b1});
/*
	  $display("i_pc_addr %x i_c_addr %x i_di %x i_e %x",
		   i_cache_pc_addr, i_cache_c_addr, i_cache_datai,
		   i_cache_enable);
 */

	  $display("i_pc_addr %x i_di %x i_e/i_b %x/%x cpu_en %x fSTALL %x rOP %x",
		   i_cache_pc_addr, i_cache_datai,
		   i_cache_enable, i_cache_busy,
		   cpu.cpu_enable, cpu.ibuf.fSTALL,
		   {cpu.ibuf.rOPC,2'h0});
/*
	  $display("pre_rIPC %x pc_inc %x xIPC %x cpu_mode_memop %x",
		   cpu.bpcu.pre_rIPC, cpu.bpcu.pc_inc, cpu.bpcu.xIPC,
		   cpu.cpu_mode_memop);

	  $display("rRESULT %x rRW %x rSIMM %x rOPA %x rOPB %x",
		   cpu.rRESULT, cpu.rRW, cpu.rSIMM,
		   cpu.xecu.rOPA, cpu.xecu.rOPB);
 */
	  $display("xWDAT %x en %x rDWBDI %x rRW %x",
		   cpu.regf.xWDAT,
		   {cpu.regf.grst,cpu.regf.fRDWE,cpu.regf.w_en},
		   cpu.regf.rDWBDI, cpu.regf.rRW);

	  $display("dpcadr %x ddi %x ddo %x den %x dwe %x dbsy %x",
		   {d_cache_pc_addr,2'b00}, d_cache_datai, d_cache_datao,
		   d_cache_enable, d_cache_we, d_cache_busy);

	  $display("---------------------------------------------------");
	end // if (CPU_RST)
    end

  integer i;
  initial
    begin
      for (i=0;i<256;i=i+1)
        begin
          i_cache.cachedat.ram.r_data[i] <= 0;
          i_cache.cachetag.ram.r_data[i] <= 0;
          i_cache.tlb.ram.r_data[i] <= 0;
          i_cache.tlbtag.ram.r_data[i] <= 0;
          d_cache.cachedat.ram.r_data[i] <= 0;
          d_cache.cachetag.ram.r_data[i] <= 0;
          d_cache.tlb.ram.r_data[i] <= 0;
          d_cache.tlbtag.ram.r_data[i] <= 0;
        end // for (i=0;i<256;i=i+1)

`include "test_cpu_prog.bin"
    end

endmodule // GlaDOS
