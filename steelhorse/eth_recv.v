module mandec_bitchange(input CLK,
			input 	    RST,
			input 	    DATAI,
			output reg  PCLK, // pseudo-CLK
			output reg  DATAO,
			output 	    ERROR);
  reg 				    r1,r2;
  reg [4:0] 			    timer_;

  wire 				    event_, run;
  wire 				    bittransition_t, bittransition_0to1_t;


  assign run = timer_ != 5'h1f;

  assign event_ = r1 ^ r2;

  assign bittransition_t = timer_ > 5'h04;
  assign bittransition_0to1_t = timer_ > 5'h0a;
  assign ERROR = timer_ == 5'h13;

  always @(posedge CLK)
    begin
      r1 <= DATAI;
      r2 <= r1;

      if (!RST)
	begin
	  timer_ <= 5'h1f;
	  DATAO <= 0;
	  PCLK <= 0;
	end
      else
	begin
	  if (event_ & bittransition_t)
	    begin
	      timer_ <= 0;
	      PCLK <= ~PCLK;

	      if (r1)
		begin
		  if (bittransition_0to1_t)
		    DATAO <= 1;
		end
	      else
		DATAO <= 0;
	    end // if (event_ & bittransition_t)
	  else
	    if (run)
		timer_ <= timer_ +1;
	end // else: !if(!RST)
    end // always @ (posedge CLK)

endmodule // mandec_bitchange

