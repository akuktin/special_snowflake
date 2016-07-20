module hyper_scheduler_mem(input CLK,
			   input RST);
  reg [47:0] 			 mem[7:0];

  // Actually, this is supposed to be a rotating access device. Like those
  // old memory blocks for Steelhorse.

  assign read_dma_w = READ_DMA;
  assign read_cpu_w = (READ_CPU || READ_CPU_save) && ! READ_DMA;

  assign out = mem[read_addr];
  assign in = WRITE_DMA ? IN_DMA : IN_CPU;
  assign write_addr = WRITE_DMA ? ADDR_DMA : ADDR_CPU;
  assign we = WRITE_DMA || WRITE_CPU;

  always @(posedge CLK)
    if (!RST)
      begin
      end
    else
      begin
	if (read_dma_r)
	  OUT_DMA <= out;
	if (read_cpu_r)
	  begin
	    OUT_CPU <= out;
	    ACK_CPU <= 1;
	    READ_CPU_save <= 0;
	  end
	else
	  begin
	    ACK_CPU <= 0;
	    READ_CPU_save <= READ_CPU;
	  end

	read_dma_r <= read_dma_w;
	read_cpu_r <= read_cpu_w;

	if (read_dma_w)
	  read_addr <= R_ADDR_DMA;
	else
	  read_addr <= R_ADDR_CPU;

	if (we)
	  mem[write_addr] <= in;
      end

endmodule // hyper_scheduler_mem

