; ====================================================================
; ----------------------------------------------------------------
; MD Video
; ----------------------------------------------------------------

; ASSEMBLER FLAGS USED:
; MCD  - Mega CD
; MARS - 32X

; --------------------------------------------------------
; Init Video
; 
; Uses:
; a0-a2,d0-d1
; --------------------------------------------------------

Video_Init:		
		lea	(RAM_MdVideo),a0	; Clear RAM
		moveq	#0,d0
		move.w	#(sizeof_mdvid-RAM_MdVideo)-1,d1
.clrram:
		move.b	d0,(a0)+
		dbf	d1,.clrram

		lea	list_vdpregs(pc),a0	; Init registers
		lea	(RAM_VdpRegs).w,a1
		lea	(vdp_ctrl),a2
		move.w	#$8000,d0
		move.w	#19-1,d1
.loop:
		move.b	(a0)+,d0
		move.b	d0,(a1)+
		move.w	d0,(a2)
		add.w	#$100,d0
		dbf	d1,.loop
.exit:

	; 32X ONLY:
	; Transfer DMA tasks to RAM
	if MARS
		lea	Video_RamCode(pc),a0
		lea	(RAM_ExRamSub).w,a1
		move.w	#((Video_RamCode_e-Video_RamCode)/2)-1,d0
.copy:
		move.w	(a0)+,d1
		move.w	d1,(a1)+
		dbf	d0,.copy
	endif

	; Debug print init
	; VRAM and Font data
		move.l	#ASCII_FONT,d0
		move.w	#ASCII_FONT_e-ASCII_FONT,d1
		move.w	#$580|$6000,d2
		move.w	d2,(RAM_VidPrntVram).w
		bra	Video_LoadArt
		
; ====================================================================
; ----------------------------------------------------------------
; Video subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Video_Clear
; 
; Clear all video data
; --------------------------------------------------------

Video_Clear:
		move.w	#0,d0			; Clear until $57F
		move.w	#$57F*$20,d1
		move.w	#0,d2
		bsr	Video_Fill
		move.w	#$FFF,d1		; FG/BG size
		move.b	(RAM_VdpRegs+2).l,d2	; FG
		andi.w	#%111000,d2
		lsl.w	#8,d2
		lsl.w	#2,d2
		bsr	Video_Fill
		move.b	(RAM_VdpRegs+3).l,d2	; BG
		andi.w	#%000111,d2
		lsl.w	#8,d2
		lsl.w	#5,d2
		bsr	Video_Fill	
		move.w	#$FFF,d1		; WD Size
		move.b	(RAM_VdpRegs+4).l,d2	; Window
		andi.w	#%111110,d2
		lsl.w	#8,d2
		lsl.w	#2,d2
		bra	Video_Fill
		
; ---------------------------------
; Video_Update
; 
; Update registers below $91
; 
; Uses:
; d4-d5,a4-a5
; ---------------------------------

Video_Update:
		lea	(RAM_VdpRegs).w,a4
		lea	(vdp_ctrl),a5
		move.w	#$8000,d4
		move.w	#17-1,d5
.loop:
		move.b	(a4)+,d4
		move.w	d4,(a5)
		add.w	#$100,d4
		dbf	d5,.loop
.exit:
		rts
		
; --------------------------------------------------------
; Video_LoadPal
; 
; Load palette to VDP
; 
; a0 - Palette data
; d0 - Start at
; d1 - Num of colors - 1
; 
; Uses:
; a4,d4
; --------------------------------------------------------

Video_LoadPal:
		lea	(vdp_data),a4
		moveq	#0,d4
		move.w	d0,d4
		add.w	d4,d4
		ori.w	#$C000,d4
		swap	d4
		move.l	d4,4(a4)
		move.w	d1,d4
.outv: 		move.w	4(a4),d5
		btst	#bitVint,d5
		beq.s	.outv
.loop:
		move.w	(a0)+,(a4)
		dbf	d4,.loop
		rts
		
