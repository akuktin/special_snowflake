##############################################
space_left_in_page_not_enough:
  add 0+$space_left_in_page;
len_for_transfer_shorter_than_block_size:
  add 0+$len_for_transfer__less_block_size;
##############################################

  null;
  add 0+$index_store;
  add 0+$index_increment;
  and $index_mask;
  sto $index_store;

  add 0+$D__begin_addr_low__begin_addr_high;
  inl; # index load
  null;
  add 0+(INDEX+D($begin_addr_high -> $begin_addr_low));
  o_1;

  null;
  add 0+(INDEX+D($begin_addr_low -> $len_left_low));
  o_2;
  and $page_addr_submask;
  xor 0xffff;
  add 1+$page_size;
  sto $space_left_in_page;

  sub (INDEX+D($len_left_low -> $len_left_high));
  and $0x8000;
  or  (INDEX+D($len_left_high -> $len_left_low));
       # (acc != 0) => (len_left > space_left_in_page)

  cmp/ones :space_left_in_page_not_enough;
  cmp/null :continue_0;
  sub $block_size;
  add 0+INDEX;
continue_0:
  sto $len_for_transfer__less_block_size;
  and $0x8000;

  cmp/ones :len_for_transfer_shorter_than_block_size;
  cmp/null :exec_transfer();
  add 0+$block_size;
  nop;

## 30 instructions

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
  add 0+$index_store;
  inl; # index load
  i_1
  add 0+INDEX;
  sto (INDEX+D($begin_addr_low -> $begin_addr_high));
  null;
  add s+INDEX;
  sto (INDEX+D($begin_addr_high -> $len_left_low));
  i_1;
  xor 0xffff;
  add 1+INDEX;
  sto (INDEX+D($len_left_low -> $len_left_high));
  ones;
  add s+INDEX
  sto INDEX;

## 16 instructions