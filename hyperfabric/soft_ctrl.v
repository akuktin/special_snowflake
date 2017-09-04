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

	       output reg [15:0] output_0,
	       output reg [15:0] output_1,
	       output reg [15:0] output_2,
	       input [15:0] 	 input_0,
	       input [15:0] 	 input_1,
	       input [15:0] 	 input_2

/*		 / * begin BLOCK MOVER * /
		output [11:0] 	  BLCK_START,
		output [5:0] 	  BLCK_COUNT_REQ,
		output 		  BLCK_ISSUE,
		output [1:0] 	  BLCK_SECTION,
		input [5:0] 	  BLCK_COUNT_SENT,
		input 		  BLCK_WORKING,
		input 		  BLCK_IRQ,
		input 		  BLCK_ABRUPT_STOP,
		input 		  BLCK_FRDRAM_DEVERR,
		input [24:0] 	  BLCK_ANCILL,
		 / * begin MCU * /
		output [19:0] 	  MCU_PAGE_ADDR,
		output [1:0] 	  MCU_REQUEST_ALIGN, // aka DRAM_SEL
		input [1:0] 	  MCU_GRANT_ALIGN*/);

  reg        d_r_en_cpu, d_r_en_cpu_delay,
	     d_w_en_cpu, d_w_en_cpu_delay,
	     READ_CPU_r, WRITE_CPU_r, low_addr_bits_r;
  reg [1:0]  low_addr_bits_w;
  reg [15:0] from_cpu_word;

  wire [15:0] d_w_data;
  wire [7:0]  d_w_addr, d_r_addr;
  wire 	      d_w_en, d_r_en;

  reg [15:0] accumulator, memory_operand, input_reg,
	     instr_f, instr_o, TIME_REG;
  reg [7:0]  ip, index;
  reg 	     add_carry, save_carry;

  wire [15:0] accumulator_adder, instr;
  wire [7:0] ip_nxt, d_r_addr_sys, d_w_addr_sys;
  wire 	     sys_cpu_en, d_w_en_sys, d_r_en_sys, cur_carry;

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

  assign d_r_addr = d_r_en_cpu ? {3'h0,ADDR_CPU,1'b0,low_addr_bits_r} :
		                 d_r_addr_sys;
  assign d_w_addr = d_w_en_cpu ? {3'h0,ADDR_CPU,low_addr_bits_w} :
		                 d_w_addr_sys;

  assign d_r_en = d_r_en_cpu || d_r_en_sys;
  assign d_w_en = d_w_en_cpu || d_w_en_sys;
  assign d_w_data = d_w_en_cpu ? from_cpu_word : accumulator;

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
      end
    else
      begin
	WRITE_CPU_r <= WRITE_CPU;
	if (WRITE_CPU && !WRITE_CPU_r)
	  begin
	    d_w_en_cpu <= 1;
	    low_addr_bits_w <= 0;

	    WRITE_CPU_ACK <= 0;
	  end
	else
	  begin
	    if (d_w_en_cpu)
	      low_addr_bits_w <= low_addr_bits_w +1;

	    if (low_addr_bits_w == 2'b11)
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
	    if (d_r_en_cpu)
	      low_addr_bits_r <= low_addr_bits_r +1;

	    if (low_addr_bits_r == 1'b1)
	      d_r_en_cpu <= 0;

	    if (d_r_en_cpu_delay && (low_addr_bits_r == 1'b0))
	      READ_CPU_ACK <= 1;
	    else
	      READ_CPU_ACK <= 0;
	  end // else: !if(READ_CPU && !READ_CPU_r)

	d_w_en_cpu_delay <= d_w_en_cpu;
	d_r_en_cpu_delay <= d_r_en_cpu;
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
		    .RE(sys_cpu_en), // 1 in // !!! very important !!!
		    .RCLKE(1'b1), // 1 in
		    .RCLK(CLK), // 1 in
		    .WDATA(0), // 16 in
		    .MASK(0), // 16 in
		    .WADDR(0), // 8 in
		    .WE(0), // 1 in
		    .WCLKE(0), // 1 in
		    .WCLK(CLK)); // 1 in

  assign ip_nxt = (instr_o[15] && (accumulator != 16'd0)) ?
		  instr_o[7:0] : ip +1;
  assign sys_cpu_en = d_r_en_sys &&
		      (! (d_w_en_cpu_delay || d_r_en_cpu_delay));

  assign d_r_addr_sys = instr[12] ? index : instr[7:0];
  assign d_w_addr_sys = instr_o[12] ? index : instr_o[7:0];
  assign d_w_en_sys   = instr_o[11:8] == 4'h8; // store
  assign d_r_en_sys   = !instr[14];

  assign {cur_carry,accumulator_adder} = accumulator + memory_operand +
					 add_carry;

  always @(posedge CLK)
    if (!RST)
      TIME_REG <= 0;
    else
      TIME_REG <= TIME_REG -1;

  always @(posedge CLK)
    if (!RST)
      begin
	accumulator <= 0; memory_operand <= 0; add_carry <= 0;
	save_carry <= 0; ip <= 0; input_reg <= 0; index <= 0;
	output_0 <= 0; output_0 <= 1; output_2 <= 0;
	instr_f <= 0; instr_o <= 0;
      end
    else
      if (sys_cpu_en)
	begin
	  ip <= ip_nxt;
	  case (instr_f[14:13])
	    2'h0: memory_operand <= d_r_data;
	    2'h1: memory_operand <= ~d_r_data;
	    2'h2: memory_operand <= 0; // together with 0xe, fakes a NOP
	    2'h3: memory_operand <= 16'hffff;
	  endcase // case (instr_f[14:13])

	  if (instr_f[12])
	    index <= index +instr_f[7:0];

	  instr_f <= instr;
	  instr_o <= instr_f;
	  case (instr_f[11:8])
	    4'h0: add_carry <= 0;
	    4'h1: add_carry <= 1;
	    4'h2: add_carry <= save_carry;
	    4'h3: add_carry <= cur_carry;

	    4'h5: input_reg <= input_0;
	    4'h6: input_reg <= input_1;
	    4'h7: input_reg <= input_2;
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

	    4'h4: accumulator <= TIME_REG;
	    4'h5: accumulator <= input_reg;
	    4'h6: accumulator <= input_reg;
	    4'h7: accumulator <= input_reg;

//	    4'h8 // store
	    4'h9: output_0 <= accumulator;
	    4'ha: output_1 <= accumulator;
	    4'hb: output_2 <= accumulator;

	    4'hc: index <= accumulator[7:0];
	    4'hd: accumulator <= accumulator & memory_operand;
	    4'he: accumulator <= accumulator | memory_operand;
	    4'hf: accumulator <= accumulator ^ memory_operand;
	  endcase // case (instr_o[11:8])
	end // if (sys_cpu_en)

endmodule // Gremlin