; --------------------------------------------------------
; Video_LoadMap
; 
; Load map data, Horizontal order
; 
; a0 - Map data
; d0 | LONG - 00|Layer|X|Y, locate(lyr,x,y)  
; d1 | LONG - Width|Height (cells),  mapsize(x,y)
; d2 | WORD - VRAM

; Uses:
; a4-a5,d4-d7
; --------------------------------------------------------

Video_LoadMap:
		lea	(vdp_data),a4
		bsr	vid_PickLayer
		
	; Start here
		move.w	d1,d5
.yloop:
		swap	d5
		move.l	d4,4(a4)
		move.l	d1,d7
		swap	d7
.xloop:
		move.w	(a0)+,d5
		cmp.w	#-1,d5
		bne.s	.nonull
		move.w	#varNullVram,d5
		bra.s	.cont
.nonull:
		add.w	d2,d5
.cont:
		swap	d7
		move.b	(RAM_VdpRegs+$C).l,d7
		and.w	#%110,d7
		cmp.w	#%110,d7
		bne.s	.nodble
		move.w	d5,d7
		lsr.w	#1,d7
		and.w	#$7FF,d7
		and.w	#$F800,d5
		or.w	d7,d5
.nodble:
		swap	d7
		move.w	d5,(a4)
		dbf	d7,.xloop
		add.l	d6,d4
		swap	d5
		dbf	d5,.yloop
		rts

; --------------------------------------------------------
; Video_LoadMap_Vert
; 
; Load map data, Vertical order
; 
; a0 - Map data
; d0 | LONG - 00|Lyr|X|Y,  locate(lyr,x,y)
; d1 | LONG - Width|Height (cells),  mapsize(x,y)
; d2 | WORD - VRAM

; Uses:
; a4-a5,d4-d7
; --------------------------------------------------------

Video_LoadMap_Vert:
		lea	(vdp_data),a4
		bsr	vid_PickLayer
		
	; Start here
		move.l	d1,d5
		swap	d5
.xloop:
		swap	d5
		move.l	d4,-(sp)
		move.w	d1,d7
		btst	#2,(RAM_VdpRegs+$C).l
		beq.s	.yloop
		lsr.w	#1,d7
.yloop:
		move.l	d4,4(a4)
		move.w	(a0),d5
		cmp.w	#-1,d5
		bne.s	.nonull
		move.w	#varNullVram,d5
		bra.s	.cont
.nonull:
		add.w	d2,d5
.cont:
		swap	d7
		adda	#2,a0
		btst	#2,(RAM_VdpRegs+$C).l
		beq.s	.nodble
		adda	#2,a0
		move.w	d5,d7
		lsr.w	#1,d7
		and.w	#$7FF,d7
		and.w	#$F800,d5
		or.w	d7,d5
.nodble:
		swap	d7
		move.w	d5,(a4)
		add.l	d6,d4
		dbf	d7,.yloop
.outdbl:
		move.l	(sp)+,d4
		add.l	#$20000,d4
		swap	d5
		dbf	d5,.xloop
		rts
		
; --------------------------------------------------------
; Video_AutoMap_Vert
; 
; Make automatic map, Vertical order
; 
; MCD: Use this to make a virtual screen
; for Stamps
; 
; d0 | LONG - 00|Lyr|X|Y,  locate(lyr,x,y)
; d1 | LONG - Width|Height (cells),  mapsize(x,y)
; d2 | WORD - VRAM

; Uses:
; a4-a5,d4-d7
; --------------------------------------------------------

; TODO: double interlace

Video_AutoMap_Vert:
		lea	(vdp_data),a4
		bsr	vid_PickLayer
		
	; Start here
		move.w	d2,d7
		move.l	d1,d5
		swap	d5
.xloop:
		swap	d5
		move.l	d4,-(sp)
		move.w	d1,d5
		btst	#2,(RAM_VdpRegs+$C).l
		beq.s	.yloop
		lsr.w	#1,d5
