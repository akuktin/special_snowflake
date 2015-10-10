module states(input CLK,
	      input 	       RST,
	      input 	       CHANGE_REQUESTED,
	      input [2:0]      COMMAND,
	      output 	       CHANGE_POSSIBLE,
	      output reg [2:0] STATE,
	      output reg       CLOCK_COMMAND,
	      output reg       SOME_PAGE_ACTIVE);
  reg [3:0] 	     counter;
  reg 		     state_is_readwrite;

  assign CHANGE_POSSIBLE = ((counter == 4'hf) ||
			    (state_is_readwrite && (COMMAND == STATE))) ?
			   1 : 0;

  always @(posedge CLK)
    if (!RST)
      begin
	SOME_PAGE_ACTIVE <= 0;
	counter <= 4'hf;
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
		begin
		  counter <= 4'hd;
		  SOME_PAGE_ACTIVE <= 1;
		end
	      else if (COMMAND == `ARSR)
		counter <= 4'h0;
	      else
		counter <= 4'hc;

	      if (COMMAND == `PRCH)
		begin
		  CLOCK_COMMAND <= 1'b1;
		  SOME_PAGE_ACTIVE <= 0;
		end
	      else
		CLOCK_COMMAND <= 1'b0;
	    end
	end // if (CHANGE_POSSIBLE)
      else
	begin
	  CLOCK_COMMAND <= 1'b0;

	  if ((CHANGE_REQUESTED & state_is_readwrite) && (COMMAND == STATE))
	    counter <= 4'hc;
	  else
	    counter <= counter +1;
	end

endmodule // states

/* Push address, data (if any) and we onto wires and assert DO_ACT.
 * When COMMAND_LATCHED is sensed as asserted, either deassert DO_ACT
 * or push the next batch of address, data (if any) and we.
 * Writing is fire-and-forget. When COMMAND_LATCHED is sensed asserted,
 * you as the memory client are done. If reading, when you sense
 * COMMAND_LATCHED, set a counter to 0. Afterwards, increment the counter
 * by one every cycle. When the counter is sensed to equal 4, the
 * DATA_READ output is valid. */
module enter_state(input CLK,
		   input 	     RST,
		   input 	     REFRESH_STROBE,
		   input [27:0]      ADDRESS_REQ,
		   input 	     WE,
		   input 	     DO_ACT,
		   input 	     CHANGE_POSSIBLE,
		   input 	     CLOCK_COMMAND,
		   input 	     SOME_PAGE_ACTIVE,
		   output reg [12:0] ADDRESS_REG,
		   output reg [1:0]  BANK_REG,
		   output reg [2:0]  COMMAND_REG,
		   output [2:0]      COMMAND,
		   output 	     CHANGE_REQUESTED,
		   output 	     DO_WRITE,
		   output 	     COMMAND_LATCHED);
  reg [27:0] 			    address;
  reg [14:0] 			    page_current;
  reg [8:0] 			    command_sequence;
  reg [1:0] 			    command_len;
  reg [2:0] 			    we_sequence;
  reg [2:0] 			    isrow_sequence;
  reg 				    refresh_strobe_ack;

  wire [2:0] 			    rw_command;
  wire 				    refresh_time;

  wire [12:0] 			    row_request;
  wire [1:0] 			    bank_request;
  wire [12:0] 			    collumn_request;

  assign CHANGE_REQUESTED = (command_len == 2'h3) ? 0 : 1;
  assign rw_command = WE ? `WRTE : `READ;
  assign DO_WRITE = we_sequence[2];
  assign COMMAND = command_sequence[8:6];
  assign refresh_time = refresh_strobe_ack ^ REFRESH_STROBE;
  assign COMMAND_LATCHED = (((COMMAND == `WRTE) || (COMMAND == `READ))
			    && CHANGE_REQUESTED && CHANGE_POSSIBLE);

  assign row_request_live = ADDRESS_REQ[27:15];
  assign bank_request_live = ADDRESS_REQ[14:13];
  assign row_request = address[27:15];
  assign bank_request = address[14:13];
  assign collumn_request = address[12:0]

  always @(posedge CLK)
    if (!RST)
      begin
	refresh_strobe_ack <= REFRESH_STROBE;
	page_current <= 0;
	command_sequence <= {`NOOP,`NOOP,`NOOP};
	we_sequence <= 3'b000;
	isrow_sequence <= 3'b010;
	command_len <= 2'h3;
	COMMAND_REG <= `NOOP;
      end
    else
      begin
	if (CHANGE_REQUESTED) /* note: this UNables back-to-back reads/writes */
	  begin
	    if (CHANGE_POSSIBLE)
	      begin
		command_len <= command_len +1;
		command_sequence <= {command_sequence[5:0],`NOOP};
		we_sequence <= {we_sequence[1:0],1'b0};
		isrow_sequence <= {isrow_sequence[1:0],1'b0};

		if (COMMAND == `PRCH)
		  COMMAND_REG <= `NOOP;
		else
		  COMMAND_REG <= COMMAND;

		if (isrow_sequence[2])
		  begin
		    page_current <= {row_request,bank_request};
		    ADDRESS_REG <= row_request;
		    BANK_REG <= bank_request;
		  end
		else
		  ADDRESS_REG <= collumn_request;
	      end
	    else
	      if (CLOCK_COMMAND)
		begin
		  COMMAND_REG <= `PRCH;
		  ADDRESS_REG <= {15'h0200};
		end
	      else
		COMMAND_REG <= `NOOP;
	  end // if (CHANGE_REQUESTED)
	else
	  begin
	    if (refresh_time)
	      begin
		refresh_strobe_ack <= REFRESH_STROBE;
		command_len <= 2'h1;
		command_sequence <= {`PRCH,`ASRS,`NOOP};
		we_sequence <= 3'b000;
		/* isrow_sequence doesn't matter */
	      end
	    else
	      if (DO_ACT)
		begin
		  isrow_sequence <= 3'b010;
		  address <= ADDRESS_REQ;
		  if ({SOME_PAGE_ACTIVE,row_request_live,bank_request_live} ==
		      {1'b1,page_current})
		    begin
		      command_len <= 2'h2;
		      command_sequence <= {rw_command,`NOOP,rw_command};
		      we_sequence <= {WE,1'b0,WE};
		    end
		  else
		    begin
		      command_len <= 2'h0;
		      command_sequence <= {`PRCH,`ACTV,rw_command};
		      we_sequence <= {1'b0,1'b0,WE};
		    end
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
	       inout [15:0] 	 DQ,
	       inout 		 DQS,
	       output reg [31:0] DATA_R,
	       output 		 DM);
  reg [15:0] 			 dq_driver;
  reg [31:0] 			 dq_driver_pre, dq_driver_holdlong;
  reg 				 dqs_driver;
  reg 				 will_write, do_write, do_deltawrite, do_halfwrite;
  reg 				 will_read, really_will_read, about_to_read,
				 do_read, reading;

  assign DM = ~do_deltawrite;
  assign DQ = do_deltawrite ? dq_driver : {{16}1'bz};
  assign DQS = (do_write | do_halfwrite) ? dqs_driver : 1'bz;

  always @(CLK_n)
    dqs_driver <= CLK_n;

  always @(posedge CLK_n)
    if (!RST)
      begin
	dq_driver_pre <= 0;
	will_read <= 0;
	will_write <= 0;
	do_read <= 0;
	about_to_read <= 0;
	really_will_read <= 0;
	do_write <= 0;
	dq_driver_holdlong <= 0;
      end
    else
      begin
	will_write <= 0;
	do_write <= will_write;
	dq_driver_holdlong <= dq_driver_pre;

	will_read <= 0;
	really_will_read <= will_read;
	about_to_read <= really_will_read;
	do_read <= about_to_read;

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

  always @(posedge CLK_p)
    if (!RST)
      begin
	do_halfwrite <= 0;
	reading <= 0;
      end
    else
      begin
	do_halfwrite <= do_write;
	reading <= do_read;
      end

  always @(CLK_d)
    if (!RST)
      begin
	do_deltawrite <= 0;
	dq_driver <= 0;
	DATA_R <= 0;
      end
    else
      begin
	do_deltawrite <= do_write;

	if (dqs_driver)
	  begin
	    dq_driver <= dq_driver_holdlong[15:0];
	    DATA_R[31:16] <= DQ;
	  end
	else
	  begin
	    dq_driver <= dq_driver_holdlong[31:16];
	    DATA_R[15:0] <= DQ;
	  end
      end

endmodule // outputs
