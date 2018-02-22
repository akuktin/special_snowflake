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
core.i_cache.cachedat.ram.r_data[0] <= {6'o01,5'h0,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[1] <= {6'o01,5'h0,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[2] <= {6'o01,5'h0,5'h0,5'h0,11'd0};



core.i_cache.cachedat.ram.r_data[3] <= {6'o52,5'h1,5'h0,16'hffff};
core.i_cache.cachedat.ram.r_data[4] <= {6'o00,5'h2,5'h1,5'h1,11'd0};
core.i_cache.cachedat.ram.r_data[5] <= {6'o52,5'h3,5'h2,16'hffff};
core.i_cache.cachedat.ram.r_data[6] <= {6'o52,5'h4,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[7] <= {6'o52,5'h5,5'h0,16'h0};

core.i_cache.cachedat.ram.r_data[8] <= {6'o01,5'h0,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[9] <= {6'o57,5'h0,5'h0,16'd8}; // eq  e
core.i_cache.cachedat.ram.r_data[10] <= {6'o52,5'h4,5'h4,16'h0001};
core.i_cache.cachedat.ram.r_data[11] <= {6'o57,5'h5,5'h0,16'd8}; // ge, e
core.i_cache.cachedat.ram.r_data[12] <= {6'o52,5'h4,5'h4,16'h0002};
core.i_cache.cachedat.ram.r_data[13] <= {6'o57,5'h5,5'h3,16'd8}; // ge  g
core.i_cache.cachedat.ram.r_data[14] <= {6'o52,5'h4,5'h4,16'h0004};
core.i_cache.cachedat.ram.r_data[15] <= {6'o57,5'h3,5'h0,16'd8}; // le  e
core.i_cache.cachedat.ram.r_data[16] <= {6'o52,5'h4,5'h4,16'h0008};
core.i_cache.cachedat.ram.r_data[17] <= {6'o57,5'h3,5'h1,16'd8}; // le  l
core.i_cache.cachedat.ram.r_data[18] <= {6'o52,5'h4,5'h4,16'h0010};
core.i_cache.cachedat.ram.r_data[19] <= {6'o57,5'h4,5'h3,16'd8}; // gt  g
core.i_cache.cachedat.ram.r_data[20] <= {6'o52,5'h4,5'h4,16'h0020};
core.i_cache.cachedat.ram.r_data[21] <= {6'o57,5'h2,5'h2,16'd8}; // lt  l
core.i_cache.cachedat.ram.r_data[22] <= {6'o52,5'h4,5'h4,16'h0040};
core.i_cache.cachedat.ram.r_data[23] <= {6'o57,5'h1,5'h1,16'd8}; // ne  n
core.i_cache.cachedat.ram.r_data[24] <= {6'o52,5'h4,5'h4,16'h0080};

core.i_cache.cachedat.ram.r_data[25] <= {6'o01,5'h0,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[26] <= {6'o01,5'h0,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[27] <= {6'o01,5'h0,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[28] <= {6'o01,5'h0,5'h0,5'h0,11'd0};

core.i_cache.cachedat.ram.r_data[29] <= {6'o57,5'h0,5'h1,16'd8}; // eq  n
core.i_cache.cachedat.ram.r_data[30] <= {6'o56,5'h0,5'h0,16'd8};
core.i_cache.cachedat.ram.r_data[31] <= {6'o52,5'h5,5'h5,16'h0001};
core.i_cache.cachedat.ram.r_data[32] <= {6'o57,5'h5,5'h1,16'd8}; // ge  l
core.i_cache.cachedat.ram.r_data[33] <= {6'o56,5'h0,5'h0,16'd8};
core.i_cache.cachedat.ram.r_data[34] <= {6'o52,5'h5,5'h5,16'h0002};
core.i_cache.cachedat.ram.r_data[35] <= {6'o57,5'h3,5'h3,16'd8}; // le  g
core.i_cache.cachedat.ram.r_data[36] <= {6'o56,5'h0,5'h0,16'd8};
core.i_cache.cachedat.ram.r_data[37] <= {6'o52,5'h5,5'h5,16'h0004};
core.i_cache.cachedat.ram.r_data[38] <= {6'o57,5'h4,5'h1,16'd8}; // gt  l
core.i_cache.cachedat.ram.r_data[39] <= {6'o56,5'h0,5'h0,16'd8};
core.i_cache.cachedat.ram.r_data[40] <= {6'o52,5'h5,5'h5,16'h0008};
core.i_cache.cachedat.ram.r_data[41] <= {6'o57,5'h4,5'h0,16'd8}; // gt  e
core.i_cache.cachedat.ram.r_data[42] <= {6'o56,5'h0,5'h0,16'd8};
core.i_cache.cachedat.ram.r_data[43] <= {6'o52,5'h5,5'h5,16'h0010};
core.i_cache.cachedat.ram.r_data[44] <= {6'o57,5'h2,5'h3,16'd8}; // lt  g
core.i_cache.cachedat.ram.r_data[45] <= {6'o56,5'h0,5'h0,16'd8};
core.i_cache.cachedat.ram.r_data[46] <= {6'o52,5'h5,5'h5,16'h0020};
core.i_cache.cachedat.ram.r_data[47] <= {6'o57,5'h2,5'h0,16'd8}; // lt  e
core.i_cache.cachedat.ram.r_data[48] <= {6'o56,5'h0,5'h0,16'd8};
core.i_cache.cachedat.ram.r_data[49] <= {6'o52,5'h5,5'h5,16'd0040};
core.i_cache.cachedat.ram.r_data[50] <= {6'o57,5'h1,5'h0,16'd8}; // ne  e
core.i_cache.cachedat.ram.r_data[51] <= {6'o56,5'h0,5'h0,16'd8};
core.i_cache.cachedat.ram.r_data[52] <= {6'o52,5'h5,5'h5,16'h0080};


core.i_cache.cachedat.ram.r_data[53] <= {6'o01,5'h0,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[55] <= {6'o01,5'h0,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[56] <= {6'o01,5'h0,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[57] <= {6'o01,5'h0,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[58] <= {6'o01,5'h0,5'h0,5'h0,11'd0};

core.i_cache.cachedat.ram.r_data[59] <= {6'o01,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[60] <= {6'o01,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[61] <= {6'o01,5'h1f,5'h1f,5'h1f,11'd11};
