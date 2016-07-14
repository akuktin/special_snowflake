/* Reads a block from DRAM and writes it to lsab_cw. */
module hyper_mvblck_frdram(input CLK,
			   input 	     RST,
			   /* begin LSAB */
			   output reg 	     LSAB_WRITE,
			   output reg [1:0]  LSAB_SECTION,
			   /* begin DRAM */
			   input [11:0]      START_ADDRESS,
			   input [4:0] 	     COUNT_REQ,
			   input [1:0] 	     SECTION,
			   input 	     ISSUE,
			   output reg 	     WORKING,
			   // -----------------------
			   output reg [11:0] MCU_COLL_ADDRESS,
			   output reg 	     MCU_REQUEST_ACCESS);
  reg 					     am_working;
  reg [3:0] 				     we_counter, release_counter;
  reg [4:0] 				     len_left;

  wire 					     release_trigger, we_trigger,
					     read_more, uneven_len;
  wire [4:0] 				     compute_len, assign_len;

  assign release_trigger = release_counter == 3'h7;
  assign we_trigger = we_counter == 3'h7;

  /* Formula tested on paper.
   * May not fit in 3 LUT4s, depending on just
   * how (non)aggresive the optimizer is. */
  assign uneven_len = COUNT_REQ[0] ^ START_ADDRESS[0];
  assign compute_len = COUNT_REQ + {4'h0,uneven_len} + 1;
  assign assign_len = {compute_len[4:1],1'b0};

  assign read_more = len_left != 5'h1;

  always @(posedge CLK)
    if (!RST)
      begin
	LSAB_WRITE <= 0; we_counter <= 0; release_counter <= 0;
	WORKING <= 0; am_working <= 0; MCU_REQUEST_ACCESS <= 0;
	len_left <= 5'h1; MCU_COLL_ADDRESS <= 0; LSAB_SECTION <= 0;
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

		MCU_REQUEST_ACCESS <= 1;
	      end // if (ISSUE)
	    // else: rest position
	  end
	else
	  begin
	    if (read_more)
	      begin
		MCU_COLL_ADDRESS <= MCU_COLL_ADDRESS +1;
		len_left <= len_left -1;
	      end
	    else
	      begin
		am_working <= 0;
		if (uneven_len)
		  release_counter <= 3'h3; // CAUTION! Leaves a bit
		                           //          of pollution.
		else
		  release_counter <= 3'h2;

		MCU_REQUEST_ACCESS <= 0;
	      end // else: !if(read_more)
	  end // else: !if(! am_working)

	if (release_trigger)
	  begin
	    WORKING <= 0;
	    LSAB_WRITE <= 0;
	  end
	else
	  if (am_working)
	    WORKING <= 1;

	if (we_trigger)
	  LSAB_WRITE <= 1;

	/* The below two are VERY IMPORTANT! The counter MUST pass through
	 * the trigger condition! Otherwise, the circuit will be stuck,
	 * continously triggering either release or write enable. */
	if (release_counter != 0)
	  release_counter <= release_counter +1;

	if (we_counter != 0)
	  we_counter <= we_counter +1;
      end

endmodule // hyper_mvblck_frdram

module hyper_lsab_frdram(input CLK,
			 input 		   RST,
			 /* begin BLOCK MOVER */
			 output reg [11:0] BLCK_START,
			 output reg [4:0]  BLCK_COUNT_REQ,
			 output 	   BLCK_ISSUE,
			 output reg [1:0]  BLCK_SECTION,
			 input 		   BLCK_WORKING,
			 /* begin MCU */
			 output reg [19:0] MCU_PAGE_ADDR,
			 output reg 	   MCU_REQUEST_ALIGN,
			 input 		   MCU_GRANT_ALIGN);

  // Need to do/handle: state[3], go, new_addr, new_section, old_addr,
  //                    transfer length

  reg 					   blck_working_prev;
  reg [1:0] 				   issue_op, new_section;
  reg [3:0] 				   state;
  reg [31:0] 				   old_addr, new_addr;

  wire 					   go;
  wire [4:0] 				   rest_of_the_way;
  wire [12:0] 				   end_addr;

  assign BLCK_ISSUE = issue_op[0] ^ issue_op[1];

  assign end_addr = BLCK_START + 5'h18;
  assign rest_of_the_way = (~BLCK_START[4:0]) + 1; // Supports arbitrary
  //  block lengths.

  always @(posedge CLK)
    if (!RST)
      begin
	old_addr <= 0; new_addr <= 0; MCU_PAGE_ADDR <= 0; BLCK_START <= 0;
	MCU_REQUEST_ALIGN <= 0; blck_working_prev <= 0; issue_op <= 0;
	BLCK_COUNT_REQ <= 0; new_section <= 0;
	state <= 4'b1000;
      end
    else
      begin
	blck_working_prev <= BLCK_WORKING;

	if (go || state[0] || state[1] ||
	    (state[2] && blck_working_prev && !BLCK_WORKING))
	  state <= {state[2:0],go};

	if (state[0])
	  begin
	    MCU_REQUEST_ALIGN <= 1;

	    MCU_PAGE_ADDR <= new_addr[31:12];
	    BLCK_START <= new_addr[11:0];

	    BLCK_SECTION <= new_section;
	  end

	if (state[1])
	  begin
	    if (end_addr[12])
	      BLCK_COUNT_REQ <= rest_of_the_way;
	    else
	      BLCK_COUNT_REQ <= 5'h18;
	  end

	if (state[2] && blck_working_prev && !BLCK_WORKING)
	  begin
	    MCU_REQUEST_ALIGN <= 0; // maybe?

	    old_addr <= {MCU_PAGE_ADDR,BLCK_START} + BLCK_COUNT_REQ;
	  end

	if (MCU_REQUEST_ALIGN && MCU_GRANT_ALIGN && //FIXME propagation time
	    ~BLCK_ISSUE && ~BLCK_WORKING && ~blck_working_prev && //approx
	    (state[1] || state[2]))
	  issue_op[0] <= ~issue_op[0];
	issue_op[1] <= issue_op[0]; // Supposed to be out of the if block.
      end

endmodule // hyper_lsab_frdram
