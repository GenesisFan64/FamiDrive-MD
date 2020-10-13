; ===========================================================================
; +-----------------------------------------------------------------+
; FamiDrive beta
; 
; A Modification of Nemul by Mairtrus
; (credit him for his original attempt)
; 
; Fixed stuff, now works on real hardware
; +-----------------------------------------------------------------+

		include	"system/macros.asm"	; Assembler macros
		include	"system/md/const.asm"	; RAM / Variables are here
		include	"system/md/map.asm"	; Genesis hardware map

; ====================================================================
; ----------------------------------------------------------------
; Emulator variables
; ----------------------------------------------------------------

; ------------------------------------------------
; RAM
; ------------------------------------------------

RAM_Fami_ROM	equ $FFFF0000		; PRG-ROM
RAM_Fami_Emu	equ $FFFF8000		; Emulator buffer
RAM_Fami_RAM	equ $FFFF9000		; RAM size: $800
RAM_Fami_PPU	equ $FFFFA000		; PPU size: $3EF8 (TODO: still uses negative variables)

; ----------------------------------------------------------------
; CPU
; ----------------------------------------------------------------

cpuNMI		equ $7FFA
cpuEntry	equ $7FFC
cpuIRQ		equ $7FFE

; ----------------------------------------------------------------
; Emulator
; ---------------------------------------------------------------

		struct RAM_Fami_Emu+$FF0
RAM_EmuLoop	ds.w 3
		finish

; ----------------------------------------------------------------
; Unsorted
; ----------------------------------------------------------------

		struct 0
emuPrgRom	ds.l 1
emuChrRom	ds.l 1
cpuSprHint	ds.w 1;equ -$38
vdpReg01	ds.w 1;equ -$36
ppuMirror	ds.w 1;equ -$34
cpuMapper	ds.w 1;equ -$32
cpuFamiVint	ds.w 1;equ -$30
cpuInputData	ds.w 2;equ -$28
cpuModeDec	ds.w 1;equ -$22
cpuFlag2	ds.w 1;equ -$20
cpuModeIntDis	ds.w 1;equ -$1E
ppuNTblBase	ds.w 1;equ -$1A
ppuChrBank	ds.w 1;equ -$18
ppuOamAddr	ds.w 1;equ -$16
ppuAddrIncr	ds.w 1;equ -$14
ppuAddrBase	ds.w 1;equ -$12
ppuDataLast	ds.w 1;equ -$10
ppuSprWide	ds.w 1;equ -$E
ppuSp0Ypos	ds.w 1;equ -$C
ppuAddrLatch	ds.w 1;equ -$A
ppuOamUnk	ds.w 1;equ -6
ppuNmiFlag	ds.w 1;equ -4
ppuStatus	ds.w 1;equ -2
vdpHintSp0	ds.w 1
FamiMdVint	ds.w 1
vdpScrlX	ds.l 1
vdpScrlY	ds.l 1
vdpPalette	ds.w 64
oamSprData	ds.w 8*70
		finish

; ====================================================================
; Header
; ====================================================================

		dc.l 0
		dc.l MD_Entry
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Hint
		dc.l MD_Error
		dc.l MD_Vint
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Error
		dc.l MD_Entry
		dc.l MD_Entry
		dc.l MD_Entry
		dc.l MD_Entry
		dc.l MD_Entry
		dc.l MD_Entry
		dc.l MD_Entry
		dc.l MD_Entry
		dc.l MD_Entry
		dc.l MD_Entry
		dc.l MD_Entry
		dc.l MD_Entry
		dc.l MD_Entry
		dc.l MD_Entry
		dc.l MD_Entry
		dc.l MD_Entry
		dc.b "SEGA MEGA DRIVE "
		dc.b "(C)GF64 20??.???"
		dc.b "FamiDrive                                       "
		dc.b "FamiDrive                                       "
		dc.b "GM KE-00000-00"
		dc.w 0
		dc.w 0
		dc.b "              "
		dc.l 0
		dc.l EndOfRom-1
		dc.l $FF0000
		dc.l $FFFFFF
		dc.l $20202020
		dc.l $20202020
		dc.l $20202020
		dc.b "                                                    "
		dc.b "JUE             "

; ====================================================================
; ----------------------------------------------------------------
; Error
; ----------------------------------------------------------------

MD_Error:
		bra.s	MD_Error

; ====================================================================
; ----------------------------------------------------------------
; Entry
; ----------------------------------------------------------------

MD_Entry:
		move	#$2700,sr
		tst.l	($A10008).l
		bne.s	loc_210
		tst.w	($A1000C).l
loc_210:
		bne.w	loc_270
		lea	(list_InitRegs).l,a5
		movem.w	(a5)+,d5-d7
		movem.l	(a5)+,a0-a4
		move.b	($A10001).l,d0
		andi.b	#$F,d0
		beq.w	old_md
		move.l	#"SEGA",($A14000).l
old_md:
		clr.l	d0
		movea.l	d0,a6
		move	a6,usp
clrstack:
		move.l	d0,-(a6)
		dbf	d6,clrstack
		bsr	Sound_LoadZ80
		bsr	Sound_PsgInit
		bsr	Video_Init
		movem.l	(a6),d0-a6
		move.b	#$40,($A10009).l
		move.b	#$40,($A1000B).l
loc_270:
		bra.w	MD_Init
; ----------------------------------------------------------------
list_InitRegs:	dc.w $8000		; d5
		dc.w $3FFF		; d6
		dc.w $100		; d7
		dc.l $A00000		; a0
		dc.l $A11100		; a1
		dc.l $A11200		; a2
		dc.l $C00000		; a3
		dc.l $C00004		; a4
		dc.b $AF, 1, $D9, $1F, $11, $27, 0, $21, $26, 0, $F9, $77
		dc.b $ED, $B0, $DD, $E1, $FD, $E1, $ED,	$47, $ED, $4F
		dc.b $D1, $E1, $F1, 8, $D9, $C1, $D1, $E1, $F1,	$F9, $F3
		dc.b $ED, $56, $36, $E9, $E9, $81, 4, $8F, 1
		dc.b $9F
		dc.b $BF
		dc.b $DF
		dc.b $FF
; ----------------------------------------------------------------

; =============== S U B	R O U T	I N E =======================================


Fami_InitVideo:
		move.w	#$8F02,4(a6)
		move.w	#$FFF,d7
		move.l	#$40000003,4(a6)
.loopfg:
		move.w	#$200,(a6)
		dbf	d7,.loopfg
		move.w	#$FFF,d7
		move.l	#$60000003,4(a6)
.loopbg:
		move.w	#$200,(a6)
		dbf	d7,.loopbg		

		move.l	#$68000002,4(a6)
		move.l	#0,(a6)
		move.l	#$40000010,4(a6)
		move.l	#0,(a6)
		moveq	#$3F,d7
		move.l	#$C0000000,4(a6)

loc_51E:
		move.w	#0,(a6)
		dbf	d7,loc_51E
		move.l	#$C0020000,4(a6)
		move.w	#$EEE,(a6)
		rts

; =============== S U B	R O U T	I N E =======================================


Sound_LoadZ80:
		move.w	d7,(a1)
		move.w	d7,(a2)

loc_8DA:
		btst	d0,(a1)
		bne.s	loc_8DA
		moveq	#$25,d2
loc_8E0:
		move.b	(a5)+,(a0)+
		dbf	d2,loc_8E0
		move.w	d0,(a2)
		move.w	d0,(a1)
		move.w	d7,(a2)
		rts
; End of function Sound_LoadZ80


; =============== S U B	R O U T	I N E =======================================


Sound_PsgInit:
		moveq	#3,d1

loc_8F0:
		move.b	(a5)+,$11(a3)
		dbf	d1,loc_8F0
		move.w	d0,(a2)
		rts
; End of function Sound_PsgInit


; =============== S U B	R O U T	I N E =======================================


Video_Init:
		moveq	#$17,d0
		lea	(byte_910).l,a0
loc_904:
		move.b	(a0)+,d5
		move.w	d5,(a4)
		add.w	d7,d5
		dbf	d0,loc_904
		rts

; ----------------------------------------------------------------
byte_910:
		dc.b $14			; HBlank int on, HV Counter on
		dc.b $64			; Display ON, VBlank int on
		dc.b (($C000)>>10)		; ForeGrd at VRAM $C000 (%00xxx000)
		dc.b (($D000)>>10)		; Window  at VRAM $D000 (%00xxxxy0)
		dc.b (($E000)>>13)		; BackGrd at VRAM $E000 (%00000xxx)
		dc.b (($BC00)>>9)		; Sprites at VRAM $BC00 (%0xxxxxxy)
		dc.b $00			; Nothing
		dc.b $00			; Background color
		dc.b $00			; Nothing
		dc.b $00			; Nothing
		dc.b $DF			; HInt value
		dc.b (%000|%00)			; No ExtInt, Scroll: VSCR:full HSCR:full
		dc.b $00			; H40, No shadow mode, Normal resolution
		dc.b (($B800)>>10)		; HScroll at VRAM $B800 (%00xxxxxx)
		dc.b $00			; Nothing
		dc.b $02			; VDP Auto increment by $02
		dc.b (%01<<4)|%01		; Layer size: V32 H64
		dc.b $00
		dc.b $00
		align 2

; ====================================================================

