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


core.i_cache.cachedat.ram.r_data[3] <= {6'o10,5'h4,5'h0,16'h0000};
core.i_cache.cachedat.ram.r_data[4] <= {6'o10,5'h5,5'h0,16'h0000};
core.i_cache.cachedat.ram.r_data[5] <= {6'o10,5'h6,5'h0,16'h0000};



core.i_cache.cachedat.ram.r_data[6] <= {6'o56,5'h18,5'h00,16'h0014};
//core.i_cache.cachedat.ram.r_data[6] <= {6'o10,5'h4,5'h4,16'h8000};
core.i_cache.cachedat.ram.r_data[7] <= {6'o10,5'h4,5'h4,16'h0001};
core.i_cache.cachedat.ram.r_data[8] <= {6'o10,5'h4,5'h4,16'h0002};
core.i_cache.cachedat.ram.r_data[9] <= {6'o10,5'h4,5'h4,16'h0004};
core.i_cache.cachedat.ram.r_data[10] <= {6'o10,5'h4,5'h4,16'h0010};

core.i_cache.cachedat.ram.r_data[11] <= {6'o56,5'h19,5'h10,16'h0014};
//core.i_cache.cachedat.ram.r_data[11] <= {6'o10,5'h5,5'h5,16'h8000};
core.i_cache.cachedat.ram.r_data[12] <= {6'o10,5'h5,5'h5,16'h0001};
core.i_cache.cachedat.ram.r_data[13] <= {6'o10,5'h5,5'h5,16'h0002};
core.i_cache.cachedat.ram.r_data[14] <= {6'o10,5'h5,5'h5,16'h0004};
core.i_cache.cachedat.ram.r_data[15] <= {6'o10,5'h5,5'h5,16'h0010};

core.i_cache.cachedat.ram.r_data[16] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[17] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[18] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};


core.i_cache.cachedat.ram.r_data[24] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[25] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[26] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};

core.i_cache.cachedat.ram.r_data[96] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[97] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[98] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};
core.i_cache.cachedat.ram.r_data[99] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};
core.i_cache.cachedat.ram.r_data[100] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};

end
