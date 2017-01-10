`timescale 1ns/1ps

`include "test_inc.v"

// Memory module
`include "../mcu/commands.v"
`include "../mcu/state2.v"
`include "../mcu/initializer.v"
`include "../mcu/integration2.v"

// Cache
`include "../cache/cpu_mcu2.v"

// LSAB
`include "../hyperfabric/lsab.v"

// Hyperfabric
`include "../hyperfabric/transport.v"
`include "../hyperfabric/mvblck_todram.v"
`include "../hyperfabric/mvblck_frdram.v"

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
      for (v=(0+4); v<(72+4); v=v+1)  // needed to prevent a full buffer
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
	fast_i <= 2'h1;
//	fast_i <= fast_i +1;
//	if (fast_i == 2'h3)
	if (slow_i < 10'h3ff)
	  slow_i <= slow_i +1;

	c <= c +1;
      end

endmodule // test_in

module test_mvblck(input CLK,
		   input 	 RST,
		   output reg 	 mvblck_RST,
		   output [11:0] START_ADDRESS,
		   output [5:0]  COUNT_REQ,
		   output [1:0]  SECTION,
		   output reg 	 ISSUE,
		   input [5:0] 	 COUNT_SENT,
		   input 	 WORKING);
  reg [31:0] 			 c;
  reg [11:0] 			 test_addr[255:0];
  reg [7:0] 			 testno, maxtests;
  reg [5:0] 			 test_count[255:0];
  reg [1:0] 			 test_section[255:0];
  reg 				 working_prev;

  wire 				 trigger, trigger_all;

  assign trigger = working_prev && !WORKING;
  assign trigger_all = (c == 32'd256) || trigger;

  assign START_ADDRESS = test_addr[testno];
  assign COUNT_REQ = test_count[testno];
  assign SECTION = test_section[testno];

  reg [31:0] 			 l, o, v, e;
  initial
    begin
      for (l=0; l<256; l=l+1)
	begin
	  test_addr[l] <= 0;
	  test_count[l] <= 0;
	  test_section[l] <= 2'h1;
	end

      // your test data here
      test_addr[1] <= 12'h100;
      test_count[1] <= 6'd1;

      test_addr[2] <= 12'h100;
      test_count[2] <= 6'd2;

      test_addr[3] <= 12'h100;
      test_count[3] <= 6'd3;

      test_addr[4] <= 12'h100;
      test_count[4] <= 6'd4;

      test_addr[5] <= 12'h100;
      test_count[5] <= 6'd5;

      test_addr[6] <= 12'h100;
      test_count[6] <= 6'd6;

      test_addr[7] <= 12'h100;
      test_count[7] <= 6'd7;

      test_addr[8] <= 12'h100;
      test_count[8] <= 6'd8;


      test_addr[9] <= 12'h101;
      test_count[9] <= 6'd1;
      test_section[9] <= 2'h2;

      test_addr[10] <= 12'h101;
      test_count[10] <= 6'd2;
      test_section[10] <= 2'h2;

      test_addr[11] <= 12'h101;
      test_count[11] <= 6'd3;
      test_section[11] <= 2'h2;

      test_addr[12] <= 12'h101;
      test_count[12] <= 6'd4;
      test_section[12] <= 2'h2;

      test_addr[13] <= 12'h101;
      test_count[13] <= 6'd5;
      test_section[13] <= 2'h2;

      test_addr[14] <= 12'h101;
      test_count[14] <= 6'd6;
      test_section[14] <= 2'h2;

      test_addr[15] <= 12'h101;
      test_count[15] <= 6'd7;
      test_section[15] <= 2'h2;

      test_addr[16] <= 12'h101;
      test_count[16] <= 6'd8;
      test_section[16] <= 2'h2;


      test_addr[17] <= 12'h100;
      test_count[17] <= 6'h12;
//      test_count[17] <= 6'h3f;
      test_section[17] <= 2'h1;

      test_addr[18] <= 12'h113;
      test_count[18] <= 6'hd;
//      test_count[18] <= 6'h3f;
      test_section[18] <= 2'h1;
    end

  always @(posedge CLK)
    if (!RST)
      begin
	c <= 0; mvblck_RST <= 0; working_prev <= 0; ISSUE <= 0;
	testno <= 8'h00; maxtests <= 18;
      end
    else
      begin
	c <= c+1;
	if (c == 32'd256)
	  mvblck_RST <= 1;
	working_prev <= WORKING;

	if (trigger)
	  begin
	    if (COUNT_SENT != COUNT_REQ)
	      $display("XXX count of sent #%d got %x want %x @ %d",
		       testno, COUNT_SENT, COUNT_REQ, c);
	  end

	if (trigger_all && (testno < maxtests))
	  begin
	    testno <= testno +1;
	    $display("TEST #%d", testno+1);
	    ISSUE <= 1;
	  end
	else
	  if (WORKING)
	    ISSUE <= 0;
      end

endmodule // test_mvblck

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
  wire 	      w_f0_cw, w_f1_cw, w_f2_cw, w_f3_cw;

  wire 	      CKE, DQS, DM, CS;
  wire [2:0]  COMMAND;
  wire [12:0] ADDRESS;
  wire [1:0]  BANK;
  wire [15:0] DQ;

  wire [31:0] mcu_data_into, mcu_data_outof;

  wire [11:0] hf_coll_addr_fill, hf_coll_addr_mut, mcu_coll_addr;
  wire [3:0]  hf_we_array_fill;
  wire 	      hf_req_access_fill, hf_req_access_mut;

  wire 	      mvblck_RST, w_issue, w_working;
  wire [1:0]  w_section;
  wire [5:0]  w_count_req, w_count_sent;
  wire [11:0] w_start_address;

  reg 	      mcu_req_access, mcu_we;

  assign mcu_coll_addr = (counter <= 32'd255) ?
			 hf_coll_addr_fill : hf_coll_addr_mut;

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
			      .rand_req_address(0),
			      .rand_req_we(0),
			      .rand_req_we_array(0),
			      .rand_req(0),
			      .rand_req_ack(),
			      .bulk_req_address({14'd0,mcu_coll_addr}),
			      .bulk_req_we(mcu_we), // NOTICE-ME!
			      .bulk_req_we_array(hf_we_array_fill),
			      .bulk_req(mcu_req_access),
			      .bulk_req_ack(),
			      .bulk_req_algn(1'b1), // for the test only
			      .bulk_req_algn_ack(),
			      .user_req_datain(mcu_data_into),
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
				.out_0(), .out_1(),
				.out_2(), .out_3(),
				.out_4(), .out_5(mcu_data_into),
				.out_6(), .out_7(w_in_cw),
				.in_0(0), .in_1(w_out_cr),
				.in_2(0), .in_3(mcu_data_outof),
				.in_4(0), .in_5(0),
				.in_6(0), .in_7(0),
				.isel(16'h0802),
				.osel(16'h20a0));

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
	       .CAREOF_INT_0(1'b1), .CAREOF_INT_1(1'b1),
	       .CAREOF_INT_2(1'b1), .CAREOF_INT_3(1'b1),
	       .OUT(w_out_cr),
	       .EMPTY_0(), .EMPTY_1(),
	       .EMPTY_2(), .EMPTY_3(),
	       .STOP_0(w_s0_cr), .STOP_1(w_s1_cr),
	       .STOP_2(w_s2_cr), .STOP_3(w_s3_cr));

  hyper_mvblck_todram fill(.CLK(CLK_n),
			   .RST(RST),
			   .LSAB_0_STOP(w_s0_cr),
			   .LSAB_1_STOP(w_s1_cr),
			   .LSAB_2_STOP(w_s2_cr),
			   .LSAB_3_STOP(w_s3_cr),
			   .LSAB_READ(w_read_cr),
			   .LSAB_SECTION(w_read_fifo_cr),
			   .START_ADDRESS(12'h0ff),
			   .COUNT_REQ(6'h3f),
			   .SECTION(2'h1),
			   .ISSUE((counter == 32'd6)),
			   .COUNT_SENT(),
			   .WORKING(),
			   .MCU_COLL_ADDRESS(hf_coll_addr_fill),
			   .MCU_WE_ARRAY(hf_we_array_fill),
			   .MCU_REQUEST_ACCESS(hf_req_access_fill));

  lsab_cw lsab_out(.CLK(CLK_n),
		   .RST(RST),
		   .READ0(0),
		   .READ1(0),
		   .READ2(0),
		   .READ3(0),
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

  hyper_mvblck_frdram mut(.CLK(CLK_n),
			  .RST(mvblck_RST),
			  .LSAB_0_FULL(w_f0_cw),
			  .LSAB_1_FULL(w_f1_cw),
			  .LSAB_2_FULL(w_f2_cw),
			  .LSAB_3_FULL(w_f3_cw),
			  .LSAB_WRITE(w_write_cw),
			  .LSAB_SECTION(w_write_fifo_cw),
			  .START_ADDRESS(w_start_address),
			  .COUNT_REQ(w_count_req),
			  .SECTION(w_section),
			  .ISSUE(w_issue),
			  .COUNT_SENT(w_count_sent),
			  .WORKING(w_working),
			  .MCU_COLL_ADDRESS(hf_coll_addr_mut),
			  .MCU_REQUEST_ACCESS(hf_req_access_mut));

  test_mvblck test_drv(.CLK(CLK_n),
		       .RST(RST),
		       .mvblck_RST(mvblck_RST),
		       .START_ADDRESS(w_start_address),
		       .COUNT_REQ(w_count_req),
		       .SECTION(w_section),
		       .ISSUE(w_issue),
		       .COUNT_SENT(w_count_sent),
		       .WORKING(w_working));

  always @(posedge CLK_n)
    if (!RST)
      begin
	mcu_req_access <= 0; mcu_we <= 0;
      end
    else
      begin
	counter <= counter +1;
	mcu_req_access <= (hf_req_access_fill || hf_req_access_mut);
	mcu_we <= hf_req_access_fill;
/*
	if (counter < 32)
	  begin
	    $display("d0 %x d1 %x d2 %x d3 %x we %x wefifo %x @ %d/%d",
		     w_data0, w_data1, w_data2, w_data3,
		     w_write, w_write_fifo,
		     counter, test_driver.slow_i);
	  end
 */
/*
	if (counter > 1190 && counter < 1500)
	  begin
	    $display("out %x re %x rfifo %x ept %x stp %x @ %d/%d",
		     w_out,
		     w_read, w_read_fifo,
		     {w_e0,w_e1,w_e2,w_e3},
		     {w_s0,w_s1,w_s2,w_s3},
		     counter, test_driver.slow_i);
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
