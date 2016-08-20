/* Reads a block from DRAM and writes it to lsab_cw. */
module hyper_mvblck_frdram(input CLK,
			   input 	     RST,
			   /* begin LSAB */
			   input 	     LSAB_0_FULL,
			   input 	     LSAB_1_FULL,
			   input 	     LSAB_2_FULL,
			   input 	     LSAB_3_FULL,
			   // -----------------------
			   output reg 	     LSAB_WRITE,
			   output reg [1:0]  LSAB_SECTION,
			   // -----------------------
			   /* begin DRAM */
			   input [11:0]      START_ADDRESS,
			   input [5:0] 	     COUNT_REQ,
			   input [1:0] 	     SECTION,
			   input [1:0] 	     DRAM_SEL,
			   input 	     ISSUE,
			   output reg [5:0]  COUNT_SENT,
			   output reg 	     WORKING,
			   output reg 	     ABRUPT_STOP,
			   // -----------------------
			   output reg [11:0] MCU_COLL_ADDRESS,
			   output [1:0]      MCU_REQUEST_ACCESS);
  reg 					     am_working, abrupt_stop_n;
  reg [2:0] 				     we_counter, release_counter;
  reg [5:0] 				     len_left;

  wire 					     release_trigger, we_trigger,
					     read_more, uneven_len;
  wire [5:0] 				     compute_len, assign_len;

  /* This signal used to be a normal, proper register whose logic was
   * easy to follow. But then I started using multiple movers against a
   * single MCU and thus needed to OR all their requests for access. To
   * maintian the speed requirements, I now need to assert and deassert
   * request signals one cycle earlier then I normally would.
   * For the easy-to-read variant, look back in the git repository. */
  assign MCU_REQUEST_ACCESS = am_working ?
			      (DRAM_SEL & {read_more,read_more}) :
			      (DRAM_SEL & {(ISSUE && RST),(ISSUE && RST)});

  assign release_trigger = release_counter == 3'h7;
  assign we_trigger = we_counter == 3'h7;

  /* Formula tested on paper.
   * May not fit in 3 LUT4s, depending on just
   * how (non)aggresive the optimizer is. */
  assign uneven_len = COUNT_REQ[0] ^ START_ADDRESS[0];
  assign compute_len = COUNT_REQ + {5'h0,uneven_len} + 1;
  assign assign_len = {compute_len[5:1],1'b0};

  assign read_more = len_left != 6'h1;

  always @(LSAB_0_FULL or LSAB_1_FULL or
	   LSAB_2_FULL or LSAB_3_FULL or LSAB_SECTION)
    case (LSAB_SECTION)
      2'b00: abrupt_stop_n <= ~LSAB_0_FULL;
      2'b01: abrupt_stop_n <= ~LSAB_1_FULL;
      2'b10: abrupt_stop_n <= ~LSAB_2_FULL;
      2'b11: abrupt_stop_n <= ~LSAB_3_FULL;
      default: abrupt_stop_n <= 1'bx;
    endcase

  always @(posedge CLK)
    if (!RST)
      begin
	LSAB_WRITE <= 0; we_counter <= 0; release_counter <= 0;
	WORKING <= 0; am_working <= 0; len_left <= 6'h1;
	MCU_COLL_ADDRESS <= 0; LSAB_SECTION <= 0; COUNT_SENT <= 0;
	ABRUPT_STOP <= 0;
      end
    else
      begin
	if (! am_working)
	  begin
	    if (ISSUE)
	      begin
		am_working <= 1;
		len_left <= assign_len;

		MCU_COLL_ADDRESS <= {START_ADDRESS[11:1],1'b0};
		LSAB_SECTION <= SECTION;

		if (START_ADDRESS[0])
		  we_counter <= 3'h1;
		else
		  we_counter <= 3'h2;
	      end // if (ISSUE)
	  end
	else
	  begin
	    if (read_more && abrupt_stop_n)
	      begin
		MCU_COLL_ADDRESS <= MCU_COLL_ADDRESS +1;
		len_left <= len_left -1;
	      end
	    else
	      begin
		ABRUPT_STOP <= !abrupt_stop_n;
		am_working <= 0;
		if (! read_more)
		  begin
		    if (uneven_len)
		      release_counter <= 3'h3; // CAUTION! Leaves a bit
		                               //          of pollution.
		    else
		      release_counter <= 3'h2;
		  end
		else
		  begin
		    /* Also requires LSAB to assert
		     * the `I'm full' signal with AT LEAST 8 words
		     * left to go. */
		    /* This (woobly release counters) works because the
		     * fact we are in this branch proves the block mover
		     * was having the intention of moving AT LEAST 1 word
		     * before the full signal was asserted. To control for
		     * the option of a very bad edge case, we keep the
		     * MCU_REQUEST_ACCESS asserted for one more cycle. We
		     * the behave (regarding release_counter) the same as
		     * we would if we were going to read an additional
		     * word. */
		    if (uneven_len)
		      release_counter <= 3'h2; // Also pollutes a bit.
		    else
		      release_counter <= 3'h1;
		  end
	      end // else: !if(read_more)
	  end // else: !if(! am_working)

	if (release_trigger)
	  begin
	    WORKING <= 0;
	    LSAB_WRITE <= 0;
	  end
	else
	  begin
	    if (am_working)
	      WORKING <= 1;
	    if (we_trigger)
	      LSAB_WRITE <= 1;
	  end

	if (we_trigger)
	  COUNT_SENT <= 0;
	else
	  if (LSAB_WRITE)
	    COUNT_SENT <= COUNT_SENT +1;

	/* The below two are VERY IMPORTANT! The counter MUST pass through
	 * the trigger condition! Otherwise, the circuit will be stuck,
	 * continously triggering either release or write enable. */
	if (release_counter != 0)
	  release_counter <= release_counter +1;

	if (we_counter != 0)
	  we_counter <= we_counter +1;
      end

endmodule // hyper_mvblck_frdram
