module Steelhorse_Hyperfabric(input sampler_CLK,
			      input 	    recv_CLK,
			      input 	    send_CLK,
			      input 	    enc_CLK,
			      input 	    lsab_CLK,
			      input 	    RST,
			      // --------------------
			      input 	    WIRE_RX,
			      output 	    WIRE_TX,
			      // --------------------
			      input [31:0]  DATA_SEND,
			      input [1:0]   LSAB_RECV_TURN,
			      input [1:0]   LSAB_SEND_TURN,
			      output [31:0] DATA_RECV,
			      output 	    WRITE_INTO_LSAB,
			      output 	    READ_FROM_LSAB,
			      output 	    IRQ,
			      output 	    IRQ_VLD,
			      output 	    ERROR,
			      input 	    ERROR_ACK,
			      input 	    RUN.
			      input [31:0]  INTRFC_DATAIN,
			      output [31:0] INTRFC_DATAOUT);
  wire 					    raw_write, raw_read, raw_irq,
					    raw_irq_vld, collison;
  wire [31:0] 				    data_raw_in;

  Steelhorse eth(.sampler_CLK(sampler_CLK),
		 .recv_CLK(recv_CLK),
		 .send_CLK(send_CLK),
		 .enc_CLK(enc_CLK),
		 .RST(RST),
		 .WIRE_RX(WIRE_RX),
		 .WIRE_TX(WIRE_TX),
		 .DATA_ADDR(),
		 .DATA_RECV(data_raw_in),
		 .WRITE_DATA_RECV(raw_write),
		 .DATA_SEND(DATA_SEND),
		 .READ_DATA_SEND(raw_read),
		 .NWPCKT_IRQ(raw_irq),
		 .NWPCKT_IRQ_VALID(raw_irq_vld),
		 .COLLISION(collision),
		 .RUN(RUN),
		 .BUSY(),
		 .INTRFC_DATAIN(INTRFC_DATAIN),
		 .INTRFC_DATAOUT(INTRFC_DATAOUT));

  sh_hf_adaptor eth_adaptor_recv(.CLK(lsab_CLK),
				 .RST(RST),
				 .LSAB_TURN(LSAB_RECV_TURN),
				 .DATA_FROM_ETH(data_raw_in),
				 .NEW_PCKT(raw_irq),
				 .NEW_PCKT_VALID(raw_irq_vld),
				 .WRITE_IN(raw_write),
				 .DATA_OUT(DATA_RECV),
				 .WRITE(WRITE_INTO_LSAB),
				 .IRQ(IRQ),
				 .IRQ_VLD(IRQ_VLD));
  sh_hf_adatpor_collision eth_adaptor_send(.CLK(lsab_CLK),
					   .RST(RST),
					   .LSAB_TURN(LSAB_SEND_TURN),
					   .COLLISION(collision),
					   .READ_LSAB_SH(raw_read),
					   .ERR_ACK(ERROR_ACK),
					   .ERR_ASKFOR(ERROR),
					   .READ_LSAB(READ_FROM_LSAB));

endmodule // Steelhorse_Hyperfabric
