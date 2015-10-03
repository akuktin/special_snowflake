module states(input CLK,
	      input 	       RST,
	      input 	       CHANGE_REQUESTED,
	      input [2:0]      COMMAND,
	      output 	       CHANGE_POSSIBLE,
	      output reg [2:0] STATE,
	      output 	       READ_ALLOWED,
	      output 	       WRITE_ALLOWED,
	      output reg       CLOCK_COMMAND);
  reg [1:0] 	     counter;
  reg 		     state_is_readwrite;

  assign CHANGE_POSSIBLE = (counter == 2'h3) ? 1 : 0;

  assign READ_ALLOWED = CHANGE_POSSIBLE | (STATE == `READ);
  assign WRITE_ALLOWED = CHANGE_POSSIBLE | (STATE == `WRTE);

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
