; ====================================================================
; ----------------------------------------------------------------
; Sound
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init Sound
; 
; Uses:
; a0-a2,d0-d1
; --------------------------------------------------------

Sound_Init:
		lea	(RAM_MdSound),a0		; Clear RAM
		moveq	#0,d0
		move.w	#(sizeof_mdsnd-RAM_MdSound)-1,d1
.clrram:
		move.b	d0,(a0)+
		dbf	d1,.clrram

	; Send Z80 code
		move.w	#$100,(z80_bus).l		; Stop Z80
		move.w	#$100,(z80_reset).l		; Reset cancel
		lea	(z80_cpu).l,a1
		moveq	#0,d0
		move.w	#$1FFF,d1
.wait:
		btst	#0,(z80_bus).l			; Wait bus
		bne.s	.wait
.clear:
		move.b	d0,(a1)+
		dbf	d1,.clear
		lea	Z80_CODE(pc),a0			; Send this code
		lea	(z80_cpu).l,a1
		move.w	#(Z80_END-Z80_CODE)-1,d1
.copy:
		move.b	(a0)+,(a1)+
		dbf	d1,.copy
		
	; FM init stuff
	; TODO

	; Start Z80
		move.w	#0,(z80_reset).l		; Reset request
		nop
		nop
		nop
		move.w	#0,(z80_bus).l			; Start Z80
		move.w	#$100,(z80_reset).l		; Reset cancel
		rts
		
; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Sound_PlaySample
; 
; Play sound sample
; 
; Input:
; d0 | LONG - Start address
; d1 | LONG - End address
; d2 | LONG - Loop sample point / -1: dont loop
; d3 | WORD - Pitch
; --------------------------------------------------------

Sound_PlaySample:
		move.w	#$0100,(z80_bus).l	; Stop Z80
		lea	(z80_cpu),a4
		move.l	d0,d4
		moveq	#0,d6
		tst.l	d2
		bmi.s	.wait
		moveq	#1,d6
		move.l	d2,d5
		add.l	d0,d5
.wait:
		btst	#0,(z80_bus).l		; Wait for it
		bne.s	.wait
		move.b	d6,sndWavFlags(a4)

	; Set loop
		tst.w	d6
		beq.s	.nolp2
		move.b	d5,sndWavLoop(a4)
		lsr.l	#8,d5
		move.b	d5,d6
		or.b	#$80,d6
		move.b	d6,sndWavLoop+1(a4)
		lsr.l	#7,d5
		move.b	d5,sndWavLoop+2(a4)
.nolp2:
		
	; Set start
		move.b	d4,sndWavStart(a4)
		lsr.l	#8,d4
		move.b	d4,d6
		or.b	#$80,d6
		move.b	d6,sndWavStart+1(a4)
		lsr.l	#7,d4
		move.b	d4,sndWavStart+2(a4)
	; Set end
		move.l	d1,d5
		move.b	d5,sndWavEnd(a4)
		lsr.l	#8,d5
		move.b	d5,d6
; 		or.b	#$80,d6
		move.b	d6,sndWavEnd+1(a4)
		lsr.l	#7,d5
		move.b	d5,sndWavEnd+2(a4)
	; Set pitch
		move.w	d3,d4
		move.b	d4,sndWavPitch(a4)
		lsr.l	#8,d4
		move.b	d4,sndWavPitch+1(a4)

	; Request start
		move.b	#1,sndWavReq(a4)

		move.w	#0,(z80_bus).l
		rts

; --------------------------------------------------------
; Sound_SetPitch
; 
; Set pitch number
; 
; Input:
; d0 | WORD - Pitch data
; --------------------------------------------------------

Sound_SetPitch:
		move.w	#$0100,(z80_bus).l	; Stop Z80
		lea	(z80_cpu),a4
		move.w	d0,d4
		lsr.w	#8,d4
		move.w	d0,d5
.wait:
		btst	#0,(z80_bus).l		; Wait for it
		bne.s	.wait
		move.b	d5,sndWavPitch(a4)
		move.b	d4,sndWavPitch+1(a4)
		move.b	#4,sndWavReq(a4)	; Request pitch
		move.w	#0,(z80_bus).l
		rts
		
; ====================================================================
; ----------------------------------------------------------------
; Sound: Z80 code
; ----------------------------------------------------------------

Z80_CODE:
		cpu Z80
		phase 0
; --------------------------------------------------------
; Z80 Starts here
; --------------------------------------------------------

		di
		im	1
		ld	sp,2000h
		jr	z_init

; ------------------------------------------------
; RST 8
; ------------------------------------------------

		push	hl
		ld	hl,zbank
		ld	(hl),a
		rra
		ld	(hl),a
		rra
		ld	(hl),a
		rra
		ld	(hl),a
		rra
		ld	(hl),a
		rra
		ld	(hl),a
		rra
		ld	(hl),a
		rra
		ld	(hl),a
		rra
	if MARS
		ld	(hl),1
	else
		ld	(hl),0
	endif
		pop	hl
		ret

; ------------------------------------------------
; RST 20h
; ------------------------------------------------

		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		
; ------------------------------------------------
; RST 28h
; ------------------------------------------------

		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop

; ------------------------------------------------
; RST 30h
; ------------------------------------------------

		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop

; ------------------------------------------------
; RST 38h
; ------------------------------------------------

		di
		push	af
		push	bc
		push	de
		push	hl
		
		call	z_vint

		pop	hl
		pop	de
		pop	bc
		pop	af
		ei
		retn

; ========================================================
; ------------------------------------------------
; Init
; ------------------------------------------------

z_init:
; 		ei
		call	zsnd_init

; ========================================================
; ------------------------------------------------
; Loop
; ------------------------------------------------

