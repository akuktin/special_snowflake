module states(input CLK,
	      input 	       RST,
	      input 	       CHANGE_REQUESTED,
	      input [2:0]      COMMAND,
	      output 	       CHANGE_POSSIBLE,
	      output reg [2:0] STATE,
	      output reg       CLOCK_COMMAND);
  reg [1:0] 	     counter;
  reg 		     state_is_readwrite;

  assign CHANGE_POSSIBLE = ((counter == 2'h3) ||
			    (state_is_readwrite && (COMMAND == STATE))) ?
			   1 : 0;

  always @(posedge CLK)
    if (!RST)
      begin
	counter <= 2'h3;
	state_is_readwrite <= 0;
	CLOCK_COMMAND <= 1'b0;
	STATE <= `PRCH;
      end
    else
      if (CHANGE_POSSIBLE)
	begin
	  if (CHANGE_REQUESTED)
	    begin
	      STATE <= COMMAND;
	      state_is_readwrite <= ((COMMAND == `READ) || (COMMAND == `WRTE));

	      if (COMMAND == `ACTV)
		counter <= 2'h1;
	      else
		counter <= 2'h0;

	      if (COMMAND == `PRCH)
		CLOCK_COMMAND <= 1'b1;
	      else
		CLOCK_COMMAND <= 1'b0;
	    end
	end // if (CHANGE_POSSIBLE)
      else
	begin
	  CLOCK_COMMAND <= 1'b0;

	  if ((CHANGE_REQUESTED & state_is_readwrite) && (COMMAND == STATE))
	    counter <= 2'h0;
	  else
	    counter <= counter +1;
	end

endmodule // states

module enter_state(input CLK,
		   input 	    RST,
		   input [11:0]     PAGE_REQUEST,
		   input 	    WE,
		   input 	    DO_ACT,
		   input 	    CHANGE_POSSIBLE,
		   input 	    CLOCK_COMMAND,
		   output reg [2:0] COMMAND,
		   output 	    CHANGE_REQUESTED,
		   output 	    DO_WRITE);
  reg [11:0] 			    page_current;
  reg [2:0] 			    command_sequence[2:0];
  reg [1:0] 			    command_len;
  reg 				    we_sequence[2:0];

  wire [2:0] 			    rw_command;

  assign CHANGE_REQUESTED = (command_len == 2'h3) ? 0 : 1;
  assign rw_command = WE ? `WRTE : `READ;
  assign DO_WRITE = we_sequence[command_len];

  always @(posedge CLK)
    if (!RST)
      begin
	page_current <= 0; /* TODO: will have to be hacked */
	command_sequence <= {`NOP/*actually PRCH*/,`ACTV,`READ};
	command_len <= 2'h3;
	COMMAND <= `NOP;
      end
    else
      begin
	if (CHANGE_REQUESTED)
	  begin
	    if (CHANGE_POSSIBLE)
	      begin
		command_len <= command_len +1;
		COMMAND <= command_sequence[command_len];
		page_current <= PAGE_REQUEST;
		/* TODO: setup data receivers/senders here */
	      end
	    else
	      if (CLOCK_COMMAND)
		COMMAND <= `PRCH;
	      else
		COMMAND <= `NOP;
	  end // if (CHANGE_REQUESTED)
	else
	  begin
	    command_sequence <= {`NOP/*actually PRCH*/,`ACTV,rw_command};
	    we_sequence <= {1'b0,1'b0,WE};

	    if (DO_ACT)
	      begin
		if (PAGE_REQUEST == page_current)
		  command_len <= 2'h2;
		else
		  command_len <= 2'h0;
	      end
	  end // else: !if(CHANGE_REQUESTED)
      end

endmodule // enter_state

module outputs(input CLK_p,
	       input 		 CLK_n,
	       input 		 CLK_d,
	       input 		 RST,
	       input 		 CHANGE_REQUESTED,
	       input 		 CHANGE_POSSIBLE,
	       input [31:0] 	 DATA_W,
	       input 		 WE,
	       inout [31:0] 	 DQ,
	       inout 		 DQS,
	       output reg [31:0] DATA_R,
	       output reg 	 DATA_VALID);
  reg [31:0] 			 dq_driver, dq_driver_pre;
  reg 				 dqs_driver, pipe_clk_dqs;
  reg 				 do_write, will_write;
  reg 				 will_read, really_will_read, do_read;

  /* Missing: the actual dual-pump action. */

  assign DQ = do_write ? dq_driver : {{32}1'bz};
  assign DQS = (pipe_clk_dqs) ? dqs_driver : 1'bz;

  always @(CLK_p)
    dqs_driver <= CLK_p;

  always @(posedge CLK_n)
    if (!RST)
      begin
	pipe_clk_dqs <= 0;
      end
    else
      begin
	if (do_write | will_write)
	  pipe_clk_dqs <= 1;
	else
	  pipe_clk_dqs <= 0;
      end

  always @(posedge CLK_p)
    if (!RST)
      begin
      end
    else
      begin
	will_write <= 0;
	do_write <= will_write;
	dq_driver <= dq_driver_pre;

	will_read <= 0;
	really_will_read <= will_read;
	DATA_VALID <= really_will_read;

	if (CHANGE_REQUESTED & CHANGE_POSSIBLE)
	  begin
	    if (WE)
	      begin
		will_write <= 1;
	      end
	    else
	      will_read <= 1;

	    dq_driver_pre <= DATA_W;
	  end // if (CHANGE_REQUESTED & CHANGE_POSSIBLE)
      end // else: !if(!RST)

  always @(posedge CLK_d)
    DATA_R <= DQ;

endmodule // outputs
