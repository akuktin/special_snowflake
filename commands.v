`ifdef COMMANDS_V
`else
`define COMMANDS_V 1'b1

/* RASn, CASn, WEn */
`define NOOP 3'b111 /* no operation */
`define ACTV 3'b011 /* activate (row open) */
`define READ 3'b101 /* read */
`define WRTE 3'b100 /* write */
`define BTRM 3'b110 /* burst terminate */
`define PRCH 3'b010 /* precharge (row close) */
`define ARSR 3'b001 /* auto refresh/self refresh */
`define MRST 3'b000 /* mode register set */

`endif
