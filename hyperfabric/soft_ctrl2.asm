##############################################
space_left_in_page_not_enough:
  add 0+$space_left_in_page;
len_for_transfer_shorter_than_block_size:
  add 0+$len_for_transfer__less_block_size;
care_of_irq:
  add $0xc000;  # mask for both IRQ and ABORT
##############################################

grab_meta_gb_0:
  lod $gb_0_active;
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
  or  $gb_0_irq_des_and_certain_01;
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
  nop;
  add 0+$block_size;

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
  inl; # 70

  add 0+(INDEX+D($mb_active -> $mb_begin_addr_high)); # 71
  cmp/null :continue_mb__0;
  add 0+(INDEX+D($mb_begin_addr_high -> $mb_begin_addr_low));
  o_1_mb; # 74

# not part of main execution
  lod $distance_gb_01__mb; # 75
  wait :grab_meta_gb_1 # 76 # wait 20 cycles
# not part of main execution

continue_mb__0:
  lod (INDEX+D($mb_begin_addr_low -> $mb_len_left)); # 75
  o_2_mb;
  and $page_addr_submask;
  xor 0xffff;
  add 1+$page_size;
  sto $space_left_in_page; # 80

  sub INDEX;
  or  0xffff
  add s+0; # meant to detect a negative number, meaning more len than space

  cmp/ones :space_left_in_page_not_enough;
  cmp/null :continue_mb__1; # 85
  sub $block_size;
  add 0+INDEX;
continue_mb__1:
  stf $len_for_transfer__less_block_size;
  add s+0;

  cmp/ones :len_for_transfer_shorter_than_block_size; # 90
  cmp/null :exec_transfer_mb;
  nop (INDEX+D($mb_len_left -> $mb_other_bits));
  add 0+$block_size;

## 93 to reach this point

exec_transfer_mb:
  or  (INDEX+D($mb_other_bits -> $mb_active)); # which mb_active?
  o_3_mb; # 95 # nulls

## 95 instructions

grab_meta_gb_1:
  lod $gb_1_active; # 96
  cmp/nop :continue_grab_meta_gb_1;

  i_1_gb;
  add 0+$gb_1_begin_addr_low;

# not part of main execution
  lod $distance_gb_01__mb; # 100
  wait :exec_gb_0; # 101 # wait 15 cycles
# not part of main execution

check_irq_in_gb_1:
  and $gb_1_careof_int_abt; # 110
  cmp/nop :signal_irq_gb_1; # OH THE PAIN!!!! (not really :) )
  or  $gb_1_irq_desc_and_certain_01;
  cmp/nop :exec_gb_0;
  null;
  nop; # 115

continue_grab_meta_gb_1:
  stc $gb_1_begin_addr_low; # 100
  add s+$gb_1_begin_addr_high;
  sto $gb_1_begin_addr_high;
  i_1_gb;
  xor 0xffff;
  add 1+$gb_1_len_left; # 105
  sto $gb_1_len_left;

  cmp/i_2_gb :check_irq_in_gb_1;
  or  $gb_1_irq_desc_and_certain_01;
  nop; # 109

signal_irq_gb_1:
  irq;
  sto $gb_1_active;

  wait (:+1 instruction); # 112 # wait 4 cycles

exec_gb_0:
  add 0+$gb_0_active; # 116
  cmp/null :continue_gb_0__0;
  add 0+$gb_0_begin_addr_high;
  o_1_gb; # 119

# not part of main execution
  lod $distance_gb_01__mb; # 120
  wait :prepare_general; # 121 # wait 20 cycles
# not part of main execution

continue_gb_0__0:
  lod $gb_0_begin_addr_low; # 120
  o_2_gb;
  and $page_addr_submask;
  xor 0xffff;
  and 1+$page_size;
  sto $space_left_in_page; # 125

  sub $gb_0_len_left;
  or  0xffff;
  add s+0; # 128

  cmp/ones :space_left_in_page_not_enough;
  cmp/null :continue_gb_0__1; # 130
  sub $block_size;
  add 0+$gb_0_len_left;