.yloop:
		move.l	d4,4(a4)
		move.w	d7,(a4)
		add.w	#1,d7
		add.l	d6,d4
		dbf	d5,.yloop

		move.l	(sp)+,d4
		add.l	#$20000,d4
		swap	d5
		dbf	d5,.xloop
		rts
		
; --------------------------------------------------------
; Video_Print
; 
; Prints string to layer
; requires ASCII font
; 
; a0 - string data
; d0 | LONG - 00|Lyr|X|Y, locate(lyr,x,y)
; 
; Notes:
; "//b" - Show BYTE value
; "//w" - Show WORD value
; "//l" - Show LONG value
;   $0A - Next line
;   $00 - End of line
; 
; Uses:
; a4-a6,d4-d7
; --------------------------------------------------------

Video_Print:
; 		movem.l	d3-d7,-(sp)
; 		movem.l	a4-a6,-(sp)
		
		lea	(vdp_data),a6
		bsr	vid_PickLayer
		lea	(RAM_VidPrntList),a5
.newjump:
		move.l	d4,4(a6)
		move.l	d4,d5
.loop:
		move.b	(a0)+,d7
		beq	.exit
		cmpi.b	#$A,d7			; $A - next line?
		beq.s	.next
		cmpi.b	#$5C,d7			; $27 ("\") special?
		beq.s	.special
		andi.w	#$FF,d7
.puttext:
		add.w	(RAM_VidPrntVram).w,d7	; VRAM add
		move.w	d7,(a6)
		add.l	#$20000,d5
		bra.s	.loop
; Next line
.next:
		add.l	d6,d4
		bra.s	.newjump

; Specials
.special:
		move.b	(a0)+,d7
		cmpi.b	#"b",d7
		beq.s	.isbyte
		cmpi.b	#"w",d7
		beq.s	.isword
		cmpi.b	#"l",d7
		beq.s	.islong
		move.w	#"\\",d7			; nothing to do
		bra.s	.puttext
		
	; TEMPORAL VALUES
.isbyte:
		move.l	d5,(a5)+
		move.w	#1,(a5)+
		add.l	#$40000,d5
		move.l	d5,4(a6)
		bra	.loop
.isword:
		move.l	d5,(a5)+
		move.w	#2,(a5)+
		add.l	#$80000,d5
		move.l	d5,4(a6)
		bra	.loop
.islong:
		move.l	d5,(a5)+
		move.w	#3,(a5)+
		add.l	#$100000,d5
		move.l	d5,4(a6)
		bra	.loop
.exit:

; --------------------------------------------------------
; Print values
; 
; vvvv vvvv tttt
; v - vdp pos
; t - value type
; --------------------------------------------------------

		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		lea	(RAM_VidPrntList),a5
.nextv:
		tst.l	(a5)
		beq	.nothing

	; grab value
		moveq	#0,d4
		move.b	(a0)+,d4
		rol.l	#8,d4
		move.b	(a0)+,d4
		rol.l	#8,d4
		move.b	(a0)+,d4
		rol.l	#8,d4
		move.b	(a0)+,d4
		movea.l	d4,a4
		moveq	#0,d4

	; get value
		move.w	4(a5),d6
		
		cmp.w	#1,d6		; byte?
		bne.s	.vbyte
		move.b	(a4),d4
		move.l	(a5),4(a6)
		rol.b	#4,d4
		bsr.s	.donibl
		rol.b	#4,d4
		bsr.s	.donibl
.vbyte:
		cmp.w	#2,d6		; word?
		bne.s	.vword
		move.b	(a4),d4
		rol.w	#8,d4
		move.b	1(a4),d4
		move.l	(a5),4(a6)
		rol.w	#4,d4
		bsr.s	.donibl
		rol.w	#4,d4
		bsr.s	.donibl
		rol.w	#4,d4
		bsr.s	.donibl
		rol.w	#4,d4
		bsr.s	.donibl
