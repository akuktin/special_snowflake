##############################################
space_left_in_page_not_enough:
  add 0+$space_left_in_page;
len_for_transfer_shorter_than_block_size:
  add 0+$len_for_transfer__less_block_size;
##############################################

main_algo:
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
  add 0+(INDEX+D($begin_addr_low -> $len_left));
  o_2;
  and $page_addr_submask;
  xor 0xffff;
  add 1+$page_size;
  sto $space_left_in_page;

  sub INDEX;
  and $0x8000;
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
  nop (INDEX+D($len_left -> $other_bits));

## 30 instructions

exec_transfer():
#  sto $transfer_size;
  or  INDEX;  # $other_bits; # approx
  o_3;

## 2 instructions


update_transfer():
  null;
  add 0+$index_store;
  inl; # index load
  i_1
  add 0+INDEX;
  sto (INDEX+D($begin_addr_low -> $begin_addr_high));
  null;
  add s+INDEX;
  sto (INDEX+D($begin_addr_high -> $len_left));
  i_1;
# the below instruction is the first one that can exist at or after
# the trg_gb_0 or trg_gb_1 signals
  xor 0xffff;
  add 1+INDEX;
  sto INDEX;

## 13 instructions

# padding
  nop;
  nop;
  nop;
