##############################################
space_left_in_page_not_enough:
  add 0+$space_left_in_page;
len_for_transfer_shorter_than_block_size:
  add 0+$len_for_transfer__less_block_size;
care_of_irq:
  add $0xc000;  # mask for both IRQ and ABORT
##############################################

grab_meta_gb_0:
  lod $gb_0_active; # 1
  cmp/nop :continue_grab_meta_gb_0;

  i_1_gb;
  add 0+$gb_0_begin_addr_low;

# not part of main execution
  lod $distance_gb_0__exec_gb_1;  # 5
  wait :exec_gb_1; # 6 # wait 15 cycles
# not part of main execution

check_irq_in_gb_0:
  and $gb_0_careof_int_abt; # 15
  cmp/nop :signal_irq_gb_0;  # OH THE PAIN!!!
  or  $gb_0_irq_desc_and_certain_01;
  cmp/nop :exec_gb_1;
  null;
  nop; # 20

continue_grab_meta_gb_0:
  stc $gb_0_begin_addr_low; # 5 # swap w/ 0x0000
  add s+$gb_0_begin_addr_high;
  sto $gb_0_begin_addr_high;
  i_1_gb;
  xor 0xffff;
  add 1+$gb_0_len_left; # 10
  sto $gb_0_len_left;

  cmp/i_2_gb :check_irq_in_gb_0;
  or  $gb_0_irq_desc_and_certain_01;
  nop; # 14

signal_irq_gb_0:
  irq; # nulls
  sto $gb_0_active;

  wait (:+1 instruction); # 17 # wait 4 cycles

# jump into execution of gb_1

## longest to enter gb_1: 21 instructions

exec_gb_1:
  add 0+$gb_1_active; # 21
  cmp/null :continue_gb_1__0;
  add 0+$gb_1_begin_addr_high;
  o_1_gb;

# not part of main execution
  lod $distance_gb_01__mb; # 25
  wait :check_if_exec_mb; # 26 # wait 20 cycles
# not part of main execution

continue_gb_1__0:
  lod $gb_1_begin_addr_low; # 25
  o_2_gb;
  and $page_addr_submask;
  xor 0xffff;
  add 1+$page_size;
  sto $space_left_in_page; # 30

  sub $gb_1_len_left;
  or  0xffff;
  add s+0; # meant to detect a negative number, meaning more len than space

  cmp/ones :space_left_in_page_not_enough;
  cmp/null :continue_gb_1__1; # 35
  sub $block_size;
  add 0+$gb_1_len_left;
continue_gb_1__1:
  stf $len_for_transfer__less_block_size; # swap w/ 0xffff
  add s+0;

  cmp/ones :len_for_transfer_shorter_than_block_size; # 40
  cmp/null :exec_transfer_gb_1;
  add 0+$block_size;
  nop;

## 43 to reach this point

exec_transfer_gb_1:
  or $other_bits_gb_1;
  o_3_gb; # 45 # nulls

## 45 instructions

#####################

check_if_exec_mb:
  add 0+$mb_flipflop_ctrl; # 46
  cmp/null :prepare_mb_trans; # test if we execute or prepare mb trans
  nop;  # <-- this one slows by one cycle compared w/ before proving

#####################

  # index is prealoaded with $mb_active
  add 0+(INDEX+D($mb_active -> $mb_begin_addr_low)); # 49
  cmp/nop :continue_grab_meta_mb; # 50

  i_1_mb;
  add 0+INDEX;

# not part of main execution
  lod $distance_gb_01__mb; # 53
  wait :exec_mb_other; # 54 # wait 15 cycles
# not part of main execution

check_irq_in_mb:
  and (INDEX+D($mb_careof_int_abt -> $mb_irq_desc_and_certain_01)); # 63
  cmp/nop :signal_irq_mb; # much, much less pain now, all of a sudden :)
  or  (INDEX+D($mb_irq_desc_and_certain_01 -> $mb_careof_int_abt)); # 65
  cmp/nop :exec_mb_other;
  null;
  nop;

continue_grab_meta_mb:
  stc (INDEX+D($mb_begin_addr_low -> $mb_begin_addr_high)); # 53
  add s+INDEX;
  sto (INDEX+D($mb_begin_addr_high -> $mb_len_left)); # 55
  i_1_mb;
  xor 0xffff;
  add 1+INDEX;
  sto (INDEX+D($mb_len_left -> $mb_irq_desc_and_certain_01));

  cmp/i_2_mb :check_irq_in_mb; # 60
  or  (INDEX+D($mb_irq_desc_and_certain_01 -> $mb_careof_int_abt));
  nop;

