module hyper_scheduler_mem(input CLK,
			   input 	     RST,
			   // ---------------------
			   input 	     READ_CPU,
			   input 	     WRITE_CPU,
			   output 	     READ_CPU_ACK,
			   output reg 	     WRITE_CPU_ACK
			   input [2:0] 	     ADDR_CPU,
			   input [31:0]      IN_CPU,
			   output reg [31:0] OUT_CPU,
			   // ---------------------
			   input 	     READ_DMA,
			   input 	     WRITE_DMA,
			   input [2:0] 	     R_ADDR_DMA,
			   input [2:0] 	     W_ADDR_DMA,
			   input [31:0]      IN_DMA,
			   output reg [31:0] OUT_DMA);
  reg [31:0] 				     mem[7:0]; // not wide enough
  reg 					     read_cpu_r, read_dma_r;
  reg [2:0] 				     read_addr;

  wire 					     read_cpu_w, read_dma_w, we;
  wire [2:0] 				     write_addr;
  wire [31:0] 				     out, in;

  assign READ_CPU_ACK = read_cpu_r;

  assign out = mem[read_addr];
  assign read_dma_w = READ_DMA;
  assign read_cpu_w = READ_CPU && !(READ_DMA || READ_CPU_ACK);

  assign in = WRITE_DMA ? IN_DMA : IN_CPU;
  assign write_addr = WRITE_DMA ? W_ADDR_DMA : ADDR_CPU;
  assign we = WRITE_DMA ? 1 : (WRITE_CPU && !WRITE_CPU_ACK);

  initial
    begin
      mem[0] <= 0; mem[1] <= 0; mem[2] <= 0; mem[3] <= 0;
      mem[4] <= 0; mem[5] <= 0; mem[6] <= 0; mem[7] <= 0;
    end

  always @(posedge CLK)
    if (!RST)
      begin
	OUT_DMA <= 0; OUT_CPU <= 0; WRITE_CPU_ACK <= 0;
	read_cpu_r <= 0; read_dma_r <= 0; read_addr <= 0;
      end
    else
      begin
	if (read_dma_r)
	  OUT_DMA <= out;
	if (read_cpu_r)
	  OUT_CPU <= out;

	read_dma_r <= read_dma_w;
	read_cpu_r <= read_cpu_w;

	if (read_dma_w)
	  read_addr <= R_ADDR_DMA;
	else
	  if (read_cpu_w)
	    read_addr <= ADDR_CPU;

	if (we)
	  mem[write_addr] <= in;

	if (WRITE_CPU && !(WRITE_DMA || WRITE_CPU_ACK))
	  WRITE_CPU_ACK <= 1;
	else
	  WRITE_CPU_ACK <= 0;
      end

endmodule // hyper_scheduler_mem

