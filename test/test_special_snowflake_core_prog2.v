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
//i_cache.cachedat.ram.r_data[2] <= {6'o01,5'h0,5'h0,5'h0,11'd0}; // orig
core.i_cache.cachedat.ram.r_data[2] <= {6'o45,5'h0,5'h0a,16'h4000};

// init the DRAM counter increment, address and limit
core.i_cache.cachedat.ram.r_data[3] <= {6'o10,5'h3,5'h0,16'h0004};
core.i_cache.cachedat.ram.r_data[4] <= {6'o10,5'h4,5'h0,16'h00c0};
core.i_cache.cachedat.ram.r_data[5] <= {6'o10,5'h10,5'h0,16'h1000};
core.i_cache.cachedat.ram.r_data[6] <= {6'o01,5'h11,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[7] <= {6'o42,5'h12,5'h4,5'h0,11'd0};

// prepare the DMA operation
core.i_cache.cachedat.ram.r_data[8] <= {6'o00,5'h1,5'h8,5'd0,11'h408};
core.i_cache.cachedat.ram.r_data[9] <= {6'o00,5'h2,5'h9,5'd0,11'h408};

// issue the DMA operation
core.i_cache.cachedat.ram.r_data[10] <= {6'o66,5'h2,5'h0,5'h1,11'd0};

// loop
// false
//i_cache.cachedat.ram.r_data[11] <= {6'o57,5'h3,5'h12,16'h0014};
// correct
core.i_cache.cachedat.ram.r_data[11] <= {6'o57,5'h3,5'h12,16'h0014};
core.i_cache.cachedat.ram.r_data[12] <= {6'o00,5'h11,5'h11,5'h3,11'd0};
core.i_cache.cachedat.ram.r_data[13] <= {6'o01,5'h12,5'h11,5'h4,11'd0};
core.i_cache.cachedat.ram.r_data[14] <= {6'o66,5'h11,5'h10,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[15] <= {6'o56,5'hf,5'h0,16'hfff0};

// terminate
core.i_cache.cachedat.ram.r_data[16] <= {6'o62,5'h1d,5'h0,5'h1,11'd0}; // load
core.i_cache.cachedat.ram.r_data[17] <= {6'o00,5'h1b,5'h1b,5'h3,11'd0};
//i_cache.cachedat.ram.r_data[16] <= {6'o00,5'h0,5'h0,5'h0,11'd0};
//i_cache.cachedat.ram.r_data[17] <= {6'o00,5'h0,5'h0,5'h0,11'd0};
core.i_cache.cachedat.ram.r_data[18] <= {6'o00,5'h0,5'h0,5'h0,11'd0};

core.i_cache.cachedat.ram.r_data[19] <= {6'o62,5'h1d,5'h0,5'h1,11'd1}; // load
core.i_cache.cachedat.ram.r_data[20] <= {6'o00,5'h18,5'h1d,5'h0,11'd1};
core.i_cache.cachedat.ram.r_data[21] <= {6'o00,5'h19,5'h1d,5'h0,11'd1};
core.i_cache.cachedat.ram.r_data[22] <= {6'o00,5'h1a,5'h1d,5'h0,11'd1};
core.i_cache.cachedat.ram.r_data[23] <= {6'o00,5'h1b,5'h1d,5'h0,11'd1};

core.i_cache.cachedat.ram.r_data[24] <= {6'o62,5'h1c,5'h0,5'h3,11'd1}; // load
core.i_cache.cachedat.ram.r_data[25] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[26] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd10};
core.i_cache.cachedat.ram.r_data[27] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd11};


/*
core.i_cache.cachedat.ram.r_data[3] <= {6'o52,5'h1,5'h0,16'hffff};
core.i_cache.cachedat.ram.r_data[4] <= {6'o00,5'h2,5'h1,5'h1,11'd0};
core.i_cache.cachedat.ram.r_data[5] <= {6'o02,5'h3,5'h2,5'h0,11'd0};

core.i_cache.cachedat.ram.r_data[6] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[6] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[7] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
core.i_cache.cachedat.ram.r_data[8] <= {6'o05,5'h1f,5'h1f,5'h1f,11'd9};
*/