signal_irq_mb:
  irq (INDEX+D($mb_careof_int_abt -> $mb_active));
  sto INDEX;

  wait (:+1 instruction); # 65 # wait 4 cycles

## 68 to this point

exec_mb_other:
  # at this point, the accumulator is guarrantied to be nulled.
  # swichover the index
  add 0+$next_index; # 69
  inl; # 70 71 72

  add 0+(INDEX+D($mb_active -> $mb_begin_addr_high)); # 73
  cmp/null :continue_mb__0;
  add 0+(INDEX+D($mb_begin_addr_high -> $mb_begin_addr_low));
  o_1_mb; # 76

# not part of main execution
  lod $distance_gb_01__mb; # 77
  wait :grab_meta_gb_1; # 78 # wait 20 cycles
# not part of main execution

continue_mb__0:
  lod (INDEX+D($mb_begin_addr_low -> $mb_len_left)); # 77
  o_2_mb;
  and $page_addr_submask;
  xor 0xffff; # 80
  add 1+$page_size;
  sto $space_left_in_page;

  sub INDEX;
  or  0xffff;
  add s+0; # 85

  cmp/ones :space_left_in_page_not_enough;
  cmp/null :continue_mb__1;
  sub $block_size;
  add 0+INDEX;
continue_mb__1:
  stf $len_for_transfer__less_block_size; # 90
  add s+0 INDEX+D($mb_len_left -> $mb_other_bits);

  cmp/ones :len_for_transfer_shorter_than_block_size;
  cmp/null :exec_transfer_mb;
  add 0+$block_size;
  nop; # 95

## 93 to reach this point

exec_transfer_mb:
  or  (INDEX+D($mb_other_bits -> $mb_active)); # which mb_active? # your own
  o_3_mb; # 97 # nulls

## 97 instructions

grab_meta_gb_1:
  lod $gb_1_active; # 98
  cmp/nop :continue_grab_meta_gb_1;

  i_1_gb; # 100
  add 0+$gb_1_begin_addr_low; # 101

# not part of main execution
  lod $distance_gb_01__mb; # 102
  wait :exec_gb_0; # 103 # wait 15 cycles
# not part of main execution

check_irq_in_gb_1:
  and $gb_1_careof_int_abt; # 112
  cmp/nop :signal_irq_gb_1; # OH THE PAIN!!!! (not really :) )
  or  $gb_1_irq_desc_and_certain_01;
  cmp/nop :exec_gb_0; # 115
  null;
  nop;

continue_grab_meta_gb_1:
  stc $gb_1_begin_addr_low; # 102
  add s+$gb_1_begin_addr_high;
  sto $gb_1_begin_addr_high;
  i_1_gb; # 105
  xor 0xffff;
  add 1+$gb_1_len_left;
  sto $gb_1_len_left;

  cmp/i_2_gb :check_irq_in_gb_1;
  or  $gb_1_irq_desc_and_certain_01; # 110
  nop; # 111

signal_irq_gb_1:
  irq;
  sto $gb_1_active;

  wait (:+1 instruction); # 114 # wait 4 cycles

exec_gb_0:
  add 0+$gb_0_active; # 118
  cmp/null :continue_gb_0__0;
  add 0+$gb_0_begin_addr_high; # 120
  o_1_gb; # 121

# not part of main execution
  lod $distance_gb_01__mb; # 122
  wait :prepare_mb_flipflop; # 123 # wait 20 cycles
# not part of main execution

continue_gb_0__0:
  lod $gb_0_begin_addr_low; # 122
  o_2_gb;
  and $page_addr_submask;
  xor 0xffff; # 125
  add 1+$page_size;
  sto $space_left_in_page;

  sub $gb_0_len_left;
  or  0xffff;
  add s+0; # 130

  cmp/ones :space_left_in_page_not_enough;
  cmp/null :continue_gb_0__1;
  sub $block_size;
  add 0+$gb_0_len_left;
continue_gb_0__1:
  sto $len_for_transfer__less_block_size; # 135
  add s+0;

  cmp/ones :len_for_transfer_shorter_than_block_size;
  cmp/null :exec_transfer_gb_0;
  add 0+$block_size;
  nop; # 140

exec_transfer_gb_0:
  or $other_bits_gb_0;
  o_3_gb; # 142 # nulls

## 140 instructions

prepare_mb_flipflop:
  add 0+$0x8000; # 143
  add 0+$mb_flipflop_ctrl;
  stc $mb_flipflop_ctrl; # 145

