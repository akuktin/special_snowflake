module aexm_regf (
   // Outputs
   xREGA, xREGB, c_io_rg, aexm_dcache_datao,
   // Inputs
   xOPC, rRW, rRDWE, xRD, rMXDST, rMXDST_use_combined, MEMOP_MXDST, rPC,
   rRESULT, rDWBSEL, aexm_dcache_datai, late_forward_D,
   gclk, x_en, d_en,
   dRA, dRB, dRD
   );
   // INTERNAL
   output [31:0] xREGA, xREGB;
   output [31:0] c_io_rg;
   input [5:0] 	 xOPC;
   input [4:0] 	 rRW, xRD;
   input [1:0] 	 rMXDST;
   input  	 MEMOP_MXDST;
   input [31:2]  rPC;
   input [31:0]  rRESULT;
   input [3:0] 	 rDWBSEL;
   input [4:0] 	 dRA, dRB, dRD;
  input 	 rMXDST_use_combined;
  input 	 rRDWE;
  input 	 late_forward_D;

   // MCU interface
   output [31:0] aexm_dcache_datao;
   input [31:0]  aexm_dcache_datai;

   // SYSTEM
   input 	 gclk, x_en, d_en;

   // --- LOAD SIZER ----------------------------------------------
   // Moves the data bytes around depending on the size of the
   // operation.

   wire [31:0] 	 wDWBDI = aexm_dcache_datai;

   reg [31:0] 	 rDWBDI, xDWBDI;

   always @(rDWBSEL or wDWBDI) begin
      // 52.0
      case (rDWBSEL)
	// 8'bit
	4'h8: xDWBDI <= {24'd0, wDWBDI[31:24]};
	4'h4: xDWBDI <= {24'd0, wDWBDI[23:16]};
	4'h2: xDWBDI <= {24'd0, wDWBDI[15:8]};
	4'h1: xDWBDI <= {24'd0, wDWBDI[7:0]};
	// 16'bit
	4'hC: xDWBDI <= {16'd0, wDWBDI[31:16]};
	4'h3: xDWBDI <= {16'd0, wDWBDI[15:0]};
	// 32'bit
	4'hF: xDWBDI <= wDWBDI;
	// Undefined
	default: xDWBDI <= 32'hX;
      endcase
   end

   // --- GENERAL PURPOSE REGISTERS (R0-R31) -----------------------
   // LUT RAM implementation is smaller and faster. R0 gets written
   // during reset with 0x00 and doesn't change after.

  reg [31:0]     combined_input;
  reg 		 w_en;

  wire [31:0] 	 xREGA, xREGB, xREGD;
  reg [31:0] 	 rREGD;

   reg [31:0] 	 xWDAT;
  wire 		 do_write;
  assign do_write = (rRDWE && w_en && (rMXDST != 2'o3));

  always @(rMXDST_use_combined or combined_input or rRESULT)
    if (!rMXDST_use_combined)
      xWDAT <= rRESULT;
    else
      xWDAT <= combined_input;

  iceram32 RAM_A(.RDATA(xREGA),
		 .RADDR({3'h0,dRA}),
		 .RE(d_en),
		 .RCLKE(1'b1),
		 .RCLK(!gclk),
		 .WDATA(xWDAT),
		 .MASK(0),
		 .WADDR({3'h0,rRW}),
		 .WE(do_write),
		 .WCLKE(1'b1),
		 .WCLK(!gclk));

  iceram32 RAM_B(.RDATA(xREGB),
		 .RADDR({3'h0,dRB}),
		 .RE(d_en),
		 .RCLKE(1'b1),
		 .RCLK(!gclk),
		 .WDATA(xWDAT),
		 .MASK(0),
		 .WADDR({3'h0,rRW}),
		 .WE(do_write),
		 .WCLKE(1'b1),
		 .WCLK(!gclk));

  iceram32 RAM_D(.RDATA(xREGD),
		 .RADDR({3'h0,dRD}),
		 .RE(d_en),
		 .RCLKE(1'b1),
		 .RCLK(!gclk),
		 .WDATA(xWDAT),
		 .MASK(0),
		 .WADDR({3'h0,rRW}),
		 .WE(do_write),
		 .WCLKE(1'b1),
		 .WCLK(!gclk));

   always @(posedge gclk)
     begin
       rDWBDI <= xDWBDI;
       w_en <= x_en;
       if (MEMOP_MXDST)
	 combined_input <= rDWBDI;
       else
	 combined_input <= {rPC,2'h0};

       if (late_forward_D)
	 rREGD <= rRESULT;
       else
	 rREGD <= xREGD;
     end

  assign c_io_rg = ((rRW == dRA) ||
		    (rRW == dRB)) ?
		   rRESULT : rDWBDI;

   // --- STORE SIZER ---------------------------------------------
   // Replicates the data bytes across depending on the size of the
   // operation.

   reg [31:0] 	 xDWBDO;

   wire [31:0] 	 xDST;
   wire 	 fDFWD_M = (rRW == xRD) & (rMXDST == 2'o2) & rRDWE;
   wire 	 fDFWD_R = (rRW == xRD) & (rMXDST == 2'o0) & rRDWE;

   assign 	 aexm_dcache_datao = xDWBDO;
   assign 	 xDST = (fDFWD_M) ? rDWBDI :
			(fDFWD_R) ? rRESULT :
			rREGD;

   always @(xOPC or xDST)
     case (xOPC[1:0])
       // 8'bit
       2'h0: xDWBDO <= {(4){xDST[7:0]}};
       // 16'bit
       2'h1: xDWBDO <= {(2){xDST[15:0]}};
       // 32'bit
       2'h2: xDWBDO <= xDST;
       default: xDWBDO <= 32'hX;
     endcase // case (xOPC[1:0])

   // --- SIMULATION ONLY ------------------------------------------
   // Randomise memory to simulate real-world memory
   // synopsys translate_off

   integer i;
   initial begin
      for (i=0; i<32; i=i+1) begin
	 RAM_A.ram.r_data[i] <= $random;
	 RAM_B.ram.r_data[i] <= $random;
	 RAM_D.ram.r_data[i] <= $random;
      end

    RAM_A.ram.r_data[0] <= 32'd0;
    RAM_B.ram.r_data[0] <= 32'd0;
    RAM_D.ram.r_data[0] <= 32'd0;
    RAM_A.ram.r_data[31] <= 32'd1;
    RAM_B.ram.r_data[31] <= 32'd1;
    RAM_D.ram.r_data[31] <= 32'd1;
   end

   // synopsys translate_on


endmodule // aexm_regf
