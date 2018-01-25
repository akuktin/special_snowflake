`timescale 1ps/1ps

`include "test_inc.v"

// Memory module
`include "../mcu/commands.v"
`include "../mcu/state2.v"
`include "../mcu/initializer.v"
`include "../mcu/integration3.v"

module GlaDOS;
  reg CLK_n, CLK_dn, RST;
  reg SYS_RST, long_counter_o;
  reg [7:0] long_counter_h, long_counter_l;

  initial
    forever
      begin
        #1500 CLK_n <= 0;
        #1500 CLK_dn <= 0;
        #1500 CLK_n <= 1;
        #1500 CLK_dn <= 1;
      end

  always @(posedge CLK_n)
    begin
      if (!RST)
	begin
	  long_counter_h <= 0;
	  long_counter_l <= 0;
	  long_counter_o <= 0;
	end
      else
	begin
	  {long_counter_o,long_counter_l} <= long_counter_l +1;
	  if (long_counter_o)
	    long_counter_h <= long_counter_h +1;
	  if (long_counter_h == 8'hff)
	    SYS_RST <= 1;
	end
    end

  wire        dCLK_P, dCLK_N, dCKE, dUDQS, dLDQS, dUDM, dLDM, dCS, dODT;
  wire [2:0]  dCOMMAND;
  wire [13:0] dADDRESS;
  wire [2:0]  dBANK;
  wire [15:0] dDQ;

  reg [31:0]  d_user_req_address;
  reg         d_user_req_we = 1'b0, d_user_req = 1'b0;
  reg [3:0]   d_user_we_array;
  reg [31:0]  d_user_req_datain;
  wire 	      d_user_req_ack;

  reg [22:0]  mcu_page_addr = 23'd0;
  reg [8:0]   mcu_coll_addr = 9'd0;
  reg	      d_mcu_we = 1'b0, d_mcu_req_access = 1'b0,
	      d_mcu_algn_req = 1'b0;
  reg [3:0]   hf_we_array_fill;
  wire 	      d_mcu_req_ack, d_mcu_algn_ack;
  reg [31:0]  d_mcu_data_into;

  wire [31:0] d_user_req_dataout;

  reg 	      refresh_strobe = 1'b0;

  // ------------------------------------------------------------

  reg [31:0]  counter_sys_rst = 0, counter_exec = 0;
  reg 	      exec = 1'b0;

  // ------------------------------------------------------------

  ddr2 d_ddr2_mem(.ck(dCLK_P),
		  .ck_n(dCLK_N),
		  .cke(dCKE),
		  .cs_n(dCS),
		  .ras_n(dCOMMAND[2]),
		  .cas_n(dCOMMAND[1]),
		  .we_n(dCOMMAND[0]),
		  .dm_rdqs({dUDM,dLDM}),
		  .ba(dBANK),
		  .addr(dADDRESS[12:0]), // simulation limitation
		  .dq(dDQ),
		  .dqs({dUDQS,dLDQS}),
		  .dqs_n(),
		  .rdqs_n(),
		  .odt(1'b1));

  ddr_memory_controler d_mcu(.CLK_n(CLK_n),
                             .CLK_dn(CLK_dn),
                             .RST_MASTER(SYS_RST),
			     .MEM_CLK_P(dCLK_P),
			     .MEM_CLK_N(dCLK_N),
                             .CKE(dCKE),
                             .COMMAND(dCOMMAND),
                             .ADDRESS(dADDRESS),
                             .BANK(dBANK),
                             .DQ(dDQ),
                             .UDQS(dUDQS),
                             .LDQS(dLDQS),
                             .UDM(dUDM),
                             .LDM(dLDM),
                             .CS(dCS),
			     .refresh_strobe(refresh_strobe),
                             .rand_req_address(d_user_req_address[25:0]),
                             .rand_req_we(d_user_req_we),
			     .rand_req_we_array(d_user_we_array),
                             .rand_req(d_user_req),
                             .rand_req_ack(d_user_req_ack),
                             .rand_req_datain(d_user_req_datain),
			     .bulk_req_address({mcu_page_addr[16:0],
						mcu_coll_addr}),
			     .bulk_req_we(d_mcu_we),
			     .bulk_req_we_array(hf_we_array_fill),
			     .bulk_req(d_mcu_req_access),
			     .bulk_req_ack(d_mcu_req_ack),
			     .bulk_req_algn(d_mcu_algn_req),
			     .bulk_req_algn_ack(d_mcu_algn_ack),
                             .bulk_req_datain(d_mcu_data_into),
                             .user_req_dataout(d_user_req_dataout));

/*
  always @(CLK_dn)
    begin
      if (((dUDM == 1'b0) || (dUDM == 1'b1)) ||
	  d_mcu.data_driver.dqs_z_ctrl)
	begin
	  $display("direct observation: dqs %x dm %x data %x",
		   {dUDQS,dLDQS}, {dUDM,dLDM}, dDQ);
	end
    end
 */

//  initial
//    forever
//      #2304000 if (SYS_RST) refresh_strobe <= !refresh_strobe;

  initial
    begin
      RST <= 0; SYS_RST <= 0;
      #14875 RST <= 1;
      #400000000;
      exec <= 1'b1;
      #300000000;
      $display("irregular finish");
      $finish;
    end // initial begin

  always @(counter_sys_rst)
    d_mcu_data_into <= counter_sys_rst;
  always @(counter_exec)
    d_user_req_datain <= counter_exec;

  always @(posedge CLK_n)
    begin
      counter_sys_rst <= counter_sys_rst + SYS_RST;
      counter_exec <= counter_exec + exec;

      if (exec)
	begin
	  d_user_req_address <= d_user_req_address +1;
	  {mcu_page_addr,mcu_coll_addr} <= {mcu_page_addr,mcu_coll_addr} +1;
	  // TODO: wiggle all of these some cycles left-right.
	  case (counter_exec)
	    32'd0: begin
	      d_user_req <= 1;
	      d_user_req_we <= 0;
	    end
	    32'd20: begin
	      refresh_strobe <= !refresh_strobe;
	    end
	    32'd80: begin
	      d_user_req_we <= 1;
	    end
	    32'd100: begin
	      refresh_strobe <= !refresh_strobe;
	    end
	    32'd167: begin
	      d_user_req_we <= 0;
	    end
	    32'd184: begin
	      $display("assert ALIGN %t -------------------------------",
		       $time);
	      d_mcu_algn_req <= 1;
	    end
	    32'd192: begin
	      d_mcu_req_access <= 1;
	    end
	    32'd210: begin
	      d_mcu_we <= 1;
	      d_user_req_we <= 1; // exception!
	    end
-	    32'd230: begin
//	    32'd231: begin
	      d_mcu_req_access <= 0;
	      $display("deassert ALIGN %t -------------------------------",
		       $time);
	      $display("====<<<>>> ic %x ss %x pRLB %x RLB %x IDM %x",
		       d_mcu.interdictor_tracker.issue_com,
		       d_mcu.interdictor_tracker.second_stroke,
		       d_mcu.interdictor_tracker.port_REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.INTERNAL_DATA_MUX);
	      d_mcu_algn_req <= 0;
	    end // case: 32'd230
	    32'd231: begin
//	    32'd238: begin
	      $display("====<<<>>> ic %x ss %x pRLB %x RLB %x IDM %x",
		       d_mcu.interdictor_tracker.issue_com,
		       d_mcu.interdictor_tracker.second_stroke,
		       d_mcu.interdictor_tracker.port_REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.INTERNAL_DATA_MUX);
	    end
	    32'd232: begin
	      $display("====<<<>>> ic %x ss %x pRLB %x RLB %x IDM %x",
		       d_mcu.interdictor_tracker.issue_com,
		       d_mcu.interdictor_tracker.second_stroke,
		       d_mcu.interdictor_tracker.port_REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.INTERNAL_DATA_MUX);
	    end
	    32'd233: begin
	      $display("====<<<>>> ic %x ss %x pRLB %x RLB %x IDM %x",
		       d_mcu.interdictor_tracker.issue_com,
		       d_mcu.interdictor_tracker.second_stroke,
		       d_mcu.interdictor_tracker.port_REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.INTERNAL_DATA_MUX);
	    end
	    32'd234: begin
	      $display("====<<<>>> ic %x ss %x pRLB %x RLB %x IDM %x",
		       d_mcu.interdictor_tracker.issue_com,
		       d_mcu.interdictor_tracker.second_stroke,
		       d_mcu.interdictor_tracker.port_REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.INTERNAL_DATA_MUX);
	    end
	    32'd235: begin
	      $display("====<<<>>> ic %x ss %x pRLB %x RLB %x IDM %x",
		       d_mcu.interdictor_tracker.issue_com,
		       d_mcu.interdictor_tracker.second_stroke,
		       d_mcu.interdictor_tracker.port_REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.INTERNAL_DATA_MUX);
	    end
	    32'd236: begin
	      $display("====<<<>>> ic %x ss %x pRLB %x RLB %x IDM %x",
		       d_mcu.interdictor_tracker.issue_com,
		       d_mcu.interdictor_tracker.second_stroke,
		       d_mcu.interdictor_tracker.port_REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.INTERNAL_DATA_MUX);
	    end
	    32'd237: begin
	      $display("====<<<>>> ic %x ss %x pRLB %x RLB %x IDM %x",
		       d_mcu.interdictor_tracker.issue_com,
		       d_mcu.interdictor_tracker.second_stroke,
		       d_mcu.interdictor_tracker.port_REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.REQUEST_ALIGN_BULK,
		       d_mcu.interdictor_tracker.INTERNAL_DATA_MUX);
	    end
	    32'd240: begin
	      d_user_req_we <= 1;
	    end
	    32'd257: begin
	      $display("assert ALIGN %t -------------------------------",
		       $time);
	      d_mcu_algn_req <= 1;
	      d_mcu_we <= 1;
	      d_mcu_req_access <= 1;
	    end
	    32'd272: begin
	      $display("deassert ALIGN %t -------------------------------",
		       $time);
	      d_mcu_algn_req <= 0;
	      d_mcu_req_access <= 0;
	    end
	    32'd300: begin
	      mcu_page_addr <= 23'h200;
	      d_mcu_algn_req <= 1;
	      d_mcu_req_access <= 1;
	    end
	    32'd320: begin
	      d_mcu_algn_req <= 0;
	      d_mcu_req_access <= 0;
	    end
	    32'd350: begin
	      d_user_req_we <= 0;
	    end
	    32'd360: begin
	      $display("assert ALIGN %t -------------------------------",
		       $time);
	      d_mcu_algn_req <= 1;
	      d_mcu_req_access <= 1;
	    end
	    32'd366: begin
	      d_user_req_we <= 1;
	    end
	    32'd380: begin
	      d_mcu_algn_req <= 0;
	      d_mcu_req_access <= 0;
	    end
	    32'd400: begin
	      d_mcu_algn_req <= 1;
	      d_mcu_req_access <= 1;
	    end
	    32'd406: begin
	      d_user_req_we <= 0;
	    end
	    32'd430: begin
	      d_mcu_algn_req <= 0;
	      d_mcu_req_access <= 0;
	    end
	    32'd460: begin
	      $display("regular finish");
	      $finish;
	    end
	  endcase // case (counter_exec)
	  d_user_we_array <= 4'hf;
	end
      else
	begin
	  d_user_req_address <= 0;
	  d_user_we_array <= 4'hf;
	  hf_we_array_fill <= 4'hf;
	end
    end // always @ (posedge CLK_n)

endmodule // GlaDOS