module innailer(input fast_CLK,
		input 	   slow_CLK,
		input 	   RST,
		input 	   DATAI,
		input 	   pseudo_CLK,
		input 	   ERROR,
		output reg DATAO,
		output reg DATA_VALID,
		output reg WAVEFRM_ERROR,
		output reg MISSED_BEAT);
   reg 			   r1, r2;
   wire 		   negedge_detect;

   reg 			   already_changed,
			   did_lose_beat;

   reg 			   prev_pCLK;
   reg 			   error_sticky;

   reg 			   bit_store;

   assign negedge_detect = (~r1) & r2;

   always @(posedge fast_CLK)
     if (!RST)
       begin
	 error_sticky <= 0;
	 bit_store <= 0;
       end
     else
     begin
	begin
	   r1 <= slow_CLK;
	   r2 <= r1;
	end

	if (ERROR & (~error_sticky))
	  /* Because of the main if clause twice below,
	   * there is a very remote possibility of a waveform
	   * error remaining undetected untill the end of
	   * frame. The CRC is supposed to pick that up. */
	  error_sticky <= 1;

	/* We have to handle a situation when slow_CLK is
	 * underclocked relative to the datastream clock. */
	if (pseudo_CLK ^ prev_pCLK)
	  already_changed <= 1;
	else
	  if (already_changed)
	    did_lose_beat <= 1;

	if (negedge_detect)
	  begin
	    if (error_sticky)
	      begin
		if (bit_store == 1'b0)
		  begin
		    error_sticky <= 0;

		    DATA_VALID <= 0;
		    WAVEFRM_ERROR <= 1;
		  end
		else
		  begin
		    DATAO <= bit_store;
		    DATA_VALID <= 1;
		    bit_store <= 1'b0;
		  end // else: !if(bit_store == 1'b0)
	      end
	    else
	      if (pseudo_CLK ^ prev_pCLK)
		begin
		  DATA_VALID <= 1;

		  bit_store <= DATAI;
		  DATAO <= bit_store;

		  WAVEFRM_ERROR <= 0;
		end
	       else
		 begin
		    /* slow_CLK is designed to be overclocked
		     * relative to the datastream clock. */
		    DATA_VALID <= 0;
		    WAVEFRM_ERROR <= 0;
		 end // else: !if(error_sticky)

	     if (did_lose_beat)
	       begin
		  MISSED_BEAT <= 1;
		  did_lose_beat <= 0;
	       end
	     else
	       MISSED_BEAT <= 0;
	     already_changed <= 0;

	     prev_pCLK <= pseudo_CLK;
	  end // if (negedge_detect)
     end // always @ (posedge fast_CLK)

endmodule // innailer

module eth_receiver(input fast_CLK,
		    input  slow_CLK,
		    input  RST,
		    input  DATA_WIRE,
		    output DATA,
		    output DATA_VALID,
		    output WAVEFRM_ERROR,
		    output MISSED_BEAT);
   wire 		   pseudo_CLK;
   wire 		   interconnect_DATA,
			   interconnect_ERROR;

   mandec_bitchange decoder(.CLK(fast_CLK),
			    .RST(RST),
			    .DATAI(DATA_WIRE),
			    .PCLK(pseudo_CLK),
			    .DATAO(interconnect_DATA),
			    .ERROR(interconnect_ERROR));

   innailer nailer(.fast_CLK(fast_CLK),
		   .slow_CLK(slow_CLK),
		   .RST(RST),
		   .DATAI(interconnect_DATA),
		   .pseudo_CLK(pseudo_CLK),
		   .ERROR(interconnect_ERROR),
		   .DATAO(DATA),
		   .DATA_VALID(DATA_VALID),
		   .WAVEFRM_ERROR(WAVEFRM_ERROR),
		   .MISSED_BEAT(MISSED_BEAT));

endmodule // eth_receiver


module bitcollector(input CLK,
		    input RST,
		    input DATAI,
		    input DATA_VALID,
		    output ROUND,
		    output reg [7:0] DATAO,
		    output WRITE_DATAO);
  reg [3:0]		counter;
  reg			r1;

  assign WRITE_DATAO = r1 ^ counter[3];
  assign ROUND = (counter[2:0] == 0);

  always @(posedge CLK)
    if (!RST)
      begin
	counter <= 0;
	r1 <= 0;
      end
    else
      begin
	if (DATA_VALID)
	  begin
	    counter <= counter +1;
            DATAO <= {DATAI,DATAO[7:1]};
	  end

	r1 <= counter[3];
      end

endmodule


module recv_cc(input CLK,
		input RST,
		input DATA,
		input DATA_VALID,
		input WAVEFRM_ERROR,
		input MISSED_BEAT,
		input AIRQ,
		input IS_COOL,
		output RUN_CRC,
		output reg CRC_TERM,
		output RECV_RST,
		output reg IRQ);
  reg [1:0]		mask;
  reg			prev_DATA;
  reg			running, ran;

  wire			error, recv, fin;
  wire			cool;

  assign RECV_RST = running;
  assign error = WAVEFRM_ERROR | MISSED_BEAT;
  assign recv = error | DATA_VALID;
  assign fin = (WAVEFRM_ERROR | MISSED_BEAT) & running;
  assign cool = IS_COOL;
  assign RUN_CRC = running;

  always @(posedge CLK)
    begin
      if (DATA_VALID)
	prev_DATA <= DATA;

      if (fin | AIRQ | ~RST)
	begin
	  if (fin & (~AIRQ) & RST)
	    IRQ <= 1;
	  else
	    IRQ <= 0;
	end

      if (!RST)
	begin
	  mask <= 0;
	  running <= 0;
	  ran <= 0;
	  CRC_TERM <= 0;
	end
      else
	begin
	  if (cool | error)
	    begin
	      mask <= 0;
	      if (! error)
		ran <= 0;
	    end
	  else
	    begin
	      if ((mask != 2'h3) &&
		  (DATA_VALID))
		mask <= mask +1;
	    end

	  if (!running)
	    begin
	      CRC_TERM <= 0;
	      if (((DATA_VALID & DATA) & prev_DATA) &&
		  (mask == 2'h3) & ~ran)
		/* Start-of-frame delimiter,
		   presumably. */
		running <= 1;
	    end
	  else
	    if (error) /* = (WAVEFRM_ERROR | MISSED_BEAT) */
	      begin
		CRC_TERM <= 1;
		running <= 0;
		if (! cool) /* To explicitely prevent assignment conflicts. */
		  ran <= 1;
	      end
	end
    end

endmodule

module recv_endpoint(input CLK,
		     input RST,
		     input CC_IRQ,
		     input CRC_SAFE,
		     input CRC_DONE,
		     input ROUND,
		     input [7:0] BITS,
		     input BITS_WRITE,
		     output [8:0] ADDR,
		     output [31:0] DATA,
		     output reg [10:0] RECV_LEN,
		     output DATA_WRITE,
		     output CC_AIRQ,
		     output reg NEW_PCKT,
		     output reg NEW_PCKT_VALID);
  reg [1:0] 		dataflip;
  reg [31:0]		data_reg;
  reg [8:0]		addr_reg;
  reg			airq, write;
  reg			terminating, terminating_delay;
  reg [10:0]		lenreg;
  reg			is_round;
  reg			crc_done_reg, crc_safe_reg;

  assign ADDR = addr_reg;
  assign DATA = data_reg;
  assign DATA_WRITE = write;
  assign CC_AIRQ = airq;

  always @(posedge CLK)
    if (!RST)
      begin
	lenreg <= 11'h7fc; /* -4 */
	dataflip <= 0;
	addr_reg <= 9'h1ff;
	airq <= 1;
	write <= 0;
	terminating <= 0;
	terminating_delay <= 0;
	NEW_PCKT <= 0;
	NEW_PCKT_VALID <= 0;
	is_round <= 0;
      end
    else
      begin
	/* WARNING: terminating_delay is a *critical* piece
	   of the puzzle! DO NOT, _UNDER_ANY_CIRCUMSTANCES_,
	   remove it! Especially if removing it seems like a
	   good idea, or it seems it has been made obsolete
	   by changes to code. Never remove it! */
	terminating_delay <= terminating;
	crc_done_reg <= CRC_DONE;
	crc_safe_reg <= CRC_SAFE;

	if (terminating | terminating_delay)
	  begin
	    write <= 0;
	    dataflip <= 0;
	    lenreg <= 11'h7fc; /* -4 */
	    addr_reg <= 9'h1ff;

	    if (terminating & ~terminating_delay)
	      RECV_LEN <= lenreg;

	    if (crc_done_reg)
	      begin
		airq <= 1;
		terminating <= 0;
		is_round <= 0;

		NEW_PCKT <= 1;
		if (crc_safe_reg & is_round /*& ~NEW_PCKT_VALID*/)
		  NEW_PCKT_VALID <= 1;
		else
		  NEW_PCKT_VALID <= 0;
	      end
	  end
	else
	  begin
	    is_round <= ROUND;
	    NEW_PCKT <= 0;
	    NEW_PCKT_VALID <= 0;
	    airq <= 0;

	    if (CC_IRQ)
	      terminating <= 1;
	      /* Important: if CC_IRQ is asserted, then
		 either data_reg is loaded with the CRC,
		 or there was an error in reception.
		 Either way, those last few (1-2) octets
		 do not have to be commited to memory.
		 Therefore, write has a little bit erratic
		 behaviour on this last octet, especially if
		 content has an odd length. */

	    if (BITS_WRITE)
	      begin
		case (dataflip)
		  2'h0: begin
		    data_reg[31:24] <= BITS;
		    write <= 0;
		    addr_reg <= addr_reg +1;
		  end
		  2'h1: begin
		    data_reg[23:16] <= BITS;
		  end
		  2'h2: begin
		    data_reg[15:8] <= BITS;
		  end
		  2'h3: begin
		    data_reg[7:0] <= BITS;
		    write <= 1;
		  end
		endcase // case (dataflip)
		dataflip <= dataflip +1;
		lenreg <= lenreg +1;
	      end
	    else
	      write <= 0;
	  end
      end

endmodule

module recv_integration(input fast_CLK,
			input slow_CLK,
			input RST,
			input WIRE,
			input IS_COOL,
			output [8:0] ADDR,
			output [31:0] DATA,
			output WRITE_DATA,
			output [10:0] RECV_LEN,
			output NEW_PCKT,
			output NEW_PCKT_VALID,
			output ACTIVE_HWY,
			output ACTIVE_LGT,
			/* --------- */
			output CRC_RST,
			output CRC_BIT,
			output CRC_WRITE,
			output CRC_TERM,
			input CRC_DONE,
			input CRC_SAFE);
  wire data_bit, data_vld, wvfrm_err, missed;
  wire [7:0] data_octet; wire write_octet, round;
  wire recv_rst, running;
  wire irq, airq;

  assign ACTIVE_LGT = data_vld | wvfrm_err | missed;
  assign ACTIVE_HWY = recv_rst;
  assign CRC_RST = ~airq;
  assign CRC_BIT = data_bit;
  assign CRC_WRITE = data_vld & running;

  eth_receiver first_stage(.fast_CLK(fast_CLK),
			   .slow_CLK(slow_CLK),
			   .RST(RST),
			   .DATA_WIRE(WIRE),
			   .DATA(data_bit),
			   .DATA_VALID(data_vld),
			   .WAVEFRM_ERROR(wvfrm_err),
			   .MISSED_BEAT(missed));
  bitcollector octetizer(.CLK(slow_CLK),
			 .RST(recv_rst),
			 .DATAI(data_bit),
			 .DATA_VALID(data_vld),
			 .ROUND(round),
			 .DATAO(data_octet),
			 .WRITE_DATAO(write_octet));
  recv_cc deframer(.CLK(slow_CLK),
		   .RST(RST),
		   .DATA(data_bit),
		   .DATA_VALID(data_vld),
		   .WAVEFRM_ERROR(wvfrm_err),
		   .MISSED_BEAT(missed),
		   .AIRQ(airq),
		   .IS_COOL(IS_COOL),
		   .RECV_RST(recv_rst),
		   .RUN_CRC(running),
		   .CRC_TERM(CRC_TERM),
		   .IRQ(irq));
  recv_endpoint second_stage(.CLK(slow_CLK),
			     .RST(RST),
			     .CC_IRQ(irq),
			     .CRC_SAFE(CRC_SAFE),
			     .CRC_DONE(CRC_DONE),
			     .ROUND(round),
			     .BITS(data_octet),
			     .BITS_WRITE(write_octet),
			     .ADDR(ADDR),
			     .DATA(DATA),
			     .DATA_WRITE(WRITE_DATA),
			     .RECV_LEN(RECV_LEN),
			     .CC_AIRQ(airq),
			     .NEW_PCKT(NEW_PCKT),
			     .NEW_PCKT_VALID(NEW_PCKT_VALID));

endmodule
