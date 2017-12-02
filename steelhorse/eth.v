module crc32ieee(input CLK,
		 input RST,
		 input BITS,
		 input WRITE_BITS,
		 input TERM,
		 output reg DONE,
		 output [31:0] CRC);
  reg [31:0]		crc_buff;
  reg [5:0]		endcounter;
  reg			terminal;

  wire			clk_e;
  wire [31:0]		crc_comp;

  assign clk_e = (~terminal & WRITE_BITS) ||
		 (terminal && (endcounter != 0));
  assign crc_comp = (crc_buff[31]) ? 32'h04c11db7 : 0;
  assign CRC = ~(crc_buff[31:0]);

  always @(posedge CLK)
    if (!RST)
      begin
	crc_buff <= 0;
	endcounter <= 0;
	terminal <= 0;
	DONE <= 0;
      end
    else
      begin
	if (TERM & (~terminal))
	  begin
	    terminal <= 1;
	    endcounter <= 6'h20; /* 32 bits for calculating CRC32-IEEE */
	  end

	/* This introduces a natural delay, needed
	   for the receiver. Sender is immune. */
	if (terminal && (endcounter == 0))
	  DONE <= 1;

	if (clk_e)
	  begin
	    if (terminal)
	      begin
		endcounter <= endcounter -1;
		crc_buff <= {crc_buff[30:0],1'b0} ^ crc_comp;
	      end
	    else /* WRITE_BITS is asserted */
	      crc_buff <= {crc_buff[30:0],BITS} ^ crc_comp;
	  end
      end

endmodule

module crcfeeder(input CLK,
		 input RST,
		 input WRITE_BIT,
		 input BIT,
		 input TERM,
		 input [31:0] CRC_COMP,
		 output BIT_O,
		 output WRITE_BIT_O,
		 output reg SAFE);
  reg [31:0]		buff;
  reg [5:0]		count;
  reg			terminating;

  wire                  bit_processed;

  assign BIT_O = buff[31];
  assign WRITE_BIT_O = WRITE_BIT & count[5];
  assign bit_processed = count[5] ? BIT : ~BIT;

  always @(posedge CLK)
    if (!RST)
      begin
	count <= 0;
	buff <= 0;
	terminating <= 0;
	SAFE <= 0;
      end
    else
      begin
	if (WRITE_BIT & (~terminating))
	  buff <= {buff[30:0],bit_processed};

	if (TERM)
	  terminating <= 1;

	if (WRITE_BIT & (~count[5]))
	  count <= count +1;

	if ((CRC_COMP == buff) && terminating)
	  SAFE <= 1;
	else
	  SAFE <= 0;
      end

endmodule
/*
module clkslc_tmpl(input CLK1,
		   input CLK2,
		   input SLCT,
		   output CLK);

  assign CLK = SLCT ? CLK1 : CLK2;

endmodule
*/
//module gearbox(input recv_CLK,  /* faster */
//		input send_CLK, /* slower */
/*		input RST,
		input MODE,
		output run_CLK,
		output CLKE);
  reg			r1;
  reg [1:0]		counter;*/

  /* Template for the clock select. */
  /* Usefull for testing. */
/*
  clkslc_tmpl clkslct(.CLK1(send_CLK),
		      .CLK2(recv_CLK),
		      .SLCT(r1),
		      .CLK(run_CLK));
*/

  /* Lattice MachXO2 clock select. */
/*  DCMA clkslct(.CLK0(recv_CLK),
	       .CLK1(send_CLK),
	       .SEL(r1),
	       .DCMOUT(run_CLK));

  assign CLKE = counter == 2'h3;

  always @(posedge send_CLK)
    if (!RST)
      begin
	r1 <= 0;
	counter <= 2'h3;
      end
    else
      begin
	if ((r1 ^ MODE) & CLKE)
	  counter <= 2'h0;
	else
	  if (~CLKE)
	    counter <= counter +1;

	if (counter == 2'h0)
	  r1 <= MODE;
      end

endmodule
*/
module cooldown_counter(input recv_CLK,
			input send_CLK,
			input RST,
			input ACTIVE_HWY,
			input ACTIVE_LGT,
			input ABORT,
			input [9:0] ABORTTARGET,
			output COOL_RECV,
			output COOL_SEND);
  /* Usage of this tracker register is gravely sub-optimal.
     Ideally, I would use a feedback loop which would be
     frequency-invariant. But. If I do that, the synthetizer
     apparently can not place everything close enough for
     proper operation and timing analysis fails, sometimes on
     a single signal. To make synthesis work, I have to unravel
     the feedback loop, giving the placer enough room to place
     everything. The tracker register is one way of doing that. */
  reg [2:0]		tracker_hwy, tracker_lgt;
  reg [9:0]		target;
  reg [7:0]		count_recv;
  reg [16:0]		count_send;

  assign COOL_RECV = count_recv[7];
  assign COOL_SEND = count_send[16:7] == target;

  always @(posedge recv_CLK)
    if (!RST)
      begin
	tracker_hwy <= 0;
	tracker_lgt <= 0;
      end
    else
      begin
	tracker_hwy <= {tracker_hwy[1:0],ACTIVE_HWY};
	tracker_lgt <= {tracker_lgt[1:0],ACTIVE_LGT};
      end

  always @(posedge send_CLK)
    if (!RST)
      begin
	count_send <= 0;
	count_recv <= 0;
	target <= 10'h001;
      end
    else
      begin
	if ((tracker_hwy != 0) || ABORT)
	  begin
	    count_send <= 0;
	    if (ABORT)
	      target <= (ABORTTARGET | 10'h001);
	    else
	      target <= 10'h001;
	  end
	else
	  begin
	    if (~COOL_SEND)
	      count_send <= count_send +1;
	  end

	if (tracker_lgt == 0)
	  begin
	    if (~COOL_RECV)
	      count_recv <= count_recv +1;
	  end
	else
	  count_recv <= 0;
      end

endmodule

module arbitrer(input CLK,
		input RST,
		input DO_GO,
		input SENDREG_OUT,
		input COOL,
		input SENDDONE,
		input [15:0] RND,
		output reg ABORT,
		output ABANDON,
		output reg [9:0] ABORTTARGET,
		output reg SENDREG_IN,
		output reg MODE,
		output reg PULSE);
  reg [5:0]		abortcount, abandoncount;
  reg [17:0]		linkdetect_counter;

  wire [3:0]		abortshift;

  assign ABANDON = abandoncount == 6'h3f;
  assign abortshift[2:0] = abandoncount[2:0];
  assign abortshift[3] = (abandoncount[5:3] != 3'h0) ? 1 : 0;

  always @(posedge CLK)
    if (!RST)
      begin
	ABORT <= 0;
	SENDREG_IN <= 0;
	MODE <= 0;
	abortcount <= 0;
	abandoncount <= 0;
	PULSE <= 0;
	linkdetect_counter <= 18'h20000;
	ABORTTARGET <= 1;
      end
    else
      if (DO_GO)
      begin
	if (~MODE)
	  begin
	    if (COOL && (SENDREG_OUT ^ SENDREG_IN))
	      begin
		if (ABANDON)
		  begin
		    SENDREG_IN <= ~SENDREG_IN;
		    abandoncount <= 0;
		  end
		else
		  MODE <= 1;
	      end

	    ABORT <= 0;
	    abortcount <= 6'h22;
	    if (linkdetect_counter == 0)
	      /* Even though I am supposed to prioritize
		 sending frames over link-detect pulses,
		 this is easier to implement. */
	      PULSE <= 1;
	    else
	      PULSE <= 0;

	    if (COOL)
	      linkdetect_counter <= linkdetect_counter -1;
	    else
	      linkdetect_counter <= 18'h20000;
	  end
	else
	  begin
	    if (SENDDONE)
	      begin
		MODE <= 0;
		ABORTTARGET <= RND >> (~abortshift);
		PULSE <= 0;

		if ((~ABORT) & (~PULSE))
		  begin
		    SENDREG_IN <= ~SENDREG_IN;
		    abandoncount <= 0;
		  end
	      end

	    if (abortcount == 6'h03)
	      begin
		PULSE <= 1;
		abandoncount <= abandoncount +1;
	      end

	    if (!COOL)
	      ABORT <= 1;
	    if (ABORT)
	      abortcount <= abortcount -1;

	    linkdetect_counter <= 18'h20000;
	  end
      end

endmodule

module integration(input sampler_CLK,
		   input recv_CLK,
		   input master_RST,
                   input DO_GO,
		   input WIRE_RX,
		   output [9:0] ADDR,
		   output [31:0] DATA_RECV,
		   output WRITE_DATA_RECV,
		   output [10:0] RECV_LEN,
		   output reg READ_DATA_SEND,
		   output NEW_PCKT,
		   output NEW_PCKT_VALID,
		/* ------------------- */
		   input send_CLK,
		   input enc_CLK,
		   input [10:0] SENDLEN,
		   input [31:0] DATA_SEND,
		   output WIRE_TX,
		   output ABANDON,
		/* ------------------- */
		   input [15:0] RND,
		   input SENDREG_RQ,
		   output SENDREG_AN,
		/* ------------------- */
		   output COLLISION);
  reg			mode, mode_r1, mode_r2;
  wire			cool_recv, cool_send;
  wire			active_recv_hwy, active_recv_lgt,
			active_recv_hwy_complex;
  wire			recv_bit, recv_write_bit;
  wire			crc_recv_rst, crc_recv_bit, crc_recv_write;
  wire			crc_send_rst, crc_send_bit, crc_send_write;
  wire			crc_done, crc_safe, sendpulse;
  wire			mode_wire, abort_send;
  wire			donesend, crc_send_term, crc_recv_term;
  wire [31:0]		crc_send_buff, crc_recv_buff;
  wire [9:0]		aborttarget;
  wire [8:0]		addr_send, addr_recv, addr_moded;
  wire			rst_send;

  wire 			read_w;

  assign COLLISION = abort_send;
  assign addr_moded = mode ? addr_send : addr_recv;
  assign ADDR = {mode,addr_moded};
  assign rst_send = mode_r2 & mode;
  assign active_recv_hwy_complex = active_recv_hwy | donesend;

  recv_integration recv(.fast_CLK(sampler_CLK),
			.slow_CLK(recv_CLK),
			.RST(master_RST),
			.WIRE(WIRE_RX),
			.IS_COOL(cool_recv),
			.ADDR(addr_recv),
			.DATA(DATA_RECV),
			.WRITE_DATA(WRITE_DATA_RECV),
			.RECV_LEN(RECV_LEN),
			.NEW_PCKT(NEW_PCKT),
			.NEW_PCKT_VALID(NEW_PCKT_VALID),
			.ACTIVE_HWY(active_recv_hwy),
			.ACTIVE_LGT(active_recv_lgt),
			.CRC_RST(crc_recv_rst),
			.CRC_BIT(recv_bit),
			.CRC_WRITE(recv_write_bit),
			.CRC_TERM(crc_recv_term),
			.CRC_SAFE(crc_safe),
			.CRC_DONE(crc_done));
  send_integration send(.CLK(send_CLK),
			.enc_CLK(enc_CLK),
			.RST(rst_send),
			.DO_GO(DO_GO),
			.SENDLEN(SENDLEN),
			.DATA(DATA_SEND),
			.SENDPULSE(sendpulse),
			.ABORT(abort_send),
			.ADDR(addr_send),
			.DONE(donesend),
			.WIRE(WIRE_TX),
			.READ(read_w),
			.CRC_RST(crc_send_rst),
			.CRC_DATA(crc_send_bit),
			.CRC_WRITE(crc_send_write),
			.CRC_FASTHALT(crc_send_term),
			.CRC_BUFF(crc_send_buff));
  crcfeeder recvfeeder(.CLK(recv_CLK),
		       .RST(crc_recv_rst),
		       .WRITE_BIT(recv_write_bit),
		       .BIT(recv_bit),
		       .TERM(crc_recv_term),
		       .CRC_COMP(crc_recv_buff),
		       .BIT_O(crc_recv_bit),
		       .WRITE_BIT_O(crc_recv_write),
		       .SAFE(crc_safe));

  crc32ieee crc_recv(.CLK(recv_CLK),
		     .RST(crc_recv_rst),
		     .BITS(crc_recv_bit),
		     .WRITE_BITS(crc_recv_write),
		     .TERM(crc_recv_term),
		     .DONE(crc_done),
		     .CRC(crc_recv_buff));
  crc32ieee crc_send(.CLK(send_CLK),
		     .RST(crc_send_rst),
		     .BITS(crc_send_bit),
		     .WRITE_BITS(crc_send_write),
		     .TERM(crc_send_term),
		     .DONE(),
		     .CRC(crc_send_buff));

  cooldown_counter cooldown(.recv_CLK(recv_CLK),
			    .send_CLK(send_CLK),
			    .RST(master_RST),
			    .ACTIVE_HWY(active_recv_hwy_complex),
			    .ACTIVE_LGT(active_recv_lgt),
			    .ABORT(abort_send),
			    .ABORTTARGET(aborttarget),
			    .COOL_RECV(cool_recv),
			    .COOL_SEND(cool_send));
  arbitrer modeselector(.CLK(send_CLK),
			.RST(master_RST),
			.DO_GO(DO_GO),
			.SENDREG_OUT(SENDREG_RQ),
			.COOL(cool_send),
			.SENDDONE(donesend),
			.SENDREG_IN(SENDREG_AN),
			.MODE(mode_wire),
			.ABORT(abort_send),
			.RND(RND),
			.ABANDON(ABANDON),
			.ABORTTARGET(aborttarget),
			.PULSE(sendpulse));

  always @(posedge send_CLK)
    if (!master_RST)
      begin
	READ_DATA_SEND <= 0;
	mode <= 0;
	mode_r1 <= 0;
	mode_r2 <= 0;
      end
    else
      if (DO_GO)
      begin
	READ_DATA_SEND <= read_w || (mode_wire && !mode);
	mode <= mode_wire;
	mode_r1 <= mode;
	mode_r2 <= mode_r1;
      end

endmodule

module Steelhorse(input sampler_CLK,
		  input recv_CLK,
		  input send_CLK,
		  input enc_CLK,
		  input RST,
		/* --------------- */
		  input WIRE_RX,
		  output WIRE_TX,
		/* --------------- */
		  output [9:0] DATA_ADDR,
		  output [31:0] DATA_RECV,
		  output WRITE_DATA_RECV,
		  input [31:0] DATA_SEND,
		  output READ_DATA_SEND,
		  output NWPCKT_IRQ,
		  output NWPCKT_IRQ_VALID,
		/*--------------- */
		  output COLLISION,
		  input RUN,
		  output reg BUSY,
		  input [31:0] INTRFC_DATAIN,
		  output [31:0] INTRFC_DATAOUT);
  reg [15:0]		rnd, intrfc_reg_send;
  reg [9:0]		intrfc;
  reg			signal1, signal2;
  reg 			intRUN;

  wire			rnd_first, abandon, sendreg_an;
  wire [10:0]		recv_len;

  reg 			DO_GO;

  assign rnd_first = rnd[1] ^ rnd[0];

  assign INTRFC_DATAOUT = {16'h0000,5'h00,recv_len};

  integration eth(.sampler_CLK(sampler_CLK),
		  .recv_CLK(recv_CLK),
		  .master_RST(RST),
		  .DO_GO(DO_GO),
		  .WIRE_RX(WIRE_RX),
		  .ADDR(DATA_ADDR),
		  .DATA_RECV(DATA_RECV),
		  .WRITE_DATA_RECV(WRITE_DATA_RECV),
		  .RECV_LEN(recv_len),
		  .READ_DATA_SEND(READ_DATA_SEND),
		  .NEW_PCKT(NWPCKT_IRQ),
		  .NEW_PCKT_VALID(NWPCKT_IRQ_VALID),
		  .send_CLK(send_CLK),
		  .enc_CLK(enc_CLK),
		  .SENDLEN(intrfc_reg_send[10:0]),
		  .DATA_SEND(DATA_SEND),
		  .WIRE_TX(WIRE_TX),
		  .ABANDON(abandon),
		  .RND(rnd),
		  .SENDREG_RQ(signal2),
		  .SENDREG_AN(sendreg_an),
		  .COLLISION(COLLISION));

  always @(posedge recv_CLK) // this can run at random speed
    if (!RST)
      begin
	intrfc <= 0;
	signal1 <= 0;
	intRUN <= 0;
      end
    else
      if ((signal1 == signal2) &&
	  (RUN != intRUN))
	begin
	  intrfc <= INTRFC_DATAIN[9:0];
	  signal1 <= ~signal1;
	  intRUN <= ~intRUN;
	end

  always @(posedge send_CLK)
    if (!RST)
      begin
	rnd <= 16'haa55;
	signal2 <= 0;
	intrfc_reg_send <= 0;
	BUSY <= 0;
	DO_GO <= 0;
      end
    else
      begin
	DO_GO <= !DO_GO;
      if (DO_GO)
      begin
	rnd <= {rnd_first,rnd[15:1]};
	if (signal1 ^ signal2)
	  begin
	    signal2 <= ~signal2;
	    intrfc_reg_send[10:0] <= intrfc;
	    intrfc_reg_send[15] <= 0;
	  end
	else
	  if (abandon)
	    intrfc_reg_send[15] <= 1;

	if (signal2 ^ sendreg_an)
	  BUSY <= 1;
	else
	  BUSY <= 0;
      end // if (DO_GO)
      end

endmodule
