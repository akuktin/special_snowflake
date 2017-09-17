##############################################
##############################################

  null;
  add 0+$0x8000;
  add 0+$mb_flipflop_ctrl;
  stc $mb_flipflop_ctrl;

  add 0+$gb_0_active; # 5
  cmp/null :jump_over;

  add 0+$len_left_gb_0;
  add 0+$0x0003;
  and $0xfffc;
  stc $len_left_gb_0; # 10

  add 0+$signal_bits_gb_0;
  and $section_mask;
  or  $certain_01;
  stc $section_and_certain_01_gb_0;

  add 0+$signal_bits_gb_0;
  exp _location_of_careofint_bit;  # bit expand
  and $0x8000;  # mask for the location of IRQ
  or  $0x4000;  # mask for the location of ABORT
  sto $careof_interrupt_abort_gb_0;

## 19 instructions up to this point

  and $0x8000; # 20
  and $signal_bits_gb_0;
  stc $gb_0_active;

## 22 instructions

  add 0+$gb_1_active;
  cmp/null :jump_over;

  add 0+$len_left_gb_1;
  add 0+$0x0003;
  and $0xfffc;
  stc $len_left_gb_1;

  add 0+$signal_bits_gb_1;
  and $section_mask; # 30
  or  $certain_01;
  stc $section_and_certain_01_gb_1;

  add 0+$signal_bits_gb_1;
  exp _location_of_careofint_bit;
  and $0x8000;  # mask for the location of IRQ
  or  $0x4000;  # mask for the location of ABORT
  sto $careof_interrupt_abort_gb_1;

  and $0x8000;
  and $signal_bits_gb_1;
  sto $gb_1_active; # 40

## 40 instructions up to this point

nop;
nop;
nop;
nop;
nop;
nop;
nop;
nop;
