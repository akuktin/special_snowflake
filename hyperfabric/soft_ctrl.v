module Gremlin(input CLK,
	       input 		 RST,
		    // ---------------------
	       input 		 READ_CPU,
	       input 		 WRITE_CPU,
	       output reg 	 READ_CPU_ACK,
	       output reg 	 WRITE_CPU_ACK,
	       input [2:0] 	 ADDR_CPU,
	       input [63:0] 	 IN_CPU,
	       output reg [31:0] OUT_CPU,
		    // ---------------------
	       output reg [1:0]  IRQ_DESC,
	       output 		 IRQ,
		    // ---------------------

	       output reg [1:0]  RST_MVBLCK,
	       output reg 	 MCU_REFRESH_STROBE,

		 /* begin BLOCK MOVER */
	       output [11:0] 	 BLCK_START,
	       output [5:0] 	 BLCK_COUNT_REQ,
	       output 		 BLCK_ISSUE,
	       output [1:0] 	 BLCK_SECTION,
	       input [5:0] 	 BLCK_COUNT_SENT,
	       input 		 BLCK_WORKING,
	       input 		 BLCK_IRQ,
	       input 		 BLCK_ABRUPT_STOP,
	       input 		 BLCK_FRDRAM_DEVERR,
	       input [24:0] 	 BLCK_ANCILL,
	         /* begin MCU */
	       output [19:0] 	 MCU_PAGE_ADDR,
	       output [1:0] 	 MCU_REQUEST_ALIGN, // aka DRAM_SEL
	       input [1:0] 	 MCU_GRANT_ALIGN,
		    // ---------------------

	       output reg [23:0] LEN_0,
	       output reg 	 DIR_0,
	       output reg 	 EN_STB_0,
	       output reg [23:0] LEN_1,
	       output reg 	 DIR_1,
	       output reg 	 EN_STB_1,
	       output reg [23:0] LEN_2,
	       output reg 	 DIR_2,
	       output reg 	 EN_STB_2,
	       output reg [23:0] LEN_3,
	       output reg 	 DIR_3,
	       output reg 	 EN_STB_3);

  reg        d_r_en_cpu, d_r_en_cpu_delay,
	     d_w_en_cpu, d_w_en_cpu_delay,
	     READ_CPU_r, WRITE_CPU_r, low_addr_bits_r;
  reg [1:0]  low_addr_bits_w;
  reg [15:0] from_cpu_word;

  wire [15:0] d_w_data, d_r_data;
  wire [7:0]  d_w_addr, d_r_addr;
  wire 	      d_w_en, d_r_en;

  reg [15:0] accumulator, memory_operand, input_reg,
	     instr_f, instr_o, TIME_REG;
  reg [7:0]  ip, index, index_reg;
  reg [1:0]  wrote_3_req, irq_strobe;
  reg 	     add_carry, save_carry, waitkill;

  wire [15:0] accumulator_adder, instr;
  wire [7:0] ip_nxt, d_r_addr_sys, d_w_addr_sys;
  wire 	     d_w_en_sys, d_r_en_sys, cur_carry;

  reg [3:0]  big_carousel;
  reg [7:0]  small_carousel;
  reg [1:0]  refresh_req, refresh_ack, issue_op, wrote_3_ack;
  reg 	     trans_active, blck_working_prev, active_trans_thistrans;

  wire 	     trg_gb_0, trg_gb_1, trg_mb, time_rfrs, trans_activate,
	     refresh_ctr_mismatch, active_trans, small_carousel_reset,
	     blck_abort;

  reg [15:0] output_reg[7:0], input_reg[7:0];

  iceram16 data_mem(.RDATA(d_r_data), // 16 out
		    .RADDR(d_r_addr), // 8 in
		    .RE(d_r_en), // 1 in
		    .RCLKE(1'b1), // 1 in
		    .RCLK(CLK), // 1 in
		    .WDATA(d_w_data), // 16 in
		    .MASK(0), // 16 in
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
    if (! RST)
      begin
	WRITE_CPU_r <= 1; READ_CPU_r <= 1;
	low_addr_bits_w <= 0; low_addr_bits_r <= 0;
	d_w_en_cpu <= 0; d_w_en_cpu_delay <= 0;
	d_r_en_cpu <= 0; d_r_en_cpu_delay <= 0;
	READ_CPU_ACK <= 0; WRITE_CPU_ACK <= 0;
	OUT_CPU <= 0;

	LEN_0 <= 0; DIR_0 <= 0; EN_STB_0 <= 0; EN_STB_0_pre <= 0;
	LEN_1 <= 0; DIR_1 <= 0; EN_STB_1 <= 0; EN_STB_1_pre <= 0;
	LEN_2 <= 0; DIR_2 <= 0; EN_STB_2 <= 0; EN_STB_2_pre <= 0;
	LEN_3 <= 0; DIR_3 <= 0; EN_STB_3 <= 0; EN_STB_3_pre <= 0;
      end
    else
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

	d_w_en_cpu_delay <= (d_w_en_cpu && !d_w_en_sys);
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
		    .WDATA(0), // 16 in
		    .MASK(0), // 16 in
		    .WADDR(0), // 8 in
		    .WE(0), // 1 in
		    .WCLKE(0), // 1 in
		    .WCLK(CLK)); // 1 in

  initial
    begin
      output_reg[0] <= 0; output_reg[1] <= 0;
      output_reg[2] <= 0; output_reg[3] <= 0;
      output_reg[4] <= 0; output_reg[5] <= 0;
      output_reg[6] <= 0; output_reg[7] <= 0;
    end


  assign ip_nxt = (instr_o[15] && (accumulator != 16'd0)) ?
		  instr_o[7:0] : ip +1;

  assign d_r_addr_sys = instr[12] ? index : instr[7:0];
  assign d_w_addr_sys = instr_o[12] ? index_reg : instr_o[7:0];
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

  always @(posedge CLK)
    if (!RST)
      begin
	accumulator <= 0; memory_operand <= 0; add_carry <= 0;
	save_carry <= 0; ip <= 0; index_reg <= 0;
	instr_f <= 0; instr_o <= 0; wrote_3_req <= 0;
	irq_strobe <= 0; IRQ_DESC <= 0; waitkill <= 0;
      end
    else
      begin
	irq_strobe[1] <= irq_strobe[0];

	begin
	  ip <= ip_nxt;
	  case (instr_f[14:13])
	    2'h0: memory_operand <= d_r_data;
	    2'h1: memory_operand <= ~d_r_data;
	    2'h2: memory_operand <= 0; // together with 0xe, fakes a NOP
	    2'h3: memory_operand <= 16'hffff;
	  endcase // case (instr_f[14:13])

	  if (instr_o[11:8] != 4'hc)
	    index_reg <= index;
	  if (instr_o[11:8] != 4'h8)
	    begin
	      waitkill <= 0;
	      if (! waitkill)
		instr_f <= instr;
	      instr_o <= instr_f;
	    end
	  else
	    begin
	      waitkill <= 1;
	      instr_f <= {1'b0,2'h3,1'b0,4'hd,8'h0}; // and 0xffff;
	      if (accumulator == 0)
		// accumulator will be nonzero by the time the instruction
		// hits execution

		// cmp/and 0 {instr_o[7:0]};
		instr_o <= {1'b1,2'h2,1'b0,4'hd,instr_o[7:0]};
	    end

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

	    4'h4: accumulator <= input_reg[{1'b0,instr_o[14:13]}];
	    4'h5: accumulator <= input_reg[{1'b1,instr_o[14:13]}];
//	    4'h6 // store
	    4'h7: begin // store w/ clear
	      accumulator <= 0;
	    end

	    4'h8: begin // wait
	      accumulator <= accumulator -1;
	    end
	    4'h9: begin
	      irq_strobe[0] <= !irq_strobe[0]; // provisional
	      IRQ_DESC <= accumulator[12:11]; // maybe
	      accumulator <= 0; // probably a good idea
	    end
	    // fucking load instrunction, bitch!
	    4'ha: accumulator <= memory_operand;
	    4'hb: begin
	      output_reg[instr_o[2:0]] <= accumulator;
	      if (instr_o[13] && (accumulator[13:2] != 0)) // provisional
		begin
		  wrote_3_req <= wrote_3_req +1;

		  accumulator <= 0; // maybe overly accomodative with this
		end
	    end

	    4'hc: begin
	      index_reg <= accumulator[7:0];
	      accumulator <= 0;
	    end
	    4'hd: accumulator <= accumulator & memory_operand;
	    4'he: accumulator <= accumulator | memory_operand;
	    4'hf: accumulator <= accumulator ^ memory_operand;
	  endcase // case (instr_o[11:8])
	end
      end // else: !if(!RST)

  assign small_carousel_reset = small_carousel == 8'hbf;
  assign BLCK_ISSUE = issue_op[0] ^ issue_op[1];
  assign active_trans = (trg_gb_0 || trg_gb_1);

  assign blck_abort = BLCK_ABRUPT_STOP || BLCK_FRDRAM_DEVERR;

  initial
    begin
      input_reg[0] <= 0; input_reg[1] <= 0;
      input_reg[2] <= 0; input_reg[3] <= 0;
      input_reg[4] <= 0; input_reg[5] <= 0;
      input_reg[6] <= 0; input_reg[7] <= 0;
    end

  always @(posedge CLK)
    if (!RST)
      begin
	small_carousel <= 8'hc1; // Out of bounds. // FIXME!!
	big_carousel <= 4'h3; refresh_req <= 0; refresh_ack <= 0;
	MCU_REFRESH_STROBE <= 0; wrote_3_ack <= 0; trans_active <= 0;
	RST_MVBLCK <= 0; MCU_REQUEST_ALIGN <= 0; MCU_PAGE_ADDR <= 0;
	blck_working_prev <= 0; issue_op <= 0;
	BLCK_COUNT_REQ <= 0; BLCK_SECTION <= 0; BLCK_START <= 0;
	active_trans_thistrans <= 0;
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

	if (trans_activate &&
	    (trg_gb_0 || trg_gb_1 || (time_mb && small_carousel != 0)))
	  begin
	    active_trans_thistrans <= active_trans;
	    trans_active <= 1;
	    wrote_3_ack <= wrote_3_ack +1;

	    // provisional
	    BLCK_START <= output_reg[{active_trans,2'h0}][11:0];
	    // something
	    BLCK_SECTION <= output_reg[{active_trans,2'h2}][1:0];
	    // maybe
	    BLCK_COUNT_REQ <= output_reg[{active_trans,2'h2}][13:2];
	    // provisional
	    MCU_PAGE_ADDR <= {output_reg[{active_trans,2'h1}],
			      output_reg[{active_trans,2'h0}][15:12]};
	    // actually supposed to be the top usable bit in the address
	    MCU_REQUEST_ALIGN <= {output_reg[{active_trans,2'h2}][15],
				  ~output_reg[{active_trans,2'h2}][15]};
	    // perhaps
	    RST_MVBLCK <= {output_reg[{active_trans,2'h2}][14],
			   ~output_reg[{active_trans,2'h2}][14]};
	  end // if (trans_activate &&...

	if (((MCU_REQUEST_ALIGN[0] && MCU_GRANT_ALIGN[0]) ||
	     (MCU_REQUEST_ALIGN[1] && MCU_GRANT_ALIGN[1])) &&
	    trans_active)
	  issue_op[0] <= !issue_op[0];
	// once more, supposed to be out of the if block
	issue_op[1] <= issue_op[0];

	blck_working_prev <= BLCK_WORKING;
	if (blck_working_prev && !BLCK_WORKING)
	  begin
	    MCU_REQUEST_ALIGN <= 0;
	    trans_active <= 0;
	    RST_MVBLCK <= 2'h0;

	    case (BLCK_SECTION)
	      2'h0: EN_STB_0 <= EN_STB_0_pre;
	      2'h1: EN_STB_1 <= EN_STB_1_pre;
	      2'h2: EN_STB_2 <= EN_STB_2_pre;
	      2'h3: EN_STB_3 <= EN_STB_3_pre;
	    endcase // case (BLCK_SECTION)

	    if (active_trans_thistrans == 1'b0)
	      begin
		input_reg[0] <= {8'h0,BLCK_COUNT_SENT,2'h0};
		input_reg[1] <= {BLCK_IRQ,blck_abort,14'h0};
		input_reg[2] <= 0;
		input_reg[3] <= 0;
	      end
	    else
	      begin
		input_reg[4] <= {8'h0,BLCK_COUNT_SENT,2'h0};
		input_reg[5] <= {BLCK_IRQ,blck_abort,14'h0};
		input_reg[6] <= 0;
		input_reg[7] <= 0;
	      end
	  end

        if (trg_gb_0 && time_rfrs)
          refresh_req <= refresh_req +1;

	if (refresh_ctr_mismatch &&
	    ! trans_active)
	  begin
	    refresh_ack <= refresh_ack +1;
	    MCU_REFRESH_STROBE <= !MCU_REFRESH_STROBE;
	  end
      end

///////////////////////////////////////////////////////////////

  assign refresh_ctr_mismatch = refresh_req != refresh_ack;
  assign trans_activate = (wrote_3_req != wrote_3_ack) && (! trans_active);

  // Up to a maximum of 2 simultaneous 1 Gbps transactions.
  // Up to a maximum of 6 simultaneous 12.5 Mbps transactions.

  assign trg_gb_0 = small_carousel == 8'h00;
  assign trg_gb_1 = small_carousel == 8'h60;
//  assign trg_mb   = small_carousel == 8'h02;

  assign time_mb = (big_carousel == 4'h4) || (big_carousel == 4'h6) ||
		   (big_carousel == 4'h8) || (big_carousel == 4'ha) ||
		   (big_carousel == 4'hc) || (big_carousel == 4'he);

  /* Having mb and rfrs on the same big_carousel cycle is simply not
   * supported, at least on the gb_0 side of the cycle. */
  assign time_rfrs = (big_carousel == 4'h1) || (big_carousel == 4'h3) ||
		     (big_carousel == 4'h5) || (big_carousel == 4'h7) ||
		     (big_carousel == 4'h9) || (big_carousel == 4'hb) ||
		     (big_carousel == 4'hd) || (big_carousel == 4'hf);

///////////////////////////////////////////////////////////////


endmodule // Gremlin