MD_Init:
		move.b	#$40,($A10009).l
		move.b	#$40,($A1000B).l
		move.w	#$100,(z80_bus).l		; Stop Z80
		move.w	#$100,(z80_reset).l		; Reset cancel
.wait:
		btst	#0,(z80_bus).l			; Wait bus
		bne.s	.wait

		move.w	#0,(z80_reset).l		; Reset request
		nop
		nop
		nop
		move.w	#0,(z80_bus).l			; Start Z80
		move.w	#$100,(z80_reset).l		; Reset cancel
		
		bra	emuStart

; ====================================================================
; ----------------------------------------------------------------
; VBlank
; ----------------------------------------------------------------

MD_Vint:
		movem.l	d0-d7/a0-a6,-(sp)

		move.w	#$8F02,4(a6)
		move.l	#$78000002,4(a6)
		move.l	vdpScrlX(a4),(a6)
		move.l	#$40000010,4(a6)
		move.l	vdpScrlY(a4),(a6)
		move.l	#$94019318,4(a6)
		move.w	#$0100,(z80_bus).l
		move.l	#$96009500+(((RAM_Fami_Emu+oamSprData)<<7)&$FF0000)|(((RAM_Fami_Emu+oamSprData)>>1)&$FF),4(a6)
		move.w	#$9700|(((RAM_Fami_Emu+oamSprData)>>17)&$7F),4(a6)
		move.w	#$7C00,4(a6)
		move.w	#$0002|$80,-(sp)
.wait:		btst	#0,(z80_bus).l
		bne.s	.wait
		move.w	(sp)+,4(a6)
		move.w	#$0100,(z80_bus).l
		move.l	#$94009340,4(a6)
		move.l	#$96009500+(((RAM_Fami_Emu+vdpPalette)<<7)&$FF0000)|(((RAM_Fami_Emu+vdpPalette)>>1)&$FF),4(a6)
		move.w	#$9700|(((RAM_Fami_Emu+vdpPalette)>>17)&$7F),4(a6)
		move.w	#$C000,4(a6)
		move.w	#$0000|$80,-(sp)
.wait2:		btst	#0,(z80_bus).l
		bne.s	.wait2
		move.w	(sp)+,4(a6)

		clr.w	vdpHintSp0(a4)
		move.w	#1,FamiMdVint(a4)
		movem.l	(sp)+,d0-d7/a0-a6
		rte

; ====================================================================
; ----------------------------------------------------------------
; HBlank
; ----------------------------------------------------------------

MD_Hint:
		move.w	#$2700,sr
		move.w	#$8ADF,4(a6)
		move.w	#1,vdpHintSp0(a4)
; 		move.l	#$C0080000,4(a6)		; for TESTING only
; 		move.w	#0,(a6)
		move.l	#$78000002,4(a6)
		move.l	vdpScrlX(a4),(a6)
		move.l	#$40000010,4(a6)
		move.l	vdpScrlY(a4),(a6)
		rte

; ====================================================================
; ----------------------------------------------------------------
; Load ROM
; ----------------------------------------------------------------

Fami_LoadRom:
		move.l	(a0),d0		; Read and Load	Fami ROM
		cmpi.l	#$4E45531A,d0
		bne.s	*

		lea	(RAM_Fami_RAM).l,a5
		moveq	#0,d0
		move.w	#$7FF/4,d1
.clrram:
		move.l	d0,(a5)+
		dbf	d1,.clrram
		lea	(RAM_Fami_PPU).l,a5
		moveq	#0,d0
		move.w	#$4000/4,d1
.clrvram:
		move.l	d0,(a5)+
		dbf	d1,.clrvram
		lea 	($C00000),a6
		bsr	Fami_InitVideo

		lea	(RAM_Fami_Emu).l,a3
		moveq	#0,d7			; PRG-ROM copy
		move.b	4(a0),d7
		bsr	romGrabPrg
		move.b	6(a0),d7		; PPU mirroring
		move.b	7(a0),d6
		and.w	#%11110000,d7
		and.w	#%11110000,d6
		lsr.w	#4,d7
		or.w	d6,d7
		move.w	d7,cpuMapper(a3)
	
	; Mirror check
		move.w	#0,d7			; 0 - horizontal
		btst	#0,6(a0)		; PPU mirroring
		beq.s	loc_9F4
		move.w	#1,d7			; 1 - vertical
loc_9F4:
		move.w	d7,ppuMirror(a3)
		
	; COPY CHR-ROM TO RAM
		lea	(RAM_Fami_PPU).l,a5
		move.l	a4,emuChrRom(a3)
		move.l	#$7FF,d7
loc_A10:
		move.l	(a4)+,(a5)+
		dbf	d7,loc_A10
		adda	#$10,a0
		move.l	a0,emuPrgRom(a3)
		rts

; ====================================================================
; ----------------------------------------------------------------
; Emulator start
; ----------------------------------------------------------------

emuStart:
		lea	(ROM_FILE).l,a0
		bsr	Fami_LoadRom
		
		lea	($C00000).l,a6
		lea 	(RAM_Fami_Emu),a4
		lea	(RAM_Fami_PPU).w,a3
		lea	(RAM_Fami_RAM).w,a2
		lea 	(RAM_Fami_ROM),a1	; PRG base
		movea.l	a1,a0
		move.w	#cpuEntry,d0		; go to Entry
		add.w	d0,a0
		move.b	1(a0),d0
		lsl.w	#8,d0
		move.b	(a0),d0
		and.w	#$7FFF,d0
		movea.l	a1,a0
		adda	d0,a0
		move.w	#$8174,vdpReg01(a4)
		move.w	#$4EF9,(RAM_EmuLoop).l
		move.l	#emuLoop,(RAM_EmuLoop+2).l

		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		move.l	#$01002000,d3

; --------------------------------------------------------
; a0 - Fami CPU current PC
; a1 - Fami PRG address
; a2 - Fami RAM address (for zero addressing)
; a3 - Fami PPU Buffer
; a4 - Fami EMU Buffer
; a5 - Used on temporal tasks
; a6 - VDP data point
; 
; d0 - A register
; d1 - X register
; d2 - Y register
; d3 - Fami STACK Point | MD current sr
; d4 - free
; d5 - free
; d6 - free
; d7 - emu temporal input/output
; --------------------------------------------------------

; ------------------------------------------------
; Main Loop
; ------------------------------------------------

emuLoop:
		tst.w	FamiMdVint(a4)
		bne.s	famiVInt
emuVint:
		clr.w	d4
		move.b	(a0)+,d4
		add.w	d4,d4
		move.w	mosCpu(pc,d4.w),d4
		jmp	mosCpu(pc,d4.w)

; ------------------------------------------------
; VBlank
; ------------------------------------------------

famiVInt:
		clr.w	FamiMdVint(a4)
		move.w	#$80,ppuStatus(a4)
		tst.w	cpuFamiVint(a4)
		bne.s	emuVint
		tst.w	ppuNmiFlag(a4)
		beq.s	emuVint

; ------------------------------------------------
doVint:
		move.l	#emuVint,(RAM_EmuLoop+2).l
		move.w	#1,cpuFamiVint(a4)

		movem.l	d4/a0/a5,-(sp)
		move.w	d3,-(sp)
		lea 	(RAM_Fami_ROM),a0	; PRG base
		move.w	#cpuNMI,d6		; go to NMI
		add.w	d6,a0
		move.b	1(a0),d6
		lsl.w	#8,d6
		move.b	(a0),d6
		and.w	#$7FFF,d6
		movea.l	a1,a0
		add.w	d6,a0
		bra	emuVint
		
