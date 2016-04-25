`timescale 1ns/1ps

`define x16
`define sq5E

module ram_dp_true_m(input [31:0] DataInA,
                     input [31:0] DataInB,
                     input [7:0]  AddressA,
                     input [7:0]  AddressB,
                     input 	  ClockA,
                     input 	  ClockB,
                     input 	  ClockEnA,
                     input 	  ClockEnB,
                     input 	  WrA,
                     input 	  WrB,
                     output [31:0] QA,
                     output [31:0] QB);
  reg [31:0]            r_data[255:0];
  reg [7:0] 		addr_regA, addr_regB;

  assign QA = r_data[addr_regA];
  assign QB = r_data[addr_regB];

  always @(posedge ClockA & ClockEnA)
    begin
      if (WrA)
        r_data[AddressA] <= DataInA;
      addr_regA <= AddressA;
    end

  always @(posedge ClockB & ClockEnB)
    begin
      if (WrB)
        r_data[AddressB] <= DataInB;
      addr_regB <= AddressB;
    end

endmodule

module iceram32(output [31:0] RDATA,
		input [7:0]   RADDR,
		input 	      RE,
		input 	      RCLKE,
		input 	      RCLK,
		output [31:0] WDATA,
		input [31:0]  MASK,
		input [7:0]   WADDR,
		input 	      WE,
		input 	      WCLKE,
		input 	      WCLK);
  ram_dp_true_m ram(.DataInA(),
		    .DataInB(WDATA),
		    .AddressA(RADDR),
		    .AddressB(WADDR),
		    .ClockA(RCLK & RE),
		    .ClockB(WCLK),
		    .ClockEnA(RCLKE),
		    .ClockEnB(WCLKE),
		    .WrA(1'b0),
		    .WrB(WE),
		    .QA(RDATA),
		    .QB());
endmodule // iceram32

module iceram16(output [15:0] RDATA,
		input [7:0]   RADDR,
		input 	      RE,
		input 	      RCLKE,
		input 	      RCLK,
		output [15:0] WDATA,
		input [15:0]  MASK,
		input [7:0]   WADDR,
		input 	      WE,
		input 	      WCLKE,
		input 	      WCLK);
  wire [15:0] 		      ignore;
  ram_dp_true_m ram(.DataInA(),
		    .DataInB({16'd0,WDATA}),
		    .AddressA(RADDR),
		    .AddressB(WADDR),
		    .ClockA(RCLK & RE),
		    .ClockB(WCLK),
		    .ClockEnA(RCLKE),
		    .ClockEnB(WCLKE),
		    .WrA(1'b0),
		    .WrB(WE),
		    .QA({ignore,RDATA}),
		    .QB());
endmodule // iceram16

`include "ddr.v"
`include "commands.v"
`include "state.v"
`include "initializer.v"
`include "integration.v"

