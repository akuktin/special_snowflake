`define NOOP 3'b111 /* no operation */
`define ACTV 3'b011 /* activate (row open) */
`define READ 3'b101 /* read */
`define WRTE 3'b100 /* write */
`define BTRM 3'b110 /* burst terminate */
`define PRCH 3'b010 /* precharge (row close) */
`define ARSR 3'b001 /* auto refresh/self refresh */
`define MRST 3'b000 /* mode register set */

module initializer(input CLK_n,
		   input 	 RST,
		   /* ----------------------- */
		   output reg 	 CKE,
		   output [2:0]  COMMAND_PIN,
		   output [13:0] ADDRESS_PIN,
		   output [2:0]  BANK_PIN,
		   /* ----------------------- */
		   input [2:0] 	 COMMAND_USER,
		   input [13:0]  ADDRESS_USER,
		   input [2:0] 	 BANK_USER,
		   /* ----------------------- */
		   output reg 	 RST_USER);
  reg 				 long_counter_o, other_cycle,
				 step_init, core_init;
  reg [7:0] 			 long_counter_h, long_counter_l;
  reg [3:0] 			 intercommand_count,
				 stage_count;
  reg [7:0] 			 aftercount;

  reg [2:0] 			 COMMAND_ini;
  reg [13:0] 			 ADDRESS_ini;
  reg [2:0] 			 BANK_ini;

  reg [2:0] 			 command_rom;
  reg [13:0] 			 address_rom;
  reg [2:0] 			 bank_rom;

  assign COMMAND_PIN = RST_USER ? COMMAND_USER : COMMAND_ini;
  assign ADDRESS_PIN = RST_USER ? ADDRESS_USER : ADDRESS_ini;
  assign BANK_PIN    = RST_USER ? BANK_USER    : BANK_ini;

  always @(*)
    begin
      // DDR2
      case (stage_count)
	4'h0: begin
	  command_rom = `PRCH;
	  address_rom = 14'h400;
	  bank_rom    = 3'h1;
	end
	4'h1: begin
	  command_rom = `MRST;
	  address_rom = 14'h000; // extended mode register 2
	  bank_rom    = 3'h2;
	end
	4'h2: begin
	  command_rom = `MRST;
	  address_rom = 14'h000; // extended mode register 3
	  bank_rom    = 3'h3;
	end
	4'h3: begin
	  command_rom = `MRST;
	  address_rom = 14'h780; // extended mode register
	  bank_rom    = 3'h1;
	end
	4'h4: begin
	  command_rom = `MRST;
	  address_rom = 14'h532; // regular mode register
	  bank_rom    = 3'h0;
	end
	4'h5: begin
	  command_rom = `PRCH;
	  address_rom = 14'h400;
	  bank_rom    = 3'h0;
	end
	4'h6: begin
	  command_rom = `ARSR;
	  address_rom = 14'h400;
	  bank_rom    = 3'h0;
	end
	4'h7: begin
	  command_rom = `ARSR;
	  address_rom = 14'h400;
	  bank_rom    = 3'h0;
	end
	4'h8: begin
	  command_rom = `MRST;
	  address_rom = 14'h432; // regular mode register
	  bank_rom    = 3'h0;
	end
	4'h9: begin
	  command_rom = `MRST;
	  address_rom = 14'h780; // extended mode register
	  bank_rom    = 3'h1;
	end
	4'ha: begin
	  command_rom = `MRST;
	  address_rom = 14'h400; // extended mode register
	  bank_rom    = 3'h1;
	end
	default: begin
	  command_rom = `NOOP;
	  address_rom = 14'h400;
	  bank_rom    = 3'h0;
	end
      endcase
    end

  always @(posedge CLK_n)
    if (!RST)
      begin
	CKE <= 0;
	RST_USER <= 0;
	long_counter_o <= 0;
	long_counter_h <= 0;
	long_counter_l <= 0;
	intercommand_count <= 0;
	stage_count <= 0;
	aftercount <= 0;
	COMMAND_ini <= `NOOP;
	other_cycle <= 0;
	step_init <= 0;
	core_init <= 1;
      end
    else
      begin
	other_cycle <= !other_cycle;
	step_init <= (intercommand_count == 4'hf);
	if (stage_count == 4'hf)
	  core_init <= 0;

	if (!CKE)
	  begin
	    {long_counter_o,long_counter_l} <= long_counter_l +1;
	    if (long_counter_o)
	      long_counter_h <= long_counter_h +1;
	    if (long_counter_h == 8'hff)
	      CKE <= 1;
	  end
	else
	  begin
	    if (core_init)
	      begin
		if (step_init)
		  begin
		    COMMAND_ini <= command_rom;
		    ADDRESS_ini <= address_rom;
		    BANK_ini    <= bank_rom;
		    stage_count <= stage_count +1;
		    intercommand_count <= 0;
		  end
		else
		  begin
		    COMMAND_ini <= `NOOP;
		    intercommand_count <= intercommand_count + other_cycle;
		  end // else: !if(step_init)
	      end // if (core_init)
	    else
	      begin
		if (!RST_USER)
		  begin
		    COMMAND_ini <= `NOOP;
		    aftercount <= aftercount +1;
		    if (aftercount == 8'hff)
		      RST_USER <= 1;
		  end
	      end // else: !if(core_init)
	  end // else: !if(!CKE)
      end // else: !if(!RST)

endmodule // initializer
