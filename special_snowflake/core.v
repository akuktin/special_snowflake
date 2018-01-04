module special_snowflake_core(input RST,
			      input 	       RST_CPU_pre,
			      input 	       CLK_p,
			      input 	       CLK_n,
			      input 	       CLK_dp,
			      input 	       CLK_dn,
			      input 	       CPU_CLK,
			      // ----------------------
			      output 	       mem_iCLK_P,
			      output 	       mem_iCLK_N,
			      output 	       mem_iCKE,
			      inout 	       mem_iUDQS,
			      inout 	       mem_iLDQS,
			      inout 	       mem_iDM,
			      output 	       mem_iCS,
			      output [2:0]     mem_iCOMMAND,
			      output [12:0]    mem_iADDRESS,
			      output [1:0]     mem_iBANK,
			      inout [15:0]     mem_iDQ,
			      output 	       mem_iODT,

			      output 	       mem_dCLK_P,
			      output 	       mem_dCLK_N,
			      output 	       mem_dCKE,
			      inout 	       mem_dUDQS,
			      inout 	       mem_dLDQS,
			      inout 	       mem_dDM,
			      output 	       mem_dCS,
			      output [2:0]     mem_dCOMMAND,
			      output [12:0]    mem_dADDRESS,
			      output [1:0]     mem_dBANK,
			      inout [15:0]     mem_dDQ,
			      output 	       mem_dODT,
			      // ----------------------
			      // ----------------------
			      output reg [1:0] write_fifo_cr,
			      output reg [1:0] read_fifo_cw,
			      // ----------------------
			      input [31:0]     data0_cr,
			      input [31:0]     data1_cr,
			      input [31:0]     data2_cr,
			      input [31:0]     data3_cr,
			      input [24:0]     ancill0_cr,
			      input [24:0]     ancill1_cr,
			      input [24:0]     ancill2_cr,
			      input [24:0]     ancill3_cr,
			      input 	       write0_cr,
			      input 	       write1_cr,
			      input 	       write2_cr,
			      input 	       write3_cr,
			      input 	       int0_cr,
			      input 	       int1_cr,
			      input 	       int2_cr,
			      input 	       int3_cr,
			      // ----------------------
			      input 	       read0_cw,
			      input 	       read1_cw,
			      input 	       read2_cw,
			      input 	       read3_cw,
			      output [31:0]    data0_cw,
			      output [31:0]    data1_cw,
			      output [31:0]    data2_cw,
			      output [31:0]    data3_cw,
			      input 	       err0_cw,
			      input 	       err1_cw,
			      input 	       err2_cw,
			      input 	       err3_cw,
			      output 	       errack0_cw,
			      output 	       errack1_cw,
			      output 	       errack2_cw,
			      output 	       errack3_cw,
			      // ----------------------
			      // ----------------------
			      output [23:0]    ph_len_0,
			      output [23:0]    ph_len_1,
			      output [23:0]    ph_len_2,
			      output [23:0]    ph_len_3,
			      output 	       ph_dir_0,
			      output 	       ph_dir_1,
			      output 	       ph_dir_2,
			      output 	       ph_dir_3,
			      output 	       ph_enstb_0,
			      output 	       ph_enstb_1,
			      output 	       ph_enstb_2,
			      output 	       ph_enstb_3);
  assign mem_iODT = 1'b1;
  assign mem_dODT = 1'b1;
  // --------------------------------------------------------
  reg 					       RST_CPU;

  wire        w_read_cr, w_write_cw;
  wire [1:0]  w_read_fifo_cr, w_write_fifo_cw;
  wire [3:0]  w_care_cr;

  wire [24:0]  w_anc1_0, w_anc1_1, w_anc1_2, w_anc1_3;
  wire [24:0]  w_ancill_cr, w_ancill_sch;

  wire [31:0] w_out_cr, w_in_cw;
  wire 	      w_s0_cr, w_s1_cr, w_s2_cr, w_s3_cr;
  wire 	      w_e0_cr, w_e1_cr, w_e2_cr, w_e3_cr;
  wire 	      w_i0_cr, w_i1_cr, w_i2_cr, w_i3_cr;
  wire 	      w_f0_cw, w_f1_cw, w_f2_cw, w_f3_cw;

  wire [31:0] i_mcu_data_into, d_mcu_data_into;

  wire [11:0] hf_coll_addr_fill, hf_coll_addr_empty, mcu_coll_addr;
  wire [3:0]  hf_we_array_fill;
  wire 	      i_hf_req_access_fill, d_hf_req_access_fill,
	      i_hf_req_access_empty, d_hf_req_access_empty;

  wire 	      w_issue, w_working_fill, w_working_empty;
  wire [1:0]  w_section;
  wire [5:0]  w_count_req, w_count_sent_fill, w_count_sent_empty;
  wire [11:0] w_start_address;

  wire 	      w_irq_cr, w_abstop_cr, w_abstop_cw, w_deverr_cw;

  wire [19:0] mcu_page_addr;
  wire 	      i_mcu_algn_req, i_mcu_algn_ack,
	      d_mcu_algn_req, d_mcu_algn_ack;

  wire 	      mvblck_RST_fill, mvblck_RST_empty;
  reg 	      i_mcu_req_access, d_mcu_req_access, i_mcu_we, d_mcu_we;

  assign mcu_coll_addr = hf_coll_addr_fill | hf_coll_addr_empty;

  wire 	      ww_go, ww_ready, ww_eop, ww_frdram_deverr;
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

  ddr_memory_controler i_mcu(.CLK_n(CLK_n),
                             .CLK_p(CLK_p),
                             .CLK_dp(CLK_dp),
                             .CLK_dn(CLK_dn),
                             .RST(RST),
			     .MEM_CLK_P(mem_iCLK_P),
			     .MEM_CLK_N(mem_iCLK_N),
                             .CKE(mem_iCKE),
                             .COMMAND(mem_iCOMMAND),
                             .ADDRESS(mem_iADDRESS),
                             .BANK(mem_iBANK),
                             .DQ(mem_iDQ),
                             .UDQS(mem_iUDQS),
                             .LDQS(mem_iLDQS),
                             .DM(mem_iDM),
                             .CS(mem_iCS),
			     .refresh_strobe(refresh_strobe),
                             .rand_req_address(i_user_req_address[25:0]),
                             .rand_req_we(i_user_req_we),
			     .rand_req_we_array(i_user_we_array),
                             .rand_req(i_user_req),
                             .rand_req_ack(i_user_req_ack),
                             .rand_req_datain(i_user_req_datain),
			     .bulk_req_address({mcu_page_addr[13:0],
						mcu_coll_addr}),
			     .bulk_req_we(i_mcu_we),
			     .bulk_req_we_array(hf_we_array_fill),
			     .bulk_req(i_mcu_req_access),
			     .bulk_req_ack(),
			     .bulk_req_algn(i_mcu_algn_req),
			     .bulk_req_algn_ack(i_mcu_algn_ack),
                             .bulk_req_datain(i_mcu_data_into),
                             .user_req_dataout(i_user_req_dataout));

  ddr_memory_controler d_mcu(.CLK_n(CLK_n),
                             .CLK_p(CLK_p),
                             .CLK_dp(CLK_dp),
                             .CLK_dn(CLK_dn),
                             .RST(RST),
			     .MEM_CLK_P(mem_dCLK_P),
			     .MEM_CLK_N(mem_dCLK_N),
                             .CKE(mem_dCKE),
                             .COMMAND(mem_dCOMMAND),
                             .ADDRESS(mem_dADDRESS),
                             .BANK(mem_dBANK),
                             .DQ(mem_dDQ),
                             .UDQS(mem_dUDQS),
                             .LDQS(mem_dLDQS),
                             .DM(mem_dDM),
                             .CS(mem_dCS),
			     .refresh_strobe(refresh_strobe),
                             .rand_req_address(d_user_req_address[25:0]),
                             .rand_req_we(d_user_req_we),
			     .rand_req_we_array(d_user_we_array),
                             .rand_req(d_user_req),
                             .rand_req_ack(d_user_req_ack),
                             .rand_req_datain(d_user_req_datain),
			     .bulk_req_address({mcu_page_addr[13:0],
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
  wire 	       d_cache_force_miss;

  wire 	       RST_CACHE;
  assign RST_CACHE = RST_CPU;

  snowball_cache i_cache(.CPU_CLK(CPU_CLK),
			 .MCU_CLK(CLK_n),
			 .RST(RST_CACHE),
			 .cache_precycle_addr(i_cache_pc_addr),
			 .cache_datao(0), // CPU perspective
			 .cache_datai(i_cache_datai), // CPU perspective
			 .cache_precycle_we(1'b0),
			 .cache_busy(i_cache_busy),
			 .cache_precycle_enable(i_cache_enable),
			 .cache_precycle_force_miss(1'b0),
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
			 .dma_data_read(0),
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
			 .cache_precycle_addr(d_cache_pc_addr),
			 .cache_datao(d_cache_datao), // CPU perspective
			 .cache_datai(d_cache_datai), // CPU perspective
			 .cache_precycle_we(d_cache_we),
			 .cache_busy(d_cache_busy),
			 .cache_precycle_enable(d_cache_enable),
			 .cache_precycle_force_miss(d_cache_force_miss),
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
		 .aexm_dcache_force_miss(d_cache_force_miss),
		 // Inputs
		 .aexm_icache_datai(i_cache_datai),
		 .aexm_dcache_datai(d_cache_datai),
		 .aexm_icache_cache_busy(i_cache_busy),
		 .aexm_dcache_cache_busy(d_cache_busy));

  trans_lsab hyperfabric_switch(.CLK(CLK_n),
				.RST(RST),
				.out_0(i_mcu_data_into),
				.out_1(d_mcu_data_into),
				.out_2(w_in_cw),
				.out_3(),
				.out_4(), .out_5(),
				.out_6(), .out_7(),
				.in_0(i_user_req_dataout),
				.in_1(d_user_req_dataout),
				.in_2(w_out_cr),
				.in_3(0),
				.in_4(0), .in_5(0),
				.in_6(0), .in_7(0),
				.lsab(0),
				.isel({5'h0,w_isel}),
				.osel({8'hff,5'h0,w_osel}));

  lsab_cr lsab_in(.CLK(CLK_n),
		  .RST(RST),
		  .READ(w_read_cr),
		  .WRITE0(write0_cr),
		  .WRITE1(write1_cr),
		  .WRITE2(write2_cr),
		  .WRITE3(write3_cr),
		  .READ_FIFO(w_read_fifo_cr),
		  .WRITE_FIFO(write_fifo_cr),
		  .IN_0(data0_cr), .IN_1(data1_cr),
		  .IN_2(data2_cr), .IN_3(data3_cr),
		  .INT_IN_0(int0_cr), .INT_IN_1(int1_cr),
		  .INT_IN_2(int2_cr), .INT_IN_3(int3_cr),
		  .CAREOF_INT_0(w_careof_int), .CAREOF_INT_1(w_careof_int),
		  .CAREOF_INT_2(w_careof_int), .CAREOF_INT_3(w_careof_int),
		  .ANCILL_IN_0(ancill0_cr), .ANCILL_IN_1(ancill1_cr),
		  .ANCILL_IN_2(ancill2_cr), .ANCILL_IN_3(ancill3_cr),
		  .OUT(w_out_cr),
		  .EMPTY_0(w_e0_cr), .EMPTY_1(w_e1_cr),
		  .EMPTY_2(w_e2_cr), .EMPTY_3(w_e3_cr),
		  .STOP_0(w_s0_cr), .STOP_1(w_s1_cr),
		  .STOP_2(w_s2_cr), .STOP_3(w_s3_cr),
		  .INT_OUT_0(w_i0_cr), .INT_OUT_1(w_i1_cr),
		  .INT_OUT_2(w_i2_cr), .INT_OUT_3(w_i3_cr),
		  .ANCILL_OUT_0(w_anc1_0), .ANCILL_OUT_1(w_anc1_1),
		  .ANCILL_OUT_2(w_anc1_2), .ANCILL_OUT_3(w_anc1_3));

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
			   .LSAB_0_ANCILL(w_anc1_0),
			   .LSAB_1_ANCILL(w_anc1_1),
			   .LSAB_2_ANCILL(w_anc1_2),
			   .LSAB_3_ANCILL(w_anc1_3),
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
			   .ANCILL_OUT(w_ancill_cr),
			   .MCU_COLL_ADDRESS(hf_coll_addr_fill),
			   .MCU_WE_ARRAY(hf_we_array_fill),
			   .MCU_REQUEST_ACCESS({d_hf_req_access_fill,
						i_hf_req_access_fill}));

  lsab_cw lsab_out(.CLK(CLK_n),
		   .RST(RST),
		   .READ0(read0_cw),
		   .READ1(read1_cw),
		   .READ2(read2_cw),
		   .READ3(read3_cw),
		   .WRITE(w_write_cw),
		   .READ_FIFO(read_fifo_cw),
		   .WRITE_FIFO(w_write_fifo_cw),
		   .IN(w_in_cw),
		   .OUT_0(data0_cw),
		   .OUT_1(data1_cw),
		   .OUT_2(data2_cw),
		   .OUT_3(data3_cw),
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
			  .DEV_0_ERR(err0_cw),
			  .DEV_1_ERR(err1_cw),
			  .DEV_2_ERR(err2_cw),
			  .DEV_3_ERR(err3_cw),
			  .DEV_0_ERR_ACK(errack0_cw),
			  .DEV_1_ERR_ACK(errack1_cw),
			  .DEV_2_ERR_ACK(errack2_cw),
			  .DEV_3_ERR_ACK(errack3_cw),
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
			  .DEVICE_ERROR(w_deverr_cw),
			  .MCU_COLL_ADDRESS(hf_coll_addr_empty),
			  .MCU_REQUEST_ACCESS({d_hf_req_access_empty,
					       i_hf_req_access_empty}));

  Gremlin hyper_softcore(.CLK(CLK_n),
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
			 .IRQ_DESC(),
			 .IRQ(res_irq),
			 // ---------------------
			 .RST_MVBLCK({mvblck_RST_fill,mvblck_RST_empty}),
			 .MCU_REFRESH_STROBE(refresh_strobe),
			 .SWCH_ISEL(w_isel),
			 .SWCH_OSEL(w_osel),
			 .CAREOF_INT(w_careof_int),
			 // ---------------------
			 .BLCK_START(w_start_address),
			 .BLCK_COUNT_REQ(w_count_req),
			 .BLCK_ISSUE(w_issue),
			 .BLCK_SECTION(w_section),
			 .BLCK_COUNT_SENT(w_count_sent_fill |
					  w_count_sent_empty),
			 .BLCK_WORKING(w_working_fill | w_working_empty),
			 .BLCK_IRQ(w_irq_cr),
			 .BLCK_ABRUPT_STOP(w_abstop_cr || w_abstop_cw),
			 .BLCK_FRDRAM_DEVERR(w_deverr_cw),
			 .BLCK_ANCILL(w_ancill_cr),
			 // ---------------------
			 .MCU_PAGE_ADDR(mcu_page_addr),
			 .MCU_REQUEST_ALIGN({d_mcu_algn_req,
					     i_mcu_algn_req}),
			 .MCU_GRANT_ALIGN({d_mcu_algn_ack,
					   i_mcu_algn_ack}),
			 // ---------------------
			 .LEN_0(ph_len_0),
			 .DIR_0(ph_dir_0),
			 .EN_STB_0(ph_enstb_0),
			 .LEN_1(ph_len_1),
			 .DIR_1(ph_dir_1),
			 .EN_STB_1(ph_enstb_1),
			 .LEN_2(ph_len_2),
			 .DIR_2(ph_dir_2),
			 .EN_STB_2(ph_enstb_2),
			 .LEN_3(ph_len_3),
			 .DIR_3(ph_dir_3),
			 .EN_STB_3(ph_enstb_3));

  initial
    begin
      // WARNING!
      // FIXME!
      // Use Verilog force statements or $readmemh/$readmemb here instead
      // of the current arrangement.
      cache_vmem <= 0; cache_inhibit <= 0;
    end

  always @(posedge CLK_n)
    if (!RST)
      begin
	write_fifo_cr <= 2'h0;
	read_fifo_cw <= 2'h2;

	irq_strobe <= 0;

	i_mcu_req_access <= 0; i_mcu_we <= 0;
	d_mcu_req_access <= 0; d_mcu_we <= 0;
      end
    else
      begin
	write_fifo_cr <= write_fifo_cr +1;
	read_fifo_cw <= read_fifo_cw +1;

	if (res_irq)
	  irq_strobe <= !irq_strobe;

	i_mcu_req_access <= i_hf_req_access_fill || i_hf_req_access_empty;
	d_mcu_req_access <= d_hf_req_access_fill || d_hf_req_access_empty;
	i_mcu_we <= i_hf_req_access_fill;
	d_mcu_we <= d_hf_req_access_fill;
      end // else: !if(!RST)

  always @(posedge CPU_CLK)
    if (!RST)
      begin
	irq_strobe_slow <= 0;
	irq_strobe_slow_prev <= 0;

	RST_CPU <= 0;
      end
    else
      begin
	irq_strobe_slow <= irq_strobe;
	irq_strobe_slow_prev <= irq_strobe_slow;

	RST_CPU <= RST_CPU_pre;
      end // else: !if(!RST)

endmodule // special_snowflake_core
