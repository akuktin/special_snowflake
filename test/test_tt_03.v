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

core.i_cache.cachedat.ram.r_data[11] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[12] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[13] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[14] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[15] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[16] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[17] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[18] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[19] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[20] <= {6'o52,5'h5,5'h0,16'h0};
core.i_cache.cachedat.ram.r_data[21] <= {6'o52,5'h5,5'h0,16'h0};


core.i_cache.cachedat.ram.r_data[3] <= {6'o52,5'h1,5'h0,16'hffff};
core.i_cache.cachedat.ram.r_data[4] <= {6'o00,5'h2,5'h1,5'h1,11'd0};
core.i_cache.cachedat.ram.r_data[5] <= {6'o52,5'h3,5'h2,16'hffff};
core.i_cache.cachedat.ram.r_data[6] <= {6'o31,5'h4,5'h1,16'h0011};
core.i_cache.cachedat.ram.r_data[7] <= {6'o10,5'h4,5'h4,16'h7005};

core.i_cache.cachedat.ram.r_data[8] <= {6'o76,5'h2,5'h0,16'h8024};
core.i_cache.cachedat.ram.r_data[9] <= {6'o10,5'h7,5'h0,16'h1};

core.i_cache.cachedat.ram.r_data[10] <= {6'o76,5'h4,5'h0,16'h0004};
core.i_cache.cachedat.ram.r_data[11] <= {6'o10,5'h4,5'h4,16'h1};
core.i_cache.cachedat.ram.r_data[12] <= {6'o76,5'h4,5'h0,16'h0008};
core.i_cache.cachedat.ram.r_data[13] <= {6'o10,5'h4,5'h4,16'h1};
core.i_cache.cachedat.ram.r_data[14] <= {6'o76,5'h4,5'h0,16'h000c};
//core.i_cache.cachedat.ram.r_data[14] <= {6'o72,5'h4,5'h0,16'h000c};

core.i_cache.cachedat.ram.r_data[15] <= {6'o72,5'h4,5'h0,16'h0010};

core.i_cache.cachedat.ram.r_data[16] <= {6'o10,5'h18,5'h0,16'h0100};
core.i_cache.cachedat.ram.r_data[17] <= {6'o57,5'h11,5'h18,16'h0000};
core.i_cache.cachedat.ram.r_data[18] <= {6'o01,5'h18,5'h7,5'h18,11'd0};


core.i_cache.cachedat.ram.r_data[22] <= {6'o42,5'h1f,5'h1f,5'h1f,11'd0};
core.i_cache.cachedat.ram.r_data[23] <= {6'o42,5'h1f,5'h1f,5'h1f,11'd0};
core.i_cache.cachedat.ram.r_data[24] <= {6'o42,5'h1f,5'h1f,5'h1f,11'd0};

core.hyper_softcore.prog_mem.ram.r_data[0] <= 16'h4e00;
//// DATA !
core.hyper_softcore.data_mem.ram.r_data[0] <= 16'h0018; //// DATA !
core.hyper_softcore.data_mem.ram.r_data[64] <= 16'h0009; // magic value!
//core.hyper_softcore.data_mem.ram.r_data[64] <= 16'h000a;
core.hyper_softcore.data_mem.ram.r_data[128] <= 16'h0001;
core.hyper_softcore.data_mem.ram.r_data[129] <= 16'h0000;
core.hyper_softcore.data_mem.ram.r_data[130] <= 16'h400d;
//// DATA !
core.hyper_softcore.prog_mem.ram.r_data[4] <= 16'h4a00;
core.hyper_softcore.prog_mem.ram.r_data[5] <= 16'h4605;

core.hyper_softcore.prog_mem.ram.r_data[8] <= 16'h0a05;
core.hyper_softcore.prog_mem.ram.r_data[9] <= 16'hce10;
core.hyper_softcore.prog_mem.ram.r_data[10] <= 16'h4e00;
core.hyper_softcore.prog_mem.ram.r_data[11] <= 16'h4e00;
core.hyper_softcore.prog_mem.ram.r_data[12] <= 16'h6a00;
core.hyper_softcore.prog_mem.ram.r_data[13] <= 16'hce08;
core.hyper_softcore.prog_mem.ram.r_data[14] <= 16'h4e00;
core.hyper_softcore.prog_mem.ram.r_data[15] <= 16'h4e00;

core.hyper_softcore.prog_mem.ram.r_data[16] <= 16'h0a40;
core.hyper_softcore.prog_mem.ram.r_data[17] <= 16'h4812;

core.hyper_softcore.prog_mem.ram.r_data[18] <= 16'h0a80;
core.hyper_softcore.prog_mem.ram.r_data[19] <= 16'h6b04;
core.hyper_softcore.prog_mem.ram.r_data[20] <= 16'h0a81;
core.hyper_softcore.prog_mem.ram.r_data[21] <= 16'h6b05;
core.hyper_softcore.prog_mem.ram.r_data[22] <= 16'h0a82;
core.hyper_softcore.prog_mem.ram.r_data[23] <= 16'h4b06;

core.hyper_softcore.prog_mem.ram.r_data[26] <= 16'h6a00;
core.hyper_softcore.prog_mem.ram.r_data[27] <= 16'hce18;



//core.hyper_softcore.prog_mem.ram.r_data[254] <= 16'h6a00;
//core.hyper_softcore.prog_mem.ram.r_data[255] <= 16'h46ff;


core.d_cache.cachetag.ram.r_data[3] <= 16'hffff;
core.d_cache.cachetag.ram.r_data[4] <= 16'hffff;

core.hyper_softcore.big_carousel <= 4'h4;
//core.hyper_softcore.small_carousel <= 8'h5b; // all is fine
//core.hyper_softcore.small_carousel <= 8'h5c; // ERROR!!!
//core.hyper_softcore.small_carousel <= 8'h5e; // wrong transaction (Mbps)
//core.hyper_softcore.small_carousel <= 8'h5e; // (other cycle)

// start 8'h5a stop 8'h5f
force core.hyper_softcore.time_mb = 0;
`define CHANGER 8'h5a

core.hyper_softcore.small_carousel <= `CHANGER;
