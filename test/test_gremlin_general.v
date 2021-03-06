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


core.hyper_softcore.prog_mem.ram.r_data[0] <= 16'h4e00;
core.hyper_softcore.prog_mem.ram.r_data[1] <= 16'h6a00;
core.hyper_softcore.prog_mem.ram.r_data[2] <= 16'h4610;
core.hyper_softcore.prog_mem.ram.r_data[3] <= 16'h4611;
core.hyper_softcore.prog_mem.ram.r_data[4] <= 16'h4712;
core.hyper_softcore.prog_mem.ram.r_data[5] <= 16'h4613;


core.hyper_softcore.prog_mem.ram.r_data[6] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[7] <= 16'h4618; // 0x18 => 1
core.hyper_softcore.prog_mem.ram.r_data[8] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[9] <= 16'h4619; // 0x19 => 2
core.hyper_softcore.prog_mem.ram.r_data[10] <= 16'h4000;
core.hyper_softcore.prog_mem.ram.r_data[11] <= 16'h461a; // 0x1a => 2
core.hyper_softcore.prog_mem.ram.r_data[12] <= 16'h6e00;
core.hyper_softcore.prog_mem.ram.r_data[13] <= 16'h0010;
core.hyper_softcore.prog_mem.ram.r_data[14] <= 16'h461b; // 0x1b => 1+0xfffe
core.hyper_softcore.prog_mem.ram.r_data[15] <= 16'h6e00;
core.hyper_softcore.prog_mem.ram.r_data[16] <= 16'h0010;
core.hyper_softcore.prog_mem.ram.r_data[17] <= 16'h461c; // 0x1c => 1+0xfffe
core.hyper_softcore.prog_mem.ram.r_data[18] <= 16'h6e00;
core.hyper_softcore.prog_mem.ram.r_data[19] <= 16'h0210;
core.hyper_softcore.prog_mem.ram.r_data[20] <= 16'h461d; // 0x1d => 1+0xffff

core.hyper_softcore.prog_mem.ram.r_data[21] <= 16'h6e00;
core.hyper_softcore.prog_mem.ram.r_data[22] <= 16'h0210;
core.hyper_softcore.prog_mem.ram.r_data[23] <= 16'h0310;
core.hyper_softcore.prog_mem.ram.r_data[24] <= 16'h461e; // 0x1e => 1+0xffff
core.hyper_softcore.prog_mem.ram.r_data[25] <= 16'h4d00;
core.hyper_softcore.prog_mem.ram.r_data[26] <= 16'h4213;
core.hyper_softcore.prog_mem.ram.r_data[27] <= 16'h461f; // 0x1f => 1

// one-istruction gap!

core.hyper_softcore.prog_mem.ram.r_data[29] <= 16'h0a10;
core.hyper_softcore.prog_mem.ram.r_data[30] <= 16'h201f;
core.hyper_softcore.prog_mem.ram.r_data[31] <= 16'h4616; // 0x16 => 1+0xfffd
core.hyper_softcore.prog_mem.ram.r_data[32] <= 16'h4d00;
core.hyper_softcore.prog_mem.ram.r_data[33] <= 16'h4200;
core.hyper_softcore.prog_mem.ram.r_data[34] <= 16'h4617; // 0x17 => 1

core.hyper_softcore.prog_mem.ram.r_data[35] <= 16'h6f00;
core.hyper_softcore.prog_mem.ram.r_data[36] <= 16'h4614; // 0x14 => 0xfffe

//// DATA !
core.hyper_softcore.data_mem.ram.r_data[0] <= 16'h0018; //// DATA !
core.hyper_softcore.input_reg_0[0] <= 16'h3210;
core.hyper_softcore.input_reg_0[1] <= 16'h4321;
core.hyper_softcore.input_reg_1[0] <= 16'h7654;
core.hyper_softcore.input_reg_1[1] <= 16'h8765;
//// DATA !

core.hyper_softcore.prog_mem.ram.r_data[37] <= 16'h0a00;
core.hyper_softcore.prog_mem.ram.r_data[38] <= 16'h4601; // 0x01 => 0x0018
core.hyper_softcore.prog_mem.ram.r_data[39] <= 16'h4c00;
// two-istruction gap!
core.hyper_softcore.prog_mem.ram.r_data[42] <= 16'h1a08;
core.hyper_softcore.prog_mem.ram.r_data[43] <= 16'h56f9; // 0x20 => 1
core.hyper_softcore.prog_mem.ram.r_data[44] <= 16'h1008;
core.hyper_softcore.prog_mem.ram.r_data[45] <= 16'h1600; // 0x21 => 3

core.hyper_softcore.prog_mem.ram.r_data[46] <= 16'hc133; // branch taken
core.hyper_softcore.prog_mem.ram.r_data[47] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[48] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[49] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[50] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[51] <= 16'h4728; // 0x28 => 6
core.hyper_softcore.prog_mem.ram.r_data[52] <= 16'hc139; // branch not taken
core.hyper_softcore.prog_mem.ram.r_data[53] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[54] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[55] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[56] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[57] <= 16'h4629; // 0x29 => 5

