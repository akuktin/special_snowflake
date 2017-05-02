module iceram32(output [31:0] RDATA,
		input [7:0]  RADDR,
		input 	     RE,
		input 	     RCLKE,
		input 	     RCLK,
		input [31:0] WDATA,
		input [31:0] MASK,
		input [7:0]  WADDR,
		input 	     WE,
		input 	     WCLKE,
		input 	     WCLK);

  SB_RAM256x16 block0(.RDATA(RDATA[15:0]),
		      .RADDR(RADDR),
		      .RE(RE),
		      .RCLKE(RCLKE),
		      .RCLK(RCLK),
		      .WDATA(WDATA[15:0]),
		      .MASK(MASK[15:0]),
		      .WADDR(WADDR),
		      .WE(WE),
		      .WCLKE(WCLKE),
		      .WCLK(WCLK));

  SB_RAM256x16 block1(.RDATA(RDATA[31:16]),
		      .RADDR(RADDR),
		      .RE(RE),
		      .RCLKE(RCLKE),
		      .RCLK(RCLK),
		      .WDATA(WDATA[31:16]),
		      .MASK(MASK[31:16]),
		      .WADDR(WADDR),
		      .WE(WE),
		      .WCLKE(WCLKE),
		      .WCLK(WCLK));

endmodule // iceram32

module iceram16(output [15:0] RDATA,
		input [7:0]  RADDR,
		input 	     RE,
		input 	     RCLKE,
		input 	     RCLK,
		input [15:0] WDATA,
		input [15:0] MASK,
		input [7:0]  WADDR,
		input 	     WE,
		input 	     WCLKE,
		input 	     WCLK);

  SB_RAM256x16 block0(.RDATA(RDATA),
		      .RADDR(RADDR),
		      .RE(RE),
		      .RCLKE(RCLKE),
		      .RCLK(RCLK),
		      .WDATA(WDATA),
		      .MASK(MASK),
		      .WADDR(WADDR),
		      .WE(WE),
		      .WCLKE(WCLKE),
		      .WCLK(WCLK));

endmodule // iceram16
