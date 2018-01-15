/* Reads a block from lsab_cr and writes it to DRAM. */
module hyper_mvblck_todram(input CLK,
			   input 	     RST,
			   /* begin LSAB */
			   input 	     LSAB_0_INT,
			   input 	     LSAB_1_INT,
			   input 	     LSAB_2_INT,
			   input 	     LSAB_3_INT,
			   input 	     LSAB_0_STOP,
			   input 	     LSAB_1_STOP,
			   input 	     LSAB_2_STOP,
			   input 	     LSAB_3_STOP,
			   input [24:0]      LSAB_0_ANCILL,
			   input [24:0]      LSAB_1_ANCILL,
			   input [24:0]      LSAB_2_ANCILL,
			   input [24:0]      LSAB_3_ANCILL,
			   // -----------------------
			   output 	     LSAB_READ,
			   output reg [1:0]  LSAB_SECTION,
			   //------------------------
			   /* begin DRAM */
			   input [8:0] 	     START_ADDRESS,
			   input [5:0] 	     COUNT_REQ,
			   input [1:0] 	     SECTION,
			   input [1:0] 	     DRAM_SEL,
			   input 	     ISSUE,
			   output reg [5:0]  COUNT_SENT,
			   output 	     WORKING,
			   output reg 	     IRQ_OUT,
			   output reg 	     ABRUPT_STOP,
			   output reg [24:0] ANCILL_OUT,
			   // -----------------------
			   output [8:0]      MCU_COLL_ADDRESS,
			   output reg [3:0]  MCU_WE_ARRAY,
			   output [1:0]      MCU_REQUEST_ACCESS);
  reg 					     WORKING = 1'b0,
					     LSAB_READ = 1'b0;
  reg [1:0] 				     MCU_REQUEST_ACCESS = 2'd0;
  reg [8:0] 				     MCU_COLL_ADDRESS = 9'd0;

  reg 					     stop_prev_n, stop_n,
					     am_working = 1'b0,
					     working_pre = 1'b0,
					     irq;
  reg [24:0] 				     ancill;
  reg [5:0] 				     len_left;
  reg [8:0] 				     track_addr;

  wire 					     trigger;

  assign trigger = track_addr[0];

  always @(LSAB_0_STOP or LSAB_1_STOP or
	   LSAB_2_STOP or LSAB_3_STOP or
	   LSAB_0_INT or LSAB_1_INT or
	   LSAB_2_INT or LSAB_3_INT or
	   LSAB_0_ANCILL or LSAB_1_ANCILL or
	   LSAB_2_ANCILL or LSAB_3_ANCILL or
	   LSAB_SECTION or LSAB_READ)
    case (LSAB_SECTION)
      2'b00: begin
	stop_n <= (LSAB_READ && !LSAB_0_STOP);
	irq <= LSAB_0_INT;
	ancill <= LSAB_0_ANCILL;
      end
      2'b01: begin
	stop_n <= (LSAB_READ && !LSAB_1_STOP);
	irq <= LSAB_1_INT;
	ancill <= LSAB_1_ANCILL;
      end
      2'b10: begin
	stop_n <= (LSAB_READ && !LSAB_2_STOP);
	irq <= LSAB_2_INT;
	ancill <= LSAB_2_ANCILL;
      end
      2'b11: begin
	stop_n <= (LSAB_READ && !LSAB_3_STOP);
	irq <= LSAB_3_INT;
	ancill <= LSAB_3_ANCILL;
      end
      default: begin
	stop_n <= 1'bx;
	irq <= 1'bx;
	ancill <= {(25){1'bx}};
      end
    endcase

  always @(posedge CLK)
    if (!RST)
      begin
	am_working <= 0; working_pre <= 0; WORKING <= 0; LSAB_READ <= 0;
	MCU_REQUEST_ACCESS <= 0; MCU_COLL_ADDRESS <= 0;
      end
    else
      begin
      if (! am_working)
	begin
	  LSAB_SECTION <= SECTION;
	  len_left <= COUNT_REQ;
	  track_addr <= START_ADDRESS;
	  stop_prev_n <= 0;
	  am_working <= ISSUE;
	  MCU_REQUEST_ACCESS <= 0;
	  if (ISSUE)
	    LSAB_READ <= 1;

	  /* FIXME: fails if the LSAB is empty at the start of exection */
	end
      else
	begin
	if (stop_n)
	  begin
	    len_left <= len_left -1;

	    LSAB_READ <= (len_left > 1);
	  end
	else
	  begin
	    LSAB_READ <= 0;
	    am_working <= 0;

	    COUNT_SENT <= COUNT_REQ - len_left;
	    IRQ_OUT <= irq;
	    ABRUPT_STOP <= LSAB_READ;
	    ANCILL_OUT <= ancill;
	  end
	track_addr <= track_addr +1;
	stop_prev_n <= stop_n;

	if (trigger)
	  begin
	    MCU_WE_ARRAY <= {stop_prev_n,stop_prev_n,stop_n,stop_n};
	    MCU_COLL_ADDRESS <= {track_addr[8:1],1'b0};
	    MCU_REQUEST_ACCESS <= DRAM_SEL;
	  end
	else
	  begin
	    MCU_REQUEST_ACCESS <= 0;
	  end

	end
	// Slow it down two cycles to prevent the driver circuit from
	// interferring with issuing commands to the MCU.
	working_pre <= am_working;
	WORKING <= working_pre;
      end // else: !if(!RST)

endmodule // hyper_mvblck_todram
