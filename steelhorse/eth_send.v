module data_crcload(input CLK,
		     input RST,
		     input DO_GO,
		     input [10:0] SENDLEN,
		     input [31:0] DATA,
		     output RUN,
		     output [8:0] ADDR,
		     output OCTET,
		     output NEXT,
		     output CRCHALT,
		     output [15:0] DELAYDATA,
		     output CRCBIT,
		     output WRITE_CRCBITS,
                     output reg READ);
  reg [4:0]		counter;
  reg [5:0] 		complement_counter;
  reg			r1, delayreg_fast, delayreg_slow;
  reg [10:0]		lenreg;
  reg [8:0]		addrreg;
  reg [7:0]		crcbits;
  reg [15:0]		stagingreg1, stagingreg2;

  wire [10:0]		computed_len;

  assign computed_len = lenreg +5;
  assign OCTET = r1 ^ counter[3];
  assign WRITE_CRCBITS = delayreg_fast & ~CRCHALT & DO_GO;
  assign DELAYDATA = stagingreg2;
  assign ADDR = addrreg;
  assign CRCBIT = complement_counter[5] ? crcbits[0] : ~crcbits[0];
  assign NEXT = (lenreg == SENDLEN);
  assign CRCHALT = (lenreg[10:7] ^ 4'hf) && (computed_len > SENDLEN);
  assign RUN = delayreg_slow;

  always @(posedge CLK)
    if (!RST)
      begin
	counter <= 0;
        complement_counter <= 0;
	r1 <= 1; /* an obscure hack */
	/* The hack in question makes sure crc32ieee doesn't
	   miss a bit. Otherwise, there would be a single-bit
	   gap between the first and second octet of the data. */
	lenreg <= 11'h7fb;
	addrreg <= 0;
	delayreg_slow <= 0;
	delayreg_fast <= 0;
	READ <= 0;
      end
    else
      if (DO_GO)
      begin
	r1 <= counter[3];
	counter <= counter +1;

	if (OCTET & (~NEXT))
	  begin
	    lenreg <= lenreg +1;

	    case (counter[4:3])
	      2'h0: begin
		crcbits <= DATA[31:24];
		READ <= 0;
	      end
	      2'h1: begin
		delayreg_slow <= 1;

		crcbits <= DATA[23:16];
		stagingreg1 <= DATA[31:16];
		stagingreg2 <= stagingreg1;
		READ <= 0;
	      end
	      2'h2: begin
		crcbits <= DATA[15:8];
		READ <= 0;
	      end
	      2'h3: begin
		crcbits <= DATA[7:0];
		stagingreg1 <= DATA[15:0];
		stagingreg2 <= stagingreg1;
		addrreg <= addrreg +1;
		READ <= 1;
	      end
	    endcase // case (counter[4:3])
	  end
	else
	  begin
	    crcbits <= {1'b0,crcbits[7:1]};
	    READ <= 0;
	  end

	delayreg_fast <= 1;

	if ((!complement_counter[5]) & delayreg_fast)
	  complement_counter <= complement_counter +1;
      end

endmodule

module data_encload(input CLK,
		    input RST,
		    input DO_GO,
		    input END_DATA,
		    input OCTET,
		    input [31:0] CRC,
		    input [15:0] DATA,
		    output BIT,
		    output reg ENDOFSHOW);
  reg [7:0]		sendreg;
  reg [1:0] 		preamble_counter, crc_counter, data_counter;
  reg			high, endisnigh;

  assign BIT = sendreg[0];

  assign preamble = preamble_counter != 2'h3;

  always @(posedge CLK)
    if (!RST)
      begin
	high <= 1;
	endisnigh <= 0;
	sendreg <= 8'h55; /* preamble, part 1 */
	ENDOFSHOW <= 0;

	preamble_counter <= 0;
	crc_counter <= 0;
	data_conter <= 0;
      end
    else
      if (DO_GO)
      begin
	if (OCTET)
	  begin
	    if (preamble)
	      begin
		preamble_counter <= preamble_counter +1;
		case (preamble_counter)
		  2'h0: sendreg <= 8'h55;
		  2'h1: sendreg <= 8'h55;
		  2'h2: sendreg <= 8'hd5;
		endcase
	      end

	    if (END_DATA)
	      begin
		crc_counter <= crc_counter +1;
		case (crc_counter)
		  2'h0:
		    sendreg <= {CRC[24],CRC[25],CRC[26],CRC[27],
				CRC[28],CRC[29],CRC[30],CRC[31]};
		  2'h1:
		    sendreg <= {CRC[16],CRC[17],CRC[18],CRC[19],
				CRC[20],CRC[21],CRC[22],CRC[23]};
		  2'h2:
		    sendreg <= {CRC[8], CRC[9], CRC[10],CRC[11],
				CRC[12],CRC[13],CRC[14],CRC[15]};
		  2'h3: begin
		    sendreg <= {CRC[0], CRC[1], CRC[2], CRC[3],
				CRC[4], CRC[5], CRC[6], CRC[7]};
		    endisnigh <= 1;
		  end
		endcase // case (crc_counter)
	      end // if (END_DATA)

	    if ((crc_counter == 2'h3) && endisnigh)
	      ENDOFSHOW <= 1;

	    if (!preamble && !END_DATA)
	      begin
		high <= !high;
		if (high)
		  sendreg <= DATA[15:8];
		else
		  sendreg <= DATA[7:0];
	      end
	  end // if (OCTET)
	else
	  sendreg <= {1'b0,sendreg[7:1]};
      end

endmodule

module manenc(input enc_CLK,
	      input RST,
	      input DATA,
	      input ABORT,
	      output reg WIRE,
	      input ENDOFSHOW,
	      input PULSE);
  reg 			side;
  reg [1:0] 		pulsing;

  always @(posedge enc_CLK)
    if ((! RST) & (~PULSE))
      begin
	side <= 0;
	WIRE <= 0;
	pulsing <= 0;
      end
    else
      begin
	side <= ~side;

	if (ENDOFSHOW | PULSE)
	  begin
	    if (PULSE)
	      begin
		pulsing <= {pulsing[0],1'b1};
		if (pulsing == 2'b11)
		  WIRE <= 0;
		else
		  WIRE <= 1;
	      end
	    else /* ENDOFSHOW is asserted */
	      begin
		WIRE <= 1;
	      end // else: !if(PULSE)
	  end // if (ENDOFSHOW | PULSE)
	else
	  begin
	    if (ABORT)
	      WIRE <= side; // Have to at least make an effort.
	                    // Note that this can actually produce invalid
	                    // waveforms, resembling end of frame pulses.
	    else
	      if (!side)
		WIRE <= ~DATA;
	      else
		WIRE <= DATA;

	    pulsing <= 0;
	  end
      end

endmodule

module send_integration(input CLK,
			input enc_CLK,
			input RST,
			input DO_GO,
			input [10:0] SENDLEN,
			input [31:0] DATA,
			input SENDPULSE,
			input ABORT,
			output [8:0] ADDR,
			output reg DONE,
			output WIRE,
			output READ,
			/* --------- */
			output CRC_RST,
			output CRC_DATA,
			output CRC_WRITE,
			output CRC_FASTHALT,
			input [31:0] CRC_BUFF);
  wire			run_enc, octet, end_data;
  wire			bit_interconnect, endofshow;
  wire [15:0]		data_interconnect;

  assign CRC_RST = RST;

  data_crcload crcloader(.CLK(CLK),
			 .RST(RST),
			 .DO_GO(DO_GO),
			 .SENDLEN(SENDLEN),
			 .DATA(DATA),
			 .RUN(run_enc),
			 .ADDR(ADDR),
			 .OCTET(octet),
			 .NEXT(end_data),
			 .CRCHALT(CRC_FASTHALT),
			 .DELAYDATA(data_interconnect),
			 .CRCBIT(CRC_DATA),
			 .WRITE_CRCBITS(CRC_WRITE),
			 .READ(READ));
  data_encload encloader(.CLK(CLK),
			 .RST(run_enc),
			 .DO_GO(DO_GO),
			 .END_DATA(end_data),
			 .OCTET(octet),
			 .CRC(CRC_BUFF),
			 .DATA(data_interconnect),
			 .ENDOFSHOW(endofshow),
			 .BIT(bit_interconnect));
  manenc enc(.enc_CLK(enc_CLK),
	     .RST(run_enc),
	     .DATA(bit_interconnect),
	     .ABORT(ABORT),
	     .WIRE(WIRE),
	     .ENDOFSHOW(endofshow),
	     .PULSE(SENDPULSE));
	/* TX controler is supposed to (de)assert RST the moment
	   it sees DONE asserted. Pulse width is encoded in the
	   signal propagation time. Give or take.  */

  always @(posedge CLK)
    if (!RST)
      DONE <= 0;
    else
      if (DO_GO)
      DONE <= (endofshow | SENDPULSE);

endmodule
