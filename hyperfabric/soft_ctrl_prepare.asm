##############################################
##############################################

  null;
  add $0x8000;
  sto $loop_marker;
  add 0+$trans_gb_0_origin;
  inl;

## 5 instructions

prepare_trans:
  add 0+$len_left;
  add 0+$0x0003;
  and $0xfffc;
  sto $len_left;

  null;
  add 0+$signal_bits;
  and $section_mask;
  or  $certain_01;
  sto $section_and_certain_01;

  null;
  add 0+$signal_bits;
  exp _location_of_careofint_bit;  # bit expand
  and $0x8000;  # mask for the location of IRQ
  or  $0x4000;  # mask for the location of ABORT
  sto $careof_interrupt_abort;

## 15 instructions

  null;
  add 0+$loop_marker;
  cmp/null (:prepare_trans -1);
  sto $loop_marker;
  add 0+$trans_gb_1_origin;

# 25

#### 46 instructions all together !!!!

nop;
nop;
