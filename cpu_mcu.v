module cache ()
  wire [31:0]       data_cache, data_out;
  wire [7:0]        idx, tlb_idx;
  wire              cache_hit;

  assign idx = vaddr[9:2];
  assign tlb_idx = vaddr[18:10];
  assign mmu_req = vaddr[31:19];
  assign tlb_in_tag = DATAO_m[31:16];
  assign tlb_in_mmu = DATAO_m[15:0];

  assign WE_tlb_m_c = WE_tlb_m[0] & (~(WE_tlb_m[1]));

  assign WE_m_c = (WE_m[0]) & (~(WE_m[1]));
  assign we_data = mcu_valid || WE_m_c;
  assign we_ctag = mcu_valid || WE_m_c;
  assign wdata_data = WE_m_c ? DATAO_m : DATA_INTO_CPU;
  assign waddr_data = WE_m_c ? PH_ADDR_m[9:2] : {idx[7:1],low_bit};
  assign wdata_ctag = WE_m_c ? PH_ADDR_m[31:10] : {rsp_tag,tlb_idx};
  assign waddr_ctag = WE_m_c ? PH_ADDR_m[9:2] : {idx[7:1],low_bit};
  assign CACHE_DATA = cache_hit ? data_cache : data_out;

  assign stall_cache = writing_into_cache != 2'b00;

  assign cache_hit = (req_tag ^ {rsp_tag,tlb_idx}) == {(21){1'b0}};
  assign MMU_FAULT_n = (mmu_vtag ^ mmu_req) == {(12){1'b0}};

  iceram32 cache(.RDATA(data_cache),
                 .RADDR(idx),
                 .RE(1'b1),
                 .RCLKE(1'b1),
                 .RCLK(CLK_CPU),
                 .WDATA(wdata_data),
                 .MASK(0),
                 .WADDR(waddr_data),
                 .WE(we_data),
                 .WCLKE(1'b1),
                 .WCLK(MCU_CLK));

  iceram32 cachetag(.RDATA(req_tag),
                    .RADDR(idx),
                    .RE(1'b1),
                    .RCLKE(1'b1),
                    .RCLK(CLK_CPU),
                    .WDATA(wdata_ctag),
                    .MASK(0),
                    .WADDR(waddr_ctag),
                    .WE(we_ctag),
                    .WCLKE(1'b1),
                    .WCLK(MCU_CLK));

  iceram16 tlb(.RDATA(rsp_tag),
               .RADDR(tlb_idx),
               .RE(1'b1),
               .RCLKE(1'b1),
               .RCLK(CLK_CPU),
	       .WDATA(tlb_in_tag),
	       .MASK(0),
	       .WADDR(PH_ADDR_m[18:10]),
	       .WE(WE_tlb_m_c),
	       .WCLKE(1'b1),
	       .WCLK(MCU_CLK));

  iceram16 tlbtag(.RDATA(mmu_vtag),
		  .RADDR(tlb_idx),
		  .RE(1'b1),
		  .RCLKE(1'b1),
		  .RCLK(CLK_CPU),
		  .WDATA(tlb_in_mmu),
		  .MASK(0),
		  .WADDR(PH_ADDR_m[18:10]),
		  .WE(WE_tlb_m_c),
		  .WCLKE(1'b1),
		  .WCLK(MCU_CLK));

  always @(posedge CPU_CLK)
    if (!RST)
      begin
      end
    else
      begin
        if (!cache_hit)
          begin
	    /* A speed hack. Normally, I'm supposed to put a
	     * conditional depending on two inputs, but that
	     * just takes too long in the silicon. */
            MEM_LOOKUP_r <= MMU_FAULT_n;
          end
        else
          begin
            MEM_LOOKUP_r <= 0;
          end

	begin
          writing_into_cache <= {writing_into_cache[0],WE};
	  DATAO_r <= DATAO;
	  PH_ADDR_r <= {rsp_tag,vaddr[18:0]};
	  writing_into_tlb <= {writing_into_tlb[0],WE_TLB};
	end

	if (SET_TLB)
	  TLB_BASE_PTR = vaddr;
      end

  always @(posedge MCU_CLK)
    if (!RST)
      begin
      end
    else
      begin
	begin
	  /* Keep in mind that WE_tlb_m_c overrides
	   * MEM_LOOKUP_m_c. */
	  MEM_LOOKUP_m <= {MEM_LOOKUP_m[0],MEM_LOOKUP_r};

	  WE_m <= {WE_m[0],writing_into_cache[0]};
	  DATAO_m <= DATAO_r;
	  PH_ADDR_m <= PH_ADDR_r;

	  WE_tlb_m <= {WE_tlb_m[0],writing_into_tlb[0]};
	end

        if (mcu_valid)
          begin
            low_bit <= ~low_bit;
          end
        else
          begin
            low_bit <= PH_ADDR_m[2];
          end

        if (first_word)
          begin
            data_out <= DATA_INTO_CPU;
          end
      end

endmodule
