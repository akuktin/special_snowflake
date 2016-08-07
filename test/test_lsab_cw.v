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
		input 	      RST,
		output [31:0] DATA,
		output 	      WRITE,
		output [1:0]  WRITE_FIFO,
		// -----------------------
		output 	      READ,
		output [1:0]  READ_FIFO,
		// -----------------------
		input [3:0]   RES_BFULL,
		// -----------------------
		input [31:0]  RES_DATA0,
		input [31:0]  RES_DATA1,
		input [31:0]  RES_DATA2,
		input [31:0]  RES_DATA3);
  reg [31:0] 	      test_data[4095:0],
		      reg_data[4095:0];
  reg [3:0] 	      reg_bfull[4095:0];
  reg [2:0] 	      reg_careof_w[4095:0],
		      reg_careof_r[4095:0];
  reg [1:0] 	      test_wfifo[4095:0],
		      test_rfifo[4095:0];
  reg 		      test_we[4095:0],
		      test_re[4095:0],
		      r_read_0, r_read_1, r_write_0;

  reg [1:0] 	      fast_i, r_rfifo_0, r_rfifo_1, r_wfifo_0;
  reg [2:0]	      r_careof_r;
  reg [9:0] 	      slow_i;
  reg [11:0] 	      out_c_0[3:0], out_c_1[3:0];
  reg [11:0] 	      c;

  wire [31:0] 	      wDATA0, wDATA1, wDATA2, wDATA3;
  wire [31:0] 	      w_data;
  wire [11:0] 	      muxed_c_0, muxed_c_1;
  wire [3:0] 	      w_stop, w_empty;
  wire [2:0] 	      w_careof_r, w_careof_w;

  reg [31:0] 	      muxed_data;

  assign muxed_c_0 = out_c_0[r_rfifo_0];
  assign muxed_c_1 = out_c_1[r_rfifo_1];

  assign w_careof_r = reg_careof_r[{r_rfifo_1,muxed_c_1}];
  assign w_careof_w = reg_careof_w[(c-1)];
  assign w_bfull = reg_bfull[(c-1)];
  assign w_data = reg_data[{r_rfifo_1,muxed_c_1}];

  always @(r_rfifo_1 or RES_DATA0 or RES_DATA1 or RES_DATA2 or RES_DATA3)
    case (r_rfifo_1)
      2'h0: muxed_data = RES_DATA0;
      2'h1: muxed_data = RES_DATA1;
      2'h2: muxed_data = RES_DATA2;
      2'h3: muxed_data = RES_DATA3;
      default: muxed_data = 32'hxxxx_xxxx;
    endcase // case (r_rfifo_1)

  assign DATA = test_data[c];

  assign WRITE = test_we[c];
  assign WRITE_FIFO = test_wfifo[c];

  assign READ = test_re[c];
  assign READ_FIFO = test_rfifo[c];

  reg [31:0] 	      l, o, v, e;

  initial
    begin
      for (l=0; l<4096; l=l+1)
	begin
	  test_data[l] <= l;
	  test_we[l] <= 0;
	  test_wfifo[l] <= 0;

	  test_re[l] <= 0;
	  test_rfifo[l] <= 0;

	  reg_data[l] <= 0;
	  reg_bfull[l] <= 0;

	  reg_careof_r[l] <= 0;
	  reg_careof_w[l] <= 0;
	end // for (v=0; v<4096; v=v+1)
      out_c_0[0] <= 0; out_c_0[1] <= 0; out_c_0[2] <= 0; out_c_0[3] <= 0;
      out_c_1[0] <= 0; out_c_1[1] <= 0; out_c_1[2] <= 0; out_c_1[3] <= 0;

      // your test data here
    end // initial begin

  always @(posedge CLK)
    if (!RST)
      begin
	fast_i <= 0; slow_i <= 0; c <= 0;
	r_read_0 <= 0; r_read_1 <= 0; r_write_0 <= 0;
	r_careof_r <= 0; r_rfifo_0 <= 0; r_rfifo_1 <= 0;
	r_wfifo_0 <= 0;
      end
    else
      begin
	fast_i <= fast_i +1;
	if (fast_i == 2'h3)
	  slow_i <= slow_i +1;

	c <= c +1;

	r_write_0 <= WRITE;
	r_wfifo_0 <= WRITE_FIFO;

	r_read_0 <= READ;
	r_read_1 <= r_read_0;
	if (r_read_0)
	  out_c_0[r_rfifo_0] <= out_c_0[r_rfifo_0] +1;
	if (r_read_1)
	  out_c_1[r_rfifo_1] <= out_c_1[r_rfifo_1] +1;

	r_rfifo_0 <= READ_FIFO;
	r_rfifo_1 <= r_rfifo_0;

	begin
	  if (r_write_0)
	    begin
	      if (w_careof_w[1])
		if (RES_BFULL != w_bfull)
		  $display("XXX bfull #%d/%d want %x got %x @ %d",
			   r_wfifo_0, (c-1), w_bfull, RES_BFULL, c);
	    end
	  if (r_read_1)
	    begin
	      if (w_careof_r[0])
		if (muxed_data != w_data)
		  $display("XXX data #%d/%d want %x got %x @ %d",
			   r_rfifo_1, muxed_c_1, w_data, muxed_data, c);
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

  wire [31:0] w_data;
  wire 	      w_write, w_read;
  wire [1:0]  w_write_fifo, w_read_fifo;

  wire [31:0] w_out0, w_out1, w_out2, w_out3;
  wire 	      w_bf0, w_bf1, w_bf2, w_bf3;

  test_drv test_driver(.CLK(CLK_n),
		       .RST(RST),
		       .DATA(w_data),
		       .WRITE(w_write),
		       .WRITE_FIFO(w_write_fifo),
		       .READ(w_read),
		       .READ_FIFO(w_read_fifo),
		       .RES_BFULL({w_bf0,w_bf1,w_bf2,w_bf3}),
		       .RES_DATA0(w_out0),
		       .RES_DATA1(w_out1),
		       .RES_DATA2(w_out2),
		       .RES_DATA3(w_out3));

  lsab_cw lsab_cw_mut(.CLK(CLK_n),
		      .RST(RST),
		      .READ(w_read),
		      .WRITE(w_write),
		      .READ_FIFO(w_read_fifo),
		      .WRITE_FIFO(w_write_fifo),
		      .IN(w_data),
		      .OUT_0(w_out0),
		      .OUT_1(w_out1),
		      .OUT_2(w_out2),
		      .OUT_3(w_out3),
		      .BFULL_0(w_bf0),
		      .BFULL_1(w_bf1),
		      .BFULL_2(w_bf2),
		      .BFULL_3(w_bf3));

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
