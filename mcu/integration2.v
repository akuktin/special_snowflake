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

module ddr_memory_controler(input CLK_n,
			    input 	  CLK_p,
			    input 	  CLK_dp,
			    input 	  CLK_dn,
			    input 	  RST,
			    /* ------------------------- */
			    output 	  CKE,
			    output [2:0]  COMMAND,
			    output [12:0] ADDRESS,
			    output [1:0]  BANK,
			    inout [15:0]  DQ,
			    inout 	  DQS,
			    output 	  DM,
			    output 	  CS,
			    /* ------------------------- */
			    input [25:0]  user_req_address,
			    input 	  user_req_we,
			    input 	  user_req,
			    input [31:0]  user_req_datain,
			    output 	  user_req_ack,
			    output [31:0] user_req_dataout);
/*
  wire [25:0] 					 user_req_address;
  wire 						 user_req_we, user_req,
						 user_req_ack;
  wire [31:0] 					 user_req_datain,
						 user_req_dataout;
 */
////////
  wire [2:0] 					 command_user,
						 command_statechange_req,
						 cur_state;
  wire [12:0] 					 address_user;
  wire [1:0] 					 bank_user;
  wire 						 rst_user, refresh_strobe,
						 change_requested,
						 change_possible,
						 some_page_active,
						 refresh_time,
						 internal_com_lat;

  assign CS = 1'b0; // Always on.

  refresh_timer refresh_strobe_m(.CLK(CLK_n),
				 .RST(rst_user),
				 .REFRESH_STROBE(refresh_strobe));

  initializer initializer_m(.CLK_n(CLK_n),
			    .RST(RST),
			    .CKE(CKE),
			    .COMMAND_PIN(COMMAND),
			    .ADDRESS_PIN(ADDRESS),
			    .BANK_PIN(BANK),
			    .COMMAND_USER(command_user),
			    .ADDRESS_USER(address_user),
			    .BANK_USER(bank_user),
			    .RST_USER(rst_user));

  state2 interdictor_tracker(.CLK(CLK_n),
			     .RST(rst_user),
			     .REFRESH_STROBE(refresh_strobe),
			     .ADDRESS_RAND(user_req_address),
			     .WE_RAND(user_req_we),
			     .REQUEST_ACCESS_RAND(user_req),
			     .GRANT_ACCESS_RAND(user_req_ack),
			     .ADDRESS_BULK(0),
			     .WE_BULK(0),
			     .REQUEST_ACCESS_BULK(0),
			     .GRANT_ACCESS_BULK(),
			     .ADDRESS_REQ(address_user),
			     .BANK_REQ(bank_user),
			     .COMMAND_REQ(command_user),
			     .INTERNAL_COMMAND_LATCHED(internal_com_lat));

  outputs data_driver(.CLK_p(CLK_p),
		      .CLK_n(CLK_n),
		      .CLK_dp(CLK_dp),
		      .CLK_dn(CLK_dn),
		      .RST(RST),
		      .COMMAND_LATCHED(internal_com_lat),
		      .DATA_W(user_req_datain),
		      .WE(user_req_we),
		      .DQ(DQ),
		      .DQS(DQS),
		      .DATA_R(user_req_dataout),
		      .DM(DM));

endmodule // ddr_memory_controler_stage1
