`timescale 1ns/1ps

`include "test_inc.v"

// Memory module
`include "../mcu/commands.v"
`include "../mcu/state2.v"
`include "../mcu/initializer.v"
`include "../mcu/integration3.v"

// Cache
`include "../cache/cpu_mcu2.v"

// CPU
`include "../aexm/aexm_enable.v"
`include "../aexm/aexm_bpcu.v"
`include "../aexm/aexm_regf.v"
`include "../aexm/aexm_ctrl.v"
`include "../aexm/aexm_xecu.v"
`include "../aexm/aexm_ibuf.v"
`include "../aexm/aexm_edk32.v"
//`include "aexm/aexm_aux.v"

// LSAB
`include "../hyperfabric/lsab.v"

// Hyperfabric
`include "../hyperfabric/transport.v"
`include "../hyperfabric/mvblck_todram.v"
`include "../hyperfabric/mvblck_frdram.v"
`include "../hyperfabric/mvblck_lsab_dram.v"

module test_fill_lsab(input CLK,
		      input 	    RST,
		      output [31:0] DATA0,
		      output [31:0] DATA1,
		      output [31:0] DATA2,
		      output [31:0] DATA3,
		      output 	    WRITE,
		      output [1:0]  WRITE_FIFO,
		      output 	    INT0,
		      output 	    INT1,
		      output 	    INT2,
		      output 	    INT3);
  reg [31:0] 	      test_data[4095:0];
  reg 		      test_we[4095:0],
		      test_int[4095:0];

  reg [1:0] 	      fast_i;
  reg [9:0] 	      slow_i;
  reg [11:0] 	      c;

  assign DATA0 = test_data[{slow_i,2'h0}];
  assign DATA1 = test_data[{slow_i,2'h1}];
  assign DATA2 = test_data[{slow_i,2'h2}];
  assign DATA3 = test_data[{slow_i,2'h3}];

  assign WRITE = test_we[{slow_i,fast_i}];
  assign WRITE_FIFO = fast_i;

  assign INT0 = test_int[{slow_i,2'h0}];
  assign INT1 = test_int[{slow_i,2'h1}];
  assign INT2 = test_int[{slow_i,2'h2}];
  assign INT3 = test_int[{slow_i,2'h3}];

  reg [31:0] 	      l, o, v, e;

  initial
    begin
      for (l=0; l<1024; l=l+1)
	begin
	  for (o=0; o<4; o=o+1)
	    begin
	      test_data[{l[9:0],o[1:0]}] <= {2'h0,o[1:0],l[23:0]};
	      test_we[{l[9:0],o[1:0]}] <= 0;
	      test_int[{l[9:0],o[1:0]}] <= 0;
	    end
	end

      // your test data here
      for (v=(0+4); v<(5+4); v=v+1)
	begin
	  test_we[{v[9:0],2'h1}] <= 1;
	end
      for (e=0; e<15; e=e+1)
	begin
	  test_we[{e[9:0],2'h2}] <= 1;
	end
      test_int[{10'd6,2'h2}] <= 1;
      test_int[{10'd8,2'h2}] <= 1;
    end // initial begin

  always @(posedge CLK)
    if (!RST)
      begin
	fast_i <= 0; slow_i <= 0; c <= 0;
      end
    else
      begin
//	fast_i <= 2'h1;
	if (WRITE && 0)
	  begin
	    $display("writing: %d/%d", slow_i, fast_i);
          end
        if ({slow_i,fast_i} != 4095)
	  begin
	    fast_i <= fast_i +1;
	    if (fast_i == 2'h3)
	      slow_i <= slow_i +1;
          end

	c <= c +1;
      end

endmodule // test_in

module test_dma(input CLK,
		input 		  RST,
		// ---------------------
		input 		  IRQ,
		input [2:0] 	  IRQ_DESC,
		// ---------------------
		input 		  READ_DMA,
		input 		  WRITE_DMA,
		input [2:0] 	  R_ADDR_DMA,
		input [2:0] 	  W_ADDR_DMA,
		input [63:0] 	  IN_DMA,
		output reg [63:0] OUT_DMA);
  reg [31:0] 			  c;
  reg [63:0] 				     mem[7:0];
  reg [63:0] 				     in_r;
  reg 					     read_dma_r, we_pre_r;
  reg [2:0] 				     read_addr, write_addr_r;

  wire 					     read_dma_w, we,
					     atomic_strobe;
  wire [2:0] 				     write_addr;
  wire [63:0] 				     out, in;

  assign out = mem[read_addr];
  assign read_dma_w = READ_DMA;

  assign in = IN_DMA;
  assign write_addr = W_ADDR_DMA;
  assign we_pre = WRITE_DMA;
  assign we = we_pre_r && !(atomic_strobe ^ in_r[61]);

  assign atomic_strobe = mem[write_addr_r][61];

  initial
    begin
      mem[0] <= 0; mem[1] <= 0; mem[2] <= 0; mem[3] <= 0;
      mem[4] <= 0; mem[5] <= 0; mem[6] <= 0; mem[7] <= 0;
    end

  always @(posedge CLK)
    if (!RST)
      begin
	OUT_DMA <= 0; read_dma_r <= 0; read_addr <= 0;
	write_addr_r <= 0; in_r <= 0; we_pre_r <= 0;
	c <= 0;
      end
    else
      begin
	begin
	  c <= c +1;
	  if (c == 600)
	    begin
//	      mem[0] <= 64'h8100_0004_0000_0fff;
//	      mem[0] <= 64'h8500_0004_0000_0fff;
//	      mem[1] <= 64'h8500_0010_0000_0fff;

////	      mem[0] <= 64'h9600_0010_0000_0000;
//	      mem[0] <= 64'h9600_0009_0000_0000;
////	      mem[1] <= 64'h9600_0002_0000_0fff;
//	      mem[1] <= 64'h9600_0002_0000_0007;

//	      mem[1] <= 64'h9000_0040_0000_0001;

	      mem[0] <= 64'h9000_0080_0010_0001;
	      mem[1] <= 64'h9000_003f_0020_0000;
	      mem[3] <= 64'h9000_003f_0030_0000;
	    end
	  if (IRQ)
	    $display("INTERRUPT REQUEST %x", IRQ_DESC);
	end

	if (read_dma_r)
	  OUT_DMA <= out;

	read_dma_r <= read_dma_w;

	if (read_dma_w)
	  read_addr <= R_ADDR_DMA;

	if (we_pre)
	  begin
	    write_addr_r <= write_addr;
	    in_r <= in;
	  end
	we_pre_r <= we_pre;

	if (we)
	  begin
	    mem[write_addr_r] <= in_r;
	    $display("returns: %x_%x", in_r[63:32], in_r[31:0]);
	    if (!in_r[63])
	      $display("END TRANSACTION %x", write_addr_r);
	  end
      end

endmodule // hyper_scheduler_mem



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

  wire [31:0] w_data0_cr, w_data1_cr, w_data2_cr, w_data3_cr;
  wire 	      w_write_cr, w_read_cr, w_write_cw, w_read_cw;
  wire [1:0]  w_write_fifo_cr, w_read_fifo_cr,
	      w_write_fifo_cw, w_read_fifo_cw;
  wire 	      w_int0_cr, w_int1_cr, w_int2_cr, w_int3_cr;
  wire [3:0]  w_care_cr;

  wire [31:0] w_out_cr, w_in_cw;
  wire 	      w_s0_cr, w_s1_cr, w_s2_cr, w_s3_cr;
  wire 	      w_e0_cr, w_e1_cr, w_e2_cr, w_e3_cr;
  wire 	      w_i0_cr, w_i1_cr, w_i2_cr, w_i3_cr;
  wire 	      w_f0_cw, w_f1_cw, w_f2_cw, w_f3_cw;

  wire [31:0] i_mcu_data_into, i_mcu_data_outof,
	      d_mcu_data_into, d_mcu_data_outof;

  wire [11:0] hf_coll_addr_fill, hf_coll_addr_empty, mcu_coll_addr;
  wire [3:0]  hf_we_array_fill;
  wire 	      i_hf_req_access_fill, d_hf_req_access_fill,
	      i_hf_req_access_empty, d_hf_req_access_empty;

  wire 	      w_issue, w_working_fill, w_working_empty;
  wire [1:0]  w_section;
  wire [5:0]  w_count_req, w_count_sent_fill, w_count_sent_empty;
  wire [11:0] w_start_address;

  wire 	      w_irq_cr, w_abstop_cr, w_abstop_cw;

  wire [19:0] mcu_page_addr;
  wire 	      i_mcu_algn_req, i_mcu_algn_ack,
	      d_mcu_algn_req, d_mcu_algn_ack;

  wire 	      mvblck_RST_fill, mvblck_RST_empty;
  reg 	      i_mcu_req_access, d_mcu_req_access, i_mcu_we, d_mcu_we;

  assign mcu_coll_addr = hf_coll_addr_fill | hf_coll_addr_empty;

  wire 	      ww_go, ww_ready, ww_eop;
  wire [1:0]  ww_new_section;
  wire [5:0]  ww_block_length, ww_count_sent;
  wire [31:0] ww_new_addr, ww_old_addr;

  wire 	      drop;
  wire 	      refresh_strobe;
  wire 	      ww_irq;
  wire [1:0]  ww_select_dram;

  wire 	      w_careof_int;
  wire [2:0]  w_isel, w_osel;

  wire 	      res_irq, res_write_mem, res_read_mem;
  wire [2:0]  res_irq_desc, res_r_addr, res_w_addr;
  wire [63:0] res_in, res_out;


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
  wire [3:0]   i_user_we_array;
  wire [31:0]  i_user_req_datain;
  wire 	       i_user_req_ack;
  wire [31:0]  i_user_req_dataout;
  wire [31:0]  d_user_req_address;
  wire         d_user_req_we, d_user_req;
  wire [3:0]   d_user_we_array;
  wire [31:0]  d_user_req_datain;
  wire 	       d_user_req_ack;
  wire [31:0]  d_user_req_dataout;

  reg 	       cache_vmem, cache_inhibit;

  wire 	       d_dma_read, d_dma_wrte, d_dma_read_ack, d_dma_wrte_ack;
  wire [31:0]  d_dma_out;

  reg 	       irq_strobe, irq_strobe_slow, irq_strobe_slow_prev;

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
			     .refresh_strobe(refresh_strobe),
                             .rand_req_address(i_user_req_address),
                             .rand_req_we(i_user_req_we),
			     .rand_req_we_array(d_user_we_array),
                             .rand_req(i_user_req),
                             .rand_req_ack(i_user_req_ack),
                             .rand_req_datain(i_user_req_datain),
			     .bulk_req_address({mcu_page_addr,
						mcu_coll_addr}),
			     .bulk_req_we(i_mcu_we),
			     .bulk_req_we_array(hf_we_array_fill),
			     .bulk_req(i_mcu_req_access),
			     .bulk_req_ack(),
			     .bulk_req_algn(i_mcu_algn_req),
			     .bulk_req_algn_ack(i_mcu_algn_ack),
                             .bulk_req_datain(i_mcu_data_into),
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
			     .refresh_strobe(refresh_strobe),
                             .rand_req_address(d_user_req_address),
                             .rand_req_we(d_user_req_we),
			     .rand_req_we_array(d_user_we_array),
                             .rand_req(d_user_req),
                             .rand_req_ack(d_user_req_ack),
                             .rand_req_datain(d_user_req_datain),
			     .bulk_req_address({mcu_page_addr,
						mcu_coll_addr}),
			     .bulk_req_we(d_mcu_we),
			     .bulk_req_we_array(hf_we_array_fill),
			     .bulk_req(d_mcu_req_access),
			     .bulk_req_ack(),
			     .bulk_req_algn(d_mcu_algn_req),
			     .bulk_req_algn_ack(d_mcu_algn_ack),
                             .bulk_req_datain(d_mcu_data_into),
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
			 .mem_we_array(i_user_we_array),
			 .mem_do_act(i_user_req),
			 .mem_dataintomem(i_user_req_datain),
			 .mem_ack(i_user_req_ack),
			 .mem_datafrommem(i_user_req_dataout),
//--------------------------------------------------
			 .dma_wrte(),
			 .dma_read(),
			 .dma_wrte_ack(0),
			 .dma_read_ack(0),
			 .dma_data_read(),
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
			 .mem_we_array(d_user_we_array),
			 .mem_do_act(d_user_req),
			 .mem_dataintomem(d_user_req_datain),
			 .mem_ack(d_user_req_ack),
			 .mem_datafrommem(d_user_req_dataout),
//--------------------------------------------------
			 .dma_wrte(d_dma_wrte),
			 .dma_read(d_dma_read),
			 .dma_wrte_ack(d_dma_wrte_ack),
			 .dma_read_ack(d_dma_read_ack),
			 .dma_data_read(d_dma_out),
//--------------------------------------------------
			 .VMEM_ACT(cache_vmem),
			 .cache_inhibit(cache_inhibit),
			 .fake_miss(1'b0),
//--------------------------------------------------
			 .MMU_FAULT(),
			 .WE_TLB(dcache_we_tlb));

  aexm_edk32 cpu(.sys_clk_i(CPU_CLK),
		 .sys_rst_i(!RST_CPU),
		 .sys_int_i(irq_strobe_slow ^ irq_strobe_slow_prev),
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

  trans_core hyperfabric_switch(.CLK(CLK_n),
				.RST(RST),
				.out_0(i_mcu_data_into),
				.out_1(d_mcu_data_into),
				.out_2(w_in_cw),
				.out_3(),
				.out_4(), .out_5(),
				.out_6(), .out_7(),
				.in_0(i_mcu_data_outof),
				.in_1(d_mcu_data_outof),
				.in_2(w_out_cr),
				.in_3(0),
				.in_4(0), .in_5(0),
				.in_6(0), .in_7(0),
				.isel({13'h0,w_isel}),
				.osel({13'h0,w_osel}));

  lsab_cr lsab_in(.CLK(CLK_n),
		  .RST(RST),
		  .READ(w_read_cr),
		  .WRITE(w_write_cr),
		  .READ_FIFO(w_read_fifo_cr),
		  .WRITE_FIFO(w_write_fifo_cr),
		  .IN_0(w_data0_cr), .IN_1(w_data1_cr),
		  .IN_2(w_data2_cr), .IN_3(w_data3_cr),
		  .INT_IN_0(w_int0_cr), .INT_IN_1(w_int1_cr),
		  .INT_IN_2(w_int2_cr), .INT_IN_3(w_int3_cr),
		  .CAREOF_INT_0(w_careof_int), .CAREOF_INT_1(w_careof_int),
		  .CAREOF_INT_2(w_careof_int), .CAREOF_INT_3(w_careof_int),
		  .OUT(w_out_cr),
		  .EMPTY_0(w_e0_cr), .EMPTY_1(w_e1_cr),
		  .EMPTY_2(w_e2_cr), .EMPTY_3(w_e3_cr),
		  .STOP_0(w_s0_cr), .STOP_1(w_s1_cr),
		  .STOP_2(w_s2_cr), .STOP_3(w_s3_cr),
		  .INT_OUT_0(w_i0_cr), .INT_OUT_1(w_i1_cr),
		  .INT_OUT_2(w_i2_cr), .INT_OUT_3(w_i3_cr));

  wire 	      drop_f;
  hyper_mvblck_todram fill(.CLK(CLK_n),
			   .RST(mvblck_RST_fill),
			   .LSAB_0_INT(w_i0_cr),
			   .LSAB_1_INT(w_i1_cr),
			   .LSAB_2_INT(w_i2_cr),
			   .LSAB_3_INT(w_i3_cr),
			   .LSAB_0_STOP(w_s0_cr),
			   .LSAB_1_STOP(w_s1_cr),
			   .LSAB_2_STOP(w_s2_cr),
			   .LSAB_3_STOP(w_s3_cr),
			   .LSAB_READ(w_read_cr),
			   .LSAB_SECTION(w_read_fifo_cr),
			   .START_ADDRESS(w_start_address),
			   .COUNT_REQ(w_count_req),
			   .SECTION(w_section),
			   .DRAM_SEL({d_mcu_algn_req,i_mcu_algn_req}),
			   .ISSUE(w_issue),
			   .COUNT_SENT(w_count_sent_fill),
			   .WORKING(w_working_fill),
			   .IRQ_OUT(w_irq_cr),
			   .ABRUPT_STOP(w_abstop_cr),
			   .MCU_COLL_ADDRESS(hf_coll_addr_fill),
			   .MCU_WE_ARRAY(hf_we_array_fill),
			   .MCU_REQUEST_ACCESS({d_hf_req_access_fill,
						i_hf_req_access_fill}));

  lsab_cw lsab_out(.CLK(CLK_n),
		   .RST(RST),
		   .READ(1),
		   .WRITE(w_write_cw),
		   .READ_FIFO(0),
		   .WRITE_FIFO(w_write_fifo_cw),
		   .IN(w_in_cw),
		   .OUT_0(),
		   .OUT_1(),
		   .OUT_2(),
		   .OUT_3(),
		   .BFULL_0(w_f0_cw),
		   .BFULL_1(w_f1_cw),
		   .BFULL_2(w_f2_cw),
		   .BFULL_3(w_f3_cw));

  wire 	      drop_e;
  hyper_mvblck_frdram empty(.CLK(CLK_n),
			  .RST(mvblck_RST_empty),
			  .LSAB_0_FULL(w_f0_cw),
			  .LSAB_1_FULL(w_f1_cw),
			  .LSAB_2_FULL(w_f2_cw),
			  .LSAB_3_FULL(w_f3_cw),
			  .LSAB_WRITE(w_write_cw),
			  .LSAB_SECTION(w_write_fifo_cw),
			  .START_ADDRESS(w_start_address),
			  .COUNT_REQ(w_count_req),
			  .SECTION(w_section),
			  .DRAM_SEL({d_mcu_algn_req,i_mcu_algn_req}),
			  .ISSUE(w_issue),
			  .COUNT_SENT(w_count_sent_empty),
			  .WORKING(w_working_empty),
			  .ABRUPT_STOP(w_abstop_cw),
			  .MCU_COLL_ADDRESS(hf_coll_addr_empty),
			  .MCU_REQUEST_ACCESS({d_hf_req_access_empty,
					       i_hf_req_access_empty}));

  hyper_lsab_dram restarter(.CLK(CLK_n),
		      .RST(RST),
		         // begin COMMAND INTERFACE
		      .GO(ww_go),
		      .SELECT_DRAM(ww_select_dram),
		      .BLOCK_LENGTH(ww_block_length),
		      .NEW_ADDR(ww_new_addr),
		      .NEW_SECTION(ww_new_section),
		      .OLD_ADDR(ww_old_addr),
		      .READY(ww_ready),
		      .RESTART_OP(ww_eop),
		      .COUNT_SENT(ww_count_sent),
		      .IRQ(ww_irq),
			 // begin BLOCK MOVER
		      .BLCK_START(w_start_address),
		      .BLCK_COUNT_REQ(w_count_req),
		      .BLCK_ISSUE(w_issue),
		      .BLCK_SECTION(w_section),
		      .BLCK_COUNT_SENT(w_count_sent_fill |
				       w_count_sent_empty),
		      .BLCK_WORKING(w_working_fill | w_working_empty),
		      .BLCK_IRQ(w_irq_cr),
		      .BLCK_ABRUPT_STOP(w_abstop_cr || w_abstop_cw),
			 // begin MCU
		      .MCU_PAGE_ADDR(mcu_page_addr),
		      .MCU_REQUEST_ALIGN({d_mcu_algn_req,
					  i_mcu_algn_req}),
		      .MCU_GRANT_ALIGN({d_mcu_algn_ack,
					i_mcu_algn_ack}));

  hyper_scheduler scheduler(.CLK(CLK_n),
		      .RST(RST_CPU_pre),
		      // service section interface
		      .CR_E0(w_e0_cr),
		      .CR_E1(w_e1_cr),
		      .CR_E2(w_e2_cr),
		      .CR_E3(w_e3_cr),
		      .CW_F0(w_f0_cw),
		      .CW_F1(w_f1_cw),
		      .CW_F2(w_f2_cw),
		      .CW_F3(w_f3_cw),
		      .GO(ww_go),
		      .EXEC_READY(ww_ready),
		      .EXEC_BLOCK_LENGTH(ww_block_length),
		      .EXEC_COUNT_SENT(ww_count_sent),
		      .EXEC_RESTART_OP(ww_eop),
		      .EXEC_NEW_SECTION(ww_new_section),
		      .MCU_REFRESH_STROBE(refresh_strobe),
		      .EXEC_SELECT_DRAM(ww_select_dram),
		      .SWCH_ISEL(w_isel),
		      .SWCH_OSEL(w_osel),
		      .EXEC_NEW_ADDR(ww_new_addr),
		      .EXEC_OLD_ADDR(ww_old_addr),
		      .CAREOF_INT(w_careof_int),
		      .RST_MVBLCK({mvblck_RST_fill,mvblck_RST_empty}),
		      .IRQ_IN(ww_irq),
		      // user section interface
		      .IRQ(res_irq),
		      .IRQ_DESC(),//res_irq_desc),
		      .WRITE_MEM(res_write_mem),
		      .MEM_W_ADDR(res_w_addr),
		      .MEM_W_DATA(res_in),
		      .READ_MEM(res_read_mem),
		      .MEM_R_ADDR(res_r_addr),
		      .MEM_R_DATA(res_out));

  hyper_scheduler_mem dma_interlink(.CLK(CLK_n),
				    .RST(RST),
			   // ---------------------
				    .READ_CPU(d_dma_read),
				    .WRITE_CPU(d_dma_wrte),
				    .READ_CPU_ACK(d_dma_read_ack),
				    .WRITE_CPU_ACK(d_dma_wrte_ack),
				    .ADDR_CPU(d_user_req_address[2:0]),
				    .IN_CPU({d_user_req_datain,
					     d_user_req_address}),
				    .OUT_CPU(d_dma_out),
			   // ---------------------
				    .READ_DMA(res_read_mem),
				    .WRITE_DMA(res_write_mem),
				    .R_ADDR_DMA(res_r_addr),
				    .W_ADDR_DMA(res_w_addr),
				    .IN_DMA(res_in),
				    .OUT_DMA(res_out));


  test_fill_lsab lsab_write(.CLK(CLK_n),
			    .RST(RST),
			    .DATA0(w_data0_cr), .DATA1(w_data1_cr),
			    .DATA2(w_data2_cr), .DATA3(w_data3_cr),
			    .WRITE(w_write_cr),
			    .WRITE_FIFO(w_write_fifo_cr),
			    .INT0(w_int0_cr), .INT1(w_int1_cr),
			    .INT2(w_int2_cr), .INT3(w_int3_cr));
/*
  test_dma test_drv(.CLK(CLK_n),
		    .RST(RST),
		    .IRQ(res_irq),
		    .IRQ_DESC(res_irq_desc),
		    .READ_DMA(res_read_mem),
		    .WRITE_DMA(res_write_mem),
		    .R_ADDR_DMA(res_r_addr),
		    .W_ADDR_DMA(res_w_addr),
		    .IN_DMA(res_in),
		    .OUT_DMA(res_out));
*/

  initial
    begin
      RST <= 0; RST_CPU <= 0; counter <= 0; readcount_r <= 0;
      RST_CPU_pre <= 0;
      #14.875 RST <= 1;
      #400000;
      RST_CPU_pre <= 1;


      #2000;
      #20000;
      $display("addr %x we %x wea %x req %x algnr %x algna %x",
	       {mcu_page_addr,mcu_coll_addr}, i_mcu_we,
	       hf_we_array_fill, i_mcu_req_access, i_mcu_algn_req,
	       i_mcu_algn_ack);
      $display("state %x,%x,%x reftime %x",
	       i_mcu.interdictor_tracker.SOME_PAGE_ACTIVE,
	       i_mcu.interdictor_tracker.REFRESH_TIME,
	       i_mcu.interdictor_tracker.actv_timeout[2],
	       i_mcu.interdictor_tracker.REFRESH_TIME);
      #20 $display("timeout"); $finish;
    end

  reg i_mcu_req_access_prev, refresh_strobe_prev;
  reg [63:0] ctr;
  initial
    begin
      cache_vmem <= 0; cache_inhibit <= 0;
    end

  always @(posedge CLK_n)
    if (!RST)
      begin
	i_mcu_req_access <= 0; i_mcu_we <= 0;
	d_mcu_req_access <= 0; d_mcu_we <= 0;
	i_mcu_req_access_prev <= 0; refresh_strobe_prev <= 0;
	ctr <= 0; irq_strobe <= 0;
      end
    else
      begin
	if (res_irq)
	  irq_strobe <= !irq_strobe;
	ctr <= ctr+1;
	i_mcu_req_access <= i_hf_req_access_fill || i_hf_req_access_empty;
	d_mcu_req_access <= d_hf_req_access_fill || d_hf_req_access_empty;
	i_mcu_we <= i_hf_req_access_fill;
	d_mcu_we <= d_hf_req_access_fill;
	i_mcu_req_access_prev <= i_mcu_req_access;
	refresh_strobe_prev <= refresh_strobe;

//	if (i_mcu_req_access & ! i_mcu_req_access_prev)
//	if (refresh_strobe ^ refresh_strobe_prev)
//	if (i_mcu_algn_req && ! i_mcu_algn_ack)
//	if ((ctr >= 66820) && (ctr < 66900))
	if ((ctr >= 66740) && (ctr < 66760) && 0)
	  begin
	    $display("@ %d fl %x ep %x",
		     ctr, i_hf_req_access_fill, i_hf_req_access_empty);
	    $display("addr %x we %x wea %x req %x algnr %x algna %x",
		     {mcu_page_addr,mcu_coll_addr}, i_mcu_we,
		     hf_we_array_fill, i_mcu_req_access, i_mcu_algn_req,
		     i_mcu_algn_ack);
/*
	    $display("ss %x chp_n %x (%x %x %x %x)",
		     i_mcu.interdictor_tracker.second_stroke,
		     !i_mcu.interdictor_tracker.change_possible_n,
		     {i_mcu.interdictor_tracker.REQUEST_ACCESS_RAND,
		      i_mcu.interdictor_tracker.REQUEST_ACCESS_BULK,
		      i_mcu.interdictor_tracker.REQUEST_ALIGN_BULK},
		     i_mcu.interdictor_tracker.REQUEST_ACCESS_BULK,
		     i_mcu.interdictor_tracker.REFRESH_TIME,
		     {i_mcu.interdictor_tracker.REQUEST_ALIGN_BULK_dly,
		      i_mcu.interdictor_tracker.GRANT_ALIGN_BULK});
 */
 	  end
      end

  always @(posedge CPU_CLK)
    if (!RST)
      begin
	irq_strobe_slow <= 0;
	irq_strobe_slow_prev <= 0;
      end
    else
    begin
      irq_strobe_slow <= irq_strobe;
      irq_strobe_slow_prev <= irq_strobe_slow;
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
      if (RST_CPU_pre && 0)
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

      cpu.regf.mARAM[8] <= 32'hc000_0000;
      cpu.regf.mBRAM[8] <= 32'hc000_0000;
      cpu.regf.mDRAM[8] <= 32'hc000_0000;


      // into data DRAM
      cpu.regf.mARAM[9] <= 32'h8d00_0045;
      cpu.regf.mBRAM[9] <= 32'h8d00_0045;
      cpu.regf.mDRAM[9] <= 32'h8d00_0045;

/*
      // into instruction DRAM
      cpu.regf.mARAM[9] <= 32'h8500_0045;
      cpu.regf.mBRAM[9] <= 32'h8500_0045;
      cpu.regf.mDRAM[9] <= 32'h8500_0045;
 */
/*
      // nothing at all
      cpu.regf.mARAM[9] <= 32'h0000_0045;
      cpu.regf.mBRAM[9] <= 32'h0000_0045;
      cpu.regf.mDRAM[9] <= 32'h0000_0045;
 */

      // interrupt
      cpu.regf.mARAM[9] <= 32'hfe00_0045;
      cpu.regf.mBRAM[9] <= 32'hfe00_0045;
      cpu.regf.mDRAM[9] <= 32'hfe00_0045;


`include "test_special_snowflake_core_prog.bin"
    end

endmodule // GlaDOS
