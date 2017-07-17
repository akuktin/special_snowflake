`timescale 1ns/1ps

`include "test_inc.v"

// Memory module
`include "../mcu/commands.v"
`include "../mcu/state2.v"
`include "../mcu/initializer.v"
`include "../mcu/integration3.v"

// Cache
`include "../cache/cpu_mcu2.v"

// CPU
`include "../aexm/aexm_enable.v"
`include "../aexm/aexm_bpcu.v"
`include "../aexm/aexm_regf.v"
`include "../aexm/aexm_ctrl.v"
`include "../aexm/aexm_xecu.v"
`include "../aexm/aexm_ibuf.v"
`include "../aexm/aexm_edk32.v"
//`include "aexm/aexm_aux.v"

// LSAB
`include "../hyperfabric/lsab.v"

// Hyperfabric
`include "../hyperfabric/transport.v"
`include "../hyperfabric/mvblck_todram.v"
`include "../hyperfabric/mvblck_frdram.v"
`include "../hyperfabric/mvblck_lsab_dram.v"

// Special Snowflake
`include "../special_snowflake/core.v"
`include "../special_snowflake/core_eth.v"

// Steelhorse]
`include "../steelhorse/eth_recv.v"
`include "../steelhorse/eth_send.v"
`include "../steelhorse/eth.v"
`include "../steelhorse/hf_adaptor.v"
`include "../steelhorse/steelhorse.v"

module GLaDOS;
  reg record; reg [3:0] halt; reg [31:0] record_buff;
  reg sampler_CLK, send_CLK, recv_CLK, _RST, send_RST, do_halt, real_new_pckt,
      enc_CLK;
  reg CLK_p, CLK_n, CLK_dp, CLK_dn, CPU_CLK;
  initial
    forever
      begin
        #1.5 CLK_n <= 0; CLK_p <= 1;
        #1.5 CLK_dp <= 1; CLK_dn <= 0;
        #1.5 CLK_n <= 1; CLK_p <= 0;
        #1.5 CLK_dp <= 0; CLK_dn <= 1;
      end
  initial
    forever
      begin
        #1.5;
        #4.5 CPU_CLK <= 1;
        #3   CPU_CLK <= 0;
      end

  reg [15:0] DATAIN[511:0], DATAOUT[511:0];
  wire __WIRE_1, __WIRE_2;
  reg __WIRE_3;
  wire [9:0] addr_send, addr_recv;
  wire [31:0] idataout_send, idataout_recv;
  reg [31:0] data_in, data_in_pre;
  wire [31:0] data_out;
  reg [15:0] idatain_send;
  reg [9:0] iaddr_send, iaddr_recv;
  reg [15:0] irecv_hldr, isend_hldr;
  wire write_data_in, read_data_out, new_pckt, sendreg_an;
  reg sendreg_rq;
  reg RUN_sig;
