#!/bin/bash
tt=00;
ser=00;
for i in a b c d e f; do
  sed -i "s/\(CHANGER 8'h5\)./\1${i}/" test_tt_${tt}.v;
  { iverilog test_special_snowflake_core2.v && vvp a.out;
    rm a.out; } 2>&1 | tee -a tt${tt}__${i}.${ser}.log;
done
exit 0
for i in 84 83 82 81 80 7f 7e 7d 7c 7b 7a 79 78 77; do
  sed -i "s/\(CHANGER 8'h\)../\1${i}/" test_tt_${tt}.v;
  { iverilog test_special_snowflake_core2.v && vvp a.out;
    rm a.out; } 2>&1 | tee -a tt${tt}__${i}.${ser}.log;
done
exit 0
