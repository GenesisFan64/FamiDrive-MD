; ====================================================================
; ----------------------------------------------------------------
; System
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init System
; 
; Uses:
; a0-a2,d0-d1
; --------------------------------------------------------

System_Init:
		move.w	#$0100,(z80_bus).l	; Stop Z80
.wait:
		btst	#0,(z80_bus).l		; Wait for it
		bne.s	.wait
		moveq	#%01000000,d0		; Init ports, TH=1
		move.b	d0,(sys_ctrl_1).l	
		move.b	d0,(sys_ctrl_2).l
		move.b	d0,(sys_ctrl_3).l
		move.w	#0,(z80_bus).l
		lea	(RAM_InputData),a0
		move.w	#sizeof_input-1/2,d1
		moveq	#0,d0
.clrinput:
		move.w	#0,(a0)+
		dbf	d1,.clrinput
		move.w	#$4EF9,d0		; JMP opcode
 		move.w	d0,(RAM_VBlankGoTo).l
		move.w	d0,(RAM_HBlankGoTo).l
		move.l	#$56255769,d0
		move.l	#$95116102,d1
		move.l	d0,(RAM_SysRandVal).l
		move.l	d1,(RAM_SysRandSeed).l
		move.l	#VInt_Default,d0	; Set default ints
		move.l	#Hint_Default,d1
		bsr	System_SetInts
		bra	System_SaveInit
		
; ====================================================================
; ----------------------------------------------------------------
; System subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; System_Random
; 
; Set random value
; 
; Output:
; d0 | LONG
; --------------------------------------------------------

System_Random:
		move.l	(RAM_SysRandSeed),d5
		move.l	(RAM_SysRandVal),d4
		rol.l	#1,d5
		asr.l	#1,d4
		add.l	d5,d4
		move.l	d5,(RAM_SysRandSeed).l
		move.l	d4,(RAM_SysRandVal).l
		move.l	d4,d0
		rts
		
; --------------------------------------------------------
; System_SetInts
; 
; Set new interrputs
; 
; d0 | LONG - VBlank
; d1 | LONG - HBlank
;
; Uses:
; d4
; --------------------------------------------------------

System_SetInts:
		move.l	d0,d4
		beq.s	.novint
		bmi.s	.novint
 		move.l	d4,(RAM_VBlankGoTo+2).l
.novint:
		move.l	d1,d4
		beq.s	.nohint
		bmi.s	.nohint
		move.l	d4,(RAM_HBlankGoTo+2).l
.nohint:
		rts

; --------------------------------------------------------
; System_VSync
; 
; Waits for VBlank
; 
; Uses:
; d4
; --------------------------------------------------------

System_VSync:
		move.w	(vdp_ctrl),d4
		btst	#bitVint,d4
		beq.s	System_VSync
		bsr	System_Input
		add.l	#1,(RAM_FrameCount).l
.inside:	move.w	(vdp_ctrl),d4
		btst	#bitVint,d4
		bne.s	.inside
		rts
		
; --------------------------------------------------------
; System_Input
; 
; Uses:
; d4-d6,a4-a5
; --------------------------------------------------------

System_Input:
; 		move.w	#$0100,(z80_bus).l	; Stop Z80
; .wait:
; 		btst	#0,(z80_bus).l		; Wait for it
; 		bne.s	.wait
		
		lea	($A10003),a4
		lea	(RAM_InputData),a5
		bsr.s	.this_one
		adda	#2,a4
		adda	#sizeof_input,a5
; 		bsr.s	.this_one
; 		move.w	#0,(z80_bus).l
; 		rts

; --------------------------------------------------------	
; do port
; --------------------------------------------------------

.this_one:
		bsr	.find_id
		move.b	d4,pad_id(a5)
		cmp.w	#$F,d4
		beq.s	.exit
		and.w	#$F,d4
		add.w	d4,d4
		move.w	.list(pc,d4.w),d5
		jmp	.list(pc,d5.w)
.exit:
		clr.b	pad_ver(a5)
		rts

; --------------------------------------------------------
; Grab ID
; --------------------------------------------------------

