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
			    input 	  refresh_strobe,
			    /* ------------------------- */
			    input [25:0]  rand_req_address,
			    input 	  rand_req_we,
			    input [3:0]   rand_req_we_array,
			    input 	  rand_req,
			    output 	  rand_req_ack,
			    input [31:0]  rand_req_datain,
			    input [25:0]  bulk_req_address,
			    input 	  bulk_req_we,
			    input [3:0]   bulk_req_we_array,
			    input 	  bulk_req,
			    output 	  bulk_req_ack,
			    input 	  bulk_req_algn,
			    output 	  bulk_req_algn_ack,
			    input [31:0]  bulk_req_datain,
			    output [31:0] user_req_dataout);
  wire [31:0] 				         user_req_datain;
  wire [2:0] 					 command_user,
						 command_statechange_req,
						 cur_state;
  wire [12:0] 					 address_user;
  wire [1:0] 					 bank_user;
  wire 						 rst_user,
						 change_requested,
						 change_possible,
						 some_page_active,
						 refresh_time;
  wire [3:0] 					 internal_com_lat,
						 internal_we_array;

  assign CS = 1'b0; // Always on.
  assign user_req_datain = bulk_req_algn ?
			   bulk_req_datain : rand_req_datain;

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

			     .ADDRESS_RAND(rand_req_address),
			     .port_WE_RAND(rand_req_we),
			     .port_REQUEST_ACCESS_RAND(rand_req),
			     .GRANT_ACCESS_RAND(rand_req_ack),
			     .WE_ARRAY_RAND(rand_req_we_array),

			     .port_ADDRESS_BULK(bulk_req_address),
			     .port_WE_BULK(bulk_req_we),
			     .port_REQUEST_ACCESS_BULK(bulk_req),
			     .GRANT_ACCESS_BULK(bulk_req_ack),
			     .port_REQUEST_ALIGN_BULK(bulk_req_algn),
			     .GRANT_ALIGN_BULK(bulk_req_algn_ack),
			     .port_WE_ARRAY_BULK(bulk_req_we_array),

			     .ADDRESS_REG(address_user),
			     .BANK_REG(bank_user),
			     .COMMAND_REG(command_user),
			     .INTERNAL_COMMAND_LATCHED(internal_com_lat),
			     .INTERNAL_WE_ARRAY(internal_we_array));

  outputs data_driver(.CLK_p(CLK_p),
		      .CLK_n(CLK_n),
		      .CLK_dp(CLK_dp),
		      .CLK_dn(CLK_dn),
		      .RST(RST),
		      .COMMAND_LATCHED(internal_com_lat),
		      .WE_ARRAY(internal_we_array),
		      .port_DATA_W(user_req_datain),
		      .DQ(DQ),
		      .DQS(DQS),
		      .DATA_R(user_req_dataout),
		      .DM(DM));

endmodule // ddr_memory_controler_stage1
