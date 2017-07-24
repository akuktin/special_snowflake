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

  wire [23:0]  ph_len_0, ph_len_1, ph_len_2, ph_len_3;
  wire 	       ph_dir_0, ph_enstb_0, ph_dir_1, ph_enstb_1,
	       ph_dir_2, ph_enstb_2, ph_dir_3, ph_enstb_3;
  reg 	       ph_enstb_0_prev, ph_enstb_1_prev,
	       ph_enstb_2_prev, ph_enstb_3_prev;

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


  test_fill_lsab lsab_write(.CLK(CLK_n),
			    .RST(RST),
			    .DATA0(w_data0_cr), .DATA1(w_data1_cr),
			    .DATA2(w_data2_cr), .DATA3(w_data3_cr),
			    .WRITE(w_write_cr),
			    .WRITE_FIFO(w_write_fifo_cr),
			    .INT0(w_int0_cr), .INT1(w_int1_cr),
			    .INT2(w_int2_cr), .INT3(w_int3_cr));

  special_snowflake_core core(.RST(RST),
			      .RST_CPU_pre(RST_CPU_pre),
			      .CLK_p(CLK_p),
			      .CLK_n(CLK_n),
			      .CLK_dp(CLK_dp),
			      .CLK_dn(CLK_dn),
			      .CPU_CLK(CPU_CLK),
			      // ----------------------
			      .mem_iCKE(iCKE),
			      .mem_iDQS(iDQS),
			      .mem_iDM(iDM),
			      .mem_iCS(iCS),
			      .mem_iCOMMAND(iCOMMAND),
			      .mem_iADDRESS(iADDRESS),
			      .mem_iBANK(iBANK),
			      .mem_iDQ(iDQ),
			      .mem_dCKE(dCKE),
			      .mem_dDQS(dDQS),
			      .mem_dDM(dDM),
			      .mem_dCS(dCS),
			      .mem_dCOMMAND(dCOMMAND),
			      .mem_dADDRESS(dADDRESS),
			      .mem_dBANK(dBANK),
			      .mem_dDQ(dDQ),
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
			      .read1_cw(1),
			      .read2_cw(1),
			      .read3_cw(1),
			      .data0_cw(),
			      .data1_cw(),
			      .data2_cw(),
			      .data3_cw(),
			      .err0_cw(0),
			      .err1_cw(0),
			      .err2_cw(0),
			      .err3_cw(0),
			      .errack0_cw(),
			      .errack1_cw(),
			      .errack2_cw(),
			      .errack3_cw());


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
	       {core.mcu_page_addr,mcu_coll_addr}, core.i_mcu_we,
	       core.hf_we_array_fill, core.i_mcu_req_access,
	       core.i_mcu_algn_req, core.i_mcu_algn_ack);
      $display("state %x,%x,%x reftime %x",
	       core.i_mcu.interdictor_tracker.SOME_PAGE_ACTIVE,
	       core.i_mcu.interdictor_tracker.REFRESH_TIME,
	       core.i_mcu.interdictor_tracker.actv_timeout[2],
	       core.i_mcu.interdictor_tracker.REFRESH_TIME);
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
	ctr <= 0;
	ph_enstb_0_prev <= 0; ph_enstb_1_prev <= 0;
	ph_enstb_2_prev <= 0; ph_enstb_3_prev <= 0;
      end
    else
      begin
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

