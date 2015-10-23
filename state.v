module states(input CLK,
	      input 	       RST,
	      input 	       CHANGE_REQUESTED,
	      input [2:0]      COMMAND,
	      input 	       REFRESH_STROBE,
	      output 	       CHANGE_POSSIBLE,
	      output reg [2:0] STATE,
	      output reg       SOME_PAGE_ACTIVE,
	      output 	       REFRESH_TIME);
  reg [3:0] 	     counter;
  reg 		     state_is_readwrite,
		     change_possible_counter,
		     miss_beat,
		     refresh_strobe_ack;

  wire 		     do_miss_beat;

  assign CHANGE_POSSIBLE = (change_possible_counter ||
			    (state_is_readwrite && (COMMAND == STATE))) ?
			   1 : 0;
  assign REFRESH_TIME = refresh_strobe_ack ^ REFRESH_STROBE;

  assign do_miss_beat = miss_beat && (COMMAND == `PRCH);

  always @(posedge CLK)
    if (!RST)
      begin
	SOME_PAGE_ACTIVE <= 0;
	counter <= 4'hf;
	state_is_readwrite <= 0;
	STATE <= `PRCH;
	change_possible_counter <= 0;
	miss_beat <= 0;
	refresh_strobe_ack <= REFRESH_STROBE;
      end
    else
      if (CHANGE_POSSIBLE)
	begin
	  if (CHANGE_REQUESTED)
	    begin
	      change_possible_counter <= 0;
	      STATE <= COMMAND;
	      state_is_readwrite <= ((COMMAND == `READ) ||
				     (COMMAND == `WRTE));

	      if (COMMAND == `ACTV)
		SOME_PAGE_ACTIVE <= 1;
	      if (COMMAND == `PRCH)
		SOME_PAGE_ACTIVE <= 0;
	      if (COMMAND == `WRTE)
		miss_beat <= 1;
	      if (COMMAND == `ARSR)
		refresh_strobe_ack <= REFRESH_STROBE;

	      case (COMMAND)
		`ARSR: counter <= 4'h3;
		`ACTV: counter <= 4'hc;
		`READ: counter <= 4'hc;
		`WRTE: counter <= 4'hc;
		`PRCH: counter <= 4'hb;
		`NOOP: counter <= 4'he;
		default: counter <= 4'hb;
	      endcase // case (COMMAND)
	    end
	end // if (CHANGE_POSSIBLE)
      else
	begin
	  counter <= counter +1;

	  if (counter == {3'h7,do_miss_beat})
	    begin
	      miss_beat <= 0;
	      change_possible_counter <= 1;
	    end
	end

endmodule // states

/* Push address, data (if any) and we onto wires and assert DO_ACT.
 * When COMMAND_LATCHED is sensed as asserted, either deassert DO_ACT
 * or push the next batch of address, data (if any) and we.
 * Writing is fire-and-forget. When COMMAND_LATCHED is sensed asserted,
 * you as the memory client are done. If reading, when you sense
 * COMMAND_LATCHED, set a counter to 0. Afterwards, increment the counter
 * by one every cycle. When the counter is sensed to equal 3, the
 * DATA_READ output is valid. */
module enter_state(input CLK,
		   input 	     RST,
		   input 	     REFRESH_TIME,
		   input [25:0]      ADDRESS_REQ,
		   input 	     WE,
		   input 	     DO_ACT,
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

  assign row_request_live = ADDRESS_REQ[25:14];
  assign bank_request_live = ADDRESS_REQ[13:12];
  assign collumn_request_live = {ADDRESS_REQ[11:0],1'b0};

  assign latch_com = DO_ACT && CHANGE_POSSIBLE;
  assign correct_page = ({REFRESH_TIME,SOME_PAGE_ACTIVE,row_request_live,bank_request_live}
			 == {2'b01,page_current});
  assign rw_command = WE ? `WRTE : `READ;

  assign CHANGE_REQUESTED = DO_ACT || refresh_time_reg;
  assign COMMAND = correct_page ? rw_command : command_buf;
  assign COMMAND_LATCHED = correct_page && latch_com;


  always @(posedge CLK)
    if (!RST)
      begin
	command_buf <= `PRCH;
	COMMAND_REG <= `NOOP;
	page_current <= 0;
	ADDRESS_REG <= 13'h0400;
	BANK_REG <= 0;
	refresh_time_reg <= 0;
      end
    else
    begin
      refresh_time_reg <= REFRESH_TIME;
      active_page_delay <= SOME_PAGE_ACTIVE;
      if (~active_page_delay & SOME_PAGE_ACTIVE)
	actv_timeout <= 3'h0;
      else
	if (!actv_timeout[2])
	  actv_timeout <= actv_timeout +1;

      if (correct_page)
	begin
	  if (latch_com)
	    begin
	      COMMAND_REG <= rw_command;
	      ADDRESS_REG <= collumn_request_live;
	    end
	  else
	    COMMAND_REG <= `NOOP;
	end // if (correct_page)
      else
	begin
	  if (CHANGE_POSSIBLE &&
	      ((DO_ACT && !REFRESH_TIME) ||
	       refresh_time_reg))
	    COMMAND_REG <= command_buf;
	  else
	    COMMAND_REG <= `NOOP;

	  if (SOME_PAGE_ACTIVE)
	    begin
	      ADDRESS_REG <= 13'h0400;
	      if (!actv_timeout[2])
		command_buf <= `NOOP;
	      else
		command_buf <= `PRCH;
	    end
	  else
	    begin
	      page_current <= {row_request_live,bank_request_live};
	      ADDRESS_REG <= {row_request_live[11:10],1'b0,row_request_live[9:0]};
	      BANK_REG <= bank_request_live;

	      if (REFRESH_TIME)
		command_buf <= `ARSR;
	      else
		command_buf <= `ACTV;
	    end // else: !if(SOME_PAGE_ACTIVE)
	end // else: !if(correct_page)
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
  reg [15:0] 			 dq_driver_h, dq_driver_l, dq_driver_holdlong;
  reg [31:0] 			 dq_driver_pre;
  reg 				 dqs_driver;
  reg 				 will_write, do_write, do_halfwrite,
				 do_deltawrite;
  reg [3:0] 			 do_read;

  wire [15:0] 			 dq_sig;
  wire 				 will_read, reading;

  assign DM = ~do_deltawrite;
  assign DQ = do_deltawrite ? dq_sig : {16{1'bz}};
  assign DQS = (do_write || do_halfwrite) ? dqs_driver : 1'bz;

  assign dq_sig = CLK_dp ? dq_driver_l : dq_driver_h;

  assign will_read = ((~WE) & COMMAND_LATCHED);
  assign reading = do_read[3];

  always @(CLK_n)
    /* This needs to result in dqs_driver being
     * a mirror image of CLKn. */
    dqs_driver <= ~CLK_n;

  always @(posedge CLK_n)
    if (!RST)
      begin
	dq_driver_pre <= 0;
	will_write <= 0;
	do_write <= 0;
	dq_driver_holdlong <= 0;
      end
    else
      begin
	do_write <= will_write;
	dq_driver_pre <= DATA_W;
	dq_driver_holdlong <= dq_driver_pre[15:0];

	do_read <= {do_read[2:0],will_read};

	if (COMMAND_LATCHED)
	  will_write <= WE;
	else
	  will_write <= 0;

	dq_driver_h <= dq_driver_pre[31:16];
      end // else: !if(!RST)

  always @(posedge CLK_p)
    if (!RST)
      begin
	do_halfwrite <= 0;
	dq_driver_l <= 0;
      end
    else
      begin
	do_halfwrite <= do_write;
	dq_driver_l <= dq_driver_holdlong;
      end

  always @(posedge CLK_dp)
    DATA_R[15:0] <= DQ;

  always @(posedge CLK_dn)
    begin
      DATA_R[31:16] <= DQ;

      if (!RST)
	do_deltawrite <= 0;
      else
	do_deltawrite <= do_write;
    end

endmodule // outputs