.list:		dc.w .exit-.list	; $0
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $4
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $8
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $C
		dc.w .id_0D-.list
		dc.w .exit-.list
		dc.w .exit-.list

; --------------------------------------------------------
; ID $0D
; 
; Normal controller, Old or New
; --------------------------------------------------------

.id_0D:
		move.b	#$40,(a4)	; Show CB|RLDU
		nop
		nop
		move.b	#$00,(a4)	; Show SA|RLDU
		nop
		nop
		move.b	#$40,(a4)	; Show CB|RLDU
		nop
		nop
		move.b	#$00,(a4)	; Show SA|RLDU
		nop
		nop
		move.b	#$40,(a4)	; 6 button responds
		nop
		nop
		move.b	(a4),d4		; Grab ??|MXYZ
 		move.b	#$00,(a4)
  		nop
  		nop
 		move.b	(a4),d6		; Type: $03 old, $0F new
 		move.b	#$40,(a4)
 		nop
 		nop
		and.w	#$F,d6
		lsr.w	#2,d6
		and.w	#1,d6
		beq.s	.oldpad
		not.b	d4
 		and.w	#%1111,d4
		move.b	on_hold(a5),d5
		eor.b	d4,d5
		move.b	d4,on_hold(a5)
		and.b	d4,d5
		move.b	d5,on_press(a5)
.oldpad:
		move.b	d6,pad_ver(a5)
		
		move.b	#$00,(a4)	; Show SA??|RLDU
		nop
		nop
		move.b	(a4),d4
		lsl.b	#2,d4
		and.b	#%11000000,d4
		move.b	#$40,(a4)	; Show ??CB|RLDU
		nop
		nop
		move.b	(a4),d5
		and.b	#%00111111,d5
		or.b	d5,d4
		not.b	d4
		move.b	on_hold+1(a5),d5
		eor.b	d4,d5
		move.b	d4,on_hold+1(a5)
		and.b	d4,d5
		move.b	d5,on_press+1(a5)
		rts
		
; --------------------------------------------------------
; Grab ID
; --------------------------------------------------------

.find_id:
		moveq	#0,d4
		move.b	#%01110000,(a4)		; TH=1,TR=1,TL=1
		nop
		nop
		bsr.s	.get_id
		move.b	#%00110000,(a4)		; TH=0,TR=1,TL=1
		nop
		nop
		add.w	d4,d4
.get_id:
		move.b	(a4),d5
		move.b	d5,d6
		and.b	#$C,d6
		beq.s	.step_1
		addq.w	#1,d4
.step_1:
		add.w	d4,d4
		move.b	d5,d6
		and.w	#3,d6
		beq.s	.step_2
		addq.w	#1,d4
.step_2:
		rts
		
; 		moveq	#0,d0
; 		bsr.s	System_ReadPad
; 		lea	(RAM_Control+(16*4)),a5
; 		moveq	#1,d0
; 		bsr.s	System_ReadPad
; 		
; 		lea	($A10003).l,a6
; 		lsl.w	#1,d0
; 		add.w	d0,a6		; Add result to port
; 		bsr.s	.srch_pad
; 		move.b	d0,(a5)
		move.w	#0,(z80_bus).l
		rts
		
; --------------------------------------------------------
; System_SaveInit
; 
; Init save data
; 
; Uses:
; a4,d4-d5
; --------------------------------------------------------

System_SaveInit:
	if MCD=0
		move.b	#1,(md_bank_sram).l
		lea	($200001).l,a4
		moveq	#0,d4
		move.w	#($4000/2)-1,d5
.initsave:
		move.b	d4,(a4)
		adda	#2,a4
		dbf	d5,.initsave
		move.b	#0,(md_bank_sram).l
	endif
		rts

; ====================================================================
; ----------------------------------------------------------------
; Game modes
; ----------------------------------------------------------------

Mode_Init:
		bsr	Video_Clear
		lea	(RAM_ModeBuff),a4
		move.w	#(MAX_MDERAM/2)-1,d5
		moveq	#0,d4
.clr:
		move.w	d4,(a4)+
		dbf	d5,.clr
		rts
		
