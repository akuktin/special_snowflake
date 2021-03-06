`timescale 1ps/1ps

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

// Hyperfabric
`include "../hyperfabric/lsab.v"
`include "../hyperfabric/transport.v"
`include "../hyperfabric/mvblck_todram.v"
`include "../hyperfabric/mvblck_frdram.v"
`include "../hyperfabric/soft_ctrl.v"

// Special Snowflake
`include "../special_snowflake/core.v"

module test_fill_lsab(input CLK,
		      input 	    RST,
		      output [31:0] DATA0,
		      output [31:0] DATA1,
		      output [31:0] DATA2,
		      output [31:0] DATA3,
		      output 	    WRITE,
		      input [1:0]   WRITE_FIFO,
		      output 	    INT0,
		      output 	    INT1,
		      output 	    INT2,
		      output 	    INT3);
  reg [31:0] 	      test_data[4095:0];
  reg 		      test_we[4095:0],
		      test_int[4095:0];

  wire [1:0] 	      fast_i;
  reg [9:0] 	      slow_i;
  reg [11:0] 	      c;

  assign DATA0 = test_data[{slow_i,2'h0}];
  assign DATA1 = test_data[{slow_i,2'h1}];
  assign DATA2 = test_data[{slow_i,2'h2}];
  assign DATA3 = test_data[{slow_i,2'h3}];

  assign WRITE = test_we[{slow_i,fast_i}];
  assign fast_i = WRITE_FIFO;

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
      for (v=(0+14); v<(5+14); v=v+1)
	begin
	  test_we[{v[9:0],2'h1}] <= 1;
	end
      for (e=10; e<25; e=e+1)
	begin
	  test_we[{e[9:0],2'h2}] <= 1;
	end
      test_int[{10'd16,2'h2}] <= 1;
      test_int[{10'd18,2'h2}] <= 1;
    end // initial begin

  always @(posedge CLK)
    if (!RST)
      begin
	slow_i <= 0; c <= 0;
      end
    else
      begin
	if (WRITE && 0)
	  begin
	    $display("writing: %d/%d", slow_i, fast_i);
          end
        if ({slow_i,fast_i} != 4095)
	  begin
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
  reg CLK_n, CLK_dn, RST, CPU_CLK, RST_CPU, RST_CPU_pre;
  reg [31:0] gremlin_cycle;

  initial
    forever
      begin
        #1500 CLK_n <= 0;
        #1500 CLK_dn <= 0;
        #1500 CLK_n <= 1;
        #1500 CLK_dn <= 1;
      end
  initial
    forever
      begin
        #1500;
        #4500 CPU_CLK <= 1;
        #3000 CPU_CLK <= 0;
      end

  reg record = 1'b0;

  reg         transaction_just_ended;
  reg         TEST_output_lsab_cw_1, TEST_output_lsab_cw_1_dly,
	      TEST_output_lsab_cw_1_dly2;
  reg [31:0]  TEST_output_lsab_cw_1_count;
  wire [31:0] TEST_output_lsab_cw_1_data;

  reg 	      SYS_RST, long_counter_o;
  reg [7:0]   long_counter_h, long_counter_l;

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


  wire        iCLK_P, iCLK_N, iCKE, iUDQS, iLDQS, iUDM, iLDM, iCS, iODT;
  wire [2:0]  iCOMMAND;
  wire [13:0] iADDRESS;
  wire [2:0]  iBANK;
  wire [15:0] iDQ;
  wire        dCLK_P, dCLK_N, dCKE, dUDQS, dLDQS, dUDM, dLDM, dCS, dODT;
  wire [2:0]  dCOMMAND;
  wire [13:0] dADDRESS;
  wire [2:0]  dBANK;
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

  wire [23:0]  ph_len_0, ph_len_1, ph_len_2, ph_len_3;
  wire 	       ph_dir_0, ph_enstb_0, ph_dir_1, ph_enstb_1,
	       ph_dir_2, ph_enstb_2, ph_dir_3, ph_enstb_3;
  reg 	       ph_enstb_0_prev, ph_enstb_1_prev,
	       ph_enstb_2_prev, ph_enstb_3_prev;

  ddr2 i_ddr2_mem(.ck(iCLK_P),
		  .ck_n(iCLK_N),
		  .cke(iCKE),
		  .cs_n(iCS),
		  .ras_n(iCOMMAND[2]),
		  .cas_n(iCOMMAND[1]),
		  .we_n(iCOMMAND[0]),
		  .dm_rdqs({iUDM,iLDM}),
		  .ba(iBANK),
		  .addr(iADDRESS[12:0]), // simulation limitation
		  .dq(iDQ),
		  .dqs({iUDQS,iLDQS}),
		  .dqs_n(),
		  .rdqs_n(),
		  .odt(iODT));

  ddr2 d_ddr2_mem(.ck(dCLK_P),
		  .ck_n(dCLK_N),
		  .cke(dCKE),
		  .cs_n(dCS),
		  .ras_n(dCOMMAND[2]),
		  .cas_n(dCOMMAND[1]),
		  .we_n(dCOMMAND[0]),
		  .dm_rdqs({dUDM,dLDM}),
		  .ba(dBANK),
		  .addr(dADDRESS[12:0]), // simulation limitation
		  .dq(dDQ),
		  .dqs({dUDQS,dLDQS}),
		  .dqs_n(),
		  .rdqs_n(),
		  .odt(dODT));

  test_fill_lsab lsab_write(.CLK(CLK_n),
			    .RST(RST),
			    .DATA0(w_data0_cr), .DATA1(w_data1_cr),
			    .DATA2(w_data2_cr), .DATA3(w_data3_cr),
			    .WRITE(w_write_cr),
			    .WRITE_FIFO(w_write_fifo_cr),
			    .INT0(w_int0_cr), .INT1(w_int1_cr),
			    .INT2(w_int2_cr), .INT3(w_int3_cr));

  special_snowflake_core core(.RST_MASTER(SYS_RST),
			      .RST_CPU_TRANS(RST_CPU_pre),
			      .CLK_n(CLK_n),
			      .CLK_dn(CLK_dn),
			      .CPU_CLK(CPU_CLK),
			      // ----------------------
			      .mem_iCLK_P(iCLK_P),
			      .mem_iCLK_N(iCLK_N),
			      .mem_iCKE(iCKE),
			      .mem_iUDQS(iUDQS),
			      .mem_iLDQS(iLDQS),
			      .mem_iUDM(iUDM),
			      .mem_iLDM(iLDM),
			      .mem_iCS(iCS),
			      .mem_iCOMMAND(iCOMMAND),
			      .mem_iADDRESS(iADDRESS),
			      .mem_iBANK(iBANK),
			      .mem_iDQ(iDQ),
			      .mem_iODT(iODT),
			      .mem_dCLK_P(dCLK_P),
			      .mem_dCLK_N(dCLK_N),
			      .mem_dCKE(dCKE),
			      .mem_dUDQS(dUDQS),
			      .mem_dLDQS(dLDQS),
			      .mem_dUDM(dUDM),
			      .mem_dLDM(dLDM),
			      .mem_dCS(dCS),
			      .mem_dCOMMAND(dCOMMAND),
			      .mem_dADDRESS(dADDRESS),
			      .mem_dBANK(dBANK),
			      .mem_dDQ(dDQ),
			      .mem_dODT(dODT),
			      // ----------------------
			      // ----------------------
			      .write_fifo_cr(w_write_fifo_cr),
			      .read_fifo_cw(w_read_fifo_cw),
			      // ----------------------
			      .data0_cr(w_data0_cr),
			      .data1_cr(w_data1_cr),
			      .data2_cr(w_data2_cr),
			      .data3_cr(w_data3_cr),
			      .ancill0_cr(24'h3),
			      .ancill1_cr(24'h5),
			      .ancill2_cr(24'h2),
			      .ancill3_cr(24'h7),
			      .write0_cr(w_write_cr),
			      .write1_cr(w_write_cr),
			      .write2_cr(w_write_cr),
			      .write3_cr(w_write_cr),
			      .int0_cr(w_int0_cr),
			      .int1_cr(w_int1_cr),
			      .int2_cr(w_int2_cr),
			      .int3_cr(w_int3_cr),
			      // ----------------------
			      .read0_cw(1),
			      .read1_cw(TEST_output_lsab_cw_1),
			      .read2_cw(1),
			      .read3_cw(1),
			      .data0_cw(),
			      .data1_cw(TEST_output_lsab_cw_1_data),
			      .data2_cw(),
			      .data3_cw(),
			      .err0_cw(0),
			      .err1_cw(0),
			      .err2_cw(0),
			      .err3_cw(0),
			      .errack0_cw(),
			      .errack1_cw(),
			      .errack2_cw(),
			      .errack3_cw(),
			      // ----------------------
			      // ----------------------
			      .ph_len_0(),
			      .ph_len_1(),
			      .ph_len_2(),
			      .ph_len_3(),
			      .ph_dir_0(),
			      .ph_dir_1(),
			      .ph_dir_2(),
			      .ph_dir_3(),
			      .ph_enstb_0(),
			      .ph_enstb_1(),
			      .ph_enstb_2(),
			      .ph_enstb_3());


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
      RST <= 0; RST_CPU <= 0; gremlin_cycle <= 0;
      RST_CPU_pre <= 0; SYS_RST <= 0;
      #14875 RST <= 1;
      #400000000;
      RST_CPU_pre <= 1;


      #2000000;
      #20000000;
      $display("addr %x we %x wea %x req %x algnr %x algna %x",
	       {core.mcu_page_addr,mcu_coll_addr}, core.i_mcu_we,
	       core.hf_we_array_fill, core.i_mcu_req_access,
	       core.i_mcu_algn_req, core.i_mcu_algn_ack);
      $display("state %x,%x,%x reftime %x",
	       core.i_mcu.interdictor_tracker.SOME_PAGE_ACTIVE,
	       core.i_mcu.interdictor_tracker.refresh_time,
	       core.i_mcu.interdictor_tracker.actv_timeout[2],
	       core.i_mcu.interdictor_tracker.refresh_time);
      #20000 $display("timeout"); $finish;
    end

  reg i_mcu_req_access_prev, refresh_strobe_prev;
  reg [63:0] ctr, cpu_ctr;
  initial
    begin
      cache_vmem <= 0; cache_inhibit <= 0;
    end

  always @(posedge CLK_n)
    begin
//      PLL_RESET <= 1;
//      reg_FRST_RST <= FRST_RST;
//      reg_SCND_RST <= SCND_RST;

//      if (! (reg_FRST_RST && reg_SCND_RST))
      if (!RST)
	begin
	  long_counter_h <= 0;
	  long_counter_l <= 0;
	  long_counter_o <= 0;
	end
      else
	begin
	  {long_counter_o,long_counter_l} <= long_counter_l +1;
	  if (long_counter_o)
	    long_counter_h <= long_counter_h +1;
	  if (long_counter_h == 8'hff)
	    SYS_RST <= 1;
	end
    end

/*
  always @(CLK_dn)
    begin
      if (((dUDM == 1'b0) || (dUDM == 1'b1)) ||
	  core.d_mcu.data_driver.dqs_z_ctrl)
	begin
	  $display("direct observation d dqs %x dm %x data %x",
		   {dUDQS,dLDQS}, {dUDM,dLDM}, dDQ);
	end
      if (((iUDM == 1'b0) || (iUDM == 1'b1)) ||
	  core.i_mcu.data_driver.dqs_z_ctrl)
	begin
	  $display("direct observation i dqs %x dm %x data %x",
		   {iUDQS,iLDQS}, {iUDM,iLDM}, iDQ);
	end
    end
 */

  always @(posedge CLK_n)
    if (!RST)
      begin
	ctr <= 0;
	ph_enstb_0_prev <= 0; ph_enstb_1_prev <= 0;
	ph_enstb_2_prev <= 0; ph_enstb_3_prev <= 0;
	transaction_just_ended <= 0;
	TEST_output_lsab_cw_1 <= 0; TEST_output_lsab_cw_1_count <= 0;
	TEST_output_lsab_cw_1_dly <= 0; TEST_output_lsab_cw_1_dly2 <= 0;
      end
    else
      begin
	gremlin_cycle <= gremlin_cycle + core.hyper_softcore.RST;

        if (core.hyper_softcore.instr_o[11:8] == 4'h8 && 0)
          $display("wait cycle   acc %x", core.hyper_softcore.accumulator);
/*
	if (core.hyper_softcore.trans_activate &&
	    (! (core.hyper_softcore.trans_active ||
		core.hyper_softcore.ready_trans)) &&
	    (core.hyper_softcore.trg_gb_0 ||
	     core.hyper_softcore.trg_gb_1 ||
	     (core.hyper_softcore.time_mb &&
	      !core.hyper_softcore.trg_gb_0)))
	  begin
	    $display("=====--------> %t STARTING TRANSACTION trg %x at %x",
		     $time, {core.hyper_softcore.trg_gb_0,
			     core.hyper_softcore.trg_gb_1,
			     core.hyper_softcore.time_mb,
			     !core.hyper_softcore.trg_gb_0},
		     core.hyper_softcore.active_trans);
	  end // if (core.hyper_softcore.trans_activate &&...
*/
	if ((core.hyper_softcore.trg_gb_0 ||
	     core.hyper_softcore.trg_gb_1) && 0)
	  begin
	    $display("gremlin transaction trigger %x mem_req %x/%x",
		     {core.hyper_softcore.trg_gb_1,
		      core.hyper_softcore.trg_gb_0},
		     core.hyper_softcore.MCU_REQUEST_ALIGN,
		     core.hyper_softcore.MCU_GRANT_ALIGN);
	  end
	if ((core.hyper_softcore.instr_o[11:8] == 4'hb) &&
	    (!core.hyper_softcore.instr_o[14]) &&
	    (core.hyper_softcore.accumulator[13:2] != 0) && 0)
	  begin
	    $display("gremlin transaction order inst/acc %x/%x",
		     core.hyper_softcore.instr_o,
		     core.hyper_softcore.accumulator);
	  end
	if (core.hyper_softcore.ready_trans && 0)
	  begin
	    $display("begin trans %x addr %x start %x (%x %x %x  %x %x %x)",
		     core.hyper_softcore.active_trans_thistrans,
		     core.hyper_softcore.MCU_PAGE_ADDR << 1,
		     core.hyper_softcore.BLCK_START,

		     core.hyper_softcore.reg_page_hi_0,
		     {core.hyper_softcore.reg_page_lo_0,
		      core.hyper_softcore.reg_start_0},
		     {core.hyper_softcore.reg_blck_sec_0,
		      core.hyper_softcore.reg_count_req_0,
		      core.hyper_softcore.reg_rdmem_op_0,
		      core.hyper_softcore.reg_opon_data_0},

		     core.hyper_softcore.reg_page_hi_1,
		     {core.hyper_softcore.reg_page_lo_1,
		      core.hyper_softcore.reg_start_1},
		     {core.hyper_softcore.reg_blck_sec_1,
		      core.hyper_softcore.reg_count_req_1,
		      core.hyper_softcore.reg_rdmem_op_1,
		      core.hyper_softcore.reg_opon_data_1});
	  end
/*
	if (((core.hyper_softcore.MCU_REQUEST_ALIGN[0] &&
	      core.hyper_softcore.MCU_GRANT_ALIGN[0]) ||
	     (core.hyper_softcore.MCU_REQUEST_ALIGN[1] &&
	      core.hyper_softcore.MCU_GRANT_ALIGN[1])) &&
	    core.hyper_softcore.trans_active)
	  begin
	    $display("=====--------> trans executes! CTR %x time %t",
		     ctr, $time);
	  end
 */
/*
          begin
	    $display("d_mcu addr_r %x pWE_r %x pRAR %x GAR %x WAR %x\n      addr_b %x pWE_b %x pRAB %x GAB %x pRLB %x GLB %x pWEB %x",
		     core.d_mcu.interdictor_tracker.ADDRESS_RAND,
		     core.d_mcu.interdictor_tracker.port_WE_RAND,
		     core.d_mcu.interdictor_tracker.port_REQUEST_ACCESS_RAND,
		     core.d_mcu.interdictor_tracker.GRANT_ACCESS_RAND,
		     core.d_mcu.interdictor_tracker.WE_ARRAY_RAND,

		     core.d_mcu.interdictor_tracker.port_ADDRESS_BULK,
		     core.d_mcu.interdictor_tracker.port_WE_BULK,
		     core.d_mcu.interdictor_tracker.port_REQUEST_ACCESS_BULK,
		     core.d_mcu.interdictor_tracker.GRANT_ACCESS_BULK,
		     core.d_mcu.interdictor_tracker.port_REQUEST_ALIGN_BULK,
		     core.d_mcu.interdictor_tracker.GRANT_ALIGN_BULK,
		     core.d_mcu.interdictor_tracker.port_WE_ARRAY_BULK);
	  end
 */
	if (core.hyper_softcore.RST && 0)
          begin
	    $display("i_mcu addr_r %x pWE_r %x pRAR %x GAR %x WAR %x\n      addr_b %x pWE_b %x pRAB %x GAB %x pRLB %x GLB %x pWEB %x",
		     core.i_mcu.interdictor_tracker.ADDRESS_RAND,
		     core.i_mcu.interdictor_tracker.port_WE_RAND,
		     core.i_mcu.interdictor_tracker.port_REQUEST_ACCESS_RAND,
		     core.i_mcu.interdictor_tracker.GRANT_ACCESS_RAND,
		     core.i_mcu.interdictor_tracker.WE_ARRAY_RAND,

		     core.i_mcu.interdictor_tracker.port_ADDRESS_BULK,
		     core.i_mcu.interdictor_tracker.port_WE_BULK,
		     core.i_mcu.interdictor_tracker.port_REQUEST_ACCESS_BULK,
		     core.i_mcu.interdictor_tracker.GRANT_ACCESS_BULK,
		     core.i_mcu.interdictor_tracker.port_REQUEST_ALIGN_BULK,
		     core.i_mcu.interdictor_tracker.GRANT_ALIGN_BULK,
		     core.i_mcu.interdictor_tracker.port_WE_ARRAY_BULK);
	  end


	if (core.hyper_softcore.blck_working_prev &&
	    !core.hyper_softcore.BLCK_WORKING)
	  begin
	    $display("end trans %x -- %x, %x||%x",
		     core.hyper_softcore.BLCK_COUNT_SENT,
		     core.hyper_softcore.BLCK_IRQ,
		     core.hyper_softcore.BLCK_ABRUPT_STOP,
		     core.hyper_softcore.BLCK_FRDRAM_DEVERR);
	    $display("transactions ends! CTR %x", ctr);
	    transaction_just_ended <= 1;
	    TEST_output_lsab_cw_1 <= 1;
	    TEST_output_lsab_cw_1_count <= 0;
	  end // if (core.hyper_softcore.blck_working_prev &&...
	else
	  transaction_just_ended <= 0;
	if (TEST_output_lsab_cw_1 && (w_read_fifo_cw == 2'h1))
	  begin
	    TEST_output_lsab_cw_1_count <= TEST_output_lsab_cw_1_count +1;
	    if (TEST_output_lsab_cw_1_count >= 2)
	      TEST_output_lsab_cw_1 <= 0;
	    TEST_output_lsab_cw_1_dly <= 1;
	  end
	else
	  begin
	    TEST_output_lsab_cw_1_dly <= 0;
	  end
	TEST_output_lsab_cw_1_dly2 <= TEST_output_lsab_cw_1_dly;
	if (TEST_output_lsab_cw_1_dly2)
	  $display("lsab_cw data_out %x",
		   TEST_output_lsab_cw_1_data);

	if (transaction_just_ended && 0)
	  begin
	    $display("count_sent %x", core.hyper_softcore.BLCK_COUNT_SENT);
	  end

/*
	if (core.hyper_softcore.write_output_reg)
	  begin
	    $display("sc %x bc %x trgs %x",
		     core.hyper_softcore.small_carousel,
		     core.hyper_softcore.big_carousel,
		     {core.hyper_softcore.trg_gb_0,
		      core.hyper_softcore.trg_gb_1,
		      core.hyper_softcore.time_mb,
		      core.hyper_softcore.time_rfrs});
	  end
 */
/*
        if (core.hyper_softcore.d_w_en_cpu)
	  $display("we %x wec %x wes %x iO %x addrc %x datac %x",
		   core.hyper_softcore.d_w_en, core.hyper_softcore.d_w_en_cpu,
		   core.hyper_softcore.d_w_en_sys,
		   core.hyper_softcore.instr_o[11:8],
		   {3'h0,core.hyper_softcore.ADDR_CPU,
		    core.hyper_softcore.low_addr_bits_w},
		   core.hyper_softcore.from_cpu_word);
 */
/*
	if (core.fill.RST)
	  begin
	    if (core.fill.ISSUE && ! core.fill.am_working)
	      begin
		$display("activating hyper_mvblck_todram (FILL) module SECTION %x",
			 core.fill.SECTION);
	      end
	    if (!core.fill.stop_n && core.fill.am_working)
	      begin
		$display("deactivating hyper_mvblck_todram (FILL) module");
	      end
	    if (core.fill.trigger && core.fill.am_working && 0)
	      $display("we_arr %x coll_addr %x req_acc %x",
		       {core.fill.stop_prev_n,core.fill.stop_prev_n,
			core.fill.stop_n,core.fill.stop_n},
		       {core.fill.track_addr[11:1],1'b0},
		       core.fill.DRAM_SEL);
	  end

	if (core.empty.RST)
	  begin
	    if (core.empty.ISSUE && ! core.empty.am_working)
	      begin
		$display("activating hyper_mvblck_frdram (EMPTY) SEC %x %t",
			 core.empty.SECTION, $time);
	      end
	  end

	if (core.lsab_out.we)
	  begin
	    $display("lsab_out we %x waddr %x wdata %x",
		     core.lsab_out.we, core.lsab_out.write_addr,
		     core.lsab_out.IN);
	  end
	if (core.lsab_out.re || core.lsab_out.re_prev)
	  begin
	    $display("lsab_out re/p %x raddr %x rdata %x",
		     {core.lsab_out.re,core.lsab_out.re_prev},
		     core.lsab_out.read_addr, core.lsab_out.out_mem);
	  end
 */

	ph_enstb_0_prev <= core.ph_enstb_0;
	ph_enstb_1_prev <= core.ph_enstb_1;
	ph_enstb_2_prev <= core.ph_enstb_2;
	ph_enstb_3_prev <= core.ph_enstb_3;

	if (ph_enstb_0_prev ^ core.ph_enstb_0)
	  $display("ISSUE 0: len %d dir %x", core.ph_len_0, core.ph_dir_0);
	if (ph_enstb_1_prev ^ core.ph_enstb_1)
	  $display("ISSUE 1: len %d dir %x", core.ph_len_1, core.ph_dir_1);
	if (ph_enstb_2_prev ^ core.ph_enstb_2)
	  $display("ISSUE 2: len %d dir %x", core.ph_len_2, core.ph_dir_2);
	if (ph_enstb_3_prev ^ core.ph_enstb_3)
	  $display("ISSUE 3: len %d dir %x", core.ph_len_3, core.ph_dir_3);

	ctr <= ctr+1;
	i_mcu_req_access_prev <= core.i_mcu_req_access;
	refresh_strobe_prev <= core.refresh_strobe;

	if (core.lsab_in.we && 0)
	  $display("LSAB wr %x addr %x data %x", core.lsab_in.WRITE_FIFO,
		   core.lsab_in.write_addr, core.lsab_in.in_mem);

	if (core.d_mcu_req_access)
	  begin
	    $display("MCU we %x wea %x",
		     core.d_mcu_we, core.hf_we_array_fill);
	  end

	if (core.fill.RST && !core.fill.am_working && 0)
	  begin
	    $display("@ start_addr %x",
		     core.w_start_address);
	  end
//	if (core.fill.RST && core.fill.am_working && 1)
	if (core.d_mcu.bulk_req_algn && 0)
	  begin
	    $display("@ %d i_fl %x i_ep %x d_fl %x d_ep %x", ctr,
		     core.i_hf_req_access_fill,
		     core.i_hf_req_access_empty,
		     core.d_hf_req_access_fill,
		     core.d_hf_req_access_empty);
	    $display("addr %x we %x wea %x dt %x req %x algnr %x algna %x",
		     {core.mcu_page_addr,core.mcu_coll_addr},
		     core.d_mcu_we,
		     core.hf_we_array_fill,
		     core.d_mcu.data_driver.port_DATA_W,
		     core.d_mcu_req_access,
		     core.d_mcu_algn_req, core.d_mcu_algn_ack);

	    $display("wm %x RAB %x web %x RAR %X wer %x",
		     core.d_mcu.interdictor_tracker.write_match,
		     core.d_mcu.interdictor_tracker.REQUEST_ACCESS_BULK,
		     core.d_mcu.interdictor_tracker.WE_BULK,
		     core.d_mcu.interdictor_tracker.REQUEST_ACCESS_RAND,
		     core.d_mcu.interdictor_tracker.WE_RAND);
/*
	    $display("ss %x chp_n %x (%x %x %x %x)",
		     core.d_mcu.interdictor_tracker.second_stroke,
		     !core.d_mcu.interdictor_tracker.change_possible_n,
		     {core.d_mcu.interdictor_tracker.REQUEST_ACCESS_RAND,
		      core.d_mcu.interdictor_tracker.REQUEST_ACCESS_BULK,
		      core.d_mcu.interdictor_tracker.REQUEST_ALIGN_BULK},
		     core.d_mcu.interdictor_tracker.REQUEST_ACCESS_BULK,
		     core.d_mcu.interdictor_tracker.refresh_time,
		     {core.d_mcu.interdictor_tracker.REQUEST_ALIGN_BULK_dly,
		      core.d_mcu.interdictor_tracker.GRANT_ALIGN_BULK});
 */
	  end // if (core.fill.RST && core.fill.am_working)

	if (core.d_mcu.interdictor_tracker.issue_com && 0)
	  if (core.d_mcu.interdictor_tracker.command == 3'b100) // `WRTE
	    $display("wm %x wa %x RAB %x RAR %x WB %x WR %x WAB %x WAR %x",
		     core.d_mcu.interdictor_tracker.write_match,
		     core.d_mcu.interdictor_tracker.we_array,
		     core.d_mcu.interdictor_tracker.REQUEST_ACCESS_BULK,
		     core.d_mcu.interdictor_tracker.REQUEST_ACCESS_RAND,
		     core.d_mcu.interdictor_tracker.WE_BULK,
		     core.d_mcu.interdictor_tracker.WE_RAND,
		     core.d_mcu.interdictor_tracker.WE_ARRAY_BULK,
		     core.d_mcu.interdictor_tracker.WE_ARRAY_RAND);

