  null;
  add 1+$cur_trans;
  inl;

  i_1;  # ?  # the point is to increment the start address;
  add 0+$start_addr_low;
  sto INDEX; # -> start_addr_low
  null;
  add s+$start_addr_high
  sto INDEX; # -> start_addr_high
  i_1;  # ?
  xor 0xffff
  add 1+$len_left_low;
  sto INDEX;
  ones;
  add s+$len_left_high;
  sto INDEX;

## 16 instructions

  null;
  add 0+$cur_trans
  sub $max_trans;
  cmp/ones :dont_reset_trans_counter;
  cmp/null :carry_on;
  add 0+$0x4;
  nop;
carry_on:
  sto $cur_trans;

  inl; # index load
  null;
  add 0+INDEX;
  sto $begin_addr_low;
  o_2;  # make sure the timing is ok
  null;
  add 0+INDEX;
  sto $begin_addr_high;
  o_1;  # make sure the timing is ok
  null;
  add 0+INDEX;
  sto $len_left_low;
  null;
  add 0+INDEX;
  sto $len_left_high;

## 23 instructions;

##############################################
dont_reset_trans_counter:
  add 0+$cur_trans;
space_left_in_page_not_enough:
  add 0+$space_left_in_page;
len_for_transfer_shorter_than_block_size:
  add 0+$len_for_transfer__less_block_size;
##############################################


  null;
  add 0+$begin_addr_low;
  and $page_addr_submask;
  xor 0xffff;
  add 1+$page_size;
  sto $space_left_in_page;

  sub $len_left_low;
  and $0x8000;
  or  $len_left_high; # acc != 0 => len_left > space_left_in_page

  cmp/ones :space_left_in_page_not_enough;
  cmp/null :continue_0;
  sub $block_size;
  add 0+$len_left_low;
continue_0:
  sto $len_for_transfer__less_block_size;
  and $0x8000;

  cmp/ones :len_for_transfer_shorter_than_block_size;
  cmp/null :exec_transfer();
  add 0+$block_size;
  nop;

## 20 instructions

exec_transfer():
#  sto $transfer_size;
  or  $other_bits; # approx
  sto $prepared_output;

#######
wait_funcion():
  time;
  add 0+$next_trans_time;

wait_loop:
  cmp/nop :wait_loop;
  dec;
  nop;
#######

  null;
  add 0+$prepared_output;
  o_3;  # THIS PHYSICALLY EXECUTES THE TRANSFER!!!

## 10 instructions


update_transfer():
  null;
  add 0+_transfered;
  add 0+begin_addr_low;
  sto $begin_addr_low;
  null;
  add s+begin_addr_high;
  sto $begin_addr_high;
  null;
  add 0+$len_left_low;
  sub _transfered;
  sto $len_left_low;
  ones;
  add s+$len_left_high;
  sto $len_left_high;

## 14 instructions