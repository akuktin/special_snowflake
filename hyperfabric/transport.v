module trans_core(input CLK,
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

module trans_fast(input CLK,
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
		  input [7:0] 	    isel,
		  input [15:0] 	    osel);
  reg [31:0] 		fan_block_0;

  wire 			osel_0, osel_1, osel_2, osel_3,
			osel_4, osel_5, osel_6, osel_7;
  wire 			omux_0, omux_1, omux_2, omux_3,
			omux_4, omux_5, omux_6, omux_7;
  wire [31:0] 		out_block_0, out_block_1, out_block_2, out_block_3,
			out_block_4, out_block_5, out_block_6, out_block_7;

  wire [31:0] 		s_gate, f_gate;
  wire 			sel_high, sel_low;

  assign osel_0 = osel[0]; assign omux_0 = osel[8];
  assign osel_1 = osel[1]; assign omux_1 = osel[9];
  assign osel_2 = osel[2]; assign omux_2 = osel[10];
  assign osel_3 = osel[3]; assign omux_3 = osel[11];
  assign osel_4 = osel[4]; assign omux_4 = osel[12];
  assign osel_5 = osel[5]; assign omux_5 = osel[13];
  assign osel_6 = osel[6]; assign omux_6 = osel[14];
  assign osel_7 = osel[7]; assign omux_7 = osel[15];

  // Only one fan block. In case a second is added, there are two options.
  // Either we will go the trans_core way and wire all inputs to both fan
  // blocks, giving us the ability to have simultaneous transactions, or we
  // will wire a separate set of inputs (in_4 through in_7) to the second
  // fan block, giving us more inputs.
  // Combinations of these are possible (some inputs have access to both
  // fan blocks, some inputs have access to only one fan block).
  assign out_block_0 = fan_block_0;
  assign out_block_1 = fan_block_0;
  assign out_block_2 = fan_block_0;
  assign out_block_3 = fan_block_0;
  assign out_block_4 = fan_block_0;
  assign out_block_5 = fan_block_0;
  assign out_block_6 = fan_block_0;
  assign out_block_7 = fan_block_0;

  assign sel_low = isel[0];
  assign sel_high = isel[1];

  assign s_gate = sel_high ? ({32{sel_low}}) : (sel_low ? in_2 : in_3);

  assign f_gate[0] = sel_high ?(s_gate[0] ?in_0[0] :in_1[0] ):s_gate[0];
  assign f_gate[1] = sel_high ?(s_gate[1] ?in_0[1] :in_1[1] ):s_gate[1];
  assign f_gate[2] = sel_high ?(s_gate[2] ?in_0[2] :in_1[2] ):s_gate[2];
  assign f_gate[3] = sel_high ?(s_gate[3] ?in_0[3] :in_1[3] ):s_gate[3];
  assign f_gate[4] = sel_high ?(s_gate[4] ?in_0[4] :in_1[4] ):s_gate[4];
  assign f_gate[5] = sel_high ?(s_gate[5] ?in_0[5] :in_1[5] ):s_gate[5];
  assign f_gate[6] = sel_high ?(s_gate[6] ?in_0[6] :in_1[6] ):s_gate[6];
  assign f_gate[7] = sel_high ?(s_gate[7] ?in_0[7] :in_1[7] ):s_gate[7];
  assign f_gate[8] = sel_high ?(s_gate[8] ?in_0[8] :in_1[8] ):s_gate[8];
  assign f_gate[9] = sel_high ?(s_gate[9] ?in_0[9] :in_1[9] ):s_gate[9];
  assign f_gate[10]= sel_high ?(s_gate[10]?in_0[10]:in_1[10]):s_gate[10];
  assign f_gate[11]= sel_high ?(s_gate[11]?in_0[11]:in_1[11]):s_gate[11];
  assign f_gate[12]= sel_high ?(s_gate[12]?in_0[12]:in_1[12]):s_gate[12];
  assign f_gate[13]= sel_high ?(s_gate[13]?in_0[13]:in_1[13]):s_gate[13];
  assign f_gate[14]= sel_high ?(s_gate[14]?in_0[14]:in_1[14]):s_gate[14];
  assign f_gate[15]= sel_high ?(s_gate[15]?in_0[15]:in_1[15]):s_gate[15];
  assign f_gate[16]= sel_high ?(s_gate[16]?in_0[16]:in_1[16]):s_gate[16];
  assign f_gate[17]= sel_high ?(s_gate[17]?in_0[17]:in_1[17]):s_gate[17];
  assign f_gate[18]= sel_high ?(s_gate[18]?in_0[18]:in_1[18]):s_gate[18];
  assign f_gate[19]= sel_high ?(s_gate[19]?in_0[19]:in_1[19]):s_gate[19];
  assign f_gate[20]= sel_high ?(s_gate[20]?in_0[20]:in_1[20]):s_gate[20];
  assign f_gate[21]= sel_high ?(s_gate[21]?in_0[21]:in_1[21]):s_gate[21];
  assign f_gate[22]= sel_high ?(s_gate[22]?in_0[22]:in_1[22]):s_gate[22];
  assign f_gate[23]= sel_high ?(s_gate[23]?in_0[23]:in_1[23]):s_gate[23];
  assign f_gate[24]= sel_high ?(s_gate[24]?in_0[24]:in_1[24]):s_gate[24];
  assign f_gate[25]= sel_high ?(s_gate[25]?in_0[25]:in_1[25]):s_gate[25];
  assign f_gate[26]= sel_high ?(s_gate[26]?in_0[26]:in_1[26]):s_gate[26];
  assign f_gate[27]= sel_high ?(s_gate[27]?in_0[27]:in_1[27]):s_gate[27];
  assign f_gate[28]= sel_high ?(s_gate[28]?in_0[28]:in_1[28]):s_gate[28];
  assign f_gate[29]= sel_high ?(s_gate[29]?in_0[29]:in_1[29]):s_gate[29];
  assign f_gate[30]= sel_high ?(s_gate[30]?in_0[30]:in_1[30]):s_gate[30];
  assign f_gate[31]= sel_high ?(s_gate[31]?in_0[31]:in_1[31]):s_gate[31];

  always @(posedge CLK)
    begin
      fan_block_0 <= f_gate;

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

endmodule // trans_fast
