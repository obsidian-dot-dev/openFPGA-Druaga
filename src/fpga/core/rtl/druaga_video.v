/***********************************
    FPGA Druaga ( Video Part )

      Copyright (c) 2007 MiSTer-X

      Super Pacman Support
                (c) 2021 Jose Tejada, jotego

************************************/
module DRUAGA_VIDEO
(
	input				VCLKx8,
	input				VCLKx4,
	input				VCLK,

	input  [8:0]	PH,
	input  [8:0]	PV,
	input           flip_screen,

	output			PCLK,
	output [7:0]	POUT,
	output			VB,

	output [10:0]	VRAM_A,
	input	 [15:0]	VRAM_D,

	output [6:0]	SPRA_A,
	input	 [23:0]	SPRA_D,

	input	 [8:0]	SCROLL,


	input				ROMCL,	// Downloaded ROM image
	input  [16:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN,
   input  [ 2:0]  MODEL
);

parameter [2:0] SUPERPAC=3'd5;
parameter [2:0] GROBDA=3'd6;

wire [8:0] HPOS = PH-16;
wire [8:0] VPOS = PV;

wire  oHB = (PH>=290) & (PH<492);

assign VB = (PV==224);


wire [4:0]	PALT_A;
wire [7:0]	PALT_D;

wire [7:0]	CLT0_A;
wire [3:0]	CLT0_D;

wire [7:0]	BGCH_D;


//
// BG scroll registers
//
reg  [8:0] BGVSCR;
wire [8:0] BGVPOS = ({8{flip_screen}} ^ BGVSCR) + VPOS + (9'h121 & {9{flip_screen}});
always @(posedge oHB) BGVSCR <= SCROLL;


//----------------------------------------
//  BG scanline generator
//----------------------------------------
reg	 [7:0] BGPN;
reg	       BGH;

reg	 [5:0] COL, ROW;
wire	       ROW4 = {(VPOS[7:5] + flip_screen) >> 2} ^ flip_screen;

wire	 [7:0] CHRC = VRAM_D[7:0];
wire	 [5:0] BGPL = VRAM_D[13:8];

wire	 [8:0] HP    = HPOS ^ {8{flip_screen}};
wire	 [8:0] VP    = {COL[5] ? VPOS : BGVPOS} ^ {8{flip_screen}};
wire	[11:0] CHRA  = { CHRC, ~HP[2], VP[2:0] };
wire	 [7:0] CHRO  = BGCH_D;
reg     [10:0] VRAMADRS;

always @ ( posedge VCLK ) begin
	case ( HP[1:0] )
		2'b00: begin BGPN <= { BGPL, CHRO[7], CHRO[3] }; BGH <= VRAM_D[14]; end
		2'b01: begin BGPN <= { BGPL, CHRO[6], CHRO[2] }; BGH <= VRAM_D[14]; end
		2'b10: begin BGPN <= { BGPL, CHRO[5], CHRO[1] }; BGH <= VRAM_D[14]; end
		2'b11: begin BGPN <= { BGPL, CHRO[4], CHRO[0] }; BGH <= VRAM_D[14]; end
	endcase
end


assign CLT0_A = BGPN ^ ( (MODEL==SUPERPAC || MODEL==GROBDA) ? 8'h0 : 8'h03 );
assign VRAM_A = VRAMADRS & ( (MODEL==SUPERPAC || MODEL==GROBDA) ? 11'h3FF : 11'h7FF );

wire            BGHI  = BGH & (CLT0_D!=4'd15);
wire    [4:0]   BGCOL = { 1'b1, ((MODEL==SUPERPAC || MODEL==GROBDA) ? ~CLT0_D :CLT0_D) };

always @(*) begin
    // This +2 adjustment is due to using a linear video timing generator
    // rather than the original circuit count.
    ROW = (VPOS[8:3] + 6'h2) ^ {5{flip_screen}};
    COL  = HPOS[8:3] ^ {5{flip_screen}};

    if( MODEL==SUPERPAC  || MODEL==GROBDA ) begin
        VRAMADRS = { 1'b0,
                      COL[5] ? {COL[4:0], ROW[4:0]} :
                               {ROW[4:0], COL[4:0]}
                   };
    end else begin
        VRAMADRS = COL[5] ? { 4'b1111, COL[1:0], ROW4, ROW[3:0] } :
                                           { VP[8:3], HP[7:3] };
    end
end

//----------------------------------------
//  Sprite scanline generator
//----------------------------------------
wire	[4:0] SPCOL;
DRUAGA_SPRITE #(.SUPERPAC(SUPERPAC)) spr
(
	VCLKx8, VCLKx4, VCLK,
	HPOS+1, VPOS, oHB,
	SPRA_A, SPRA_D,
	SPCOL,

	ROMCL,ROMAD,ROMDT,ROMEN,
	MODEL,
	flip_screen
);


//----------------------------------------
//  Color mixer & Final output
//----------------------------------------
assign PALT_A = BGHI ? BGCOL : ((SPCOL[3:0]==4'd15) ? BGCOL : SPCOL );

assign POUT = oHB ? 0 : PALT_D;
assign PCLK = VCLK;


//----------------------------------------
//  ROMs
//----------------------------------------
DLROM #(12,8) bgchr(
			VCLKx8, CHRA, BGCH_D,
			// ROM download
			ROMCL,ROMAD[11:0],ROMDT[7:0],ROMEN & (ROMAD[16:12]=={1'b1,4'h2})
		);

DLROM #(8,4)  clut0(
			VCLKx8, CLT0_A, CLT0_D,
			// ROM download
			ROMCL,ROMAD[ 7:0],ROMDT[3:0],ROMEN & (ROMAD[16: 8]=={1'b1,8'h34})
		);

DLROM #(5,8)  palet(
			VCLK, PALT_A, PALT_D,
			// ROM download
			ROMCL,ROMAD[ 4:0],ROMDT[7:0],ROMEN & (ROMAD[16: 5]=={1'b1,8'h36,3'b000})
		);

endmodule

