module lolsab(input CLK,
	      input 		RST,
	      input 		READ,
	      input 		WRITE,
	      input [1:0] 	READ_FIFO,
	      input [1:0] 	WRITE_FIFO,
	      input [31:0] 	IN_0,
	      input 		INT_IN_0,
	      input 		CAREOF_INT_0,
	      input [2:0] 	ANCILL_IN_0,
	      output reg [31:0] OUT,
	      output reg 	EMPTY_0,
	      output reg 	STOP_0,
	      output reg 	INT_OUT_0,
	      output reg [2:0] 	ANCILL_OUT_0);
  reg               full_0;
  reg [5:0]         len_0;
  reg [5:0]         write_addr_0;
  reg [5:0]         read_addr_0;
  reg               re_prev;

  wire                      read_0;
  wire                      write_0;
  wire                      do_read_0;
  wire                      do_write_0;

  reg               become_empty_0;
  reg               become_full_0;
  reg [5:0]         become_len_0;

  reg [1:0] 	    intbuff_raddr_0, intbuff_raddr_trail_0, intbuff_waddr_0;
  wire 		    intbuff_int_det_0, intbuff_int_0,
		    intbuff_empty_0, intbuff_full_0;
  reg [5:0] 	    intbuff_0[3:0];
  reg [2:0] 	    ancbuff_0[3:0];

  wire [31:0] 	    out_mem;
  reg [31:0] 	    in_mem;
  reg [7:0]         write_addr, read_addr;
  reg               we, re;

  assign read_0 = READ && (READ_FIFO == 2'h0);
  assign write_0 = WRITE && (WRITE_FIFO == 2'h0);
  assign do_write_0 = full_0 ? 0 : write_0;
  assign do_read_0 = STOP_0 ? 0 : read_0;

  always @(len_0 or do_read_0 or do_write_0 or full_0 or EMPTY_0)
    case ({len_0,do_read_0,do_write_0})
      {6'h3f,2'b10}: begin become_full_0 <= 0; become_empty_0 <= 0; end
      {6'h3e,2'b01}: begin become_full_0 <= 1; become_empty_0 <= 0; end
      {6'h01,2'b10}: begin become_full_0 <= 0; become_empty_0 <= 1; end
      {6'h00,2'b01}: begin become_full_0 <= 0; become_empty_0 <= 0; end
      default: begin become_full_0 <= full_0; become_empty_0 <= EMPTY_0; end
    endcase // case ({len_0,do_read_0,do_write_0})

  always @(do_read_0 or do_write_0 or len_0)
    case ({do_read_0,do_write_0})
      2'b10: become_len_0 <= len_0 -1;
      2'b01: become_len_0 <= len_0 +1;
      default: become_len_0 <= len_0;
    endcase // case ({do_read_0,do_write_0})

  always @(WRITE_FIFO or
          IN_0 or
          write_addr_0 or
          do_write_0)
    case (WRITE_FIFO)
      2'b00: begin
       in_mem <= IN_0;
       write_addr <= {2'b00,write_addr_0};
       we <= do_write_0;
      end
      default: begin
	in_mem <= 0;
	write_addr <= 0;
	we <= 0;
      end
    endcase // case (WRITE_FIFO)

  always @(READ_FIFO or
          read_addr_0 or
          do_read_0)
    case (READ_FIFO)
      2'b00: begin
       read_addr <= {2'b00,read_addr_0};
       re <= do_read_0;
      end
      default: begin
	read_addr <= 0;
	re <= 0;
      end
    endcase // case (READ_FIFO)

  iceram32 lsab_sram(.RDATA(out_mem),
                     .RADDR(read_addr),
                     .RE(re),
                     .RCLKE(1'b1),
                     .RCLK(CLK),
                     .WDATA(in_mem),
                     .MASK(0),
                     .WADDR(write_addr),
                     .WE(we),
                     .WCLKE(1'b1),
                     .WCLK(CLK));

  // With the carry chain and performing the ENTIRE XOR in a single gate,
  // both of below two fit in two gates.
  assign intbuff_int_det_0 = ((intbuff_0[intbuff_raddr_0] ^
			       read_addr_0) == 0) &&
			     do_read_0 &&
			     !intbuff_empty_0;
  assign intbuff_int_0 = intbuff_int_det_0 && CAREOF_INT_0;
  assign intbuff_empty_0 = intbuff_raddr_0 == intbuff_waddr_0;
  assign intbuff_full_0 = intbuff_raddr_trail_0 == intbuff_waddr_0;

  always @(posedge CLK)
    if (!RST)
      begin
       EMPTY_0 <= 1;
       full_0 <= 0;
       len_0 <= 0;
       write_addr_0 <= 0;
       read_addr_0 <= 0;
       re_prev <= 0; OUT <= 0;
	STOP_0 <= 1;
	INT_OUT_0 <= 0;
	ANCILL_OUT_0 <= 0;
	intbuff_raddr_0 <= 1; intbuff_raddr_trail_0 <= 0;
	intbuff_waddr_0 <= 1;
      end
    else
      begin
	STOP_0 <= become_empty_0 || intbuff_int_0; // three gates deep
	INT_OUT_0 <= intbuff_int_0;
	EMPTY_0 <= become_empty_0;
	ANCILL_OUT_0 <= ancbuff_0[intbuff_raddr_0];
	full_0 <= become_full_0;
	len_0 <= become_len_0;

	if (do_write_0)
          write_addr_0 <= write_addr_0 + 1;
	if (do_read_0)
          read_addr_0 <= read_addr_0 + 1;

	re_prev <= re;
	if (re_prev)
          OUT <= out_mem;

	if (intbuff_int_det_0)
	  begin
	    intbuff_raddr_0 <= intbuff_raddr_0 +1;
	    intbuff_raddr_trail_0 <= intbuff_raddr_trail_0 +1;
	  end
	if (INT_IN_0 && do_write_0 && (!intbuff_full_0))
	  begin
	    intbuff_0[intbuff_waddr_0] <= write_addr_0;
	    ancbuff_0[intbuff_waddr_0] <= ANCILL_IN_0;
	    intbuff_waddr_0 <= intbuff_waddr_0 +1;
	  end
      end

endmodule // lolsab
