`define steelhorse_lsab_cr_slot 2'h0
`define steelhorse_lsab_cw_slot 2'h0

module sh_hf_adaptor(input CLK,
		    input 	  RST,
		    input [1:0]   LSAB_TURN,
		    input [31:0]  DATA_FROM_ETH,
		    input 	  NEW_PCKT,
		    input 	  NEW_PCKT_VALID,
		    input 	  WRITE_IN,
		    output [31:0] DATA_OUT,
		    output reg 	  WRITE,
		    output reg 	  IRQ,
		    output reg 	  IRQ_VLD);

  /* This is needed because Steelhorse asserts IRQ some cycles after
   * asserting the last write. It only performs writes into LSAB. Reads
   * are properly handled by Steelhorse. */

  /* Even though, in principle, I should expend extra time to remove the
   * exception where Steelhorse writes the CRC when it receives a packet
   * whose length is divisible by four, that is very difficult to do.
   * The receiver in Steelhorse is built in such a way that it can only
   * detect the frame-end pulse after signalling the last octet is to
   * be written. OTOH, the hyperfabric LSAB requires the IRQ to be asserted
   * together with the last data word. I'm in a gap. Fortunately, Steelhorse
   * has proper signalling of the frame length, so the data consumer is
   * guarrantied to get the correct frame length communicated to it
   * out-of-band with the hyperfabric switch. That solves that problem.
   * The only real wart that will come out of this is that the CPU program
   * will have to allocate a buffer 4 bytes larger than it otherwise would
   * have and order a transaction 4 bytes (one word) longer that it other-
   * wise would. Overall, I would say that is acceptable. */

  reg [31:0] 			  holder;
  reg 				  NEW_PCKT_prev, is_NEW_PCKT, write_holder,
				  holder_full, f_write_r;

  wire 				  my_turn, write, w_in, w_out;

  // MY_SLOT is a compile-time constant
  assign my_turn = LSAB_TURN == `steelhorse_lsab_cr_slot;

  assign write = WRITE_IN;
  assign DATA_OUT = holder;

  assign w_in  = write;
  assign w_out = (write || is_NEW_PCKT) && holder_full;

  always @(posedge CLK)
    if (!RST)
      begin
	holder <= 0; NEW_PCKT_prev <= 0; is_NEW_PCKT <= 0;
	write_holder <= 0; holder_full <= 0; f_write_r <= 0;
      end
    else
      begin
	NEW_PCKT_prev <= NEW_PCKT;

	is_NEW_PCKT <= NEW_PCKT && (!NEW_PCKT_prev);
	if (NEW_PCKT && (!NEW_PCKT_prev))
	  IRQ_VLD <= NEW_PCKT_VALID;

	if (is_NEW_PCKT)
	  IRQ <= 1;
	else if (my_turn) // else is actually important here
	  IRQ <= 0;

	if (w_in)
	  write_holder <= 1;
	else if (my_turn) // else is actually important here
	  write_holder <= 0;

	if (write_holder && my_turn)
	  holder <= DATA_FROM_ETH;

	if (w_out)
	  WRITE <= 1;
	else if (my_turn) // else is actually important here
	  WRITE <= 0;

	if (IRQ && my_turn)
	  begin
	    holder_full <= 0;
	    f_write_r <= 0;
	  end
	else
	  begin
	    if (write)
	      f_write_r <= 1;

	    if (f_write_r && my_turn)
	      holder_full <= 1;
	  end
      end

endmodule

module sh_hf_adapter_collision(input CLK,
			       input 	   RST,
			       input [1:0] LSAB_TURN,
			       input 	   COLLISION,
			       input 	   READ_LSAB_SH,
			// -------------------------------
			       input 	   ERR_ACK,
			       output 	   ERR_ASKFOR,
			// -------------------------------
			       output 	   READ_LSAB);

  reg [6:0] drain_counter;

  wire 	    read_lsab_err, my_turn;

  assign my_turn = LSAB_TURN == `steelhorse_lsab_cw_slot;
  assign read_lsab_err = !drain_counter[6];
  assign READ_LSAB = read_lsab_err || READ_LSAB_SH;

  always @(posedge CLK)
    if (!RST)
      begin
	drain_counter <= 7'h40;
	ERR_ASKFOR <= 0;
      end
    else
      begin
	if (READ_LSAB && my_turn && !drain_counter[6])
	  drain_counter <= drain_counter +1;

	if (ERR_ASKFOR && ERR_ACK)
	  drain_counter <= 0;

	if (COLLISION)
	  ERR_ASKFOR <= 1;
	else if (ERR_ACK)
	  ERR_ASKFOR <= 0;
      end

endmodule // sh_hf_adapter_cw
