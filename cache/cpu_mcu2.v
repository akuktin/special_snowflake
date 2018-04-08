module snowball_cache(input CPU_CLK,
		      input 	    MCU_CLK,
		      input 	    RST_CPU,
		      input 	    RST_SYS,
		      input [31:0]  cache_precycle_addr,
		      input [31:0]  cache_datao, // CPU perspective
		      output [31:0] cache_datai, // CPU perspective
		      input 	    cache_precycle_we,
		      output 	    cache_busy,
		      input 	    cache_precycle_enable,
		      input 	    cache_precycle_force_miss,
//--------------------------------------------------
//--------------------------------------------------
		      output [31:0] mem_addr,
		      output 	    mem_we,
		      output [3:0]  mem_we_array,
		      output 	    mem_do_act,
		      output [31:0] mem_dataintomem,
		      input 	    mem_ack,
		      input [31:0]  mem_datafrommem,
//--------------------------------------------------
		      output 	    dma_wrte,
		      output 	    dma_read,
		      input 	    dma_wrte_ack,
		      input 	    dma_read_ack,
		      input [31:0]  dma_data_read,
//--------------------------------------------------
		      input 	    VMEM_ACT,
		      input 	    cache_inhibit,
		      input 	    fake_miss,
//--------------------------------------------------
		      output 	    MMU_FAULT,
		      input 	    WE_TLB);
  reg 					MMU_FAULT = 1'b0, cache_busy = 1'b0,
					mem_do_act = 1'b0,
					dma_wrte = 1'b0, dma_read = 1'b0;
  reg [31:0] 				cache_datai = 32'd0,
					mem_addr = 32'd0,
					mem_dataintomem = 32'd0;

  reg 			    vmem = 1'b0;
  reg 			    mcu_responded_trans = 1'b0,
			    mcu_active_trans = 1'b0;
  reg 			    cache_vld = 1'b0, cache_tlb = 1'b0,
			    tlb_en_sticky = 1'b0,
			    cache_en_sticky = 1'b0, cache_busy_real = 1'b0;
  reg 			    mcu_responded = 1'b0, mcu_responded_reg = 1'b0;
  reg [31:0] 		    cache_cycle_addr, data_tomem_trans;
  reg 			    cache_cycle_we, tlb_cycle_we;
  reg 			    mcu_we = 1'b0, tlb_we_reg = 1'b0,
			    mem_do_act_reg, mcu_active_delay = 1'b0,
			    w_we_trans, w_tlb_trans, w_we_recv, w_tlb_recv,
			    mandatory_lookup_sig = 1'b0,
			    mandatory_lookup_pre_sig = 1'b0,
			    mandatory_lookup_sig_recv = 1'b0,
			    mandatory_lookup_exp = 1'b0,
			    mandatory_lookup_capture, datain_mux_dma,
			    cache_prev_we = 1'b0, mcu_active = 1'b0,
			    mcu_active_reg = 1'b0, cache_cycle_force_miss_n;
  reg [2:0] 		    read_counter = 3'h0;
  reg [31:0] 		    data_mcu_trans, data_mcu_trans_other,
			    w_addr_trans, w_data_trans,
			    w_addr_recv, w_data_recv, dma_data_read_reg = 0;
  reg [7:0] 		    w_addr, cache_prev_idx;
  reg [23:0] 		    wctag_data_forread_trans,
			    wctag_data_forread_recv, wctag_data_forread;

  wire [31:0] 		    data_cache, wdata_data, wctag_data,
			    mem_dataintocpu;
  wire 			    cache_hit, w_MMU_FAULT;

  wire [15:0] 		    tlb_in_tag, tlb_in_mmu;

  wire [15:0] 		    vmem_rsp_tag, rsp_tag, mmu_req, mmu_vtag;
  wire [23:0] 		    req_tag;
  wire [7:0] 		    idx_pre, tlb_idx_pre, tlb_idx;
  wire 			    cache_work, wdata_we, tlb_we, op_type_w,
			    activate_tlb, activate_cache,
			    tlb_reinit, cache_reinit, mandatory_lookup,
			    mandatory_lookup_act, mem_lookup;

  reg 			    mcu_valid_data, capture_data;

  assign mem_we_array = 4'b1100;

  assign idx_pre = cache_precycle_addr[7:0];
  assign tlb_idx_pre = cache_precycle_addr[15:8];

  assign tlb_idx = cache_cycle_addr[15:8];
  assign mmu_req = cache_cycle_addr[31:16];
  assign cache_work = cache_precycle_enable && (! cache_inhibit);

  assign vmem_rsp_tag = vmem ? rsp_tag : mmu_req;

  assign tlb_in_tag = mem_dataintomem[31:16];
  assign tlb_in_mmu = mem_dataintomem[15:0];

  /* This bit here can be optimized to perform checking vmem_rsp_tag in a
   * single gate. That is, a single gate can both compare and switch
   * what it compares to. I probably didn't code it well enough, though. */
  assign cache_hit = ((req_tag ^ {vmem_rsp_tag,tlb_idx}) ==
		      {(24){1'b0}}) ? cache_cycle_force_miss_n : 0;
  /* This bit here should be implementable exclusively by hacking the
   * carry chain. I probably didn't code this well enough also. */
  assign w_MMU_FAULT = (mmu_vtag ^ mmu_req) != {(16){1'b0}} ? vmem : 0;

  iceram32 cachedat(.RDATA(data_cache),
                    .RADDR(idx_pre),
                    .RE(cache_work),
                    .RCLKE(1'b1),
                    .RCLK(CPU_CLK),
                    .WDATA(wdata_data),
                    .MASK(0),
                    .WADDR(w_addr),
                    .WE(wdata_we),
                    .WCLKE(1'b1),
                    .WCLK(MCU_CLK));

  wire [7:0] 		    ignore_cachetag;
  iceram32 cachetag(.RDATA({ignore_cachetag,req_tag}),
                    .RADDR(idx_pre),
                    .RE(cache_work),
                    .RCLKE(1'b1),
                    .RCLK(CPU_CLK),
                    .WDATA(wctag_data),
                    .MASK(0),
                    .WADDR(w_addr),
                    .WE(wdata_we),
                    .WCLKE(1'b1),
                    .WCLK(MCU_CLK));

  iceram16 tlb(.RDATA(rsp_tag),
               .RADDR(tlb_idx_pre),
               .RE(cache_work),
               .RCLKE(1'b1),
               .RCLK(CPU_CLK),
	       .WDATA(tlb_in_tag),
	       .MASK({(16){1'b0}}),
	       .WADDR(mem_addr[7:0]),
	       .WE(tlb_we),
	       .WCLKE(1'b1),
	       .WCLK(MCU_CLK));

  iceram16 tlbtag(.RDATA(mmu_vtag),
		  .RADDR(tlb_idx_pre),
		  .RE(cache_work),
		  .RCLKE(1'b1),
		  .RCLK(CPU_CLK),
		  .WDATA(tlb_in_mmu),
		  .MASK({(16){1'b0}}),
		  .WADDR(mem_addr[7:0]),
		  .WE(tlb_we),
		  .WCLKE(1'b1),
		  .WCLK(MCU_CLK));

  assign cache_reinit = cache_en_sticky && (mcu_responded ||
					    ((! cache_busy_real) &&
					     (! fake_miss)));
  assign tlb_reinit = tlb_en_sticky && (mcu_responded ||
					((! cache_busy_real) &&
					 (! fake_miss)));
  assign mandatory_lookup = ((mandatory_lookup_sig_recv ^
			      mandatory_lookup_exp) &&
			     cache_prev_we) ||
			    (cache_vld && cache_cycle_we);
  assign mandatory_lookup_act = mandatory_lookup_capture &&
				(cache_prev_idx == cache_cycle_addr[7:0]);

  assign activate_cache = (cache_work && (! (cache_busy || mem_lookup))) ||
			  cache_reinit;
  assign activate_tlb   = (WE_TLB && (! (cache_busy || mem_lookup))) ||
			  tlb_reinit;

  assign mem_lookup = (cache_vld && (!w_MMU_FAULT) &&
		       ((! cache_hit) ||
			cache_cycle_we ||
			mandatory_lookup_act)) ||
		      cache_tlb;

  always @(posedge CPU_CLK)
    if (RST_CPU)
      begin
	vmem <= VMEM_ACT;
	MMU_FAULT <= w_MMU_FAULT;

	if (cache_work || WE_TLB)
	  begin
	    cache_cycle_force_miss_n <= ! cache_precycle_force_miss;
	    cache_cycle_addr <= cache_precycle_addr;
	    cache_cycle_we <= cache_precycle_we;
	    data_tomem_trans <= cache_datao;
	    tlb_cycle_we <= WE_TLB;
	    mandatory_lookup_capture <= mandatory_lookup;
	  end

	if (cache_vld && (! cache_cycle_we))
	  begin
	    if (cache_hit)
	      cache_datai <= data_cache;
	    else
	      cache_datai <= data_mcu_trans_other;
	  end
	else if (mcu_responded)
	  cache_datai <= data_mcu_trans;

	begin
	  w_addr_trans <= {vmem_rsp_tag,cache_cycle_addr[15:0]};
	  w_data_trans <= data_tomem_trans;
	  w_we_trans <= cache_cycle_we;
	  w_tlb_trans <= tlb_cycle_we;
	  wctag_data_forread_trans <= {vmem_rsp_tag,tlb_idx};
	end

	if (mem_lookup) // 4 signals and 3 compounds
	  begin
	    mcu_active_trans <= !mcu_active_trans;
	    cache_busy_real <= 1;
	    cache_prev_we <= cache_cycle_we;
	    cache_prev_idx <= cache_cycle_addr[7:0];

	    if (cache_cycle_we)
	      begin
		mandatory_lookup_exp <= !mandatory_lookup_exp;
	      end
	  end
	else
	  begin
	    if (mcu_responded)
	      cache_busy_real <= 0;
	  end // else: !if(mem_lookup)

	if (mem_lookup || fake_miss)
	  cache_busy <= 1;
	else
	  if ((cache_busy_real && mcu_responded) ||
	      (! cache_busy_real))
	    cache_busy <= 0;

	if (activate_cache || activate_tlb) // 10 signals + mem_lookup
	  begin
	    if (activate_cache)
	      begin
		cache_vld <= 1;
		cache_en_sticky <= 0;
	      end
	    else if (activate_tlb)
	      begin
		cache_tlb <= 1;
		tlb_en_sticky <= 0;
	      end
	  end
	else
	  begin
	    cache_vld <= 0;
	    cache_tlb <= 0;

	    if (cache_work && (! tlb_en_sticky))
	      cache_en_sticky <= 1;
	    if (WE_TLB && (! cache_en_sticky))
	      tlb_en_sticky <= 1;
	  end

	// Ofcourse, if it gliches, then we have a problem.
	mcu_responded <= (mcu_responded_trans ^ mcu_responded_reg) &&
			 !mcu_responded;
	if (mcu_responded)
	  mcu_responded_reg <= !mcu_responded_reg;
	mandatory_lookup_sig_recv <= mandatory_lookup_sig;
      end

  assign mem_we = (mcu_we || tlb_we_reg) && (!mem_ack);
  assign mem_dataintocpu = datain_mux_dma ?
			   dma_data_read_reg : mem_datafrommem;

  assign wdata_data = mem_dataintomem | mem_dataintocpu;
  /* BRAINWAVE: wdata_we could actually be just mcu_active_delay, and
   *            wctag_data could just be mem_addr[31:8]. Much simpler,
   *            same overall functionality. */
  assign wdata_we = (mcu_active_delay && mcu_we) ||
		    (mcu_valid_data);
  assign wctag_data = mcu_we ? mem_addr[31:8] : wctag_data_forread;
  assign tlb_we = mcu_active_delay && tlb_we_reg;
  assign op_type_w = (mcu_we || tlb_we_reg);

  always @(read_counter)
    case (read_counter)
      3'd6: begin mcu_valid_data <= 1; capture_data <= 1; end
      3'd7: begin mcu_valid_data <= 1; capture_data <= 0; end
      default: begin mcu_valid_data <= 0; capture_data <= 0; end
    endcase // case (read_counter)

  always @(posedge MCU_CLK)
    if (RST_SYS)
      begin
	// Ofcourse, if it gliches, then we have a problem.
	mcu_active <= (mcu_active_trans ^ mcu_active_reg) && !mcu_active;
	if (mcu_active)
	  mcu_active_reg <= !mcu_active_reg;
	mcu_active_delay <= mcu_active;
	if (mcu_active_delay && mcu_we)
	  mandatory_lookup_pre_sig <= !mandatory_lookup_pre_sig;
	/* Delay the response for a cycle to guarrantee no incomplete
	 * writes */
	mandatory_lookup_sig <= mandatory_lookup_pre_sig;

	begin
	  w_data_recv <= w_data_trans;
	  w_addr_recv <= w_addr_trans;
	  w_we_recv <= w_we_trans;
	  w_tlb_recv <= w_tlb_trans;
	  wctag_data_forread_recv <= wctag_data_forread_trans;
	end

	if (mcu_active)
	  begin
	    mem_do_act <= (w_addr_recv[31:30] == 2'b00);
	    dma_wrte <= (w_addr_recv[31:30] == 2'b11) && ( w_we_recv);
	    dma_read <= (w_addr_recv[31:30] == 2'b11) && (!w_we_recv);
	    // The below is HEAVILY hacked to enable generating wdata_data
	    // in a single gate.
	    // May be a bad idea to optimize THIS aggresivelly.
	    datain_mux_dma <= (w_addr_recv[31:30] == 2'b11) || w_we_recv;

	    if (w_we_recv | w_tlb_recv)
	      mem_dataintomem <= w_data_recv;
	    mem_addr <= w_addr_recv;
	    mcu_we <= w_we_recv;
	    tlb_we_reg <= w_tlb_recv;
	    wctag_data_forread <= wctag_data_forread_recv;
	  end
	else
	  begin
	    if (mem_do_act_reg && mem_ack)
	      begin
		mem_do_act <= 0;
		mem_dataintomem <= 0;
	      end
	    if (dma_wrte && dma_wrte_ack) // do I really need this?
                                          // maybe just use the ack signal??
	      dma_wrte <= 0;
	    if (dma_read && dma_read_ack) // DIRNT ?
	      dma_read <= 0;
	  end

	mem_do_act_reg <= mem_do_act;

	if (((mem_do_act_reg && mem_ack) || // DIRNT ?
	     (dma_read && dma_read_ack)) && // DIRNT ?
	    (! op_type_w))
	  read_counter <= 3'd3;
	else
	  if (read_counter != 3'd0)
	    read_counter <= read_counter +1;

	if (capture_data)
	  begin
	    data_mcu_trans <= mem_dataintocpu;
	    w_addr <= {w_addr[7:1],(~w_addr[0])};
	    dma_data_read_reg <= 0;
	  end
	else
	  begin
	    if (mcu_active)
	      w_addr <= w_addr_recv[7:0];

	    if (mcu_valid_data)
	      data_mcu_trans_other <= mem_dataintocpu;

	    if (dma_read && dma_read_ack) // DIRNT ?
	      dma_data_read_reg <= dma_data_read;
	  end

	if ((((mem_do_act && mem_ack) || // DIRNT ?
	      (dma_wrte && dma_wrte_ack)) && op_type_w) || // DIRNT ?
	    (capture_data))
	  mcu_responded_trans <= !mcu_responded_trans;
      end

endmodule // cache
