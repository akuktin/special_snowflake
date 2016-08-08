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

  wire [31:0] w_data0, w_data1, w_data2, w_data3;
  wire 	      w_write, w_read;
  wire [1:0]  w_write_fifo, w_read_fifo;
  wire 	      w_int0, w_int1, w_int2, w_int3;
  wire [3:0]  w_care;

  wire [31:0] w_out;
  wire 	      w_s0, w_s1, w_s2, w_s3;

  wire 	      CKE, DQS, DM, CS;
  wire [2:0]  COMMAND;
  wire [12:0] ADDRESS;
  wire [1:0]  BANK;
  wire [15:0] DQ;

  wire [31:0] mcu_data_into, mcu_data_outof;

  wire [11:0] hf_coll_addr;
  wire [3:0]  hf_we_array;
  wire 	      hf_req_access, mvblck_RST;

  reg 	      mcu_req_access;

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
			      .bulk_req_address({14'd0,hf_coll_addr}),
			      .bulk_req_we(mcu_req_access), // NOTICE-ME!
			      .bulk_req_we_array(hf_we_array),
			      .bulk_req(mcu_req_access),
			      .bulk_req_ack(),
			      .bulk_req_algn(1'b1), // for the test only
			      .bulk_req_algn_ack(),
			      .user_req_datain(mcu_data_into),
			      .user_req_dataout(mcu_data_outof));

  trans_core hyperfabric_switch(.CLK(CLK_n),
				.RST(RST),
				.out_0(), .out_1(),
				.out_2(), .out_3(),
				.out_4(), .out_5(mcu_data_into),
				.out_6(), .out_7(),
				.in_0(), .in_1(w_out),
				.in_2(), .in_3(mcu_data_outof),
				.in_4(), .in_5(),
				.in_6(), .in_7(),
				.isel(),
				.osel());

  lsab_cr lsab(.CLK(CLK_n),
	       .RST(RST),
	       .READ(w_read),
	       .WRITE(w_write),                      //
	       .READ_FIFO(w_read_fifo),
	       .WRITE_FIFO(w_write_fifo),            //
	       .IN_0(w_data0), .IN_1(w_data1),       // //
	       .IN_2(w_data2), .IN_3(w_data3),       // //
	       .INT_IN_0(w_int0), .INT_IN_1(w_int1), // //
	       .INT_IN_2(w_int2), .INT_IN_3(w_int3), // //
	       .CAREOF_INT_0(1'b1), .CAREOF_INT_1(1'b1),
	       .CAREOF_INT_2(1'b1), .CAREOF_INT_3(1'b1),
	       .OUT(w_out),
	       .EMPTY_0(), .EMPTY_1(),
	       .EMPTY_2(), .EMPTY_3(),
	       .STOP_0(w_s0), .STOP_1(w_s1),
	       .STOP_2(w_s2), .STOP_3(w_s3));

  hyper_mvblck_todram mut(.CLK(CLK_n),
			  .RST(mvblck_RST),
			  .LSAB_0_STOP(w_s0),
			  .LSAB_1_STOP(w_s1),
			  .LSAB_2_STOP(w_s2),
			  .LSAB_3_STOP(w_s3),
			  .LSAB_READ(w_read),
			  .LSAB_SECTION(w_read_fifo),
			  .START_ADDRESS(), //
			  .COUNT_REQ(),     //
			  .SECTION(),       //
			  .ISSUE(),         //
			  .COUNT_SENT(),    //
			  .WORKING(),       //
			  .MCU_COLL_ADDRESS(hf_coll_addr),
			  .MCU_WE_ARRAY(hf_we_array),
			  .MCU_REQUEST_ACCESS(hf_req_access));

  always @(posedge CLK_n)
    if (!RST)
      begin
	mcu_req_access <= 0;
      end
    else
      begin
	counter <= counter +1;
	mcu_req_access <= hf_req_access;
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
