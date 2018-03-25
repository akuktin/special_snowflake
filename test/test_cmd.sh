#!/bin/bash
tt=00;
ser=02;
for i in 48 49 4a 4b 4c 4d 4e 4f 50 51 52 53 54 55 56 57 58 59 5a 5b 5c 5d 5e 5f 60 61 62 63 64 65 66 67 68 69 6a 6b 6c 6d 6e 6f 70 71 72 73 74 75 76 77; do
  sed -i "s/\(CHANGER 8'h\)../\1${i}/" test_tt_${tt}.v;
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