.vword:
		cmp.w	#3,d6		; long?
		bne.s	.vlong
		move.b	(a4),d4
		rol.l	#8,d4
		move.b	1(a4),d4
		rol.l	#8,d4
		move.b	2(a4),d4
		rol.l	#8,d4
		move.b	3(a4),d4
		move.l	(a5),4(a6)
		move.w	#7,d6
.lngloop:	rol.l	#4,d4
		bsr.s	.donibl
		dbf	d6,.lngloop
.vlong:
		clr.l	(a5)+
		clr.w	(a5)+
		bra	.nextv

; make nibble byte
.donibl:
		move.w	d4,d5
		andi.w	#%1111,d5
		cmp.b	#$A,d5
		blt.s	.lowr
		add.b	#7,d5
.lowr:
		add.w	#"0",d5
		add.w	(RAM_VidPrntVram),d5
		move.w	d5,(a6)
		rts
; exit
.nothing:
; 		movem.l	(sp)+,a4-a6
; 		movem.l	(sp)+,d3-d7
		rts

; --------------------------------------------------------
; Shared: pick layer / x pos / y pos and set size
; --------------------------------------------------------

vid_PickLayer:
	; Pick layer
		move.l	d0,d6
		swap	d6
		btst	#0,d6
		beq.s	.plawnd
		move.b	(RAM_VdpRegs+4).l,d4	; BG
		move.w	d4,d5
		lsr.w	#1,d5
		andi.w	#%11,d5
		swap	d4
		move.w	d5,d4
		swap	d4
		andi.w	#1,d4
		lsl.w	#8,d4
		lsl.w	#5,d4
		bra.s	.golyr
.plawnd:
		move.b	(RAM_VdpRegs+2).l,d4	; FG
		btst	#1,d6
		beq.s	.nowd
		move.b	(RAM_VdpRegs+3).l,d4	; WINDOW
.nowd:		
		move.w	d4,d5
		lsr.w	#4,d5
		andi.w	#%11,d5
		swap	d4
		move.w	d5,d4
		swap	d4
		andi.w	#%00001110,d4
		lsl.w	#8,d4
		lsl.w	#2,d4
.golyr:
		ori.w	#$4000,d4
		move.w	d0,d5			; Y start pos
		andi.w	#$FF,d5			; Y only
		lsl.w	#6,d5			
		move.b	(RAM_VdpRegs+$10).w,d6
		andi.w	#%11,d6
		beq.s	.thissz
		add.w	d5,d5			; H64
		andi.w	#%10,d6
		beq.s	.thissz
		add.w	d5,d5			; H128		
.thissz:
		add.w	d5,d4
		move.w	d0,d5
		andi.w	#$FF00,d5		; X only
		lsr.w	#7,d5
		add.w	d5,d4			; X add
		swap	d4
		moveq	#0,d6
		move.w	#$40,d6			; Set jump size
		move.b	(RAM_VdpRegs+$10).w,d5
		andi.w	#%11,d5
		beq.s	.thisszj
		add.w	d6,d6			; H64
		andi.w	#%10,d5
		beq.s	.thisszj
		add.w	d6,d6			; H128		
.thisszj:
		swap	d6
		rts
		
; --------------------------------------------------------
; Video_Fill
; 
; Fill data to VRAM
;
; d0 | WORD - Fill data
; d1 | WORD - Size
; d2 | WORD - VRAM
; --------------------------------------------------------

Video_Fill:
		lea	(vdp_ctrl),a4
		
		move.w	#$8100,d4
		move.b	(RAM_VdpRegs+1),d4
		bset	#bitDmaEnbl,d4
		move.w	d4,(a4)
