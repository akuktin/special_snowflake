module aexm_enable(input CLK,
		   input      grst,
		   input      icache_busy,
		   input      dcache_busy,
		   input      dSTRLOD,
		   input      dLOD,
		   input      dSKIP,
		   input      fSTALL,
		   output reg cpu_mode_memop, // 0: stall, 1: normal
		   output     cpu_enable,
		   output     icache_enable,
		   output     dcache_enable);
  reg 			      starter, grst_delay;
  reg 			      just_issued_dcache_command;
  reg 			      dcache_LOD_enable_reg, dcache_LOD_enable_dly,
			      xLOD, xSTRLOD;
  wire 			      enter_memop_criterion,
			      exit_memop_criterion,
			      dcache_LOD_enable;

  assign cpu_enable = (cpu_mode_memop && (! icache_busy)) ||
		      (starter);

  assign enter_memop_criterion = cpu_mode_memop &&
				 (dSTRLOD || fSTALL) &&
				 (! dSKIP) &&
				 cpu_enable;

  assign exit_memop_criterion = (!cpu_mode_memop) &&
				(xLOD ?
				 ((!icache_busy) &&
				  (!dcache_busy) &&
				  (dcache_LOD_enable_dly)) :
				 ((!icache_busy) &&
				  (!dcache_busy) &&
				  (!just_issued_dcache_command)));

  assign icache_enable = starter ||
			 (cpu_mode_memop ?
			  (cpu_enable && (! enter_memop_criterion)) :// +TLB
			  (exit_memop_criterion));

  assign dcache_enable = xLOD ?
			 dcache_LOD_enable :
			 (exit_memop_criterion && xSTRLOD);

  assign dcache_LOD_enable = (!cpu_mode_memop) &&
			     (!dcache_LOD_enable_reg) &&
			     (!dcache_busy) &&
			     (!just_issued_dcache_command);

  always @(posedge CLK)
    if (!grst)
      begin
	grst_delay <= 0; starter <= 0;
	cpu_mode_memop <= 1;
	just_issued_dcache_command <= 0;
	dcache_LOD_enable_reg <= 0; dcache_LOD_enable_dly <= 0; xLOD <= 0;
	xSTRLOD <= 0;
      end
    else
      begin
	begin
	  grst_delay <= 1;
	  if (grst && !grst_delay)
	    starter <= 1;
	  else
	    starter <= 0;
	end
	// Used to guarrantie there will never be two outstanding commands
	// to the data cache. Necessary for a scalar CPU core.
	just_issued_dcache_command <= dcache_enable;

	if (cpu_enable)
	  begin
	    xSTRLOD <= dSTRLOD;
	    xLOD <= dLOD;
	  end

	if (cpu_mode_memop)
	  begin
	    if (enter_memop_criterion)
	      cpu_mode_memop <= 0;
	  end
	else
	  begin
	    if (exit_memop_criterion)
	      begin
		cpu_mode_memop <= 1;
		dcache_LOD_enable_reg <= 0;
		dcache_LOD_enable_dly <= 0;
	      end
	    else
	      begin
		if (dcache_LOD_enable)
		  dcache_LOD_enable_reg <= 1;
		dcache_LOD_enable_dly <= dcache_LOD_enable_reg;
	      end
	  end
      end

endmodule // aexm_enable
