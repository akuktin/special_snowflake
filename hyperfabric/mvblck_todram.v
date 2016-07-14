/* Reads a block from lsab_cr and writes it to DRAM. */
module hyper_mvblck_todram(input CLK,
			   input 	     RST,
			   /* begin LSAB */
			   input 	     LSAB_0_EMPTY,
			   input 	     LSAB_1_EMPTY,
			   input 	     LSAB_2_EMPTY,
			   input 	     LSAB_3_EMPTY,
			   // -----------------------
			   output reg 	     LSAB_READ,
			   output reg [1:0]  LSAB_SECTION
			   //------------------------
			   /* begin DRAM */
			   input [11:0]      START_ADDRESS,
			   input [4:0] 	     COUNT_REQ,
			   input [1:0] 	     SECTION,
			   input 	     ISSUE,
			   output reg [4:0]  COUNT_SENT,
			   output reg 	     WORKING,
			   // -----------------------
			   output reg [11:0] MCU_COLL_ADDRESS,
			   output reg [3:0]  MCU_WE_ARRAY,
			   output reg 	     MCU_REQUEST_ACCESS);
  reg 					     empty_prev_n, empty_n,
					     pre_request_access,
					     am_working;
  reg [4:0] 				     len_left;
  reg [11:0] 				     track_addr;

  wire 					     trriger, read_more;

  assign trigger = track_addr[0];
  assign read_more = len_left != 0;

  always @(LSAB_0_EMPTY or LSAB_1_EMPTY or
	   LSAB_2_EMPTY or LSAB_3_EMPTY or LSAB_SECTION)
    case (LSAB_SECTION)
      2'b00: empty_n <= ~LSAB_0_EMPTY;
      2'b01: empty_n <= ~LSAB_1_EMPTY;
      2'b10: empty_n <= ~LSAB_2_EMPTY;
      2'b11: empty_n <= ~LSAB_3_EMPTY;
      default: empty_n <= 1'bx;
    endcase

  always @(posedge CLK)
    if (!RST)
      begin
	am_working <= 0;
	LSAB_READ <= 0; LSAB_SECTION <= 0; COUNT_LEFT <= 0; WORKING <= 0;
	MCU_COLL_ADDRESS <= 0; MCU_WE_ARRAY <= 0; MCU_REQUEST_ACCESS <= 0;
	emputy_prev_n <= 0; pre_request_access <= 0; len_left <= 0;
	track_addr <= 0;
      end
    else
      begin
      if (! am_working)
	begin
	  LSAB_SECTION <= SECTION;
	  len_left <= COUNT_REQ;
	  track_addr <= START_ADDRESS;
	  empty_prev_n <= 0; pre_request_access <= 0;
	  am_working <= ISSUE;

	  /* FIXME: fails if the LSAB is empty at the start of exection */
	end
      else
	begin
	if (empty_n && read_more)
	  begin
	    track_addr <= track_addr +1;
	    len_left <= len_left -1;

	    LSAB_READ <= 1;
	  end
	else
	  begin
	    LSAB_READ <= 0;
	    am_working <= 0;

	    COUNT_SENT <= COUNT_REQ - len_left;
	  end
	empty_prev_n <= empty_n;

	if (trigger)
	  begin
	    MCU_WE_ARRAY <= {empty_prev_n,empty_prev_n,empty_n,empty_n};
	    MCU_COLL_ADDRESS <= {track_addr[11:1],1'b0};
	    pre_request_access <= 1;
	  end
	else
	  begin
	    pre_request_access <= 0;
	  end

	end

	// Slow it down one cycle to allow the data to clear the switch.
	MCU_REQUEST_ACCESS <= pre_request_access;
	// Slow it down one cycle to prevent the driver circuit from
	// interferring with issuing commands to the MCU.
	WORKING <= am_working;
      end // else: !if(!RST)

endmodule // hyper_mvblck_todram

module hyper_lsab_todram(input CLK,
			 input 		   RST,
			 /* begin BLOCK MOVER */
			 output reg [11:0] BLCK_START,
			 output reg [4:0]  BLCK_COUNT_REQ,
			 output 	   BLCK_ISSUE,
			 output reg [1:0]  BLCK_SECTION,
			 input [4:0] 	   BLCK_COUNT_SENT,
			 input 		   BLCK_WORKING,
			 /* begin MCU */
			 output reg [19:0] MCU_PAGE_ADDR,
			 output reg 	   MCU_REQUEST_ALIGN,
			 input 		   MCU_GRANT_ALIGN);

  // Need to do/handle: state[3], go, new_addr, new_section, old_addr.

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

	    old_addr <= {MCU_PAGE_ADDR,BLCK_START} + BLCK_COUNT_SENT;
	  end

	if (MCU_REQUEST_ALIGN && MCU_GRANT_ALIGN && //FIXME propagation time
	    ~BLCK_ISSUE && ~BLCK_WORKING && ~blck_working_prev && //approx
	    (state[1] || state[2]))
	  issue_op[0] <= ~issue_op[0];
	issue_op[1] <= issue_op[0]; // Supposed to be out of the if block.
      end

endmodule // hyper_lsab_todram
