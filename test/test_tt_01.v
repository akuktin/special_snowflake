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
//core.i_cache.cachedat.ram.r_data[6] <= {6'o52,5'h4,5'h0,16'h4020};
core.i_cache.cachedat.ram.r_data[6] <= {6'o52,5'h4,5'h0,16'h0124};
core.i_cache.cachedat.ram.r_data[7] <= {6'o52,5'h5,5'h0,16'h0};


core.i_cache.cachedat.ram.r_data[8] <= {6'o72,5'he,5'h0,16'h0820};
core.i_cache.cachedat.ram.r_data[9] <= {6'o76,5'h3,5'h0,16'h0120};
core.i_cache.cachedat.ram.r_data[10] <= {6'o76,5'h4,5'h0,16'h0124};
core.i_cache.cachedat.ram.r_data[11] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[12] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[13] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[14] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[15] <= {6'o72,5'hc,5'h0,16'h0800};
core.i_cache.cachedat.ram.r_data[16] <= {6'o62,5'hd,5'h0,5'h4,11'h001};
core.i_cache.cachedat.ram.r_data[17] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[18] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[19] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[20] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[21] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[22] <= {6'o42,5'h1f,5'h1f,5'h1f,11'd0};
core.i_cache.cachedat.ram.r_data[23] <= {6'o42,5'h1f,5'h1f,5'h1f,11'd0};
core.i_cache.cachedat.ram.r_data[24] <= {6'o42,5'h1f,5'h1f,5'h1f,11'd0};

// nil/8'hc1: 2x refresh, 399031500/400171500 (-190)
// nil/8'hc2: 2x refresh, 399025500/400171500 (-191)
//  -1/8'hb9: 2x refresh, 398695500/400171500 (-246)
// nil/8'hb9: 2x refresh, 399847500/400171500 ( -54)
// nil/8'h29: 1x refresh, 400711500/400171500 (  90)
// nil/8'h83: 2x refresh, 400171500/400345500 ( -29)

// nil/8'h84: 2x refresh, 400165500/400339500 ( -29)
// nil/8'h82: 1x refresh, (400171500) 400243500/400417500 ( -29)

//core.hyper_softcore.small_carousel <= 8'h83; // last regular
//core.hyper_softcore.small_carousel <= 8'h82; // first double activate
//core.hyper_softcore.small_carousel <= 8'h7f; // first w/ refresh just aftr
//core.hyper_softcore.small_carousel <= 8'h7a; // refreshes realign

// start 8'h84 stop 8'h79

core.hyper_softcore.small_carousel <= 8'h79;
