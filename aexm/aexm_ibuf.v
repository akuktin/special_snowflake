module aexm_ibuf (/*AUTOARG*/
   // Outputs
   xIMM, xRA, xRD, xRB, xALT, xOPC, dOPC, dIMMVAL, dINST,
   dRA, dRB, dRD,
   // Inputs
   rMSR_IE, rBRA, aexm_icache_datai, sys_int_i, gclk, d_en, x_en
   );
   // INTERNAL
   output [15:0] xIMM;
   output [4:0]  xRA, xRD, xRB, dRA, dRB, dRD;
   output [10:0] xALT;
   output [5:0]  xOPC, dOPC;
   output [31:0] dIMMVAL;
   output [31:0] dINST;

   input 	 rMSR_IE;
  input 	 rBRA;

   // INST WISHBONE
   input [31:0]  aexm_icache_datai;

   // SYSTEM
   input 	 sys_int_i;
   input 	 gclk, d_en, x_en;

   reg [15:0] 	 xIMM = 16'd0;
   reg [4:0] 	 xRA = 5'h0, xRD = 5'h0;
   reg [5:0] 	 xOPC = 6'h0;

   assign 	 {xRB, xALT} = xIMM;

   wire [31:0] 	wINTOP = {6'o56,5'h1e,5'h0c,16'h0060}; // register to be
                                                       // changed to 5'h00
  reg 		issued_interrupt = 1'b0, cpu_interrupt = 1'b0;

  wire [31:0] 	dINST;

   // --- INTERRUPT LATCH --------------------------------------
   // Debounce and latch onto the positive level. This is independent
   // of the pipeline so that stalls do not affect it.

   reg 		rFINT = 1'b0;
   reg [1:0] 	rDINT = 2'h0;
   wire 	wSHOT = rDINT[0];

   always @(posedge gclk)
     begin
	if (rMSR_IE)
	  rDINT <= {rDINT[0], sys_int_i};

	// still needs some work
	rFINT <= issued_interrupt ? 1'b0 :
		 (rFINT | wSHOT) & rMSR_IE;
     end

  reg 		xIMM_sig = 1'b0, xIMM_sig_d = 1'b0;
  wire 		dIMM = (dOPC == 6'o54);
  wire 		dRTD = (dOPC == 6'o55);
  wire 		dBRU = ((dOPC == 6'o46) || (dOPC == 6'o56));
  wire 		dBCC = ((dOPC == 6'o47) || (dOPC == 6'o57));

  wire [31:0] 	dIMMVAL;

  wire 		interrupt_possible_braimm;
  wire 		d_is_branch;
  reg 		x_is_branch = 1'b0; // should actually be xBRA, but this
                                    // way is cheaper
  wire 		do_interrupt;

  assign do_interrupt = (rFINT && !issued_interrupt && !cpu_interrupt) &&
			interrupt_possible_braimm;

  assign dINST = cpu_interrupt ? wINTOP : aexm_icache_datai;

  assign dIMMVAL = (xIMM_sig) ?
		   {xIMM, dINST[15:0]} :
		   { {(16){dINST[15]}}, dINST[15:0]};

  // Protection from infinite non-branching branches: does not exist, or
  // isn't implemented. Instead, if we were to hit a bad actor which
  // tried to brick the CPU, we lay in wait and simply wait for him to
  // hit a branching branch instruction. It's going to happen eventually -
  // the kernel is trusted and the userland program will eventually
  // either branch or hit a page fault. They can't run forever.

  // The only thing missing is a register counting the number of non-taken
  // branches we laid in wait this way, for detecting this sort of thing.

  assign d_is_branch = (dRTD || dBRU || dBCC);
  assign interrupt_possible_braimm = !(xIMM_sig && !xIMM_sig_d) &&
				     (rBRA ?
				      1 :
				      !(d_is_branch || x_is_branch ));

   // --- REGISTER FILE ---------------------------------------

  wire [5:0] dOPC;
  wire [4:0] dRD, dRA, dRB;
  assign dOPC = dINST[31:26];
  assign dRD  = dINST[25:21];
  assign dRA  = dINST[20:16];
  assign dRB  = dINST[15:11];

   // --- PIPELINE --------------------------------------------

   always @(posedge gclk)
     begin
     if (d_en) begin
       cpu_interrupt <= do_interrupt;
       issued_interrupt <= cpu_interrupt;

       {xOPC, xRD, xRA, xIMM} <= dINST;

       xIMM_sig <= dIMM;
       x_is_branch <= d_is_branch;
     end
     if (x_en) begin
       xIMM_sig_d <= xIMM_sig;
     end
     end

endmodule // aexm_ibuf
