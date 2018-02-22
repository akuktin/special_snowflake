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


core.i_cache.cachedat.ram.r_data[3] <= {6'o10,5'h1,5'h0,16'hffff};
core.i_cache.cachedat.ram.r_data[4] <= {6'o10,5'h2,5'h0,16'h0007};
//core.i_cache.cachedat.ram.r_data[5] <= {6'o10,5'h1c,5'h0,16'h9707};

core.i_cache.cachedat.ram.r_data[5] <= {6'o45,5'h10,5'h1,5'h1f,11'h001};

core.i_cache.cachedat.ram.r_data[6] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[7] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[8] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[9] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[10] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[11] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[12] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[13] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[14] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[15] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[16] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[17] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[18] <= {6'o57,5'h10,5'h0,16'hffe0};
core.i_cache.cachedat.ram.r_data[19] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[20] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[21] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[22] <= {6'o57,5'h10,5'h1,16'h0010};
core.i_cache.cachedat.ram.r_data[23] <= {6'o57,5'h10,5'h1,16'h0010};


core.i_cache.cachedat.ram.r_data[24] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[25] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[26] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};

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
  core.cpu.regf.RAM_A.ram.r_data[1] <= 32'hffff_ffff;

end

always @(posedge CPU_CLK)
  begin
    if ((ctr > 64'h10540) &&
        (ctr < 64'h10620))
      begin
        $display("i_pca %x rPC %x dOPC %x xOPC %x xBRA %x di/ci/ii %x immv %x",
		 core.i_cache_pc_addr, core.cpu.bpcu.rPC,
		 core.cpu.ibuf.dOPC, core.cpu.ibuf.xOPC,
		 core.cpu.bpcu.xBRA,
		 {core.cpu.ibuf.do_interrupt,core.cpu.ibuf.cpu_interrupt,
		  core.cpu.ibuf.issued_interrupt},
		 core.cpu.ibuf.dIMMVAL);
      end
  end

always @(negedge CLK_n)
  begin
//    if (ctr == 64'h10584)
    if (ctr == 64'h10588)
      begin
//        $display("core.i_cache_pc_addr %x", core.i_cache_pc_addr);
	$display("fire interrupt!");
        force core.res_irq = 1'b1;
      end
//    if (ctr == 64'h10585)
    if (ctr == 64'h10589)
      begin
        release core.res_irq;
      end
  end
