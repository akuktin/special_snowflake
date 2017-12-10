rsub r0, r0, r0
rsub r0, r0, r0
rsub r0, r0, r0

xori r1, r0, 0xffff
add  r2, r1, r1
xori r3, r2, 0xffff
xori r4, r0, 0x0000
xori r5, r0, 0x0000

rsub r0, r0, r0
beqi 0,  r0, 0x8   # eq e
xori r4, r4, 0x0001
beqi 5,  r0, 0x8   # ge e
xori r4, r4, 0x0002
beqi 5,  r3, 0x8   # ge g
xori r4, r4, 0x0004
beqi 3,  r0, 0x8   # le e
xori r4, r4, 0x0008
beqi 3,  r1, 0x8   # le l
xori r4, r4, 0x0010
beqi 4,  r3, 0x8   # gt g
xori r4, r4, 0x0020
beqi 2,  r2, 0x8   # lt l
xori r4, r4, 0x0040
beqi 1,  r1, 0x8   # ne n
xori r4, r4, 0x0080

rsub r0, r0, r0
rsub r0, r0, r0
rsub r0, r0, r0
rsub r0, r0, r0

beqi 0,  r1, 0x8   # eq n
bri  r0,  0, 0x8
xori r5, r5, 0x0001
beqi 5,  r1, 0x8   # ge l
bri  r0,  0, 0x8
xori r5, r5, 0x0002
beqi 3,  r3, 0x8   # le g
bri  r0,  0, 0x8
xori r5, r5, 0x0004
beqi 4,  r1, 0x8   # gt l
bri  r0,  0, 0x8
xori r5, r5, 0x0008
beqi 4,  r0, 0x8   # gt e
bri  r0,  0, 0x8
xori r5, r5, 0x0010
beqi 2,  r3, 0x8   # lt g
bri  r0,  0, 0x8
xori r5, r5, 0x0020
beqi 2,  r0, 0x8   # lt e
bri  r0,  0, 0x8
xori r5, r5, 0x0040
beqi 1,  r0, 0x8   # ne e
bri  r0,  0, 0x8
xori r5, r5, 0x0080

rsub r0, r0, r0
rsub r0, r0, r0
rsub r0, r0, r0
rsub r0, r0, r0
rsub r0, r0, r0

rsub r31, r31, r31
rsub r31, r31, r31
rsub r31, r31, r31
