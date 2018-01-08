module trans_core(input CLK,
		  input 	    RST,
		  output reg [31:0] out_0,
		  output reg [31:0] out_1,
		  output reg [31:0] out_2,
		  output reg [31:0] out_3,
		  output reg [31:0] out_4,
		  output reg [31:0] out_5,
		  output reg [31:0] out_6,
		  output reg [31:0] out_7,
		  input [31:0] 	    in_0,
		  input [31:0] 	    in_1,
		  input [31:0] 	    in_2,
		  input [31:0] 	    in_3,
		  input [31:0] 	    in_4,
		  input [31:0] 	    in_5,
		  input [31:0] 	    in_6,
		  input [31:0] 	    in_7,
		  input [15:0] 	    isel,
		  input [15:0] 	    osel);
  reg [31:0] 		fan_block_0, fan_block_1;

  wire 			isel_0_0, isel_0_1, isel_0_2, isel_0_3,
			isel_0_4, isel_0_5, isel_0_6, isel_0_7;
  wire 			isel_1_0, isel_1_1, isel_1_2, isel_1_3,
			isel_1_4, isel_1_5, isel_1_6, isel_1_7;
  wire 			osel_0, osel_1, osel_2, osel_3,
			osel_4, osel_5, osel_6, osel_7;
  wire 			omux_0, omux_1, omux_2, omux_3,
			omux_4, omux_5, omux_6, omux_7;
  wire [31:0] 		in_block_0,
			in_block_0_0, in_block_0_1,
			in_block_0_2, in_block_0_3;
  wire [31:0] 		in_block_1,
			in_block_1_0, in_block_1_1,
			in_block_1_2, in_block_1_3;
  wire [31:0] 		out_block_0, out_block_1, out_block_2, out_block_3,
			out_block_4, out_block_5, out_block_6, out_block_7;

  assign isel_0_0 = isel[0]; assign isel_1_0 = isel[8];
  assign isel_0_1 = isel[1]; assign isel_1_1 = isel[9];
  assign isel_0_2 = isel[2]; assign isel_1_2 = isel[10];
  assign isel_0_3 = isel[3]; assign isel_1_3 = isel[11];
  assign isel_0_4 = isel[4]; assign isel_1_4 = isel[12];
  assign isel_0_5 = isel[5]; assign isel_1_5 = isel[13];
  assign isel_0_6 = isel[6]; assign isel_1_6 = isel[14];
  assign isel_0_7 = isel[7]; assign isel_1_7 = isel[15];

  assign osel_0 = osel[0]; assign omux_0 = osel[8];
  assign osel_1 = osel[1]; assign omux_1 = osel[9];
  assign osel_2 = osel[2]; assign omux_2 = osel[10];
  assign osel_3 = osel[3]; assign omux_3 = osel[11];
  assign osel_4 = osel[4]; assign omux_4 = osel[12];
  assign osel_5 = osel[5]; assign omux_5 = osel[13];
  assign osel_6 = osel[6]; assign omux_6 = osel[14];
  assign osel_7 = osel[7]; assign omux_7 = osel[15];

  assign in_block_0_0 = ({32{isel_0_0}} & in_0) | ({32{isel_0_1}} & in_1);
  assign in_block_0_1 = ({32{isel_0_2}} & in_2) | ({32{isel_0_3}} & in_3);
  assign in_block_0_2 = ({32{isel_0_4}} & in_4) | ({32{isel_0_5}} & in_5);
  assign in_block_0_3 = ({32{isel_0_6}} & in_6) | ({32{isel_0_7}} & in_7);
  assign in_block_0 = in_block_0_0 | in_block_0_1 |
		      in_block_0_2 | in_block_0_3;
  assign in_block_1_0 = ({32{isel_1_0}} & in_0) | ({32{isel_1_1}} & in_1);
  assign in_block_1_1 = ({32{isel_1_2}} & in_2) | ({32{isel_1_3}} & in_3);
  assign in_block_1_2 = ({32{isel_1_4}} & in_4) | ({32{isel_1_5}} & in_5);
  assign in_block_1_3 = ({32{isel_1_6}} & in_6) | ({32{isel_1_7}} & in_7);
  assign in_block_1 = in_block_1_0 | in_block_1_1 |
		      in_block_1_2 | in_block_1_3;
  assign out_block_0 = omux_0 ? fan_block_0 : fan_block_1;
  assign out_block_1 = omux_1 ? fan_block_0 : fan_block_1;
  assign out_block_2 = omux_2 ? fan_block_0 : fan_block_1;
  assign out_block_3 = omux_3 ? fan_block_0 : fan_block_1;
  assign out_block_4 = omux_4 ? fan_block_0 : fan_block_1;
  assign out_block_5 = omux_5 ? fan_block_0 : fan_block_1;
  assign out_block_6 = omux_6 ? fan_block_0 : fan_block_1;
  assign out_block_7 = omux_7 ? fan_block_0 : fan_block_1;

  always @(posedge CLK)
      begin
	fan_block_0 <= in_block_0;
	fan_block_1 <= in_block_1;

	if (osel_0)
	  out_0 <= out_block_0;
	if (osel_1)
	  out_1 <= out_block_1;
	if (osel_2)
	  out_2 <= out_block_2;
	if (osel_3)
	  out_3 <= out_block_3;
	if (osel_4)
	  out_4 <= out_block_4;
	if (osel_5)
	  out_5 <= out_block_5;
	if (osel_6)
	  out_6 <= out_block_6;
	if (osel_7)
	  out_7 <= out_block_7;
      end

