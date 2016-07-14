`define block_length 5'h18

module hyper_lsab_dram(input CLK,
		       input 		 RST,
			 /* begin BLOCK MOVER */
		       output reg [11:0] BLCK_START,
		       output reg [4:0]  BLCK_COUNT_REQ,
		       output 		 BLCK_ISSUE,
		       output reg [1:0]  BLCK_SECTION,
		       input [4:0] 	 BLCK_COUNT_SENT,
		       input 		 BLCK_WORKING,
			 /* begin MCU */
		       output reg [19:0] MCU_PAGE_ADDR,
		       output reg 	 MCU_REQUEST_ALIGN,
		       input 		 MCU_GRANT_ALIGN);

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

  assign end_addr = BLCK_START + `block_length;
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
	      BLCK_COUNT_REQ <= `block_length;
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

endmodule // hyper_lsab_dram
