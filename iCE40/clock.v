module divide_by_10(input INCLK,
		    output reg OUTCLK,
		    input      RST);
  reg [2:0] 		  counter;

  wire [2:0] 		  counter_transformed;
  wire 			  flippoint, outclk_new;

  assign flippoint = counter == 5;
  assign counter_transformed = flippoint ? 0 : counter;
  assign outclk_new = flippoint ? !OUTCLK : OUTCLK;

  always @(posedge INCLK)
    if (!RST)
      begin
	OUTCLK <= 1;
	counter <= 0;
      end
    else
      begin
	counter <= counter_transformed +1;
	OUTCLK <= outclk_new;
      end

endmodule // divide_by_10

module divide_by_2(input INCLK,
		   output reg OUTCLK,
		   input      RST);

  always @(posedge INCLK)
    if (!RST)
      begin
	OUTCLK <= 1;
      end
    else
      begin
	OUTCLK <= !OUTCLK;
      end

endmodule // divide_by_2

module clockblock(input REF_CLK,
		  input  OUT_RST,
		  output SYS_CLK,          //
		  output SYS_CLK_DELAYED,  //
		  output CPU_CLK,          //
		  output ETH_SAMPLER_CLK,  //
		  output ETH_INPUT_CLK,    //
		  output ETH_OUTPUT_CLK,   //
		  output FRST_RST);        //

  wire 			 clk_transfer;
  wire 			 ref_clk_div5;
  wire 			 lock_stepup;

  pll_0_v01 pll_stepup(.REFERENCECLK(REF_CLK),
		       .RESET(OUT_RST),
		       .PLLOUTGLOBAL(SYS_CLK),
//		       .PLLOUTGLOBALB(SYS_CLK_DELAYED),
		       .LOCK(lock_stepup));
  assign SYS_CLK_DELAYED = SYS_CLK; // until I figure out how to create a 90deg
				    // delay

  assign clk_transfer = SYS_CLK;

  pll_1_v01 pll_stepdown(.REFERENCECLK(clk_transfer),
			 .RESET(lock_stepup),
			 .PLLOUTGLOBAL(CPU_CLK),
			 .LOCK(FRST_RST));

  divide_by_10 gen_eth_in(.INCLK(SYS_CLK),
			  .OUTCLK(ETH_INPUT_CLK),
			  .RST(lock_stepup));

  divide_by_2 gen_eth_out(.INCLK(REF_CLK),
			  .OUTCLK(ETH_OUTPUT_CLK),
			  .RST(OUT_RST));

  assign ETH_SAMPLER_CLK = SYS_CLK;

endmodule // clockblock
