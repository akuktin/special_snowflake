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


// test: just perform a simple XOR of registers 30 and  31 to prove the
//       CPU has its berings straight


core.i_cache.cachedat.ram.r_data[3] <= {6'o42,5'h1e,5'h1e,5'h1e,11'd0};
core.i_cache.cachedat.ram.r_data[4] <= {6'o42,5'h1e,5'h1e,5'h1e,11'd0};

core.i_cache.cachedat.ram.r_data[5] <= {6'o42,5'h1f,5'h1f,5'h1f,11'd0};
core.i_cache.cachedat.ram.r_data[6] <= {6'o42,5'h1f,5'h1f,5'h1f,11'd0};
core.i_cache.cachedat.ram.r_data[7] <= {6'o42,5'h1f,5'h1f,5'h1f,11'd0};
core.i_cache.cachedat.ram.r_data[8] <= {6'o42,5'h1f,5'h1f,5'h1f,11'd0};
core.i_cache.cachedat.ram.r_data[9] <= {6'o42,5'h1f,5'h1f,5'h1f,11'd0};
