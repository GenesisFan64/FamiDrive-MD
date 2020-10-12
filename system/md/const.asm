; ====================================================================
; ----------------------------------------------------------------
; Engine settings
; ----------------------------------------------------------------

; MDRAM_START	equ	$FFFF9000
; MAX_MDERAM	equ 	$200		; MAX RAM for Game modes

; ====================================================================
; ----------------------------------------------------------------
; Aliases
; ----------------------------------------------------------------

; Controller_1	equ RAM_InputData
; Controller_2	equ RAM_InputData+sizeof_input

Vdp_palette	equ $C0000000		; Palette
Vdp_vsram	equ $40000010		; Vertical scroll

; ====================================================================
; ----------------------------------------------------------------
; Variables
; ----------------------------------------------------------------

; --------------------------------------------------------
; controller
; --------------------------------------------------------

JoyUp		equ $0001
JoyDown		equ $0002
JoyLeft		equ $0004
JoyRight	equ $0008
JoyB		equ $0010
JoyC		equ $0020
JoyA		equ $0040
JoyStart	equ $0080
JoyZ		equ $0100
JoyY		equ $0200
JoyX		equ $0400
JoyMode		equ $0800

; right byte only
bitJoyUp	equ 0
bitJoyDown	equ 1
bitJoyLeft	equ 2
bitJoyRight	equ 3
bitJoyB		equ 4
bitJoyC		equ 5
bitJoyA		equ 6
bitJoyStart	equ 7

; left byte only
bitJoyZ		equ 0
bitJoyY		equ 1
bitJoyX		equ 2
bitJoyMode	equ 3

; --------------------------------------------------------
; vdp_ctrl READ bits
; --------------------------------------------------------

bitHint		equ 2
bitVint		equ 3
bitDma		equ 1

; --------------------------------------------------------
; VDP register vars
; --------------------------------------------------------

; Register $80
HVStop		equ $02
HintEnbl	equ $10
bitHVStop	equ 1
bitHintEnbl	equ 4

; Register $81
DispEnbl 	equ $40
VintEnbl 	equ $20
DmaEnbl		equ $10
bitDispEnbl	equ 6
bitVintEnbl	equ 5
bitDmaEnbl	equ 4
bitV30		equ 3

; --------------------------------------------------------
; Misc
; --------------------------------------------------------

varNullVram	equ $7FF