.dmaw:		move.w	(a4),d4
		btst	#bitDma,d4
		bne.s	.dmaw
		move.w	#$8F01,(a4)		; Increment $01

	; SIZE
		move.w	d1,d4
		move.l	#$94009300,d5
		lsr.w	#1,d4
		move.b	d4,d5
		swap	d5
		lsr.w	#8,d4
		move.b	d4,d5
		swap	d5
		move.l	d5,(a4)
		move.w	#$9780,(a4)		; DMA Fill bit

	; DESTINATION
		move.l	d2,d4
; 		lsl.w	#5,d4
		move.w	d4,d5
		andi.w	#$3FFF,d5
		ori.w	#$4000,d5
		swap	d5
		move.w	d4,d5
		lsr.w	#8,d5
		lsr.w	#6,d5
		andi.w	#%11,d5
		ori.w	#$80,d5
		move.l	d5,(a4)
		move.w	d0,-4(a4)
.dmawe:		move.w	(a4),d4
		btst	#bitDma,d4
		bne.s	.dmawe

		move.w	#$8F02,(a4)		; Increment $02
		move.w	#$8100,d4
		move.b	(RAM_VdpRegs+1),d4
		move.w	d4,(a4)
		rts

; --------------------------------------------------------
; Video_Copy
; 
; Copy VRAM data to another location
;
; d0 | WORD - VRAM Source
; d1 | WORD - Size
; d2 | WORD - VRAM Destination
; --------------------------------------------------------

Video_Copy:
		lea	(vdp_ctrl),a4
		
		move.w	#$8100,d4
		move.b	(RAM_VdpRegs+1),d4
		bset	#bitDmaEnbl,d4
		move.w	d4,(a4)
.dmaw:		move.w	(a4),d4
		btst	#bitDma,d4
		bne.s	.dmaw
		move.w	#$8F01,(a4)		; Increment $01

	; SIZE
		move.w	d1,d4
		move.l	#$94009300,d5
		lsr.w	#1,d4
		move.b	d4,d5
		swap	d5
		lsr.w	#8,d4
		move.b	d4,d5
		swap	d5
		move.l	d5,(a4)
	
	; SOURCE
		move.l	#$96009500,d5
		move.w	d0,d4
		move.b	d4,d5
		swap	d5
		lsr.w	#8,d4
		move.b	d4,d5
		move.l	d5,(a4)
		move.w	#$97C0,(a4)		; DMA Fill bit
		
	; DESTINATION
		move.l	d2,d4
; 		lsl.w	#5,d4
		move.w	d4,d5
		andi.w	#$3FFF,d5
		ori.w	#$4000,d5
		swap	d5
		move.w	d4,d5
		lsr.w	#8,d5
		lsr.w	#6,d5
		andi.w	#%11,d5
		ori.w	#$C0,d5
		move.l	d5,(a4)
		move.w	d0,-4(a4)
.dmawe:		move.w	(a4),d4
		btst	#bitDma,d4
		bne.s	.dmawe

		move.w	#$8F02,(a4)		; Increment $02
		move.w	#$8100,d4
		move.b	(RAM_VdpRegs+1),d4
		move.w	d4,(a4)
		rts

; --------------------------------------------------------
; Video_LoadArt
; 
; notes below
; --------------------------------------------------------

Video_LoadArt:
		bra	VidExt_LoadArt
.mars:
	; MARS
		jmp	(Video_RamCode).l	; (first routine)

; ====================================================================
; --------------------------------------------------------
; These subroutines will be stored on
; RAM if using 32X
; --------------------------------------------------------

Video_RamCode:
		
; --------------------------------------------------------
; VidRam_LoadArt
; 
; Load art using DMA
;
; d0 | LONG - Art data
; d1 | WORD - Size
; d2 | WORD - VRAM (cell)
; 
; Uses:
; d4-d5,a4
; 
; *HARDWARE NOTES*
; MCD: WORDRAM source data must be incremented by 2 bytes
;      also the first WORD write might get lost
; 
; 32X: RV bit must be set before starting DMA
; --------------------------------------------------------

