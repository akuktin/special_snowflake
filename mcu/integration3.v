module ddr_memory_controler(input CLK_n,
			    input 	  CLK_dn,
			    input 	  RST_MASTER,
			    /* ------------------------- */
			    output 	  MEM_CLK_P,
			    output 	  MEM_CLK_N,
			    output 	  CKE,
			    output [2:0]  COMMAND,
			    output [13:0] ADDRESS,
			    output [2:0]  BANK,
			    inout [15:0]  DQ,
			    inout 	  UDQS,
			    inout 	  LDQS,
			    output 	  UDM,
			    output 	  LDM,
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
  wire [2:0] 					 command_user;
  wire [13:0] 					 address_user;
  wire [2:0] 					 bank_user;
  wire [3:0] 					 internal_com_lat,
						 internal_we_array;
  wire 						 rst_user;

  assign CS = 1'b0; // Always on.
  assign user_req_datain = bulk_req_algn ?
			   bulk_req_datain : rand_req_datain;

  clock_driver clock(.CLK_n(CLK_n),
		     .RST(RST_MASTER),
		     .CLK_P(MEM_CLK_P),
		     .CLK_N(MEM_CLK_N));

  initializer initializer_m(.CLK_n(CLK_n),
			    .RST(RST_MASTER),
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

  outputs data_driver(.CLK_n(CLK_n),
		      .CLK_dn(CLK_dn),
		      .COMMAND_LATCHED(internal_com_lat),
		      .WE_ARRAY(internal_we_array),
		      .port_DATA_W(user_req_datain),
		      .DQ(DQ),
		      .UDQS(UDQS),
		      .LDQS(LDQS),
		      .DATA_R(user_req_dataout),
		      .UDM(UDM),
		      .LDM(LDM));

endmodule // ddr_memory_controler_stage1
