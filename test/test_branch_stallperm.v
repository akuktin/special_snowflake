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
core.i_cache.cachedat.ram.r_data[5] <= {6'o10,5'h3,5'h0,16'h9707};

//core.i_cache.cachedat.ram.r_data[6] <= {6'o05,5'h0,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[6] <= {6'o45,5'h10,5'h1,5'h1f,11'h001};

core.i_cache.cachedat.ram.r_data[7] <= {6'o21,5'h4,5'h1,5'h2,11'h400};//bsf
//core.i_cache.cachedat.ram.r_data[8] <= {6'o05,5'h0,5'h0,5'h0,11'd0};
//core.i_cache.cachedat.ram.r_data[8] <= {6'o57,5'h10,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[8] <= {6'o57,5'h10,5'h0,16'h000c};
core.i_cache.cachedat.ram.r_data[9] <= {6'o21,5'h5,5'h3,5'h2,11'h400};//bsf
core.i_cache.cachedat.ram.r_data[10] <= {6'o00,5'h6,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[11] <= {6'o00,5'h7,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[12] <= {6'o76,5'h4,5'h0,16'h0010};//str 4
//core.i_cache.cachedat.ram.r_data[13] <= {6'o05,5'h0,5'h0,5'h0,11'd0};
//core.i_cache.cachedat.ram.r_data[13] <= {6'o57,5'h10,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[13] <= {6'o57,5'h10,5'h0,16'h000c};
core.i_cache.cachedat.ram.r_data[14] <= {6'o21,5'h6,5'h3,5'h2,11'h400};//bsf
core.i_cache.cachedat.ram.r_data[15] <= {6'o00,5'h6,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[16] <= {6'o00,5'h7,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[17] <= {6'o72,5'h18,5'h0,16'h0010};//lod
//core.i_cache.cachedat.ram.r_data[18] <= {6'o05,5'h0,5'h0,5'h0,11'd0};
//core.i_cache.cachedat.ram.r_data[18] <= {6'o57,5'h10,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[18] <= {6'o57,5'h10,5'h0,16'h000c};
core.i_cache.cachedat.ram.r_data[19] <= {6'o21,5'h7,5'h3,5'h2,11'h400};//bsf
core.i_cache.cachedat.ram.r_data[20] <= {6'o00,5'h6,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[21] <= {6'o00,5'h7,5'h0,16'h0010};

core.i_cache.cachedat.ram.r_data[22] <= {6'o21,5'h8,5'h1,5'h2,11'h400};//bsf
//core.i_cache.cachedat.ram.r_data[23] <= {6'o05,5'h0,5'h0,5'h0,11'd0};
//core.i_cache.cachedat.ram.r_data[23] <= {6'o57,5'h10,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[23] <= {6'o57,5'h10,5'h0,16'h000c};
core.i_cache.cachedat.ram.r_data[24] <= {6'o76,5'h5,5'h0,16'h0014};//str 5
core.i_cache.cachedat.ram.r_data[25] <= {6'o00,5'h6,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[26] <= {6'o00,5'h7,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[27] <= {6'o76,5'h4,5'h0,16'h0018};//str 4
//core.i_cache.cachedat.ram.r_data[28] <= {6'o05,5'h0,5'h0,5'h0,11'd0};
//core.i_cache.cachedat.ram.r_data[28] <= {6'o57,5'h10,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[28] <= {6'o57,5'h10,5'h0,16'h000c};
core.i_cache.cachedat.ram.r_data[29] <= {6'o76,5'h5,5'h0,16'h001c};//str 5
core.i_cache.cachedat.ram.r_data[30] <= {6'o00,5'h6,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[31] <= {6'o00,5'h7,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[32] <= {6'o72,5'h19,5'h0,16'h0014};//lod
//core.i_cache.cachedat.ram.r_data[33] <= {6'o05,5'h0,5'h0,5'h0,11'd0};
//core.i_cache.cachedat.ram.r_data[33] <= {6'o57,5'h10,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[33] <= {6'o57,5'h10,5'h0,16'h000c};
core.i_cache.cachedat.ram.r_data[34] <= {6'o76,5'h4,5'h0,16'h0020};//str 4
core.i_cache.cachedat.ram.r_data[35] <= {6'o00,5'h6,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[36] <= {6'o00,5'h7,5'h0,16'h0010};

core.i_cache.cachedat.ram.r_data[37] <= {6'o21,5'h9,5'h1,5'h2,11'h400};//bsf
//core.i_cache.cachedat.ram.r_data[38] <= {6'o05,5'h0,5'h0,5'h0,11'd0};
//core.i_cache.cachedat.ram.r_data[38] <= {6'o57,5'h10,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[38] <= {6'o57,5'h10,5'h0,16'h000c};
core.i_cache.cachedat.ram.r_data[39] <= {6'o72,5'h1a,5'h0,16'h0018};//lod
core.i_cache.cachedat.ram.r_data[40] <= {6'o00,5'h6,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[41] <= {6'o00,5'h7,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[42] <= {6'o76,5'h5,5'h0,16'h0024};//str 5
//core.i_cache.cachedat.ram.r_data[43] <= {6'o05,5'h0,5'h0,5'h0,11'd0};
//core.i_cache.cachedat.ram.r_data[43] <= {6'o57,5'h10,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[43] <= {6'o57,5'h10,5'h0,16'h000c};
core.i_cache.cachedat.ram.r_data[44] <= {6'o72,5'h1b,5'h0,16'h001c};//lod
core.i_cache.cachedat.ram.r_data[45] <= {6'o00,5'h6,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[46] <= {6'o00,5'h7,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[47] <= {6'o72,5'h1c,5'h0,16'h0020};//lod
//core.i_cache.cachedat.ram.r_data[48] <= {6'o05,5'h0,5'h0,5'h0,11'd0};
//core.i_cache.cachedat.ram.r_data[48] <= {6'o57,5'h10,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[48] <= {6'o57,5'h10,5'h0,16'h000c};
core.i_cache.cachedat.ram.r_data[49] <= {6'o72,5'h1d,5'h0,16'h0024};//lod
core.i_cache.cachedat.ram.r_data[50] <= {6'o00,5'h6,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[51] <= {6'o00,5'h7,5'h0,16'h0010};

core.i_cache.cachedat.ram.r_data[52] <= {6'o00,5'he,5'h0,16'h0010};
core.i_cache.cachedat.ram.r_data[53] <= {6'o00,5'hf,5'h0,16'h0010};

core.i_cache.cachedat.ram.r_data[54] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[55] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[56] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};
core.i_cache.cachedat.ram.r_data[57] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[58] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[59] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};
core.i_cache.cachedat.ram.r_data[60] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[61] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[62] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};
core.i_cache.cachedat.ram.r_data[63] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[64] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[65] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};
core.i_cache.cachedat.ram.r_data[66] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[67] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[68] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};
core.i_cache.cachedat.ram.r_data[69] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[70] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[71] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};
core.i_cache.cachedat.ram.r_data[72] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[73] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[74] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};
core.i_cache.cachedat.ram.r_data[75] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};
core.i_cache.cachedat.ram.r_data[76] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[77] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[78] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};

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

end

reg do_record = 0;
always @(posedge CPU_CLK)
  begin

    if (core.i_cache_pc_addr == 32'h6)
      do_record <= 1;

    if (do_record)
      begin
        $display("xOPC %x rPC %x f/d/xSKIP %x fSTALL %x dx_en %x  i_pc_a %x xBRA %x",
	         core.cpu.ibuf.xOPC, core.cpu.bpcu.rPC,
		 {core.cpu.bpcu.fSKIP,core.cpu.bpcu.dSKIP,
		  core.cpu.bpcu.xSKIP}, core.cpu.ctrl.fSTALL,
		 {core.cpu.bpcu.d_en,core.cpu.bpcu.x_en},
		 core.i_cache_pc_addr, core.cpu.bpcu.xBRA);
      end
  end
