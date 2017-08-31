module hyper____mem(input CLK,
		    input 	      RST,
		    // ---------------------
		    input 	      READ_CPU,
		    input 	      WRITE_CPU,
		    output 	      READ_CPU_ACK,
		    output reg 	      WRITE_CPU_ACK,
		    input [2:0]       ADDR_CPU,
		    input [63:0]      IN_CPU,
		    output reg [31:0] OUT_CPU,
		    // ---------------------
		    input 	      foo);

  iceram16 mem(.RDATA(to_cpu_word), // 16 out
	       .RADDR(to_cpu_addr), // 8 in
	       .RE(reading), // 1 in
	       .RCLKE(1'b1), // 1 in
	       .RCLK(CLK), // 1 in
	       .WDATA(from_cpu_word), // 16 in
	       .MASK(0), // 16 in
	       .WADDR(from_cpu_addr), // 8 in
	       .WE(writing), // 1 in
	       .WCLKE(1'b1), // 1 in
	       .WCLK(CLK)); // 1 in

  assign from_cpu_addr = {3'h0,ADDR_CPU,low_addr_bits_w};
  assign to_cpu_addr = {3'h0,ADDR_CPU,1'b0,low_addr_bits_r};

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
	WRITE_CPU_r <= 1;
	writing <= 0; low_addr_bits_w <= 0;
      end
    else
      begin
	WRITE_CPU_r <= WRITE_CPU;
	if (WRITE_CPU && !WRITE_CPU_r)
	  begin
	    writing <= 1;
	    low_addr_bits_w <= 0;

	    WRITE_CPU_ACK <= 0;
	  end
	else
	  begin
	    if (writing)
	      low_addr_bits_w <= low_addr_bits_w +1;

	    if (low_addr_bits_w == 2'b11)
	      begin
		writing <= 0;
		WRITE_CPU_ACK <= 1;
	      end
	    else
	      WRITE_CPU_ACK <= 0;
	  end // else: !if(WRITE_CPU && !WRITE_CPU_r)

	READ_CPU_r <= READ_CPU;
	if (READ_CPU && !READ_CPU_r)
	  begin
	    reading <= 1;
	    low_addr_bits_r <= 0;
	    READ_CPU_ACK <= 0;
	  end
	else
	  begin
	    if (reading)
	      low_addr_bits_r <= low_addr_bits_r +1;

	    if (low_addr_bits_r == 1'b1)
	      begin
		reading <= 0;
		READ_CPU_ACK <= 1;
	      end
	    else
	      READ_CPU_ACK <= 0;

	    if (reading)
	      begin
		if (low_addr_bits_r == 1'b0)
		  OUT_CPU[31:16] <= to_cpu_word;
		else
		  OUT_CPU[15:0] <= to_cpu_word;
	      end
	  end
      end

endmodule // hyper____mem
