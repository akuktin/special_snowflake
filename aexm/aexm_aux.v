module cache_stall(input  cache_busy_n,
		   input  cpu_force,
		   input  cpu_req,
		   output cache_enable);
  reg 			  xcache_enable;
  assign cache_enable = xcache_enable;

  always @(cpu_force or cpu_req or cache_busy_n)
    begin
      case ({cpu_force,cpu_req,cache_busy_n})
	3'b100: xcache_enable <= 1;
	3'b101: xcache_enable <= 1;
	3'b110: xcache_enable <= 1;
	3'b111: xcache_enable <= 1;
	3'b011: xcache_enable <= 1;
	default: xcache_enable <= 0;
      endcase // case ({cpu_force,cpu_req,cache_busy_n})
    end

endmodule // cache_stall