/*
  assign data_in = addr_send[9] ?
                   {DATAIN[{addr_send[6:0],1'b0}],
                    DATAIN[{addr_send[6:0],1'b1}]} :
                   0;
*/

  wire        iCKE, iDQS, iDM, iCS;
  wire [2:0]  iCOMMAND;
  wire [12:0] iADDRESS;
  wire [1:0]  iBANK;
  wire [15:0] iDQ;
  wire        dCKE, dDQS, dDM, dCS;
  wire [2:0]  dCOMMAND;
  wire [12:0] dADDRESS;
  wire [1:0]  dBANK;
  wire [15:0] dDQ;

  ddr i_ddr_mem(.Clk(CLK_p),
		.Clk_n(CLK_n),
		.Cke(iCKE),
		.Cs_n(iCS),
		.Ras_n(iCOMMAND[2]),
		.Cas_n(iCOMMAND[1]),
		.We_n(iCOMMAND[0]),
		.Ba(iBANK),
		.Addr(iADDRESS),
		.Dm({iDM,iDM}),
		.Dq(iDQ),
		.Dqs({iDQS,iDQS}));

  ddr d_ddr_mem(.Clk(CLK_p),
		.Clk_n(CLK_n),
		.Cke(dCKE),
		.Cs_n(dCS),
		.Ras_n(dCOMMAND[2]),
		.Cas_n(dCOMMAND[1]),
		.We_n(dCOMMAND[0]),
		.Ba(dBANK),
		.Addr(dADDRESS),
		.Dm({dDM,dDM}),
		.Dq(dDQ),
		.Dqs({dDQS,dDQS}));

  Steelhorse send(.sampler_CLK(sampler_CLK),
		  .enc_CLK(enc_CLK),
		  .recv_CLK(recv_CLK),
		  .send_CLK(send_CLK),
		  .RST(_RST),
		  .WIRE_RX(__WIRE_3),
		  .WIRE_TX(__WIRE_1),
		  .DATA_ADDR(addr_send),
		  .DATA_RECV(),
		  .WRITE_DATA_RECV(),
		  .DATA_SEND(data_in),
		  .READ_DATA_SEND(read_data_out),
		  .NWPCKT_IRQ(),
		  .NWPCKT_IRQ_VALID(),
		  .RUN(RUN_sig),
		  .BUSY(),
		  .INTRFC_DATAIN({16'h0,idatain_send}),
		  .INTRFC_DATAOUT(idataout_send));

  chip mut(.RST(_RST),
	   .CLK_p(CLK_p),
	   .CLK_n(CLK_n),
	   .CLK_dp(CLK_dp),
	   .CLK_dn(CLK_dn),
	   .CPU_CLK(CPU_CLK),
	   .sampler_CLK(sampler_CLK),
	   .recv_CLK(recv_CLK),
	   .send_CLK(send_CLK),
	   .enc_CLK(enc_CLK),
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
	   .ETH_WIRE_RX(__WIRE_1),
	   .ETH_WIRE_TX(__WIRE_2));

  Steelhorse recv(.sampler_CLK(sampler_CLK),
		  .recv_CLK(recv_CLK),
		  .send_CLK(send_CLK),
		  .enc_CLK(enc_CLK),
		  .RST(_RST),
		  .WIRE_RX(__WIRE_2),
		  .WIRE_TX(),
		  .DATA_ADDR(addr_recv),
		  .DATA_RECV(data_out),
		  .WRITE_DATA_RECV(write_data_in),
		  .DATA_SEND(),
		  .NWPCKT_IRQ(),
		  .NWPCKT_IRQ_VALID(new_pckt),
		  .RUN(),
		  .BUSY(),
		  .INTRFC_DATAIN(),
		  .INTRFC_DATAOUT(idataout_recv));

  initial forever begin #5 sampler_CLK <= 1; #5 sampler_CLK <= 0; record_buff <= record_buff +1; end
  initial forever begin #50 send_CLK <= 1; #50 send_CLK <= 0; end
  initial forever begin #25 enc_CLK <= 1; #25 enc_CLK <= 0; end
  initial forever begin #40 recv_CLK <= 1; #40 recv_CLK <= 0; end

  initial
    begin
      record_buff <= 0; real_new_pckt <= 1;
      do_halt <= 0; __WIRE_3 <= 0; record <= 0; halt <= 0;
      iaddr_send <= 10'h009; iaddr_recv <= 10'h008;
      _RST <= 0; RUN_sig <= 0;
      #200;
      _RST <= 1;
      #400000;
      mut.rst_counter <= 20'hfff00;
//      #1800;
      record <= 1;
      #200;
//      #4000;
      #20;
      iaddr_send <= 10'h00a;
      RUN_sig <= 1;
      idatain_send <= 16'h0010;
      #120 iaddr_send <= 10'h009;
      #60;
      #5400 __WIRE_3 <= 1;
      #200 __WIRE_3 <= 0;

      #180000;
      #20;
      iaddr_send <= 10'h00a;
//      RUN_sig <= 0;
      idatain_send <= 16'h0005;
      #120 iaddr_send <= 10'h009;
      #60;

      #300000 record <= 0;
      #200;
      $display("bad_end");
      $display("\t%x %x %x %x  %x %x %x %x\n\t%x %x %x %x  %x %x %x %x",
	       DATAOUT[0], DATAOUT[1], DATAOUT[2], DATAOUT[3],
	       DATAOUT[4], DATAOUT[5], DATAOUT[6], DATAOUT[7],
	       DATAOUT[8], DATAOUT[9], DATAOUT[10],DATAOUT[11],
	       DATAOUT[12],DATAOUT[13],DATAOUT[14],DATAOUT[15]);
      $display("\t%x %x %x %x  %x %x %x %x\n\t%x %x %x %x  %x %x %x %x",
	       DATAOUT[16],DATAOUT[17],DATAOUT[18],DATAOUT[19],
	       DATAOUT[20],DATAOUT[21],DATAOUT[22],DATAOUT[23],
	       DATAOUT[24],DATAOUT[25],DATAOUT[26],DATAOUT[27],
	       DATAOUT[28],DATAOUT[29],DATAOUT[30],DATAOUT[31]);
      $finish;
     end

   initial
     begin
       DATAIN[0] = 16'h1234;
       DATAIN[1] = 16'h5678;
       DATAIN[2] = 16'h9abc;
       DATAIN[3] = 16'hdef0;
       DATAIN[4] = 16'h0123;
       DATAIN[5] = 16'h4567;
       DATAIN[6] = 16'h89ab;
       DATAIN[7] = 16'hcdef;
    end

  always @(negedge write_data_in)
    if (~addr_recv[9])
      begin
        DATAOUT[{addr_recv[6:0],1'b0}] <= data_out[31:16];
        DATAOUT[{addr_recv[6:0],1'b1}] <= data_out[15:0];
      end

  always @(posedge CPU_CLK)
    if (record && 0)
      begin
	$display("PC %x mem[0x03] %x mem[0x04] %x",
		 mut.core.cpu.bpcu.rPC,
		 mut.core.cpu.regf.mBRAM[3],
		 mut.core.cpu.regf.mARAM[4]);
      end

  always @(posedge recv_CLK)
    if (new_pckt)
      begin
	if (real_new_pckt)
	  begin
	    do_halt <= 1;
	  end
	else
	  begin
	    real_new_pckt <= 1;
	    $display("reception successfull.");
	  end
      end

  always @(posedge send_CLK)
    begin
    if (read_data_out)
      begin
	data_in_pre <= {DATAIN[{addr_send[6:0],1'b0}],
                        DATAIN[{addr_send[6:0],1'b1}]};
      end
    data_in <= data_in_pre;

    if (record)
      begin
//	$display("");
	if ((halt != 4'h0) || do_halt)
	  begin
	    if (halt == 4'h7)
	      begin
		$display("good_end");
		$display("\t%x %x %x %x  %x %x %x %x\n\t%x %x %x %x  %x %x %x %x",
			 DATAOUT[0], DATAOUT[1], DATAOUT[2], DATAOUT[3],
			 DATAOUT[4], DATAOUT[5], DATAOUT[6], DATAOUT[7],
			 DATAOUT[8], DATAOUT[9], DATAOUT[10],DATAOUT[11],
			 DATAOUT[12],DATAOUT[13],DATAOUT[14],DATAOUT[15]);
		$display("\t%x %x %x %x  %x %x %x %x\n\t%x %x %x %x  %x %x %x %x",
			 DATAOUT[16],DATAOUT[17],DATAOUT[18],DATAOUT[19],
			 DATAOUT[20],DATAOUT[21],DATAOUT[22],DATAOUT[23],
			 DATAOUT[24],DATAOUT[25],DATAOUT[26],DATAOUT[27],
			 DATAOUT[28],DATAOUT[29],DATAOUT[30],DATAOUT[31]);
		$display("");
		$display("\t%x %x %x %x  %x %x %x %x\n\t%x %x %x %x  %x %x %x %x",
			 DATAOUT[32],DATAOUT[33],DATAOUT[34],DATAOUT[35],
			 DATAOUT[36],DATAOUT[37],DATAOUT[38],DATAOUT[39],
			 DATAOUT[40],DATAOUT[41],DATAOUT[42],DATAOUT[43],
			 DATAOUT[44],DATAOUT[45],DATAOUT[46],DATAOUT[47]);
		$display("\t%x %x %x %x  %x %x %x %x\n\t%x %x %x %x  %x %x %x %x",
			 DATAOUT[48],DATAOUT[49],DATAOUT[50],DATAOUT[51],
			 DATAOUT[52],DATAOUT[53],DATAOUT[54],DATAOUT[55],
			 DATAOUT[56],DATAOUT[57],DATAOUT[58],DATAOUT[59],
			 DATAOUT[60],DATAOUT[61],DATAOUT[62],DATAOUT[63]);
		$display("");
		$display("\t%x %x %x %x  %x %x %x %x\n\t%x %x %x %x  %x %x %x %x",
			 DATAOUT[64],DATAOUT[65],DATAOUT[66],DATAOUT[67],
			 DATAOUT[68],DATAOUT[69],DATAOUT[70],DATAOUT[71],
			 DATAOUT[72],DATAOUT[73],DATAOUT[74],DATAOUT[75],
			 DATAOUT[76],DATAOUT[77],DATAOUT[78],DATAOUT[79]);
		$display("\t%x %x %x %x  %x %x %x %x\n\t%x %x %x %x  %x %x %x %x",
			 DATAOUT[80],DATAOUT[81],DATAOUT[82],DATAOUT[83],
			 DATAOUT[84],DATAOUT[85],DATAOUT[86],DATAOUT[87],
			 DATAOUT[88],DATAOUT[89],DATAOUT[90],DATAOUT[91],
			 DATAOUT[92],DATAOUT[93],DATAOUT[94],DATAOUT[95]);
		$display("");
		$display("\t%x %x %x %x  %x %x %x %x\n\t%x %x %x %x  %x %x %x %x",
			 DATAOUT[96],DATAOUT[97],DATAOUT[98],DATAOUT[99],
			 DATAOUT[100],DATAOUT[101],DATAOUT[102],DATAOUT[103],
			 DATAOUT[104],DATAOUT[105],DATAOUT[106],DATAOUT[107],
			 DATAOUT[108],DATAOUT[109],DATAOUT[110],DATAOUT[111]);
		$display("\t%x %x %x %x  %x %x %x %x\n\t%x %x %x %x  %x %x %x %x",
			 DATAOUT[112],DATAOUT[113],DATAOUT[114],DATAOUT[115],
			 DATAOUT[116],DATAOUT[117],DATAOUT[118],DATAOUT[119],
			 DATAOUT[120],DATAOUT[121],DATAOUT[122],DATAOUT[123],
			 DATAOUT[124],DATAOUT[125],DATAOUT[126],DATAOUT[127]);
		$display("recv_len: %x", idataout_recv);
		$display("send_buff: %x", idataout_send);
		$finish;
	      end
	    else
	      halt <= halt +1;
	  end
      end
    end

  integer i;
  initial
    begin
      for (i=0;i<256;i=i+1)
        begin
          mut.core.i_cache.cachedat.ram.r_data[i] <= 0;
          mut.core.i_cache.cachetag.ram.r_data[i] <= 0;
          mut.core.i_cache.tlb.ram.r_data[i] <= 0;
          mut.core.i_cache.tlbtag.ram.r_data[i] <= 0;
          mut.core.d_cache.cachedat.ram.r_data[i] <= 0;
          mut.core.d_cache.cachetag.ram.r_data[i] <= 0;
          mut.core.d_cache.tlb.ram.r_data[i] <= 0;
          mut.core.d_cache.tlbtag.ram.r_data[i] <= 0;
        end // for (i=0;i<256;i=i+1)

      mut.core.d_cache.cachedat.ram.r_data[4] <= 32'hffff_ffff;
      mut.core.cpu.regf.mARAM[27] <= 32'h0000_0000;
      mut.core.cpu.regf.mBRAM[27] <= 32'h0000_0000;
      mut.core.cpu.regf.mDRAM[27] <= 32'h0000_0000;

      mut.core.cpu.regf.mARAM[8] <= 32'h8800_00c0;
      mut.core.cpu.regf.mBRAM[8] <= 32'h8800_00c0;
      mut.core.cpu.regf.mDRAM[8] <= 32'h8800_00c0;

      mut.core.cpu.regf.mARAM[9] <= 32'hc000_0024;
      mut.core.cpu.regf.mBRAM[9] <= 32'hc000_0024;
      mut.core.cpu.regf.mDRAM[9] <= 32'hc000_0024;

      mut.core.cpu.regf.mARAM[10] <= 32'hbc00_0014;
      mut.core.cpu.regf.mBRAM[10] <= 32'hbc00_0014;
      mut.core.cpu.regf.mDRAM[10] <= 32'hbc00_0014;

      mut.core.cpu.regf.mARAM[11] <= 32'h8800_0014;
      mut.core.cpu.regf.mBRAM[11] <= 32'h8800_0014;
      mut.core.cpu.regf.mDRAM[11] <= 32'h8800_0014;

      mut.core.cpu.regf.mARAM[12] <= 32'hc000_0020;
      mut.core.cpu.regf.mBRAM[12] <= 32'hc000_0020;
      mut.core.cpu.regf.mDRAM[12] <= 32'hc000_0020;

//`include "test_ss_core_eth_send_prog.bin"
`include "test_ss_core_eth_recv_prog.bin"
    end
/*
  always @(posedge send_CLK)
    if (record)
      #3
	$display("__WIRE_1: %x", __WIRE_1);
*/
/*
  always @(negedge send_CLK)
    if (record)
      #3
	$display("__WIRE_1: %x --", __WIRE_1);
*/

  always @(posedge mut.core.cpu.gclk)
    if (mut.core.cpu.aexm_icache_precycle_enable &&
	(!mut.core.cpu.grst) && 0)
      begin
	$display("icache addr %x reg[4] %x",
		 mut.core.cpu.aexm_icache_precycle_addr,
		 mut.core.cpu.regf.mARAM[4]);
      end

  always @(posedge mut.core.empty.CLK)
    if (mut.core.empty.RST &&
	(! mut.core.empty.am_working) &&
	mut.core.empty.ISSUE)
      $display("START_ADDRESS %x", mut.core.empty.START_ADDRESS);

  always @(posedge mut.core.dma_interlink.CLK)
    if (mut.core.dma_interlink.RST)
      begin
	if (mut.core.dma_interlink.read_dma_r &&
	    mut.core.dma_interlink.out[63]) begin
	  $display("OUT DMA: %x_%x_%x",
		   mut.core.dma_interlink.out[65:64],
		   mut.core.dma_interlink.out[63:32],
		   mut.core.dma_interlink.out[31:0]);
	end

	if (mut.core.dma_interlink.we_pre &&
	    (!mut.core.dma_interlink.WRITE_DMA))
	  $display("IN--CPU: --%x_%x",
		   mut.core.dma_interlink.IN_CPU[63:32],
		   mut.core.dma_interlink.IN_CPU[31:0]);

	if (mut.core.dma_interlink.we &&
	    (!mut.core.dma_interlink.we_dma))
	  $display("IN  CPU: %x_%x_%x",
		   mut.core.dma_interlink.in_r[65:64],
		   mut.core.dma_interlink.in_r[63:32],
		   mut.core.dma_interlink.in_r[31:0]);
      end

  always @(posedge mut.core.scheduler.CLK)
    if (mut.core.scheduler.RST)
      begin
	if (mut.core.scheduler.GO)
	  $display("new_addr_high %x test %x %x/%x",
		   mut.core.scheduler.new_addr_high,
		   mut.core.scheduler.is_restart_r,
		   mut.core.scheduler.EXEC_OLD_ADDR[31:8],
		   mut.core.scheduler.saved_mem_addr);

	if ((mut.core.scheduler.enter_stage_1) ||
	    (mut.core.scheduler.posedge_EXEC_READY &&
	     mut.core.scheduler.EXEC_RESTART_OP))
	  $display("new_addr_low %x test %x %x/%x",
		   mut.core.scheduler.new_addr_low,
		   (mut.core.scheduler.posedge_EXEC_READY &&
		    mut.core.scheduler.EXEC_RESTART_OP),
		   mut.core.scheduler.EXEC_OLD_ADDR[7:0],
		   mut.core.scheduler.MEM_R_DATA[7:0]);
      end

	////////////////////////////

  always @(posedge mut.core.restarter.CLK)
    if (mut.core.restarter.RST)
      begin
	if (mut.core.restarter.state[0])
	  $display("NEW_ADDR %x_%x",
		   mut.core.restarter.NEW_ADDR[31:12],
		   mut.core.restarter.NEW_ADDR[11:0]);
      end // if (RST)

  always @(posedge mut.eth.eth.eth.recv.second_stage.CLK)
    if (mut.eth.eth.eth.recv.second_stage.RST &&
	(mut.eth.eth.eth.recv.second_stage.terminating |
	 mut.eth.eth.eth.recv.second_stage.terminating_delay) &&
	mut.eth.eth.eth.recv.second_stage.crc_done_reg)
      begin
	if (mut.eth.eth.eth.recv.second_stage.crc_safe_reg &&
	    mut.eth.eth.eth.recv.second_stage.is_round)
	  $display("STEELHORSE %x RECEIVE good packet", 2'h1);
	else
	  $display("STEELHORSE %x RECEIVE bad packet", 2'h1);
      end

  always @(posedge mut.eth.eth.send_CLK)
    if (mut.eth.eth.RST &&
	(mut.eth.eth.signal1 ^
	 mut.eth.eth.signal2))
      $display("STEELHORSE %x BEGIN execution of command", 2'h1);

  always @(posedge send.eth.recv.second_stage.CLK)
    if (send.eth.recv.second_stage.RST &&
	(send.eth.recv.second_stage.terminating |
	 send.eth.recv.second_stage.terminating_delay) &&
	send.eth.recv.second_stage.crc_done_reg)
      begin
	if (send.eth.recv.second_stage.crc_safe_reg &&
	    send.eth.recv.second_stage.is_round)
	  $display("STEELHORSE %x RECEIVE good packet", 2'h0);
	else
	  $display("STEELHORSE %x RECEIVE bad packet", 2'h0);
      end

  always @(posedge send.send_CLK)
    if (send.RST && (send.signal1 ^ send.signal2))
      $display("STEELHORSE %x BEGIN execution of command", 2'h0);

  always @(posedge recv.eth.recv.second_stage.CLK)
    if (recv.eth.recv.second_stage.RST &&
	(recv.eth.recv.second_stage.terminating |
	 recv.eth.recv.second_stage.terminating_delay) &&
	recv.eth.recv.second_stage.crc_done_reg)
      begin
	if (recv.eth.recv.second_stage.crc_safe_reg &&
	    recv.eth.recv.second_stage.is_round)
	  $display("STEELHORSE %x RECEIVE good packet", 2'h2);
	else
	  $display("STEELHORSE %x RECEIVE bad packet", 2'h2);
      end

  always @(posedge recv.send_CLK)
    if (recv.RST && (recv.signal1 ^ recv.signal2))
      $display("STEELHORSE %x BEGIN execution of command", 2'h2);

endmodule // GLaDOS
