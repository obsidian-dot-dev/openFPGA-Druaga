/***********************************
    FPGA Druaga ( Top module )

      Copyright (c) 2007 MiSTer-X

      Super Pacman Support
        (c) 2021 Jose Tejada, jotego
************************************/
module fpga_druaga
(
    input           RESET,  // RESET
    input           MCLK,       // MasterClock: 49.125MHz

    input     [8:0] PH,     // Screen H
    input     [8:0] PV,     // Screen V
    output          PCLK,       // Pixel Clock
    output  [7:0]   POUT,       // Pixel Color

    output  [7:0]  SOUT,        // Sound Out

                                    // Sticks and Buttons (Active Logic)
    input     [5:0] INP0,           // 1P {B2,B1,L,D,R,U}
    input     [5:0] INP1,           // 2P {B2,B1,L,D,R,U}
    input     [2:0] INP2,            // {Coin,Start2P,Start1P}

    input     [7:0] DSW0,       // DIPSWs (Active Logic)
    input     [7:0] DSW1,
    input     [7:0] DSW2,


    input           ROMCL,  // Downloaded ROM image
    input    [16:0] ROMAD,
    input    [7:0]  ROMDT,
    input           ROMEN,
    input    [2:0]  MODEL,    // Type Number, 5 for Super Pacman
    input           flip_screen
);

parameter [2:0] SUPERPAC=3'd5;

// Clock Generator
wire CLK24M,CLKCPUx2;
wire VCLK_x8,VCLK_x4,VCLK_x2,VCLK_x1;
CLKGEN cgen(
    MCLK,
    CLK24M,CLKCPUx2,
    VCLK_x8,VCLK_x4,VCLK_x2,VCLK_x1
);

// Main-CPU Interface
wire                MCPU_CLK = CLKCPUx2;
wire    [15:0]  MCPU_ADRS;
wire                MCPU_VMA;
wire                MCPU_RW;
wire                MCPU_WE  = ( ~MCPU_RW );
wire                MCPU_RE  = (  MCPU_RW );
wire    [7:0]       MCPU_DO;
wire    [7:0]       MCPU_DI;

// Sub-CPU Interface
wire                SCPU_CLK    = CLKCPUx2;
wire    [15:0]  SCPU_ADRS;
wire                SCPU_VMA;
wire                SCPU_RW;
wire                SCPU_WE  = ( ~SCPU_RW );
wire                SCPU_RE  = (  SCPU_RW );
wire    [7:0]       SCPU_DO;
wire    [7:0]       SCPU_DI;

// I/O Interface
wire                MCPU_CS_IO, SCPU_WE_WSG;
wire [7:0]      IO_O;
wire [10:0]     vram_a;
wire [15:0]     vram_d;
wire [6:0]      spra_a;
wire [23:0]     spra_d;
MEMS #(.SUPERPAC(SUPERPAC)) mems
(
    CLKCPUx2,
    MCPU_ADRS, MCPU_VMA, MCPU_WE, MCPU_DO, MCPU_DI, MCPU_CS_IO, IO_O,
    SCPU_ADRS, SCPU_VMA, SCPU_WE, SCPU_DO, SCPU_DI, SCPU_WE_WSG,

    VCLK_x4,
    vram_a,vram_d,
    spra_a,spra_d,

    ROMCL,ROMAD,ROMDT,ROMEN,
    MODEL
);

// Control Registers
wire oVB;
wire [7:0] SCROLL;
wire MCPU_IRQ, MCPU_IRQEN;
wire SCPU_IRQ, SCPU_IRQEN;
wire SCPU_RESET, IO_RESET;
wire PSG_ENABLE;

REGS #(.SUPERPAC(SUPERPAC)) regs
(
    CLKCPUx2, RESET, oVB,
    MCPU_ADRS, MCPU_VMA, MCPU_WE,
    SCPU_ADRS, SCPU_VMA, SCPU_WE,
    SCROLL,
    MCPU_IRQ, MCPU_IRQEN,
    SCPU_IRQ, SCPU_IRQEN,
    SCPU_RESET, IO_RESET,
    PSG_ENABLE,
    MODEL
);


