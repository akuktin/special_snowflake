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

// standing jump
core.i_cache.cachedat.ram.r_data[7] <= {6'o56,5'h1e,5'h0,16'h0};

  core.i_cache.cachedat.ram.r_data[8] <= {6'o11,5'hf,5'hf,16'h0017};
  core.i_cache.cachedat.ram.r_data[9] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[10] <= {6'o11,5'hf,5'hf,16'h0fe0};
  core.i_cache.cachedat.ram.r_data[11] <= {6'o11,5'hf,5'hf,16'h0010};
  core.i_cache.cachedat.ram.r_data[12] <= {6'o11,5'hf,5'hf,16'h0017};

core.i_cache.cachedat.ram.r_data[13] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[14] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[15] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};

core.i_cache.cachedat.ram.r_data[96] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[97] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[98] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};
core.i_cache.cachedat.ram.r_data[99] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};
core.i_cache.cachedat.ram.r_data[100] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};

core.hyper_softcore.data_mem.ram.r_data[192] <= 16'h0000;
core.hyper_softcore.data_mem.ram.r_data[193] <= 16'h0001;
core.hyper_softcore.data_mem.ram.r_data[194] <= 16'h0002;
core.hyper_softcore.data_mem.ram.r_data[195] <= 16'h0003;
core.hyper_softcore.data_mem.ram.r_data[196] <= 16'h0004;

core.hyper_softcore.prog_mem.ram.r_data[154] <= 16'h0ac0;
core.hyper_softcore.prog_mem.ram.r_data[155] <= 16'h4600;
core.hyper_softcore.prog_mem.ram.r_data[156] <= 16'h4601;
core.hyper_softcore.prog_mem.ram.r_data[157] <= 16'h4602;
core.hyper_softcore.prog_mem.ram.r_data[158] <= 16'h48a2; // wait
core.hyper_softcore.prog_mem.ram.r_data[159] <= 16'h4603;
core.hyper_softcore.prog_mem.ram.r_data[160] <= 16'h4604;
core.hyper_softcore.prog_mem.ram.r_data[161] <= 16'h4605;
core.hyper_softcore.prog_mem.ram.r_data[162] <= 16'h4606; // jump to here
core.hyper_softcore.prog_mem.ram.r_data[163] <= 16'h4607;
core.hyper_softcore.prog_mem.ram.r_data[164] <= 16'h4608;

core.hyper_softcore.prog_mem.ram.r_data[174] <= 16'h0ac1;
core.hyper_softcore.prog_mem.ram.r_data[175] <= 16'h4610;
core.hyper_softcore.prog_mem.ram.r_data[176] <= 16'h4611;
core.hyper_softcore.prog_mem.ram.r_data[177] <= 16'h4612;
core.hyper_softcore.prog_mem.ram.r_data[178] <= 16'h48b6; // wait
core.hyper_softcore.prog_mem.ram.r_data[179] <= 16'h4613;
core.hyper_softcore.prog_mem.ram.r_data[180] <= 16'h4614;
core.hyper_softcore.prog_mem.ram.r_data[181] <= 16'h4615;
core.hyper_softcore.prog_mem.ram.r_data[182] <= 16'h4616; // jump to here
core.hyper_softcore.prog_mem.ram.r_data[183] <= 16'h4617;
core.hyper_softcore.prog_mem.ram.r_data[184] <= 16'h4618;

core.hyper_softcore.prog_mem.ram.r_data[194] <= 16'h0ac2;
core.hyper_softcore.prog_mem.ram.r_data[195] <= 16'h4620;
core.hyper_softcore.prog_mem.ram.r_data[196] <= 16'h4621;
core.hyper_softcore.prog_mem.ram.r_data[197] <= 16'h4622;
core.hyper_softcore.prog_mem.ram.r_data[198] <= 16'h48ca; // wait
core.hyper_softcore.prog_mem.ram.r_data[199] <= 16'h4623;
core.hyper_softcore.prog_mem.ram.r_data[200] <= 16'h4624;
core.hyper_softcore.prog_mem.ram.r_data[201] <= 16'h4625;
core.hyper_softcore.prog_mem.ram.r_data[202] <= 16'h4626; // jump to here
core.hyper_softcore.prog_mem.ram.r_data[203] <= 16'h4627;
core.hyper_softcore.prog_mem.ram.r_data[204] <= 16'h4628;

core.hyper_softcore.prog_mem.ram.r_data[214] <= 16'h0ac3;
core.hyper_softcore.prog_mem.ram.r_data[215] <= 16'h4630;
core.hyper_softcore.prog_mem.ram.r_data[216] <= 16'h4631;
core.hyper_softcore.prog_mem.ram.r_data[217] <= 16'h4632;
core.hyper_softcore.prog_mem.ram.r_data[218] <= 16'h48de; // wait
core.hyper_softcore.prog_mem.ram.r_data[219] <= 16'h4633;
core.hyper_softcore.prog_mem.ram.r_data[220] <= 16'h4634;
core.hyper_softcore.prog_mem.ram.r_data[221] <= 16'h4635;
core.hyper_softcore.prog_mem.ram.r_data[222] <= 16'h4636; // jump to here
core.hyper_softcore.prog_mem.ram.r_data[223] <= 16'h4637;
core.hyper_softcore.prog_mem.ram.r_data[224] <= 16'h4638;

core.hyper_softcore.prog_mem.ram.r_data[234] <= 16'h0ac4;
core.hyper_softcore.prog_mem.ram.r_data[235] <= 16'h4640;
core.hyper_softcore.prog_mem.ram.r_data[236] <= 16'h4641;
core.hyper_softcore.prog_mem.ram.r_data[237] <= 16'h4642;
core.hyper_softcore.prog_mem.ram.r_data[238] <= 16'h48f2; // wait
core.hyper_softcore.prog_mem.ram.r_data[239] <= 16'h4643;
core.hyper_softcore.prog_mem.ram.r_data[240] <= 16'h4644;
core.hyper_softcore.prog_mem.ram.r_data[241] <= 16'h4645;
core.hyper_softcore.prog_mem.ram.r_data[242] <= 16'h4646; // jump to here
core.hyper_softcore.prog_mem.ram.r_data[243] <= 16'h4647;
core.hyper_softcore.prog_mem.ram.r_data[244] <= 16'h4648;


core.hyper_softcore.prog_mem.ram.r_data[254] <= 16'h6a00;
core.hyper_softcore.prog_mem.ram.r_data[255] <= 16'h46ff;


  for (i=1; i<31; i=i+1)
    begin
      core.cpu.regf.RAM_A.ram.r_data[i] <= 32'hxxxx_xxxx;
      core.cpu.regf.RAM_B.ram.r_data[i] <= 32'hxxxx_xxxx;
      core.cpu.regf.RAM_D.ram.r_data[i] <= 32'hxxxx_xxxx;
    end
//  core.cpu.regf.RAM_A.ram.r_data[22] <= 32'hffff_ffff;

end // initial begin

always @(posedge CLK_n)
  begin
    if (core.hyper_softcore.d_w_en_cpu)
      $display("w_sys %x w_cpu %x",
	       core.hyper_softcore.d_w_en_sys,
	       core.hyper_softcore.d_w_en_cpu);
    if (core.hyper_softcore.RST)
      $display("opc_o %x", core.hyper_softcore.instr_o);
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
