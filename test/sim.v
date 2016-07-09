`define x4
`define sq5E

`include "ddr.v"
`include "../mcu/commands.v"
`include "../mcu/state2.v"
`include "../mcu/initializer.v"
`include "../mcu/integration2.v"

module GlaDOS;
  reg CLK_p, CLK_n, CLK_dp, CLK_dn, RST;
  reg [31:0] counter, readcount, readcount2, readcount_r;

  reg [31:0] data_read, transtest;

  reg [26:0]  user_req_address;
  reg 	      user_req_we, user_req;
  reg [31:0]  user_req_datain;
  reg         inhibit_ack;
  wire 	      user_req_ack;
  wire [31:0] user_req_dataout;

  wire 	      CKE, DQS, DM, CS;
  wire [2:0]  COMMAND;
  wire [12:0] ADDRESS;
  wire [1:0]  BANK;
  wire [15:0] DQ;

  ddr ddr_mem(.Clk(CLK_p),
	      .Clk_n(CLK_n),
	      .Cke(CKE),
	      .Cs_n(CS),
	      .Ras_n(COMMAND[2]),
	      .Cas_n(COMMAND[1]),
	      .We_n(COMMAND[0]),
	      .Ba(BANK),
	      .Addr(ADDRESS),
	      .Dm(DM),
	      .Dq(DQ),
	      .Dqs(DQS));

  ddr_memory_controler ddr_mc(.CLK_n(CLK_n),
			      .CLK_p(CLK_p),
			      .CLK_dp(CLK_dp),
			      .CLK_dn(CLK_dn),
			      .RST(RST),
			      .CKE(CKE),
			      .COMMAND(COMMAND),
			      .ADDRESS(ADDRESS),
			      .BANK(BANK),
			      .DQ(DQ),
			      .DQS(DQS),
			      .DM(DM),
			      .CS(CS),
			      .user_req_address(user_req_address),
			      .user_req_we(user_req_we),
			      .user_req_we_array(4'b1111),
			      .user_req(user_req),
			      .user_req_datain(user_req_datain),
			      .user_req_ack(user_req_ack),
			      .user_req_dataout(user_req_dataout));

  initial
    forever
      begin
	#1.5 CLK_n <= 0; CLK_p <= 1;
	#1.5 CLK_dp <= 1; CLK_dn <= 0;
	#1.5 CLK_n <= 1; CLK_p <= 0;
	#1.5 CLK_dp <= 0; CLK_dn <= 1;
      end

  initial
    begin
      RST <= 0;
      inhibit_ack <= 0;
      counter <= 0;
      user_req_address <= 0;
      user_req_we <= 1;
      user_req <= 0;
      user_req_datain <= 32'h5a5ab00b;
      readcount_r <= 0;
      #14.875 RST <= 1;

      #400000;
      /* assuming an inactive memory, activates a page some cycles
         before the time for refresh comes around */
////      #3878;
      /* assuming an inactive memory, activates a page the same
         cycle that the time for refresh comes around */
////      #3884;
//      #3866;
      #3867;
      /* assuming an inactive memory, attempts to activate a page
         on the cycle after the time for refresh comes around */
////      #3890;
      /* assuming an inactive memory, attempts to activate a page
         some cycles after the time for refresh comes around */
////      #3896;

//#3800;

inhibit_ack <= 1;
      user_req <= 1;
      #34;
      #32;
#6
//  user_req_we <= 0;//1;
      #6;
      user_req <= 1;
      #200  user_req_address <= 32'h0010_1100;
      #100  user_req_we <= 0;
//      #300 user_req_we <= 0;
#100 $finish;
#64 $finish;

//      #12775;
      #20000;

      user_req <= 1;
      user_req_we <= 0;
      inhibit_ack <= 1;
      #128;
      user_req <= 0;

      #20000;
      $finish;
    end // initial begin

  always @(posedge CLK_n)
    begin
      if (readcount || readcount2 || user_req)
//	$display("r: %x, r2: %x, --cmd: %x, com_buf: %x, actv_t: %x, pgac: %x, rtm: %x",
/*	$display("r: %x, rr: %x, --cmd: %x, crq: %x, com_buf: %x, actv_t: %x, rtm: %x, pgac: %x",
//		 readcount, readcount2, COMMAND,
		 readcount, {user_req, user_req_we,
                             ddr_mc.interdictor.CHANGE_POSSIBLE,
			     ddr_mc.interdictor.CHANGE_REQUESTED}, COMMAND,
                 ddr_mc.state_tracker.COMMAND,
		 ddr_mc.interdictor.command_buf,
		 ddr_mc.interdictor.actv_timeout,
		 {ddr_mc.interdictor.REFRESH_TIME,
		  ddr_mc.state_tracker.refresh_strobe_ack,
		  ddr_mc.state_tracker.REFRESH_STROBE},
		 ddr_mc.interdictor.SOME_PAGE_ACTIVE);*/
//	$display("r: %x, r2: %x, --cmd: %x, user_req: %x, user_req_ack: %x",
//		 readcount, readcount2, COMMAND, user_req, user_req_ack);

      if (user_req_ack)
	begin
	if (!inhibit_ack)
	  user_req <= 0;
	readcount_r <= 0;


//	  $display("user_req_ack asserted, user_req_address: %x, readcount: %x", user_req_address, readcount);
//	  user_req <= 0;

//x	  if (!user_req_we)
	    readcount <= 70;
	  if (readcount2 != 0)
	    begin
//	      $display("disabling user_req");
	      user_req <= 0;
	      readcount2 <= readcount -1;
	    end
//	  else
//	    user_req_address <= user_req_address ^ 27'h00010000;

//	  user_req_we <= ~user_req_we;
//	  user_req_we <= 0;
	end
      else
	begin
	if (readcount != 0)
	  readcount <= readcount -1;
//	if (readcount_r != 0)
	  readcount_r <= readcount_r +1;
	end
      if (readcount2 != 0)
	readcount2 <= readcount2 -1;

      if (readcount_r == 3)
	$display("__read: %x", user_req_dataout);
      if ((readcount == 4) || (readcount2 == 4))
	begin
	  $display("__read: %x", user_req_dataout);
	end

    end // always @ (posedge CLK_n)

/*
  always @(posedge CLK_dp or posedge CLK_dn)
    begin
      if (readcount != 0)
	begin
	  $display("__> DM: %x, DQ: %x, DQS: %x, read: %x", DM, DQ, DQS, user_req_dataout);
	end
    end
*/
  always @(posedge CLK_dp)
    transtest[31:16] <= DQ;

  always @(posedge CLK_dn)
    transtest[15:0] <= DQ;

/*
  always @(posedge CLK_p)
    begin
      counter <= counter +1;

      if (counter == 64'h0000_0000)
	$finish;
    end
 */

endmodule // GlaDOS