endmodule // trans_core

module trans_lsab(input CLK,
		  input 	    RST,
		  output reg [31:0] out_0,
		  output reg [31:0] out_1,
		  output reg [31:0] out_2,
		  output reg [31:0] out_3,
		  output reg [31:0] out_4,
		  output reg [31:0] out_5,
		  output reg [31:0] out_6,
		  output reg [31:0] out_7,
		  input [31:0] 	    in_0,
		  input [31:0] 	    in_1,
		  input [31:0] 	    in_2,
		  input [31:0] 	    in_3,
		  input [31:0] 	    in_4,
		  input [31:0] 	    in_5,
		  input [31:0] 	    in_6,
		  input [31:0] 	    in_7,
		  input [31:0] 	    lsab,
		  input [7:0] 	    isel,
		  input [15:0] 	    osel);
  reg [31:0] 		fan_block_0;

  wire 			isel_0_0, isel_0_1, isel_0_2, isel_0_3,
			isel_0_4, isel_0_5, isel_0_6, isel_0_7;
  wire 			osel_0, osel_1, osel_2, osel_3,
			osel_4, osel_5, osel_6, osel_7;
  wire 			omux_0, omux_1, omux_2, omux_3,
			omux_4, omux_5, omux_6, omux_7;
  wire [31:0] 		fan_block_1;
  wire [31:0] 		in_block_0,
			in_block_0_0, in_block_0_1,
			in_block_0_2, in_block_0_3;
  wire [31:0] 		out_block_0, out_block_1, out_block_2, out_block_3,
			out_block_4, out_block_5, out_block_6, out_block_7;

  assign isel_0_0 = isel[0];
  assign isel_0_1 = isel[1];
  assign isel_0_2 = isel[2];
  assign isel_0_3 = isel[3];
  assign isel_0_4 = isel[4];
  assign isel_0_5 = isel[5];
  assign isel_0_6 = isel[6];
  assign isel_0_7 = isel[7];

  assign osel_0 = osel[0]; assign omux_0 = osel[8];
  assign osel_1 = osel[1]; assign omux_1 = osel[9];
  assign osel_2 = osel[2]; assign omux_2 = osel[10];
  assign osel_3 = osel[3]; assign omux_3 = osel[11];
  assign osel_4 = osel[4]; assign omux_4 = osel[12];
  assign osel_5 = osel[5]; assign omux_5 = osel[13];
  assign osel_6 = osel[6]; assign omux_6 = osel[14];
  assign osel_7 = osel[7]; assign omux_7 = osel[15];

  assign in_block_0_0 = ({32{isel_0_0}} & in_0) | ({32{isel_0_1}} & in_1);
  assign in_block_0_1 = ({32{isel_0_2}} & in_2) | ({32{isel_0_3}} & in_3);
  assign in_block_0_2 = ({32{isel_0_4}} & in_4) | ({32{isel_0_5}} & in_5);
  assign in_block_0_3 = ({32{isel_0_6}} & in_6) | ({32{isel_0_7}} & in_7);
  assign in_block_0 = in_block_0_0 | in_block_0_1 |
		      in_block_0_2 | in_block_0_3;
  assign out_block_0 = omux_0 ? fan_block_0 : fan_block_1;
  assign out_block_1 = omux_1 ? fan_block_0 : fan_block_1;
  assign out_block_2 = omux_2 ? fan_block_0 : fan_block_1;
  assign out_block_3 = omux_3 ? fan_block_0 : fan_block_1;
  assign out_block_4 = omux_4 ? fan_block_0 : fan_block_1;
  assign out_block_5 = omux_5 ? fan_block_0 : fan_block_1;
  assign out_block_6 = omux_6 ? fan_block_0 : fan_block_1;
  assign out_block_7 = omux_7 ? fan_block_0 : fan_block_1;

  assign fan_block_1 = lsab;

  always @(posedge CLK)
      begin
	fan_block_0 <= in_block_0;

	if (osel_0)
	  out_0 <= out_block_0;
	if (osel_1)
	  out_1 <= out_block_1;
	if (osel_2)
	  out_2 <= out_block_2;
	if (osel_3)
	  out_3 <= out_block_3;
	if (osel_4)
	  out_4 <= out_block_4;
	if (osel_5)
	  out_5 <= out_block_5;
	if (osel_6)
	  out_6 <= out_block_6;
	if (osel_7)
	  out_7 <= out_block_7;
      end

endmodule // trans_lsab