.zloop:
		nop
		nop
		ld	a,(sndWavReq)
		or	a
		jp	z,.zloop
		jp	p,.request
		ld	a,b
		or	c
		jp	z,.exit

		ld	hl,(sndWavRead+1)	; xxxx.00
		ld	a,(hl)
		ld	(zym_data_1),a		; expects 2Ah at ctrl_1
	; 0000XX.XX
		dec	c
		ld	hl,(sndWavRead)		; 00xx.xx + pitch
		add 	hl,de
		ld	(sndWavRead),hl		; check for 0X00.00
		jp	nc,.zloop		; loop 1
	; 00XX00.00
		dec	b
		ld	a,(sndWavRead+2)
		inc 	a			; +01 xx00
		jp	m,.midl
	; XX8000.00
		push	de
		ld	e,a
		ld	a,(sndWavBank)
		inc	a			; next rom bank
		ld	d,a
		ld	(sndWavBank),a
		rst	8
		ld	bc,-1			; full size
		ld	a,(sndWavEndB)		; end bank
		cp	d			; bank current == end?
		jp	nz,.nxtbnk
		ld	bc,(sndWavEnd)		; set end len
		ld	a,b
		and	7Fh
		ld	b,a
.nxtbnk:
		ld	a,e
		pop	de
		or	80h
.midl:
		ld	(sndWavRead+2),a	; save xx00
		ld	a,2Ah			; just in case
		ld	(zym_ctrl_1),a
		jr	.zloop
		
; ----------------------------------------
; WAV FINISHED
; ----------------------------------------

.exit:
		ld	a,(sndWavFlags)
		bit 	0,a
		jp	nz,.mkloop

		ld	a,2Bh
		ld	(zym_ctrl_1),a
		xor	a
		ld	(zym_data_1),a
		ld	e,a
		and	7Fh
		ld	(sndWavReq),a
		ld	a,e

; ----------------------------------------
; WAV REQUEST
; 
; a - sndWavReq
; 01h new/reset
; 02h full stop 
; 03h pause/unpause
; 04h pitch change
; ----------------------------------------

.request:
		and	1111b
		dec	a
		add	a,a
		ld	de,0
		ld	e,a
		ld	hl,.list
		add	hl,de
		ld	e,(hl)
		inc 	hl
		ld	d,(hl)
		ld	h,d
		ld	l,e
		xor	a
		ld	(sndWavReq),a
		jp	(hl)
		
; ----------------------------------------

.list:
		dw .task1
		dw .task2
		dw .task3
		dw .task4

; ----------------------------------------

.mkloop:
		ld	hl,(sndWavLoop)
		ld	a,(sndWavLoopB)
		jr	.restart
		
; ----------------------------------------
; $01 - Reset
; ----------------------------------------

.task1:
		ld	hl,(sndWavStart)
		ld	a,(sndWavStartB)

.restart:
		set 	7,h
		ld	(sndWavRead+1),hl
		ld	(sndWavBank),a
		rst	8
		xor	a
		ld	(sndWavRead),a
		ld	de,(sndWavPitch)	; pitch speed
		
		ld	a,2Bh
		ld	(zym_ctrl_1),a
		ld	a,(sndWavReq)
		or	80h
		ld	(sndWavReq),a
		ld	(zym_data_1),a
		ld	a,2Ah
		ld	(zym_ctrl_1),a
		
	; check if same bank
		ld	bc,-1
		ld	a,(sndWavStartB)
		ld	c,a
		ld	a,(sndWavEndB)
		cp	c
		jp	nz,.zloop
		ld	bc,(sndWavEnd)		; end len
		ld	a,b
		and	7Fh
		ld	b,a
		jp	.zloop
	
; ----------------------------------------
; $02 - Stop
; ----------------------------------------

.task2:
		ld	a,2Bh
		ld	(zym_ctrl_1),a
		xor	a
		ld	(zym_data_1),a
		jp	.zloop
		
; ----------------------------------------
; $03 - Pause/Unpause
; ----------------------------------------

.task3:
		jp	.zloop

; ----------------------------------------
; $04 - Pitch change
; ----------------------------------------

.task4:
		ld	de,(sndWavPitch)	; pitch speed
		ld	a,80h
		ld	(sndWavReq),a
		jp	.zloop

; ========================================================		
; ------------------------------------------------
; VBlank
; ------------------------------------------------

z_vint:

	; Return WAVE byte
		ld	a,(sndWavReq)
		or	a
		jp	p,.nope
		ld	hl,(sndWavRead+1)
		ld	a,2Ah
		ld	(zym_ctrl_1),a
		ld	a,(hl)
		ld	(zym_data_1),a
.nope:
		ret

; ========================================================		
; ------------------------------------------------
; Subroutines
; ------------------------------------------------

zsnd_init:
		ld	a,2Bh
		ld	(zym_ctrl_1),a
		xor	a
		ld	(zym_data_1),a
		
		ld	hl,zpsg_ctrl
		ld	bc,9FBFh
		ld	de,0DFFFh
		ld	(hl),b
		ld	(hl),c
		ld	(hl),d
		ld	(hl),e

	; FM/PSG goes here
		ret

; ========================================================
; ------------------------------------------------
; Buffer
; ------------------------------------------------

sndWavRead	db 0		; 000000.XX
		dw 0		; 00XXXX.00
sndWavBank	db 0		; XX0000.00
sndWavCopy	db 0

; ========================================================
; ------------------------------------------------
; User input
; ------------------------------------------------

; --------------------------------------------------------

		cpu 68000
		padding off
		phase Z80_CODE+*

Z80_END:
		align 2
		
; ====================================================================
; ----------------------------------------------------------------
; Sound data
; ----------------------------------------------------------------
