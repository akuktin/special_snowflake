tt=03; for i in a b c d e f; do sed -i "s/\(CHANGER 8'h5\)./\1${i}/" test_tt_${tt}.bin; { iverilog test_special_snowflake_core2.v && vvp a.out; rm a.out; } 2>&1 | tee -a tt${tt}__${i}.test; echo DONE $i; done