module hyper_scheduler(input CLK,
		       input RST);
  reg [1:0] 		     trans_req, trans_ack,
			     refresh_req, refresh_ack;
  reg [3:0] 		     big_carousel;
  reg [7:0] 		     small_carousel;

  assign MEM_W_DATA = {cont_trans_r,EXEC_OLD_ADDRESS};

  // Should fit in two gates. Otherwise, register the wires and use those.
  assign READ_MEM = trg_gb_0 || trg_gb_1 || (trg_mb && time_mb);

  assign small_carousel_reset = small_carousel == 8'hbf;

  // Up to a maximum of 2 simultaneous 1 Gbps transactions.
  // Up to a maximum of 6 simultaneous 12.5 Mbps transactions.

  assign trg_gb_0 = small_carousel == 8'h00;
  assign trg_gb_1 = small_carousel == 8'h60;
  assign trg_mb   = small_carousel == 8'h02;

  assign time_mb = (big_carousel == 4'h4) || (big_carousel == 4'h6) ||
		   (big_carousel == 4'h8) || (big_carousel == 4'ha) ||
		   (big_carousel == 4'hc) || (big_carousel == 4'he);

  /* There are one or two instances in the code where having mb and rfrs
   * on the same big_carousel cycle is simply not supported. At least on
   * the gb_0 side of the cycle. */
  assign time_rfrs = (big_carousel == 4'h1) || (big_carousel == 4'h3) ||
		     (big_carousel == 4'h5) || (big_carousel == 4'h7) ||
		     (big_carousel == 4'h9) || (big_carousel == 4'hb) ||
		     (big_carousel == 4'hd) || (big_carousel == 4'hf);

  assign transaction_active = MEM_R_DATA[66]; // dummy address
  assign remaining_len = MEM_R_DATA[63:32]; // dummy address
  assign new_section = MEM_R_DATA[65:64]; // dummy address

  // should fit in two gates
  assign MEM_R_ADDR = trg_gb_0 ? 0 : (trg_gb_1 ? 1 : big_carousel[3:1]);

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
		    EXEC_OLD_ADDR : addr_from_mem;

  assign last_block_w = (remaining_len[31:6] ^ 0) == 0;

  assign BL1 = last_block_w ? remaining_len[5:0] : 6'h3f;
  assign BL2 = EXEC_BLOCK_LENGTH - EXEC_COUNT_SENT;
  assign new_block_length = (posedge_EXEC_READY && EXEC_ENDOF_PAGE) ?
			    BL2 : BL1;

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

	addr_from_mem <= MEM_R_DATA[31:0]; // dummy_address

	if (READ_MEM)
	  save0_MEM_R_ADDR <= MEM_R_ADDR;

        if (trg_gb_0 && time_rfrs)
          refresh_req <= refresh_req +1;

	trg_post <= READ_MEM;
	trg_post_post <= trg_post;
	if (trg_post_post && transaction_active &&
	    // A suggestion. Note that for writing to a periphery,
	    // you want periph_can_take_it[save0_MEM_R_ADDR].
	    periph_has_something[save0_MEM_R_ADDR])
	  begin
	    trans_req <= trans_req +1;
	    save1_MEM_R_ADDR <= save0_MEM_R_ADDR;
	  end

	if (posedge_EXEC_READY && !EXEC_ENDOF_PAGE)
	  begin
	    trans_ack <= trans_ack +1;
	    MEM_W_ADDR <= save2_MEM_R_ADDR;
	    WRITE_MEM <= 1;
	    cont_trans_r <= !(last_block_r && (EXEC_BLOCK_LENGTH ==
					       EXEC_COUNT_SENT));
	    // Maybe also raise an interrupt if cont_trans_r?
	  end
	else
	  WRITE_MEM <= 0;

	if (GO)
	  begin
	    EXEC_NEW_ADDR <= new_addr;
	    RST_mvblck <= 1;
	    $configure_switch();
	  end
	else
	  if (posedge_EXEC_READY && (!EXEC_ENDOF_PAGE))
	    RST_mvblck <= 0;

	if (exec_refresh)
	  begin
	    MCU_REFRESH_STROBE <= ~MCU_REFRESH_STROBE;
	    refresh_ack <= refresh_ack +1;
	  end

	if (enter_stage_1)
	  begin
	    EXEC_NEW_SECTION <= new_section;
	    trans_ack <= trans_ack +1;
	    save2_MEM_R_ADDR <= save1_MEM_R_ADDR;
	    last_block_r <= last_block_w;
	  end

	if ((enter_stage_1) ||
	    (posedge_EXEC_READY && EXEC_ENDOF_PAGE))
	  begin
	    GO <= 1;
	    EXEC_BLOCK_LENGTH <= new_block_length;
	  end
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
		       output [31:0] 	 OLD_ADDR,
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
  reg [23:0] 				 OLD_ADDR_high;
  reg [7:0] 				 OLD_ADDR_low;
  reg 					 carry_old_addr_calc,
					 add_old_addr_high;

  reg 					   blck_working_prev;
  reg [1:0] 				   issue_op;
  reg [3:0] 				   state;

  wire 					   do_go;
  wire [5:0] 				   rest_of_the_way;
  wire [12:0] 				   end_addr;

  assign OLD_ADDR = {OLD_ADDR_high,OLD_ADDR_low};

  assign BLCK_ISSUE = issue_op[0] ^ issue_op[1];

  assign end_addr = BLCK_START + BLOCK_LENGTH;
  assign rest_of_the_way = (~BLCK_START[5:0]) + 1; // Supports arbitrary
                                                   // block lengths.

  assign do_go = GO && (state == 4'b1000);
  assign READY = state[3];

  always @(posedge CLK)
    if (!RST)
      begin
	OLD_ADDR_high <= 0; OLD_ADDR_low <= 0; carry_old_addr_calc <= 0;
	MCU_PAGE_ADDR <= 0; BLCK_START <= 0; MCU_REQUEST_ALIGN <= 0;
	blck_working_prev <= 0; issue_op <= 0; BLCK_COUNT_REQ <= 0;
	ENDOF_PAGE <= 0; COUNT_SENT <= 0; add_old_addr_high <= 0;
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
	    MCU_REQUEST_ALIGN <= 1; // Change this for supporting multiple
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

	    {carry_old_addr_calc,OLD_ADDR_low} <= BLCK_START[7:0] +
						  {2'b00,BLCK_COUNT_SENT};
	    ENDOF_PAGE <= end_addr[12] && (BLCK_COUNT_REQ ==
					   BLCK_COUNT_SENT);
	    COUNT_SENT <= BLCK_COUNT_SENT;
	    add_old_addr_high <= 1;
	  end
	else
	  add_old_addr_high <= 0;

	if (add_old_addr_high)
	  OLD_ADDR_high <= {MCU_PAGE_ADDR,BLCK_START[11:8]} +
			   {23'd0,carry_old_addr_calc};

//	if (((MCU_REQUEST_ALIGN[0] && MCU_GRANT_ALIGN[0]) ||
//	     (MCU_REQUEST_ALIGN[1] && MCU_GRANT_ALIGN[1])) && // also FIXME
	if (MCU_REQUEST_ALIGN && MCU_GRANT_ALIGN && //FIXME propagation time
	    ~BLCK_ISSUE && ~BLCK_WORKING && ~blck_working_prev && //approx
	    (state[1] || state[2]))
	  issue_op[0] <= ~issue_op[0];
	issue_op[1] <= issue_op[0]; // Supposed to be out of the if block.
      end

endmodule // hyper_lsab_dram
