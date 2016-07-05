`define NOOP 3'b111 /* no operation */
`define ACTV 3'b011 /* activate (row open) */
`define READ 3'b101 /* read */
`define WRTE 3'b100 /* write */
`define BTRM 3'b110 /* burst terminate */
`define PRCH 3'b010 /* precharge (row close) */
`define ARSR 3'b001 /* auto refresh/self refresh */
`define MRST 3'b000 /* mode register set */

module enter_state(input CLK,
		   input 	     RST,
		   input 	     REFRESH_TIME,
		   /* random port */
		   input [25:0]      ADDRESS_RAND,
		   input 	     WE_RAND,
		   input 	     REQUEST_ACCESS_RAND,
		   /* bulk_port */
		   input [25:0]      ADDRESS_BULK,
		   input 	     WE_BULK,
		   input 	     REQUEST_ACCESS_BULK,
		   /* end */
		   input 	     CHANGE_POSSIBLE,
		   input 	     SOME_PAGE_ACTIVE,
		   output reg [12:0] ADDRESS_REG,
		   output reg [1:0]  BANK_REG,
		   output reg [2:0]  COMMAND_REG,
		   output [2:0]      COMMAND,
		   output 	     CHANGE_REQUESTED,
		   output 	     COMMAND_LATCHED);
  reg [13:0] 			    page_current;
  reg [2:0] 			    actv_timeout,
				    command_buf;
  reg 				    refresh_time_reg,
				    active_page_delay;

  wire [2:0] 			    rw_command;

  wire [11:0] 			    row_request_live;
  wire [1:0] 			    bank_request_live;
  wire [12:0] 			    collumn_request_live;

  assign row_request_live_rand = ADDRESS_RAND[25:14];
  assign bank_request_live_rand = ADDRESS_RAND[13:12];
  assign collumn_request_live_rand = {ADDRESS_RAND[11:0],1'b0};

  assign correct_page_rand = ({REQUEST_ACCESS_RAND,REQUEST_ACCESS_BULK,
			       REFRESH_TIME,SOME_PAGE_ACTIVE,
                               row_request_live_rand,bank_request_live_rand}
			      == {4'b1001,page_current});

  assign row_request_live_bulk = ADDRESS_BULK[25:14];
  assign bank_request_live_bulk = ADDRESS_BULK[13:12];
  assign collumn_request_live_bulk = {ADDRESS_BULK[11:0],1'b0};

  assign correct_page_bulk = ({REQUEST_ACCESS_BULK,
			       REFRESH_TIME,SOME_PAGE_ACTIVE,
                               row_request_live_bulk,bank_request_live_bulk}
			      == {3'b101,page_current});

  assign correct_page_any = correct_page_rand || correct_page_bulk;

  assign write_match = REQUEST_ACCESS_BULK ? WE_BULK :
		       (REQUEST_ACCESS_RAND && WE_RAND);

  assign issue_com = (correct_page_any && issue_enable_on_page) ||
		     issue_enable_override;

  // Signals from `states' module.
  assign issue_enable_on_page = second_stroke && state_is_readwrite &&
				(state_is_write ?
				 write_match :
				 (!write_match));

  // Signals from `states' module.
  assign issue_enable_override = second_stroke && (!change_possible_n) &&
				 (REQUEST_ACCESS_RAND ||
				  REQUEST_ACCESS_BULK);

  always @(SOME_PAGE_ACTIVE or REFRESH_TIME or actv_timeout[2])
    case ({SOME_PAGE_ACTIVE,REFRESH_TIME,actv_timeout[2]})
      3'b1x1: command_non_wr <= `PRCH;
      3'b01x: command_non_wr <= `ARSR;
      3'b00x: command_non_wr <= `ACTV;
      default: command_non_wr <= `NOOP;
    endcase // case ({SOME_PAGE_ACTIVE,REFRESH_TIME,actv_timeout[2]})

  assign want_PRCH_delayable = SOME_PAGE_ACTIVE && state_is_write;

  // Actually not a mux, but a single gate, like command_non_wr.
  assign command_wr = write_match ? `WRTE : `READ;

  assign command = correct_page_any ? command_wr : command_non_wr;

  assign address_in = REQUEST_ACCESS_BULK ? ADDRESS_BULK : ADDRESS_RAND;

  /* The below three are ported from an earlier iteration. They probably
   * could not be developed with this module microarchitecture if the
   * module were to be developed from scratch. */
  assign address = correct_page_any ?
		   {address_in[11:0],1'b0} :
		   {address_in[25:24],1'b0,address_in[23:14]};
  assign page = correct_page_any ?
		page_current :
		address_in[25:14];
  assign bank_addr = correct_page_any ?
		     BANK_REG :
		     address_in[13:12];

  assign timeout_norm_comp_n = counter != 4'he;
  assign timeout_dlay_comp_n = counter != 4'hf;

  assign change_possible_w_n = correct_page_any ? timeout_norm_comp_n :
			       (want_PRCH_delayable ?
				timeout_dlay_comp_n : timeout_norm_comp_n);

  always @(posedge CLK)
    if (!RST)
      begin
	COMMAND_REG <= `NOOP;
	miss_beat <= 0;
	ADDRESS_REG <= 13'h0400;
      end
    else
      begin
	refresh_time_reg <= REFRESH_TIME;
	active_page_delay <= SOME_PAGE_ACTIVE; // FIXME: this used to have
                                               // a lower latency.
	if ((!active_page_delay) & SOME_PAGE_ACTIVE)
	  actv_timeout <= 3'h0;
	else
	  if (!actv_timeout[2])
	    actv_timeout <= actv_timeout +1;

	if (issue_com)
	  begin
	    COMMAND_REG <= command;
	    command_reg2 <= command;
	  end
	else
	  begin
	    COMMAND_REG <= `NOOP;
	    command_reg2 <= `NOOP;
	  end

	if (SOME_PAGE_ACTIVE &&
	    (! correct_page_any))
	  ADDRESS_REG <= 13'h0400;
	else
	  if (issue_com)
	    begin
	      page_current <= page;
	      ADDRESS_REG <= address;
	      BANK_REG <= bank_addr;
	    end

	// The below used to be in the state tracker
	// -----------------------------------------
	second_stroke <= ~issue_com;

	if (!second_stroke)
	  begin
	    if (command_reg2 == `ACTV)
	      SOME_PAGE_ACTIVE <= 1;
	    if (command_reg2 == `PRCH)
	      SOME_PAGE_ACTIVE <= 0;
	    if (command_reg2 == `WRTE)
	      state_is_write <= 1;
	    else if (command_reg2 != `NOOP)
	      state_is_write <= 0;
	    if (command_reg2 == `ARSR)
	      refresh_strobe_ack <= REFRESH_STROBE;

	    case (command_reg2)
	      `ARSR: counter <= 4'h4;
	      `ACTV: counter <= 4'hd;
	      `NOOP: counter <= 4'he;
	      default: counter <= 4'hc;
	    endcase // case (command_reg2)
	  end // if (!second_stroke)
	else
	  counter <= counter + change_possible_n;

	if (issue_com)
	  begin
	    change_possible_n <= 0;
	    state_is_readwrite <= correct_page_any;
	  end

	if (!issue_com)
	  change_possible_n <= change_possible_w_n;
      end

endmodule // enter_state

module outputs(input CLK_p,
	       input 		 CLK_n,
	       input 		 CLK_dp,
	       input 		 CLK_dn,
	       input 		 RST,
	       input 		 COMMAND_LATCHED,
	       input [31:0] 	 DATA_W,
	       input 		 WE,
	       inout [15:0] 	 DQ,
	       inout 		 DQS,
	       output reg [31:0] DATA_R,
	       output 		 DM);
  reg [3:0] 			 do_read;

  reg [31:0] 			 dq_driver_pre;
  reg [15:0] 			 dq_driver_h, dq_driver_l,
				 dq_driver_holdlong;

  reg 				 DM_drive, we_save, we_1,
				 pre_DMs, dDM;
  reg [1:0]			 command_was_latched;
  reg [1:0] 			 dq_n;
  reg 				 dq_p;

  reg [15:0] 			 DQ_driver;
  wire 				 we_0, dq_n_in;

  assign reading = do_read[3];

  assign DM = DM_drive;
  assign DQ = DM_drive ? {16{1'bz}} : DQ_driver;
  assign DQS = ({dq_n,dq_p} == 0) ? 1'bz : CLK_p;

  assign we_0 = we_save & (command_was_latched[0] | command_was_latched[1]);
  assign dq_n_in = we_save & command_was_latched[0];

  always @(*)
    begin
      case ({we_1,DM_drive,dDM,CLK_dn})
	4'b0xxx: DQ_driver = dq_driver_l;
	4'b1000: DQ_driver = dq_driver_l;
	default: DQ_driver = dq_driver_h;
      endcase
    end

  always @(posedge CLK_n)
    if (!RST)
      begin
	dq_driver_pre <= 0;
	dq_driver_h <= 0;
	dq_driver_holdlong <= 0;
	command_was_latched <= 0;
	we_save <= 0;
	we_1 <= 0;
      end
    else
      begin
	dq_driver_pre <= DATA_W;
	dq_driver_h <= dq_driver_pre[31:16];
	dq_driver_holdlong <= dq_driver_pre[15:0];

	command_was_latched <= {command_was_latched[0],COMMAND_LATCHED};
	we_save <= WE;
	we_1 <= we_0;
      end // else: !if(!RST)

  always @(negedge CLK_p) // important for signal propagation
    if (!RST)
      dq_n <= 0;
    else
      dq_n <= {dq_n[0],dq_n_in};

  always @(posedge CLK_p)
    if (!RST)
      begin
	dq_driver_l <= 0;
	pre_DMs <= 0;
	dDM <= 0;
	dq_p <= 0;
      end
    else
      begin
	dq_driver_l <= dq_driver_holdlong;

	pre_DMs <= ~we_0;
	dDM <= pre_DMs;

	dq_p <= dq_n[1];
      end

  always @(posedge CLK_dp)
    DATA_R[15:0] <= DQ;

  always @(posedge CLK_dn)
    begin
      DATA_R[31:16] <= DQ;

      if (!RST)
	DM_drive <= 0;
      else
	DM_drive <= pre_DMs;
    end

endmodule // outputs
