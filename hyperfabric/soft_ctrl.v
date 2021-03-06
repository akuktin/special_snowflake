module Gremlin(input CLK,
	       input 		 RST,
		    // ---------------------
	       input 		 READ_CPU,
	       input 		 WRITE_CPU,
	       output 		 READ_CPU_ACK,
	       output 		 WRITE_CPU_ACK,
	       input [2:0] 	 ADDR_CPU,
	       input [63:0] 	 IN_CPU,
	       output reg [31:0] OUT_CPU,
		    // ---------------------
	       output reg [2:0]  IRQ_DESC,
	       output 		 IRQ,
		    // ---------------------

	       output [1:0] 	 RST_MVBLCK,
	       output 		 MCU_REFRESH_STROBE,
	       output reg [2:0]  SWCH_ISEL,
	       output reg [2:0]  SWCH_OSEL,
	       output 		 CAREOF_INT,

		 /* begin BLOCK MOVER */
	       output reg [8:0]  BLCK_START,
	       output reg [5:0]  BLCK_COUNT_REQ,
	       output 		 BLCK_ISSUE,
	       output reg [1:0]  BLCK_SECTION,
	       input [5:0] 	 BLCK_COUNT_SENT,
	       input 		 BLCK_WORKING,
	       input 		 BLCK_IRQ,
	       input 		 BLCK_ABRUPT_STOP,
	       input 		 BLCK_FRDRAM_DEVERR,
	       input [24:0] 	 BLCK_ANCILL,
	         /* begin MCU */
	       output reg [22:0] MCU_PAGE_ADDR,
	       output [1:0] 	 MCU_REQUEST_ALIGN, // aka DRAM_SEL
	       input [1:0] 	 MCU_GRANT_ALIGN,
		    // ---------------------

	       output reg [23:0] LEN_0,
	       output reg 	 DIR_0,
	       output 		 EN_STB_0,
	       output reg [23:0] LEN_1,
	       output reg 	 DIR_1,
	       output 		 EN_STB_1,
	       output reg [23:0] LEN_2,
	       output reg 	 DIR_2,
	       output 		 EN_STB_2,
	       output reg [23:0] LEN_3,
	       output reg 	 DIR_3,
	       output 		 EN_STB_3);
  reg 				 READ_CPU_ACK = 1'b0,
				 WRITE_CPU_ACK = 1'b0;

  assign CAREOF_INT = 1'b1;
  reg [1:0] 			 RST_MVBLCK = 2'h0,
				 MCU_REQUEST_ALIGN = 2'h0;
  reg 				 MCU_REFRESH_STROBE = 1'b0;
  reg 				 EN_STB_0 = 1'b0, EN_STB_1 = 1'b0,
				 EN_STB_2 = 1'b0, EN_STB_3 = 1'b0;

  reg        d_r_en_cpu = 1'b0, d_r_en_cpu_delay = 1'b0,
	     d_w_en_cpu = 1'b0,
	     READ_CPU_r = 1'b1, WRITE_CPU_r = 1'b1, low_addr_bits_r;
  reg [1:0]  low_addr_bits_w = 2'd0;
  reg [15:0] from_cpu_word;

  wire [15:0] d_w_data, d_r_data;
  wire [7:0]  d_w_addr, d_r_addr;
  wire 	      d_w_en, d_r_en;

  reg [15:0] accumulator, memory_operand,
	     instr_f = 16'h4d00, instr_o = 16'h4d00, acc_output;
  reg [7:0]  ip = 8'd0, index, index_reg, index_capture;
  reg [1:0]  trans_req = 2'h0, irq_strobe = 2'h0;
  reg 	     add_carry, save_carry, waitkill = 1'b0, advance_ip = 1'b1,
	     issue_trans_ack = 1'b0, issue_trans_req = 1'b0;

  wire [15:0] accumulator_adder, instr;
  wire [7:0] ip_nxt, d_r_addr_sys, d_w_addr_sys;
  wire 	     d_w_en_sys, d_r_en_sys, cur_carry;

  reg [3:0]  big_carousel = 4'h3;
  reg [7:0]  small_carousel = 8'hc1; // Out of bounds. // FIXME!!
  reg [1:0]  issue_op = 2'h0, trans_ack = 2'h0;
  reg [2:0]  write_output_desc;
  reg 	     trans_active = 1'b0, blck_working_prev = 1'b0,
	     active_trans_thistrans, trans_ends = 1'b0,
	     write_output_reg, issue_op_new = 1'b0, ready_trans = 1'b0,
	     rdmem_op, opon_data, trg_gb_0 = 1'b0, trg_gb_1 = 1'b0,
	     time_mb = 1'b0, time_rfrs = 1'b0,
	     small_carousel_reset = 1'b0, refresh_req = 1'b0;

  reg 	     EN_STB_0_pre = 1'b0, EN_STB_1_pre = 1'b0,
	     EN_STB_2_pre = 1'b0, EN_STB_3_pre = 1'b0;

  wire [2:0] carousel_section;
  wire 	     refresh_ctr_mismatch, blck_abort;
  reg 	     carousel_section_02, carousel_section_1mb;

  reg [15:0] input_reg_0[1:0], input_reg_1[1:0];

  iceram16 data_mem(.RDATA(d_r_data), // 16 out
		    .RADDR(d_r_addr), // 8 in
		    .RE(d_r_en), // 1 in
		    .RCLKE(1'b1), // 1 in
		    .RCLK(CLK), // 1 in
		    .WDATA(d_w_data), // 16 in
		    .MASK({(16){1'b0}}), // 16 in
		    .WADDR(d_w_addr), // 8 in
		    .WE(d_w_en), // 1 in
		    .WCLKE(1'b1), // 1 in
		    .WCLK(CLK)); // 1 in

  assign d_r_addr = d_r_en_sys ? d_r_addr_sys :
		                 {3'h0,ADDR_CPU,1'b0,low_addr_bits_r};
  assign d_w_addr = d_w_en_sys ? d_w_addr_sys :
		                 {3'h0,ADDR_CPU,low_addr_bits_w};

  assign d_r_en = d_r_en_cpu || d_r_en_sys;
  assign d_w_en = d_w_en_cpu || d_w_en_sys;
  assign d_w_data = d_w_en_sys ? accumulator : from_cpu_word;

  always @(low_addr_bits_w or IN_CPU)
    case (low_addr_bits_w)
      2'h0: from_cpu_word <= IN_CPU[63:48];
      2'h1: from_cpu_word <= IN_CPU[47:32];
      2'h2: from_cpu_word <= IN_CPU[31:16];
      2'h3: from_cpu_word <= IN_CPU[15:0];
    endcase // case (low_addr_bits)

  always @(posedge CLK)
      begin
	WRITE_CPU_r <= WRITE_CPU;
	if (WRITE_CPU && !WRITE_CPU_r)
	  begin
	    d_w_en_cpu <= 1;
	    low_addr_bits_w <= 0;

	    WRITE_CPU_ACK <= 0;

	    case (IN_CPU[57:56])
	      2'h0: begin
		LEN_0 <= {8'h0,IN_CPU[47:32]};
		DIR_0 <= IN_CPU[58];
		EN_STB_0_pre <= !EN_STB_0_pre;
	      end
	      2'h1: begin
		LEN_1 <= {8'h0,IN_CPU[47:32]};
		DIR_1 <= IN_CPU[58];
		EN_STB_1_pre <= !EN_STB_1_pre;
	      end
	      2'h2: begin
		LEN_2 <= {8'h0,IN_CPU[47:32]};
		DIR_2 <= IN_CPU[58];
		EN_STB_2_pre <= !EN_STB_2_pre;
	      end
	      2'h3: begin
		LEN_3 <= {8'h0,IN_CPU[47:32]};
		DIR_3 <= IN_CPU[58];
		EN_STB_3_pre <= !EN_STB_3_pre;
	      end
	    endcase // case (IN_CPU[57:56])
	  end
	else
	  begin
	    if (d_w_en_cpu && !d_w_en_sys)
	      low_addr_bits_w <= low_addr_bits_w +1;

	    if ((low_addr_bits_w == 2'b11) && !d_w_en_sys)
	      begin
		d_w_en_cpu <= 0;
		WRITE_CPU_ACK <= 1;
	      end
	    else
	      WRITE_CPU_ACK <= 0;
	  end // else: !if(WRITE_CPU && !WRITE_CPU_r)

	READ_CPU_r <= READ_CPU;
	if (READ_CPU && !READ_CPU_r)
	  begin
	    d_r_en_cpu <= 1;
	    low_addr_bits_r <= 0;
	    READ_CPU_ACK <= 0;
	  end
	else
	  begin
	    if (d_r_en_cpu && !d_r_en_sys)
	      low_addr_bits_r <= low_addr_bits_r +1;

	    if ((low_addr_bits_r == 1'b1) && !d_r_en_sys)
	      d_r_en_cpu <= 0;

	    if (d_r_en_cpu_delay && (low_addr_bits_r == 1'b0))
	      READ_CPU_ACK <= 1;
	    else
	      READ_CPU_ACK <= 0;
	  end // else: !if(READ_CPU && !READ_CPU_r)

	d_r_en_cpu_delay <= (d_r_en_cpu && !d_r_en_sys);
	if (d_r_en_cpu_delay)
	  begin
	    if (low_addr_bits_r == 1'b1) // no delay register
	      OUT_CPU[31:16] <= d_r_data;
	    else
	      OUT_CPU[15:0] <= d_r_data;
	  end
      end

  iceram16 prog_mem(.RDATA(instr), // 16 out
		    .RADDR(ip_nxt), // 8 in
		    .RE(1'b1), // 1 in
		    .RCLKE(1'b1), // 1 in
		    .RCLK(CLK), // 1 in
		    .WDATA({(16){1'b0}}), // 16 in
		    .MASK({(16){1'b0}}), // 16 in
		    .WADDR({(8){1'b0}}), // 8 in
		    .WE(1'b0), // 1 in
		    .WCLKE(1'b0), // 1 in
		    .WCLK(CLK)); // 1 in


  assign ip_nxt = (instr_o[15] && (accumulator != 16'd0)) ?
		  instr_o[7:0] : ip + advance_ip;

  assign d_r_addr_sys = instr[12] ? index : instr[7:0];
  assign d_w_addr_sys = instr_o[12] ? index_capture : instr_o[7:0];
  assign d_w_en_sys   = (instr_o[11:8] == 4'h6) || // store
			(instr_o[11:8] == 4'h7);
  assign d_r_en_sys   = (!instr[14]) && (!waitkill);

  assign {cur_carry,accumulator_adder} = accumulator + memory_operand +
					 add_carry;

  assign IRQ = irq_strobe[0] ^ irq_strobe[1];

  always @(index_reg or instr_f[12] or instr_f[7:0])
    if (instr_f[12])
      index <= index_reg + instr_f[7:0];
    else
      index <= index_reg;

  reg [6:0] reg_page_lo_0, reg_page_lo_1;
  reg [8:0] reg_start_0, reg_start_1;
  reg [15:0] reg_page_hi_0, reg_page_hi_1;
  reg 	     reg_opon_data_0, reg_rdmem_op_0,
	     reg_opon_data_1, reg_rdmem_op_1;
  reg [11:0] reg_count_req_0, reg_count_req_1;
  reg [1:0]  reg_blck_sec_0, reg_blck_sec_1;

  always @(posedge CLK)
    begin
      if (RST)
        begin
          ip <= ip_nxt;
          advance_ip <= !((instr[11:8] == 4'hc) || (instr_f[11:8] == 4'hc));
        end

      irq_strobe[1] <= irq_strobe[0];
      case (instr_f[14:13])
	2'h0: memory_operand <= d_r_data;
	2'h1: memory_operand <= ~d_r_data;
	2'h2: memory_operand <= 0; // together with 0xe, fakes a NOP
	2'h3: memory_operand <= 16'hffff;
      endcase // case (instr_f[14:13])

      index_capture <= index_reg;
      if (instr_o[11:8] != 4'hc)
	index_reg <= index;

      waitkill <= (instr_f[11:8] == 4'h8) || (instr_o[11:8] == 4'h8);
      if (waitkill || !advance_ip)
	instr_f <= {1'b0,2'h2,1'b0,4'hd,8'h0}; // and 0x0000;
      else
	instr_f <= instr;
      if (instr_o[11:8] != 4'h8)
	instr_o <= instr_f;
      else
	if (accumulator == 0)
	  // accumulator will be nonzero by the time the instruction
	  // hits execution

	  // cmp/and 0x0000 {instr_o[7:0]};
	  instr_o <= {1'b1,2'h2,1'b0,4'hd,instr_o[7:0]};

      write_output_reg <= (instr_o[11:8] == 4'hb);
      write_output_desc <= instr_o[2:0];
      acc_output <= accumulator;

      case (instr_f[11:8])
	4'h0: add_carry <= 0;
	4'h1: add_carry <= 1;
	4'h2: add_carry <= save_carry;
	4'h3: add_carry <= cur_carry;
      endcase // case (instr_f[11:8])
      case (instr_o[11:8])
	4'h0: begin
	  accumulator <= accumulator_adder;
	  save_carry <= cur_carry;
	end
	4'h1: begin
	  accumulator <= accumulator_adder;
	  save_carry <= cur_carry;
	end
	4'h2: begin
	  accumulator <= accumulator_adder;
	  save_carry <= cur_carry;
	end
	4'h3: begin
	  accumulator <= accumulator_adder;
	  save_carry <= cur_carry;
	end

	4'h4: accumulator <= input_reg_0[instr_o[13]];
	4'h5: accumulator <= input_reg_1[instr_o[13]];
//	4'h6 // store
	4'h7: begin // swap (store and read)
	  accumulator <= memory_operand;
	end

	4'h8: begin // wait
	  accumulator <= accumulator -1;
	end
	4'h9: begin
	  irq_strobe[0] <= !irq_strobe[0]; // provisional
	  IRQ_DESC <= accumulator[15:13]; // maybe
	  accumulator <= memory_operand;
	end
	// fucking load instruction, bitch!
	4'ha: accumulator <= memory_operand;
	4'hb: begin
	  if ((!instr_o[13]) && (accumulator[13:2] != 0))// provisional
	    begin
	      issue_trans_req <= !issue_trans_req;
	      accumulator <= memory_operand;
	    end
	end

	4'hc: begin
	  index_reg <= accumulator[7:0];
	  accumulator <= memory_operand;
	end
	4'hd: accumulator <= accumulator & memory_operand;
	4'he: accumulator <= accumulator | memory_operand;
	4'hf: accumulator <= accumulator ^ memory_operand;
      endcase // case (instr_o[11:8])
      if (write_output_reg)
	begin
	  if (issue_trans_req != issue_trans_ack)
	    begin
	      issue_trans_ack <= issue_trans_req;
	      trans_req <= trans_req ^ {write_output_desc[2],
					!write_output_desc[2]};
	    end
	  if (write_output_desc[2] == 1'b1)
	    begin
	      case (write_output_desc[1:0])
		2'h0: begin
		  reg_page_lo_1 <= acc_output[15:9];
		  reg_start_1 <= acc_output[8:0];
		end
		2'h1: begin
		  reg_page_hi_1 <= acc_output;
		end
		2'h2: begin
		  reg_opon_data_1 <= acc_output[0];
		  reg_rdmem_op_1 <= acc_output[1];
		  reg_count_req_1 <= acc_output[13:2];
		  reg_blck_sec_1 <= acc_output[15:14];
		end
	      endcase // case (instr[1:0])
	    end
	  else
	    begin
	      case (write_output_desc[1:0])
		2'h0: begin
		  reg_page_lo_0 <= acc_output[15:9];
		  reg_start_0 <= acc_output[8:0];
		end
		2'h1: begin
		  reg_page_hi_0 <= acc_output;
		end
		2'h2: begin
		  reg_opon_data_0 <= acc_output[0];
		  reg_rdmem_op_0 <= acc_output[1];
		  reg_count_req_0 <= acc_output[13:2];
		  reg_blck_sec_0 <= acc_output[15:14];
		end
	      endcase // case (instr[1:0])
	    end // else: !if(write_output_desc[2] == 1'b1)
	end // if (write_output_reg)
    end // if (RST)

  assign BLCK_ISSUE = issue_op[0] ^ issue_op[1];

  assign blck_abort = BLCK_ABRUPT_STOP || BLCK_FRDRAM_DEVERR;

  assign carousel_section = small_carousel[7:5];

  always @(posedge CLK)
    begin
      if (RST)
	begin

	  // Up to a maximum of 2 simultaneous 1 Gbps transactions.
	  // Up to a maximum of 6 simultaneous 12.5 Mbps transactions.

	  trg_gb_0 <= small_carousel == 8'h00;
	  trg_gb_1 <= small_carousel == 8'h60;
	  //  assign trg_mb   = small_carousel == 8'h02;

	  time_mb <= (big_carousel == 4'h4) || (big_carousel == 4'h6) ||
		     (big_carousel == 4'h8) || (big_carousel == 4'ha) ||
		     (big_carousel == 4'hc) || (big_carousel == 4'he);

	  /* Having mb and rfrs on the same big_carousel cycle is simply
	   * not supported, at least on the gb_0 side of the cycle. */
	  time_rfrs <= (big_carousel == 4'h1) || (big_carousel == 4'h3) ||
		       (big_carousel == 4'h5) || (big_carousel == 4'h7) ||
		       (big_carousel == 4'h9) || (big_carousel == 4'hb) ||
		       (big_carousel == 4'hd) || (big_carousel == 4'hf);

	  ///////////////////////////////////////////////////////////////

	  small_carousel_reset <= (small_carousel == 8'hbe);
	  if (small_carousel_reset)
	    begin
	      small_carousel <= 0;
	      big_carousel <= big_carousel +1;
	    end
	  else
	    small_carousel <= small_carousel +1;

          if (trg_gb_0 && time_rfrs)
            refresh_req <= !refresh_req;

	  if (refresh_ctr_mismatch && !trans_active)
	    begin
	      MCU_REFRESH_STROBE <= !MCU_REFRESH_STROBE;
	    end
	end // if (RST)

      carousel_section_02 <= (carousel_section == 3'h0) ||
			     ((carousel_section == 3'h3) ||
			      (carousel_section == 3'h4));
      carousel_section_1mb <= ((carousel_section == 3'h1) ||
			       (carousel_section == 3'h2)) &&
			      time_mb;

      if ((trans_req[1] != trans_ack[1]) &&
	  carousel_section_02 && !trans_active)
	begin
	  rdmem_op <= reg_rdmem_op_1;
	  opon_data <= reg_opon_data_1;
	  BLCK_SECTION <= reg_blck_sec_1;
	  BLCK_COUNT_REQ <= reg_count_req_1;
	  BLCK_START <= reg_start_1;
	  MCU_PAGE_ADDR <= {reg_page_hi_1, reg_page_lo_1};

	  trans_ack[1] <= !trans_ack[1];
	  ready_trans <= 1;
	  trans_active <= 1;
	  active_trans_thistrans <= 1;
	end // if ((trans_req[1] != trans_ack[1]) &&...

      if ((trans_req[0] != trans_ack[0]) &&
	  carousel_section_1mb && !trans_active)
	begin
	  rdmem_op <= reg_rdmem_op_0;
	  opon_data <= reg_opon_data_0;
	  BLCK_SECTION <= reg_blck_sec_0;
	  BLCK_COUNT_REQ <= reg_count_req_0;
	  BLCK_START <= reg_start_0;
	  MCU_PAGE_ADDR <= {reg_page_hi_0, reg_page_lo_0};

	  trans_ack[0] <= !trans_ack[0];
	  ready_trans <= 1;
	  trans_active <= 1;
	  active_trans_thistrans <= 0;
	end // if ((trans_req[0] != trans_ack[0]) &&...

	if (ready_trans)
	  begin
	    ready_trans <= 0;
	    issue_op_new <= !issue_op_new;

	    // actually supposed to be the top usable bit in the address
	    MCU_REQUEST_ALIGN <= {opon_data,~opon_data};
	    // perhaps
	    RST_MVBLCK <= {rdmem_op,~rdmem_op};
	    SWCH_ISEL <= rdmem_op ? 3'b001 : {2'b01,~opon_data};
	    SWCH_OSEL <= rdmem_op ? {1'b0,opon_data,~opon_data} : 3'b100;
	  end // if (trans_activate &&...

	if (((MCU_REQUEST_ALIGN[0] && MCU_GRANT_ALIGN[0]) ||
	     (MCU_REQUEST_ALIGN[1] && MCU_GRANT_ALIGN[1])) &&
	    trans_active)
	  issue_op[0] <= issue_op_new;
	// once more, supposed to be out of the if block
	issue_op[1] <= issue_op[0];

	blck_working_prev <= BLCK_WORKING;
	if (blck_working_prev && !BLCK_WORKING)
	  begin
	    MCU_REQUEST_ALIGN <= 0;
	    trans_active <= 0;
	    RST_MVBLCK <= 2'h0;
	    trans_ends <= 1;
	  end
	else
	  trans_ends <= 0;

        if (trans_ends)
	  begin
	    case (BLCK_SECTION)
	      2'h0: EN_STB_0 <= EN_STB_0_pre;
	      2'h1: EN_STB_1 <= EN_STB_1_pre;
	      2'h2: EN_STB_2 <= EN_STB_2_pre;
	      2'h3: EN_STB_3 <= EN_STB_3_pre;
	    endcase // case (BLCK_SECTION)

	    if (active_trans_thistrans == 1'b0)
	      begin
		input_reg_0[0] <= {8'h0,BLCK_COUNT_SENT,2'h0};
		input_reg_0[1] <= {6'h0,BLCK_IRQ,blck_abort,8'h0};
	      end
	    else
	      begin
		input_reg_1[0] <= {8'h0,BLCK_COUNT_SENT,2'h0};
		input_reg_1[1] <= {6'h0,BLCK_IRQ,blck_abort,8'h0};
	      end
	  end
    end

///////////////////////////////////////////////////////////////

  assign refresh_ctr_mismatch = refresh_req != MCU_REFRESH_STROBE;

endmodule // Gremlin
