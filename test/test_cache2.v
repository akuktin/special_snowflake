`timescale 1ps/1ps

`include "test_inc.v"

`include "../mcu/state2.v"
`include "../mcu/initializer.v"
`include "../mcu/integration3.v"

`include "../cache/cpu_mcu2.v"

`define delay     32'h0000_0001
`define longdelay 32'h0000_0003

module testsuite(input CLK, // CPU_CLK
		 input 		   RST,
		 input [31:0] 	   counter,
		 input [31:0] 	   cache_datai,
		 input 		   cache_busy,
		 input 		   mmu_fault,
		 output reg [31:0] cache_pc_addr,
		 output reg [31:0] cache_datao,
		 output reg 	   cache_pc_we,
		 output reg 	   cache_pc_en,
		 output reg 	   we_tlb,
		 output 	   fake_miss);
  reg [31:0] 			   test_addr[512:0], test_waittime[512:0],
				   test_datao[512:0], test_datai[512:0],
				   test_timeout[512:0],
				   test_fakemissb[512:0], test_fakemisse[512:0],
				   test_timeout_comp[512:0];
  reg 				   test_we[512:0], test_caredatai[512:0],
				   test_tlb[512:0];

  reg [31:0] 			   time_for_next_test, test_num, test_seen,
				   test_issued, test_num_delay,
				   fake_miss_begin, fake_miss_end;
  reg 				   just_issued_test;
  wire 				   time_to_test, waiting_for_result, fake_miss;

  integer 			   i;
  initial
    begin
      i = 0;
      /* write simple*/ // 0x00
      test_addr[i]      <= 32'h0000_0010;test_datao[i]    <= 32'h5454_6900;
      test_we[i]        <= 1'b1;         test_waittime[i] <= 32'd10;
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h0000_0000;
      test_timeout[i]   <= 32'd10;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b write/read, same idx */ // 0x01
      test_addr[i]      <= 32'h0000_0000;test_datao[i]    <= 32'h5454_6901;
      test_we[i]        <= 1'b1;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h0000_0000;
      test_timeout[i]   <= 32'd10;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x02
      test_addr[i]      <= 32'h0000_0000;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b write/read, cache hit */ // 0x03
      test_addr[i]      <= 32'h0010_0010;test_datao[i]    <= 32'h5454_6902;
      test_we[i]        <= 1'b1;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h0000_0000;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x04
      test_addr[i]      <= 32'h0000_0000;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b write/read, cache miss */ // 0x05
      test_addr[i]      <= 32'h0010_0000;test_datao[i]    <= 32'h5454_6903;
      test_we[i]        <= 1'b1;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h0000_0000;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x06
      test_addr[i]      <= 32'h0000_0010;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0028);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6900;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b write, same page, same idx */ // 0x07
      test_addr[i]      <= 32'h0020_0020;test_datao[i]    <= 32'h5454_6904;
      test_we[i]        <= 1'b1;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h0000_0000;
      test_timeout[i]   <= 32'd11;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x08
      test_addr[i]      <= 32'h0020_0020;test_datao[i]    <= 32'h5a5a_6905;
      test_we[i]        <= 1'b1;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b write, same page, other idx */ // 0x09
      test_addr[i]      <= 32'h0020_0030;test_datao[i]    <= 32'h5454_6906;
      test_we[i]        <= 1'b1;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h0000_0000;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x0a
      test_addr[i]      <= 32'h0020_0040;test_datao[i]    <= 32'h5a5a_5407;
      test_we[i]        <= 1'b1;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b write, other page, same idx */ // 0x0b
      test_addr[i]      <= 32'h0030_0050;test_datao[i]    <= 32'h5454_6908;
      test_we[i]        <= 1'b1;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h0000_0000;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x0c
      test_addr[i]      <= 32'h0000_0050;test_datao[i]    <= 32'h5a5a_5409;
      test_we[i]        <= 1'b1;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd30;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b write, other page, other idx */ // 0x0d
      test_addr[i]      <= 32'h0050_0060;test_datao[i]    <= 32'h5454_690a;
      test_we[i]        <= 1'b1;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h0000_0000;
      test_timeout[i]   <= 32'd28;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x0e
      test_addr[i]      <= 32'h0000_0050;test_datao[i]    <= 32'h5a5a_540b;
      test_we[i]        <= 1'b1;         test_waittime[i] <=
			                  (`delay + 32'h0000_002c);
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd40;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b read, cache hit, cache hit*/ // 0x0f
      test_addr[i]      <= 32'h0010_0000;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6903;
      test_timeout[i]   <= 32'd1;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x10
      test_addr[i]      <= 32'h0000_0010;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6900;
      test_timeout[i]   <= 32'd1;        test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b read, cache hit, cache miss*/ // 0x11
      test_addr[i]      <= 32'h0000_0010;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6900;
      test_timeout[i]   <= 32'd1;        test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x12
      test_addr[i]      <= 32'h0000_0000;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b read, cache miss, cache hit*/ // 0x13
      test_addr[i]      <= 32'h0010_0000;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6903;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x14
      test_addr[i]      <= 32'h0000_0010;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6900;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b read, cache miss, cache miss*/ // 0x15
      test_addr[i]      <= 32'h0030_0050;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6908;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x16
      test_addr[i]      <= 32'h0000_0000;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0028);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd30;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b read, ghosting, snatch*/ // 0x17
      test_addr[i]      <= 32'h0010_0000;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6903;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x18
      test_addr[i]      <= 32'h0000_0000;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* write interlude */ // 0x19
      test_addr[i]      <= 32'h0020_0031;test_datao[i]    <= 32'h5a5a_540f;
      test_we[i]        <= 1'b1;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x1a
      test_addr[i]      <= 32'h0090_0030;test_datao[i]    <= 32'h5a5a_540f;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0020);
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd30;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b read, ghosting, same address*/ // 0x1b
      test_addr[i]      <= 32'h0000_0050;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5a5a_540b;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x1c
      test_addr[i]      <= 32'h0000_0050;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5a5a_540b;
      test_timeout[i]   <= 32'd24;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b read, ghosting, peer address*/ // 0x1d
      test_addr[i]      <= 32'h0020_0030;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6906;
      test_timeout[i]   <= 32'd35;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x1e
      test_addr[i]      <= 32'h0020_0031;test_datao[i]    <= 32'h5a5a_540e;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0028);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5a5a_540f;
      test_timeout[i]   <= 32'd42;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b read/write, cache hit, same idx*/ // 0x1f
      test_addr[i]      <= 32'h0020_0030;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6906;
      test_timeout[i]   <= 32'd1;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x20
      test_addr[i]      <= 32'h0000_0030;test_datao[i]    <= 32'h5a5a_0010;
      test_we[i]        <= 1'b1;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6900;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b read, cache hit, other idx*/ // 0x21
      test_addr[i]      <= 32'h0000_0030;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5a5a_0010;
      test_timeout[i]   <= 32'd1;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x22
      test_addr[i]      <= 32'h0000_0000;test_datao[i]    <= 32'h5454_5454;
      test_we[i]        <= 1'b1;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b read, cache miss, same idx*/ // 0x23
      test_addr[i]      <= 32'h0010_0000;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6903;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x24
      test_addr[i]      <= 32'h0000_0010;test_datao[i]    <= 32'h5a5a_0020;
      test_we[i]        <= 1'b1;         test_waittime[i] <=
			                  (`delay + 32'h0000_0020 );
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6900;
      test_timeout[i]   <= 32'd30;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* b2b read, cache miss, other idx*/ // 0x25
      test_addr[i]      <= 32'h0020_0030;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_6906;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x26
      test_addr[i]      <= 32'h0000_0000;test_datao[i]    <= 32'h5a5a_0030;
      test_we[i]        <= 1'b1;         test_waittime[i] <=
			                  (`delay + 32'h0000_0020);
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd30;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* interlude, b2b write + write + WE_TLB */ // 0x27
      test_addr[i]      <= 32'h0000_2020;test_datao[i]    <= 32'h5454_0400;
      test_we[i]        <= 1'b1;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h0000_0000;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x28
      test_addr[i]      <= 32'h0000_1010;test_datao[i]    <= 32'h5a5a_0440;
      test_we[i]        <= 1'b1;         test_waittime[i] <=
			                  (`delay + 32'h0000_0020);
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd30;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x29
      test_addr[i]      <= 32'h0010_1010;test_datao[i]    <= 32'h5a5a_0450;
      test_we[i]        <= 1'b1;         test_waittime[i] <=
			                  (`delay + 32'h0000_0020);
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x2a
      test_addr[i]      <= 32'h0000_0110;test_datao[i]    <= 32'h0000_0180;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0500);
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b1;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* vmem b2b read, cache hit, cache miss*/ // 0x2b
      test_addr[i]      <= 32'h0178_2020;test_datao[i]    <= 32'h5454_1400;
      test_we[i]        <= 1'b0;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5454_0400;
      test_timeout[i]   <= 32'd1;        test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x2c
      test_addr[i]      <= 32'h0180_1010;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h5a5a_0440;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* vmem b2b write, same page, other idx + write */ // 0x2d
      test_addr[i]      <= 32'h0282_3030;test_datao[i]    <= 32'h0001_5a5a;
      test_we[i]        <= 1'b1;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h0000_0000;
      test_timeout[i]   <= 32'd33;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x2e
      test_addr[i]      <= 32'h0100_0404;test_datao[i]    <= 32'h0200_5a5a;
      test_we[i]        <= 1'b1;         test_waittime[i] <=
			                  (`delay + 32'h0000_0028);
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd44;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x2f
      test_addr[i]      <= 32'h0000_ff04;test_datao[i]    <= 32'hfdff_5a5a;
      test_we[i]        <= 1'b1;         test_waittime[i] <=
			                  (`delay + 32'h0000_0400);
      test_caredatai[i] <= 1'b0;         test_datai[i]    <= 32'h5454_6901;
      test_timeout[i]   <= 32'd28;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* pmem b2b read, cache hit, cache miss */ // 0x30
      test_addr[i]      <= 32'h0000_3030;test_datao[i]    <= 32'h5454_1400;
      test_we[i]        <= 1'b0;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h0001_5a5a;
      test_timeout[i]   <= 32'd1;        test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1; // 0x31
      test_addr[i]      <= 32'h0000_0404;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h0200_5a5a;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd0;
      i = i +1;
      /* read, cache hit, fake_miss simulataneous */ // 0x32
      test_addr[i]      <= 32'h0000_0404;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h0200_5a5a;
      test_timeout[i]   <= 32'd4;        test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd5;
      i = i +1;
      /* read, cache miss, fake_miss simulataneous, prolonged */ // 0x33
      test_addr[i]      <= 32'h0000_ff04;test_datao[i]    <= 32'hfdff_5a5a;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'hfdff_5a5a;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd18;
      i = i +1;
      /* read, cache miss, fake_miss simulataneous, subsumed */ // 0x34
      test_addr[i]      <= 32'h0000_0404;test_datao[i]    <= 32'hfdff_5a5a;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h0200_5a5a;
      test_timeout[i]   <= 32'd20;       test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd5;
      i = i +1;
      /* b2b read, cache hit, cache hit, fake_miss simulatanous */ // 0x35
      test_addr[i]      <= 32'h0000_3030;test_datao[i]    <= 32'h5454_1400;
      test_we[i]        <= 1'b0;         test_waittime[i] <= `delay;
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h0001_5a5a;
      test_timeout[i]   <= 32'd5;        test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <=
					  (`delay + 32'd32);
      i = i +1; // 0x36
      test_addr[i]      <= 32'h0000_0404;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'h0000_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h0200_5a5a;
      test_timeout[i]   <= 32'd5;        test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd5;
      i = i +1;
      /* read, cache hit, fake_miss tet-a-tet */ // 0x37
      test_addr[i]      <= 32'h0000_3030;test_datao[i]    <= 32'h5454_1400;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
					  (`delay + 32'd2);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h0001_5a5a;
      test_timeout[i]   <= (`delay + 32'd2); test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <=
					  (`delay + 32'd3);
      i = i +1; // 0x38
      // Tet-a-tet. Failure will be tolerated.
      test_addr[i]      <= 32'h0000_0404;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'hff00_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h0200_5a5a;
      test_timeout[i]   <= 32'd2;        test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd3;        test_fakemisse[i] <= 32'd3;
      i = i +1;
      /* read, cache hit, fake_miss previous */ // 0x38
      test_addr[i]      <= 32'h0000_3030;test_datao[i]    <= 32'h5454_1400;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
					  (`delay + 32'd10);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h0001_5a5a;
      test_timeout[i]   <= 32'd1;        test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd4;        test_fakemisse[i] <=
					  (`delay + 32'd32);
      i = i +1; // 0x39
      // This test falsely fails.
      test_addr[i]      <= 32'h0000_0404;test_datao[i]    <= 32'h5a5a_5454;
      test_we[i]        <= 1'b0;         test_waittime[i] <=
			                  (`delay + 32'hff00_0018);
      test_caredatai[i] <= 1'b1;         test_datai[i]    <= 32'h0200_5a5a;
      test_timeout[i]   <= 32'd4;        test_tlb[i]      <= 1'b0;
      test_fakemissb[i] <= 32'd0;        test_fakemisse[i] <= 32'd5;
      i = i +1;

      /* Remaining to test: intrigues of MMU_FAULT,
       * turning virtual memory mode on and off as well as
       * turning cache inhibition on and off. */

      /* The big problem is the behaviour of cache in cases when a command
       * gets issued on the exact same cycle that fake_miss gets deasserted
       * which results in a result coming one cycle later than expected.
       * The cache client simply needs to pay attention to cache_busy.
       * There is no other way. */
    end

  assign time_to_test = (time_for_next_test == counter);
  assign waiting_for_result = (test_num_delay != test_seen);
  assign fake_miss = ((counter >= fake_miss_begin) &&
		      (counter <  fake_miss_end)) ? 1 : 0;

  always @(posedge CLK)
    if (! RST)
      begin
	cache_pc_addr <= 0; cache_datao <= 0;
	cache_pc_we <= 0; cache_pc_en <= 0;
	time_for_next_test <= 32'd48_200;
	test_num <= 0; test_seen <= 0;
	test_issued <= 0; test_num_delay <= 0;
	just_issued_test <= 0; we_tlb <= 0;
	fake_miss_begin <= 0; fake_miss_end <= 0;
      end
    else
      begin
	just_issued_test <= cache_pc_en;
	test_num_delay <= test_num;
	test_issued <= test_num_delay;

	if (time_to_test)
	  begin
	    cache_pc_addr <= test_addr[test_num];
	    cache_datao <= test_datao[test_num];
	    cache_pc_we <= test_we[test_num];

	    cache_pc_en <= !test_tlb[test_num];
	    we_tlb <= test_tlb[test_num];
	    fake_miss_begin <= counter + test_fakemissb[test_num];
	    fake_miss_end <= counter + test_fakemisse[test_num];

	    time_for_next_test <= counter + test_waittime[test_num];
	    test_timeout_comp[test_num] <= test_timeout[test_num] +
					    counter + 2;
	    test_num <= test_num +1;

	    $display("--- issue test %x @counter %d @time %t",
		     test_num, counter, $time);
	  end
	else
	  begin
	    cache_pc_en <= 0;
	    we_tlb <= 0;
	  end // else: !if(time_to_test)

	if (!(cache_busy ||
	      (just_issued_test && (test_issued == test_seen))))
	  begin
	    if (waiting_for_result)
	      begin
		test_seen <= test_seen +1;
		if (test_caredatai[test_seen] &&
		    !(cache_datai === test_datai[test_seen]))
		  begin
		    $display("XXX bad outcome %x @counter %d @time %t: %x",
			     test_seen, counter,
			     $time, cache_datai);
		  end
		if (counter > test_timeout_comp[test_seen])
		  begin
		    $display("XXX timeout %x @counter %d @time %t",
			     test_seen, counter, $time);
		  end
	      end
	  end
      end

endmodule // testsuite

module GlaDOS;
  reg CLK_p, CLK_n, CLK_dp, CLK_dn, RST = 0, CPU_CLK;
  reg [31:0] counter = 0, minicounter = 0,
	     readcount, readcount2, readcount_r;
  reg display_intrfc, display_internals;

  reg SYS_RST = 0, long_counter_o;
  reg [7:0] long_counter_h, long_counter_l;

  reg [31:0] data_read, transtest;

  wire [31:0]  user_req_address;
  wire 	       user_req_we, user_req;
  wire [31:0]  user_req_datain;
  reg         inhibit_ack;
  wire 	      user_req_ack;
  wire [31:0] user_req_dataout;
  wire [3:0]  user_req_we_array;

  reg 	      refresh_strobe = 1'b0;

  wire        CLK_P, CLK_N, CKE, UDQS, LDQS, UDM, LDM, CS, ODT;
  wire [2:0]  COMMAND;
  wire [13:0] ADDRESS;
  wire [2:0]  BANK;
  wire [15:0] DQ;

  reg [31:0]  cache_addr;
  reg 	      cache_we, tlb_we;
  reg 	      cache_en, cache_en_follow;
  reg [31:0]  cache_datao;
  wire [31:0] cache_datai;
  wire 	      cache_en_decoded, cache_busy, cache_MMU_FAULT;

  wire [31:0] test_cache_addr, test_cache_datao;
  wire 	      test_cache_we, test_cache_en, test_cache_we_tlb,
	      test_fake_miss;

  reg cache_vmem, cache_inhibit;

  assign cache_en_decoded = cache_en ^ cache_en_follow;

  ddr2 ddr2_mem(.ck(CLK_P),
		.ck_n(CLK_N),
		.cke(CKE),
		.cs_n(CS),
		.ras_n(COMMAND[2]),
		.cas_n(COMMAND[1]),
		.we_n(COMMAND[0]),
		.dm_rdqs({UDM,LDM}),
		.ba(BANK),
		.addr(ADDRESS[12:0]), // simulation limitation
		.dq(DQ),
		.dqs({UDQS,LDQS}),
		.dqs_n(),
		.rdqs_n(),
		.odt(1'b1));

  ddr_memory_controler ddr_mc(.CLK_n(CLK_n),
			      .CLK_dn(CLK_dn),
			      .RST_MASTER(SYS_RST),
			      .MEM_CLK_P(CLK_P),
			      .MEM_CLK_N(CLK_N),
			      .CKE(CKE),
			      .COMMAND(COMMAND),
			      .ADDRESS(ADDRESS),
			      .BANK(BANK),
			      .DQ(DQ),
			      .UDQS(UDQS),
			      .LDQS(LDQS),
			      .UDM(UDM),
			      .LDM(LDM),
			      .CS(CS),
			      .refresh_strobe(refresh_strobe),
			      .rand_req_address(user_req_address[25:0]),
			      .rand_req_we(user_req_we),
			      .rand_req_we_array(user_req_we_array),
			      .rand_req(user_req),
			      .rand_req_ack(user_req_ack),
			      .rand_req_datain(user_req_datain),
			      .bulk_req_address(0),
			      .bulk_req_we(0),
			      .bulk_req_we_array(0),
			      .bulk_req(0),
			      .bulk_req_ack(),
			      .bulk_req_algn(0),
			      .bulk_req_algn_ack(),
			      .bulk_req_datain(0),
			      .user_req_dataout(user_req_dataout));

  snowball_cache
    cache_under_test(.CPU_CLK(CPU_CLK),
		     .MCU_CLK(CLK_n),
		     .RST(SYS_RST),
		     .cache_precycle_addr(test_cache_addr),
		     .cache_datao(test_cache_datao), // CPU perspective
		     .cache_datai(cache_datai), // CPU perspective
		     .cache_precycle_we(test_cache_we),
		     .cache_busy(cache_busy),
		     .cache_precycle_enable(test_cache_en),
		     .cache_precycle_force_miss(1'b0),
//--------------------------------------------------
//--------------------------------------------------
		     .dma_mcu_access(1'b1),
		     .mem_addr(user_req_address),
		     .mem_we(user_req_we),
		     .mem_we_array(user_req_we_array),
		     .mem_do_act(user_req),
		     .mem_dataintomem(user_req_datain),
		     .mem_ack(user_req_ack),
		     .mem_datafrommem(user_req_dataout),
//--------------------------------------------------
		     .dma_wrte(),
		     .dma_read(),
		     .dma_wrte_ack(0),
		     .dma_read_ack(0),
		     .dma_data_read(0),
//--------------------------------------------------
		     .VMEM_ACT(cache_vmem),
		     .cache_inhibit(cache_inhibit),
		     .fake_miss(test_fake_miss),
//--------------------------------------------------
		     .MMU_FAULT(cache_MMU_FAULT),
		     .WE_TLB(test_cache_we_tlb));

  initial
    forever
      begin
	#1500 CLK_n <= 0; CLK_p <= 1;
	#1500 CLK_dp <= 1; CLK_dn <= 0;
	#1500 CLK_n <= 1; CLK_p <= 0;
	#1500 CLK_dp <= 0; CLK_dn <= 1;
      end
  initial
    forever
      begin
	#1500;
	#4500 CPU_CLK <= 1;
	#3000 CPU_CLK <= 0;
      end

  always @(posedge CLK_n)
    begin
      if (!RST)
	begin
	  long_counter_h <= 0;
	  long_counter_l <= 0;
	  long_counter_o <= 0;
	end
      else
	begin
	  {long_counter_o,long_counter_l} <= long_counter_l +1;
	  if (long_counter_o)
	    long_counter_h <= long_counter_h +1;
	  if (long_counter_h == 8'hff)
	    SYS_RST <= 1;
	end
    end

  initial
    forever
      #2304000 if (SYS_RST) refresh_strobe <= !refresh_strobe;


  reg [11:0] u;
  initial
    begin
      display_internals <= 0;
      RST <= 0;
      #14875 RST <= 1;
      #400000000;
      #50000000;
      #50000000;

      #20000;
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
      $display("counter %d", test_unit.counter);
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
	if (counter == 32'd50_000)
	  begin
	    $display("initiating virtual memory @counter %d", counter);
	    cache_vmem <= 1;
	  end
	if (counter == 32'd51_024)
	  begin
	    $display("initiating physical memory @counter %d", counter);
	    cache_vmem <= 0;
	  end

	display_internals <= 1;
	if (display_internals &&
//	    (counter >= 32'd48_459) &&
//	    (counter <  32'd48_486))
	    (counter >= 32'd51_310) &&
	    (counter <  32'd51_325))
	  begin
	    $display("c%d --------------------------------------", counter);
	    $display("adr %x do %x di %x we %x b %x en %x fm %x",
		     cache_under_test.cache_precycle_addr,
		     cache_under_test.cache_datao,
		     cache_under_test.cache_datai,
		     cache_under_test.cache_precycle_we,
		     cache_under_test.cache_busy,
		     cache_under_test.cache_precycle_enable,
		     cache_under_test.fake_miss);
	    $display("lookup: %x%x(%x%x%x)/%x rqtg/rstg %x/%x idx %x tdx %x",
		     cache_under_test.cache_vld,
		     (!cache_under_test.w_MMU_FAULT),
		     (!cache_under_test.cache_hit),
		     cache_under_test.cache_cycle_we,
		     cache_under_test.mandatory_lookup_act,
		     cache_under_test.cache_tlb,
		     cache_under_test.req_tag,
		     {cache_under_test.vmem_rsp_tag,
		      cache_under_test.tlb_idx},
		     cache_under_test.idx_pre,
		     cache_under_test.tlb_idx_pre);
/*
	    $display("data_cache %x req_tag %x mcu_resp %x data_mcu_trans %x p_we %x",
		     cache_under_test.data_cache,
		     cache_under_test.req_tag,
		     cache_under_test.mcu_responded,
		     cache_under_test.data_mcu_trans,
		     cache_under_test.cache_prev_we);
 */
	    $display("actv_cache %x actv_tlb %x",
		     cache_under_test.activate_cache,
		     cache_under_test.activate_tlb);
	  end
      end // else: !if(!_RST)

  always @(posedge CLK_n)
    if (!SYS_RST)
      begin
        minicounter <= 0;
      end
    else
      begin
	minicounter <= minicounter +1;
      end

  testsuite test_unit(.CLK(CPU_CLK),
		      .RST(RST),
		      .counter(counter),
		      .cache_datai(cache_datai),
		      .cache_busy(cache_busy),
		      .mmu_fault(),
		      .cache_pc_addr(test_cache_addr),
		      .cache_datao(test_cache_datao),
		      .cache_pc_we(test_cache_we),
		      .cache_pc_en(test_cache_en),
		      .we_tlb(test_cache_we_tlb),
		      .fake_miss(test_fake_miss));

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
      cache_under_test.tlbtag.ram.r_data[16] <= 16'h018f; // 0x0010
      cache_under_test.tlbtag.ram.r_data[32] <= 16'h0178; // 0x0020
      cache_under_test.tlbtag.ram.r_data[48] <= 16'h0282; // 0x0030
      cache_under_test.tlbtag.ram.r_data[4]  <= 16'h0100; // 0x0004
    end

endmodule // GlaDOS