//	if (core.fill.RST && core.fill.am_working &&
//	    core.d_mcu.interdictor_tracker.issue_com)
	if (!core.d_mcu.interdictor_tracker.second_stroke)
	  begin
	    $display("d cmd %x addr %x bank %x we %x data %x predata %x",
//		     core.d_mcu.interdictor_tracker.command,
//		     core.d_mcu.interdictor_tracker.address_in,
		     core.d_mcu.interdictor_tracker.COMMAND_REG,
		     core.d_mcu.interdictor_tracker.ADDRESS_REG,
		     core.d_mcu.interdictor_tracker.BANK_REG,
		     core.d_mcu.data_driver.WE_ARRAY,
		     core.d_mcu.data_driver.DATA_W,
		     core.d_mcu.data_driver.dq_predriver);
	  end // if (!core.d_mcu.interdictor_tracker.second_stroke)


	if (!core.i_mcu.interdictor_tracker.second_stroke)
	  begin
	    $display("i cmd %x addr %x bank %x we %x data %x predata %x",
//		     core.i_mcu.interdictor_tracker.command,
//		     core.i_mcu.interdictor_tracker.address_in,
		     core.i_mcu.interdictor_tracker.COMMAND_REG,
		     core.i_mcu.interdictor_tracker.ADDRESS_REG,
		     core.i_mcu.interdictor_tracker.BANK_REG,
		     core.i_mcu.data_driver.WE_ARRAY,
		     core.i_mcu.data_driver.DATA_W,
		     core.i_mcu.data_driver.dq_predriver);
	  end // if (!core.i_mcu.interdictor_tracker.second_stroke)

