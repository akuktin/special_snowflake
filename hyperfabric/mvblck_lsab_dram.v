module hyper_scheduler_mem(input CLK,
			   input 	     RST,
			   // ---------------------
			   input 	     READ_CPU,
			   input 	     WRITE_CPU,
			   output 	     READ_CPU_ACK,
			   output reg 	     WRITE_CPU_ACK,
			   input [2:0] 	     ADDR_CPU,
			   input [63:0]      IN_CPU,
			   output reg [31:0] OUT_CPU,
			   // ---------------------
			   input 	     READ_DMA,
			   input 	     WRITE_DMA,
			   input [2:0] 	     R_ADDR_DMA,
			   input [2:0] 	     W_ADDR_DMA,
			   input [63:0]      IN_DMA,
			   output reg [63:0] OUT_DMA,
			   // ---------------------
			   output reg [23:0] LEN_0,
			   output reg 	     DIR_0,
			   output reg 	     EN_STB_0,
			   output reg [23:0] LEN_1,
			   output reg 	     DIR_1,
			   output reg 	     EN_STB_1,
			   output reg [23:0] LEN_2,
			   output reg 	     DIR_2,
			   output reg 	     EN_STB_2,
			   output reg [23:0] LEN_3,
			   output reg 	     DIR_3,
			   output reg 	     EN_STB_3);
  reg [65:0] 				     mem[7:0];
  reg [23:0] 				     orig_len[7:0];
  reg [65:0] 				     in_r;
  reg [23:0] 				     in_orig_r;
  reg 					     read_cpu_r, read_dma_r,
					     we_dma, we_pre_r;
  reg [2:0] 				     read_addr, write_addr_r;

  wire 					     read_cpu_w, read_dma_w, we,
					     atomic_strobe, tran_started,
					     we_pre;
  wire [2:0] 				     write_addr;
  wire [23:0] 				     cpu_len;
  wire [21:0] 				     cpu_lenfixed;
  wire [65:0] 				     out, in;

  assign READ_CPU_ACK = read_cpu_r;

  assign out = mem[read_addr];
  assign read_dma_w = READ_DMA;
  assign read_cpu_w = READ_CPU && !(READ_DMA || READ_CPU_ACK);

  assign cpu_len = IN_CPU[55:32];
  assign cpu_lenfixed = (cpu_len[1:0] == 0) ?
			cpu_len[23:2] : (cpu_len[23:2] +1);
  assign in = WRITE_DMA ?
	      {2'h1,IN_DMA} :
	      {2'h0,IN_CPU[63:56],cpu_lenfixed,2'h0,
	       IN_CPU[31:3],3'h0};
  assign write_addr = WRITE_DMA ? W_ADDR_DMA : ADDR_CPU;
  assign we_pre = WRITE_DMA ? 1 : (WRITE_CPU && !WRITE_CPU_ACK);
  assign we = we_dma ? (we_pre_r && !(atomic_strobe ^ in_r[61])) :
                       we_pre_r;

  assign atomic_strobe = mem[write_addr_r][61];
  assign tran_started = mem[write_addr_r][64];

  initial
    begin
      mem[0] <= 0; mem[1] <= 0; mem[2] <= 0; mem[3] <= 0;
      mem[4] <= 0; mem[5] <= 0; mem[6] <= 0; mem[7] <= 0;
      orig_len[0] <= 0; orig_len[1] <= 0;
      orig_len[2] <= 0; orig_len[3] <= 0;
      orig_len[4] <= 0; orig_len[5] <= 0;
      orig_len[6] <= 0; orig_len[7] <= 0;
    end

  always @(posedge CLK)
    if (!RST)
      begin
	OUT_DMA <= 0; OUT_CPU <= 0; WRITE_CPU_ACK <= 0;
	read_cpu_r <= 0; read_dma_r <= 0; read_addr <= 0;
	write_addr_r <= 0; in_r <= 0; we_dma <= 0; we_pre_r <= 0;
	in_orig_r <= 0;
	LEN_0 <= 0; DIR_0 <= 0; EN_STB_0 <= 0;
	LEN_1 <= 0; DIR_1 <= 0; EN_STB_1 <= 0;
	LEN_2 <= 0; DIR_2 <= 0; EN_STB_2 <= 0;
	LEN_3 <= 0; DIR_3 <= 0; EN_STB_3 <= 0;
      end
    else
      begin
	if (read_dma_r)
	  OUT_DMA <= out[63:0];
	if (read_cpu_r)
	  OUT_CPU <= out[63:32];

	read_dma_r <= read_dma_w;
	read_cpu_r <= read_cpu_w;

	if (read_dma_w)
	  read_addr <= R_ADDR_DMA;
	else
	  if (read_cpu_w)
	    read_addr <= ADDR_CPU;

	if (we_pre)
	  begin
	    write_addr_r <= write_addr;
	    in_r <= in;
	    in_orig_r <= cpu_len;
	  end
	we_dma <= WRITE_DMA;
	we_pre_r <= we_pre;

	if (we)
	  begin
	    mem[write_addr_r] <= in_r;
	    if (!we_dma)
	      orig_len[write_addr_r] <= in_orig_r;
	    if (we_dma && !tran_started)
	      begin
		case (in_r[57:56])
		  2'h0: begin
		    LEN_0 <= orig_len[write_addr_r];
		    DIR_0 <= in_r[58];
		    EN_STB_0 <= !EN_STB_0;
		  end
		  2'h1: begin
		    LEN_1 <= orig_len[write_addr_r];
		    DIR_1 <= in_r[58];
		    EN_STB_1 <= !EN_STB_1;
		  end
		  2'h2: begin
		    LEN_2 <= orig_len[write_addr_r];
		    DIR_2 <= in_r[58];
		    EN_STB_2 <= !EN_STB_2;
		  end
		  2'h3: begin
		    LEN_3 <= orig_len[write_addr_r];
		    DIR_3 <= in_r[58];
		    EN_STB_3 <= !EN_STB_3;
		  end
		endcase // case (in_r[57:56])
	      end
	  end

	if (WRITE_CPU && !(WRITE_DMA || WRITE_CPU_ACK))
	  WRITE_CPU_ACK <= 1;
	else
	  WRITE_CPU_ACK <= 0;
      end

endmodule // hyper_scheduler_mem

module hyper_scheduler(input CLK,
		       input 		 RST,
		       input 		 CR_E0,
		       input 		 CR_E1,
		       input 		 CR_E2,
		       input 		 CR_E3,
		       input 		 CW_F0,
		       input 		 CW_F1,
		       input 		 CW_F2,
		       input 		 CW_F3,
		       output reg 	 GO,
		       input 		 EXEC_READY,
		       output reg [5:0]  EXEC_BLOCK_LENGTH,
		       input [5:0] 	 EXEC_COUNT_SENT,
		       input 		 EXEC_RESTART_OP,
		       output reg [1:0]  EXEC_NEW_SECTION,
		       output reg 	 MCU_REFRESH_STROBE,
		       output reg [1:0]  EXEC_SELECT_DRAM,
		       output reg [2:0]  SWCH_ISEL,
		       output reg [2:0]  SWCH_OSEL,
		       output reg [31:0] EXEC_NEW_ADDR,
		       input [31:0] 	 EXEC_OLD_ADDR,
		       output reg 	 IRQ,
		       output reg [2:0]  IRQ_DESC,
		       output reg 	 WRITE_MEM,
		       output [2:0] 	 MEM_W_ADDR,
		       output [2:0] 	 MEM_R_ADDR,
		       input 		 IRQ_IN,
		       input [2:0] 	 ANCILL_IN,
		       output 		 READ_MEM,
		       output reg 	 CAREOF_INT,
		       output reg [1:0]  RST_MVBLCK,
		       input [63:0] 	 MEM_R_DATA,
		       output [63:0] 	 MEM_W_DATA,
		       input 		 FRDRAM_DEVERR);
  reg [3:0] 		     big_carousel;
  reg [7:0] 		     small_carousel;

  reg [23:0] 		     saved_mem_addr;
  reg [21:0] 		     save2_remaining_len, leftover_len;
  reg [7:0] 		     save2_read_data;
  reg [2:0] 		     save2_MEM_R_ADDR, save1_MEM_R_ADDR,
			     save0_MEM_R_ADDR;
  reg [1:0] 		     trans_ack, trans_req, refresh_ack,
			     refresh_req, block_lowlen;
  reg 			     last_block_r, cont_trans_r, trg_post,
			     trg_post_post, save_data_mem, EXEC_READY_prev,
			     save2_last_block, is_restart_r, block_valid;

  reg 			     periph_ready[7:0];

  wire [23:0] 		     new_addr_high;
  wire [21:0] 		     remaining_len;
  wire [7:0] 		     new_addr_low;
  wire [5:0] 		     BL1, BL2, new_block_length;
  wire [2:0] 		     isel, osel;
  wire [1:0] 		     section;
  wire 			     cont_trans, last_block_w, exec_refresh,
			     enter_stage_1, refresh_ctr_mismatch,
			     counters_mismatch, posedge_EXEC_READY,
			     rdmem_op, data_mem, transaction_active,
			     time_rfrs, time_mb, trg_mb, trg_gb_0,
			     trg_gb_1, small_carousel_reset, w_careof_int;

  assign MEM_W_ADDR = save2_MEM_R_ADDR;
  assign MEM_W_DATA = {cont_trans_r,block_valid, // approx
		       save2_read_data[5:0], // approx
		       leftover_len,block_lowlen,EXEC_OLD_ADDR};

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

  assign transaction_active = MEM_R_DATA[63];

  assign remaining_len = MEM_R_DATA[55:34];
  assign section = MEM_R_DATA[57:56];
  assign rdmem_op = MEM_R_DATA[58];
  assign data_mem = MEM_R_DATA[59]; // actually supposed to be the highest
                                    // usable bit in the DRAM address
  assign w_careof_int = MEM_R_DATA[60];

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

  assign new_addr_low = (posedge_EXEC_READY && EXEC_RESTART_OP) ?
			EXEC_OLD_ADDR[7:0] : MEM_R_DATA[7:0];
  assign new_addr_high = is_restart_r ?
			 EXEC_OLD_ADDR[31:8] : saved_mem_addr;

  assign last_block_w = (remaining_len[21:6] ^ 0) == 0;

  assign BL1 = last_block_r ? remaining_len[5:0] : 6'h3f;
  assign BL2 = EXEC_BLOCK_LENGTH - EXEC_COUNT_SENT;
  assign new_block_length = (posedge_EXEC_READY && EXEC_RESTART_OP) ?
			    BL2 : BL1;

  assign isel = rdmem_op ? 3'b100 : {1'h0,data_mem,~data_mem};
  assign osel = rdmem_op ? {1'h0,data_mem,~data_mem} : 3'b100;

  assign cont_trans = (! (save2_last_block &&
			  (EXEC_BLOCK_LENGTH == EXEC_COUNT_SENT))) &&
		      (! IRQ_IN);

  always @(posedge CLK)
    if (!RST)
      begin
	small_carousel <= 8'hc1; // Out of bounds.
	big_carousel <= 4'h3;
	trans_req <= 0; trans_ack <= 0; refresh_req <= 0; refresh_ack <= 0;
	EXEC_READY_prev <= 1'b1; GO <= 0; EXEC_BLOCK_LENGTH <= 0;
	EXEC_NEW_SECTION <= 0; MCU_REFRESH_STROBE <= 0;
	EXEC_SELECT_DRAM <= 0; SWCH_ISEL <= 0; SWCH_OSEL <= 0;
	EXEC_NEW_ADDR <= 0; IRQ <= 0; WRITE_MEM <= 0;
	save2_MEM_R_ADDR <= 0; save1_MEM_R_ADDR <= 0;
	save0_MEM_R_ADDR <= 0; save2_last_block <= 0;
	last_block_r <= 0; cont_trans_r <= 0; trg_post <= 0;
	trg_post_post <= 0; save_data_mem <= 0; is_restart_r <= 0;
	periph_ready[0] <= 0; periph_ready[1] <= 0; periph_ready[2] <= 0;
	periph_ready[3] <= 0; periph_ready[4] <= 0; periph_ready[5] <= 0;
	periph_ready[6] <= 0; periph_ready[7] <= 0;
	save2_read_data <= 0; save2_remaining_len <= 0;
	leftover_len <= 0; IRQ_DESC <= 0; saved_mem_addr <= 0;
	CAREOF_INT <= 0; RST_MVBLCK <= 0; block_valid <= 0;
	block_lowlen <= 0;
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

	// {read_memory_op,section}
	periph_ready[0] <= !CW_F0; periph_ready[1] <= !CW_F1;
	periph_ready[2] <= !CW_F2; periph_ready[3] <= !CW_F3;
	periph_ready[4] <= !CR_E0; periph_ready[5] <= !CR_E1;
	periph_ready[6] <= !CR_E2; periph_ready[7] <= !CR_E3;

	last_block_r <= last_block_w;

	if (READ_MEM)
	  save0_MEM_R_ADDR <= MEM_R_ADDR;

        if (trg_gb_0 && time_rfrs)
          refresh_req <= refresh_req +1;

	trg_post <= READ_MEM;
	trg_post_post <= trg_post;
	if (trg_post_post && transaction_active &&
	    periph_ready[{rdmem_op,section}])
	  begin
	    trans_req <= trans_req +1;
	    save1_MEM_R_ADDR <= save0_MEM_R_ADDR;
	  end

	if (posedge_EXEC_READY && !EXEC_RESTART_OP)
	  begin
	    WRITE_MEM <= 1;
	    leftover_len <= save2_remaining_len - {16'd0,EXEC_COUNT_SENT};
	    cont_trans_r <= cont_trans;
	    IRQ <= !cont_trans; // add ` && ANCILL_IN[0]' (former VALID_IN)
	    IRQ_DESC <= MEM_W_ADDR;
	    EXEC_SELECT_DRAM <= 0;
	    RST_MVBLCK <= 0;
	    block_lowlen <= ANCILL_IN[2:1];
	    // The below is actually, *really* ugly. If I continue like this,
	    // I'll soon end up with spagheti code. But, since hyperfabric
	    // just got reclassified as a experimental implementation, this
	    // is probably OK.

	    // Note the multiplexing of sense.
	    block_valid <= (ANCILL_IN[0] || !FRDRAM_DEVERR);
	  end
	else
	  begin
	    WRITE_MEM <= 0;
	    IRQ <= 0;
	  end

	if (exec_refresh)
	  begin
	    MCU_REFRESH_STROBE <= ~MCU_REFRESH_STROBE;
	    refresh_ack <= refresh_ack +1;
	  end

	if (enter_stage_1)
	  begin
	    EXEC_NEW_SECTION <= section;
	    trans_ack <= trans_ack +1;
	    save2_MEM_R_ADDR <= save1_MEM_R_ADDR;
	    save2_read_data <= MEM_R_DATA[63:56];
	    save2_remaining_len <= remaining_len;
	    save2_last_block <= last_block_r;

	    EXEC_SELECT_DRAM <= {data_mem,~data_mem};
	    RST_MVBLCK <= {rdmem_op,~rdmem_op};
	    SWCH_ISEL <= isel;
	    SWCH_OSEL <= osel;
	    CAREOF_INT <= w_careof_int;
	  end // if (enter_stage_1)

	if (GO)
	  begin
	    EXEC_NEW_ADDR[31:8] <= new_addr_high;
	  end

	if ((enter_stage_1) ||
	    (posedge_EXEC_READY && EXEC_RESTART_OP))
	  begin
	    saved_mem_addr[21:0] <= MEM_R_DATA[29:8];
	    is_restart_r <= (posedge_EXEC_READY && EXEC_RESTART_OP);

	    GO <= 1;
	    EXEC_BLOCK_LENGTH <= new_block_length;
	    EXEC_NEW_ADDR[7:0] <= new_addr_low;
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
		       input [1:0] 	 SELECT_DRAM,
		       input [5:0] 	 BLOCK_LENGTH,
		       input [31:0] 	 NEW_ADDR,
		       input [1:0] 	 NEW_SECTION,
		       output [31:0] 	 OLD_ADDR,
		       output 		 READY,
		       output reg 	 RESTART_OP,
		       output reg [5:0]  COUNT_SENT,
		       output reg 	 IRQ,
		       output reg [2:0]  ANCILL,
		       output reg 	 FRDRAM_DEVERR,
			 /* begin BLOCK MOVER */
		       output reg [11:0] BLCK_START,
		       output reg [5:0]  BLCK_COUNT_REQ,
		       output 		 BLCK_ISSUE,
		       output reg [1:0]  BLCK_SECTION,
		       input [5:0] 	 BLCK_COUNT_SENT,
		       input 		 BLCK_WORKING,
		       input 		 BLCK_IRQ,
		       input 		 BLCK_ABRUPT_STOP,
		       input 		 BLCK_FRDRAM_DEVERR,
		       input [2:0] 	 BLCK_ANCILL,
			 /* begin MCU */
		       output reg [19:0] MCU_PAGE_ADDR,
		       output reg [1:0]  MCU_REQUEST_ALIGN, // aka DRAM_SEL
		       input [1:0] 	 MCU_GRANT_ALIGN);
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
	RESTART_OP <= 0; COUNT_SENT <= 0; add_old_addr_high <= 0;
	IRQ <= 0; ANCILL <= 0; FRDRAM_DEVERR <= 0;
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
	    MCU_REQUEST_ALIGN <= SELECT_DRAM;

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
	    // This is actually a speed hack. We hope the CPU will force a
	    // precharge which we will then hijack.
	    MCU_REQUEST_ALIGN <= 0;

	    {carry_old_addr_calc,OLD_ADDR_low} <= BLCK_START[7:0] +
						  {2'b00,BLCK_COUNT_SENT};
	    RESTART_OP <= (end_addr[12] &&
			   (BLCK_COUNT_REQ == BLCK_COUNT_SENT) &&
			   (! BLCK_ABRUPT_STOP));
	    COUNT_SENT <= BLCK_COUNT_SENT;
	    IRQ <= BLCK_IRQ;
	    ANCILL <= BLCK_ANCILL;
	    FRDRAM_DEVERR <= BLCK_FRDRAM_DEVERR;
	    add_old_addr_high <= 1;
	  end
	else
	  add_old_addr_high <= 0;

	if (add_old_addr_high)
	  OLD_ADDR_high <= {MCU_PAGE_ADDR,BLCK_START[11:8]} +
			   {23'd0,carry_old_addr_calc};

	if (((MCU_REQUEST_ALIGN[0] && MCU_GRANT_ALIGN[0]) ||
	     (MCU_REQUEST_ALIGN[1] && MCU_GRANT_ALIGN[1])) && // also FIXME
//	if (MCU_REQUEST_ALIGN && MCU_GRANT_ALIGN && //FIXME propagation time
	    ~BLCK_ISSUE && ~BLCK_WORKING && ~blck_working_prev && //approx
	    (state[1] || state[2]))
	  issue_op[0] <= ~issue_op[0];
	issue_op[1] <= issue_op[0]; // Supposed to be out of the if block.
      end

endmodule // hyper_lsab_dram