VidExt_LoadArt:
		lea	(vdp_ctrl),a4

		move.w	#$8100,d4
		move.b	(RAM_VdpRegs+1),d4
		bset	#bitDmaEnbl,d4
		move.w	d4,(a4)

	; SIZE
		move.w	d1,d4
		move.l	#$94009300,d5
		lsr.w	#1,d4
		move.b	d4,d5
		swap	d5
		lsr.w	#8,d4
		move.b	d4,d5
		swap	d5
		move.l	d5,(a4)

	; SOURCE
		move.l	d0,d4
	if MCD
		cmp.l	#syscd_wordram,d4		; below WRAM
		blt.s	.exclude
		cmp.l	#syscd_wordram+$3FFFF,d4	; over WRAM
		bge.s	.exclude
		add.l	#2,d4
.exclude:
	endif
  		lsr.l	#1,d4
 		move.l	#$96009500,d5
 		move.b	d4,d5
 		lsr.l	#8,d4
 		swap	d5
 		move.b	d4,d5
 		move.l	d5,(a4)
 		move.w	#$9700,d5
 		lsr.l	#8,d4
 		move.b	d4,d5
 		move.w	d5,(a4)
 		
	; DESTINATION
		move.w	d2,d4
		and.w	#$7FF,d4
		lsl.w	#5,d4
		move.w	d4,d5
		and.l	#$3FE0,d4
		ori.w	#$4000,d4
		move.w	d4,(a4)			; First write
		move.w	#$0100,(z80_bus).l	; Stop Z80
		lsr.w	#8,d5
		lsr.w	#6,d5
		andi.w	#%11,d5
		ori.w	#$80,d5
.wait:
		btst	#0,(z80_bus).l		; Wait for it
		bne.s	.wait
 		move.w	d5,-(sp)
		move.w	(sp)+,(a4)		; Second
		move.w	#0,(z80_bus).l

; 	if MCD
; 		swap	d4			; MCD: failsafe
; 		move.w	d5,d4
; 		and.w	#$FF7F,d4		; Clear DMA bit
; 		move.l	a5,-(sp)		; Save a5 if needed
; 		movea.l	d0,a5
; 		move.l	d4,(a4)
; 		move.l	(a5),-(a4)
; 		move.l	(sp)+,a5
; 	endif
	
		move.w	#$8100,d4
		move.b	(RAM_VdpRegs+1),d4
		move.w	d4,(a4)
		rts

; --------------------------------------------------------

Video_RamCode_e:
		align 2

; ====================================================================
; --------------------------------------------------------
; Video data
; --------------------------------------------------------

list_vdpregs:
		dc.b $04			; HBlank int off, HV Counter on
		dc.b $44			; Display ON, VBlank int off
		dc.b (($C000)>>10)		; ForeGrd at VRAM $C000 (%00xxx000)
		dc.b (($D000)>>10)		; Window  at VRAM $D000 (%00xxxxy0)
		dc.b (($E000)>>13)		; BackGrd at VRAM $E000 (%00000xxx)
		dc.b (($F800)>>9)		; Sprites at VRAM $F800 (%0xxxxxxy)
		dc.b $00			; Nothing
		dc.b $00			; Background color: 0
		dc.b $00			; Nothing
		dc.b $00			; Nothing
		dc.b $00			; HInt value
		dc.b (%000|%00)			; No ExtInt, Scroll: VSCR:full HSCR:full
		dc.b $81			; H40, No shadow mode, Normal resolution
		dc.b (($FC00)>>10)		; HScroll at VRAM $FC00 (%00xxxxxx)
		dc.b $00			; Nothing
		dc.b $02			; VDP Auto increment by $02
		dc.b (%00<<4)|%01		; Layer size: V32 H64
		dc.b $00
		dc.b $00
		align 2
ASCII_PAL:	binclude "engine/shared/ascii_pal.bin"
ASCII_PAL_e:
ASCII_FONT:	binclude "engine/shared/ascii_font.bin"
ASCII_FONT_e:
		align 2