/*
	if (!core.i_mcu.interdictor_tracker.second_stroke)
	  begin
	    $display("i cmd %x addr %x bank %x we %x data %x predata %x",
		     iCOMMAND, iADDRESS, iBANK,
		     core.i_mcu.data_driver.WE_ARRAY,
		     core.i_mcu.data_driver.DATA_W,
		     core.i_mcu.data_driver.dq_predriver);
	  end // if (!core.i_mcu.interdictor_tracker.second_stroke)

	if (core.lsab_in.re_prev)
	  $display("lsb_do %x swc_is %x swc_dc %x swx_os %x swc_do %x",
		   core.w_out_cr,
		   core.hyperfabric_switch.isel,
		   core.hyperfabric_switch.fan_block_0,
		   core.hyperfabric_switch.osel,
		   core.hyperfabric_switch.out_1);

        if (core.d_mcu.interdictor_tracker.SOME_PAGE_ACTIVE && 0)
          begin
            $display("ic %x icop %x icvr %x RAR %x Wr %x",
                     core.d_mcu.interdictor_tracker.issue_com,
                     core.d_mcu.interdictor_tracker.issue_enable_on_page,
                     core.d_mcu.interdictor_tracker.issue_enable_override,
                     core.d_mcu.interdictor_tracker.REQUEST_ACCESS_RAND,
                     core.d_mcu.interdictor_tracker.WE_RAND);
            $display("cpra %x cpal %x cprd %x",
                     core.d_mcu.interdictor_tracker.correct_page_rand,
                     core.d_mcu.interdictor_tracker.correct_page_algn,
                     core.d_mcu.interdictor_tracker.correct_page_rdy);
	    $display("wPd %x cntr %x tnc %x tdc %x cp %x SPA %x siw %x RT %x",
		     core.d_mcu.interdictor_tracker.want_PRCH_delayable,
		     {core.d_mcu.interdictor_tracker.do_extra_pass,
		      core.d_mcu.interdictor_tracker.counter},
		     core.d_mcu.interdictor_tracker.timeout_norm_comp_n,
		     core.d_mcu.interdictor_tracker.timeout_dlay_comp_n,
		     core.d_mcu.interdictor_tracker.change_possible_w_n,
		     core.d_mcu.interdictor_tracker.SOME_PAGE_ACTIVE,
		     core.d_mcu.interdictor_tracker.state_is_write,
		     core.d_mcu.interdictor_tracker.refresh_time);
            $display("-----------------------------------------------------");
          end
 */
      end

  always @(posedge CPU_CLK)
    if (!RST)
      begin
	cpu_ctr <= 0;
      end
    else
      begin
      cpu_ctr <= cpu_ctr +RST_CPU;
      RST_CPU <= RST_CPU_pre;
      if (core.cpu.sys_int_i)
	begin
	  $display("INTERRUPT! DESC %x",
		   core.hyper_softcore.IRQ_DESC);
	end
      if (core.cpu.ibuf.cpu_interrupt)
	$display("interrupt d stage");
      if (core.cpu.ibuf.issued_interrupt)
	$display("interrupt x stage");

