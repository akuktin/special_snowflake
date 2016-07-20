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
			   input [5:0] 	     COUNT_REQ,
			   input [1:0] 	     SECTION,
			   input 	     ISSUE,
			   output reg [5:0]  COUNT_SENT,
			   output reg 	     WORKING,
			   // -----------------------
			   output reg [11:0] MCU_COLL_ADDRESS,
			   output reg [3:0]  MCU_WE_ARRAY,
			   output reg 	     MCU_REQUEST_ACCESS);
  reg 					     empty_prev_n, empty_n,
					     am_working;
  reg [5:0] 				     len_left;
  reg [11:0] 				     track_addr;

  wire 					     trigger, read_more;

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
	emputy_prev_n <= 0; len_left <= 0;
	track_addr <= 0;
      end
    else
      begin
      if (! am_working)
	begin
	  LSAB_SECTION <= SECTION;
	  len_left <= COUNT_REQ;
	  track_addr <= START_ADDRESS;
	  empty_prev_n <= 0;
	  am_working <= ISSUE;
	  MCU_REQUEST_ACCESS <= 0;

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
	    MCU_REQUEST_ACCESS <= 1;
	  end
	else
	  begin
	    MCU_REQUEST_ACCESS <= 0;
	  end

	end
	// Slow it down one cycle to prevent the driver circuit from
	// interferring with issuing commands to the MCU.
	WORKING <= am_working;
      end // else: !if(!RST)

endmodule // hyper_mvblck_todram
