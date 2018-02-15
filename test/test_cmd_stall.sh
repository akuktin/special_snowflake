#!/bin/bash
tt=interrupt_stall;
ser=00;
for i in 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18
         19 1a 1b 1c 1d 1e 1f 20 21 22 23 24 25; do
  sed -i "s/\(CHANGER 64'h\)../\1${i}/" test_${tt}.bin;
  { iverilog test_special_snowflake_core2.v && vvp a.out;
    rm a.out; } 2>&1 | tee -a tt${tt}__${i}.${ser}.log;
done
