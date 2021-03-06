`timescale 1ns/1ps

`include "test_inc.v"

// Memory module
`include "../mcu/commands.v"
`include "../mcu/state2.v"
`include "../mcu/initializer.v"
`include "../mcu/integration3.v"

// Cache
`include "../cache/cpu_mcu2.v"

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
	fast_i <= fast_i +1;
	if (fast_i == 2'h3)
//	if (slow_i < 10'h3ff)
	  slow_i <= slow_i +1;

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
  reg CLK_p, CLK_n, CLK_dp, CLK_dn, RST, RST_ddr, CPU_CLK;
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

  wire 	      CKE, DQS, DM, CS;
  wire [2:0]  COMMAND;
  wire [12:0] ADDRESS;
  wire [1:0]  BANK;
  wire [15:0] DQ;

  wire [31:0] mcu_data_into, mcu_data_outof;

  wire [11:0] hf_coll_addr_fill, hf_coll_addr_empty, mcu_coll_addr;
  wire [3:0]  hf_we_array_fill;
  wire 	      hf_req_access_fill, hf_req_access_empty;

  wire 	      w_issue, w_working_fill, w_working_empty;
  wire [1:0]  w_section;
  wire [5:0]  w_count_req, w_count_sent_fill, w_count_sent_empty;
  wire [11:0] w_start_address;

  wire 	      w_irq_cr, w_abstop_cr, w_abstop_cw;

  wire [19:0] mcu_page_addr;
  wire 	      mcu_algn_req, mcu_algn_ack;

  wire 	      mvblck_RST_fill, mvblck_RST_empty;
  reg 	      mcu_req_access, mcu_we;

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

  ddr ddr_mem(.Clk(CLK_p),
	      .Clk_n(CLK_n),
	      .Cke(CKE),
	      .Cs_n(CS),
	      .Ras_n(COMMAND[2]),
	      .Cas_n(COMMAND[1]),
	      .We_n(COMMAND[0]),
	      .Ba(BANK),
	      .Addr(ADDRESS),
	      .Dm({DM,DM}),
	      .Dq(DQ),
	      .Dqs({DQS,DQS}));

  ddr_memory_controler ddr_mc(.CLK_n(CLK_n),
			      .CLK_p(CLK_p),
			      .CLK_dp(CLK_dp),
			      .CLK_dn(CLK_dn),
			      .RST(RST_ddr),
			      .CKE(CKE),
			      .COMMAND(COMMAND),
			      .ADDRESS(ADDRESS),
			      .BANK(BANK),
			      .DQ(DQ),
			      .DQS(DQS),
			      .DM(DM),
			      .CS(CS),
			      .refresh_strobe(refresh_strobe),
			      .rand_req_address(0),
			      .rand_req_we(0),
			      .rand_req_we_array(0),
			      .rand_req(0),
			      .rand_req_ack(),
			      .bulk_req_address({mcu_page_addr,
						 mcu_coll_addr}),
			      .bulk_req_we(mcu_we), // NOTICE-ME!
			      .bulk_req_we_array(hf_we_array_fill),
			      .bulk_req(mcu_req_access),
			      .bulk_req_ack(),
			      .bulk_req_algn(mcu_algn_req),
			      .bulk_req_algn_ack(mcu_algn_ack),
			      .bulk_req_datain(mcu_data_into),
			      .user_req_dataout(mcu_data_outof));

  test_fill_lsab lsab_write(.CLK(CLK_n),
			    .RST(RST),
			    .DATA0(w_data0_cr), .DATA1(w_data1_cr),
			    .DATA2(w_data2_cr), .DATA3(w_data3_cr),
			    .WRITE(w_write_cr),
			    .WRITE_FIFO(w_write_fifo_cr),
			    .INT0(w_int0_cr), .INT1(w_int1_cr),
			    .INT2(w_int2_cr), .INT3(w_int3_cr));

  trans_core hyperfabric_switch(.CLK(CLK_n),
				.RST(RST),
				.out_0(mcu_data_into), .out_1(),
				.out_2(w_in_cw), .out_3(),
				.out_4(), .out_5(),
				.out_6(), .out_7(),
				.in_0(mcu_data_outof), .in_1(0),
				.in_2(w_out_cr), .in_3(0),
				.in_4(0), .in_5(0),
				.in_6(0), .in_7(0),
				.isel({13'h0,w_isel}),
				.osel({13'h0,w_osel}));

  lsab_cr lsab_in(.CLK(CLK_n),
		  .RST(RST),
		  .READ(w_read_cr),
		  .WRITE0(w_write_cr),
		  .WRITE1(w_write_cr),
		  .WRITE2(w_write_cr),
		  .WRITE3(w_write_cr),
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
			   .DRAM_SEL({1'b0,mcu_algn_req}),
			   .ISSUE(w_issue),
			   .COUNT_SENT(w_count_sent_fill),
			   .WORKING(w_working_fill),
			   .IRQ_OUT(w_irq_cr),
			   .ABRUPT_STOP(w_abstop_cr),
			   .MCU_COLL_ADDRESS(hf_coll_addr_fill),
			   .MCU_WE_ARRAY(hf_we_array_fill),
			   .MCU_REQUEST_ACCESS({drop_f,hf_req_access_fill}));

  lsab_cw lsab_out(.CLK(CLK_n),
		   .RST(RST),
		   .READ0(1),
		   .READ1(1),
		   .READ2(1),
		   .READ3(1),
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
			  .DRAM_SEL({1'b0,mcu_algn_req}),
			  .ISSUE(w_issue),
			  .COUNT_SENT(w_count_sent_empty),
			  .WORKING(w_working_empty),
			  .ABRUPT_STOP(w_abstop_cw),
			  .MCU_COLL_ADDRESS(hf_coll_addr_empty),
			  .MCU_REQUEST_ACCESS({drop_e,hf_req_access_empty}));

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
		      .MCU_REQUEST_ALIGN({drop,mcu_algn_req}),
		      .MCU_GRANT_ALIGN({1'b0,mcu_algn_ack}));

  hyper_scheduler mut(.CLK(CLK_n),
		      .RST(RST),
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
		      .IRQ_DESC(res_irq_desc),
		      .WRITE_MEM(res_write_mem),
		      .MEM_W_ADDR(res_w_addr),
		      .MEM_W_DATA(res_in),
		      .READ_MEM(res_read_mem),
		      .MEM_R_ADDR(res_r_addr),
		      .MEM_R_DATA(res_out));

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

  always @(posedge CLK_n)
    if (!RST)
      begin
	mcu_req_access <= 0; mcu_we <= 0;
      end
    else
      begin
	counter <= counter +1;
	mcu_req_access <= (hf_req_access_fill || hf_req_access_empty);
	mcu_we <= hf_req_access_fill;

/*
	if (counter > 400 && counter < 610)
	  begin
	    $display("addr %x we %x wea %x req %x algnr %x algna %x @ %d",
		     {mcu_page_addr,mcu_coll_addr}, mcu_we,
		     hf_we_array_fill, mcu_req_access, mcu_algn_req,
		     mcu_algn_ack, counter);
	  end
 */
/*
	if (counter < 128)
	  begin
	    $display("we %x wfifo %x re %x rfifo %x ept %x stp %x @ %d/%d",
		     w_write, w_write_fifo,
		     w_read, w_read_fifo,
		     {w_e0,w_e1,w_e2,w_e3},
		     {w_s0,w_s1,w_s2,w_s3},
		     counter, test_driver.slow_i);
	  end
 */
/*
	if (counter < 128)
	  begin
	    $display("intbdet2 %x intb2 %x care2 %x bcme2 %x @ %d",
		     lsab_cr_mut.intbuff_int_det_2,
		     lsab_cr_mut.intbuff_int_2,
		     lsab_cr_mut.CAREOF_INT_2,
		     lsab_cr_mut.become_empty_2,
		     counter);
	  end
 */
      end // else: !if(!RST)

  initial
    begin
      counter <= 0;
      RST <= 0; RST_ddr <= 0;
      #14.34 RST_ddr <= 1;
      #400000 RST <= 1;
      #18432;

/*
      for (readcount=0; readcount<64; readcount=readcount+1)
	begin
	  $display("test_data[%d] %x",
		   readcount[9:0],
		   test_driver.test_we[{readcount[9:0],2'h0}]);
	end
 */
/*
      for (readcount=0; readcount<1024; readcount=readcount+1)
	begin
	  $display("test_data[%d] %x",
		   readcount[9:0],
		   test_driver.test_data[{readcount[9:0],2'h0}]);
	end
 */
/*
      for (readcount=0; readcount<4; readcount=readcount+1)
	begin
	  $display("intb2[%d] %x",
		   readcount[1:0], lsab_cr_mut.intbuff_2[readcount]);
	end
 */
      $finish;
    end

endmodule // GlaDOS