/*
      if (core.d_cache.cache_vld && (! core.d_cache.cache_cycle_we))
	  begin
	    if (core.d_cache.cache_hit)
	      begin
		$display("####### option 1 %x", core.d_cache.data_cache);
	      end
	    else if (core.d_cache.cache_same_word_read)
	      begin
		$display("####### option 2 %x", core.d_cache.data_mcu_trans);
	      end
	    else
	      begin
		$display("####### option 3 %x", core.d_cache.data_mcu_trans_other);
	      end
	  end
	else if (core.d_cache.mcu_responded)
	  begin
	    $display("####### option 4 %x", core.d_cache.data_mcu_trans);
	  end
      if (core.d_cache.mem_lookup)
	begin
	  $display("### mem_lookup cv %x wMF %x ch %x gh %x ccw %x mla %x ct %x",
		   core.d_cache.cache_vld,
		   core.d_cache.w_MMU_FAULT,
		   core.d_cache.cache_hit,
		   core.d_cache.ghost_hit,
		   core.d_cache.cache_cycle_we,
		   core.d_cache.mandatory_lookup_act,
		   core.d_cache.cache_tlb);
	end // if (core.d_cache.mem_lookup)
 */
/*
      if ((core.d_cache.mcu_responded_trans ^
	   core.d_cache.mcu_responded_reg) &&
	  !core.d_cache.mcu_responded)
	begin
	  $display("mrt %x mrr %x mr%",
		   core.d_cache.mcu_responded_trans,
		   core.d_cache.mcu_responded_reg,
		   core.d_cache.mcu_responded);
	end
 */

      if ((core.cpu.regf.RAM_D.ram.r_data[31] == 32'd0) ||
          (core.hyper_softcore.data_mem.ram.r_data[255] != 16'd0) ||
	  (core.hyper_softcore.index_reg == 16'h00b5))
	begin
	  $display("halting CTR %x CPUCTR %x", ctr, cpu_ctr);
          $display("acc %x bc %x sc %x",
		   core.hyper_softcore.accumulator,
		   core.hyper_softcore.big_carousel,
		   core.hyper_softcore.small_carousel);
          $display("input_reg  %x %x       %x %x",
		   core.hyper_softcore.input_reg_0[0],
		   core.hyper_softcore.input_reg_0[1],
		   core.hyper_softcore.input_reg_1[0],
		   core.hyper_softcore.input_reg_1[1]);
          $display("output_reg %x %x %x  %x %x %x",
		   core.hyper_softcore.reg_page_hi_0,
		   {core.hyper_softcore.reg_page_lo_0,
		    core.hyper_softcore.reg_start_0},
		   {core.hyper_softcore.reg_blck_sec_0,
		    core.hyper_softcore.reg_count_req_0,
		    core.hyper_softcore.reg_rdmem_op_0,
		    core.hyper_softcore.reg_opon_data_0},

		   core.hyper_softcore.reg_page_hi_1,
		   {core.hyper_softcore.reg_page_lo_1,
		    core.hyper_softcore.reg_start_1},
		   {core.hyper_softcore.reg_blck_sec_1,
		    core.hyper_softcore.reg_count_req_1,
		    core.hyper_softcore.reg_rdmem_op_1,
		    core.hyper_softcore.reg_opon_data_1});
          for (i=0; i<(256/8); i=i+1)
            begin
              $display("%x: %x %x %x %x  %x %x %x %x", (i*8),
                core.hyper_softcore.data_mem.ram.r_data[(i*8)][15:0],
                core.hyper_softcore.data_mem.ram.r_data[(i*8)+1][15:0],
                core.hyper_softcore.data_mem.ram.r_data[(i*8)+2][15:0],
                core.hyper_softcore.data_mem.ram.r_data[(i*8)+3][15:0],
                core.hyper_softcore.data_mem.ram.r_data[(i*8)+4][15:0],
                core.hyper_softcore.data_mem.ram.r_data[(i*8)+5][15:0],
                core.hyper_softcore.data_mem.ram.r_data[(i*8)+6][15:0],
                core.hyper_softcore.data_mem.ram.r_data[(i*8)+7][15:0]);
            end
	  $display("wMSR %x", core.cpu.xecu.wMSR);
	  $display(" r0: %x,  r1: %x,  r2: %x  r3: %x",
		   core.cpu.regf.RAM_D.ram.r_data[0], core.cpu.regf.RAM_D.ram.r_data[1],
		   core.cpu.regf.RAM_D.ram.r_data[2], core.cpu.regf.RAM_D.ram.r_data[3]);
	  $display(" r4: %x,  r5: %x,  r6: %x  r7: %x",
		   core.cpu.regf.RAM_D.ram.r_data[4], core.cpu.regf.RAM_D.ram.r_data[5],
		   core.cpu.regf.RAM_D.ram.r_data[6], core.cpu.regf.RAM_D.ram.r_data[7]);
	  $display(" r8: %x,  r9: %x, r10: %x r11: %x",
		   core.cpu.regf.RAM_D.ram.r_data[8], core.cpu.regf.RAM_D.ram.r_data[9],
		   core.cpu.regf.RAM_D.ram.r_data[10], core.cpu.regf.RAM_D.ram.r_data[11]);
	  $display("r12: %x, r13: %x, r14: %x r15: %x",
		   core.cpu.regf.RAM_D.ram.r_data[12], core.cpu.regf.RAM_D.ram.r_data[13],
		   core.cpu.regf.RAM_D.ram.r_data[14], core.cpu.regf.RAM_D.ram.r_data[15]);
	  $display("r16: %x, r17: %x, r18: %x r19: %x",
		   core.cpu.regf.RAM_D.ram.r_data[16], core.cpu.regf.RAM_D.ram.r_data[17],
		   core.cpu.regf.RAM_D.ram.r_data[18], core.cpu.regf.RAM_D.ram.r_data[19]);
	  $display("r20: %x, r21: %x, r22: %x r23: %x",
		   core.cpu.regf.RAM_D.ram.r_data[20], core.cpu.regf.RAM_D.ram.r_data[21],
		   core.cpu.regf.RAM_D.ram.r_data[22], core.cpu.regf.RAM_D.ram.r_data[23]);
	  $display("r24: %x, r25: %x, r26: %x r27: %x",
		   core.cpu.regf.RAM_D.ram.r_data[24], core.cpu.regf.RAM_D.ram.r_data[25],
		   core.cpu.regf.RAM_D.ram.r_data[26], core.cpu.regf.RAM_D.ram.r_data[27]);
	  $display("r28: %x, r29: %x, r30: %x r31: %x",
		   core.cpu.regf.RAM_D.ram.r_data[28], core.cpu.regf.RAM_D.ram.r_data[29],
		   core.cpu.regf.RAM_D.ram.r_data[30], core.cpu.regf.RAM_D.ram.r_data[31]);
	  $finish;
	end
/*
	  $display(" r0: %x,  r1: %x,  r2: %x  r3: %x",
		   core.cpu.regf.RAM_D.ram.r_data[0], core.cpu.regf.RAM_D.ram.r_data[1],
		   core.cpu.regf.RAM_D.ram.r_data[2], core.cpu.regf.RAM_D.ram.r_data[3]);
	  $display(" r4: %x,  r5: %x,  r6: %x  r7: %x",
		   core.cpu.regf.RAM_D.ram.r_data[4], core.cpu.regf.RAM_D.ram.r_data[5],
		   core.cpu.regf.RAM_D.ram.r_data[6], core.cpu.regf.RAM_D.ram.r_data[7]);
	  $display(" r8: %x,  r9: %x, r10: %x r11: %x",
		   core.cpu.regf.RAM_D.ram.r_data[8], core.cpu.regf.RAM_D.ram.r_data[9],
		   core.cpu.regf.RAM_D.ram.r_data[10], core.cpu.regf.RAM_D.ram.r_data[11]);
	  $display("r12: %x, r13: %x, r14: %x r15: %x",
		   core.cpu.regf.RAM_D.ram.r_data[12], core.cpu.regf.RAM_D.ram.r_data[13],
		   core.cpu.regf.RAM_D.ram.r_data[14], core.cpu.regf.RAM_D.ram.r_data[15]);
	  $display("r16: %x, r17: %x, r18: %x r19: %x",
		   core.cpu.regf.RAM_D.ram.r_data[16], core.cpu.regf.RAM_D.ram.r_data[17],
		   core.cpu.regf.RAM_D.ram.r_data[18], core.cpu.regf.RAM_D.ram.r_data[19]);
	  $display("r20: %x, r21: %x, r22: %x r23: %x",
		   core.cpu.regf.RAM_D.ram.r_data[20], core.cpu.regf.RAM_D.ram.r_data[21],
		   core.cpu.regf.RAM_D.ram.r_data[22], core.cpu.regf.RAM_D.ram.r_data[23]);
	  $display("r24: %x, r25: %x, r26: %x r27: %x",
		   core.cpu.regf.RAM_D.ram.r_data[24], core.cpu.regf.RAM_D.ram.r_data[25],
		   core.cpu.regf.RAM_D.ram.r_data[26], core.cpu.regf.RAM_D.ram.r_data[27]);
	  $display("r28: %x, r29: %x, r30: %x r31: %x",
		   core.cpu.regf.RAM_D.ram.r_data[28], core.cpu.regf.RAM_D.ram.r_data[29],
		   core.cpu.regf.RAM_D.ram.r_data[30], core.cpu.regf.RAM_D.ram.r_data[31]);
*/
      if (RST_CPU_pre && 0)
	begin
/*
	 if (core.cpu.xecu.fMTS)
	   $display("MTS: xMSR_IE %x xMSR_C %x",
		    core.cpu.xecu.xMSR_IE, core.cpu.xecu.xMSR_C);
 */
//      $display("c_vld %x req_tag %x ^ rsp %x idx %x en %x/%x",
//	       core.i_cache.cachehit_vld, core.i_cache.req_tag,
//	       core.i_cache.vmem_rsp_tag, core.i_cache.tlb_idx_w,
//	       core.i_cache_enable,
//	       {core.i_cache_busy_n,(core.RST & (~core.RST_CPU)),1'b1});
/*
	  $display("i_pc_addr %x i_c_addr %x i_di %x i_e %x",
		   core.i_cache_pc_addr, core.i_cache.cache_cycle_addr,
                   core.i_cache_datai, core.i_cache_enable);
 */
/*
	  $display("i_pc_addr %x i_di %x i_e/i_b %x/%x cpu_en %x fSTALL %x rOP %o",
		   core.i_cache_pc_addr, core.i_cache_datai,
		   core.i_cache_enable, core.i_cache_busy,
		   core.cpu.cpu_enable, core.cpu.fSTALL,
		   {core.cpu.ibuf.rOPC});
 */
/*
	  $display("xMXALU %x xRESULT %x\nrRADD %x rRLOG %x rRSFT %x rRMOV %x rRBSF %x",
		   core.cpu.xecu.xMXALU, core.cpu.xecu.xRESULT,
		   core.cpu.xecu.rRES_ADD, core.cpu.xecu.rRES_LOG,
		   core.cpu.xecu.rRES_SFT, core.cpu.xecu.rRES_MOV,
		   core.cpu.xecu.rRES_BSF);
 */
/*
	  $display("pre_rIPC %x pc_inc %x xIPC %x cpu_mode_memop %x",
		   core.cpu.bpcu.pre_rIPC, core.cpu.bpcu.pc_inc,
		   core.cpu.bpcu.xIPC, core.cpu.cpu_mode_memop);
 */
/*
	  $display("xMXSRC %x xMXTGT %x xMXALT %x xRESULT %x wREGA %x c_io_rg %x",
		   core.cpu.xMXSRC, core.cpu.xMXTGT, core.cpu.xMXALT,
		   core.cpu.xecu.xRESULT, core.cpu.bpcu.wREGA,
		   core.cpu.bpcu.c_io_rg);
 */
/*
	  $display("wBRU %x wBCC %x wBRA %x dRWv %x xRWv %x rRWv %x wOPC %o fS %x xS %x",
		   core.cpu.ctrl.wBRU, core.cpu.ctrl.wBCC,
		   core.cpu.ctrl.wBRA, core.cpu.ctrl.dRW_valid,
		   core.cpu.ctrl.xRW_valid, core.cpu.ctrl.rRW_valid,
		   core.cpu.ctrl.wOPC, core.cpu.ctrl.fSTALL,
		   core.cpu.ctrl.xSKIP);
 */
/*
	  $display("lfA %x lfB %x AfwM %x BfwM %x AfwR %x BfwR %x xMXSRC %x xMXTGT %x xMXALT %x",
		   core.cpu.ctrl.late_forward_A, core.cpu.ctrl.late_forward_B,
                   core.cpu.ctrl.wAFWD_M, core.cpu.ctrl.wBFWD_M,
                   core.cpu.ctrl.wAFWD_R, core.cpu.ctrl.wBFWD_R,
                   core.cpu.ctrl.xMXSRC, core.cpu.ctrl.xMXTGT,
                   core.cpu.ctrl.xMXALT);
 */
/*
	  $display("rRESULT %x rRW %x we %x rOPC %o rOPA %x rOPB %x",
		   core.cpu.rRESULT, core.cpu.rRW, core.cpu.regf.w_en,
                   core.cpu.rOPC,
		   core.cpu.xecu.rOPA, core.cpu.xecu.rOPB);
 */
/*
 	  $display("xWDAT %x aA %x dA %x aB %x dB %x aD %x dD %x",
		   core.cpu.regf.xWDAT,
		   core.cpu.regf.regf_rRA, core.cpu.regf.xREGA,
		   core.cpu.regf.regf_rRB, core.cpu.regf.xREGB,
		   core.cpu.regf.regf_rRD, core.cpu.regf.xREGD);
 */
/*
	  $display("dpcadr %x ddi %x ddo %x den %x dwe %x dbsy %x",
		   {core.d_cache_pc_addr,2'b00}, core.d_cache_datai, core.d_cache_datao,
		   core.d_cache_enable, core.d_cache_we, core.d_cache_busy);
 */

          if (core.cpu.bpcu.xBRA)
            $display("took branch");
          $display("---------------------------------------------------");
	end // if (CPU_RST)
    end

  integer i;
  initial
    begin
      for (i=0;i<256;i=i+1)
        begin
          core.i_cache.cachedat.ram.r_data[i] <= 0;
          core.i_cache.cachetag.ram.r_data[i] <= 0;
          core.i_cache.tlb.ram.r_data[i] <= 0;
          core.i_cache.tlbtag.ram.r_data[i] <= 0;
          core.d_cache.cachedat.ram.r_data[i] <= 0;
          core.d_cache.cachetag.ram.r_data[i] <= 0;
          core.d_cache.tlb.ram.r_data[i] <= 0;
          core.d_cache.tlbtag.ram.r_data[i] <= 0;
	  core.hyper_softcore.data_mem.ram.r_data[i] <= 16'hxxxx;
	  core.hyper_softcore.prog_mem.ram.r_data[i] <= 16'h4e00;
        end // for (i=0;i<256;i=i+1)
      core.hyper_softcore.data_mem.ram.r_data[255] <= 16'h0000;
//      core.hyper_softcore.prog_mem.ram.r_data[16] <= 16'h4100;
//      core.hyper_softcore.prog_mem.ram.r_data[18] <= 16'h4608;

      core.d_cache.cachedat.ram.r_data[4] <= 32'hffff_ffff;
      core.cpu.regf.RAM_A.ram.r_data[27] <= 32'h0000_0000;
      core.cpu.regf.RAM_B.ram.r_data[27] <= 32'h0000_0000;
      core.cpu.regf.RAM_D.ram.r_data[27] <= 32'h0000_0000;

      core.cpu.regf.RAM_A.ram.r_data[8] <= 32'hc000_0000;
      core.cpu.regf.RAM_B.ram.r_data[8] <= 32'hc000_0000;
      core.cpu.regf.RAM_D.ram.r_data[8] <= 32'hc000_0000;


      // into data DRAM
      core.cpu.regf.RAM_A.ram.r_data[9] <= 32'h8d00_0045;
      core.cpu.regf.RAM_B.ram.r_data[9] <= 32'h8d00_0045;
      core.cpu.regf.RAM_D.ram.r_data[9] <= 32'h8d00_0045;

/*
      // into instruction DRAM
      core.cpu.regf.RAM_A.ram.r_data[9] <= 32'h8500_0045;
      core.cpu.regf.RAM_B.ram.r_data[9] <= 32'h8500_0045;
      core.cpu.regf.RAM_D.ram.r_data[9] <= 32'h8500_0045;
 */
/*
      // nothing at all
      core.cpu.regf.RAM_A.ram.r_data[9] <= 32'h0000_0045;
      core.cpu.regf.RAM_B.ram.r_data[9] <= 32'h0000_0045;
      core.cpu.regf.RAM_D.ram.r_data[9] <= 32'h0000_0045;
 */

      // interrupt
      core.cpu.regf.RAM_A.ram.r_data[9] <= 32'hfe00_0045;
      core.cpu.regf.RAM_B.ram.r_data[9] <= 32'hfe00_0045;
      core.cpu.regf.RAM_D.ram.r_data[9] <= 32'hfe00_0045;
//      cpu.regf.RAM_A.ram.r_data[9] <= 32'hfe00_0005;
//      cpu.regf.RAM_B.ram.r_data[9] <= 32'hfe00_0005;
//      cpu.regf.RAM_D.ram.r_data[9] <= 32'hfe00_0005;

      core.cpu.regf.RAM_A.ram.r_data[10] <= 32'h0000_0002;
      core.cpu.regf.RAM_B.ram.r_data[10] <= 32'h0000_0002;
      core.cpu.regf.RAM_D.ram.r_data[10] <= 32'h0000_0002;


//`include "test_CPU_proof_of_life.v"
//`include "test_branches_allofthem.v"
//`include "test_shifter_prog.v"
//`include "test_forward.v"
//`include "test_branchbug.v"

//`include "test_memops.v"
//`include "test_dmaops0.v"
//`include "test_dmaops2.v"
//`include "test_dmaops3.v"

//`include "test_tt_00.v"
//`include "test_tt_01.v"

//`include "test_tt_03.v"
//`include "test_tt_04.v"

//`include "test_tt_06.v"
//`include "test_tt_07.v"

//`include "test_special_snowflake_core_prog2.v"
    end // initial begin

//`include "test_r0_forward.v"
//`include "test_forward_branch.v"
//`include "test_interrupt_cpu.v"
//`include "test_interrupt_stall.v"
//`include "test_interrupt_stall_spectest00.v"
//`include "test_branch_dslot.v"
//`include "test_interrupt_branchloop.v"
//`include "test_interrupt_branchloop_free.v"
//`include "test_interrupt_branchloop_2free.v"
//`include "test_interrupt_branchimmediate_0.v"
//`include "test_interrupt_branchimmediate_1.v"
//`include "test_interrupt_branchtriple.v"
//`include "test_interrupt_branchtwofree.v"
//`include "test_interrupt_branchwrite.v"
//`include "test_interrupt_branchload.v"
//`include "test_branch_stream.v"
//`include "test_branch_stallperm.v"
//`include "test_lforward_load_wRA.v"
//`include "test_lforward_store_wRA.v"
//`include "test_lforward_load_data.v"
//`include "test_lforward_store_data.v"
//`include "test_lforward_loadstore_data.v"
//`include "test_lforward_rD_store.v"
//`include "test_lforward_prerD_store.v"

//`include "test_dma_cpucomm.v"
//`include "test_gremlin_general.v"
//`include "test_gremlin_delay.v"
//`include "test_gremlin_waitacc.v"

`include "test_softctrl_parttest_00.v"

endmodule // GlaDOS
