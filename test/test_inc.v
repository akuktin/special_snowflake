`define x16
`define sq5E

module ram_dp_true_m(input [31:0] DataInA,
                     input [31:0] DataInB,
                     input [7:0]  AddressA,
                     input [7:0]  AddressB,
                     input 	  ClockA,
                     input 	  ClockB,
                     input 	  ClockEnA,
                     input 	  ClockEnB,
                     input 	  WrA,
                     input 	  WrB,
                     output [31:0] QA,
                     output [31:0] QB);
  reg [31:0]            r_data[255:0];
  reg [7:0] 		addr_regA, addr_regB;

  assign QA = r_data[addr_regA];
  assign QB = r_data[addr_regB];

  always @(posedge ClockA)
    if (ClockEnA)
      begin
	if (WrA)
          r_data[AddressA] <= DataInA;
	addr_regA <= AddressA;
      end

  always @(posedge ClockB)
    if (ClockEnB)
      begin
	if (WrB)
          r_data[AddressB] <= DataInB;
	addr_regB <= AddressB;
      end

endmodule

module iceram32(output [31:0] RDATA,
		input [7:0]   RADDR,
		input 	      RE,
		input 	      RCLKE,
		input 	      RCLK,
		output [31:0] WDATA,
		input [31:0]  MASK,
		input [7:0]   WADDR,
		input 	      WE,
		input 	      WCLKE,
		input 	      WCLK);
  ram_dp_true_m ram(.DataInA(),
		    .DataInB(WDATA),
		    .AddressA(RADDR),
		    .AddressB(WADDR),
		    .ClockA(RCLK & RCLKE),
		    .ClockB(WCLK & WCLKE),
		    .ClockEnA(RE),
		    .ClockEnB(WE),
		    .WrA(1'b0),
		    .WrB(WE),
		    .QA(RDATA),
		    .QB());
endmodule // iceram32

module iceram16(output [15:0] RDATA,
		input [7:0]   RADDR,
		input 	      RE,
		input 	      RCLKE,
		input 	      RCLK,
		output [15:0] WDATA,
		input [15:0]  MASK,
		input [7:0]   WADDR,
		input 	      WE,
		input 	      WCLKE,
		input 	      WCLK);
  wire [15:0] 		      ignore;
  ram_dp_true_m ram(.DataInA(),
		    .DataInB({16'd0,WDATA}),
		    .AddressA(RADDR),
		    .AddressB(WADDR),
		    .ClockA(RCLK & RCLKE),
		    .ClockB(WCLK & WCLKE),
		    .ClockEnA(RE),
		    .ClockEnB(WE),
		    .WrA(1'b0),
		    .WrB(WE),
		    .QA({ignore,RDATA}),
		    .QB());
endmodule // iceram16

`include "ddr.v"