// I/O Controler
wire IsMOTOS;
IOCTRL #(.SUPERPAC(SUPERPAC)) ioctrl(
    CLKCPUx2, oVB, IO_RESET, MCPU_CS_IO, MCPU_WE, MCPU_ADRS[5:0],
    MCPU_DO,
    IO_O,
    {INP1,INP0},INP2,
    {DSW2,DSW1,DSW0},
    IsMOTOS,
    MODEL
);


// Video Core
wire [7:0] oPOUT;
DRUAGA_VIDEO video
(
    .VCLKx8(VCLK_x8),.VCLKx4(VCLK_x4),.VCLK(VCLK_x1),

    .PH(PH),.PV(PV),
    .flip_screen(flip_screen),
    .PCLK(PCLK),.POUT(oPOUT),.VB(oVB),

    .VRAM_A(vram_a), .VRAM_D(vram_d),
    .SPRA_A(spra_a), .SPRA_D(spra_d),

    .SCROLL({1'b0,SCROLL}),

    .ROMCL(ROMCL),.ROMAD(ROMAD),.ROMDT(ROMDT),.ROMEN(ROMEN),
    .MODEL(MODEL)
);

// This prevents a glitch in the sprites for the first line
// but it hides the top line of the CRT test screen
assign POUT = (IsMOTOS && (PV==0)) ? 8'h0 : oPOUT;

// MainCPU
cpucore main_cpu
(
    .clk(MCPU_CLK),
    .rst(RESET),
    .rw(MCPU_RW),
    .vma(MCPU_VMA),
    .address(MCPU_ADRS),
    .data_in(MCPU_DI),
    .data_out(MCPU_DO),
    .halt(1'b0),
    .hold(1'b0),
    .irq(MCPU_IRQ),
    .firq(1'b0),
    .nmi(1'b0)
);


// SubCPU
cpucore sub_cpu
(
    .clk(SCPU_CLK),
    .rst(SCPU_RESET),
    .rw(SCPU_RW),
    .vma(SCPU_VMA),
    .address(SCPU_ADRS),
    .data_in(SCPU_DI),
    .data_out(SCPU_DO),
    .halt(1'b0),
    .hold(1'b0),
    .irq(SCPU_IRQ),
    .firq(1'b0),
    .nmi(1'b0)
);


// SOUND
wire       WAVE_CLK;
wire [7:0] WAVE_AD;
wire [3:0] WAVE_DT;
DLROM #(8,4) wsgwv(WAVE_CLK,WAVE_AD,WAVE_DT, ROMCL,ROMAD[7:0],ROMDT,ROMEN & (ROMAD[16:8]=={1'b1,8'h35}));

// Grobda has 4 bit DAC at address $0002
//wire [7:0] TempSound;
//reg  [3:0] GrobdaDAC;
//wire GROBDA_DAC_W = ( ( SCPU_ADRS == 16'h0002 ) ) & SCPU_WE;

//assign SOUT = (MODEL == 3'd6)  ? ({ 1'b0,GrobdaDAC,GrobdaDAC } + TempSound) : TempSound;
//
//always @( negedge MCPU_CLK or posedge RESET ) begin
//    if ( RESET ) begin
//        GrobdaDAC <= 4'b000;
//    end
//    else begin
//		if (GROBDA_DAC_W) begin
//			GrobdaDAC <= SCPU_DO[3:0];
//		end
//		else begin
//			// Hack to silence DAC since it is left at 7 on sample playback
//			if (TempSound != 8'd0 && GrobdaDAC == 4'd7) begin
//				GrobdaDAC <= 4'd0;
//			end
//		end
//	end
//end

WSG_8CH wsg
(
    .CLK24M(CLK24M),
    .ADDR(SCPU_ADRS[5:0]),.DATA(SCPU_DO),.WE(SCPU_WE_WSG),
    .SND_ENABLE(PSG_ENABLE),
    .WAVE_CLK(WAVE_CLK),.WAVE_AD(WAVE_AD),.WAVE_DT(WAVE_DT),
    .SOUT(SOUT)
);

endmodule

module CLKGEN
(
    input  MCLK,

    output CLK24M,
    output CLKCPUx2,

    output VCLK_x8,
    output VCLK_x4,
    output VCLK_x2,
    output VCLK_x1
);

reg [2:0] CLKS;

assign CLK24M   = CLKS[0];
assign CLKCPUx2 = CLKS[2];

assign VCLK_x8  = MCLK;
assign VCLK_x4  = CLKS[0];
assign VCLK_x2  = CLKS[1];
assign VCLK_x1  = CLKS[2];

always @( posedge MCLK ) CLKS <= CLKS+1;

endmodule


module MEMS
(
    input           CPUCLKx2,

    input [15:0]    MCPU_ADRS,
    input               MCPU_VMA,
    input               MCPU_WE,
    input    [7:0]  MCPU_DO,
    output [7:0]    MCPU_DI,
    output          IO_CS,
    input  [7:0]    IO_O,

    input [15:0]    SCPU_ADRS,
    input               SCPU_VMA,
    input               SCPU_WE,
    input    [7:0]  SCPU_DO,
    output [7:0]    SCPU_DI,
    output          SCPU_WSG_WE,

    input               VCLKx4,
    input    [10:0] vram_a,
    output [15:0]   vram_d,
    input   [6:0]   spra_a,
    output [23:0]   spra_d,


    input               ROMCL,  // Downloaded ROM image
    input  [16:0]   ROMAD,
    input     [7:0] ROMDT,
    input           ROMEN,
    input     [3:0] MODEL
);

parameter [2:0] SUPERPAC=3'd5;
parameter [2:0] GROBDA=3'd6;

wire [7:0] mrom_d, srom_d;
DLROM #(15,8) mcpui( CPUCLKx2, MCPU_ADRS[14:0], mrom_d, ROMCL,ROMAD[14:0],ROMDT,ROMEN & (ROMAD[16:15]==2'b0_0));
DLROM #(13,8) scpui( CPUCLKx2, SCPU_ADRS[12:0], srom_d, ROMCL,ROMAD[12:0],ROMDT,ROMEN & (ROMAD[16:13]==4'b1_000));

reg  mram_cs0, mram_cs1,
     mram_cs2, mram_cs3,
     mram_cs4, mram_cs5;

reg    [10:0] cram_ad;
wire   [10:0] mram_ad = MCPU_ADRS[10:0];

assign IO_CS  = ( MCPU_ADRS[15:11] == 5'b01001  ) & MCPU_VMA;    // $4800-$4FFF
wire mrom_cs  = ( MCPU_ADRS[15] ) & MCPU_VMA;    // $8000-$FFFF

always @(*) begin
    cram_ad = mram_ad;
    if( MODEL == SUPERPAC || MODEL == GROBDA ) begin
        mram_cs0 = ( MCPU_ADRS[15:10] == 6'b000000 ) && MCPU_VMA;    // $0000-$03FF
        mram_cs1 = ( MCPU_ADRS[15:10] == 6'b000001 ) && MCPU_VMA;    // $0400-$07FF
        mram_cs2 = ( MCPU_ADRS[15:11] == 5'b00001  ) && MCPU_VMA;    // $1000-$17FF
        mram_cs3 = ( MCPU_ADRS[15:11] == 5'b00010  ) && MCPU_VMA;    // $1800-$1FFF
        mram_cs4 = ( MCPU_ADRS[15:11] == 5'b00011  ) && MCPU_VMA;    // $2000-$27FF
        if( mram_cs0 | mram_cs1 ) cram_ad[10]=0;
    end else begin
        mram_cs0 = ( MCPU_ADRS[15:11] == 5'b00000  ) && MCPU_VMA;    // $0000-$07FF
        mram_cs1 = ( MCPU_ADRS[15:11] == 5'b00001  ) && MCPU_VMA;    // $0800-$0FFF
        mram_cs2 = ( MCPU_ADRS[15:11] == 5'b00010  ) && MCPU_VMA;    // $1000-$17FF
        mram_cs3 = ( MCPU_ADRS[15:11] == 5'b00011  ) && MCPU_VMA;    // $1800-$1FFF
        mram_cs4 = ( MCPU_ADRS[15:11] == 5'b00100  ) && MCPU_VMA;    // $2000-$27FF
    end
    mram_cs5 = ( MCPU_ADRS[15:10] == 6'b010000 ) && MCPU_VMA;    // $4000-$43FF
end

wire       mram_w0  = ( mram_cs0 & MCPU_WE );
wire       mram_w1  = ( mram_cs1 & MCPU_WE );
wire       mram_w2  = ( mram_cs2 & MCPU_WE );
wire       mram_w3  = ( mram_cs3 & MCPU_WE );
wire       mram_w4  = ( mram_cs4 & MCPU_WE );
wire       mram_w5  = ( mram_cs5 & MCPU_WE );

wire [7:0] mram_o0, mram_o1, mram_o2, mram_o3, mram_o4, mram_o5;

assign          MCPU_DI  = mram_cs0 ? mram_o0 :
                           mram_cs1 ? mram_o1 :
                           mram_cs2 ? mram_o2 :
                           mram_cs3 ? mram_o3 :
                           mram_cs4 ? mram_o4 :
                           mram_cs5 ? mram_o5 :
                           mrom_cs  ? mrom_d  :
                           IO_CS    ? IO_O    :
                           8'h0;

DPRAM_2048V main_ram0( CPUCLKx2, cram_ad, MCPU_DO, mram_o0, mram_w0, VCLKx4, vram_a, vram_d[7:0]   );
DPRAM_2048V main_ram1( CPUCLKx2, cram_ad, MCPU_DO, mram_o1, mram_w1, VCLKx4, vram_a, vram_d[15:8]  );

DPRAM_2048V main_ram2( CPUCLKx2, mram_ad, MCPU_DO, mram_o2, mram_w2, VCLKx4, { 4'b1111, spra_a }, spra_d[7:0]   );
DPRAM_2048V main_ram3( CPUCLKx2, mram_ad, MCPU_DO, mram_o3, mram_w3, VCLKx4, { 4'b1111, spra_a }, spra_d[15:8]  );
DPRAM_2048V main_ram4( CPUCLKx2, mram_ad, MCPU_DO, mram_o4, mram_w4, VCLKx4, { 4'b1111, spra_a }, spra_d[23:16] );


                                                                                                // (SCPU ADRS)
wire                SCPU_CS_SREG = ( ( SCPU_ADRS[15:13] == 3'b000 ) & ( SCPU_ADRS[9:6] == 4'b0000 ) ) & SCPU_VMA;
wire                srom_cs  = ( SCPU_ADRS[15:13] == 3'b111 ) & SCPU_VMA;       // $E000-$FFFF
wire                sram_cs0 = (~SCPU_CS_SREG) & (~srom_cs) & SCPU_VMA;     // $0000-$03FF
wire    [7:0]       sram_o0;

assign          SCPU_DI  =  sram_cs0 ? sram_o0 :
                                    srom_cs  ? srom_d  :
                                    8'h0;

assign          SCPU_WSG_WE = SCPU_CS_SREG & SCPU_WE;

DPRAM_2048 share_ram
(
    CPUCLKx2, mram_ad, MCPU_DO, mram_o5, mram_w5,
    CPUCLKx2, { 1'b0, SCPU_ADRS[9:0] }, SCPU_DO, sram_o0, sram_cs0 & SCPU_WE
);

endmodule



module REGS
(
    input               MCPU_CLK,
    input               RESET,
    input               VBLANK,

    input    [15:0]     MCPU_ADRS,
    input               MCPU_VMA,
    input               MCPU_WE,

    input    [15:0]     SCPU_ADRS,
    input               SCPU_VMA,
    input               SCPU_WE,

    output reg [7:0]    SCROLL,
    output              MCPU_IRQ,
    output reg          MCPU_IRQEN,
    output              SCPU_IRQ,
    output reg          SCPU_IRQEN,
    output              SCPU_RESET,
    output              IO_RESET,
    output reg          PSG_ENABLE,

    input     [2:0]     MODEL
);

parameter [2:0] SUPERPAC=3'd5;
parameter [2:0] GROBDA=3'd6;

// BG Scroll Register
wire    MCPU_SCRWE = ( ( MCPU_ADRS[15:11] == 5'b00111 ) & MCPU_VMA & MCPU_WE );
always @ ( negedge MCPU_CLK or posedge RESET ) begin
    if ( RESET ) SCROLL <= 8'h0;
    else begin
        if( MODEL==SUPERPAC || MODEL==GROBDA )
            SCROLL <= 8'h0;
        else
            if ( MCPU_SCRWE ) SCROLL <= MCPU_ADRS[10:3];
    end
end

// MainCPU IRQ Generator
wire    MCPU_IRQWE  = ( ( MCPU_ADRS[15:1] == 15'b010100000000001 ) & MCPU_VMA & MCPU_WE );
//wire  MCPU_IRQWES = ( ( SCPU_ADRS[15:1] == 15'b001000000000001 ) & SCPU_VMA & SCPU_WE );
assign MCPU_IRQ    = MCPU_IRQEN & VBLANK;

always @( negedge MCPU_CLK or posedge RESET ) begin
    if ( RESET ) begin
        MCPU_IRQEN <= 1'b0;
    end
    else begin
        if ( MCPU_IRQWE  ) MCPU_IRQEN <= MCPU_ADRS[0];
//      if ( MCPU_IRQWES ) MCPU_IRQEN <= SCPU_ADRS[0];
    end
end


// SubCPU IRQ Generator
wire    SCPU_IRQWE  = ( ( MCPU_ADRS[15:1] == 15'b010100000000000 ) & MCPU_VMA & MCPU_WE );
wire    SCPU_IRQWES = ( ( SCPU_ADRS[15:1] == 15'b001000000000000 ) & SCPU_VMA & SCPU_WE );
assign SCPU_IRQ    = SCPU_IRQEN & VBLANK;

always @( negedge MCPU_CLK or posedge RESET ) begin
    if ( RESET ) begin
        SCPU_IRQEN <= 1'b0;
    end
    else begin
        if ( SCPU_IRQWE  ) SCPU_IRQEN <= MCPU_ADRS[0];
        if ( SCPU_IRQWES ) SCPU_IRQEN <= SCPU_ADRS[0];
    end
end


// SubCPU RESET Control
reg SCPU_RSTf   = 1'b0;
wire    SCPU_RSTWE  = ( ( MCPU_ADRS[15:1] == 15'b010100000000101 ) & MCPU_VMA & MCPU_WE );
wire    SCPU_RSTWES = ( ( SCPU_ADRS[15:1] == 15'b001000000000101 ) & SCPU_VMA & SCPU_WE );
assign SCPU_RESET  = ~SCPU_RSTf;

always @( negedge MCPU_CLK or posedge RESET ) begin
    if ( RESET ) begin
        SCPU_RSTf <= 1'b0;
    end
    else begin
        if ( SCPU_RSTWE  ) SCPU_RSTf <= MCPU_ADRS[0];
        if ( SCPU_RSTWES ) SCPU_RSTf <= SCPU_ADRS[0];
    end
end


// I/O CHIP RESET Control
reg IOCHIP_RSTf   = 1'b0;
wire    IOCHIP_RSTWE  = ( ( MCPU_ADRS[15:1] == 15'b010100000000100 ) & MCPU_VMA & MCPU_WE );
assign IO_RESET     = ~IOCHIP_RSTf;

always @( negedge MCPU_CLK or posedge RESET ) begin
    if ( RESET ) begin
        IOCHIP_RSTf <= 1'b0;
    end
    else begin
        if ( IOCHIP_RSTWE ) IOCHIP_RSTf <= MCPU_ADRS[0];
    end
end


// Sound Enable Control
wire    PSG_ENAWE   = ( ( MCPU_ADRS[15:1] == 15'b010100000000011 ) & MCPU_VMA & MCPU_WE );
wire    PSG_ENAWES  = ( ( SCPU_ADRS[15:1] == 15'b001000000000011 ) & SCPU_VMA & SCPU_WE );

always @( negedge MCPU_CLK or posedge RESET ) begin
    if ( RESET ) begin
        PSG_ENABLE <= 1'b0;
    end
    else begin
        if ( PSG_ENAWE  ) PSG_ENABLE <= MCPU_ADRS[0];
        if ( PSG_ENAWES ) PSG_ENABLE <= SCPU_ADRS[0];
    end
end

endmodule


module cpucore
(
    input               clk,
    input               rst,
    output          rw,
    output          vma,
    output [15:0]   address,
    input   [7:0]   data_in,
    output  [7:0]   data_out,
    input               halt,
    input               hold,
    input               irq,
    input               firq,
    input               nmi
);


mc6809 cpu
(
   .D(data_in),
    .DOut(data_out),
   .ADDR(address),
   .RnW(rw),
    .E(vma),
   .nIRQ(~irq),
   .nFIRQ(~firq),
   .nNMI(~nmi),
   .EXTAL(clk),
   .nHALT(~halt),
   .nRESET(~rst),

    .XTAL(1'b0),
    .MRDY(1'b1),
    .nDMABREQ(1'b1)
);

endmodule

