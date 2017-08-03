module aexm_xecu (/*AUTOARG*/
   // Outputs
   aexm_dcache_precycle_addr,
   xRESULT, rRESULT, rDWBSEL, rMSR_IE,
   // Inputs
   xREGA, xREGB, xMXSRC, xMXTGT, rRA, rRB, rMXALU, xSKIP, rALT,
   xSIMM, rIMM, rOPC, xOPC, rRD, rDWBDI, rIPC, rPC, gclk, grst, d_en, x_en
   );
   parameter DW=32;

   parameter BSF=0;

   // DATA interface
   output [DW-1:0] aexm_dcache_precycle_addr;

   // INTERNAL
   output [31:0]   xRESULT;
   output [31:0]   rRESULT;
   output [3:0]    rDWBSEL;
   output 	   rMSR_IE;
   input [31:0]    xREGA, xREGB;
   input [1:0] 	   xMXSRC, xMXTGT;
   input [4:0] 	   rRA, rRB;
   input [2:0] 	   rMXALU;
   input [10:0]    rALT;
  input 	   xSKIP;

   input [31:0]    xSIMM;
   input [15:0]    rIMM;
   input [5:0] 	   rOPC, xOPC;
   input [4:0] 	   rRD;
   input [31:0]    rDWBDI;
   input [31:2]    rIPC, rPC;

   // SYSTEM
   input 	   gclk, grst, d_en, x_en;

   reg 		   rMSR_C, xMSR_C;
   reg 		   rMSR_IE, xMSR_IE;
   reg 		   rMSR_BE, xMSR_BE;
   reg 		   rMSR_BIP, xMSR_BIP;

   // --- OPERAND SELECT

   reg [31:0] 	   rOPA, rOPB;
   always @(posedge gclk)
     if (grst)
       rOPA <= 0;
     else if (d_en)
     case (xMXSRC)
       2'o0: rOPA <= xREGA;
       2'o1: rOPA <= fSUB ? ~xRESULT : xRESULT;
       2'o2: rOPA <= rDWBDI;
       2'o3: rOPA <= {rIPC, 2'o0};
     endcase // case (xMXSRC)

   always @(posedge gclk)
     if (grst)
       rOPB <= 0;
     else if (d_en)
     case (xMXTGT)
       2'o0: rOPB <= xREGB;
       2'o1: rOPB <= xRESULT;
       2'o2: rOPB <= rDWBDI;
       2'o3: rOPB <= xSIMM;
     endcase // case (xMXTGT)

  reg 		   wOPC;
  always @(posedge gclk)
    if (grst)
      wOPC <= 0;
    else if (d_en)
      wOPC <= fCCC ? xMSR_C : fSUB;

   // --- ADD/SUB SELECTOR ----

   reg 		    rRES_ADDC;
   reg [31:0] 	    rRES_ADD;

   wire [31:0] 		wADD;
   wire 		wADC;

  wire 			fCCC = !xOPC[5] & xOPC[1] & !xOPC[4];
  wire 			fSUB = !xOPC[5] & xOPC[0] & !xOPC[4];
// fCMP and wCMP are decommisioned until further notice
//   wire 		fCMP = !rOPC[3] & rIMM[1]; // unsigned only
//   wire 		wCMP = (fCMP) ? !wADC : wADD[31]; // cmpu adjust

   assign 		{wADC, wADD} = (rOPB + rOPA) + wOPC; // add carry

   always @(wADC or wADD /*or wCMP*/) begin
