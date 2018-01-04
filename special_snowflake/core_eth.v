/*module top_level(input REF_CLK,
                 input OUT_RST,
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
  wire SYS_CLK, SYS_CLK_DELAYED, CPU_CLK, FRST_RST,
       ETH_SAMPLER_CLK, ETH_INPUT_CLK, ETH_OUTPUT_CLK;

  clockblock the_clocks(.REF_CLK(REF_CLK),
		  .OUT_RST(OUT_RST),
		  .SYS_CLK(SYS_CLK),
		  .SYS_CLK_DELAYED(SYS_CLK_DELAYED),
		  .CPU_CLK(CPU_CLK),
		  .ETH_SAMPLER_CLK(ETH_SAMPLER_CLK),
		  .ETH_INPUT_CLK(ETH_INPUT_CLK),
		  .ETH_OUTPUT_CLK(ETH_OUTPUT_CLK),
		  .FRST_RST(FRST_RST));

  chip the_chip(	.RST(FRST_RST),
		.CLK_p(),
		.CLK_n(SYS_CLK),
		.CLK_dp(),
		.CLK_dn(SYS_CLK_DELAYED),
		.CPU_CLK(CPU_CLK),
		.sampler_CLK(ETH_SAMPLER_CLK),
		.enc_CLK(REF_CLK),
		.recv_CLK(ETH_INPUT_CLK),
		.send_CLK(ETH_OUTPUT_CLK),
		// ---------------------
		.iCKE(iCKE),
		.iDQS(iDQS),
		.iDM(iDM),
		.iCS(iCS),
		.iCOMMAND(iCOMMAND),
		.iADDRESS(iADDRESS),
		.iBANK(iBANK),
		.iDQ(iDQ),
		.dCKE(dCKE),
		.dDQS(dDQS),
		.dDM(dDM),
		.dCS(dCS),
		.dCOMMAND(dCOMMAND),
		.dADDRESS(dADDRESS),
		.dBANK(dBANK),
		.dDQ(dDQ),
		.ETH_WIRE_RX(ETH_WIRE_RX),
		.ETH_WIRE_TX(ETH_WIRE_TX));

endmodule
*/

module chip(input RST,
	    input 	  CLK_p,
	    input 	  CLK_n,
	    input 	  CLK_dp,
	    input 	  CLK_dn,
	    input 	  CPU_CLK,
	    input 	  sampler_CLK,
	    input 	  enc_CLK,
	    input 	  recv_CLK,
	    input 	  send_CLK,
	    // -------------------
	    output 	  iCKE,
	    inout 	  iUDQS,
	    inout 	  iLDQS,
	    inout 	  iDM,
	    output 	  iCS,
	    output [2:0]  iCOMMAND,
	    output [12:0] iADDRESS,
	    output [1:0]  iBANK,
	    inout [15:0]  iDQ,
	    output 	  iODT,
	    output 	  dCKE,
	    inout 	  dUDQS,
	    inout 	  dLDQS,
	    inout 	  dDM,
	    output 	  dCS,
	    output [2:0]  dCOMMAND,
	    output [12:0] dADDRESS,
	    output [1:0]  dBANK,
	    inout [15:0]  dDQ,
	    output 	  dODT,
	    // -------------------
	    input 	  ETH_WIRE_RX,
	    output 	  ETH_WIRE_TX);
  reg [19:0] 		  rst_counter;

  wire [1:0] 		  w_write_fifo_cr, w_read_fifo_cw;
  wire 			  RST_CPU_pre;

  wire 			  eth_read, eth_write, eth_irq, eth_irq_valid,
			  eth_collision, eth_collision_ack;
  wire [31:0] 		  eth_send_data, eth_recv_data;

  wire 			  eth_ctrl_enstb;
  wire [31:0] 		  eth_ctrl_dataout;
  wire [23:0] 		  eth_ctrl_datain_short;

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
			      .mem_iUDQS(iUDQS),
			      .mem_iLDQS(iLDQS),
			      .mem_iDM(iDM),
			      .mem_iCS(iCS),
			      .mem_iCOMMAND(iCOMMAND),
			      .mem_iADDRESS(iADDRESS),
			      .mem_iBANK(iBANK),
			      .mem_iDQ(iDQ),
			      .mem_iODT(iODT),
			      .mem_dCKE(dCKE),
			      .mem_dUDQS(dUDQS),
			      .mem_dLDQS(dLDQS),
			      .mem_dDM(dDM),
			      .mem_dCS(dCS),
			      .mem_dCOMMAND(dCOMMAND),
			      .mem_dADDRESS(dADDRESS),
			      .mem_dBANK(dBANK),
			      .mem_dDQ(dDQ),
			      .mem_dODT(dODT),
			      // ----------------------
			      // ----------------------
			      .write_fifo_cr(w_write_fifo_cr),
			      .read_fifo_cw(w_read_fifo_cw),
			      // ----------------------
			      .data0_cr(eth_recv_data),
			      .data1_cr(0),
			      .data2_cr(0),
			      .data3_cr(0),
			      .ancill0_cr({eth_ctrl_dataout[23:0],
					   eth_irq_valid}),
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
			      .errack3_cw(),
			      .ph_len_0(eth_ctrl_datain_short),
			      .ph_len_1(),
			      .ph_len_2(),
			      .ph_len_3(),
			      .ph_dir_0(),
			      .ph_enstb_0(eth_ctrl_enstb),
			      .ph_dir_1(),
			      .ph_enstb_1(),
			      .ph_dir_2(),
			      .ph_enstb_2(),
			      .ph_dir_3(),
			      .ph_enstb_3());

  Steelhorse_Hyperfabric eth(.sampler_CLK(sampler_CLK),
			      .recv_CLK(recv_CLK),
			      .send_CLK(send_CLK),
			      .enc_CLK(enc_CLK),
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
			      .RUN(eth_ctrl_enstb),
			      .INTRFC_DATAIN({8'h0,eth_ctrl_datain_short}),
			      .INTRFC_DATAOUT(eth_ctrl_dataout));

  always @(posedge CPU_CLK)
    if (!RST)
      rst_counter <= 0;
//    else
//    if (!RST_CPU_pre)
//	rst_counter <= rst_counter +1;

endmodule // chip