module hyper_scheduler(input CLK,
		       input RST);
  reg [1:0] 		     trans_req, trans_ack,
			     refresh_req, refresh_ack;
  reg [3:0] 		     big_carousel;
  reg [7:0] 		     small_carousel;

  assign small_carousel_reset = small_carousel == 8'hbf;

  // Up to a maximum of 2 simultaneous 1 Gbps transactions.
  assign trg_gb_0 = small_carousel == 8'h00;
  assign trg_gb_1 = small_carousel == 8'h60;

  // Up to a maximum of 6 simultaneous 12.5 Mbps transactions.
  assign time_mb_0 = big_carousel == 4'h0;
  assign time_mb_1 = big_carousel == 4'h2;
  assign time_mb_2 = big_carousel == 4'h4;
  assign time_mb_3 = big_carousel == 4'h6;
  assign time_mb_4 = big_carousel == 4'h8;
  assign time_mb_5 = big_carousel == 4'ha;

  assign time_rfrs = (big_carousel == 4'h1) ||
		     (big_carousel == 4'h3) ||
		     (big_carousel == 4'h5) ||
		     (big_carousel == 4'h7) ||
		     (big_carousel == 4'h9) ||
		     (big_carousel == 4'hb) ||
		     (big_carousel == 4'hd) ||
		     (big_carousel == 4'hf);

  assign trg_mb_0 = do_gb_0 && done_gb_0 && time_mb_0;
  assign trg_mb_1 = do_gb_0 && done_gb_0 && time_mb_1;
  assign trg_mb_2 = do_gb_0 && done_gb_0 && time_mb_2;
  assign trg_mb_3 = do_gb_0 && done_gb_0 && time_mb_3;
  assign trg_mb_4 = do_gb_0 && done_gb_0 && time_mb_4;
  assign trg_mb_5 = do_gb_0 && done_gb_0 && time_mb_5;


  assign posedge_EXEC_READY = EXEC_READY && (!EXEC_READY_prev);
  assign counters_mismatch = trans_req != trans_ack;
  assign refresh_ctr_mismatch = refresh_req != refresh_ack;
  // 11 signals
  assign enter_stage_1 = EXEC_READY && counters_mismatch && (!GO) &&
			 (!posedge_EXEC_READY) && (!refresh_ctr_mismatch);
  // 9 signals
  assign exec_refresh = EXEC_READY && refresh_ctr_mismatch && (!GO) &&
			(!posedge_EXEC_READY);

  assign new_addr = (posedge_EXEC_READY && EXEC_ENDOF_PAGE) ?
		    EXEC_OLD_ADDR : mem_new_addr;

  always @(posedge CLK)
    if (!RST)
      begin
	small_carousel <= 8'hc1; // Out of bounds.
	big_carousel <= 4'h3;
	trans_req <= 0; trans_ack <= 0; refresh_req <= 0; refresh_ack <= 0;
	EXEC_READY_prev <= 1'b1;
      end
    else
      begin
	if (small_carousel_reset)
	  begin
	    small_carousel <= 0;
	    big_carousel <= big_carousel +1;
	  end
	else
	  small_carousel <= small_carousel +1;
	EXEC_READY_prev <= EXEC_READY;

	if (trg_gb_0)
	  begin
	    trans_req <= trans_req +1;

	    if (time_rfrs)
	      refresh_req <= refresh_req +1;
	  end
	if (trg_gb_1)
	  trans_req <= trans_req +1;

	if (posedge_EXEC_READY)
	  begin
	    if (EXEC_ENDOF_PAGE)
	      begin
		EXEC_NEW_ADDR <= new_addr;
	      end
	    else
	      begin
		trans_ack <= trans_ack +1;
		mem_trans[this_trans] <= EXEC_OLD_ADDRESS; // probably not
                                                           // good enough
		EXEC_BLOCK_LENGTH <= new_block_len;
		/* FIXME: also calculate remaining stuff for transfer. */
	      end
	  end // if (posedge_EXEC_READY)

	if (GO)
	  begin
	    RST_mvblck <= 1;
	    $configure_switch();
	  end
	else
	  if (posedge_EXEC_READY && (!EXEC_ENDOF_PAGE))
	    begin
	      RST_mvblck <= 0;
	      $unconfigure_switch();
	    end

	if (exec_refresh)
	  begin
	    MCU_REFRESH_STROBE <= ~MCU_REFRESH_STROBE;
	    refresh_ack <= refresh_ack +1;
	  end

	if (enter_stage_1)
	  begin
	    EXEC_NEW_ADDR <= new_addr;
	    EXEC_NEW_SECTION <= new_section;
	    EXEC_BLOCK_LENGTH <= 6'h3f; // WRONG! should be max of
                                        // `block_length and len_remaining.

	    trans_ack <= trans_ack +1; // if aborting the opportunity, this
                                       // is one of the places to do it
	  end

	if ((enter_stage_1) ||
	    (posedge_EXEC_READY && EXEC_ENDOF_PAGE))
	  GO <= 1;
	else
	  if (! EXEC_READY)
	    GO <= 0;
      end

endmodule // hyper_scheduler

module hyper_lsab_dram(input CLK,
		       input 		 RST,
		         /* begin COMMAND INTERFACE */
		       input 		 GO,
		       input [5:0] 	 BLOCK_LENGTH,
		       input [31:0] 	 NEW_ADDR,
		       input [1:0] 	 NEW_SECTION,
		       output reg [31:0] OLD_ADDR,
		       output 		 READY,
		       output reg 	 ENDOF_PAGE,
		       output reg [5:0]  COUNT_SENT,
			 /* begin BLOCK MOVER */
		       output reg [11:0] BLCK_START,
		       output reg [5:0]  BLCK_COUNT_REQ,
		       output 		 BLCK_ISSUE,
		       output reg [1:0]  BLCK_SECTION,
		       input [5:0] 	 BLCK_COUNT_SENT,
		       input 		 BLCK_WORKING,
			 /* begin MCU */
		       output reg [19:0] MCU_PAGE_ADDR,
		       output reg 	 MCU_REQUEST_ALIGN,
		       input 		 MCU_GRANT_ALIGN);
  reg 					   blck_working_prev;
  reg [1:0] 				   issue_op;
  reg [3:0] 				   state;

  wire 					   do_go;
  wire [5:0] 				   rest_of_the_way;
  wire [12:0] 				   end_addr;

  assign BLCK_ISSUE = issue_op[0] ^ issue_op[1];

  assign end_addr = BLCK_START + BLOCK_LENGTH;
  assign rest_of_the_way = (~BLCK_START[5:0]) + 1; // Supports arbitrary
                                                   // block lengths.

  assign do_go = GO && (state == 4'b1000);
  assign READY = state[3];

  always @(posedge CLK)
    if (!RST)
      begin
	OLD_ADDR <= 0; MCU_PAGE_ADDR <= 0; BLCK_START <= 0;
	MCU_REQUEST_ALIGN <= 0; blck_working_prev <= 0; issue_op <= 0;
	BLCK_COUNT_REQ <= 0; ENDOF_PAGE <= 0; COUNT_SENT <= 0;
	state <= 4'b1000;
      end
    else
      begin
	blck_working_prev <= BLCK_WORKING;

	if (do_go || state[0] || state[1] ||
	    (state[2] && blck_working_prev && !BLCK_WORKING))
	  state <= {state[2:0],do_go};

	if (state[0])
	  begin
	    MCU_REQUEST_ALIGN <= 1; // Change this for supporting multple
                                    // DRAMs.

	    MCU_PAGE_ADDR <= NEW_ADDR[31:12];
	    BLCK_START <= NEW_ADDR[11:0];

	    BLCK_SECTION <= NEW_SECTION;
	  end

	if (state[1])
	  begin
	    if (end_addr[12])
	      BLCK_COUNT_REQ <= rest_of_the_way;
	    else
	      BLCK_COUNT_REQ <= BLOCK_LENGTH;
	  end

	if (state[2] && blck_working_prev && !BLCK_WORKING)
	  begin
	    MCU_REQUEST_ALIGN <= 0; // maybe?

	    // Split calculating OLD_ADDR accoding to the following formula:
	    // 8 lower bits in the first cycle, 24 higher in the second.
	    OLD_ADDR <= {MCU_PAGE_ADDR,BLCK_START} + BLCK_COUNT_SENT;
	    ENDOF_PAGE <= end_addr[12] && (BLCK_COUNT_REQ ==
					   BLCK_COUNT_SENT);
	    COUNT_SENT <= BLCK_COUNT_SENT;
	  end

//	if (((MCU_REQUEST_ALIGN[0] && MCU_GRANT_ALIGN[0]) ||
//	     (MCU_REQUEST_ALIGN[1] && MCU_GRANT_ALIGN[1])) && // also FIXME
	if (MCU_REQUEST_ALIGN && MCU_GRANT_ALIGN && //FIXME propagation time
	    ~BLCK_ISSUE && ~BLCK_WORKING && ~blck_working_prev && //approx
	    (state[1] || state[2]))
	  issue_op[0] <= ~issue_op[0];
	issue_op[1] <= issue_op[0]; // Supposed to be out of the if block.
      end

endmodule // hyper_lsab_dram