prepare_gb_0:
  add 0+$gb_0_active;
  xor $0x8000;
  cmp/null :jump_over_prepare_gb_0;

  add 0+$signal_bits_gb_0;
  and $0x8000; # 150

# not part of main execution
  lod $distance_gb_01__mb; # 151
  wait :prepare_gb_1; # 152 # wait 15 cycles
# not part of main execution

jump_over_prepare_gb_0:
  stc $gb_0_active; # 151

  add 0+$len_left_gb_0;
  add 0+$0x0003;
  and $0x7ffc;
  stc $len_left_gb_0; # 155

  add 0+$signal_bits_gb_0;
  and $section_mask;
  or  $certain_01;
  stc $section_and_certain_01_gb_0; # AKA $gb_0_irq_desc_and_cerain_01

  add 0+$signal_bits_gb_0; # 160
  and $location_of_careofint_bit;
  cmp/ones :care_of_irq;
  cmp/nop :write_careof_int_gb_0;
  null;
  add $0x4000; # 165 # mask for only ABORT
write_careof_int_gb_0:
  stc $careof_interrupt_abort_gb_0; # AKA $gb_0_careof_int_abt


prepare_gb_1:
  add 0+$gb_1_active; # 167
  xor $0x8000;
  cmp/null :jump_over_prepare_gb_1;

  add 0+$signal_bits_gb_1; $ 170
  and $0x8000; # 171

# not part of main execution
  lod $distance_gb_01__mb; # 172
  wait :balancing_wait; # 173 # wait 15 cycles
# not part of main execution

jump_over_prepare_gb_1:
  stc $gb_1_active; # 172

  add 0+$len_left_gb_1;
  add 0+$0x0003;
  and $0x7ffc; # 175
  stc $len_left_gb_1;

  add 0+$signal_bits_gb_1;
  and $section_mask;
  or  $certain_01;
  stc $section_and_certain_01_gb_1; # 180 # AKA $gb_1_irq_desc_and_cerain_01

  add 0+$signal_bits_gb_1;
  and $location_of_careofint_bit;
  cmp/ones :care_of_irq;
  cmp/nop :write_careof_int_gb_1;
  null; # 185
  add $0x4000;  # mask for only ABORT
write_careof_int_gb_1:
  stc $careof_interrupt_abort_gb_1; # 187 # AKA $gb_1_careof_int_abt

balancing_wait:
  wait :grab_meta_gb_0; # 188 # wait 4 cycles

# NOTICE!
# The first cycle of the following small carousel is cycle no. 0xc1 because
# the cycles in this code are counted using a scale starting with 1 (not 0)


# needs to complete its job in 46 cycles max
prepare_mb_trans:
  null; # 50 in the main thread # origin of counting # /1
  add 1+$cur_mb_trans_ptr;
  and $cur_mb_trans_ptr_mask;
  sto $cur_mb_trans_ptr;
  inl; # 54/5 55 56
  add 0+INDEX; # 57
  inl; # 58 59/10 60 # loaded with $mb_active

  add 0+(INDEX+D($mb_active -> $signal_bits));
  xor $0x8000;
  cmp/null :jump_over_prepare_mb;
  add 0+(INDEX+D($signal_bits -> $mb_active)); # /15
  and $0x8000; # 65/16

# not part of main execution
  lod $distance_gb_01__mb; # 66/17
  wait :mb_step_indices; # 67/18 # wait 15 cycles
# not part of main execution

jump_over_prepare_mb:
  stc (INDEX+D($mb_active -> $len_left)); # 66/17

  add 0+INDEX;
  add 0+$0x0003;
  and $0x7ffc; # /20
  stc (INDEX+D($len_left -> $signal_bits)); # 70

  add 0+(INDEX+D($signal_bits -> $mb_irq_desc_and_certain_01));
  and $section_mask;
  or  $certain_01;
  stc (INDEX+D($mb_irq_desc_and_certain_01 -> $signal_bits)); # /25

  add 0+(INDEX+D($signal_bits -> $mb_careof_int_abt)); # 75
  and $location_of_careofint_bit;
  cmp/ones :care_of_irq;
  cmp/nop :write_careof_int_mb;
  null; # /30
  add $0x4000; # 80
write_careof_int_mb:
  stc INDEX;

mb_step_indices:
  # step the transaction pointer
  add 0+$cur_mb_trans_ptr; # 82
  inl; # 83 84/35 85
  add 0+INDEX; # 86
  swp $next_index; # 87 # a proper swap
  inl; # 88 89/40 90

# 31 instructions since origin

waitout_untill_gb:
  lod $delay_for_prepare_mb; # 91
  wait :grab_meta_gb_1; # 92/43 # wait 6 cycles
