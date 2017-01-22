module chip(input RST,
	    input 	  CLK_p,
	    input 	  CLK_n,
	    input 	  CLK_dp,
	    input 	  CLK_dn,
	    input 	  CPU_CLK,
	    // -------------------
	    output 	  iCKE,
	    output 	  iDQS,
	    inout 	  iDM,
	    output 	  iCS,
	    output [2:0]  iCOMMAND,
	    output [12:0] iADDRESS,
	    output [1:0]  iBANK,
	    inout [15:0]  iDQ,
	    output 	  dCKE,
	    output 	  dDQS,
	    inout 	  dDM,
	    output 	  dCS,
	    output [2:0]  dCOMMAND,
	    output [12:0] dADDRESS,
	    output [1:0]  dBANK,
	    inout [15:0]  dDQ,
	    // -------------------
	    input 	  ETH_WIRE_RX,
	    output 	  ETH_WIRE_TX);
  reg [19:0] 		  rst_counter;

  wire [1:0] 		  w_write_fifo_cr, w_read_fifo_cw;
  wire 			  RST_CPU_pre;

  assign RST_CPU_pre = rst_counter[19];

  special_snowflake_core core(.RST(RST),
			      .RST_CPU_pre(RST_CPU_pre),
			      .CLK_p(CLK_p),
			      .CLK_n(CLK_n),
			      .CLK_dp(CLK_dp),
			      .CLK_dn(CLK_dn),
			      .CPU_CLK(CPU_CLK),
			      // ----------------------
			      .mem_iCKE(iCKE),
			      .mem_iDQS(iDQS),
			      .mem_iDM(iDM),
			      .mem_iCS(iCS),
			      .mem_iCOMMAND(iCOMMAND),
			      .mem_iADDRESS(iADDRESS),
			      .mem_iBANK(iBANK),
			      .mem_iDQ(iDQ),
			      .mem_dCKE(dCKE),
			      .mem_dDQS(dDQS),
			      .mem_dDM(dDM),
			      .mem_dCS(dCS),
			      .mem_dCOMMAND(dCOMMAND),
			      .mem_dADDRESS(dADDRESS),
			      .mem_dBANK(dBANK),
			      .mem_dDQ(dDQ),
			      // ----------------------
			      // ----------------------
			      .write_fifo_cr(w_write_fifo_cr),
			      .read_fifo_cw(w_read_fifo_cw),
			      // ----------------------
			      .data0_cr(eth_recv_data),
			      .data1_cr(0),
			      .data2_cr(0),
			      .data3_cr(0),
			      .ancill0_cr({2'h0,eth_irq_valid}),
			      .ancill1_cr(0),
			      .ancill2_cr(0),
			      .ancill3_cr(0),
			      .write0_cr(eth_write),
			      .write1_cr(0),
			      .write2_cr(0),
			      .write3_cr(0),
			      .int0_cr(eth_irq),
			      .int1_cr(0),
			      .int2_cr(0),
			      .int3_cr(0),
			      // ----------------------
			      .read0_cw(eth_read),
			      .read1_cw(0),
			      .read2_cw(0),
			      .read3_cw(0),
			      .data0_cw(eth_send_data),
			      .data1_cw(),
			      .data2_cw(),
			      .data3_cw(),
			      .err0_cw(eth_collision),
			      .err1_cw(0),
			      .err2_cw(0),
			      .err3_cw(0),
			      .errack0_cw(eth_collision_ack),
			      .errack1_cw(),
			      .errack2_cw(),
			      .errack3_cw());

  wire 			  eth_read, eth_write, eth_irq, eth_irq_valid,
			  eth_collision, eth_collision_ack;
  wire [31:0] 		  eth_send_data, eth_recv_data;

  Steelhorse_Hyperfabric eth(.sampler_CLK(),
			      .recv_CLK(),
			      .send_CLK(),
			      .enc_CLK(),
			      .lsab_CLK(CLK_n),
			      .RST(RST),
			      // --------------------
			      .WIRE_RX(ETH_WIRE_RX),
			      .WIRE_TX(ETH_WIRE_TX),
			      // --------------------
			      .DATA_SEND(eth_send_data),
			      .LSAB_RECV_TURN(w_write_fifo_cr),
			      .LSAB_SEND_TURN(w_read_fifo_cw),
			      .DATA_RECV(eth_recv_data),
			      .WRITE_INTO_LSAB(eth_write),
			      .READ_FROM_LSAB(eth_read),
			      .IRQ(eth_irq),
			      .IRQ_VLD(eth_irq_valid),
			      .ERROR(eth_collision),
			      .ERROR_ACK(eth_collision_ack),
			      .RUN(), // input, strobe
			      .INTRFC_DATAIN(), // input
			      .INTRFC_DATAOUT()); // output

  always @(posedge CPU_CLK)
    if (!RST)
      rst_counter <= 0;
    else
      if (!RST_CPU_pre)
	rst_counter <= rst_counter +1;

endmodule // chip
