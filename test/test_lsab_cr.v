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

module test_drv(input CLK,
		input 		  RST,
		output reg [31:0] DATA0,
		output reg [31:0] DATA1,
		output reg [31:0] DATA2,
		output reg [31:0] DATA3,
		output 		  WRITE,
		output [1:0] 	  WRITE_FIFO,
		output 		  INT0,
		output 		  INT1,
		output 		  INT2,
		output 		  INT3,
		// -----------------------
		output 		  READ,
		output [1:0] 	  READ_FIFO,
		output 		  CAREOF_INT_0,
		output 		  CAREOF_INT_1,
		output 		  CAREOF_INT_2,
		output 		  CAREOF_INT_3,
		// -----------------------
		input [3:0] 	  RES_EMPTY,
		input [3:0] 	  RES_STOP,
		input [31:0] 	  RES_DATA);
  reg [31:0] 	      test_data[4095:0],
		      reg_data[4095:0];
  reg [3:0] 	      test_care[4095:0],
		      reg_empty[4095:0],
		      reg_stop[4095:0];
  reg [2:0] 	      reg_careof[4095:0];
  reg [1:0] 	      test_rfifo[4095:0];
  reg 		      test_we[4095:0],
		      test_re[4095:0],
		      test_int[4095:0],
		      r_read_0, r_read_1;

  reg [1:0] 	      fast_i;
  reg [2:0]	      r_careof;
  reg [9:0] 	      slow_i;
  reg [11:0] 	      c, out_c_0, out_c_1;

  wire [31:0] 	      wDATA0, wDATA1, wDATA2, wDATA3;
  wire [31:0] 	      w_data;
  wire [3:0] 	      w_stop, w_empty;
  wire [2:0] 	      w_careof;

  assign w_careof = reg_careof[out_c_0];
  assign w_empty = reg_empty[out_c_0];
  assign w_stop = reg_stop[out_c_0];
  assign w_data = reg_data[out_c_1];

  assign wDATA0 = test_data[{slow_i,2'h0}];
  assign wDATA1 = test_data[{slow_i,2'h1}];
  assign wDATA2 = test_data[{slow_i,2'h2}];
  assign wDATA3 = test_data[{slow_i,2'h3}];

  assign WRITE = test_we[{slow_i,fast_i}];
  assign WRITE_FIFO = fast_i;

  assign INT0 = test_int[{slow_i,2'h0}];
  assign INT1 = test_int[{slow_i,2'h1}];
  assign INT2 = test_int[{slow_i,2'h2}];
  assign INT3 = test_int[{slow_i,2'h3}];

  assign READ = test_re[c];
  assign READ_FIFO = test_rfifo[c];
  assign CAREOF_INT_0 = test_care[c][0];
  assign CAREOF_INT_1 = test_care[c][1];
  assign CAREOF_INT_2 = test_care[c][2];
  assign CAREOF_INT_3 = test_care[c][3];

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
      for (v=0; v<4096; v=v+1)
	begin
	  test_re[v] <= 0;
	  test_rfifo[v] <= 0;
	  test_care[v] <= 0;

	  reg_data[v] <= 0;
	  reg_empty[v] <= 0;
	  reg_stop[v] <= 0;
	  reg_careof[v] <= 0;
	end // for (v=0; v<4096; v=v+1)

      // your test data here

      // simple test for emptiness
      test_re[2] <= 1'b1;
      reg_careof[0] <= 3'h4;
      reg_empty[0] <= 4'hf;

      // test receiving a small datagram, with an ignored interrupt
      for (e=4; e<12; e=e+1)
	begin
	  test_we[{e[9:0],2'h2}] <= 1;
	  reg_careof[(e-3)] <= 3;
	  reg_empty[(e-3)] <= 4'h9;
	  reg_stop[(e-3)] <= 4'h9;
	  reg_data[(e-3)] <= {2'h0,2'h2,e[23:0]};
	end
      test_int[{10'd7,2'h2}] <= 1'b1;

      for (l=44; l<52; l=l+1)
	begin
	  test_re[l] <= 1;
	  test_rfifo[l] <= 2'h2;
	end
      reg_empty[8] <= 4'hb;
      reg_stop[8] <= 4'hb;

      // test receiving a datagram, with three outstanding interrupts
      for (o=13; o<22; o=o+1)
	begin
	  test_we[{o[9:0],2'h2}] <= 1;
	  reg_careof[(o-4)] <= 4'hf;
	  reg_empty[(o-4)] <= 4'h9;
	  reg_stop[(o-4)] <= 4'h9;
	  reg_data[(o-4)] <= {2'h0,2'h2,o[23:0]};

	  reg_careof[(o-1)] <= 4'hf;
	  reg_empty[(o-1)] <= 4'h9;
	  reg_stop[(o-1)] <= 4'h9;
	end
      for (v=15; v<22; v=v+1)
	reg_data[(v-3)] <= {2'h0,2'h2,v[23:0]};
      for (e=16; e<22; e=e+1)
	reg_data[(e-2)] <= {2'h0,2'h2,e[23:0]};
      for (l=20; l<22; l=l+1)
	reg_data[(l-1)] <= {2'h0,2'h2,l[23:0]};
      reg_stop[11] <= 4'hb;
      reg_stop[13] <= 4'hb;
      reg_stop[18] <= 4'hb;
      test_int[{10'd15,2'h2}] <= 1;
      test_int[{10'd16,2'h2}] <= 1;
      test_int[{10'd20,2'h2}] <= 1;

      for (o=96; o<108; o=o+1)
	begin
	  test_re[o] <= 1;
	  test_rfifo[o] <= 2'h2;
	  test_care[o] <= 4'hf;
	end
      reg_empty[20] <= 4'hb;
      reg_stop[20] <= 4'hb;

      // test receiving an overflowing datagram, on another channel
      for (e=2; e<318; e=e+1)
	begin
	  test_we[{e[9:0],2'h1}] <= 1;
	end

      for (l=1200; l<(1200+63+17); l=l+1)
	begin
	  test_re[l] <= 1;
	  test_rfifo[l] <= 2'h1;
	  test_care[l] <= 4'hf;
	end
      for (o=2; o<65; o=o+1)
	begin
	  reg_careof[(o+19)] <= 4'hf;
	  reg_empty[(o+19)] <= 4'hb;
	  reg_stop[(o+19)] <= 4'hb;
	  reg_data[(o+19)] <= {2'h0,2'h1,o[23:0]};
	end
      for (v=300; v<318; v=v+1)
	begin
	  reg_careof[(v-216)] <= 4'hf;
	  reg_empty[(v-216)] <= 4'hb;
	  reg_stop[(v-216)] <= 4'hb;
	  reg_data[(v-216)] <= {2'h0,2'h1,v[23:0]};
	end
      reg_empty[101] <= 4'hf;
      reg_stop[101] <= 4'hf;
    end // initial begin

  always @(posedge CLK)
    if (!RST)
      begin
	fast_i <= 0; slow_i <= 0; c <= 0;
	out_c_0 <= 0; out_c_1 <= 0; r_read_0 <= 0; r_read_1 <= 0;
	r_careof <= 0;
      end
    else
      begin
	DATA0 <= wDATA0;
	DATA1 <= wDATA1;
	DATA2 <= wDATA2;
	DATA3 <= wDATA3;
	fast_i <= fast_i +1;
	if (fast_i == 2'h3)
	  slow_i <= slow_i +1;

	c <= c +1;

	r_read_0 <= READ;
	r_read_1 <= r_read_0;
	if (r_read_0)
	  out_c_0 <= out_c_0 +1;
	if (r_read_1)
	  out_c_1 <= out_c_1 +1;
	r_careof <= w_careof;

	begin
	  if (r_read_0)
	    begin
//	      $display("out empty %x stop %x @ %d",
//		       RES_EMPTY, RES_STOP, c);
	      if (w_careof[2])
		if (RES_EMPTY != w_empty)
		  $display("XXX empty #%d want %x got %x @ %d",
			   out_c_0, w_empty, RES_EMPTY, c);
	      if (w_careof[1])
		if (RES_STOP != w_stop)
		  $display("XXX stop #%d want %x got %x @ %d",
			   out_c_0, w_stop, RES_STOP, c);
	    end
	  if (r_read_1)
	    begin
//	      $display("out data %x @ %d",
//		       RES_DATA, c);
	      if (r_careof[0])
		if (RES_DATA != w_data)
		  $display("XXX data #%d want %x got %x @ %d",
			   out_c_1, w_data, RES_DATA, c);
	    end
	end
      end

endmodule // test_in


module GlaDOS;
  reg CLK_p, CLK_n, CLK_dp, CLK_dn, RST, CPU_CLK;
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
  wire 	      w_int0, w_int1, w_int2, w_int3,
	      w_care0, w_care1, w_care2, w_care3;
  reg 	      r_read;

  wire [31:0] w_out;
  wire 	      w_e0, w_e1, w_e2, w_e3,
	      w_s0, w_s1, w_s2, w_s3;

  test_drv test_driver(.CLK(CLK_n),
		       .RST(RST),
		       .DATA0(w_data0),
		       .DATA1(w_data1),
		       .DATA2(w_data2),
		       .DATA3(w_data3),
		       .WRITE(w_write),
		       .WRITE_FIFO(w_write_fifo),
		       .INT0(w_int0),
		       .INT1(w_int1),
		       .INT2(w_int2),
		       .INT3(w_int3),
		       .READ(w_read),
		       .READ_FIFO(w_read_fifo),
		       .CAREOF_INT_0(w_care0),
		       .CAREOF_INT_1(w_care1),
		       .CAREOF_INT_2(w_care2),
		       .CAREOF_INT_3(w_care3),
		       .RES_EMPTY({w_e0,w_e1,w_e2,w_e3}),
		       .RES_STOP({w_s0,w_s1,w_s2,w_s3}),
		       .RES_DATA(w_out));

  lsab_cr lsab_cr_mut(.CLK(CLK_n),
		      .RST(RST),
		      .READ(w_read),
		      .WRITE0(w_write),
		      .WRITE1(w_write),
		      .WRITE2(w_write),
		      .WRITE3(w_write),
		      .READ_FIFO(w_read_fifo),
		      .WRITE_FIFO(w_write_fifo),
		      .IN_0(w_data0),
		      .IN_1(w_data1),
		      .IN_2(w_data2),
		      .IN_3(w_data3),
		      .INT_IN_0(w_int0),
		      .INT_IN_1(w_int1),
		      .INT_IN_2(w_int2),
		      .INT_IN_3(w_int3),
		      .CAREOF_INT_0(w_care0),
		      .CAREOF_INT_1(w_care1),
		      .CAREOF_INT_2(w_care2),
		      .CAREOF_INT_3(w_care3),
		      .OUT(w_out),
		      .EMPTY_0(w_e0),
		      .EMPTY_1(w_e1),
		      .EMPTY_2(w_e2),
		      .EMPTY_3(w_e3),
		      .STOP_0(w_s0),
		      .STOP_1(w_s1),
		      .STOP_2(w_s2),
		      .STOP_3(w_s3));

  always @(posedge CLK_n)
    if (!RST)
      begin
      end
    else
      begin
	counter <= counter +1;
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
      RST <= 0;
      #14.34 RST <= 1;
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
