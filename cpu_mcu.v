module cache (input CPU_CLK,
	      input 	    MCU_CLK,
	      input 	    RST,
	      input [31:0]  aexm_cache_cycle_addr,
	      input [31:0]  aexm_cache_precycle_addr,
	      input [31:0]  aexm_cache_datao, // CPU perspective
	      output [31:0] aexm_cache_datai, // CPU perspective
	      input 	    aexm_cache_cycle_we,
	      output 	    aexm_cache_cachebusy_n,
//--------------------------------------------------
//--------------------------------------------------
              input 	    dma_mcu_access,
              output [25:0] mem_addr,
              output 	    mem_we,
              output 	    mem_do_act,
              output [31:0] mem_dataintomem,
              input 	    mem_ack,
              input [31:0]  mem_datafrommem,
//--------------------------------------------------
	      input 	    VMEM_ACT,
	      input 	    WE_TLB);
  reg 			    first_word, mem_ack_reg, mem_do_act_reg,
			    read_counter_NULL_r, request_acted_on_r;
  reg 			    request_acted_on,
			    read_counter_NULL;
  reg [2:0] 		    read_counter;
  reg [31:0] 		    data_out;

  reg 			    MEM_LOOKUP_r_n, low_bit;
  reg 			    writing_into_cache, writing_into_tlb,
			    writing_into_mem;
  reg [31:0] 		    DATAO_r, PH_ADDR_r;
  reg 			    MEM_LOOKUP_m_n;
  reg [1:0] 		    WE_m, WE_tlb_m, WE_mm;
  reg [31:0] 		    DATAO_m, PH_ADDR_m;

  wire [31:0] 		    vaddr, wdata_data, wdata_ctag;
  wire [7:0] 		    idx, tlb_idx,
			    idx_w, tlb_idx_w,
			    waddr_data, waddr_ctag;
  wire [13:0] 		    mmu_req;
  wire [15:0] 		    tlb_in_tag, tlb_in_mmu;
  wire 			    WE_tlb_m_c, WE_m_c, we_data, we_ctag,
			    cache_hit, MMU_FAULT;

  wire [31:0] 		    data_cache;
  wire [21:0] 		    req_tag;
  wire [13:0] 		    rsp_tag, mmu_vtag;

  reg 			    mcu_valid, cachehit_vld;

  wire [31:0] 		    DATA_INTO_CPU;
  assign DATA_INTO_CPU = mem_datafrommem;

  assign mem_do_act = (!MEM_LOOKUP_m_n) & dma_mcu_access &
		      (!request_acted_on);

  assign mem_addr = {2'b00,PH_ADDR_m[31:2]};
  assign mem_we = WE_mm[0] && (!mem_ack_reg);
  assign mem_dataintomem = DATAO_m;

  assign aexm_cache_cachebusy_n = cache_hit;
  assign vaddr = aexm_cache_precycle_addr;

  assign idx = vaddr[9:2];
  assign tlb_idx = vaddr[17:10];

  assign idx_w = aexm_cache_cycle_addr[9:2];
  assign tlb_idx_w = aexm_cache_cycle_addr[17:10];
  assign mmu_req = aexm_cache_cycle_addr[31:18];

  assign tlb_in_tag = DATAO_m[31:16];
  assign tlb_in_mmu = DATAO_m[15:0];

  assign WE_tlb_m_c = WE_tlb_m[0] & (~(WE_tlb_m[1]));

  assign WE_m_c = (WE_m[0]) & (~(WE_m[1]));
  assign we_data = mcu_valid || WE_m_c;
  assign we_ctag = mcu_valid || WE_m_c;
  assign wdata_data = WE_m_c ? DATAO_m : DATA_INTO_CPU;
  assign waddr_data = WE_m_c ? PH_ADDR_m[9:2] : {idx_w[7:1],low_bit};
  assign wdata_ctag = WE_m_c ? PH_ADDR_m[31:10] : {rsp_tag,tlb_idx_w};
  assign waddr_ctag = WE_m_c ? PH_ADDR_m[9:2] : {idx_w[7:1],low_bit};
  assign aexm_cache_datai = cache_hit ? data_cache : data_out;

  assign cache_hit = ({cachehit_vld,req_tag} ^
		      {1'b1,rsp_tag,tlb_idx_w}) ==
		     {(23){1'b0}};
  assign MMU_FAULT = ({VMEM_ACT,mmu_vtag} ^ {1'b1,mmu_req}) != {(15){1'b0}};

  iceram32 cachedat(.RDATA(data_cache),
                    .RADDR(idx),
                    .RE(1'b1),
                    .RCLKE(1'b1),
                    .RCLK(CPU_CLK),
                    .WDATA(wdata_data),
                    .MASK(0),
                    .WADDR(waddr_data),
                    .WE(we_data),
                    .WCLKE(1'b1),
                    .WCLK(MCU_CLK));

  wire [9:0] 		    ignore_cachetag;
  iceram32 cachetag(.RDATA({ignore_cachetag,req_tag}),
                    .RADDR(idx),
                    .RE(1'b1),
                    .RCLKE(1'b1),
                    .RCLK(CPU_CLK),
                    .WDATA(wdata_ctag),
                    .MASK(0),
                    .WADDR(waddr_ctag),
                    .WE(we_ctag),
                    .WCLKE(1'b1),
                    .WCLK(MCU_CLK));

  wire [1:0] 		    ignore_tlb;
  iceram16 tlb(.RDATA({ignore_tlb,rsp_tag}),
               .RADDR(tlb_idx),
               .RE(1'b1),
               .RCLKE(1'b1),
               .RCLK(CPU_CLK),
	       .WDATA(tlb_in_tag),
	       .MASK(0),
	       .WADDR(PH_ADDR_m[17:10]),
	       .WE(WE_tlb_m_c),
	       .WCLKE(1'b1),
	       .WCLK(MCU_CLK));

  wire [1:0] 		    ignore_tlbtag;
  iceram16 tlbtag(.RDATA({ignore_tlbtag,mmu_vtag}),
		  .RADDR(tlb_idx),
		  .RE(1'b1),
		  .RCLKE(1'b1),
		  .RCLK(CPU_CLK),
		  .WDATA(tlb_in_mmu),
		  .MASK(0),
		  .WADDR(PH_ADDR_m[17:10]),
		  .WE(WE_tlb_m_c),
		  .WCLKE(1'b1),
		  .WCLK(MCU_CLK));

  always @(read_counter)
    case (read_counter)
      3'd6: mcu_valid <= 1;
      3'd7: mcu_valid <= 1;
      default: mcu_valid <= 0;
    endcase // case (read_counter)

  always @({MEM_LOOKUP_r_n,aexm_cache_cycle_we,
	   request_acted_on_r,read_counter_NULL_r})
    case ({MEM_LOOKUP_r_n,aexm_cache_cycle_we,
	   request_acted_on_r,read_counter_NULL_r})
      4'b10xx: begin
	cachehit_vld <= 1;
	// no_action;
      end
      4'b111x: begin
	cachehit_vld <= 1;
	// mandatory refraction to write commands after a write;
      end
      4'b1101: begin
	cachehit_vld <= 0;
	// no_action;
      end
      4'b1100: begin
	cachehit_vld <= 0;
	// no_action;
      end
      4'b0000: begin
	cachehit_vld <= 0;
	// read_waiting_for_mcu;
      end
      4'b0001: begin
	cachehit_vld <= 0;
	// read_waiting_for_mcu;
      end
      4'b0010: begin
	cachehit_vld <= 0;
	// read_mcu_request_in_progress;
      end
      4'b0011: begin
	cachehit_vld <= 1;
	// read_mcu_request_completed;
      end
      4'b0100: begin
	cachehit_vld <= 0;
	// write_waiting_for_mcu;
      end
      4'b0101: begin
	cachehit_vld <= 0;
	// write_waiting_for_mcu;
      end
      4'b0110: begin
	cachehit_vld <= 1;
	// write_mcu_request_completed;
      end
      4'b0111: begin
	cachehit_vld <= 1;
	// write_mcu_request_completed;
      end
      default: cachehit_vld <= 1;
    endcase

  always @(posedge CPU_CLK)
    if (!RST)
      begin
	MEM_LOOKUP_r_n <= 1; writing_into_cache <= 0;
	DATAO_r <= 0; PH_ADDR_r <= 0; writing_into_tlb <= 0;
	read_counter_NULL_r <= 0; request_acted_on_r <= 0;
	writing_into_mem <= 0;
      end
    else
      begin
        if (!cache_hit)
          begin
	    /* A speed hack. Normally, I'm supposed to put a
	     * conditional depending on two inputs, but that
	     * just takes too long in the silicon. */
//            MEM_LOOKUP_r_n <= MMU_FAULT;
            MEM_LOOKUP_r_n <= 0; // for testing only
          end
        else
          begin
            MEM_LOOKUP_r_n <= 1;
          end

	begin
          writing_into_cache <= aexm_cache_cycle_we;
	  writing_into_tlb <= WE_TLB;
	  writing_into_mem <= (aexm_cache_cycle_we || WE_TLB);

	  DATAO_r <= aexm_cache_datao;
	  PH_ADDR_r <= {rsp_tag,aexm_cache_cycle_addr[18:0]};
	end

	begin
	  read_counter_NULL_r <= read_counter_NULL;
	  request_acted_on_r <= request_acted_on;
	end

//	if (SET_TLB)
//	  TLB_BASE_PTR = vaddr;
      end

  always @(posedge MCU_CLK)
    if (!RST)
      begin
	MEM_LOOKUP_m_n <= 1'b1; WE_m <= 0; DATAO_m <= 0; PH_ADDR_m <= 0;
	WE_tlb_m <= 0; low_bit <= 0; data_out <= 0; request_acted_on <= 0;
	read_counter <= 0; mem_ack_reg <= 0; mem_do_act_reg <= 0;
	read_counter_NULL <= 0; WE_mm <= 0;
      end
    else
      begin
	begin
	  /* Keep in mind that WE_tlb_m_c overrides
	   * MEM_LOOKUP_m_c. */
	  MEM_LOOKUP_m_n <= MEM_LOOKUP_r_n;

	  WE_m <= {WE_m[0],writing_into_cache};
	  WE_tlb_m <= {WE_tlb_m[0],writing_into_tlb};
	  WE_mm <= {WE_mm[0],writing_into_mem};

	  DATAO_m <= DATAO_r;
	  PH_ADDR_m <= PH_ADDR_r;
	end

        if (mcu_valid)
          begin
            low_bit <= ~low_bit;
          end
        else
          begin
            low_bit <= PH_ADDR_m[2];
          end

        if (read_counter == 3'd6)
          data_out <= DATA_INTO_CPU;

	mem_ack_reg <= mem_ack;
	mem_do_act_reg <= mem_do_act;

	if (mem_do_act_reg & mem_ack_reg)
	  request_acted_on <= 1;
	else
	  if (request_acted_on & MEM_LOOKUP_m_n)
	    request_acted_on <= 0;

	if ((!WE_mm[1]) && mem_ack_reg && mem_do_act_reg)
	  begin
//	    read_counter <= 3'd2;
	    read_counter <= 3'd4; // for testing only
	    read_counter_NULL <= 0;
	  end
	else
	  begin
	    if (read_counter != 3'd0)
	      read_counter <= read_counter +1;

	    case (read_counter)
////	      3'd5: read_counter_NULL <= 1;
//	      3'd6: read_counter_NULL <= 1;
	      3'd7: read_counter_NULL <= 1;
	      3'd0: read_counter_NULL <= 1;
	      default: read_counter_NULL <= 0;
	    endcase // case (read_counter)
	  end
      end

  /* MISSING:
   *
   * 4. TLB writing (don't forget to deassert MEM_LOOKUP_m_n)
   */

endmodule
