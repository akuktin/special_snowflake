initial begin

// add : 00
// addi: 10
// rsub: 01
// rsubi: 11
// bs  : 21 // 11'h400: rD <= rA << rB; 200: rA >> rB arit; rA >> rB
// bsi : 31 // bs with IMM, IMM is 5 bits long
// xor : 42
// xori: 52
// and : 41
// andi: 51
// or  : 40
// ori : 50
// beq : 47 (delay: rD == 5'h10) // branch if rA equal 0, to PC + rB
// beqi: 57 (delay: rD == 5'h10) // branch if rA equal 0, to PC + IMM
// br  : 46 // branch to PC + rB, store cur PC to rD
// bri : 56 // branch to PC + IMM, store cur PC to rD
// lw  : 62 // load word from rA + rB to rD
// lwi : 72 // load word from rA + IMM to rD
// sw  : 66 // store word from rD into rA + rB
// swi : 76 // store word from rD into rA + IMM

// init R0
core.i_cache.cachedat.ram.r_data[0] <= {6'o05,5'h0,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[1] <= {6'o05,5'h0,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[2] <= {6'o05,5'h0,5'h0,5'h0,11'd0};


core.i_cache.cachedat.ram.r_data[3] <= {6'o54,5'h0,5'h0,16'h9707};
core.i_cache.cachedat.ram.r_data[4] <= {6'o10,5'h1,5'h0,16'h0008};
core.i_cache.cachedat.ram.r_data[5] <= {6'o10,5'h2,5'h0,16'hf7ef};

//core.i_cache.cachedat.ram.r_data[6] <= {6'o76,5'h2,5'h0,16'h0404};
  core.i_cache.cachedat.ram.r_data[6] <= {6'o11,5'hf,5'hf,16'h0010};


  core.i_cache.cachedat.ram.r_data[7] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[8] <= {6'o11,5'hf,5'hf,16'h0017};
  core.i_cache.cachedat.ram.r_data[9] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[10] <= {6'o11,5'hf,5'hf,16'h0fe0};

core.i_cache.cachedat.ram.r_data[11] <= {6'o10,5'h8,5'h0,16'h0400};
core.i_cache.cachedat.ram.r_data[12] <= {6'o76,5'h2,5'h8,16'h0004};
core.i_cache.cachedat.ram.r_data[13] <= {6'o10,5'h8,5'h0,16'h0000};

  core.i_cache.cachedat.ram.r_data[14] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[15] <= {6'o11,5'hf,5'hf,16'h0017};
  core.i_cache.cachedat.ram.r_data[16] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[17] <= {6'o11,5'hf,5'hf,16'h0fe0};

core.i_cache.cachedat.ram.r_data[18] <= {6'o10,5'h8,5'h0,16'h0400};
core.i_cache.cachedat.ram.r_data[19] <= {6'o11,5'hf,5'hf,16'h0010};
core.i_cache.cachedat.ram.r_data[20] <= {6'o76,5'h2,5'h8,16'h0008};
core.i_cache.cachedat.ram.r_data[21] <= {6'o10,5'h8,5'h0,16'h0000};

  core.i_cache.cachedat.ram.r_data[22] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[23] <= {6'o11,5'hf,5'hf,16'h0017};
  core.i_cache.cachedat.ram.r_data[24] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[25] <= {6'o11,5'hf,5'hf,16'h0fe0};

core.i_cache.cachedat.ram.r_data[26] <= {6'o10,5'h8,5'h0,16'h0400};
core.i_cache.cachedat.ram.r_data[27] <= {6'o11,5'hf,5'hf,16'h0010};
core.i_cache.cachedat.ram.r_data[28] <= {6'o11,5'hf,5'hf,16'h0010};
core.i_cache.cachedat.ram.r_data[29] <= {6'o76,5'h2,5'h8,16'h000c};
core.i_cache.cachedat.ram.r_data[30] <= {6'o10,5'h8,5'h0,16'h0000};

  core.i_cache.cachedat.ram.r_data[31] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[32] <= {6'o11,5'hf,5'hf,16'h0017};
  core.i_cache.cachedat.ram.r_data[33] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[34] <= {6'o11,5'hf,5'hf,16'h0fe0};

core.i_cache.cachedat.ram.r_data[35] <= {6'o10,5'h8,5'h0,16'h0400};
core.i_cache.cachedat.ram.r_data[36] <= {6'o11,5'hf,5'hf,16'h0010};
core.i_cache.cachedat.ram.r_data[37] <= {6'o11,5'hf,5'hf,16'h0010};
core.i_cache.cachedat.ram.r_data[38] <= {6'o11,5'hf,5'hf,16'h0010};
core.i_cache.cachedat.ram.r_data[39] <= {6'o76,5'h2,5'h8,16'h0010};
core.i_cache.cachedat.ram.r_data[40] <= {6'o10,5'h8,5'h0,16'h0000};

  core.i_cache.cachedat.ram.r_data[41] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[42] <= {6'o11,5'hf,5'hf,16'h0017};
  core.i_cache.cachedat.ram.r_data[43] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[44] <= {6'o11,5'hf,5'hf,16'h0fe0};

core.i_cache.cachedat.ram.r_data[45] <= {6'o10,5'h8,5'h0,16'h0400};
core.i_cache.cachedat.ram.r_data[46] <= {6'o11,5'hf,5'hf,16'h0010};
core.i_cache.cachedat.ram.r_data[47] <= {6'o11,5'hf,5'hf,16'h0010};
core.i_cache.cachedat.ram.r_data[48] <= {6'o11,5'hf,5'hf,16'h0010};
core.i_cache.cachedat.ram.r_data[49] <= {6'o11,5'hf,5'hf,16'h0010};
core.i_cache.cachedat.ram.r_data[50] <= {6'o76,5'h2,5'h8,16'h0014};
core.i_cache.cachedat.ram.r_data[51] <= {6'o10,5'h8,5'h0,16'h0000};

  core.i_cache.cachedat.ram.r_data[52] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[53] <= {6'o11,5'hf,5'hf,16'h0017};
  core.i_cache.cachedat.ram.r_data[54] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[55] <= {6'o11,5'hf,5'hf,16'h0fe0};

core.i_cache.cachedat.ram.r_data[56] <= {6'o72,5'h9,5'h0,16'h0404};
core.i_cache.cachedat.ram.r_data[57] <= {6'o72,5'ha,5'h0,16'h0408};
core.i_cache.cachedat.ram.r_data[58] <= {6'o72,5'hb,5'h0,16'h040c};
core.i_cache.cachedat.ram.r_data[59] <= {6'o72,5'hc,5'h0,16'h0410};
core.i_cache.cachedat.ram.r_data[60] <= {6'o72,5'hd,5'h0,16'h0414};

core.i_cache.cachedat.ram.r_data[61] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[62] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[63] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};

core.i_cache.cachedat.ram.r_data[96] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[97] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[98] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};
core.i_cache.cachedat.ram.r_data[99] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};
core.i_cache.cachedat.ram.r_data[100] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};

  for (i=1; i<31; i=i+1)
    begin
      core.cpu.regf.RAM_A.ram.r_data[i] <= 32'hxxxx_xxxx;
      core.cpu.regf.RAM_B.ram.r_data[i] <= 32'hxxxx_xxxx;
      core.cpu.regf.RAM_D.ram.r_data[i] <= 32'hxxxx_xxxx;
    end