continue_gb_0__1:
  sto $len_for_transfer__less_block_size;
  add s+0;

  cmp/ones :len_for_transfer_shorter_than_block_size; # 135
  cmp/null :exec_transfer_gb_0;
  nop;
  add 0+$block_size;

exec_transfer_gb_0:
  or $other_bits_gb_0;
  o_3_gb; # 140 # nulls

## 140 instructions

prepare_general:
  add 0+$0x8000; # 141
  add 0+$mb_flipflop_ctrl;
  stc $mb_flipflop_ctrl;

  add 0+$gb_0_active;
  cmp/null :jump_over_prepare_gb_0; # 150

  add 0+$signal_bits_gb_0;
  and $0x8000;

# not part of main execution
  lod $distance_gb_01__mb;
  wait :check_if_exec_mb;
# not part of main execution

jump_over_prepare_gb_0:
  stc $gb_0_active;

  add 0+$len_left_gb_0;
  add 0+$0x0003;
  and $0xfffc;
  stc $len_left_gb_0;

  add 0+$signal_bits_gb_0;
  and $section_mask;
  or  $certain_01; # 160
  stc $section_and_certain_01_gb_0;

  add 0+$signal_bits_gb_0;
  and $location_of_careofint_bit;
  cmp/ones :care_of_irq;
  cmp/nop (:+2 instructions);
  null;
  add $0x4000;  # mask for only ABORT
  stc $careof_interrupt_abort_gb_0;


  add 0+$gb_1_active;
  cmp/null :jump_over_prepare_gb_1; # 170

  add 0+$signal_bits_gb_1;
  and $0x8000;

# not part of main execution
  lod $distance_gb_01__mb;
  wait :check_if_exec_mb;
# not part of main execution

jump_over_prepare_gb_1:
  stc $gb_1_active;

  add 0+$len_left_gb_1;
  add 0+$0x0003;
  and $0xfffc;
  stc $len_left_gb_1;

  add 0+$signal_bits_gb_1;
  and $section_mask;
  or  $certain_01; # 180
  stc $section_and_certain_01_gb_1;

  add 0+$signal_bits_gb_1;
  and $location_of_careofint_bit;
  cmp/ones :care_of_irq;
  cmp/nop (:+2 instructions);
  null;
  add $0x4000;  # mask for only ABORT
  stc $careof_interrupt_abort_gb_1;

## 188 instructions up to this point

  lod $balancing_wait_cycles;
  wait :grab_meta_gb_0;


prepare_mb:
  null; # 50 in the main thread # origin of counting # 1
  add 1+$cur_mb_trans_ptr;
  and $cur_mb_trans_ptr_mask;
  sto $cur_mb_trans_ptr;
  inl;
  add 0+INDEX;
  inl;  # loaded with $mb_active

  add 0+(INDEX+D($mb_active -> $signal_bits));
  cmp/null :jump_over_prepare_mb;
  add 0+(INDEX+D($len_left -> $mb_active)); # 10
  and $0x8000;

# not part of main execution
  lod $distance_gb_01__mb;
  wait :check_if_exec_mb;
# not part of main execution

jump_over_prepare_mb:
  stc (INDEX+D($mb_active -> $len_left));

  add 0+INDEX;
  add 0+$0x0003;
  and $0xfffc;
  stc (INDEX+D($len_left -> $signal_bits));

  add 0+(INDEX+D($signal_bits -> $mb_irq_desc_and_certain_01));
  and $section_mask;
  or  $certain_01;
  stc (INDEX+D($mb_irq_desc_and_certain_01 -> $signal_bits)); # 20

  add 0+(INDEX+D($signal_bits -> $mb_careof_int_abt));
  and $location_of_careofint_bit;
  cmp/ones :care_of_irq;
  cmp/nop (:+2 instructions);
  null;
  add $0x4000;
  stc INDEX;

  add 0+$cur_mb_trans_ptr;
  sto $next_index;
  sub 1; # 30
  inl;

# 31 instructions since origin

  lod $delay_for_prepare_mb;
  wait :grab_meta_gb_1;
