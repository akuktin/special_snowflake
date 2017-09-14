##############################################
space_left_in_page_not_enough:
  add 0+$space_left_in_page;
len_for_transfer_shorter_than_block_size:
  add 0+$len_for_transfer__less_block_size;
signal_irq:
  irq;
  and $index_ptr_mask;
##############################################

main_algo:
## padding
  nop; # padding
## padding
  null;
  add 1+$index_ptr_store;
  and $index_ptr_mask;
  sto $index_ptr_store;

  cmp/inl :(+3 instructions);
  add 0+INDEX;

  cmp/nop :exit_from_main_algo;

  inl; # index load

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
  and 0;
  add s+0;
  # (acc != 0) => (len_left > space_left_in_page)

  cmp/ones :space_left_in_page_not_enough;
  cmp/null :continue_0;
  sub $block_size;
  add 0+INDEX;
continue_0:
  sto $len_for_transfer__less_block_size;
  and $0x8000; # magically right :)

  cmp/ones :len_for_transfer_shorter_than_block_size;
  cmp/null :exec_transfer();
  add 0+$block_size;
  nop;
  nop (INDEX+D($len_left -> $other_bits));

## 32 instructions

exec_transfer():
#  sto $transfer_size;
  or  (INDEX+D($other_bits -> $begin_addr_low));  # $other_bits; # approx
  o_3;

## 2 instructions


update_transfer():
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
  sto (INDEX+D($len_left -> $care_about_interrupt)); # needed for section

## 10 instructions

# NOT GOOD ENOUGH! -> $len_left == 0, no interrupt or don't care about them

  cmp/i_2 :main_algo;
  and (INDEX+D($care_about_interrupt -> $other_bits));
  cmp/or INDEX :signal_irq; # for the section
# ----

  add 1+$index_ptr_store; # works fine, they live in different bits
  cmp/nop (:main_algo +4);
  nop;
  and $index_ptr_mask;

## 7 instructions