core.hyper_softcore.prog_mem.ram.r_data[58] <= 16'h083e;
core.hyper_softcore.prog_mem.ram.r_data[59] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[60] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[61] <= 16'h0013;
core.hyper_softcore.prog_mem.ram.r_data[62] <= 16'h462b; // 0x2b => 0

core.hyper_softcore.prog_mem.ram.r_data[63] <= 16'h0400;
core.hyper_softcore.prog_mem.ram.r_data[64] <= 16'h4630; // 0x30 => 0x3210
core.hyper_softcore.prog_mem.ram.r_data[65] <= 16'h4500;
core.hyper_softcore.prog_mem.ram.r_data[66] <= 16'h4631; // 0x31 => 0x7654

core.hyper_softcore.prog_mem.ram.r_data[67] <= 16'hc947; // IRQ (11)
core.hyper_softcore.prog_mem.ram.r_data[68] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[69] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[70] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[71] <= 16'h4632; // 0x32 => 2

core.hyper_softcore.prog_mem.ram.r_data[72] <= 16'h6b01; // o[1] => 2
core.hyper_softcore.prog_mem.ram.r_data[73] <= 16'h0130;
core.hyper_softcore.prog_mem.ram.r_data[74] <= 16'h4b02; // o[2] => 0x3213+tran
core.hyper_softcore.prog_mem.ram.r_data[75] <= 16'h4633; // 0x33 => 0

core.hyper_softcore.prog_mem.ram.r_data[76] <= 16'h4a00;
core.hyper_softcore.prog_mem.ram.r_data[77] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[78] <= 16'h462d; // 0x2d => 1
core.hyper_softcore.prog_mem.ram.r_data[79] <= 16'h462e; // 0x2e/overwritten
core.hyper_softcore.prog_mem.ram.r_data[80] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[81] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[82] <= 16'h072e; // 0x2e => 3
core.hyper_softcore.prog_mem.ram.r_data[83] <= 16'h462f; // 0x2f => 1

core.hyper_softcore.prog_mem.ram.r_data[84] <= 16'h4635; // 0x35/overwritten
core.hyper_softcore.prog_mem.ram.r_data[85] <= 16'h6a00;
core.hyper_softcore.prog_mem.ram.r_data[86] <= 16'h4100;
core.hyper_softcore.prog_mem.ram.r_data[87] <= 16'h0735; // 0x35 => 0
core.hyper_softcore.prog_mem.ram.r_data[88] <= 16'h4200;
core.hyper_softcore.prog_mem.ram.r_data[89] <= 16'h4636; // 0x36 => 2

// data mem
core.hyper_softcore.data_mem.ram.r_data[200] <= 16'h00ca;
core.hyper_softcore.data_mem.ram.r_data[201] <= 16'h00cc;
core.hyper_softcore.data_mem.ram.r_data[202] <= 16'h0020;
core.hyper_softcore.data_mem.ram.r_data[203] <= 16'h0100;
core.hyper_softcore.data_mem.ram.r_data[204] <= 16'h0200;
core.hyper_softcore.data_mem.ram.r_data[205] <= 16'h0400;
core.hyper_softcore.data_mem.ram.r_data[206] <= 16'h0800;
core.hyper_softcore.data_mem.ram.r_data[207] <= 16'h1000;
// /data mem

core.hyper_softcore.prog_mem.ram.r_data[90] <= 16'h0ac8;
core.hyper_softcore.prog_mem.ram.r_data[91] <= 16'h4c00;
core.hyper_softcore.prog_mem.ram.r_data[92] <= 16'h4e00;
core.hyper_softcore.prog_mem.ram.r_data[93] <= 16'h4e00;
core.hyper_softcore.prog_mem.ram.r_data[94] <= 16'h4e00;
core.hyper_softcore.prog_mem.ram.r_data[95] <= 16'h0ac9;
core.hyper_softcore.prog_mem.ram.r_data[96] <= 16'h4c00;
//  core.hyper_softcore.prog_mem.ram.r_data[97] <= 16'h4e00;
//  core.hyper_softcore.prog_mem.ram.r_data[98] <= 16'h4e00;
core.hyper_softcore.prog_mem.ram.r_data[97] <= 16'h1001;
core.hyper_softcore.prog_mem.ram.r_data[98] <= 16'h1001;
core.hyper_softcore.prog_mem.ram.r_data[99] <= 16'h1001;
core.hyper_softcore.prog_mem.ram.r_data[100] <= 16'h1001;
core.hyper_softcore.prog_mem.ram.r_data[101] <= 16'h46d0; // 0xd0 => 0x1e00


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
    if (core.hyper_softcore.d_w_en_cpu && 0)
      $display("w_sys %x w_cpu %x",
	       core.hyper_softcore.d_w_en_sys,
	       core.hyper_softcore.d_w_en_cpu);
    if (core.hyper_softcore.RST && 0)
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
