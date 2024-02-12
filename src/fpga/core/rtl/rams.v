/***************************************
	FPGA Druaga ( Dualport RAM modules )

			Copyright (c) 2007 MiSTer-X
****************************************/
module DPRAM_2048( CL0, ADRS0, IN0, OUT0, WR0, CL1, ADRS1, IN1, OUT1, WR1 );

input 			CL0;
input	  [10:0]	ADRS0;	
input	   [7:0]	IN0;
output	[7:0]	OUT0;
input				WR0;

input 			CL1;
input	  [10:0]	ADRS1;	
input		[7:0]	IN1;
output	[7:0]	OUT1;
input				WR1;

DPRAM2K_8 ramcore
(
	ADRS0,ADRS1,
	CL0,CL1,
	IN0,IN1,
	WR0,WR1,
	OUT0,OUT1
);

endmodule


module DPRAM_2048V( CL0, ADRS0, IN0, OUT0, WR0, CL1, ADRS1, OUT1 );

input 			CL0;
input	  [10:0]	ADRS0;	
input	   [7:0]	IN0;
output	[7:0]	OUT0;
input				WR0;

input 			CL1;
input	  [10:0]	ADRS1;	
output   [7:0]	OUT1;

DPRAM2K_8 ramcore
(
	ADRS0,ADRS1,
	CL0,CL1,
	IN0,8'h0,
	WR0,1'b0,
	OUT0,OUT1
);

endmodule


module LBUF512
(
	input				CLKW,
	input				WEN,
	input		[8:0]	ADRSW,
	input		[3:0]	IN,
	input				CLKR,
	input				REN,
	input		[8:0]	ADRSR,
	output   [3:0]	OUT
);

DPRAM512_4 ramcore
(
	IN,
	CLKW,
	CLKR,
	ADRSR,
	REN,
	ADRSW,
	WEN,
	OUT
);

	
endmodule


module DLROM #(parameter AW,parameter DW)
(
	input							CL0,
	input [(AW-1):0]			AD0,
	output reg [(DW-1):0]	DO0,

	input							CL1,
	input [(AW-1):0]			AD1,
	input	[(DW-1):0]			DI1,
	input							WE1
);

reg [DW:0] core[0:((2**AW)-1)];

always @(posedge CL0) DO0 <= core[AD0];
always @(posedge CL1) if (WE1) core[AD1] <= DI1;

endmodule
