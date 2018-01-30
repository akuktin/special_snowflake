module aexm_xecu (
   // Outputs
   aexm_dcache_precycle_addr,
   xRESULT, rRESULT, rDWBSEL, rMSR_IE,
   // Inputs
   xREGA, xREGB, dMXSRC, dMXTGT, xRA, xMXALU, xSKIP, xALT,
   dIMMVAL, xIMM, xOPC, dOPC, xRD, c_io_rg, rIPC, rPC, gclk, d_en, x_en
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
   input [1:0] 	   dMXSRC, dMXTGT;
   input [4:0] 	   xRA;
   input [2:0] 	   xMXALU;
   input [10:0]    xALT;
  input 	   xSKIP;

   input [31:0]    dIMMVAL;
   input [15:0]    xIMM;
   input [5:0] 	   xOPC, dOPC;
   input [4:0] 	   xRD;
   input [31:0]    c_io_rg;
   input [31:2]    rIPC, rPC;

   // SYSTEM
   input 	   gclk, d_en, x_en;

   reg 		   rMSR_BE = 1'b0, xMSR_BE;
   reg 		   rMSR_BIP = 1'b0, xMSR_BIP;
   reg 		   rMSR_C = 1'b0, xMSR_C;
   reg 		   rMSR_IE = 1'b0, xMSR_IE;

   // --- OPERAND SELECT

  reg [31:0] 	   rOPA = 32'hcecabeef, rOPB = 32'hb00000b5;
  reg 		   carry = 1'b0;

   always @(posedge gclk)
     if (d_en)
     case (dMXSRC)
       2'o0: rOPA <= dSUB ? ~xREGA : xREGA;
       2'o1: rOPA <= dSUB ? ~xRESULT : xRESULT;
       2'o2: rOPA <= dSUB ? ~c_io_rg : c_io_rg;
       2'o3: rOPA <= dSUB ? ~({rIPC, 2'o0}) : {rIPC, 2'o0};
     endcase // case (dMXSRC)

   always @(posedge gclk)
     if (d_en)
     case (dMXTGT)
       2'o0: rOPB <= xREGB;
       2'o1: rOPB <= xRESULT;
       2'o2: rOPB <= c_io_rg;
       2'o3: rOPB <= dIMMVAL;
     endcase // case (dMXTGT)

  always @(posedge gclk)
    if (d_en)
      carry <= dCCC ? xMSR_C : dSUB;

   // --- ADD/SUB SELECTOR ----

   reg 		    rRES_ADDC;
   reg [31:0] 	    rRES_ADD;

   wire [31:0] 		wADD;
   wire 		wADC;

  wire 			dCCC = !dOPC[5] & dOPC[1] & !dOPC[4];
  wire 			dSUB = !dOPC[5] & dOPC[0] & !dOPC[4];
// fCMP and wCMP are decommisioned until further notice
//   wire 		fCMP = !xOPC[3] & xIMM[1]; // unsigned only
//   wire 		wCMP = (fCMP) ? !wADC : wADD[31]; // cmpu adjust

   assign 		{wADC, wADD} = (rOPB + rOPA) + carry;

   always @(wADC or wADD /*or wCMP*/) begin
// wCMP decommisioned until further notice
//     {rRES_ADDC, rRES_ADD} <= {wADC, wCMP, wADD[30:0]};
     {rRES_ADDC, rRES_ADD} <= {wADC, wADD[31:0]};
   end

   // --- LOGIC SELECTOR --------------------------------------

   reg [31:0] 	    rRES_LOG;
   always @(rOPA or rOPB or xOPC)
     case (xOPC[1:0])
       2'o0: rRES_LOG <= rOPA | rOPB;
       2'o1: rRES_LOG <= rOPA & rOPB;
       2'o2: rRES_LOG <= rOPA ^ rOPB;
       2'o3: rRES_LOG <= rOPA & ~rOPB;
     endcase // case (xOPC[1:0])

   // --- SHIFTER SELECTOR ------------------------------------

   reg [31:0] 	    rRES_SFT;
   reg 		    rRES_SFTC;

   always @(xIMM or rMSR_C or rOPA)
     case (xIMM[6:5])
       2'o0: {rRES_SFT, rRES_SFTC} <= {rOPA[31],rOPA[31:0]};
       2'o1: {rRES_SFT, rRES_SFTC} <= {rMSR_C,rOPA[31:0]};
       2'o2: {rRES_SFT, rRES_SFTC} <= {1'b0,rOPA[31:0]};
       2'o3: {rRES_SFT, rRES_SFTC} <= (xIMM[0]) ? { {(16){rOPA[15]}}, rOPA[15:0], rMSR_C} :
				      { {(24){rOPA[7]}}, rOPA[7:0], rMSR_C};
     endcase // case (xIMM[6:5])

   // --- MOVE SELECTOR ---------------------------------------

   wire [31:0] 	    wMSR = {rMSR_C, 3'o0,
			    20'h05a5a,
			    4'h0, rMSR_BIP, rMSR_C, rMSR_IE, rMSR_BE};
   wire 	    fMFSR = (xOPC == 6'o45) & !xIMM[14] & xIMM[0];
   wire 	    fMFPC = (xOPC == 6'o45) & !xIMM[14] & !xIMM[0];
   reg [31:0] 	    rRES_MOV;
   always @(fMFPC or fMFSR or rOPA or rOPB or rPC or xRA
	    or wMSR)
     rRES_MOV <= (fMFSR) ? wMSR :
		 (fMFPC) ? rPC :
		 (xRA[3]) ? rOPB : // !?! WTF!
		 rOPA;

   // --- BARREL SHIFTER --------------------------------------

   reg [31:0] 	 rRES_BSF;
   reg [31:0] 	 xBSRL, xBSRA, xBSLL;

   // Infer a logical left barrel shifter.
   always @(rOPA or rOPB)
     xBSLL <= rOPA << rOPB[4:0];

   // Infer a logical right barrel shifter.
   always @(rOPA or rOPB)
     xBSRL <= rOPA >> rOPB[4:0];

   // Infer a arithmetic right barrel shifter.
   always @(rOPA or rOPB)
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
     if (!x_en) begin // TODO: maybe remove the if
	rBSRL <= xBSRL;
	rBSRA <= xBSRA;
	rBSLL <= xBSLL;
     end

   always @(xALT or rBSLL or rBSRA or rBSRL)
     case (xALT[10:9])
       2'd0: rRES_BSF <= rBSRL;
       2'd1: rRES_BSF <= rBSRA;
       2'd2: rRES_BSF <= rBSLL;
       default: rRES_BSF <= 32'hX;
     endcase // case (xALT[10:9])


   // --- MSR REGISTER -----------------

   // C
   wire 	   fMTS = (xOPC == 6'o45) & xIMM[14] & !xSKIP;
   wire 	   fADDC = ({xOPC[5:4], xOPC[2]} == 3'o0);

   always @(fADDC or fMTS or xSKIP or rMSR_C or xMXALU
	    or rOPA or rRES_ADDC or rRES_SFTC)
     if (xSKIP) begin
	xMSR_C <= rMSR_C;
     end else
       case (xMXALU)
	 3'o0: xMSR_C <= (fADDC) ? rRES_ADDC : rMSR_C;
	 3'o1: xMSR_C <= rMSR_C; // LOGIC
	 3'o2: xMSR_C <= rRES_SFTC; // SHIFT
	 3'o3: xMSR_C <= (fMTS) ? rOPA[2] : rMSR_C;
	 3'o4: xMSR_C <= rMSR_C;
	 3'o5: xMSR_C <= rMSR_C;
	 default: xMSR_C <= 1'hX;
       endcase // case (xMXALU)

   // IE/BIP/BE
   wire 	    fRTID = (xOPC == 6'o55) & xRD[0] & !xSKIP;
   wire 	    fRTBD = (xOPC == 6'o55) & xRD[1] & !xSKIP;
   wire 	    fBRK = ((xOPC == 6'o56) | (xOPC == 6'o66)) &
		    (xRA == 5'hC) & !xSKIP;
   wire 	    fINT = ((xOPC == 6'o56) | (xOPC == 6'o66)) &
		    (xRA == 5'hE) & !xSKIP;

   always @(fINT or fMTS or fRTID or rMSR_IE or rOPA)
     xMSR_IE <= (fINT) ? 1'b0 :
		(fRTID) ? 1'b1 :
		(fMTS) ? rOPA[1] :
		rMSR_IE;

   always @(fBRK or fMTS or fRTBD or rMSR_BIP or rOPA)
     xMSR_BIP <= (fBRK) ? 1'b1 :
		 (fRTBD) ? 1'b0 :
		 (fMTS) ? rOPA[3] :
		 rMSR_BIP;

   always @(fMTS or rMSR_BE or rOPA)
     xMSR_BE <= (fMTS) ? rOPA[0] : rMSR_BE;

   // --- RESULT SELECTOR -------------------------------------------
   // Selects results from functional units.
   reg [31:0] 	   rRESULT = 32'd0, xRESULT;

   // RESULT
   always @(xMXALU or rRES_ADD or rRES_BSF or rRES_LOG or
	    rRES_MOV or rRES_SFT)
       case (xMXALU)
	 3'o0: xRESULT <= rRES_ADD;
	 3'o1: xRESULT <= rRES_LOG;
	 3'o2: xRESULT <= rRES_SFT;
	 3'o3: xRESULT <= rRES_MOV;
	 3'o4: xRESULT <= 32'hX;
	 3'o5: xRESULT <= (BSF) ? rRES_BSF : 32'hX;
	 default: xRESULT <= 32'hX;
       endcase // case (xMXALU)

   // --- DATA WISHBONE -----

   reg [3:0] 	    rDWBSEL = 4'h0, xDWBSEL;
//   assign           aexm_dcache_precycle_addr = xRESULT[DW-1:2];
  assign aexm_dcache_precycle_addr = {rRES_ADD[31:29],2'h0,
				      rRES_ADD[28:2]};

   always @(xOPC or wADD)
     case (xOPC[1:0])
       2'o0: case (wADD[1:0]) // 8'bit
	       2'o0: xDWBSEL <= 4'h8;
	       2'o1: xDWBSEL <= 4'h4;
	       2'o2: xDWBSEL <= 4'h2;
	       2'o3: xDWBSEL <= 4'h1;
	     endcase // case (wADD[1:0])
       2'o1: xDWBSEL <= (wADD[1]) ? 4'h3 : 4'hC; // 16'bit
       2'o2: xDWBSEL <= 4'hF; // 32'bit
       2'o3: xDWBSEL <= 4'h0; // FSL
     endcase // case (xOPC[1:0])

   // --- SYNC ---

   always @(posedge gclk)
     begin
       if (x_en) begin
	 rRESULT <= xRESULT;
	 rMSR_C <= xMSR_C;
	 rMSR_IE <= xMSR_IE;
	 rMSR_BE <= xMSR_BE;
	 rMSR_BIP <= xMSR_BIP;
       end
       rDWBSEL <= xDWBSEL;
     end

endmodule // aexm_xecu
