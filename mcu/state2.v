`define NOOP 3'b111 /* no operation */
`define ACTV 3'b011 /* activate (row open) */
`define READ 3'b101 /* read */
`define WRTE 3'b100 /* write */
`define BTRM 3'b110 /* burst terminate */
`define PRCH 3'b010 /* precharge (row close) */
`define ARSR 3'b001 /* auto refresh/self refresh */
`define MRST 3'b000 /* mode register set */

module state2(input CLK,
	      input 		RST,
	      input 		REFRESH_STROBE,
	      /* random port */
	      input [25:0] 	ADDRESS_RAND,
	      input 		WE_RAND,
	      input 		REQUEST_ACCESS_RAND,
	      output reg 	GRANT_ACCESS_RAND,
	      input [3:0] 	WE_ARRAY_RAND,
	      /* bulk_port */
	      input [25:0] 	ADDRESS_BULK,
	      input 		WE_BULK,
	      input 		REQUEST_ACCESS_BULK,
	      output reg 	GRANT_ACCESS_BULK,
	      input 		REQUEST_ALIGN_BULK,
	      output reg 	GRANT_ALIGN_BULK,
	      input [3:0] 	WE_ARRAY_BULK,
	      /* end ports */
	      output reg [12:0] ADDRESS_REG,
	      output reg [1:0] 	BANK_REG,
	      output reg [2:0] 	COMMAND_REG,
	      output [3:0] 	INTERNAL_COMMAND_LATCHED,
	      output reg [3:0] 	INTERNAL_WE_ARRAY);
  reg 				     change_possible_n, state_is_readwrite,
				     refresh_strobe_ack, state_is_write,
				     SOME_PAGE_ACTIVE, second_stroke,
				     REFRESH_TIME;
  reg [2:0] 			     command_reg2, actv_timeout;
  reg [3:0] 			     counter;
  reg [13:0] 			     page_current;

  wire 				     issue_com, correct_page_any,
				     correct_page_rand, correct_page_bulk,
				     correct_page_algn, correct_page_rdy,
				     change_possible_w_n, write_match,
				     timeout_norm_comp_n,
				     timeout_dlay_comp_n,
				     want_PRCH_delayable,
				     issue_enable_override,
				     issue_enable_on_page;
  wire [1:0] 			     bank_addr,
				     bank_request_live_bulk,
				     bank_request_live_rand;
  wire [2:0] 			     command, command_wr;
  wire [3:0] 			     we_array;
  wire [11:0] 			     row_request_live_bulk,
				     row_request_live_rand;
  wire [12:0] 			     address;
  wire [13:0] 			     page;
  wire [25:0] 			     address_in;

  reg [2:0] 			     command_non_wr;

  assign INTERNAL_COMMAND_LATCHED = {second_stroke,command_reg2};

  assign row_request_live_rand = ADDRESS_RAND[25:14];
  assign bank_request_live_rand = ADDRESS_RAND[13:12];

  assign correct_page_rand = ({REQUEST_ACCESS_RAND,REQUEST_ALIGN_BULK,
			       REFRESH_TIME,SOME_PAGE_ACTIVE,
                               row_request_live_rand,bank_request_live_rand}
			      == {4'b1001,page_current});

  assign row_request_live_bulk = ADDRESS_BULK[25:14];
  assign bank_request_live_bulk = ADDRESS_BULK[13:12];

  assign correct_page_bulk = ({REQUEST_ACCESS_BULK,
			       REFRESH_TIME,SOME_PAGE_ACTIVE,
                               row_request_live_bulk,bank_request_live_bulk}
			      == {3'b101,page_current});

  assign correct_page_algn = ({REQUEST_ALIGN_BULK,
                               REFRESH_TIME,SOME_PAGE_ACTIVE,
                               row_request_live_bulk,bank_request_live_bulk}
			      == {3'b101,page_current});

  assign correct_page_any = correct_page_rand || correct_page_bulk;
  assign correct_page_rdy = correct_page_rand || correct_page_algn;

  assign write_match = REQUEST_ACCESS_BULK ? WE_BULK :
		       (REQUEST_ACCESS_RAND && WE_RAND);

  assign issue_com = (correct_page_any && issue_enable_on_page) ||
		     issue_enable_override;

  assign issue_enable_on_page = second_stroke && state_is_readwrite &&
				(state_is_write ?
				 write_match :
				 (!write_match));

  assign issue_enable_override = second_stroke && (!change_possible_n) &&
				 (REQUEST_ACCESS_RAND ||
				  REQUEST_ACCESS_BULK ||
				  REFRESH_TIME ||
				  // FIXME: not good enough
				  (REQUEST_ALIGN_BULK &&
				   (!GRANT_ALIGN_BULK)));

  always @(SOME_PAGE_ACTIVE or REFRESH_TIME or actv_timeout[2])
    case ({SOME_PAGE_ACTIVE,REFRESH_TIME,actv_timeout[2]})
      /*
       Short form:
      3'b1x1: command_non_wr <= `PRCH;
      3'b01x: command_non_wr <= `ARSR;
      3'b00x: command_non_wr <= `ACTV;
       */
      3'b101: command_non_wr <= `PRCH;
      3'b111: command_non_wr <= `PRCH;
      3'b010: command_non_wr <= `ARSR;
      3'b011: command_non_wr <= `ARSR;
      3'b000: command_non_wr <= `ACTV;
      3'b001: command_non_wr <= `ACTV;
      default: command_non_wr <= `NOOP;
    endcase // case ({SOME_PAGE_ACTIVE,REFRESH_TIME,actv_timeout[2]})

  assign want_PRCH_delayable = SOME_PAGE_ACTIVE && state_is_write;

  // Actually not a mux, but a single gate, like command_non_wr.
  assign command_wr = write_match ? `WRTE : `READ;

  assign command = correct_page_any ? command_wr : command_non_wr;

  assign address_in = REQUEST_ALIGN_BULK ? ADDRESS_BULK : ADDRESS_RAND;

  /* The below three are ported from an earlier iteration. They probably
   * could not be developed with this module microarchitecture if the
   * module were to be developed from scratch. */
  assign address = correct_page_rdy ?
		   {address_in[11:0],1'b0} :
		   {address_in[25:24],1'b0,address_in[23:14]};
  assign page = correct_page_rdy ?
		page_current :
		address_in[25:12];
  assign bank_addr = correct_page_rdy ?
		     BANK_REG :
		     address_in[13:12];

  assign timeout_norm_comp_n = !((counter == 4'hd) || (counter == 4'he));
  assign timeout_dlay_comp_n = !((counter == 4'hf) || (counter == 4'h0)); // sped up

  /* Fully synthetizable in three gates, may need to be rewritten to help
   * the synthetizer. */
  assign change_possible_w_n = ~second_stroke ? 1 :
			       correct_page_any ? timeout_norm_comp_n :
			       (want_PRCH_delayable ?
				timeout_dlay_comp_n : timeout_norm_comp_n);

  assign we_array = REQUEST_ACCESS_BULK ? WE_ARRAY_BULK : WE_ARRAY_RAND;

  always @(posedge CLK)
    if (!RST)
      begin
	COMMAND_REG <= `NOOP; ADDRESS_REG <= 13'h0400; BANK_REG <= 0;
	GRANT_ACCESS_RAND <= 0; GRANT_ACCESS_BULK <= 0;
	change_possible_n <= 1; state_is_readwrite <= 0;
	refresh_strobe_ack <= 0; state_is_write <= 0; SOME_PAGE_ACTIVE <= 0;
	second_stroke <= 1; REFRESH_TIME <= 0;
	command_reg2 <= `NOOP; actv_timeout <= 3'h7; counter <= 4'he;
	page_current <= 0; GRANT_ALIGN_BULK <= 0; INTERNAL_WE_ARRAY <= 0;
      end
    else
      begin
	REFRESH_TIME <= refresh_strobe_ack ^ REFRESH_STROBE;
	if ((!second_stroke) && (command_reg2 == `ACTV))
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
	    (! correct_page_rdy))
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
	      `ARSR: counter <= 4'h3;
	      `ACTV: counter <= 4'hc;
	      `PRCH: counter <= 4'hc; // sped up
	      `READ: counter <= 4'hc; // sped up
	      `WRTE: counter <= 4'hc; // sped up
	      `NOOP: counter <= 4'he;
	      default: counter <= 4'hb;
	    endcase // case (command_reg2)
	  end // if (!second_stroke)
	else
	  counter <= counter + change_possible_n;

	if (issue_com)
	  begin
	    change_possible_n <= 1;
	    state_is_readwrite <= correct_page_any;

	    GRANT_ACCESS_RAND <= correct_page_rand;
	    GRANT_ACCESS_BULK <= correct_page_bulk;

	    INTERNAL_WE_ARRAY <= we_array;
	  end

	if (!issue_com)
	  begin
	    change_possible_n <= change_possible_w_n;

	    GRANT_ACCESS_RAND <= 0;
	    GRANT_ACCESS_BULK <= 0;
	  end

	GRANT_ALIGN_BULK <= correct_page_algn;
      end

endmodule // enter_state

module outputs(input CLK_p,
	       input 		 CLK_n,
	       input 		 CLK_dp,
	       input 		 CLK_dn,
	       input 		 RST,
	       input [3:0] 	 COMMAND_LATCHED,
	       input [3:0] 	 WE_ARRAY,
	       input [31:0] 	 DATA_W,
	       inout [15:0] 	 DQ,
	       inout 		 DQS,
	       output reg [31:0] DATA_R,
	       output 		 DM);
  reg [3:0] 			 do_read;

  reg [31:0] 			 dq_driver_pre;
  reg [15:0] 			 dq_driver_h, dq_driver_l,
				 dq_driver_holdlong;

  reg 				 DM_drive, we_1,
				 pre_DMs, dDM;
  reg 				 command_was_latched;
  reg [1:0] 			 dq_n, we_array_save;
  reg 				 dq_p;
  wire 				 did_issue_write;

  reg [15:0] 			 DQ_driver;
  wire 				 we_0, dq_n_in;

  assign reading = do_read[3];

  assign DM = DM_drive;
  assign DQ = DM_drive ? {16{1'bz}} : DQ_driver; // may be a bad idea
  assign DQS = ({dq_n,dq_p} == 0) ? 1'bz : CLK_p;

  assign we_0 = (did_issue_write | command_was_latched);
  assign dq_n_in = did_issue_write;

  assign did_issue_write = COMMAND_LATCHED == {1'b0,`WRTE};

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
	we_1 <= 0;
      end
    else
      begin
	dq_driver_pre <= DATA_W;
	dq_driver_h <= dq_driver_pre[31:16];
	dq_driver_holdlong <= dq_driver_pre[15:0];

	command_was_latched <= did_issue_write;
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

	we_array_save <= WE_ARRAY[1:0];
	pre_DMs <= !(did_issue_write ?
		     (WE_ARRAY[2] || WE_ARRAY[3]) :
		     (we_array_save[0] || we_array_save[1]));
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
