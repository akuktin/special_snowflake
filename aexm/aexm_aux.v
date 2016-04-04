module cache_stall(input  cache_busy_n,
		   input  cpu_force,
		   output cache_enable);
  reg 			  xcache_enable;
  assign cache_enable = xcache_enable;

  always @(cache_busy or cpu_force)
    begin
      if (cpu_force)
	xcache_enable <= 1;
      else
	if (cache_busy_n)
	  xcache_enable <= 1;
	else
	  xcache_enable <= 0;
    end

endmodule // cache_stall