; ----------------------------------------------------------------
mosCpu:		dc.w mos_BRK-mosCpu	; $00
		dc.w loc_1A12-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1970-mosCpu
		dc.w loc_1042-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1A78-mosCpu	; $08
		dc.w loc_195C-mosCpu	; $09 - ORA #$xx
		dc.w loc_1030-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_19A6-mosCpu
		dc.w loc_1080-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1166-mosCpu	; $10
		dc.w loc_1A3C-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_198A-mosCpu
		dc.w loc_1060-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_11AA-mosCpu	; $18
		dc.w loc_19EC-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_19C6-mosCpu
		dc.w loc_10A2-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_167C-mosCpu	; $20
		dc.w loc_FD8-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_10F0-mosCpu
		dc.w loc_F36-mosCpu
		dc.w loc_1ACA-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1AA6-mosCpu	; $28
		dc.w loc_F22-mosCpu
		dc.w loc_1AB6-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_111A-mosCpu
		dc.w loc_F6C-mosCpu
		dc.w loc_1B0C-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_114A-mosCpu	; $30
		dc.w loc_1002-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_F50-mosCpu
		dc.w loc_1AEA-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1D80-mosCpu	; $38
		dc.w loc_FB2-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_F8C-mosCpu
		dc.w loc_1B30-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1BF6-mosCpu	; $40 - RTI
		dc.w loc_1566-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_14C4-mosCpu
		dc.w loc_18D2-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1A6A-mosCpu	; $48
		dc.w loc_14B0-mosCpu
		dc.w loc_18C0-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_164E-mosCpu	; $4C - JMP $xxxx
		dc.w loc_14FA-mosCpu
		dc.w loc_1910-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_118E-mosCpu	; $50
		dc.w loc_1590-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_14DE-mosCpu
		dc.w loc_18F0-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_11BC-mosCpu	; $58
		dc.w loc_1540-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_151A-mosCpu
		dc.w loc_1932-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1C32-mosCpu	; $60 - RTS
		dc.w loc_ED2-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_E44-mosCpu
		dc.w loc_1B6A-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1A88-mosCpu	; $68
		dc.w loc_E34-mosCpu
		dc.w loc_1B56-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1660-mosCpu	; $6C - JMP ($xxxx)
		dc.w loc_E72-mosCpu
		dc.w loc_1BAC-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_119C-mosCpu	; $70
		dc.w loc_EF8-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_E5A-mosCpu
		dc.w loc_1B8A-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1D92-mosCpu	; $78
		dc.w loc_EB0-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_E8E-mosCpu
		dc.w loc_1BD0-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu	; $80
		dc.w loc_1DF6-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1E5C-mosCpu
		dc.w loc_1D9C-mosCpu
		dc.w loc_1E2E-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_149E-mosCpu	; $88
		dc.w mos_Null-mosCpu
		dc.w loc_1EC4-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1E76-mosCpu
		dc.w loc_1DB6-mosCpu
		dc.w loc_1E48-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_10C6-mosCpu	; $90
		dc.w loc_1E10-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1E68-mosCpu
		dc.w loc_1DA8-mosCpu
		dc.w loc_1E3A-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1EE0-mosCpu	; $98
		dc.w loc_1DE0-mosCpu
		dc.w loc_1Ed3-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1DCA-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1836-mosCpu	; $A0
		dc.w loc_1754-mosCpu
		dc.w loc_17AC-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1848-mosCpu
		dc.w loc_16B6-mosCpu
		dc.w loc_17BE-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1E9C-mosCpu	; $A8
		dc.w loc_16A4-mosCpu	; $A9 - LDA #$xx
		dc.w loc_1E8A-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_187A-mosCpu
		dc.w loc_16E8-mosCpu
		dc.w loc_17F0-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_10D4-mosCpu
		dc.w loc_177E-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1860-mosCpu
		dc.w loc_16CE-mosCpu
		dc.w loc_17d3-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_11C6-mosCpu
		dc.w loc_172E-mosCpu
		dc.w loc_1EAE-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_189A-mosCpu
		dc.w loc_1708-mosCpu
		dc.w loc_1810-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_13AE-mosCpu
		dc.w loc_12CC-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_13CE-mosCpu
		dc.w loc_11EE-mosCpu
		dc.w loc_1420-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_163C-mosCpu
		dc.w loc_11CE-mosCpu
		dc.w loc_148C-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_13F4-mosCpu
		dc.w loc_123C-mosCpu
		dc.w loc_1452-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1158-mosCpu
		dc.w loc_1302-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1214-mosCpu
		dc.w loc_1438-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_11B2-mosCpu
		dc.w loc_129A-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1268-mosCpu
		dc.w loc_146E-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_133C-mosCpu
		dc.w loc_1D20-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_135C-mosCpu
		dc.w loc_1C6A-mosCpu
		dc.w loc_15BE-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_162A-mosCpu
		dc.w loc_1C52-mosCpu
		dc.w loc_1956-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1382-mosCpu
		dc.w loc_1CA8-mosCpu
		dc.w loc_15F0-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_10E2-mosCpu
		dc.w loc_1D4E-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1C88-mosCpu
		dc.w loc_15d3-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1D88-mosCpu
		dc.w loc_1CF6-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w mos_Null-mosCpu
		dc.w loc_1CCC-mosCpu
		dc.w loc_160C-mosCpu
		dc.w mos_Null-mosCpu
; ----------------------------------------------------------------

mos_Null:
		bra.s	*

; ----------------------------------------------------------------

loc_E34:
		move.b	(a0)+,d7
		ori.b	#4,d3
		move	d3,sr
		addx.b	d7,d0
		move	sr,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_E44:
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d7
		ori.b	#4,d3
		move	d3,sr
		addx.b	d7,d0
		move	sr,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_E5A:
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d1,d6
		move.b	(a2,d6.w),d7
		ori.b	#4,d3
		move	d3,sr
		addx.b	d7,d0
		move	sr,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_E72:				; DATA XREF: ROM:00000BE6o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		bsr	addr_Read
		ori.b	#4,d3
		move	d3,sr
		addx.b	d7,d0
		move	sr,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_E8E:				; DATA XREF: ROM:00000C26o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d1,d4
		addx.b	d7,d6
		bsr	addr_Read
		ori.b	#4,d3
		move	d3,sr
		addx.b	d7,d0
		move	sr,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_EB0:				; DATA XREF: ROM:00000C16o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		ori.b	#4,d3
		move	d3,sr
		addx.b	d7,d0
		move	sr,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_ED2:				; DATA XREF: ROM:00000BB6o
		clr.w	d5
		move.b	(a0)+,d5
		add.b	d1,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		bsr	addr_Read
		ori.b	#4,d3
		move	d3,sr
		addx.b	d7,d0
		move	sr,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_EF8:				; DATA XREF: ROM:00000BF6o
		clr.w	d5
		move.b	(a0)+,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		ori.b	#4,d3
		move	d3,sr
		addx.b	d7,d0
		move	sr,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_F22:				; DATA XREF: ROM:00000Ad3o
		move.b	(a0)+,d7
		and.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_F36:				; DATA XREF: ROM:00000AC6o
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d7
		and.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_F50:				; DATA XREF: ROM:00000B06o
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d1,d6
		move.b	(a2,d6.w),d7
		and.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_F6C:
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		bsr	addr_Read
		and.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_F8C:
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d1,d4
		addx.b	d7,d6
		bsr	addr_Read
		and.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_FB2:				; DATA XREF: ROM:00000B16o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		and.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_FD8:				; DATA XREF: ROM:00000AB6o
		clr.w	d5
		move.b	(a0)+,d5
		add.b	d1,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		bsr	addr_Read
		and.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1002:				; DATA XREF: ROM:00000AF6o
		clr.w	d5
		move.b	(a0)+,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		and.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1030:				; DATA XREF: ROM:00000A5Ao
		lsl.b	#1,d0
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1042:
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d7
		lsl.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1060:
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d1,d6
		move.b	(a2,d6.w),d7
		lsl.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1080:
		move.b	(a0)+,d4
		move.b	(a0)+,d6
		lsl.w	#8,d6
		move.b	d4,d6
		move.b	(a2,d6.w),d7
		lsl.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_10A2:				; DATA XREF: ROM:00000AAAo
		move.b	(a0)+,d4
		move.b	(a0)+,d6
		lsl.w	#8,d6
		move.b	d4,d6
		add.w	d1,d6
		move.b	(a2,d6.w),d7
		lsl.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_10C6:
		move.b	(a0)+,d6
		move	d3,sr
		bcs.s	loc_10D0
		ext.w	d6
		adda.w	d6,a0
loc_10D0:
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_10D4:
		move.b	(a0)+,d6
		move	d3,sr
		bcc.s	loc_10DE
		ext.w	d6
		adda.w	d6,a0
loc_10DE:
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_10E2:
		move.b	(a0)+,d6
		move	d3,sr
		bne.s	loc_10EC
		ext.w	d6
		adda.w	d6,a0
loc_10EC:
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_10F0:
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d7
		move.b	d7,d4
		andi.b	#$F1,d3
		lsl.b	#1,d7
		bcc.s	loc_1106
		ori.b	#8,d3
loc_1106:
		lsl.b	#1,d7
		bcc.s	loc_110E
		ori.b	#2,d3
loc_110E:
		and.b	d0,d4
		bne.s	loc_1116
		ori.b	#4,d3
loc_1116:
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_111A:
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		bsr	addr_Read
		move.b	d7,d4
		andi.b	#$F1,d3
		lsl.b	#1,d7
		bcc.s	loc_1136
		ori.b	#8,d3

loc_1136:
		lsl.b	#1,d7
		bcc.s	loc_113E
		ori.b	#2,d3

loc_113E:
		and.b	d0,d4
		bne.s	loc_1146
		ori.b	#4,d3

loc_1146:
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_114A:				; DATA XREF: ROM:00000AF2o
		move.b	(a0)+,d6
		move	d3,sr
		bpl.s	loc_1154
		ext.w	d6
		adda.w	d6,a0

loc_1154:				; CODE XREF: ROM:0000114Ej
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1158:				; DATA XREF: ROM:00000D72o
		move.b	(a0)+,d6
		move	d3,sr
		beq.s	loc_1162
		ext.w	d6
		adda.w	d6,a0

loc_1162:				; CODE XREF: ROM:0000115Cj
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1166:
		move.b	(a0)+,d6
		move	d3,sr
		bmi.s	loc_1170
		ext.w	d6
		adda.w	d6,a0

loc_1170:
		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------
; $00 - BRK
; ----------------------------------------------------------------

mos_BRK:
		lea 	(RAM_Fami_ROM),a5
		move.w	#cpuIRQ,d6		; go to IRQ
		add.w	d6,a5
		move.b	1(a5),d6
		lsl.w	#8,d6
		move.b	(a5),d6

		move.w	#1,cpuModeIntDis(a4)
		move.w	#1,cpuFlag2(a4)
		bra.w	loc_1686
; ----------------------------------------------------------------

loc_118E:
		move.b	(a0)+,d6
		move	d3,sr
		bvs.s	loc_1198
		ext.w	d6
		adda.w	d6,a0