// wCMP decommisioned until further notice
//     {rRES_ADDC, rRES_ADD} <= #1 {wADC, wCMP, wADD[30:0]};
     {rRES_ADDC, rRES_ADD} <= #1 {wADC, wADD[31:0]};
   end

   // --- LOGIC SELECTOR --------------------------------------

   reg [31:0] 	    rRES_LOG;
   always @(/*AUTOSENSE*/rOPA or rOPB or rOPC)
     case (rOPC[1:0])
       2'o0: rRES_LOG <= #1 rOPA | rOPB;
       2'o1: rRES_LOG <= #1 rOPA & rOPB;
       2'o2: rRES_LOG <= #1 rOPA ^ rOPB;
       2'o3: rRES_LOG <= #1 rOPA & ~rOPB;
     endcase // case (rOPC[1:0])

   // --- SHIFTER SELECTOR ------------------------------------

   reg [31:0] 	    rRES_SFT;
   reg 		    rRES_SFTC;

   always @(/*AUTOSENSE*/rIMM or rMSR_C or rOPA)
     case (rIMM[6:5])
       2'o0: {rRES_SFT, rRES_SFTC} <= #1 {rOPA[31],rOPA[31:0]};
       2'o1: {rRES_SFT, rRES_SFTC} <= #1 {rMSR_C,rOPA[31:0]};
       2'o2: {rRES_SFT, rRES_SFTC} <= #1 {1'b0,rOPA[31:0]};
       2'o3: {rRES_SFT, rRES_SFTC} <= #1 (rIMM[0]) ? { {(16){rOPA[15]}}, rOPA[15:0], rMSR_C} :
				      { {(24){rOPA[7]}}, rOPA[7:0], rMSR_C};
     endcase // case (rIMM[6:5])

   // --- MOVE SELECTOR ---------------------------------------

   wire [31:0] 	    wMSR = {rMSR_C, 3'o0,
			    20'h0ED32,
			    4'h0, rMSR_BIP, rMSR_C, rMSR_IE, rMSR_BE};
   wire 	    fMFSR = (rOPC == 6'o45) & !rIMM[14] & rIMM[0];
   wire 	    fMFPC = (rOPC == 6'o45) & !rIMM[14] & !rIMM[0];
   reg [31:0] 	    rRES_MOV;
   always @(/*AUTOSENSE*/fMFPC or fMFSR or rOPA or rOPB or rPC or rRA
	    or wMSR)
     rRES_MOV <= (fMFSR) ? wMSR :
		 (fMFPC) ? rPC :
		 (rRA[3]) ? rOPB :
		 rOPA;

   // --- BARREL SHIFTER --------------------------------------

   reg [31:0] 	 rRES_BSF;
   reg [31:0] 	 xBSRL, xBSRA, xBSLL;

   // Infer a logical left barrel shifter.
   always @(/*AUTOSENSE*/rOPA or rOPB)
     xBSLL <= rOPA << rOPB[4:0];

   // Infer a logical right barrel shifter.
   always @(/*AUTOSENSE*/rOPA or rOPB)
     xBSRL <= rOPA >> rOPB[4:0];

   // Infer a arithmetic right barrel shifter.
   always @(/*AUTOSENSE*/rOPA or rOPB)
     case (rOPB[4:0])
       5'd00: xBSRA <= rOPA;
       5'd01: xBSRA <= {{(1){rOPA[31]}}, rOPA[31:1]};
       5'd02: xBSRA <= {{(2){rOPA[31]}}, rOPA[31:2]};
       5'd03: xBSRA <= {{(3){rOPA[31]}}, rOPA[31:3]};
       5'd04: xBSRA <= {{(4){rOPA[31]}}, rOPA[31:4]};
       5'd05: xBSRA <= {{(5){rOPA[31]}}, rOPA[31:5]};
       5'd06: xBSRA <= {{(6){rOPA[31]}}, rOPA[31:6]};
       5'd07: xBSRA <= {{(7){rOPA[31]}}, rOPA[31:7]};
       5'd08: xBSRA <= {{(8){rOPA[31]}}, rOPA[31:8]};
       5'd09: xBSRA <= {{(9){rOPA[31]}}, rOPA[31:9]};
       5'd10: xBSRA <= {{(10){rOPA[31]}}, rOPA[31:10]};
       5'd11: xBSRA <= {{(11){rOPA[31]}}, rOPA[31:11]};
       5'd12: xBSRA <= {{(12){rOPA[31]}}, rOPA[31:12]};
       5'd13: xBSRA <= {{(13){rOPA[31]}}, rOPA[31:13]};
       5'd14: xBSRA <= {{(14){rOPA[31]}}, rOPA[31:14]};
       5'd15: xBSRA <= {{(15){rOPA[31]}}, rOPA[31:15]};
       5'd16: xBSRA <= {{(16){rOPA[31]}}, rOPA[31:16]};
       5'd17: xBSRA <= {{(17){rOPA[31]}}, rOPA[31:17]};
       5'd18: xBSRA <= {{(18){rOPA[31]}}, rOPA[31:18]};
       5'd19: xBSRA <= {{(19){rOPA[31]}}, rOPA[31:19]};
       5'd20: xBSRA <= {{(20){rOPA[31]}}, rOPA[31:20]};
       5'd21: xBSRA <= {{(21){rOPA[31]}}, rOPA[31:21]};
       5'd22: xBSRA <= {{(22){rOPA[31]}}, rOPA[31:22]};
       5'd23: xBSRA <= {{(23){rOPA[31]}}, rOPA[31:23]};
       5'd24: xBSRA <= {{(24){rOPA[31]}}, rOPA[31:24]};
       5'd25: xBSRA <= {{(25){rOPA[31]}}, rOPA[31:25]};
       5'd26: xBSRA <= {{(26){rOPA[31]}}, rOPA[31:26]};
       5'd27: xBSRA <= {{(27){rOPA[31]}}, rOPA[31:27]};
       5'd28: xBSRA <= {{(28){rOPA[31]}}, rOPA[31:28]};
       5'd29: xBSRA <= {{(29){rOPA[31]}}, rOPA[31:29]};
       5'd30: xBSRA <= {{(30){rOPA[31]}}, rOPA[31:30]};
       5'd31: xBSRA <= {{(31){rOPA[31]}}, rOPA[31]};
     endcase // case (rOPB[4:0])

   reg [31:0] 	 rBSRL, rBSRA, rBSLL;

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rBSLL <= 32'h0;
	rBSRA <= 32'h0;
	rBSRL <= 32'h0;
	// End of automatics
     end else if (!x_en) begin // TODO: maybe remove the if
	rBSRL <= #1 xBSRL;
	rBSRA <= #1 xBSRA;
	rBSLL <= #1 xBSLL;
     end

   always @(/*AUTOSENSE*/rALT or rBSLL or rBSRA or rBSRL)
     case (rALT[10:9])
       2'd0: rRES_BSF <= rBSRL;
       2'd1: rRES_BSF <= rBSRA;
       2'd2: rRES_BSF <= rBSLL;
       default: rRES_BSF <= 32'hX;
     endcase // case (rALT[10:9])


   // --- MSR REGISTER -----------------

   // C
   wire 	   fMTS = (rOPC == 6'o45) & rIMM[14] & !xSKIP;
   wire 	   fADDC = ({rOPC[5:4], rOPC[2]} == 3'o0);

   always @(/*AUTOSENSE*/fADDC or fMTS or xSKIP or rMSR_C or rMXALU
	    or rOPA or rRES_ADDC or rRES_SFTC)
     if (xSKIP) begin
	xMSR_C <= rMSR_C;
     end else
       case (rMXALU)
	 3'o0: xMSR_C <= (fADDC) ? rRES_ADDC : rMSR_C;
	 3'o1: xMSR_C <= rMSR_C; // LOGIC
	 3'o2: xMSR_C <= rRES_SFTC; // SHIFT
	 3'o3: xMSR_C <= (fMTS) ? rOPA[2] : rMSR_C;
	 3'o4: xMSR_C <= rMSR_C;
	 3'o5: xMSR_C <= rMSR_C;
	 default: xMSR_C <= 1'hX;
       endcase // case (rMXALU)

   // IE/BIP/BE
   wire 	    fRTID = (rOPC == 6'o55) & rRD[0] & !xSKIP;
   wire 	    fRTBD = (rOPC == 6'o55) & rRD[1] & !xSKIP;
   wire 	    fBRK = ((rOPC == 6'o56) | (rOPC == 6'o66)) & (rRA == 5'hC) & !xSKIP;
   wire 	    fINT = ((rOPC == 6'o56) | (rOPC == 6'o66)) & (rRA == 5'hE) & !xSKIP;

   always @(/*AUTOSENSE*/fINT or fMTS or fRTID or rMSR_IE or rOPA)
     xMSR_IE <= (fINT) ? 1'b0 :
		(fRTID) ? 1'b1 :
		(fMTS) ? rOPA[1] :
		rMSR_IE;

   always @(/*AUTOSENSE*/fBRK or fMTS or fRTBD or rMSR_BIP or rOPA)
     xMSR_BIP <= (fBRK) ? 1'b1 :
		 (fRTBD) ? 1'b0 :
		 (fMTS) ? rOPA[3] :
		 rMSR_BIP;

   always @(/*AUTOSENSE*/fMTS or rMSR_BE or rOPA)
     xMSR_BE <= (fMTS) ? rOPA[0] : rMSR_BE;

   // --- RESULT SELECTOR -------------------------------------------
   // Selects results from functional units.
   reg [31:0] 	   rRESULT, xRESULT;

   // RESULT
   always @(rMXALU or rRES_ADD or rRES_BSF or rRES_LOG or
	    rRES_MOV or rRES_SFT)
       case (rMXALU)
	 3'o0: xRESULT <= rRES_ADD;
	 3'o1: xRESULT <= rRES_LOG;
	 3'o2: xRESULT <= rRES_SFT;
	 3'o3: xRESULT <= rRES_MOV;
	 3'o4: xRESULT <= 32'hX;
	 3'o5: xRESULT <= (BSF) ? rRES_BSF : 32'hX;
	 default: xRESULT <= 32'hX;
       endcase // case (rMXALU)

   // --- DATA WISHBONE -----

   reg [3:0] 	    rDWBSEL, xDWBSEL;
//   assign           aexm_dcache_precycle_addr = xRESULT[DW-1:2];
  assign aexm_dcache_precycle_addr = {xRESULT[31:29],2'h0,
				      xRESULT[28:2]};

   always @(/*AUTOSENSE*/rOPC or wADD)
     case (rOPC[1:0])
       2'o0: case (wADD[1:0]) // 8'bit
	       2'o0: xDWBSEL <= 4'h8;
	       2'o1: xDWBSEL <= 4'h4;
	       2'o2: xDWBSEL <= 4'h2;
	       2'o3: xDWBSEL <= 4'h1;
	     endcase // case (wADD[1:0])
       2'o1: xDWBSEL <= (wADD[1]) ? 4'h3 : 4'hC; // 16'bit
       2'o2: xDWBSEL <= 4'hF; // 32'bit
       2'o3: xDWBSEL <= 4'h0; // FSL
     endcase // case (rOPC[1:0])

   // --- SYNC ---

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rDWBSEL <= 4'h0;
	rMSR_BE <= 1'h0;
	rMSR_BIP <= 1'h0;
	rMSR_C <= 1'h0;
	rMSR_IE <= 1'h0;
	rRESULT <= 32'h0;
	// End of automatics
     end else begin // if (grst)
       if (x_en) begin
	rRESULT <= #1 xRESULT;
	rMSR_C <= #1 xMSR_C;
	rMSR_IE <= #1 xMSR_IE;
	rMSR_BE <= #1 xMSR_BE;
	rMSR_BIP <= #1 xMSR_BIP;
       end
       rDWBSEL <= xDWBSEL;
     end

endmodule // aexm_xecu