//	if (i_mcu_req_access & ! i_mcu_req_access_prev)
//	if (refresh_strobe ^ refresh_strobe_prev)
//	if (i_mcu_algn_req && ! i_mcu_algn_ack)
//	if ((ctr >= 66820) && (ctr < 66900))
	if ((ctr >= 66740) && (ctr < 66760) && 0)
	  begin
	    $display("@ %d fl %x ep %x", ctr,
		     core.i_hf_req_access_fill, core.i_hf_req_access_empty);
	    $display("addr %x we %x wea %x req %x algnr %x algna %x",
		     {core.mcu_page_addr,core.mcu_coll_addr}, core.i_mcu_we,
		     core.hf_we_array_fill, core.i_mcu_req_access,
		     core.i_mcu_algn_req, core.i_mcu_algn_ack);
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
      if (core.cpu.regf.mDRAM[31] == 32'd0)
	begin
	  $display("halting");
	  $display("wMSR %x", core.cpu.xecu.wMSR);
	  $display(" r0: %x,  r1: %x,  r2: %x  r3: %x",
		   core.cpu.regf.mDRAM[0], core.cpu.regf.mDRAM[1],
		   core.cpu.regf.mDRAM[2], core.cpu.regf.mDRAM[3]);
	  $display(" r4: %x,  r5: %x,  r6: %x  r7: %x",
		   core.cpu.regf.mDRAM[4], core.cpu.regf.mDRAM[5],
		   core.cpu.regf.mDRAM[6], core.cpu.regf.mDRAM[7]);
	  $display(" r8: %x,  r9: %x, r10: %x r11: %x",
		   core.cpu.regf.mDRAM[8], core.cpu.regf.mDRAM[9],
		   core.cpu.regf.mDRAM[10], core.cpu.regf.mDRAM[11]);
	  $display("r12: %x, r13: %x, r14: %x r15: %x",
		   core.cpu.regf.mDRAM[12], core.cpu.regf.mDRAM[13],
		   core.cpu.regf.mDRAM[14], core.cpu.regf.mDRAM[15]);
	  $display("r16: %x, r17: %x, r18: %x r19: %x",
		   core.cpu.regf.mDRAM[16], core.cpu.regf.mDRAM[17],
		   core.cpu.regf.mDRAM[18], core.cpu.regf.mDRAM[19]);
	  $display("r20: %x, r21: %x, r22: %x r23: %x",
		   core.cpu.regf.mDRAM[20], core.cpu.regf.mDRAM[21],
		   core.cpu.regf.mDRAM[22], core.cpu.regf.mDRAM[23]);
	  $display("r24: %x, r25: %x, r26: %x r27: %x",
		   core.cpu.regf.mDRAM[24], core.cpu.regf.mDRAM[25],
		   core.cpu.regf.mDRAM[26], core.cpu.regf.mDRAM[27]);
	  $display("r28: %x, r29: %x, r30: %x r31: %x",
		   core.cpu.regf.mDRAM[28], core.cpu.regf.mDRAM[29],
		   core.cpu.regf.mDRAM[30], core.cpu.regf.mDRAM[31]);
	  $finish;
	end
/*
	  $display(" r0: %x,  r1: %x,  r2: %x  r3: %x",
		   core.cpu.regf.mDRAM[0], core.cpu.regf.mDRAM[1],
		   core.cpu.regf.mDRAM[2], core.cpu.regf.mDRAM[3]);
	  $display(" r4: %x,  r5: %x,  r6: %x  r7: %x",
		   core.cpu.regf.mDRAM[4], core.cpu.regf.mDRAM[5],
		   core.cpu.regf.mDRAM[6], core.cpu.regf.mDRAM[7]);
	  $display(" r8: %x,  r9: %x, r10: %x r11: %x",
		   core.cpu.regf.mDRAM[8], core.cpu.regf.mDRAM[9],
		   core.cpu.regf.mDRAM[10], core.cpu.regf.mDRAM[11]);
	  $display("r12: %x, r13: %x, r14: %x r15: %x",
		   core.cpu.regf.mDRAM[12], core.cpu.regf.mDRAM[13],
		   core.cpu.regf.mDRAM[14], core.cpu.regf.mDRAM[15]);
	  $display("r16: %x, r17: %x, r18: %x r19: %x",
		   core.cpu.regf.mDRAM[16], core.cpu.regf.mDRAM[17],
		   core.cpu.regf.mDRAM[18], core.cpu.regf.mDRAM[19]);
	  $display("r20: %x, r21: %x, r22: %x r23: %x",
		   core.cpu.regf.mDRAM[20], core.cpu.regf.mDRAM[21],
		   core.cpu.regf.mDRAM[22], core.cpu.regf.mDRAM[23]);
	  $display("r24: %x, r25: %x, r26: %x r27: %x",
		   core.cpu.regf.mDRAM[24], core.cpu.regf.mDRAM[25],
		   core.cpu.regf.mDRAM[26], core.cpu.regf.mDRAM[27]);
	  $display("r28: %x, r29: %x, r30: %x r31: %x",
		   core.cpu.regf.mDRAM[28], core.cpu.regf.mDRAM[29],
		   core.cpu.regf.mDRAM[30], core.cpu.regf.mDRAM[31]);
*/
      if (RST_CPU_pre && 0)
	begin
//      $display("c_vld %x req_tag %x ^ rsp %x idx %x en %x/%x",
//	       core.i_cache.cachehit_vld, core.i_cache.req_tag,
//	       core.i_cache.vmem_rsp_tag, core.i_cache.tlb_idx_w,
//	       core.i_cache_enable,
//	       {core.i_cache_busy_n,(core.RST & (~core.RST_CPU)),1'b1});
/*
	  $display("i_pc_addr %x i_c_addr %x i_di %x i_e %x",
		   core.i_cache_pc_addr, core.i_cache_c_addr,
                    core.i_cache_datai, core.i_cache_enable);
 */

	  $display("i_pc_addr %x i_di %x i_e/i_b %x/%x cpu_en %x fSTALL %x rOP %o",
		   core.i_cache_pc_addr, core.i_cache_datai,
		   core.i_cache_enable, core.i_cache_busy,
		   core.cpu.cpu_enable, core.cpu.fSTALL,
		   {core.cpu.ibuf.rOPC});
/*
	  $display("pre_rIPC %x pc_inc %x xIPC %x cpu_mode_memop %x",
		   cpu.bpcu.pre_rIPC, cpu.bpcu.pc_inc, cpu.bpcu.xIPC,
		   cpu.cpu_mode_memop);

	  $display("rRESULT %x rRW %x rSIMM %x rOPA %x rOPB %x",
		   cpu.rRESULT, cpu.rRW, cpu.rSIMM,
		   cpu.xecu.rOPA, cpu.xecu.rOPB);
 */
	  $display("xWDAT %x en %x rDWBDI %x rRW %x",
		   core.cpu.regf.xWDAT,
		   {core.cpu.regf.grst,core.cpu.regf.fRDWE,core.cpu.regf.w_en},
		   core.cpu.regf.rDWBDI, core.cpu.regf.rRW);

	  $display("dpcadr %x ddi %x ddo %x den %x dwe %x dbsy %x",
		   {core.d_cache_pc_addr,2'b00}, core.d_cache_datai, core.d_cache_datao,
		   core.d_cache_enable, core.d_cache_we, core.d_cache_busy);

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
        end // for (i=0;i<256;i=i+1)

      core.d_cache.cachedat.ram.r_data[4] <= 32'hffff_ffff;
      core.cpu.regf.mARAM[27] <= 32'h0000_0000;
      core.cpu.regf.mBRAM[27] <= 32'h0000_0000;
      core.cpu.regf.mDRAM[27] <= 32'h0000_0000;

      core.cpu.regf.mARAM[8] <= 32'hc000_0000;
      core.cpu.regf.mBRAM[8] <= 32'hc000_0000;
      core.cpu.regf.mDRAM[8] <= 32'hc000_0000;


      // into data DRAM
      core.cpu.regf.mARAM[9] <= 32'h8d00_0045;
      core.cpu.regf.mBRAM[9] <= 32'h8d00_0045;
      core.cpu.regf.mDRAM[9] <= 32'h8d00_0045;

/*
      // into instruction DRAM
      core.cpu.regf.mARAM[9] <= 32'h8500_0045;
      core.cpu.regf.mBRAM[9] <= 32'h8500_0045;
      core.cpu.regf.mDRAM[9] <= 32'h8500_0045;
 */
/*
      // nothing at all
      core.cpu.regf.mARAM[9] <= 32'h0000_0045;
      core.cpu.regf.mBRAM[9] <= 32'h0000_0045;
      core.cpu.regf.mDRAM[9] <= 32'h0000_0045;
 */

      // interrupt
      core.cpu.regf.mARAM[9] <= 32'hfe00_0045;
      core.cpu.regf.mBRAM[9] <= 32'hfe00_0045;
      core.cpu.regf.mDRAM[9] <= 32'hfe00_0045;
//      cpu.regf.mARAM[9] <= 32'hfe00_0005;
//      cpu.regf.mBRAM[9] <= 32'hfe00_0005;
//      cpu.regf.mDRAM[9] <= 32'hfe00_0005;

      core.cpu.regf.mARAM[10] <= 32'h0000_0002;
      core.cpu.regf.mBRAM[10] <= 32'h0000_0002;
      core.cpu.regf.mDRAM[10] <= 32'h0000_0002;


`include "test_special_snowflake_core_prog2.bin"
//`include "test_branches_allofthem.bin"
// `include "test_shifter_prog.bin"
    end

endmodule // GlaDOS