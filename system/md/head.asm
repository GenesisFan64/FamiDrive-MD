; ====================================================================
; ----------------------------------------------------------------
; ROM HEAD
; 
; Genesis / Mega Drive
; ----------------------------------------------------------------

		dc.l 0				; Stack point
		dc.l MD_Entry			; Entry point
		dc.l MD_ErrBus			; Bus error
		dc.l MD_ErrAddr			; Address error
		dc.l MD_ErrIll			; ILLEGAL Instruction
		dc.l MD_ErrZDiv			; Divide by 0
		dc.l MD_ErrChk			; CHK Instruction
		dc.l MD_ErrTrapV		; TRAPV Instruction
		dc.l MD_ErrPrivl		; Privilege violation
		dc.l MD_Trace			; Trace
		dc.l MD_Line1010		; Line 1010 Emulator
		dc.l MD_Line1111		; Line 1111 Emulator
		dc.l MD_ErrorEx			; Error exception
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx	
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx		
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap;RAM_HBlankGoTo		; VDP HBlank interrupt
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap;RAM_VBlankGoTo		; VDP VBlank interrupt
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.b "SEGA GENESIS    "
		dc.b "(C)GF64 20??.???"
		dc.b "NO TITLE                                        "
		dc.b "NO TITLE                                        "
		dc.b "GM HOMEBREW-00  "
		dc.b "J               "
		dc.l 0
		dc.l ROM_END
		dc.l $FF0000
		dc.l $FFFFFF
		dc.b "RA",$F8,$20
		dc.l $200000
		dc.l $203FFF
		align $1F0
		dc.b "U               "

; ====================================================================
; ----------------------------------------------------------------
; Error trap
; ----------------------------------------------------------------

MD_ErrBus:		; Bus error
MD_ErrAddr:		; Address error
MD_ErrIll:		; ILLEGAL Instruction
MD_ErrZDiv:		; Divide by 0
MD_ErrChk:		; CHK Instruction
MD_ErrTrapV:		; TRAPV Instruction
MD_ErrPrivl:		; Privilege violation
MD_Trace:		; Trace
MD_Line1010:		; Line 1010 Emulator
MD_Line1111:		; Line 1111 Emulator
MD_ErrorEx:		; Error exception
MD_ErrorTrap:
		rte
		
; ----------------------------------------------------------------
; Entry point
; ----------------------------------------------------------------

MD_Entry:
		move	#$2700,sr
		move.b	(sys_io).l,d0
		andi.b	#%1111,d0
		beq.s	.oldmd
		move.l	($100).l,(sys_tmss).l	; "SEGA"
.oldmd:
		tst.w	(vdp_ctrl).l		; Unlock VDP (random tst)
		
		moveq	#0,d0
		movea.l	d0,a6
		move.l	a6,usp
.waitframe:	move.w	(vdp_ctrl).l,d0		; Wait for VBlank
		btst	#bitVint,d0
		beq.s	.waitframe
		move.l	#$80048144,(vdp_ctrl).l	; Keep display
		lea	($FFFF0000),a0
		move.w	#($F000/4)-1,d0
.clrram:
		clr.l	(a0)+
		dbf	d0,.clrram
		movem.l	($FF0000),d0-a6		; Clear registers
		bra	MD_Main