loc_1198:
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_119C:
		move.b	(a0)+,d6
		move	d3,sr
		bvc.s	loc_11A6
		ext.w	d6
		adda.w	d6,a0

loc_11A6:				; CODE XREF: ROM:000011A0j
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_11AA:				; DATA XREF: ROM:00000A92o
		andi.b	#$EE,d3
		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------
; CLD - Clear Decimal mode
; ----------------------------------------------------------------

loc_11B2:
		move.w	#0,cpuModeDec(a4)
		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------
; CLI - Clear Interrupt disable
; ----------------------------------------------------------------

loc_11BC:
		move.w	#0,cpuModeIntDis(a4)
		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------

loc_11C6:				; DATA XREF: ROM:00000D12o
		andi.b	#$FD,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_11CE:				; DATA XREF: ROM:00000D56o
		move.b	(a0)+,d7
		cmp.b	d7,d0
		move	sr,d5
		andi.w	#$D,d5
		eori.b	#1,d5
		andi.b	#2,d3
		or.b	d5,d3
		andi.b	#1,d5
		lsl.b	#4,d5
		or.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_11EE:				; DATA XREF: ROM:00000D46o
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d7
		cmp.b	d7,d0
		move	sr,d5
		andi.w	#$D,d5
		eori.b	#1,d5
		andi.b	#2,d3
		or.b	d5,d3
		andi.b	#1,d5
		lsl.b	#4,d5
		or.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1214:				; DATA XREF: ROM:00000D86o
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d1,d6
		move.b	(a2,d6.w),d7
		cmp.b	d7,d0
		move	sr,d5
		andi.w	#$D,d5
		eori.b	#1,d5
		andi.b	#2,d3
		or.b	d5,d3
		andi.b	#1,d5
		lsl.b	#4,d5
		or.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_123C:				; DATA XREF: ROM:00000d36o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		bsr	addr_Read
		cmp.b	d7,d0
		move	sr,d5
		andi.w	#$D,d5
		eori.b	#1,d5
		andi.b	#2,d3
		or.b	d5,d3
		andi.b	#1,d5
		lsl.b	#4,d5
		or.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1268:				; DATA XREF: ROM:00000DA6o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d1,d4
		addx.b	d7,d6
		bsr	addr_Read
		cmp.b	d7,d0
		move	sr,d5
		andi.w	#$D,d5
		eori.b	#1,d5
		andi.b	#2,d3
		or.b	d5,d3
		andi.b	#1,d5
		lsl.b	#4,d5
		or.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_129A:				; DATA XREF: ROM:00000D96o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		cmp.b	d7,d0
		move	sr,d5
		andi.w	#$D,d5
		eori.b	#1,d5
		andi.b	#2,d3
		or.b	d5,d3
		andi.b	#1,d5
		lsl.b	#4,d5
		or.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_12CC:				; DATA XREF: ROM:00000d63o
		clr.w	d5
		move.b	(a0)+,d5
		add.b	d1,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		bsr	addr_Read
		cmp.b	d7,d0
		move	sr,d5
		andi.w	#$D,d5
		eori.b	#1,d5
		andi.b	#2,d3
		or.b	d5,d3
		andi.b	#1,d5
		lsl.b	#4,d5
		or.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1302:				; DATA XREF: ROM:00000D76o
		clr.w	d5
		move.b	(a0)+,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		cmp.b	d7,d0
		move	sr,d5
		andi.w	#$D,d5
		eori.b	#1,d5
		andi.b	#2,d3
		or.b	d5,d3
		andi.b	#1,d5
		lsl.b	#4,d5
		or.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_133C:				; DATA XREF: ROM:00000DB2o
		move.b	(a0)+,d7
		cmp.b	d7,d1
		move	sr,d5
		andi.w	#$D,d5
		eori.b	#1,d5
		andi.b	#2,d3
		or.b	d5,d3
		andi.b	#1,d5
		lsl.b	#4,d5
		or.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_135C:				; DATA XREF: ROM:00000DC2o
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d7
		cmp.b	d7,d1
		move	sr,d5
		andi.w	#$D,d5
		eori.b	#1,d5
		andi.b	#2,d3
		or.b	d5,d3
		andi.b	#1,d5
		lsl.b	#4,d5
		or.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1382:				; DATA XREF: ROM:00000DE2o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		bsr	addr_Read
		cmp.b	d7,d1
		move	sr,d5
		andi.w	#$D,d5
		eori.b	#1,d5
		andi.b	#2,d3
		or.b	d5,d3
		andi.b	#1,d5
		lsl.b	#4,d5
		or.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_13AE:				; DATA XREF: ROM:00000d62o
		move.b	(a0)+,d7
		cmp.b	d7,d2
		move	sr,d5
		andi.w	#$D,d5
		eori.b	#1,d5
		andi.b	#2,d3
		or.b	d5,d3
		andi.b	#1,d5
		lsl.b	#4,d5
		or.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_13CE:				; DATA XREF: ROM:00000D42o
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d7
		cmp.b	d7,d2
		move	sr,d5
		andi.w	#$D,d5
		eori.b	#1,d5
		andi.b	#2,d3
		or.b	d5,d3
		andi.b	#1,d5
		lsl.b	#4,d5
		or.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_13F4:				; DATA XREF: ROM:00000d32o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		bsr	addr_Read
		cmp.b	d7,d2
		move	sr,d5
		andi.w	#$D,d5
		eori.b	#1,d5
		andi.b	#2,d3
		or.b	d5,d3
		andi.b	#1,d5
		lsl.b	#4,d5
		or.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1420:				; DATA XREF: ROM:00000D4Ao
		clr.w	d6
		move.b	(a0)+,d6
		subq.b	#1,(a2,d6.w)
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1438:				; DATA XREF: ROM:00000D8Ao
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d1,d6
		subq.b	#1,(a2,d6.w)
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1452:				; DATA XREF: ROM:00000d3Ao
		move.b	(a0)+,d4
		move.b	(a0)+,d6
		lsl.w	#8,d6
		move.b	d4,d6
		subq.b	#1,(a2,d6.w)
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_146E:				; DATA XREF: ROM:00000DAAo
		move.b	(a0)+,d4
		move.b	(a0)+,d6
		lsl.w	#8,d6
		move.b	d4,d6
		add.w	d1,d6
		subq.b	#1,(a2,d6.w)
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_148C:				; DATA XREF: ROM:00000D5Ao
		subq.b	#1,d1
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_149E:				; DATA XREF: ROM:00000C52o
		subq.b	#1,d2
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_14B0:				; DATA XREF: ROM:00000B56o
		move.b	(a0)+,d7
		eor.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_14C4:				; DATA XREF: ROM:00000B46o
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d7
		eor.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_14DE:				; DATA XREF: ROM:00000B86o
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d1,d6
		move.b	(a2,d6.w),d7
		eor.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_14FA:				; DATA XREF: ROM:00000B66o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		bsr	addr_Read
		eor.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_151A:				; DATA XREF: ROM:00000BA6o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d1,d4
		addx.b	d7,d6
		bsr	addr_Read
		eor.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1540:				; DATA XREF: ROM:00000B96o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		eor.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1566:				; DATA XREF: ROM:00000B36o
		clr.w	d5
		move.b	(a0)+,d5
		add.b	d1,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		bsr	addr_Read
		eor.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1590:
		clr.w	d5
		move.b	(a0)+,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		eor.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_15BE:
		clr.w	d6
		move.b	(a0)+,d6
		addq.b	#1,(a2,d6.w)
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_15d3:
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d1,d6
		addq.b	#1,(a2,d6.w)
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_15F0:
		move.b	(a0)+,d4
		move.b	(a0)+,d6
		lsl.w	#8,d6
		move.b	d4,d6
		addq.b	#1,(a2,d6.w)
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_160C:
		move.b	(a0)+,d4
		move.b	(a0)+,d6
		lsl.w	#8,d6
		move.b	d4,d6
		add.w	d1,d6
		addq.b	#1,(a2,d6.w)
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_162A:
		addq.b	#1,d1
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_163C:
		addq.b	#1,d2
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------
; $4C - JMP $xxxx
; ----------------------------------------------------------------

loc_164E:
		moveq	#0,d6
		move.b	1(a0),d6
		lsl.w	#8,d6
		move.b	(a0),d6
; 		lea	(a2,d6.l),a0
		
		and.l	#$7FFF,d6
		movea.l a1,a0
		add.l 	d6,a0
		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------
; $6C - JMP ($xxxx)
; ----------------------------------------------------------------

loc_1660:
		moveq	#0,d4
		move.b	1(a0),d6
		lsl.w	#8,d6
		move.b	(a0),d6
		move.b	1(a2,d6.w),d4
		lsl.w	#8,d4
		move.b	(a2,d6.w),d4
		
; 		lea	(a2,d4.l),a0
		and.l	#$7FFF,d4
		movea.l a1,a0
		add.l 	d4,a0
		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------
; $6C - JSR $xxxx
; ----------------------------------------------------------------

loc_167C:
		moveq	#0,d6
		move.b	(a0)+,d4
		move.b	(a0),d6
		lsl.w	#8,d6
		move.b	d4,d6