`include "cpu_mcu2.v"

module GlaDOS;
  reg CLK_p, CLK_n, CLK_dp, CLK_dn, RST, CPU_CLK;
  reg [31:0] counter, minicounter, readcount, readcount2, readcount_r;
  reg display_intrfc;

  reg [31:0] data_read, transtest;

  wire [31:0]  user_req_address;
  wire 	       user_req_we, user_req;
  wire [31:0]  user_req_datain;
  reg         inhibit_ack;
  wire 	      user_req_ack;
  wire [31:0] user_req_dataout;

  wire 	      CKE, DQS, DM, CS;
  wire [2:0]  COMMAND;
  wire [12:0] ADDRESS;
  wire [1:0]  BANK;
  wire [15:0] DQ;

  reg [31:0]  cache_addr;
  reg 	      cache_we, tlb_we;
  reg 	      cache_en, cache_en_follow;
  reg [31:0]  cache_datao;
  wire [31:0] cache_datai;
  wire 	      cache_en_decoded, cache_busy, cache_MMU_FAULT;

  reg cache_vmem, cache_inhibit;

  assign cache_en_decoded = cache_en ^ cache_en_follow;

  ddr ddr_mem(.Clk(CLK_p),
	      .Clk_n(CLK_n),
	      .Cke(CKE),
	      .Cs_n(CS),
	      .Ras_n(COMMAND[2]),
	      .Cas_n(COMMAND[1]),
	      .We_n(COMMAND[0]),
	      .Ba(BANK),
	      .Addr(ADDRESS),
	      .Dm({DM,DM}),
	      .Dq(DQ),
	      .Dqs({DQS,DQS}));

  ddr_memory_controler ddr_mc(.CLK_n(CLK_n),
			      .CLK_p(CLK_p),
			      .CLK_dp(CLK_dp),
			      .CLK_dn(CLK_dn),
			      .RST(RST),
			      .CKE(CKE),
			      .COMMAND(COMMAND),
			      .ADDRESS(ADDRESS),
			      .BANK(BANK),
			      .DQ(DQ),
			      .DQS(DQS),
			      .DM(DM),
			      .CS(CS),
			      .user_req_address(user_req_address),
			      .user_req_we(user_req_we),
			      .user_req(user_req),
			      .user_req_datain(user_req_datain),
			      .user_req_ack(user_req_ack),
			      .user_req_dataout(user_req_dataout));

  snowball_cache
    cache_under_test(.CPU_CLK(CPU_CLK),
		     .MCU_CLK(CLK_n),
		     .RST(RST),
		     .cache_precycle_addr(cache_addr),
		     .cache_datao(cache_datao), // CPU perspective
		     .cache_datai(cache_datai), // CPU perspective
		     .cache_precycle_we(cache_we),
		     .cache_busy(cache_busy),
		     .cache_precycle_enable(cache_en_decoded),
//--------------------------------------------------
//--------------------------------------------------
		     .dma_mcu_access(1'b1),
		     .mem_addr(user_req_address),
		     .mem_we(user_req_we),
		     .mem_do_act(user_req),
		     .mem_dataintomem(user_req_datain),
		     .mem_ack(user_req_ack),
		     .mem_datafrommem(user_req_dataout),
//--------------------------------------------------
		     .VMEM_ACT(cache_vmem),
		     .cache_inhibit(cache_inhibit),
//--------------------------------------------------
		     .MMU_FAULT(cache_MMU_FAULT),
		     .WE_TLB(tlb_we));

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

  reg [11:0] u;
  initial
    begin
      RST <= 0;
      #14.875 RST <= 1;
      #400000;
      #50000;

      #20;
/*
      for (u=0;u<256;u=u+1)
        begin
          $display("cache_under_test.cachedat.ram.r_data[%x] = %x",
                   u, cache_under_test.cachedat.ram.r_data[u]);
        end
      for (u=0;u<256;u=u+1)
        begin
          $display("cache_under_test.cachetag.ram.r_data[%x] = %x",
                   u, cache_under_test.cachetag.ram.r_data[u]);
        end
*/
      $finish;
    end

  always @(posedge CPU_CLK)
    if (!RST)
      begin
	cache_addr <= 0; cache_datao <= 0;
	cache_we <= 0; tlb_we <= 0;
	cache_en <= 0; cache_en_follow <= 0;

        cache_vmem <= 0; cache_inhibit <= 0; counter <= 0;
      end
    else
      begin
        counter <= counter +1;
	cache_en_follow <= cache_en;

/*	case (counter)
	default:
	endcase*/

      end // else: !if(!_RST)

  always @(posedge CLK_n)
    if (!RST)
      begin
        minicounter <= 0;
      end
    else
      begin
	minicounter <= minicounter +1;
      end

  integer i;
  initial
    begin
      for (i=0;i<256;i=i+1)
        begin
	  if (i == 1)
            cache_under_test.cachedat.ram.r_data[i] <= 32'h5a5a0000;
	  else
            cache_under_test.cachedat.ram.r_data[i] <= 32'h5a5adada;
          cache_under_test.cachetag.ram.r_data[i] <= 0;
          cache_under_test.tlb.ram.r_data[i] <= 0;
          cache_under_test.tlbtag.ram.r_data[i] <= 0;
        end
      cache_under_test.tlbtag.ram.r_data[16] <= 16'h0080;
//      cache_under_test.tlbtag.ram.r_data[32] <= 16'h0080;
      cache_under_test.tlbtag.ram.r_data[48] <= 16'h0080;
      cache_under_test.tlbtag.ram.r_data[4] <= 16'h0080;
    end

endmodule // GlaDOS

