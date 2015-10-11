module refresh_timer(input CLK,
		     input  RST,
		     output REFRESH_STROBE);
  reg [7:0] 		    counter_l;
  reg [2:0] 		    counter_h;
  reg 			    counter_o;

  assign REFRESH_STROBE = counter_h[2];

  always @(posedge CLK)
    if (!RST)
      begin
	counter_o <= 0;
	counter_h <= 2;
	counter_l <= 0;
      end
    else
      begin
	{counter_o,counter_l} <= counter_l +1;
	if (counter_o)
	  counter_h <= counter_h +1;
      end

endmodule // refresh_timer