loc_1686:
		swap	d3
		move.w	a0,d4
		move.b	d4,d5
		lsr.w	#8,d4
		or.b	#$80,d4
		move.b	d4,(a2,d3.w)
		subq.b	#1,d3
		move.b	d5,(a2,d3.w)
		subq.b	#1,d3
		swap	d3
; 		lea	(a2,d6.l),a0

		and.l	#$7FFF,d6
		movea.l a1,a0
		add.l 	d6,a0
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------
; $A9 - LDA #$xx
; ----------------------------------------------------------------

loc_16A4:
		move.b	(a0)+,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_16B6:
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_16CE:				; DATA XREF: ROM:00000D06o
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d1,d6
		move.b	(a2,d6.w),d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_16E8:				; DATA XREF: ROM:00000CE6o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		bsr	addr_Read
		move.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1708:				; DATA XREF: ROM:00000D26o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d1,d4
		addx.b	d7,d6
		bsr	addr_Read
		move.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_172E:				; DATA XREF: ROM:00000D16o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		move.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1754:				; DATA XREF: ROM:00000CB6o
		clr.w	d5
		move.b	(a0)+,d5
		add.b	d1,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		bsr	addr_Read
		move.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_177E:				; DATA XREF: ROM:00000CF6o
		clr.w	d5
		move.b	(a0)+,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		move.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_17AC:				; DATA XREF: ROM:00000CBAo
		move.b	(a0)+,d1
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_17BE:				; DATA XREF: ROM:00000CCAo
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d1
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_17d3:				; DATA XREF: ROM:00000D0Ao
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d2,d6
		move.b	(a2,d6.w),d1
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_17F0:				; DATA XREF: ROM:00000CEAo
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		bsr	addr_Read
		move.b	d7,d1
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1810:				; DATA XREF: ROM:00000D2Ao
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		move.b	d7,d1
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1836:				; DATA XREF: ROM:00000CB2o
		move.b	(a0)+,d2
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1848:				; DATA XREF: ROM:00000CC2o
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d2
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1860:				; DATA XREF: ROM:00000D02o
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d1,d6
		move.b	(a2,d6.w),d2
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_187A:				; DATA XREF: ROM:00000CE2o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		bsr	addr_Read
		move.b	d7,d2
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_189A:				; DATA XREF: ROM:00000D22o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d1,d4
		addx.b	d7,d6
		bsr	addr_Read
		move.b	d7,d2
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_18C0:				; DATA XREF: ROM:00000B5Ao
		lsr.b	#1,d0
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_18D2:				; DATA XREF: ROM:00000B4Ao
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d7
		lsr.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_18F0:				; DATA XREF: ROM:00000B8Ao
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d1,d6
		move.b	(a2,d6.w),d7
		lsr.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1910:				; DATA XREF: ROM:00000B6Ao
		move.b	(a0)+,d4
		move.b	(a0)+,d6
		lsl.w	#8,d6
		move.b	d4,d6
		move.b	(a2,d6.w),d7
		lsr.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1932:				; DATA XREF: ROM:00000BAAo
		move.b	(a0)+,d4
		move.b	(a0)+,d6
		lsl.w	#8,d6
		move.b	d4,d6
		add.w	d1,d6
		move.b	(a2,d6.w),d7
		lsr.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1956:				; DATA XREF: ROM:00000DDAo
		nop
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_195C:				; DATA XREF: ROM:00000A56o
		move.b	(a0)+,d7
		or.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1970:				; DATA XREF: ROM:00000A46o
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d7
		or.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_198A:				; DATA XREF: ROM:00000A86o
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d1,d6
		move.b	(a2,d6.w),d7
		or.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_19A6:				; DATA XREF: ROM:00000A66o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		bsr	addr_Read
		or.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_19C6:				; DATA XREF: ROM:00000AA6o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d1,d4
		addx.b	d7,d6
		bsr	addr_Read
		or.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_19EC:				; DATA XREF: ROM:00000A96o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		or.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1A12:
		clr.w	d5
		move.b	(a0)+,d5
		add.b	d1,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		bsr	addr_Read
		or.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1A3C:
		clr.w	d5
		move.b	(a0)+,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		or.b	d7,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1A6A:				; DATA XREF: ROM:00000B52o
		swap	d3
		move.b	d0,(a2,d3.w)
		subq.b	#1,d3
		swap	d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1A78:				; DATA XREF: ROM:00000A52o
		move.w	d3,d5
		swap	d3
		move.b	d5,(a2,d3.w)
		subq.b	#1,d3
		swap	d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1A88:				; DATA XREF: ROM:00000BD2o
		addi.l	#$10000,d3
		move.l	d3,d5
		swap	d5
		move.b	(a2,d5.w),d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1AA6:				; DATA XREF: ROM:00000AD2o
		swap	d3
		addq.b	#1,d3
		move.b	(a2,d3.w),d5
		swap	d3
		move.b	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1AB6:				; DATA XREF: ROM:00000ADAo
		move	d3,sr
		roxl.b	#1,d0
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1ACA:				; DATA XREF: ROM:00000ACAo
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d7
		move	d3,sr
		roxl.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1AEA:				; DATA XREF: ROM:00000B0Ao
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d1,d6
		move.b	(a2,d6.w),d7
		move	d3,sr
		roxl.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1B0C:				; DATA XREF: ROM:00000AEAo
		move.b	(a0)+,d4
		move.b	(a0)+,d6
		lsl.w	#8,d6
		move.b	d4,d6
		move.b	(a2,d6.w),d7
		move	d3,sr
		roxl.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1B30:				; DATA XREF: ROM:00000B2Ao
		move.b	(a0)+,d4
		move.b	(a0)+,d6
		lsl.w	#8,d6
		move.b	d4,d6
		add.w	d1,d6
		move.b	(a2,d6.w),d7
		move	d3,sr
		roxl.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1B56:				; DATA XREF: ROM:00000BDAo
		move	d3,sr
		roxr.b	#1,d0
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1B6A:				; DATA XREF: ROM:00000BCAo
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d7
		move	d3,sr
		roxr.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1B8A:				; DATA XREF: ROM:00000C0Ao
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d1,d6
		move.b	(a2,d6.w),d7
		move	d3,sr
		roxr.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1BAC:				; DATA XREF: ROM:00000BEAo
		move.b	(a0)+,d4
		move.b	(a0)+,d6
		lsl.w	#8,d6
		move.b	d4,d6
		move.b	(a2,d6.w),d7
		move	d3,sr
		roxr.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1BD0:				; DATA XREF: ROM:00000C2Ao
		move.b	(a0)+,d4
		move.b	(a0)+,d6
		lsl.w	#8,d6
		move.b	d4,d6
		add.w	d1,d6
		move.b	(a2,d6.w),d7
		move	d3,sr
		roxr.b	#1,d7
		move	sr,d5
		andi.w	#$1D,d5
		andi.b	#$E2,d3
		or.w	d5,d3
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------
; $40 - RTI
; 
; NOTE: Interrupt exit
; ----------------------------------------------------------------

loc_1BF6:
		move.w	(sp)+,d3
		movem.l	(sp)+,d4/a0/a5

		move.l	#emuLoop,(RAM_EmuLoop+2).l
		move.w	#0,cpuFamiVint(a4)
		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------
; $60 - RTS
; ----------------------------------------------------------------

loc_1C32:
		swap	d3
		moveq	#0,d6
		addq.b	#1,d3
		move.b	(a2,d3.w),d4
		addq.b	#1,d3
		move.b	(a2,d3.w),d6
		lsl.w	#8,d6
		move.b	d4,d6
		swap	d3
		addq.w	#1,d6
; 		lea	(a2,d6.l),a0

		and.l	#$7FFF,d6
		movea.l a1,a0
		add.l 	d6,a0
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1C52:
		move.b	(a0)+,d7
		eori.b	#$11,d3
		ori.b	#4,d3
		move	d3,sr
		subx.b	d7,d0
		move	sr,d3
		eori.b	#$11,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1C6A:
		clr.w	d6
		move.b	(a0)+,d6
		move.b	(a2,d6.w),d7
		eori.b	#$11,d3
		ori.b	#4,d3
		move	d3,sr
		subx.b	d7,d0
		move	sr,d3
		eori.b	#$11,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1C88:				; DATA XREF: ROM:00000E06o
		clr.w	d6
		move.b	(a0)+,d6
		add.b	d1,d6
		move.b	(a2,d6.w),d7
		eori.b	#$11,d3
		ori.b	#4,d3
		move	d3,sr
		subx.b	d7,d0
		move	sr,d3
		eori.b	#$11,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1CA8:				; DATA XREF: ROM:00000DE6o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		bsr	addr_Read
		eori.b	#$11,d3
		ori.b	#4,d3
		move	d3,sr
		subx.b	d7,d0
		move	sr,d3
		eori.b	#$11,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1CCC:				; DATA XREF: ROM:00000E26o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d1,d4
		addx.b	d7,d6
		bsr	addr_Read
		eori.b	#$11,d3
		ori.b	#4,d3
		move	d3,sr
		subx.b	d7,d0
		move	sr,d3
		eori.b	#$11,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1CF6:				; DATA XREF: ROM:00000E16o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		eori.b	#$11,d3
		ori.b	#4,d3
		move	d3,sr
		subx.b	d7,d0
		move	sr,d3
		eori.b	#$11,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1D20:				; DATA XREF: ROM:00000DB6o
		clr.w	d5
		move.b	(a0)+,d5
		add.b	d1,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		bsr	addr_Read
		eori.b	#$11,d3
		ori.b	#4,d3
		move	d3,sr
		subx.b	d7,d0
		move	sr,d3
		eori.b	#$11,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1D4E:				; DATA XREF: ROM:00000DF6o
		clr.w	d5
		move.b	(a0)+,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		bsr	addr_Read
		eori.b	#$11,d3
		ori.b	#4,d3
		move	d3,sr
		subx.b	d7,d0
		move	sr,d3
		eori.b	#$11,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1D80:
		ori.b	#$11,d3
		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------