//  core.cpu.regf.RAM_A.ram.r_data[22] <= 32'hffff_ffff;

end

always @(posedge CPU_CLK)
  begin
    if (record && 0)
//    if (core.cpu.grst)
      begin
        $display("i_pc_addr %x rPC %x dOPC %x xOPC %x xBRA %x di/ci/ii %x SKIP %x",
		 core.i_cache_pc_addr, core.cpu.bpcu.rPC,
		 core.cpu.ibuf.dOPC, core.cpu.ibuf.xOPC,
		 core.cpu.bpcu.xBRA,
		 {core.cpu.ibuf.do_interrupt,core.cpu.ibuf.cpu_interrupt,
		  core.cpu.ibuf.issued_interrupt},
		 {core.cpu.bpcu.fSKIP,core.cpu.bpcu.dSKIP,
		  core.cpu.bpcu.xSKIP});
/*
	$display("d/x_en %x dMXALT %x cior %x xRESULT %x xREGA %x",
		 {core.cpu.bpcu.d_en,core.cpu.bpcu.x_en},
		 core.cpu.bpcu.dMXALT, core.cpu.bpcu.c_io_rg,
		 core.cpu.bpcu.xRESULT, core.cpu.bpcu.xREGA);

        $display("i_pca %x rPC %x di/ci/ii %x immv %x wRA %x",
		 core.i_cache_pc_addr, core.cpu.bpcu.rPC,
		 {core.cpu.ibuf.do_interrupt,core.cpu.ibuf.cpu_interrupt,
		  core.cpu.ibuf.issued_interrupt},
		 core.cpu.ibuf.dIMMVAL,
		 core.cpu.bpcu.wREGA);

        $display("rPC %x dBB %x clip %x ere %x renn %x ce %x dS %x rSn %x dOPC %x xOPC %x xBRA %x",
		 core.cpu.bpcu.rPC,
		 {core.cpu.bpcu.dBRU,core.cpu.bpcu.dBCC},
		 {core.cpu.bpcu.expect_reg_equal,
		  core.cpu.bpcu.reg_equal_null_n,
		  core.cpu.bpcu.invert_answer},
		 {core.cpu.bpcu.careof_equal_n,
		  core.cpu.bpcu.careof_ltgt,
		  core.cpu.bpcu.ltgt_true,
		  core.cpu.bpcu.expect_equal},
		 core.cpu.bpcu.reg_equal_null_n,
		 core.cpu.bpcu.chain_endpoint,
		 core.cpu.bpcu.dSKIP,
		 core.cpu.bpcu.rSKIP_n,
		 core.cpu.ibuf.dOPC, core.cpu.ibuf.xOPC,
		 core.cpu.bpcu.xBRA);

	$display("-------------------------------------------------");
 */
      end
  end

/*
`define CHANGER 64'h0b
always @(negedge CPU_CLK)
  begin
    if (cpu_ctr == (`CHANGER -1))
      record <= 1;
    if (cpu_ctr == (`CHANGER))
      begin
        $display("core.i_cache_pc_addr %x", core.i_cache_pc_addr);
	$display("fire interrupt!");
        force core.cpu.sys_int_i = 1'b1;
      end
    if (cpu_ctr == (`CHANGER +1))
      begin
        release core.cpu.sys_int_i;
      end
  end
 */
