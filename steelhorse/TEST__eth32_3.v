`timescale 10ns/1ps

`include "eth_recv.v"
`include "eth_send.v"
`include "eth.v"

module GLaDOS;
  reg record; reg [3:0] halt; reg [31:0] record_buff;
  reg sampler_CLK, send_CLK, recv_CLK, _RST, send_RST, do_halt, real_new_pckt,
      enc_CLK;
  reg [15:0] DATAIN[511:0], DATAOUT[511:0];
  wire __WIRE_1, __WIRE_2;
  reg __WIRE_3;
  wire [9:0] addr_send, addr_recv;
  wire [31:0] idataout_send, idataout_recv;
  wire [31:0] data_in;
  wire [31:0] data_out;
  reg [15:0] idatain_send;
  reg [9:0] iaddr_send, iaddr_recv;
  reg [15:0] irecv_hldr, isend_hldr;
  wire write_data_in, read_data_out, new_pckt, sendreg_an;
  reg sendreg_rq;
  reg RUN_sig;

  assign data_in = addr_send[9] ?
                   {DATAIN[{addr_send[6:0],1'b0}],
                    DATAIN[{addr_send[6:0],1'b1}]} :
                   0;

  Steelhorse send(.sampler_CLK(sampler_CLK),
		  .enc_CLK(enc_CLK),
		  .recv_CLK(recv_CLK),
		  .send_CLK(send_CLK),
		  .RST(_RST),
		  .WIRE_RX(__WIRE_3),
		  .WIRE_TX(__WIRE_1),
		  .DATA_ADDR(addr_send),
		  .DATA_RECV(),
		  .WRITE_DATA_RECV(),
		  .DATA_SEND(data_in),
		  .READ_DATA_SEND(read_data_out),
		  .NWPCKT_IRQ(),
		  .NWPCKT_IRQ_VALID(),
		  .RUN(RUN_sig),
		  .BUSY(),
		  .INTRFC_DATAIN({16'h0,idatain_send}),
		  .INTRFC_DATAOUT(idataout_send));
  Steelhorse recv(.sampler_CLK(sampler_CLK),
		  .recv_CLK(recv_CLK),
		  .send_CLK(send_CLK),
		  .enc_CLK(enc_CLK),
		  .RST(_RST),
		  .WIRE_RX(__WIRE_1),
		  .WIRE_TX(__WIRE_2),
		  .DATA_ADDR(addr_recv),
		  .DATA_RECV(data_out),
		  .WRITE_DATA_RECV(write_data_in),
		  .DATA_SEND(),
		  .NWPCKT_IRQ(),
		  .NWPCKT_IRQ_VALID(new_pckt),
		  .RUN(),
		  .BUSY(),
		  .INTRFC_DATAIN(),
		  .INTRFC_DATAOUT(idataout_recv));

  initial forever begin #0.5 sampler_CLK <= 1; #0.5 sampler_CLK <= 0; record_buff <= record_buff +1; end
  initial forever begin #5 send_CLK <= 1; #5 send_CLK <= 0; end
  initial forever begin #2.5 enc_CLK <= 1; #2.5 enc_CLK <= 0; end
  initial forever begin #4 recv_CLK <= 1; #4 recv_CLK <= 0; end

  initial
    begin
      record_buff <= 0; real_new_pckt <= 0;
      do_halt <= 0; __WIRE_3 <= 0; record <= 0; halt <= 0;
      iaddr_send <= 10'h009; iaddr_recv <= 10'h008;
      _RST <= 0; RUN_sig <= 0;
      #20;
      _RST <= 1;
      #180;
      record <= 1;
      #20;
      #18000;

      #2;
      iaddr_send <= 10'h00a;
      RUN_sig <= 1;
      idatain_send <= 16'h0010;
      #12 iaddr_send <= 10'h009;
      #6;
      #540 __WIRE_3 <= 1;
      #20 __WIRE_3 <= 0;

      #18000;
      #2;
      iaddr_send <= 10'h00a;
      RUN_sig <= 0;
      idatain_send <= 16'h0005;
      #12 iaddr_send <= 10'h009;
      #6;

      #30000 record <= 0;
      #20;
      $display("bad_end");
      $display("\t%x %x %x %x  %x %x %x %x\n\t%x %x %x %x  %x %x %x %x",
	       DATAOUT[0], DATAOUT[1], DATAOUT[2], DATAOUT[3],
	       DATAOUT[4], DATAOUT[5], DATAOUT[6], DATAOUT[7],
	       DATAOUT[8], DATAOUT[9], DATAOUT[10],DATAOUT[11],
	       DATAOUT[12],DATAOUT[13],DATAOUT[14],DATAOUT[15]);
      $display("\t%x %x %x %x  %x %x %x %x\n\t%x %x %x %x  %x %x %x %x",
	       DATAOUT[16],DATAOUT[17],DATAOUT[18],DATAOUT[19],
	       DATAOUT[20],DATAOUT[21],DATAOUT[22],DATAOUT[23],
	       DATAOUT[24],DATAOUT[25],DATAOUT[26],DATAOUT[27],
	       DATAOUT[28],DATAOUT[29],DATAOUT[30],DATAOUT[31]);
      $finish;
     end

   initial
     begin
       DATAIN[0] = 16'h1234;
       DATAIN[1] = 16'h5678;
       DATAIN[2] = 16'h9abc;
       DATAIN[3] = 16'hdef0;
       DATAIN[4] = 16'h0123;
       DATAIN[5] = 16'h4567;
       DATAIN[6] = 16'h89ab;
       DATAIN[7] = 16'hcdef;
    end

  always @(negedge write_data_in)
    if (~addr_recv[9])
      begin
        DATAOUT[{addr_recv[6:0],1'b0}] <= data_out[31:16];
        DATAOUT[{addr_recv[6:0],1'b1}] <= data_out[15:0];
      end

  always @(posedge recv_CLK)
    if (new_pckt)
      begin
	if (real_new_pckt)
	  begin
	    do_halt <= 1;
	  end
	else
	  begin
	    real_new_pckt <= 1;
	    $display("reception successfull.");
	  end
      end

  always @(posedge send_CLK)
    begin
/*    if (read_data_out)
      begin
	data_in <= {DATAIN[{addr_send[6:0],1'b0}],
                    DATAIN[{addr_send[6:0],1'b1}]};
      end
*/
    if (record)
      begin
//	$display("");
	if ((halt != 4'h0) || do_halt)
	  begin
	    if (halt == 4'h7)
	      begin
		$display("good_end");
		$display("\t%x %x %x %x  %x %x %x %x\n\t%x %x %x %x  %x %x %x %x",
			 DATAOUT[0], DATAOUT[1], DATAOUT[2], DATAOUT[3],
			 DATAOUT[4], DATAOUT[5], DATAOUT[6], DATAOUT[7],
			 DATAOUT[8], DATAOUT[9], DATAOUT[10],DATAOUT[11],
			 DATAOUT[12],DATAOUT[13],DATAOUT[14],DATAOUT[15]);
		$display("\t%x %x %x %x  %x %x %x %x\n\t%x %x %x %x  %x %x %x %x",
			 DATAOUT[16],DATAOUT[17],DATAOUT[18],DATAOUT[19],
			 DATAOUT[20],DATAOUT[21],DATAOUT[22],DATAOUT[23],
			 DATAOUT[24],DATAOUT[25],DATAOUT[26],DATAOUT[27],
			 DATAOUT[28],DATAOUT[29],DATAOUT[30],DATAOUT[31]);
		$display("recv_len: %x", idataout_recv);
		$display("send_buff: %x", idataout_send);
		$finish;
	      end
	    else
	      halt <= halt +1;
	  end
      end
    end

/*
  always @(posedge send_CLK)
    if (record)
      #0.3
	$display("__WIRE_1: %x", __WIRE_1);
*/
/*
  always @(negedge send_CLK)
    if (record)
      #0.3
	$display("__WIRE_1: %x --", __WIRE_1);
*/

endmodule // GLaDOS
