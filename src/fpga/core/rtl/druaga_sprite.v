/***********************************
    FPGA Druaga ( Sprite Part )

      Copyright (c) 2007 MiSTer-X

      Super Pacman Support
                (c) 2021 Jose Tejada, jotego

************************************/
module DRUAGA_SPRITE
(
	input				VCLKx8,
	input				VCLKx4,
	input				VCLK,

	input [8:0]		HPOS,
	input [8:0] 	VPOS,
	input				oHB,

	output [6:0]	SPRA_A,
	input	 [23:0]	SPRA_D,

	output [4:0]	SPCOL,


	input				ROMCL,	// Downloaded ROM image
	input  [16:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN,
   input   [2:0]  MODEL,
   input          flip_screen
);

parameter [2:0] SUPERPAC=3'd5;
parameter [2:0] GROBDA=3'd6;

reg  [9:0]	CLT1_A;
wire [3:0]	CLT1_D;
DLROM #(10,4) clut1( VCLKx8, CLT1_A, CLT1_D, ROMCL,ROMAD[9:0],ROMDT[3:0],ROMEN & (ROMAD[16:10]=={1'b1,4'h3,2'b00}));

wire [13:0]	SPCH_A;
wire [15:0]	SPCH_D;
DLROM #(14,8) spch0( VCLKx8, SPCH_A, SPCH_D[15:8], ROMCL,ROMAD[13:0],ROMDT,ROMEN & (ROMAD[16:14]==3'b010));
DLROM #(14,8) spch1( VCLKx8, SPCH_A, SPCH_D[ 7:0], ROMCL,ROMAD[13:0],ROMDT,ROMEN & (ROMAD[16:14]==3'b011));


reg			lbufr = 1'b0;					// 0/1

reg	[5:0]	loop = 6'h0;					// 0~32
reg	[4:0]	lpcn = 5'h0;					// 0~31
reg	[4:0]	xf, yf;							// 0~31
reg	[8:0]	sx;								// 0~511
reg	[4:0]	sy;								// 0~31
reg	[5:0]	pn;								// 0x00~0x3F
reg	[8:0]	vposl;							// 0~511

reg	[6:0]	nProc = 7'h0;					// 0~64


// sprite registers access
reg			bLoad = 1'b0;					// 0/1
wire	[7:0]	spriteram   = SPRA_D[7:0];
wire	[7:0]	spriteram_2 = SPRA_D[15:8];
wire	[7:0]	spriteram_3 = SPRA_D[23:16];
assign		SPRA_A		= {nProc[5:0],bLoad};

// laster hit check
wire	[8:0]	y = spriteram_2 + 8'h10 + vposl;
wire	[8:0]	m = { 1'b1, ( 8'hF0 ^ { 3'b000, spriteram_3[3], 4'b0000 } )};
wire			bHit = ( ( y & m ) == { 1'b0, m[7:0] } );

reg		  _sizx;
wire		   sizx = spriteram_3[2];
wire			sizy = spriteram_3[3];
wire	[4:0]	mskx = { sizx, 4'b1111 };
wire	[4:0]	msky = { sizy, 4'b1111 };
reg	[4:0] _msky = 5'b01111;

reg			bKick = 1'b0;

reg	[7:0]	cno;
wire	[4:0]	ox = lpcn ^ xf ^ {flip_screen & _sizx, {4{flip_screen}}};
assign SPCH_A = { cno[7:2], (cno[1]|sy[4]), (cno[0]|ox[4]), sy[3], ox[3:2], sy[2:0] };

wire	[15:0] SPCO = SPCH_D;

always @(*) begin
    CLT1_A = (ox[1:0]==2'b00) ? { pn, SPCO[15], SPCO[11], SPCO[7], SPCO[3] } :
             (ox[1:0]==2'b01) ? { pn, SPCO[14], SPCO[10], SPCO[6], SPCO[2] } :
             (ox[1:0]==2'b10) ? { pn, SPCO[13], SPCO[ 9], SPCO[5], SPCO[1] } :
                                { pn, SPCO[12], SPCO[ 8], SPCO[4], SPCO[0] } ;
    if( MODEL == SUPERPAC || MODEL == GROBDA ) begin  // 2bpp
        CLT1_A[9:2]= { 2'd0, CLT1_A[9:4] };
    end
end

wire [3:0] SPCL;
assign SPCOL = {1'b0,SPCL};
LINEBUF_DOUBLE	linebuf( VCLK, ~oHB, lbufr, VCLK, (loop!=0), sx, CLT1_D, HPOS, SPCL );

always @( negedge VCLK ) begin
	if (~oHB) begin		// Horizontal display time
		bKick <= 1'b1;
		if (loop!=0) begin	// rend sprite scanline
			  sx <= sx+1;
			lpcn <= lpcn+1;
			loop <= loop-1;
		end
		else begin				// rend sprite scanline init.
			if (~nProc[6]) begin
				if (~bLoad) begin
					if (bHit) begin
						  cno <= spriteram & { 6'b111111, ~sizy, ~sizx };
							xf <= spriteram_3[0] ? mskx : 5'h0;
							yf <= spriteram_3[1] ? msky : 5'h0;
							sy <= ( 9'h10 + vposl + { 1'b0, spriteram_2 } );
						_msky <= msky;
						_sizx <= sizx;
						bLoad <= 1'b1;
					end
					else begin
						nProc <= nProc+1;
						bLoad <= 1'b0;
					end
				end
				else begin
					   pn <= spriteram[5:0];
					   sx <= {{spriteram_3[0], spriteram_2[7:0]} ^ {9{flip_screen}}} - 9'h38 + {9'h161 & {9{flip_screen}}} - {flip_screen & _sizx, 4'b0};
						sy <= ( sy & _msky ) ^ yf;
					 loop <= spriteram_3[1] ? 6'h0 : { _sizx, ~_sizx, 4'h0 };
					 lpcn <= 6'h0;
					nProc <= nProc+1;
					bLoad <= 1'b0;
				end
			end
		end
	end
	else begin				// Horizontal blanking time
		if (bKick) begin
			lbufr <= ~VPOS[0];
			vposl <= {VPOS ^ {9{flip_screen}}} + 1 + {220 & {9{flip_screen}}};
			nProc <= 0;
			bKick <= 1'b0;
		end
	end
end

endmodule

//----------------------------------------
//  Line Buffer ( for Sprite )
//----------------------------------------
module LINEBUF_DOUBLE( CLK, EN, SIDE1, CLK2, WEN, ADRSW, IN, ADRSR, OUT );

input				CLK;
input				EN;
input				SIDE1;
input				CLK2;
input				WEN;
input		[8:0]	ADRSW;
input		[3:0]	IN;
input		[8:0]	ADRSR;
output	[3:0]	OUT;

wire	[3:0]		OUT0, OUT1;

wire				SIDE0  = ~SIDE1;
wire				OPAQUE = ~( IN[0] & IN[1] & IN[2] & IN[3] );

assign			OUT = SIDE1 ? OUT1 : OUT0;

LBUF512 buf0( CLK, SIDE0 ? EN : ( EN & WEN & SIDE1 & OPAQUE ), SIDE0 ? ADRSR-9'h1 : ADRSW, SIDE0 ? 4'b1111 : IN, CLK2, EN & SIDE0, ADRSR, OUT0 );
LBUF512 buf1( CLK, SIDE1 ? EN : ( EN & WEN & SIDE0 & OPAQUE ), SIDE1 ? ADRSR-9'h1 : ADRSW, SIDE1 ? 4'b1111 : IN, CLK2, EN & SIDE1, ADRSR, OUT1 );

endmodule

