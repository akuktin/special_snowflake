module lsab_cr(input CLK,
              input 		RST,
              input 		READ,
              input 		WRITE0,
              input 		WRITE1,
              input 		WRITE2,
              input 		WRITE3,
              input [1:0] 	READ_FIFO,
              input [1:0] 	WRITE_FIFO,
              input [31:0] 	IN_0,
              input [31:0] 	IN_1,
              input [31:0] 	IN_2,
              input [31:0] 	IN_3,
	      input 		INT_IN_0,
	      input 		INT_IN_1,
	      input 		INT_IN_2,
	      input 		INT_IN_3,
	      input 		CAREOF_INT_0,
	      input 		CAREOF_INT_1,
	      input 		CAREOF_INT_2,
	      input 		CAREOF_INT_3,
	      input [24:0] 	ANCILL_IN_0,
	      input [24:0] 	ANCILL_IN_1,
	      input [24:0] 	ANCILL_IN_2,
	      input [24:0] 	ANCILL_IN_3,
              output reg [31:0] OUT,
	      output 		EMPTY_0,
	      output 		EMPTY_1,
	      output 		EMPTY_2,
	      output 		EMPTY_3,
	      output 		STOP_0,
	      output 		STOP_1,
	      output 		STOP_2,
	      output 		STOP_3,
	      output reg 	INT_OUT_0,
	      output reg 	INT_OUT_1,
	      output reg 	INT_OUT_2,
	      output reg 	INT_OUT_3,
	      output reg [24:0] ANCILL_OUT_0,
	      output reg [24:0] ANCILL_OUT_1,
	      output reg [24:0] ANCILL_OUT_2,
	      output reg [24:0] ANCILL_OUT_3);
  reg 				EMPTY_0 = 1'b1, EMPTY_1 = 1'b1,
				EMPTY_2 = 1'b1, EMPTY_3 = 1'b1,
				STOP_0 = 1'b1, STOP_1 = 1'b1,
				STOP_2 = 1'b1, STOP_3 = 1'b1;


  reg               full_0 = 1'b0, full_1 = 1'b0,
		    full_2 = 1'b0, full_3 = 1'b0;
  reg [5:0]         len_0 = 6'h0, len_1 = 6'h0,
		    len_2 = 6'h0, len_3 = 6'h0;
  reg [5:0]         write_addr_0 = 6'h0, write_addr_1 = 6'h0,
                    write_addr_2 = 6'h0, write_addr_3 = 6'h0;
  reg [5:0]         read_addr_0 = 6'h0, read_addr_1 = 6'h0,
                    read_addr_2 = 6'h0, read_addr_3 = 6'h0;
  reg               re_prev;

  wire                      read_0, read_1, read_2, read_3;
  wire                      write_0, write_1, write_2, write_3;
  wire                      do_read_0, do_read_1, do_read_2, do_read_3;
  wire                      do_write_0, do_write_1, do_write_2, do_write_3;

  reg               become_empty_0, become_empty_1,
                    become_empty_2, become_empty_3;
  reg               become_full_0, become_full_1,
                    become_full_2, become_full_3;
  reg [5:0]         become_len_0, become_len_1,
                    become_len_2, become_len_3;

  reg [1:0] 	    intbuff_raddr_0 = 2'h1, intbuff_raddr_trail_0 = 2'h0,
		    intbuff_waddr_0 = 2'h1,
		    intbuff_raddr_1 = 2'h1, intbuff_raddr_trail_1 = 2'h0,
		    intbuff_waddr_1 = 2'h1,
		    intbuff_raddr_2 = 2'h1, intbuff_raddr_trail_2 = 2'h0,
		    intbuff_waddr_2 = 2'h1,
		    intbuff_raddr_3 = 2'h1, intbuff_raddr_trail_3 = 2'h0,
		    intbuff_waddr_3 = 2'h1;
  wire 		    intbuff_int_det_0, intbuff_int_0,
		    intbuff_empty_0, intbuff_full_0,
		    intbuff_int_det_1, intbuff_int_1,
		    intbuff_empty_1, intbuff_full_1,
		    intbuff_int_det_2, intbuff_int_2,
		    intbuff_empty_2, intbuff_full_2,
		    intbuff_int_det_3, intbuff_int_3,
		    intbuff_empty_3, intbuff_full_3;
  reg [5:0] 	    intbuff_0[3:0], intbuff_1[3:0], intbuff_2[3:0],
		    intbuff_3[3:0];
  reg [24:0] 	    ancbuff_0[3:0], ancbuff_1[3:0], ancbuff_2[3:0],
		    ancbuff_3[3:0];

  wire [31:0] 	    out_mem;
  reg [31:0] 	    in_mem;
  reg [7:0]         write_addr, read_addr;
  reg               we, re;

  assign read_0 = READ && (READ_FIFO == 2'h0);
  assign read_1 = READ && (READ_FIFO == 2'h1);
  assign read_2 = READ && (READ_FIFO == 2'h2);
  assign read_3 = READ && (READ_FIFO == 2'h3);

  assign write_0 = WRITE0 && (WRITE_FIFO == 2'h0);
  assign write_1 = WRITE1 && (WRITE_FIFO == 2'h1);
  assign write_2 = WRITE2 && (WRITE_FIFO == 2'h2);
  assign write_3 = WRITE3 && (WRITE_FIFO == 2'h3);

  assign do_write_0 = full_0 ? 0 : write_0;
  assign do_write_1 = full_1 ? 0 : write_1;
  assign do_write_2 = full_2 ? 0 : write_2;
  assign do_write_3 = full_3 ? 0 : write_3;

  assign do_read_0 = STOP_0 ? 0 : read_0;
  assign do_read_1 = STOP_1 ? 0 : read_1;
  assign do_read_2 = STOP_2 ? 0 : read_2;
  assign do_read_3 = STOP_3 ? 0 : read_3;

  always @(len_0 or do_read_0 or do_write_0 or full_0 or EMPTY_0)
    case ({len_0,do_read_0,do_write_0})
      {6'h3f,2'b10}: begin become_full_0 <= 0; become_empty_0 <= 0; end
      {6'h3e,2'b01}: begin become_full_0 <= 1; become_empty_0 <= 0; end
      {6'h01,2'b10}: begin become_full_0 <= 0; become_empty_0 <= 1; end
      {6'h00,2'b01}: begin become_full_0 <= 0; become_empty_0 <= 0; end
      default: begin become_full_0 <= full_0; become_empty_0 <= EMPTY_0; end
    endcase // case ({len_0,do_read_0,do_write_0})

  always @(len_1 or do_read_1 or do_write_1 or full_1 or EMPTY_1)
    case ({len_1,do_read_1,do_write_1})
      {6'h3f,2'b10}: begin become_full_1 <= 0; become_empty_1 <= 0; end
      {6'h3e,2'b01}: begin become_full_1 <= 1; become_empty_1 <= 0; end
      {6'h01,2'b10}: begin become_full_1 <= 0; become_empty_1 <= 1; end
      {6'h00,2'b01}: begin become_full_1 <= 0; become_empty_1 <= 0; end
      default: begin become_full_1 <= full_1; become_empty_1 <= EMPTY_1; end
    endcase // case ({len_1,do_read_1,do_write_1})

  always @(len_2 or do_read_2 or do_write_2 or full_2 or EMPTY_2)
    case ({len_2,do_read_2,do_write_2})
      {6'h3f,2'b10}: begin become_full_2 <= 0; become_empty_2 <= 0; end
      {6'h3e,2'b01}: begin become_full_2 <= 1; become_empty_2 <= 0; end
      {6'h01,2'b10}: begin become_full_2 <= 0; become_empty_2 <= 1; end
      {6'h00,2'b01}: begin become_full_2 <= 0; become_empty_2 <= 0; end
      default: begin become_full_2 <= full_2; become_empty_2 <= EMPTY_2; end
    endcase // case ({len_2,do_read_2,do_write_2})

  always @(len_3 or do_read_3 or do_write_3 or full_3 or EMPTY_3)
    case ({len_3,do_read_3,do_write_3})
      {6'h3f,2'b10}: begin become_full_3 <= 0; become_empty_3 <= 0; end
      {6'h3e,2'b01}: begin become_full_3 <= 1; become_empty_3 <= 0; end
      {6'h01,2'b10}: begin become_full_3 <= 0; become_empty_3 <= 1; end
      {6'h00,2'b01}: begin become_full_3 <= 0; become_empty_3 <= 0; end
      default: begin become_full_3 <= full_3; become_empty_3 <= EMPTY_3; end
    endcase // case ({len_3,do_read_3,do_write_3})

  always @(do_read_0 or do_write_0 or len_0)
    case ({do_read_0,do_write_0})
      2'b10: become_len_0 <= len_0 -1;
      2'b01: become_len_0 <= len_0 +1;
      default: become_len_0 <= len_0;
    endcase // case ({do_read_0,do_write_0})

  always @(do_read_1 or do_write_1 or len_1)
    case ({do_read_1,do_write_1})
      2'b10: become_len_1 <= len_1 -1;
      2'b01: become_len_1 <= len_1 +1;
      default: become_len_1 <= len_1;
    endcase // case ({do_read_1,do_write_1})

  always @(do_read_2 or do_write_2 or len_2)
    case ({do_read_2,do_write_2})
      2'b10: become_len_2 <= len_2 -1;
      2'b01: become_len_2 <= len_2 +1;
      default: become_len_2 <= len_2;
    endcase // case ({do_read_2,do_write_2})

  always @(do_read_3 or do_write_3 or len_3)
    case ({do_read_3,do_write_3})
      2'b10: become_len_3 <= len_3 -1;
      2'b01: become_len_3 <= len_3 +1;
      default: become_len_3 <= len_3;
    endcase // case ({do_read_3,do_write_3})

  always @(WRITE_FIFO or
          IN_0 or IN_1 or IN_2 or IN_3 or
          write_addr_0 or write_addr_1 or write_addr_2 or write_addr_3 or
          do_write_0 or do_write_1 or do_write_2 or do_write_3)
    case (WRITE_FIFO)
      2'b00: begin
       in_mem <= IN_0;
       write_addr <= {2'b00,write_addr_0};
       we <= do_write_0;
      end
      2'b01: begin
       in_mem <= IN_1;
       write_addr <= {2'b01,write_addr_1};
       we <= do_write_1;
      end
      2'b10: begin
       in_mem <= IN_2;
       write_addr <= {2'b10,write_addr_2};
       we <= do_write_2;
      end
      2'b11: begin
       in_mem <= IN_3;
       write_addr <= {2'b11,write_addr_3};
       we <= do_write_3;
      end
    endcase // case (WRITE_FIFO)

  always @(READ_FIFO or
          read_addr_0 or read_addr_1 or read_addr_2 or read_addr_3 or
          do_read_0 or do_read_1 or do_read_2 or do_read_3)
    case (READ_FIFO)
      2'b00: begin
       read_addr <= {2'b00,read_addr_0};
       re <= do_read_0;
      end
      2'b01: begin
       read_addr <= {2'b01,read_addr_1};
       re <= do_read_1;
      end
      2'b10: begin
       read_addr <= {2'b10,read_addr_2};
       re <= do_read_2;
      end
      2'b11: begin
       read_addr <= {2'b11,read_addr_3};
       re <= do_read_3;
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

  // With the carry chain and performing the ENTIRE XOR in a single gate,
  // both of below two fit in two gates.
  assign intbuff_int_det_1 = ((intbuff_1[intbuff_raddr_1] ^
			       read_addr_1) == 0) &&
			     do_read_1 &&
			     !intbuff_empty_1;
  assign intbuff_int_1 = intbuff_int_det_1 && CAREOF_INT_1;
  assign intbuff_empty_1 = intbuff_raddr_1 == intbuff_waddr_1;
  assign intbuff_full_1 = intbuff_raddr_trail_1 == intbuff_waddr_1;

  // With the carry chain and performing the ENTIRE XOR in a single gate,
  // both of below two fit in two gates.
  assign intbuff_int_det_2 = ((intbuff_2[intbuff_raddr_2] ^
			       read_addr_2) == 0) &&
			     do_read_2 &&
			     !intbuff_empty_2;
  assign intbuff_int_2 = intbuff_int_det_2 && CAREOF_INT_2;
  assign intbuff_empty_2 = intbuff_raddr_2 == intbuff_waddr_2;
  assign intbuff_full_2 = intbuff_raddr_trail_2 == intbuff_waddr_2;

  // With the carry chain and performing the ENTIRE XOR in a single gate,
  // both of below two fit in two gates.
  assign intbuff_int_det_3 = ((intbuff_3[intbuff_raddr_3] ^
			       read_addr_3) == 0) &&
			     do_read_3 &&
			     !intbuff_empty_3;
  assign intbuff_int_3 = intbuff_int_det_3 && CAREOF_INT_3;
  assign intbuff_empty_3 = intbuff_raddr_3 == intbuff_waddr_3;
  assign intbuff_full_3 = intbuff_raddr_trail_3 == intbuff_waddr_3;

  always @(posedge CLK)
    if (RST)
      begin
	STOP_0 <= become_empty_0 || intbuff_int_0; // three gates deep
       INT_OUT_0 <= intbuff_int_0;
       EMPTY_0 <= become_empty_0;
	ANCILL_OUT_0 <= ancbuff_0[intbuff_raddr_0];
       full_0 <= become_full_0;
	STOP_1 <= become_empty_1 || intbuff_int_1; // three gates deep
       INT_OUT_1 <= intbuff_int_1;
       EMPTY_1 <= become_empty_1;
	ANCILL_OUT_1 <= ancbuff_1[intbuff_raddr_1];
       full_1 <= become_full_1;
	STOP_2 <= become_empty_2 || intbuff_int_2; // three gates deep
       INT_OUT_2 <= intbuff_int_2;
       EMPTY_2 <= become_empty_2;
	ANCILL_OUT_2 <= ancbuff_2[intbuff_raddr_2];
       full_2 <= become_full_2;
	STOP_3 <= become_empty_3 || intbuff_int_3; // three gates deep
       INT_OUT_3 <= intbuff_int_3;
       EMPTY_3 <= become_empty_3;
	ANCILL_OUT_3 <= ancbuff_3[intbuff_raddr_3];
       full_3 <= become_full_3;
       len_0 <= become_len_0;
       len_1 <= become_len_1;
       len_2 <= become_len_2;
       len_3 <= become_len_3;

       if (do_write_0)
         write_addr_0 <= write_addr_0 + 1;
       if (do_read_0)
         read_addr_0 <= read_addr_0 + 1;
       if (do_write_1)
         write_addr_1 <= write_addr_1 + 1;
       if (do_read_1)
         read_addr_1 <= read_addr_1 + 1;
       if (do_write_2)
         write_addr_2 <= write_addr_2 + 1;
       if (do_read_2)
         read_addr_2 <= read_addr_2 + 1;
       if (do_write_3)
         write_addr_3 <= write_addr_3 + 1;
       if (do_read_3)
         read_addr_3 <= read_addr_3 + 1;

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

	if (intbuff_int_det_1)
	  begin
	    intbuff_raddr_1 <= intbuff_raddr_1 +1;
	    intbuff_raddr_trail_1 <= intbuff_raddr_trail_1 +1;
	  end
	if (INT_IN_1 && do_write_1 && (!intbuff_full_1))
	  begin
	    intbuff_1[intbuff_waddr_1] <= write_addr_1;
	    ancbuff_1[intbuff_waddr_1] <= ANCILL_IN_1;
	    intbuff_waddr_1 <= intbuff_waddr_1 +1;
	  end

	if (intbuff_int_det_2)
	  begin
	    intbuff_raddr_2 <= intbuff_raddr_2 +1;
	    intbuff_raddr_trail_2 <= intbuff_raddr_trail_2 +1;
	  end
	if (INT_IN_2 && do_write_2 && (!intbuff_full_2))
	  begin
	    intbuff_2[intbuff_waddr_2] <= write_addr_2;
	    ancbuff_2[intbuff_waddr_2] <= ANCILL_IN_2;
	    intbuff_waddr_2 <= intbuff_waddr_2 +1;
	  end

	if (intbuff_int_det_3)
	  begin
	    intbuff_raddr_3 <= intbuff_raddr_3 +1;
	    intbuff_raddr_trail_3 <= intbuff_raddr_trail_3 +1;
	  end
	if (INT_IN_3 && do_write_3 && (!intbuff_full_3))
	  begin
	    intbuff_3[intbuff_waddr_3] <= write_addr_3;
	    ancbuff_3[intbuff_waddr_3] <= ANCILL_IN_3;
	    intbuff_waddr_3 <= intbuff_waddr_3 +1;
	  end
      end

endmodule // lsab_cr

module lsab_cw(input CLK,
              input 	    RST,
              input 	    READ0,
              input 	    READ1,
              input 	    READ2,
              input 	    READ3,
              input 	    WRITE,
              input [1:0]   READ_FIFO,
              input [1:0]   WRITE_FIFO,
              input [31:0]  IN,
              output [31:0] OUT_0,
              output [31:0] OUT_1,
              output [31:0] OUT_2,
              output [31:0] OUT_3,
	      output 	    BFULL,
	       /* begin DEVICE ERR */
	      input 	    DEV_0_ERR,
	      input 	    DEV_1_ERR,
	      input 	    DEV_2_ERR,
	      input 	    DEV_3_ERR,
	      output 	    DEV_0_ERR_ACK,
	      output 	    DEV_1_ERR_ACK,
	      output 	    DEV_2_ERR_ACK,
	      output 	    DEV_3_ERR_ACK,
	      output 	    DEVERR,
	      input 	    DEVERRACK);
  reg [31:0] 		    OUT_0 = 32'd0, OUT_1 = 32'd0,
			    OUT_2 = 32'd0, OUT_3 = 32'd0;
  reg 			    BFULL = 1'b0;
  reg 			    DEV_0_ERR_ACK = 1'b0,
			    DEV_1_ERR_ACK = 1'b0,
			    DEV_2_ERR_ACK = 1'b0,
			    DEV_3_ERR_ACK = 1'b0;
  reg 			    DEVERR = 1'b0;

  reg               empty_0 = 1'b1, empty_1 = 1'b1,
		    empty_2 = 1'b1, empty_3 = 1'b1;
  reg               full_0 = 1'b0, full_1 = 1'b0,
		    full_2 = 1'b0, full_3 = 1'b0;
  reg               bfull_0 = 1'b0, bfull_1 = 1'b0,
                    bfull_2 = 1'b0, bfull_3 = 1'b0;
  reg [5:0]         len_0 = 6'd0, len_1 = 6'd0, len_2 = 6'd0, len_3 = 6'd0;
  reg [5:0]         write_addr_0 = 6'd0, write_addr_1 = 6'd0,
                    write_addr_2 = 6'd0, write_addr_3 = 6'd0;
  reg [5:0]         read_addr_0 = 6'd0, read_addr_1 = 6'd0,
                    read_addr_2 = 6'd0, read_addr_3 = 6'd0;
  reg               re_prev;
  reg [1:0]         re_fifo_prev;

  wire                      read_0, read_1, read_2, read_3;
  wire                      write_0, write_1, write_2, write_3;
  wire                      do_read_0, do_read_1, do_read_2, do_read_3;
  wire                      do_write_0, do_write_1, do_write_2, do_write_3;

  reg               become_empty_0, become_empty_1,
                    become_empty_2, become_empty_3;
  reg               become_full_0, become_full_1,
                    become_full_2, become_full_3;
  reg               become_bfull_0, become_bfull_1,
                    become_bfull_2, become_bfull_3;
  reg [5:0]         become_len_0, become_len_1,
                    become_len_2, become_len_3;

  wire [31:0] 	    out_mem;
  reg [7:0]         write_addr, read_addr;
  reg               we, re;

  assign read_0 = READ0 && (READ_FIFO == 2'h0);
  assign read_1 = READ1 && (READ_FIFO == 2'h1);
  assign read_2 = READ2 && (READ_FIFO == 2'h2);
  assign read_3 = READ3 && (READ_FIFO == 2'h3);

  assign write_0 = WRITE && (WRITE_FIFO == 2'h0);
  assign write_1 = WRITE && (WRITE_FIFO == 2'h1);
  assign write_2 = WRITE && (WRITE_FIFO == 2'h2);
  assign write_3 = WRITE && (WRITE_FIFO == 2'h3);

  assign do_write_0 = full_0 ? 0 : write_0;
  assign do_write_1 = full_1 ? 0 : write_1;
  assign do_write_2 = full_2 ? 0 : write_2;
  assign do_write_3 = full_3 ? 0 : write_3;

  assign do_read_0 = empty_0 ? 0 : read_0;
  assign do_read_1 = empty_1 ? 0 : read_1;
  assign do_read_2 = empty_2 ? 0 : read_2;
  assign do_read_3 = empty_3 ? 0 : read_3;

  always @(len_0 or do_read_0 or do_write_0 or full_0 or empty_0 or bfull_0)
    case ({len_0,do_read_0,do_write_0})
      {6'h3f,2'b10}: begin
	become_full_0 <= 0; become_empty_0 <= 0; become_bfull_0 <= 1;
      end
      {6'h3e,2'b01}: begin
	become_full_0 <= 1; become_empty_0 <= 0; become_bfull_0 <= 1;
      end
      {6'h37,2'b10}: begin
	become_full_0 <= 0; become_empty_0 <= 0; become_bfull_0 <= 0;
      end
      {6'h36,2'b01}: begin
	become_full_0 <= 0; become_empty_0 <= 0; become_bfull_0 <= 1;
      end
      {6'h01,2'b10}: begin
	become_full_0 <= 0; become_empty_0 <= 1; become_bfull_0 <= 0;
      end
      {6'h00,2'b01}: begin
	become_full_0 <= 0; become_empty_0 <= 0; become_bfull_0 <= 0;
      end
      default: begin
	become_full_0 <= full_0; become_empty_0 <= empty_0;
	become_bfull_0 <= bfull_0;
      end
    endcase // case ({len_0,do_read_0,do_write_0})

  always @(len_1 or do_read_1 or do_write_1 or full_1 or empty_1 or bfull_1)
    case ({len_1,do_read_1,do_write_1})
      {6'h3f,2'b10}: begin
	become_full_1 <= 0; become_empty_1 <= 0; become_bfull_1 <= 1;
      end
      {6'h3e,2'b01}: begin
	become_full_1 <= 1; become_empty_1 <= 0; become_bfull_1 <= 1;
      end
      {6'h37,2'b10}: begin
	become_full_1 <= 0; become_empty_1 <= 0; become_bfull_1 <= 0;
      end
      {6'h36,2'b01}: begin
	become_full_1 <= 0; become_empty_1 <= 0; become_bfull_1 <= 1;
      end
      {6'h01,2'b10}: begin
	become_full_1 <= 0; become_empty_1 <= 1; become_bfull_1 <= 0;
      end
      {6'h00,2'b01}: begin
	become_full_1 <= 0; become_empty_1 <= 0; become_bfull_1 <= 0;
      end
      default: begin
	become_full_1 <= full_1; become_empty_1 <= empty_1;
	become_bfull_1 <= bfull_1;
      end
    endcase // case ({len_1,do_read_1,do_write_1})

  always @(len_2 or do_read_2 or do_write_2 or full_2 or empty_2 or bfull_2)
    case ({len_2,do_read_2,do_write_2})
      {6'h3f,2'b10}: begin
	become_full_2 <= 0; become_empty_2 <= 0; become_bfull_2 <= 1;
      end
      {6'h3e,2'b01}: begin
	become_full_2 <= 1; become_empty_2 <= 0; become_bfull_2 <= 1;
      end
      {6'h37,2'b10}: begin
	become_full_2 <= 0; become_empty_2 <= 0; become_bfull_2 <= 0;
      end
      {6'h36,2'b01}: begin
	become_full_2 <= 0; become_empty_2 <= 0; become_bfull_2 <= 1;
      end
      {6'h01,2'b10}: begin
	become_full_2 <= 0; become_empty_2 <= 1; become_bfull_2 <= 0;
      end
      {6'h00,2'b01}: begin
	become_full_2 <= 0; become_empty_2 <= 0; become_bfull_2 <= 0;
      end
      default: begin
	become_full_2 <= full_2; become_empty_2 <= empty_2;
	become_bfull_2 <= bfull_2;
      end
    endcase // case ({len_2,do_read_2,do_write_2})

  always @(len_3 or do_read_3 or do_write_3 or full_3 or empty_3 or bfull_3)
    case ({len_3,do_read_3,do_write_3})
      {6'h3f,2'b10}: begin
	become_full_3 <= 0; become_empty_3 <= 0; become_bfull_3 <= 1;
      end
      {6'h3e,2'b01}: begin
	become_full_3 <= 1; become_empty_3 <= 0; become_bfull_3 <= 1;
      end
      {6'h37,2'b10}: begin
	become_full_3 <= 0; become_empty_3 <= 0; become_bfull_3 <= 0;
      end
      {6'h36,2'b01}: begin
	become_full_3 <= 0; become_empty_3 <= 0; become_bfull_3 <= 1;
      end
      {6'h01,2'b10}: begin
	become_full_3 <= 0; become_empty_3 <= 1; become_bfull_3 <= 0;
      end
      {6'h00,2'b01}: begin
	become_full_3 <= 0; become_empty_3 <= 0; become_bfull_3 <= 0;
      end
      default: begin
	become_full_3 <= full_3; become_empty_3 <= empty_3;
	become_bfull_3 <= bfull_3;
      end
    endcase // case ({len_3,do_read_3,do_write_3})

  always @(do_read_0 or do_write_0 or len_0)
    case ({do_read_0,do_write_0})
      2'b10: become_len_0 <= len_0 -1;
      2'b01: become_len_0 <= len_0 +1;
      default: become_len_0 <= len_0;
    endcase // case ({do_read_0,do_write_0})

  always @(do_read_1 or do_write_1 or len_1)
    case ({do_read_1,do_write_1})
      2'b10: become_len_1 <= len_1 -1;
      2'b01: become_len_1 <= len_1 +1;
      default: become_len_1 <= len_1;
    endcase // case ({do_read_1,do_write_1})

  always @(do_read_2 or do_write_2 or len_2)
    case ({do_read_2,do_write_2})
      2'b10: become_len_2 <= len_2 -1;
      2'b01: become_len_2 <= len_2 +1;
      default: become_len_2 <= len_2;
    endcase // case ({do_read_2,do_write_2})

  always @(do_read_3 or do_write_3 or len_3)
    case ({do_read_3,do_write_3})
      2'b10: become_len_3 <= len_3 -1;
      2'b01: become_len_3 <= len_3 +1;
      default: become_len_3 <= len_3;
    endcase // case ({do_read_3,do_write_3})

  always @(WRITE_FIFO or
          write_addr_0 or write_addr_1 or write_addr_2 or write_addr_3 or
          do_write_0 or do_write_1 or do_write_2 or do_write_3)
    case (WRITE_FIFO)
      2'b00: begin
       write_addr <= {2'b00,write_addr_0};
       we <= do_write_0;
      end
      2'b01: begin
       write_addr <= {2'b01,write_addr_1};
       we <= do_write_1;
      end
      2'b10: begin
       write_addr <= {2'b10,write_addr_2};
       we <= do_write_2;
      end
      2'b11: begin
       write_addr <= {2'b11,write_addr_3};
       we <= do_write_3;
      end
    endcase // case (WRITE_FIFO)

  always @(READ_FIFO or
          read_addr_0 or read_addr_1 or read_addr_2 or read_addr_3 or
          do_read_0 or do_read_1 or do_read_2 or do_read_3)
    case (READ_FIFO)
      2'b00: begin
       read_addr <= {2'b00,read_addr_0};
       re <= do_read_0;
      end
      2'b01: begin
       read_addr <= {2'b01,read_addr_1};
       re <= do_read_1;
      end
      2'b10: begin
       read_addr <= {2'b10,read_addr_2};
       re <= do_read_2;
      end
      2'b11: begin
       read_addr <= {2'b11,read_addr_3};
       re <= do_read_3;
      end
    endcase // case (READ_FIFO)

  iceram32 lsab_sram(.RDATA(out_mem),
                     .RADDR(read_addr),
                     .RE(re),
                     .RCLKE(1'b1),
                     .RCLK(CLK),
                     .WDATA(IN),
                     .MASK(0),
                     .WADDR(write_addr),
                     .WE(we),
                     .WCLKE(1'b1),
                     .WCLK(CLK));

  always @(posedge CLK)
    if (RST)
      begin
	case (WRITE_FIFO) // gate depth of this construct was not modeled
	  2'h0: begin
	    BFULL <= become_bfull_0;
	    DEVERR <= DEV_0_ERR;
	    DEV_0_ERR_ACK <= DEVERRACK;
	    DEV_1_ERR_ACK <= 0;
	    DEV_2_ERR_ACK <= 0;
	    DEV_3_ERR_ACK <= 0;
	  end
	  2'h1: begin
	    BFULL <= become_bfull_1;
	    DEVERR <= DEV_1_ERR;
	    DEV_0_ERR_ACK <= 0;
	    DEV_1_ERR_ACK <= DEVERRACK;
	    DEV_2_ERR_ACK <= 0;
	    DEV_3_ERR_ACK <= 0;
	  end
	  2'h2: begin
	    BFULL <= become_bfull_2;
	    DEVERR <= DEV_2_ERR;
	    DEV_0_ERR_ACK <= 0;
	    DEV_1_ERR_ACK <= 0;
	    DEV_2_ERR_ACK <= DEVERRACK;
	    DEV_3_ERR_ACK <= 0;
	  end
	  2'h3: begin
	    BFULL <= become_bfull_3;
	    DEVERR <= DEV_3_ERR;
	    DEV_0_ERR_ACK <= 0;
	    DEV_1_ERR_ACK <= 0;
	    DEV_2_ERR_ACK <= 0;
	    DEV_3_ERR_ACK <= DEVERRACK;
	  end
	endcase // case (WRITE_FIFO)

       empty_0 <= become_empty_0;
       full_0 <= become_full_0;
       empty_1 <= become_empty_1;
       full_1 <= become_full_1;
       empty_2 <= become_empty_2;
       full_2 <= become_full_2;
       empty_3 <= become_empty_3;
       full_3 <= become_full_3;
       len_0 <= become_len_0;
       len_1 <= become_len_1;
       len_2 <= become_len_2;
       len_3 <= become_len_3;

       if (do_write_0)
         write_addr_0 <= write_addr_0 + 1;
       if (do_read_0)
         read_addr_0 <= read_addr_0 + 1;
       if (do_write_1)
         write_addr_1 <= write_addr_1 + 1;
       if (do_read_1)
         read_addr_1 <= read_addr_1 + 1;
       if (do_write_2)
         write_addr_2 <= write_addr_2 + 1;
       if (do_read_2)
         read_addr_2 <= read_addr_2 + 1;
       if (do_write_3)
         write_addr_3 <= write_addr_3 + 1;
       if (do_read_3)
         read_addr_3 <= read_addr_3 + 1;

       re_prev <= re;
       re_fifo_prev <= READ_FIFO;
       if (re_prev)
         case (re_fifo_prev)
           2'b00: OUT_0 <= out_mem;
           2'b01: OUT_1 <= out_mem;
           2'b10: OUT_2 <= out_mem;
           2'b11: OUT_3 <= out_mem;
         endcase // case (re_fifo_prev)
      end

endmodule // lsab_cw