; SED - Set Decimal mode
; ----------------------------------------------------------------

loc_1D88:
		move.w	#1,cpuModeDec(a4)
		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------
; SEI - Set Interrupt disable
; ----------------------------------------------------------------

loc_1D92:
		move.w	#1,cpuModeIntDis(a4)
		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------

loc_1D9C:
		clr.w	d4
		move.b	(a0)+,d4
		move.b	d0,(a2,d4.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1DA8:
		clr.w	d4
		move.b	(a0)+,d4
		add.b	d1,d4
		move.b	d0,(a2,d4.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1DB6:				; DATA XREF: ROM:00000C66o
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		move.b	d0,d7
		bra	addr_Write
; ----------------------------------------------------------------
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1DCA:
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d1,d4
		addx.b	d7,d6
		move.b	d0,d7
		bra	addr_Write
; ----------------------------------------------------------------

loc_1DE0:
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		move.b	d0,d7
		bra	addr_Write
; ----------------------------------------------------------------

loc_1DF6:
		clr.w	d5
		move.b	(a0)+,d5
		add.b	d1,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		move.b	d0,d7
		bra	addr_Write
; ----------------------------------------------------------------

loc_1E10:
		clr.w	d5
		move.b	(a0)+,d5
		clr.w	d4
		move.b	(a2,d5.w),d4
		clr.w	d6
		move.b	1(a2,d5.w),d6
		clr.b	d7
		add.b	d2,d4
		addx.b	d7,d6
		move.b	d0,d7
		bra	addr_Write
; ----------------------------------------------------------------

loc_1E2E:
		clr.w	d4
		move.b	(a0)+,d4
		move.b	d1,(a2,d4.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1E3A:
		clr.w	d4
		move.b	(a0)+,d4
		add.b	d2,d4
		move.b	d1,(a2,d4.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1E48:
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		move.b	d1,d7
		bra	addr_Write
; ----------------------------------------------------------------
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1E5C:
		clr.w	d4
		move.b	(a0)+,d4
		move.b	d2,(a2,d4.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1E68:
		clr.w	d4
		move.b	(a0)+,d4
		add.b	d1,d4
		move.b	d2,(a2,d4.w)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1E76:
		clr.w	d4
		move.b	(a0)+,d4
		clr.w	d6
		move.b	(a0)+,d6
		move.b	d2,d7
		bra	addr_Write
; ----------------------------------------------------------------
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1E8A:
		move.b	d0,d1
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1E9C:
		move.b	d0,d2
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1EAE:
		move.l	d3,d5
		swap	d5
		move.b	d5,d1
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1EC4:
		move.b	d1,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1Ed3:				; DATA XREF: ROM:00000C9Ao
		swap	d3
		move.b	d1,d3
		swap	d3
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_1EE0:				; DATA XREF: ROM:00000C92o
		move.b	d2,d0
		move	sr,d5
		andi.w	#$C,d5
		andi.b	#$F3,d3
		or.w	d5,d3
		jmp	(RAM_EmuLoop).l

; ====================================================================
; ----------------------------------------------------------------
; Read request
; 
; d6 - XX00
; d4 - 00XX
; ----------------------------------------------------------------

addr_Read:
		tst.b	d6		; $8000
		bmi	rdFrom_PRG
	; TODO: $6000-$7FFF
		cmp.b	#$40,d6		; $4000
		bge	rdFrom_APU
		cmp.b	#$20,d6		; $2000
		bge	rdFrom_PPU

; ----------------------------------------------------------------

rdFrom_RAM:
		lsl.w	#8,d6
		move.b	d4,d6
		andi.w	#$7FF,d6
		move.b	(a2,d6.w),d7
		rts
; ----------------------------------------------------------------

rdFrom_PRG:
		lsl.w	#8,d6
		move.b	d4,d6
		andi.w	#$7FFF,d6
		move.b	(a1,d6.w),d7
		rts
; ----------------------------------------------------------------

rdFrom_APU:
		cmpi.b	#$1F,d4
		bhi.w	loc_23A6

		cmp.b	#$16,d4		; $4016
		beq.s	APU_Input_1
		cmp.b	#$17,d4		; $4017
		beq.s	APU_Input_2

; ----------------------------------------------------------------

APU_Rd_Null:
		rts

; ----------------------------------------------------------------

loc_23A6:
		move.w	d3,d7
		rts

; ----------------------------------------------------------------

APU_Input_1:
		move.w	cpuInputData(a4),d7
		andi.w	#1,d7
		lsr	cpuInputData(a4)
		rts
; ----------------------------------------------------------------

APU_Input_2:
		move.w	cpuInputData+2(a4),d7
		andi.w	#1,d7
		lsr	cpuInputData+2(a4)
		rts
; ----------------------------------------------------------------

rdFrom_PPU:
		andi.w	#7,d4
		add.w	d4,d4
		move.w	off_23D4(pc,d4.w),d4
		jmp	off_23D4(pc,d4.w)
; ----------------------------------------------------------------
off_23D4:	dc.w loc_23F4-off_23D4		; $2000
		dc.w loc_23F4-off_23D4		; $2001
		dc.w rdPPU_Status-off_23D4	; $2002
		dc.w loc_23F4-off_23D4		; $2003
		dc.w return_241A-off_23D4	; $2004
		dc.w loc_23F4-off_23D4		; $2005
		dc.w loc_23F4-off_23D4		; $2006
		dc.w rdPPU_Data-off_23D4	; $2007
; ----------------------------------------------------------------

loc_23F4:
		move.w	(a1,d3.w),d7
		rts
; ----------------------------------------------------------------

rdPPU_Status:
		move.w	#0,ppuAddrLatch(a4)
		move.w	ppuStatus(a4),d7
		move.w	#0,ppuStatus(a4)

	; sprite 0 beam hit
; 		move.w	ppuSp0Ypos(a4),d4
; 		move.w	8(a6),d5
; 		lsr.w	#8,d5
; 		cmp.b	d5,d4
; 		bcs.s	return_2418
; 		ori.w	#$40,d7
; return_2418:
		move.w	vdpHintSp0(a4),d4
		beq.s	.no_hit
		ori.w	#$40,d7
; 		clr.w	vdpHintSp0(a4)
.no_hit:
		move.w	(vdp_ctrl),d4
		btst	#bitVint,d4
		beq.s	.novflag
		ori.w	#$80,d7
.novflag:
		rts
; ----------------------------------------------------------------

return_241A:				; DATA XREF: ROM:000023E4o
		rts
; ----------------------------------------------------------------

rdPPU_Data:
		move.w	ppuDataLast(a4),d7
		move.w	ppuAddrBase(a4),d4
		move.b	(a3,d4.w),ppuDataLast+1(a4)
		move.w	ppuAddrIncr(a4),d4
		add.w	d4,ppuAddrBase(a4)
		rts

; ====================================================================
; ----------------------------------------------------------------
; Write request
; 
; d6 - XX00
; d4 - 00XX
; ----------------------------------------------------------------

addr_Write:
		tst.b	d6		; $8000
		bmi	wrTo_PRG
	; TODO: $6000-$7FFF
		cmp.b	#$40,d6		; $4000
		bge	wrTo_APU
		cmp.b	#$20,d6		; $2000
		bge	wrTo_PPU

; ====================================================================
; ----------------------------------------------------------------
; WRITE request to RAM
; ----------------------------------------------------------------

wrTo_RAM:
		lsl.w	#8,d6
		move.b	d4,d6
		andi.w	#$7FF,d6
		move.b	d7,(a2,d6.w)
		jmp	(RAM_EmuLoop).l

; ====================================================================
; ----------------------------------------------------------------
; WRITE request to ROM area, mappers
; ----------------------------------------------------------------

wrTo_PRG:
		cmp.w	#3,cpuMapper(a4)
		beq.s	.mapper_3
		jmp	(RAM_EmuLoop).l

; --------------------------------------------------------
; Mapper $03, CNROM
; 
; Bank select ($8000-$FFFF)
; 
; 7  bit  0
; ---- ----
; xxDD xxCC
;   ||   ||
;   ||   ++- Select 8 KB CHR ROM bank for PPU $0000-$1FFF
;   ++------ Security diodes config
; --------------------------------------------------------

.mapper_3:
		move.l	a4,-(sp)
		movea.l	emuChrRom(a4),a5
		and.w	#%11,d7
		lsl.w	#8,d7
		lsl.w	#5,d7
		adda	d7,a5
		move.l	a3,a4
		move.w	#($1FFF/4)-1,d7
.copychr:
		move.l	(a5)+,(a4)+
		dbf	d7,.copychr
		move.l	(sp)+,a4
		bsr	Nemul_LoadChr
		jmp	(RAM_EmuLoop).l

; ====================================================================
; ----------------------------------------------------------------
; WRITE to APU
; ----------------------------------------------------------------

wrTo_APU:
		cmpi.b	#$1F,d4
		bhi.s	APU_Null
		add.w	d4,d4
		move.w	off_2866(pc,d4.w),d4
		jmp	off_2866(pc,d4.w)

; ----------------------------------------------------------------
off_2866:	dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_OAMDMA-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Input-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866
		dc.w APU_Null-off_2866

APU_Null:
		jmp	(RAM_EmuLoop).l

; =============== S U B	R O U T	I N E =======================================


APU_Input:				; DATA XREF: ROM:000028BEo
		tst.b	d7
		beq.s	APU_Null
		bsr	readInput
		jmp	(RAM_EmuLoop).l

; =============== S U B	R O U T	I N E =======================================


readInput:
		move.l	a3,-(sp)
		lea	($A10003).l,a3
		lea	cpuInputData(a4),a5
		bsr	.this_pad
		addq.w	#2,a3
		bsr	.this_pad		
		move.l	(sp)+,a3
		rts
		
.this_pad:
		move.b	#0,(a3)
		nop
		nop
		move.b	(a3),d5
		lsl.b	#2,d5
		andi.b	#$C0,d5
		move.b	#$40,(a3)
		nop
		nop
		move.b	(a3),d4
		andi.b	#$3F,d4
		or.b	d4,d5
		not.b	d5
		clr.w	d4
		lsl.b	#1,d5
		addx.b	d4,d4
		lsl.w	#1,d5
		lsl.b	#1,d5
		addx.b	d4,d4
		lsr.w	#1,d5
		lsl.b	#1,d5
		addx.b	d4,d4
		lsl.b	#1,d5
		addx.b	d4,d4
		or.b	d5,d4
		move.w	d4,(a5)+
		rts


; =============== S U B	R O U T	I N E =======================================


APU_OAMDMA:
		lsl.w	#8,d7
		move.w	ppuOamUnk(a4),d6
		eori.w	#1,d6
		move.b	ppuOamAddr(a4,d6.w),d7
		lea	(a2,d7.w),a5
		move.w	#$8A00,d7
		move.b	(a5),d7
		move.b	d7,ppuSp0Ypos+1(a4)		; sprite 0 ypos
		sub.w	#1,d7
		move.w	d7,4(a6)

		move.l	a3,-(sp)
		lea 	oamSprData(a4),a3
		moveq	#$3F,d5
		moveq	#0,d7
.lp_sprnormal:
		move.b	(a5)+,d7
		move.w	d7,d6
		addi.w	#$79,d6
		move.w	d6,(a3)+
		moveq	#64,d6
		sub.b	d5,d6
		move.w	d6,(a3)+
		move.b	(a5)+,d7
		move.w	d7,d6
		ori.w	#$100,d6
		move.b	(a5)+,d7
		move.w	d7,d4
		rol.b	#2,d4
		lsl.w	#1,d4
		lsl.b	#3,d4
		lsl.w	#7,d4
		or.w	d6,d4
		eori.w	#$8000,d4
		move.w	d4,(a3)+
		move.b	(a5)+,d7
		move.w	d7,d6
		addi.w	#$80,d6
		move.w	d6,(a3)+
		dbf	d5,.lp_sprnormal
		move.l	(sp)+,a3

		jmp	(RAM_EmuLoop).l


; =============== S U B	R O U T	I N E =======================================


wrTo_PPU:
		andi.w	#7,d4
		add.w	d4,d4
		move.w	off_29F6(pc,d4.w),d4
		jmp	off_29F6(pc,d4.w)

; ----------------------------------------------------------------
off_29F6:	dc.w loc_2A16-off_29F6 ; $2000
		dc.w loc_2A5E-off_29F6 ; $2001
		dc.w loc_2ACC-off_29F6 ; $2002
		dc.w loc_2AD0-off_29F6 ; $2003
		dc.w loc_2AE2-off_29F6 ; $2004
		dc.w wrPPU_Scroll-off_29F6 ; $2005
		dc.w loc_2AE6-off_29F6 ; $2006
		dc.w wrPPU_Data-off_29F6 ; $2007
; ----------------------------------------------------------------

loc_2A16:

	; NMI on/off
		clr.w	d6
		lsl.b	#1,d7			; $80
		bcc.s	.noVintFlag
		move.b	#$80,d6			; NMI ON
.noVintFlag:
		move.w	d6,ppuNmiFlag(a4)
		
	; 8x8 or 8x16 sprites
		clr.w	d6
		lsl.b	#2,d7
		bcc.s	loc_2A2C
		moveq	#1,d6
loc_2A2C:
		move.w	d6,ppuSprWide(a4)
		
	; PPU VRAM BG bank/Sprites bank
		move.b	d7,d6
		andi.w	#$C0,d6
		cmp.w	ppuChrBank(a4),d6
		beq.s	.no_reload
		move.w	d6,ppuChrBank(a4)
		bsr	Nemul_LoadChr
.no_reload:

	; PPU VRAM increment
		moveq	#1,d6
		lsl.b	#3,d7
		bcc.s	.nrml_incr
		moveq	#$20,d6
.nrml_incr:
		move.w	d6,ppuAddrIncr(a4)

	; PPU Name table base
		andi.w	#$C0,d7
		move.w	d7,ppuNTblBase(a4)
		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------
; $2002 - PPU MASK
; ----------------------------------------------------------------

loc_2A5E:
		move.w	#$8500+(($A000)>>9),d6
		swap	d6
		move.w	vdpReg01(a4),d6		; REGISTER 81
		and.b	#$BF,d6
		btst	#3,d7
		beq.s	.hidebg
		ori.b	#$40,d6
.hidebg:
		swap	d6
		btst	#4,d7
		beq.s	.hidesp
		move.w	#$8500+(($BC00)>>9),d6
.hidesp:
		move.l	d6,4(a6)
		swap	d6
		move.w	d6,vdpReg01(a4)

		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------
; $2005 - PPU SCROLL
; -----------------------------------------------------------------

wrPPU_Scroll:
		move.w	ppuNTblBase(a4),d6
		eori.w	#1,ppuAddrLatch(a4)
		beq.s	loc_2AA4
		
		andi.w	#$FF,d7
		and.w	#1,d6
		lsl.w	#8,d6
		add.w	d6,d7
		neg.w	d7
		move.w	d7,vdpScrlX(a4)
		move.w	d7,vdpScrlX+2(a4)
		jmp	(RAM_EmuLoop).l

; --------------------------------------------------------
; Vertical
; --------------------------------------------------------

loc_2AA4:
		and.w	#$FF,d7
		addq.w	#8,d7
		lsl.b	#1,d6
		bcs.s	loc_2ABE
		move.w	d7,vdpScrlY(a4)
		add.w	#$110,d7
		move.w	d7,vdpScrlY+2(a4)
		jmp	(RAM_EmuLoop).l
loc_2ABE:
		move.w	d7,vdpScrlY+2(a4)
		add.w	#$110,d7
		move.w	d7,vdpScrlY(a4)
		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------

loc_2ACC:				; DATA XREF: ROM:000029FEo
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_2AD0:
		move.w	ppuOamUnk(a4),d4
		move.b	d7,ppuOamAddr(a4,d4.w)
		eori.w	#1,ppuOamUnk(a4)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_2AE2:
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

loc_2AE6:
		move.w	ppuAddrLatch(a4),d4
		move.b	d7,ppuAddrBase(a4,d4.w)
		eori.w	#1,ppuAddrLatch(a4)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

wrPPU_Data:
		move.w	ppuAddrBase(a4),d4
		move.w	ppuAddrIncr(a4),d6
		add.w	d6,ppuAddrBase(a4)
		andi.w	#$3FFF,d4
		move.b	d7,(a3,d4.w)
		cmpi.w	#$3F00,d4
		bcc.s	ppuSetColor
		move.w	d4,d5
		andi.w	#$3C0,d5
		cmpi.w	#$3C0,d5
		bne.w	ppuDrwCell
		bra.w	ppuDrwCellPal
; ----------------------------------------------------------------

ppuVdpIndex:
		dc.w $0000,$0002,$0004,$0006
		dc.w $0020,$0022,$0024,$0026
		dc.w $0040,$0042,$0044,$0046
		dc.w $0060,$0062,$0064,$0066
		dc.w $0008,$000A,$000C,$000E
		dc.w $0028,$002A,$002C,$002E
		dc.w $0048,$004A,$004C,$004E
		dc.w $0068,$006A,$006C,$006E
		align 2

ppuSetColor:
		andi.w	#$1F,d4
		add.w	d4,d4
		move.w	ppuVdpIndex(pc,d4.w),d4
		lea 	vdpPalette(a4,d4.w),a5
		andi.b	#$3F,d7
		add.w	d7,d7
		move.w	ppuVdpColors(pc,d7.w),(a5)
		lea	(RAM_Fami_Emu+vdpPalette),a5
; 		move.w	$08(a5),$00(a5)
; 		move.w	$28(a5),$20(a5)	
; 		move.w	$38(a5),$30(a5)
; 		move.w	$48(a5),$40(a5)
		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------

ppuVdpColors:	dc.w $666
		dc.w $820
		dc.w $A00
		dc.w $A04
		dc.w $806
		dc.w $406
		dc.w 6
		dc.w $26
		dc.w $44
		dc.w $40
		dc.w $60
		dc.w $40
		dc.w $440
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w $AAA
		dc.w $E60
		dc.w $E40
		dc.w $E28
		dc.w $C2A
		dc.w $82C
		dc.w $24C
		dc.w $4A
		dc.w $66
		dc.w $84
		dc.w $A0
		dc.w $480
		dc.w $880
		dc.w 0
		dc.w 0
		dc.w 0
		dc.w $EEE
		dc.w $EC6
		dc.w $EAA
		dc.w $E8C
		dc.w $E6E
		dc.w $C6E
		dc.w $88E
		dc.w $2AE
		dc.w $CC
		dc.w $E8
		dc.w $4E6
		dc.w $8E4
		dc.w $EC4
		dc.w $444
		dc.w 0
		dc.w 0
		dc.w $EEE
		dc.w $EEC
		dc.w $ECC
		dc.w $ECE
		dc.w $ECE
		dc.w $ECE
		dc.w $CCE
		dc.w $AEE
		dc.w $8EE
		dc.w $AEC
		dc.w $8EC
		dc.w $CEC
		dc.w $EEC
		dc.w $CCC
		dc.w 0
		dc.w 0
; ----------------------------------------------------------------

ppuDrwCell:
	; d4 - ppu address
	; d7 - cell 0-255

; 	; d4 - X pos
; 	; d5 - Y pos
; 	; d7 - Page


		and.w	#$FF,d7
		move.w	d4,d5
		move.w	d4,d6
		and.w	#$1F,d5
		and.w	#$3E0,d6
		add.w	d5,d5
		lsl.w	#2,d6
		add.w	d5,d6

		move.w	d4,d5
		lsr.w	#8,d5
		lsr.w	#2,d5
		btst	#1,d5
		beq.s	.top_lyr
		add.w	#$2000,d6
.top_lyr:
		btst	#0,d5
		beq.s	.left_pg
		add.w	#$40,d6
.left_pg:
		or.w	#$8000,d7
		or.w	#$4000,d6
; 		move.w	#$2700,sr
		move.w	d6,4(a6)
		move.w	#3,4(a6)
		move.w	d7,(a6)
		tst.w	ppuMirror(a4)			; horizontal mirror check
		bne.s	.vermirror
		move.w	d6,d5	
		add.w	#$40,d6
		and.w	#$40,d6
		and.w	#$FFBF,d5
		or.w	d5,d6
		move.w	d6,4(a6)
		move.w	#3,4(a6)
		move.w	d7,(a6)
; 		move.w	#$2000,sr
		jmp	(RAM_EmuLoop).l
.vermirror:
		and.w	#$3FFF,d6
		add.w	#$2000,d6
		or.w	#$4000,d6
		move.w	d6,4(a6)
		move.w	#3,4(a6)
		move.w	d7,(a6)
; 		move.w	#$2000,sr
		jmp	(RAM_EmuLoop).l

; ----------------------------------------------------------------

ppuDrwCellPal:
		jmp	(RAM_EmuLoop).l

; 		move.w	#$8F02,4(a6)
; 		andi.w	#$FFF,d4
; 		lsl.w	#1,d4
; 		move.l	d3,-(sp)
; 		lea	(word_2D8E).l,a5
; 		move.w	(a5,d4.w),d3
; 		lsl.w	#1,d4
; 		lea	(dword_4D8E).l,a5
; 		move.l	(a5,d4.w),d5
; 		swap	d7
; 		andi.w	#$FFC,d4
; 		cmpi.w	#$FE0,d4
; 		bcc.w	loc_2C9A
; 		clr.w	d7
; 		lsr.l	#2,d7
; 		lsr.w	#1,d7
; 		ori.w	#$8000,d7
; 		move.w	d7,d6
; 		move.b	1(a2,d3.w),d6
; 		swap	d6
; 		move.w	d7,d6
; 		move.b	3(a2,d3.w),d6
; 		clr.w	d7
; 		lsr.l	#2,d7
; 		lsr.w	#1,d7
; 		ori.w	#$8000,d7
; 		move.w	d7,d4
; 		move.b	5(a2,d3.w),d4
; 		swap	d4
; 		move.w	d7,d4
; 		move.b	7(a2,d3.w),d4
; 		move.l	d6,(a2,d3.w)
; 		move.l	d4,4(a2,d3.w)
; 		move.l	d5,4(a6)
; 		move.l	d6,(a6)
; 		move.l	d4,(a6)
; 		addi.w	#$80,d3
; 		addi.l	#$800000,d5
; 		move.b	1(a2,d3.w),d6
; 		swap	d6
; 		move.b	3(a2,d3.w),d6
; 		move.b	5(a2,d3.w),d4
; 		swap	d4
; 		move.b	7(a2,d3.w),d4
; 		move.l	d6,(a2,d3.w)
; 		move.l	d4,4(a2,d3.w)
; 		move.l	d5,4(a6)
; 		move.l	d6,(a6)
; 		move.l	d4,(a6)
; 		addi.w	#$80,d3
; 		addi.l	#$800000,d5
; loc_2C9A:
; 		clr.w	d7
; 		lsr.l	#2,d7
; 		lsr.w	#1,d7
; 		ori.w	#$8000,d7
; 		move.w	d7,d6
; 		move.b	1(a2,d3.w),d6
; 		swap	d6
; 		move.w	d7,d6
; 		move.b	3(a2,d3.w),d6
; 		clr.w	d7
; 		lsr.l	#2,d7
; 		lsr.w	#1,d7
; 		ori.w	#$8000,d7
; 		move.w	d7,d4
; 		move.b	5(a2,d3.w),d4
; 		swap	d4
; 		move.w	d7,d4
; 		move.b	7(a2,d3.w),d4
; 		move.l	d6,(a2,d3.w)
; 		move.l	d4,4(a2,d3.w)
; 		move.l	d5,4(a6)
; 		move.l	d6,(a6)
; 		move.l	d4,(a6)
; 		addi.w	#$80,d3
; 		addi.l	#$800000,d5
; 		move.b	1(a2,d3.w),d6
; 		swap	d6
; 		move.b	3(a2,d3.w),d6
; 		move.b	5(a2,d3.w),d4
; 		swap	d4
; 		move.b	7(a2,d3.w),d4
; 		move.l	d6,(a2,d3.w)
; 		move.l	d4,4(a2,d3.w)
; 		move.l	d5,4(a6)
; 		move.l	d6,(a6)
; 		move.l	d4,(a6)
; 		move.l	(sp)+,d3
; 		jmp	(RAM_EmuLoop).l
; ----------------------------------------------------------------


; =============== S U B	R O U T	I N E =======================================


romGrabPrg:
		lea	$10(a0),a4
		cmpi.b	#1,d7
		beq.w	loc_29C0
		cmpi.b	#2,d7
		beq.w	loc_29D8
		trap	#2
; ----------------------------------------------------------------
loc_29C0:
		lea	(RAM_Fami_ROM).l,a5
		lea	(RAM_Fami_ROM+$4000).l,a3
		move.l	#$FFF,d7
.rom_1:
		move.l	(a4)+,d3
		move.l	d3,(a5)+
		move.l	d3,(a3)+
		dbf	d7,.rom_1
		rts
; ----------------------------------------------------------------

loc_29D8:
		lea	(RAM_Fami_ROM).l,a5
		move.l	#$1FFF,d7
loc_29E2:
		move.l	(a4)+,(a5)+
		dbf	d7,loc_29E2
		rts

; =============== S U B	R O U T	I N E =======================================


Nemul_LoadChr:
		move.w	#$2700,sr
		move.w	#$8F02,4(a6)
		move.l	#$40000000,4(a6)
		moveq	#0,d5
		move.w	ppuChrBank(a4),d6
		bsr.w	.make_chr
		moveq	#4,d5
		move.w	ppuChrBank(a4),d6
		lsl.b	#1,d6
		bsr.w	.make_chr
		move.w	#$2000,sr
		rts

.make_chr:
		movea.l	a3,a5
		lsl.b	#1,d6
		bcc.s	loc_8DBA
		adda.l	#$1000,a5
loc_8DBA:
		movem.l	d0-d2/d3-d7,-(sp)
		move.l	#$FF,d7
loc_8DC4:
		moveq	#7,d3
loc_8DC6:
		move.b	(a5),d1
		move.b	8(a5),d2
		moveq	#0,d0
		moveq	#7,d6
loc_8DD0:
		add.b	d2,d2
		addx.w	d0,d0
		add.b	d1,d1
		addx.w	d0,d0
		dbf	d6,loc_8DD0
		moveq	#0,d4
		moveq	#7,d6
loc_8DE0:
		move.b	d0,d1
		lsr.w	#2,d0
		andi.l	#3,d1
		beq.s	loc_8DEE
		or.b	d5,d1
loc_8DEE:
		or.b	d1,d4
		ror.l	#4,d4
		dbf	d6,loc_8DE0
		move.l	d4,(a6)
		addq.l	#1,a5
		dbf	d3,loc_8DC6
		addq.l	#8,a5
		dbf	d7,loc_8DC4
		movem.l	(sp)+,d0-d2/d3-d7
return_8E08:
		rts

; ====================================================================

		align $8000
EndOfRom:

; ====================================================================
; ----------------------------------------------------------------
; ROM are here
; ----------------------------------------------------------------

ROM_FILE:	binclude "roms/paperboy.nes"
