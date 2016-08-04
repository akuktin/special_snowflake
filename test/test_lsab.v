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
		      r_read;

  reg [1:0] 	      fast_i;
  reg [9:0] 	      slow_i;
  reg [11:0] 	      c, out_c;

  wire [31:0] 	      wDATA0, wDATA1, wDATA2, wDATA3;
  wire [31:0] 	      w_data;
  wire [3:0] 	      w_stop, w_empty;
  wire [2:0] 	      w_careof;

  assign w_careof = reg_careof[out_c];
  assign w_empty = reg_empty[out_c];
  assign w_stop = reg_stop[out_c];
  assign w_data = reg_data[out_c];

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

  reg [31:0] 	      l, o, v;

  initial
    begin
      for (l=0; l<1024; l=l+1)
	begin
	  for (o=0; o<4; o=o+1)
	    begin
	      test_data[{l[8:0],o[1:0]}] <= {2'h0,o[1:0],l[23:0]};
	      test_we[{l[8:0],o[1:0]}] <= 0;
	      test_int[{l[8:0],o[1:0]}] <= 0;
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
	end

      // your test data here
    end // initial begin

  always @(posedge CLK)
    if (!RST)
      begin
	fast_i <= 0; slow_i <= 0; c <= 0; r_read <= 0; out_c <= 0;
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

	r_read <= READ;
	if (r_read)
	  out_c <= out_c +1;

	begin
	  if (r_read)
	    begin
	      if (w_careof[2])
		if (RES_EMPTY != w_empty)
		  $display("XXX empty want %x got %x @ %x",
			   w_empty, RES_EMPTY, c);
	      if (w_careof[1])
		if (RES_STOP != w_stop)
		  $display("XXX stop want %x got %x @ %x",
			   w_empty, RES_EMPTY, c);
	      if (w_careof[0])
		if (RES_DATA != w_data)
		  $display("XXX data want %x got %x @ %x",
			   w_empty, RES_EMPTY, c);
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
		       .CAREOF_INT_0(w_care_0),
		       .CAREOF_INT_1(w_care_1),
		       .CAREOF_INT_2(w_care_2),
		       .CAREOF_INT_3(w_care_3),
		       .RES_EMPTY({w_e0,w_e1,w_e2,w_e3}),
		       .RES_STOP({w_s0,w_s1,w_s2,w_s3}),
		       .RES_DATA(w_out));

  lsab_cr lsab_cr_mut(.CLK(CLK_n),
		      .RST(RST),
		      .READ(w_read),
		      .WRITE(w_write),
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
      end // else: !if(!RST)

  initial
    begin
      counter <= 0;
      RST <= 0;
      #14.34 RST <= 1;
      #18432 $finish;
    end

endmodule // GlaDOS