; ====================================================================
; ----------------------------------------------------------------
; MEGA CD ONLY
; ----------------------------------------------------------------
	
	if MCD
	
; --------------------------------------------------------
; MCD_SubTask
; 
; Request task to SubCPU
; check subcpu.asm to see each task action
;
; Input:
; d0 - Task number
; --------------------------------------------------------

MCD_SubWait:
		lea	(syscd_comm_s),a4
.wait:		tst.b	(a4)
		bne.s	.wait		; wait BUSY
		rts

; --------------------------------------------------------
; MCD_SubTask
; 
; Request task to SubCPU
; check subcpu.asm to see each task action
;
; Input:
; d0 - Task number
; --------------------------------------------------------

MCD_SubTask:
		lea	(syscd_comm_s),a4
		move.b	d0,-1(a4)
.wait:
		tst.b	(a4)
		beq.s	.wait		; wait BUSY
.working:
		tst.b	(a4)
		bpl.s	.working	; wait DONE
		move.b	#0,-1(a4)
.free:
		tst.b	(a4)
		beq.s	.free		; wait FREE
		rts

; --------------------------------------------------------
; MCD_MkStmpScrn
; MEGA CD ONLY
; 
; Make a virtual screen for Stamps
;
; Input:
; d0 | LONG - 00|Lyr|X|Y / locate(lyr,x,y)
; d1 | LONG - width|height / doubleword(width,height)
; --------------------------------------------------------

MCD_MkStmpScrn:
		lea	(syscd_args_m),a0	; Stamps: Init
		move.w	#0,(a0)			; 16x16 dot | 1x1 screen | RPT
		move.l	d1,d4
		move.w	d4,4(a0)
		lsr.w	#3,d4
		sub.w	#1,d4
		swap	d4
		move.w	d4,2(a0)
		lsr.w	#3,d4
		sub.w	#1,d4
		swap	d4
		move.l	d4,d1
		move.w	#1,d2
		bsr	Video_AutoMap_Vert
		
		move.b	(syscd_memory),d4	; WRAM -> Sub
		or.b	#2,d4
		move.b	d4,(syscd_memory)
; .wait:	move.b	(syscd_memory),d4	; WRAM ? Sub
; 		and.w	#2,d4
; 		beq.s	.wait
		moveq	#$20,d0			; Init stamps
		bsr	MCD_SubTask
		moveq	#8,d0			; WRAM -> Main
		bra	MCD_SubTask

; --------------------------------------------------------
; MCD_Stmp_Render
; MEGA CD ONLY
; 
; Request Stamp rendering from SubCPU
; Call this OUTSIDE of VBlank
;
; To draw output to VDP: (example)
; 	moveq	#8,d0
; 	bsr	MCD_SubTask
; 	move.l	#syscd_wordram+$38000,d0	; stamp output
; 	move.w	#(width*height)/2,d1		;
; 	move.w	#1,d2
; 	bsr	Video_LoadArt
; (Call this inside of VBlank)
; --------------------------------------------------------

MCD_Stmp_Render:
		move.b	(syscd_memory),d4	; WRAM -> Sub
		or.b	#2,d4
		move.b	d4,(syscd_memory)
.wait:		move.b	(syscd_memory),d4	; WRAM ? Sub
		and.w	#2,d4
		beq.s	.wait
		moveq	#$21,d0
		bsr	MCD_SubTask
		moveq	#8,d0			; WRAM -> Main
		bsr	MCD_SubTask
		rts

; --------------------------------------------------------

	endif
	
; ====================================================================
; ----------------------------------------------------------------
; System: default interrupts
; ----------------------------------------------------------------

; --------------------------------------------------------
; VBlank
; --------------------------------------------------------

VInt_Default:
		movem.l	d0-a6,-(sp)
		bsr	System_Input
		add.l	#1,(RAM_FrameCount).l
		movem.l	(sp)+,d0-a6		
		rte

; --------------------------------------------------------
; HBlank
; --------------------------------------------------------

HInt_Default:
		rte
		
; ====================================================================
; ----------------------------------------------------------------
; System data
; ----------------------------------------------------------------
