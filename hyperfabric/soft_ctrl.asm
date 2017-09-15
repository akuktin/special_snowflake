##############################################
space_left_in_page_not_enough:
  add 0+$space_left_in_page;
len_for_transfer_shorter_than_block_size:
  add 0+$len_for_transfer__less_block_size;
##############################################

main_algo:
  null;
  add 1+$index_ptr_store;
  nop;
  sto $index_ptr_store;
  inl;  # index load
  add 0+INDEX;
  cmp/inl (:+5 instructions);

  add 0+(INDEX+D($begin_addr_high -> $begin_addr_low));
  o_1;

# not part of main loop
  ones;
  cmp/nop :exit_from_main_algo;
# not part of main loop

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

## 30 instructions

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
  sto (INDEX+D($len_left -> $section_and_certain_01));

## 10 instructions

  cmp/i_2 :check_irq_in;
  or  INDEX; # sets section
# save the irq/abort bits
  sto (INDEX+D($section_and_certain_01 -> $careof_interrupt_abort));
  irq;
  cmp/null (:main_algo +2);
# ----
  add 1+$index_ptr_store;
  nop;

check_irq_in:
  and (INDEX+D($careof_interrupt_abort -> $section_and_certain_01));
  cmp/or INDEX :signal_irq;
# ----
  cmp/nop (:main_algo +3);
  add 1+$index_ptr_store;
  nop;
signal_irq:
  irq;

## the rest of the way to 48 instructions
