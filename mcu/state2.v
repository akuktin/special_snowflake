`define NOOP 3'b111 /* no operation */
`define ACTV 3'b011 /* activate (row open) */
`define READ 3'b101 /* read */
`define WRTE 3'b100 /* write */
`define BTRM 3'b110 /* burst terminate */
`define PRCH 3'b010 /* precharge (row close) */
`define ARSR 3'b001 /* auto refresh/self refresh */
`define MRST 3'b000 /* mode register set */

module state2(input CLK,
	      input 		RST,
	      input 		REFRESH_STROBE,
	      /* random port */
	      input [25:0] 	ADDRESS_RAND,
	      input 		port_WE_RAND,
	      input 		port_REQUEST_ACCESS_RAND,
	      output reg 	GRANT_ACCESS_RAND,
	      input [3:0] 	WE_ARRAY_RAND,
	      /* bulk_port */
	      input [25:0] 	port_ADDRESS_BULK,
	      input 		port_WE_BULK,
	      input 		port_REQUEST_ACCESS_BULK,
	      output reg 	GRANT_ACCESS_BULK,
	      input 		port_REQUEST_ALIGN_BULK,
	      output reg 	GRANT_ALIGN_BULK,
	      input [3:0] 	port_WE_ARRAY_BULK,
	      /* end ports */
	      output reg [12:0] ADDRESS_REG,
	      output reg [1:0] 	BANK_REG,
	      output reg [2:0] 	COMMAND_REG,
	      output [3:0] 	INTERNAL_COMMAND_LATCHED,
	      output reg [3:0] 	INTERNAL_WE_ARRAY);
  reg 				     change_possible_n, state_is_readwrite,
				     refresh_strobe_ack, state_is_write,
				     SOME_PAGE_ACTIVE, second_stroke,
				     REFRESH_TIME, REQUEST_ALIGN_BULK_dly,
				     REQUEST_ACCESS_RAND, WE_RAND,
				     REQUEST_ACCESS_BULK, WE_BULK,
				     REQUEST_ALIGN_BULK,
				     correct_page_rand, correct_page_bulk,
				     correct_page_algn, correct_page_any,
				     correct_page_rdy;
  reg [2:0] 			     command_reg2, actv_timeout;
  reg [3:0] 			     counter, WE_ARRAY_BULK;
  reg [13:0] 			     page_current;
  reg [25:0] 			     ADDRESS_BULK;

  wire 				     issue_com,
				     correct_page_rand_w,
				     correct_page_bulk_w,
				     correct_page_algn_w,
				     change_possible_w_n, write_match,
				     timeout_norm_comp_n,
				     timeout_dlay_comp_n,
				     want_PRCH_delayable,
				     issue_enable_override,
				     issue_enable_on_page;
  wire [1:0] 			     bank_addr,
				     bank_request_live_bulk,
				     bank_request_live_rand;
  wire [2:0] 			     command, command_wr;
  wire [3:0] 			     we_array;
  wire [11:0] 			     row_request_live_bulk,
				     row_request_live_rand;
  wire [12:0] 			     address;
  wire [13:0] 			     page;
  wire [25:0] 			     address_in;

  reg [2:0] 			     command_non_wr;

  assign INTERNAL_COMMAND_LATCHED = {second_stroke,command_reg2};

  assign row_request_live_rand = ADDRESS_RAND[25:14];
  assign bank_request_live_rand = ADDRESS_RAND[13:12];

  assign correct_page_rand_w = ({port_REQUEST_ACCESS_RAND,
				 port_REQUEST_ALIGN_BULK,
				 REFRESH_TIME,
				 SOME_PAGE_ACTIVE,
				 row_request_live_rand,
				 bank_request_live_rand}
				== {4'b1001,
				    page_current});

  assign row_request_live_bulk = ADDRESS_BULK[25:14];
  assign bank_request_live_bulk = ADDRESS_BULK[13:12];

  assign correct_page_bulk_w = ({port_REQUEST_ACCESS_BULK,
				 REFRESH_TIME,
				 SOME_PAGE_ACTIVE,
				 row_request_live_bulk,
				 bank_request_live_bulk}
				== {3'b101,
				    page_current});

  assign correct_page_algn_w = ({port_REQUEST_ALIGN_BULK,
				 REFRESH_TIME,
				 SOME_PAGE_ACTIVE,
				 row_request_live_bulk,
				 bank_request_live_bulk}
				== {3'b101,
				    page_current});

  assign write_match = REQUEST_ACCESS_BULK ? WE_BULK :
		       (REQUEST_ACCESS_RAND && WE_RAND);

  assign issue_com = (((correct_page_rand && port_REQUEST_ACCESS_RAND) ||
		       (correct_page_bulk && REQUEST_ACCESS_BULK))
		      && issue_enable_on_page) ||
		     issue_enable_override;

  assign issue_enable_on_page = second_stroke && state_is_readwrite &&
				(state_is_write ?
				 write_match :
				 (!write_match));

  assign issue_enable_override = second_stroke && (!change_possible_n) &&
				 ((REQUEST_ACCESS_RAND &&
				   (!(REQUEST_ACCESS_BULK ||
				      REQUEST_ALIGN_BULK))) ||
				  REQUEST_ACCESS_BULK ||
				  REFRESH_TIME ||
				  // FIXME: still not really good enough
				  (REQUEST_ALIGN_BULK_dly &&
				   (!GRANT_ALIGN_BULK)));

  always @(SOME_PAGE_ACTIVE or REFRESH_TIME or actv_timeout[2])
    case ({SOME_PAGE_ACTIVE,REFRESH_TIME,actv_timeout[2]})
      /*
       Short form:
      3'b1x1: command_non_wr <= `PRCH;
      3'b01x: command_non_wr <= `ARSR;
      3'b00x: command_non_wr <= `ACTV;
       */
      3'b101: command_non_wr <= `PRCH;
      3'b111: command_non_wr <= `PRCH;
      3'b010: command_non_wr <= `ARSR;
      3'b011: command_non_wr <= `ARSR;
      3'b000: command_non_wr <= `ACTV;
      3'b001: command_non_wr <= `ACTV;
      default: command_non_wr <= `NOOP;
    endcase // case ({SOME_PAGE_ACTIVE,REFRESH_TIME,actv_timeout[2]})

  assign want_PRCH_delayable = SOME_PAGE_ACTIVE && state_is_write;

  // Actually not a mux, but a single gate, like command_non_wr.
  assign command_wr = write_match ? `WRTE : `READ;

  assign command = correct_page_any ? command_wr : command_non_wr;

  assign address_in = REQUEST_ALIGN_BULK ? ADDRESS_BULK : ADDRESS_RAND;

  assign address = (SOME_PAGE_ACTIVE &&
                    (! correct_page_rdy)) ?
                   13'h0400 :
                   (correct_page_rdy ?
		    {address_in[11:0],1'b0} :
		    {address_in[25:24],1'b0,address_in[23:14]});
  assign page = correct_page_rdy ?
		page_current :
		address_in[25:12];
  assign bank_addr = correct_page_rdy ?
		     BANK_REG :
		     address_in[13:12];

  assign timeout_norm_comp_n = !((counter == 4'hd) || (counter == 4'he));
  assign timeout_dlay_comp_n = !((counter == 4'hf) || (counter == 4'h0)); // sped up

  /* Fully synthetizable in three gates, may need to be rewritten to help
   * the synthetizer. */
  assign change_possible_w_n = ~second_stroke ? 1 :
			       correct_page_any ? timeout_norm_comp_n :
			       (want_PRCH_delayable ?
				timeout_dlay_comp_n : timeout_norm_comp_n);

  assign we_array = REQUEST_ACCESS_BULK ? WE_ARRAY_BULK : WE_ARRAY_RAND;

  always @(posedge CLK)
    if (!RST)
      begin
	COMMAND_REG <= `NOOP; ADDRESS_REG <= 13'h0400; BANK_REG <= 0;
	GRANT_ACCESS_RAND <= 0; GRANT_ACCESS_BULK <= 0;
	change_possible_n <= 1; state_is_readwrite <= 0;
	refresh_strobe_ack <= 0; state_is_write <= 0; SOME_PAGE_ACTIVE <= 0;
	second_stroke <= 1; REFRESH_TIME <= 0;
	command_reg2 <= `NOOP; actv_timeout <= 3'h7; counter <= 4'he;
	page_current <= 0; GRANT_ALIGN_BULK <= 0; INTERNAL_WE_ARRAY <= 0;
	REQUEST_ALIGN_BULK_dly <= 0;

	REQUEST_ACCESS_RAND <= 0; REQUEST_ACCESS_BULK <= 0;
	REQUEST_ALIGN_BULK <= 0; correct_page_rand <= 0;
	correct_page_bulk <= 0; correct_page_algn <= 0; WE_BULK <= 0;
	correct_page_any <= 0; correct_page_rdy <= 0; WE_RAND <= 0;
      end
    else
      begin
	REQUEST_ACCESS_RAND <= port_REQUEST_ACCESS_RAND;
	REQUEST_ACCESS_BULK <= port_REQUEST_ACCESS_BULK;
	REQUEST_ALIGN_BULK <= port_REQUEST_ALIGN_BULK;
	WE_BULK <= port_WE_BULK;
	WE_RAND <= port_WE_RAND;
	ADDRESS_BULK <= port_ADDRESS_BULK;
	WE_ARRAY_BULK <= port_WE_ARRAY_BULK;

	correct_page_rand <= correct_page_rand_w;
	correct_page_bulk <= correct_page_bulk_w;
	correct_page_algn <= correct_page_algn_w;
	correct_page_any <= correct_page_rand_w || correct_page_bulk_w;
	correct_page_rdy <= correct_page_rand_w || correct_page_algn_w;

	REQUEST_ALIGN_BULK_dly <= REQUEST_ALIGN_BULK;

	REFRESH_TIME <= refresh_strobe_ack ^ REFRESH_STROBE;
	if ((!second_stroke) && (command_reg2 == `ACTV))
	  actv_timeout <= 3'h0;
	else
	  if (!actv_timeout[2])
	    actv_timeout <= actv_timeout +1;


	if (issue_com)
	  begin
	    COMMAND_REG <= command;
	    command_reg2 <= command;
	  end
	else
	  begin
	    COMMAND_REG <= `NOOP;
	    command_reg2 <= `NOOP;
	  end

	ADDRESS_REG <= address;
	if ((!(SOME_PAGE_ACTIVE &&
	       (! correct_page_rdy))) &&
	    (issue_com))
	  begin
	    page_current <= page;
	    BANK_REG <= bank_addr;
	  end

	// The below used to be in the state tracker
	// -----------------------------------------
	second_stroke <= ~issue_com;

	if (!second_stroke)
	  begin
	    if (command_reg2 == `ACTV)
	      SOME_PAGE_ACTIVE <= 1;
	    if (command_reg2 == `PRCH)
	      SOME_PAGE_ACTIVE <= 0;
	    if (command_reg2 == `WRTE)
	      state_is_write <= 1;
	    else if (command_reg2 != `NOOP)
	      state_is_write <= 0;
	    if (command_reg2 == `ARSR)
	      refresh_strobe_ack <= REFRESH_STROBE;

	    case (command_reg2)
	      `ARSR: counter <= 4'h3;
	      `ACTV: counter <= 4'hc;
	      `PRCH: counter <= 4'hc; // sped up
	      `READ: counter <= 4'hc; // sped up
	      `WRTE: counter <= 4'hc; // sped up
	      `NOOP: counter <= 4'he;
	      default: counter <= 4'hb;
	    endcase // case (command_reg2)
	  end // if (!second_stroke)
	else
	  counter <= counter + change_possible_n;

	if (issue_com)
	  begin
	    change_possible_n <= 1;
	    state_is_readwrite <= correct_page_any;

	    GRANT_ACCESS_RAND <= correct_page_rand;
	    GRANT_ACCESS_BULK <= correct_page_bulk;

	    INTERNAL_WE_ARRAY <= we_array;
	  end

	if (!issue_com)
	  begin
	    change_possible_n <= change_possible_w_n;

	    GRANT_ACCESS_RAND <= 0;
	    GRANT_ACCESS_BULK <= 0;
	  end

	GRANT_ALIGN_BULK <= correct_page_algn;
      end

endmodule // enter_state

module outputs(input CLK_p,
	       input 	     CLK_n,
	       input 	     CLK_dp,
	       input 	     CLK_dn,
	       input 	     RST,
	       input [3:0]   COMMAND_LATCHED,
	       input [3:0]   WE_ARRAY,
	       input [31:0]  port_DATA_W,
	       inout [15:0]  DQ,
	       inout 	     DQS,
	       output [31:0] DATA_R,
	       output 	     DM);
  reg [31:0] 			 data_gapholder, dq_predriver, DATA_W;
  reg [3:0] 			 we_gapholder;
  reg [1:0] 			 dm_predriver, dqs_predriver, active;
  reg 				 dqs_z_prectrl, dqs_z_ctrl, dqdm_z_prectrl,
				 high_bits;

  wire 				 did_issue_write;

  /* NOTICE: For whatever reason, or confusion, I made the WE (that is, DM)
   *         refer to 16-bit chunks of data, instead of the much saner
   *         8-bit. No idea why I did that, and it's been a year since. */

  assign did_issue_write = COMMAND_LATCHED == {1'b0,`WRTE};

  ddr_data_pins pins(.CLK_n(CLK_n),
		     .CLK_dn(CLK_dn),
		     .dq_predriver(dq_predriver),
		     .dm_predriver(dm_predriver),
		     .dqs_predriver(dqs_predriver),
		     .dqs_z_ctrl(dqs_z_ctrl),
		     .dqdm_z_prectrl(dqdm_z_prectrl),
		     .dq_data_r(DATA_R),
		     .DQ(DQ),
		     .DQS(DQS),
		     .DM(DM));

  always @(did_issue_write or active[0])
    if ({did_issue_write,active[0]} == 2'b00)
      dqs_z_prectrl <= 0;
    else
      dqs_z_prectrl <= 1;


  always @(posedge CLK_n)
    if (!RST)
      begin
	data_gapholder <= 0; we_gapholder <= 0;
	dq_predriver <= 0; dm_predriver <= 0; dqdm_z_prectrl <= 0;
	dqs_predriver <= 0; DATA_W <= 0;
	active <= 0; high_bits <= 0;
      end
    else
      begin
	DATA_W <= port_DATA_W;
	data_gapholder <= DATA_W;
	dq_predriver <= data_gapholder;

	we_gapholder <= WE_ARRAY;

	high_bits <= did_issue_write;

	active <= {active[0],did_issue_write};

	if (high_bits)
	  dm_predriver <= we_gapholder[1:0];
	else
	  dm_predriver <= WE_ARRAY[3:2];

	if ({did_issue_write,active[0]} == 2'b00)
	  begin
	    dqdm_z_prectrl <= 0;
	    dqs_predriver <= 2'h0;
	  end
	else
	  begin
	    dqdm_z_prectrl <= 1;
	    dqs_predriver <= 2'h2;
	  end

	/* This will be used when we switch over to DDR2.

	if ({did_issue_write,active} == 3'b000)
	  dqs_z_prectrl <= 0;
	else
	  dqs_z_prectrl <= 1;
	 */

      end // else: !if(!RST)

  always @(negedge CLK_dn)
    if (!RST)
      dqs_z_ctrl <= 0;
    else
      dqs_z_ctrl <= dqs_z_prectrl;

endmodule // outputs

module ddr_data_pins(input CLK_n,
		     input 	   CLK_dn,
		     input [31:0]  dq_predriver,
		     input [1:0]   dm_predriver,
		     input [1:0]   dqs_predriver,
		     input 	   dqs_z_ctrl,
		     input 	   dqdm_z_prectrl,
		     output [31:0] dq_data_r,
		     /////////////////////
		     inout [15:0]  DQ,
		     inout 	   DQS,
		     output 	   DM);

  defparam DQS_00.PIN_TYPE = 6'b100001;
  defparam DQS_00.IO_STANDARD = "SB_LVCMOS";
  SB_IOeg DQS_00(.PACKAGE_PIN(DQS),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(1'b0),
	     .OUTPUT_CLK(! CLK_n), // INVERTED!
	     .OUTPUT_ENABLE(dqs_z_ctrl),
	     .D_OUT_0(dqs_predriver[1]),
	     .D_OUT_1(dqs_predriver[0]),
	     .D_IN_0(),
	     .D_IN_1());

  defparam DM_00.PIN_TYPE = 6'b110001;
  defparam DM_00.IO_STANDARD = "SB_LVCMOS";
  SB_IO DM_00(.PACKAGE_PIN(DM),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(1'b0),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(!dm_predriver[1]),
	     .D_OUT_1(!dm_predriver[0]),
	     .D_IN_0(),
	     .D_IN_1());

  defparam DQ_00.PIN_TYPE = 6'b110000;
  defparam DQ_00.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_00(.PACKAGE_PIN(DQ[15]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[31]),
	     .D_OUT_1(dq_predriver[15]),
	     .D_IN_0(dq_data_r[31]),
	     .D_IN_1(dq_data_r[15]));

  defparam DQ_01.PIN_TYPE = 6'b110000;
  defparam DQ_01.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_01(.PACKAGE_PIN(DQ[14]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[30]),
	     .D_OUT_1(dq_predriver[14]),
	     .D_IN_0(dq_data_r[30]),
	     .D_IN_1(dq_data_r[14]));

  defparam DQ_02.PIN_TYPE = 6'b110000;
  defparam DQ_02.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_02(.PACKAGE_PIN(DQ[13]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[29]),
	     .D_OUT_1(dq_predriver[13]),
	     .D_IN_0(dq_data_r[29]),
	     .D_IN_1(dq_data_r[13]));

  defparam DQ_03.PIN_TYPE = 6'b110000;
  defparam DQ_03.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_03(.PACKAGE_PIN(DQ[12]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[28]),
	     .D_OUT_1(dq_predriver[12]),
	     .D_IN_0(dq_data_r[28]),
	     .D_IN_1(dq_data_r[12]));

  defparam DQ_04.PIN_TYPE = 6'b110000;
  defparam DQ_04.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_04(.PACKAGE_PIN(DQ[11]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[27]),
	     .D_OUT_1(dq_predriver[11]),
	     .D_IN_0(dq_data_r[27]),
	     .D_IN_1(dq_data_r[11]));

  defparam DQ_05.PIN_TYPE = 6'b110000;
  defparam DQ_05.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_05(.PACKAGE_PIN(DQ[10]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[26]),
	     .D_OUT_1(dq_predriver[10]),
	     .D_IN_0(dq_data_r[26]),
	     .D_IN_1(dq_data_r[10]));

  defparam DQ_06.PIN_TYPE = 6'b110000;
  defparam DQ_06.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_06(.PACKAGE_PIN(DQ[9]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[25]),
	     .D_OUT_1(dq_predriver[9]),
	     .D_IN_0(dq_data_r[25]),
	     .D_IN_1(dq_data_r[9]));

  defparam DQ_07.PIN_TYPE = 6'b110000;
  defparam DQ_07.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_07(.PACKAGE_PIN(DQ[8]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[24]),
	     .D_OUT_1(dq_predriver[8]),
	     .D_IN_0(dq_data_r[24]),
	     .D_IN_1(dq_data_r[8]));

  defparam DQ_08.PIN_TYPE = 6'b110000;
  defparam DQ_08.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_08(.PACKAGE_PIN(DQ[7]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[23]),
	     .D_OUT_1(dq_predriver[7]),
	     .D_IN_0(dq_data_r[23]),
	     .D_IN_1(dq_data_r[7]));

  defparam DQ_09.PIN_TYPE = 6'b110000;
  defparam DQ_09.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_09(.PACKAGE_PIN(DQ[6]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[22]),
	     .D_OUT_1(dq_predriver[6]),
	     .D_IN_0(dq_data_r[22]),
	     .D_IN_1(dq_data_r[6]));

  defparam DQ_10.PIN_TYPE = 6'b110000;
  defparam DQ_10.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_10(.PACKAGE_PIN(DQ[5]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[21]),
	     .D_OUT_1(dq_predriver[5]),
	     .D_IN_0(dq_data_r[21]),
	     .D_IN_1(dq_data_r[5]));

  defparam DQ_11.PIN_TYPE = 6'b110000;
  defparam DQ_11.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_11(.PACKAGE_PIN(DQ[4]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[20]),
	     .D_OUT_1(dq_predriver[4]),
	     .D_IN_0(dq_data_r[20]),
	     .D_IN_1(dq_data_r[4]));

  defparam DQ_12.PIN_TYPE = 6'b110000;
  defparam DQ_12.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_12(.PACKAGE_PIN(DQ[3]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[19]),
	     .D_OUT_1(dq_predriver[3]),
	     .D_IN_0(dq_data_r[19]),
	     .D_IN_1(dq_data_r[3]));

  defparam DQ_13.PIN_TYPE = 6'b110000;
  defparam DQ_13.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_13(.PACKAGE_PIN(DQ[2]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[18]),
	     .D_OUT_1(dq_predriver[2]),
	     .D_IN_0(dq_data_r[18]),
	     .D_IN_1(dq_data_r[2]));

  defparam DQ_14.PIN_TYPE = 6'b110000;
  defparam DQ_14.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_14(.PACKAGE_PIN(DQ[1]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[17]),
	     .D_OUT_1(dq_predriver[1]),
	     .D_IN_0(dq_data_r[17]),
	     .D_IN_1(dq_data_r[1]));

  defparam DQ_15.PIN_TYPE = 6'b110000;
  defparam DQ_15.IO_STANDARD = "SB_LVCMOS";
  SB_IO DQ_15(.PACKAGE_PIN(DQ[0]),
	     .LATCH_INPUT_VALUE(1'b0),
	     .CLOCK_ENABLE(1'b1),
	     .INPUT_CLK(CLK_dn),
	     .OUTPUT_CLK(CLK_dn),
	     .OUTPUT_ENABLE(dqdm_z_prectrl),
	     .D_OUT_0(dq_predriver[16]),
	     .D_OUT_1(dq_predriver[0]),
	     .D_IN_0(dq_data_r[16]),
	     .D_IN_1(dq_data_r[0]));

endmodule // pins

module SB_IO(inout PACKAGE_PIN,
	     input  LATCH_INPUT_VALUE,
	     input  CLOCK_ENABLE,
	     input  INPUT_CLK,
	     input  OUTPUT_CLK,
	     input  OUTPUT_ENABLE,
	     input  D_OUT_0,
	     input  D_OUT_1,
	     output reg D_IN_0,
	     output reg D_IN_1);
  reg 			out_en, reg_out_0, reg_out_1;
  wire 			out_mux;

  assign PACKAGE_PIN = out_en ? out_mux : 1'bz;
  assign out_mux = OUTPUT_CLK ? reg_out_0 : reg_out_1;

  always @(posedge INPUT_CLK)
    if (CLOCK_ENABLE)
      D_IN_0 <= PACKAGE_PIN;

  always @(negedge INPUT_CLK)
    if (CLOCK_ENABLE)
      D_IN_1 <= PACKAGE_PIN;

  always @(posedge OUTPUT_CLK)
    if (CLOCK_ENABLE)
      begin
	out_en <= OUTPUT_ENABLE;
	reg_out_0 <= D_OUT_0;
	reg_out_1 <= D_OUT_1;
      end
//  always @(negedge OUTPUT_CLK)
//    if (CLOCK_ENABLE)
//      begin
//        reg_out_1 <= D_OUT_1;
//      end

endmodule // SB_IO

module SB_IOeg(inout PACKAGE_PIN,
	     input  LATCH_INPUT_VALUE,
	     input  CLOCK_ENABLE,
	     input  INPUT_CLK,
	     input  OUTPUT_CLK,
	     input  OUTPUT_ENABLE,
	     input  D_OUT_0,
	     input  D_OUT_1,
	     output reg D_IN_0,
	     output reg D_IN_1);
  reg 			reg_out_0, reg_out_1;
  wire 			out_mux;

  assign PACKAGE_PIN = OUTPUT_ENABLE ? out_mux : 1'bz;
  assign out_mux = OUTPUT_CLK ? reg_out_0 : reg_out_1;

  always @(posedge INPUT_CLK)
    if (CLOCK_ENABLE)
      D_IN_0 <= PACKAGE_PIN;

  always @(negedge INPUT_CLK)
    if (CLOCK_ENABLE)
      D_IN_1 <= PACKAGE_PIN;

  always @(posedge OUTPUT_CLK)
    if (CLOCK_ENABLE)
      begin
	reg_out_0 <= D_OUT_0;
	reg_out_1 <= D_OUT_1;
      end
//  always @(negedge OUTPUT_CLK)
//    if (CLOCK_ENABLE)
//      begin
//        reg_out_1 <= D_OUT_1;
//      end

endmodule // SB_IO
