module aexm_enable(input CLK,
		   input      grst,
		   input      icache_busy,
		   input      dcache_busy,
		   input      dSTRLOD,
		   output reg cpu_mode_memop, // 0: stall, 1: normal
		   output     cpu_enable,
		   output     icache_enable,
		   output     dcache_enable);
  reg 			      just_issued_dcache_command, starter;
  wire 			      enter_memop_criterion,
			      exit_memop_criterion;

  assign cpu_enable = (cpu_mode_memop && (! icache_busy)) ||
		      (starter && ! grst);

  assign enter_memop_criterion = cpu_mode_memop &&
				 dSTRLOD &&
				 cpu_enable;

  assign exit_memop_criterion = (!cpu_mode_memop) &&
				(!icache_busy) &&
				(!dcache_busy) &&
				(!just_issued_dcache_command);

  assign icache_enable = cpu_mode_memop ?
			 (cpu_enable && (! enter_memop_criterion)) :// +TLB
			 (exit_memop_criterion);

  assign dcache_enable = exit_memop_criterion;

  always @(posedge CLK)
    if (grst)
      begin
	starter <= 1;
	cpu_mode_memop <= 1; cpu_enable <= 0;
	just_issued_dcache_command <= 0;
      end
    else
      begin
	starter <= 0;
	// Used to guarrantie there will never be two outstanding commands
	// to the data cache. Necessary for a scalar CPU core.
	just_issued_dcache_command <= dcache_enable;

	if (cpu_mode_memop)
	  begin
	    if (enter_memop_criterion)
	      cpu_mode_memop <= 0;
	  end
	else
	  if (exit_memop_criterion)
	    cpu_mode_memop <= 1;
      end

endmodule // aexm_enable
