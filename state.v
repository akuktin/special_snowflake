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
		   output 	    CHANGE_REQUESTED);
  reg [11:0] 			    page_current;
  reg [2:0] 			    command_sequence[2:0];
  reg [1:0] 			    command_len;

  wire [2:0] 			    rw_command;

  assign CHANGE_REQUESTED = (command_len == 2'h3) ? 0 : 1;
  assign rw_command = WE ? `WRTE : `READ;

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
