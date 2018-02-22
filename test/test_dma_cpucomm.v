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
  core.i_cache.cachedat.ram.r_data[11] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[12] <= {6'o11,5'hf,5'hf,16'h0017};
  core.i_cache.cachedat.ram.r_data[13] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[14] <= {6'o11,5'hf,5'hf,16'h0fe0};

core.i_cache.cachedat.ram.r_data[15] <= {6'o76,5'h2,5'h0,16'hfff8};
core.i_cache.cachedat.ram.r_data[16] <= {6'o10,5'h8,5'h0,16'h0000};

  core.i_cache.cachedat.ram.r_data[17] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[18] <= {6'o11,5'hf,5'hf,16'h0017};
  core.i_cache.cachedat.ram.r_data[19] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[20] <= {6'o11,5'hf,5'hf,16'h0fe0};

core.i_cache.cachedat.ram.r_data[21] <= {6'o72,5'h9,5'h0,16'hff08};

  core.i_cache.cachedat.ram.r_data[22] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[23] <= {6'o11,5'hf,5'hf,16'h0017};
  core.i_cache.cachedat.ram.r_data[24] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[25] <= {6'o11,5'hf,5'hf,16'h0fe0};

core.i_cache.cachedat.ram.r_data[26] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[27] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[28] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};

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

  for (i=0;i<256;i=i+2)
    begin
      core.hyper_softcore.prog_mem.ram.r_data[i]   <= 16'h47f0;
      core.hyper_softcore.prog_mem.ram.r_data[i+1] <= 16'h0af8;
    end

end // initial begin

always @(posedge CLK_n)
  begin
    if (core.hyper_softcore.d_w_en_cpu)
      $display("w_sys %x w_cpu %x",
	       core.hyper_softcore.d_w_en_sys,
	       core.hyper_softcore.d_w_en_cpu);
  end

always @(posedge CPU_CLK)
  begin
//    if (record)
    if (core.cpu.grst && 0)
      begin
	$display("rPC %x xRD %x dRD %x xREGD %x xDST %x r8d %x",
		 core.cpu.bpcu.rPC, core.cpu.regf.xRD,
		 core.cpu.regf.dRD, core.cpu.regf.xREGD,
		 core.cpu.regf.xDST, core.cpu.regf.RAM_D.ram.r_data[8]);
        $display("i_pc_addr %x rPC %x dOPC %x xOPC %x xBRA %x di/ci/ii %x SKIP %x",
		 core.i_cache_pc_addr, core.cpu.bpcu.rPC,
		 core.cpu.ibuf.dOPC, core.cpu.ibuf.xOPC,
		 core.cpu.bpcu.xBRA,
		 {core.cpu.ibuf.do_interrupt,core.cpu.ibuf.cpu_interrupt,
		  core.cpu.ibuf.issued_interrupt},
		 {core.cpu.bpcu.fSKIP,core.cpu.bpcu.dSKIP,
		  core.cpu.bpcu.xSKIP});

	$display("-------------------------------------------------");
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
