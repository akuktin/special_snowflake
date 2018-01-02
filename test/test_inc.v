`define x16
// DDR
//`define sq5E
// DDR2
`define sg25E

module ram_dp_true_m(input [31:0] DataInA,
                     input [31:0]      DataInB,
                     input [7:0]       AddressA,
                     input [7:0]       AddressB,
		     input 	       REnA,
		     input 	       REnB,
                     input 	       ClockA,
                     input 	       ClockB,
                     input 	       ClockEnA,
                     input 	       ClockEnB,
                     input 	       WrA,
                     input 	       WrB,
                     output reg [31:0] QA,
                     output reg [31:0] QB);
  reg [31:0]            r_data[255:0];

  always @(posedge ClockA & ClockEnA)
    begin
      if (WrA)
        r_data[AddressA] <= DataInA;
      if (REnA)
	QA <= r_data[AddressA];
    end

  always @(posedge ClockB & ClockEnB)
    begin
      if (WrB)
        r_data[AddressB] <= DataInB;
      if (REnB)
	QB <= r_data[AddressB];
    end

endmodule

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
  ram_dp_true_m ram(.DataInA(),
		    .DataInB(WDATA),
		    .AddressA(RADDR),
		    .AddressB(WADDR),
		    .REnA(RE),
		    .REnB(1'b0),
		    .ClockA(RCLK),
		    .ClockB(WCLK),
		    .ClockEnA(RCLKE),
		    .ClockEnB(WCLKE),
		    .WrA(1'b0),
		    .WrB(WE),
		    .QA(RDATA),
		    .QB());
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
  wire [15:0] 		      ignore;
  ram_dp_true_m ram(.DataInA(),
		    .DataInB({16'd0,WDATA}),
		    .AddressA(RADDR),
		    .AddressB(WADDR),
		    .REnA(RE),
		    .REnB(1'b0),
		    .ClockA(RCLK),
		    .ClockB(WCLK),
		    .ClockEnA(RCLKE),
		    .ClockEnB(WCLKE),
		    .WrA(1'b0),
		    .WrB(WE),
		    .QA({ignore,RDATA}),
		    .QB());
endmodule // iceram16

//`include "ddr.v"
`include "ddr2.v"
