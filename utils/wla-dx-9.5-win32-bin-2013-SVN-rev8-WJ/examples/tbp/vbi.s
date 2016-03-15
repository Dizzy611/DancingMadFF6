
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; tank bomb panic
; written by ville helin <vhelin@cc.hut.fi> in 2000
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

.INCLUDE "defines.i"

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; vbi
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

.BANK 0 SLOT 0
.ORG 0
.SECTION "VBI_INITIAL"

VBI_INITIAL:
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; read input
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

	LD	HL, P1
	LD	(HL), $20
	LD	A, (HL)
	LD	A, (HL)
	CPL
	AND	$0F
	SWAP	A
	LD	B, A
	LD	(HL), $10
	LD	A, (HL)
	LD	A, (HL)
	LD	A, (HL)
	LD	A, (HL)
	LD	A, (HL)
	LD	A, (HL)
	CPL
	AND	$0F
	OR	B
	LD	B, A
	LD	(HL), $30

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; horizontal move
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

	BIT	5, A
	JR	Z, _MOVE_LEFT_NO

_MOVE_LEFT:
	LD	B, $FF			;move left.
	JR	_MOVE_HORIZONTAL_DONE
_MOVE_LEFT_NO:
	BIT	4, A
	JR	Z, _MOVE_RIGHT_NO
_MOVE_RIGHT:
	LD	B, 1			;move right.
	JR	_MOVE_HORIZONTAL_DONE
_MOVE_RIGHT_NO:
	LD	B, 0			;don't move horizontal.
_MOVE_HORIZONTAL_DONE:

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; vertical move
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

	BIT	7, A
	JR	Z, _MOVE_DOWN_NO
_MOVE_DOWN:
	LD	C, $1			;move down.
	JR	_MOVE_VERTICAL_DONE
_MOVE_DOWN_NO:
	BIT	6, A
	JR	Z, _MOVE_UP_NO
_MOVE_UP:
	LD	C, $FF			;move up.
	JR	_MOVE_VERTICAL_DONE
_MOVE_UP_NO:
	LD	C, 0			;don't move horizontal.
_MOVE_VERTICAL_DONE:

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; move player (-7 <= B&C <= 7)
; B = horizontal movement
; C = vertical movement
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

JUMP_X:	XOR	A
	LD	(work_vbi), A		;reset status byte.

	LD	HL, screen_x		;move screen.
	LD	A, (HL)
	ADD	B
	LD	(HL), A
	LD	HL, screen_y
	LD	A, (HL)
	ADD	C
	LD	(HL), A

	LD	HL, player_x
	LD	A, (HL)
	ADD	B
	BIT	7, A
	JR	Z, _MOVE_HADJ_NOT_NEG
	ADD	8
	LD	(HL), A
	LD	HL, player_x8
	DEC	(HL)
	LD	HL, work_vbi
	SET	3, (HL)			;player_x8 changed left.
	JR	_MOVE_HADJ_DONE

_MOVE_HADJ_NOT_NEG:
	BIT	3, A
	JR	NZ, _MOVE_HADJ_POS
	LD	(HL), A
	JR	_MOVE_HADJ_DONE

_MOVE_HADJ_POS:
	SUB	8
	LD	(HL), A
	LD	HL, player_x8
	INC	(HL)
	LD	HL, work_vbi
	SET	2, (HL)			;player_x8 changed right!

_MOVE_HADJ_DONE:
	LD	HL, player_y
	LD	A, (HL)
	ADD	C
	BIT	7, A
	JR	Z, _MOVE_VADJ_NOT_NEG
	ADD	8
	LD	(HL), A
	LD	HL, player_y8
	DEC	(HL)
	LD	HL, work_vbi
	SET	4, (HL)			;player_y8 changed up.

	LD	HL, screen_origo	;adjust map pointer.
	LD	D, (HL)
	INC	HL
	LD	E, (HL)
	LD	HL, level_dx
	XOR	A
	SUB	(HL)
	LD	H, $FF
	LD	L, A
	ADD	HL, DE
	LD	A, H
	LD	B, L
	LD	HL, screen_origo
	LD	(HL), A
	INC	HL
	LD	(HL), B
	JR	_MOVE_VADJ_DONE

_MOVE_VADJ_NOT_NEG:
	BIT	3, A
	JR	NZ, _MOVE_VADJ_POS
	LD	(HL), A
	JR	_MOVE_VADJ_DONE

_MOVE_VADJ_POS:
	SUB	8
	LD	(HL), A
	LD	HL, player_y8
	INC	(HL)
	LD	HL, work_vbi
	SET	5, (HL)			;player_y8 changed down.

	LD	HL, screen_origo	;adjust map pointer.
	LD	D, (HL)
	INC	HL
	LD	E, (HL)
	LD	HL, level_dx
	LD	L, (HL)
	LD	H, 0
	ADD	HL, DE
	LD	A, H
	LD	B, L
	LD	HL, screen_origo
	LD	(HL), A
	INC	HL
	LD	(HL), B

_MOVE_VADJ_DONE:

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; update scroll registers
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

	LD	A, (screen_x)
	LDH	(R_SCX), A
	LD	A, (screen_y)
	LDH	(R_SCY), A

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; draw horizontal?
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

	LD	HL, work_vbi
	BIT	3, (HL)
	JP	NZ, _SCREEN_COPY_LEFT
	BIT	2, (HL)
	JP	Z, _SCREEN_COPY_HORIZONTAL_DONE

_SCREEN_COPY_RIGHT:
	LD	A, (player_x8)
	ADD	10
	LD	E, A
	LD	D, 0
	LD	HL, screen_origo
	LDI	A, (HL)
	LD	L, (HL)
	LD	H, A
	ADD	HL, DE			;hl = map position.
	PUSH	HL

	LD	A, (screen_x)
	SRL	A
	SRL	A
	SRL	A
	ADD	20
	AND	31
	LD	C, A
	LD	A, (screen_y)
	SRL	A
	SRL	A
	AND	%11111110
	LD	E, A
	LD	HL, mul_32
	ADD	HL, DE
	LDI	A, (HL)
	LD	H, (HL)
	ADD	C
	LD	L, A			;hl = screen y + screen x.
	LD	DE, $9800
	ADD	HL, DE

	LD	A, H
	AND	$9B
	LD	H, A			;scroll wrap.

	POP	BC			;bc = map position.
	LD	D, 10			;10 * 2 tiles.
	LD	A, (level_dx)
	LD	E, A			;d  = counter, e = level_dx.

_SCREEN_COPY_RIGHT_LOOP:
	LD	A, (level_bank_map)	;map tile.
	LD	($2000), A
	XOR	A
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char.

	LD	A, (level_bank_attr)	;map tile attributes.
	LD	($2000), A
	LD	A, %00000001
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char attributes.

	LD	A, C
	ADD	E
	LD	C, A
	LD	A, B
	ADC	0
	LD	B, A			;map y fixed.

	LD	A, L
	ADD	32
	LD	L, A
	LD	A, H
	ADC	0
	AND	$9B			;scroll wrap screen.
	LD	H, A			;screen y fixed.

	LD	A, (level_bank_map)	;map tile.
	LD	($2000), A
	XOR	A
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char.

	LD	A, (level_bank_attr)	;map tile attributes.
	LD	($2000), A
	LD	A, %00000001
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char attributes.

	LD	A, C
	ADD	E
	LD	C, A
	LD	A, B
	ADC	0
	LD	B, A			;map y fixed.

	LD	A, L
	ADD	32
	LD	L, A
	LD	A, H
	ADC	0
	AND	$9B			;scroll wrap screen.
	LD	H, A			;screen y fixed.

	DEC	D
	JR	NZ, _SCREEN_COPY_RIGHT_LOOP
	JP	_SCREEN_COPY_HORIZONTAL_DONE

_SCREEN_COPY_LEFT:
	LD	A, (player_x8)
	SUB	10
	LD	E, A
	LD	D, 0
	LD	HL, screen_origo
	LDI	A, (HL)
	LD	L, (HL)
	LD	H, A
	ADD	HL, DE			;hl = map position.
	PUSH	HL

	LD	A, (screen_x)
	SRL	A
	SRL	A
	SRL	A
	LD	C, A
	LD	A, (screen_y)
	SRL	A
	SRL	A
	AND	%11111110
	LD	E, A
	LD	HL, mul_32
	ADD	HL, DE
	LDI	A, (HL)
	LD	H, (HL)
	ADD	C
	LD	L, A			;hl = screen y + screen x.
	LD	DE, $9800
	ADD	HL, DE

	LD	A, H
	AND	$9B
	LD	H, A			;scroll wrap.

	POP	BC			;bc = map position.
	LD	D, 10			;10 * 2 tiles.
	LD	A, (level_dx)
	LD	E, A			;d  = counter, e = level_dx.

_SCREEN_COPY_LEFT_LOOP:
	LD	A, (level_bank_map)	;map tile.
	LD	($2000), A
	XOR	A
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char.

	LD	A, (level_bank_attr)	;map tile attributes.
	LD	($2000), A
	LD	A, %00000001
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char attributes.

	LD	A, C
	ADD	E
	LD	C, A
	LD	A, B
	ADC	0
	LD	B, A			;map y fixed.

	LD	A, L
	ADD	32
	LD	L, A
	LD	A, H
	ADC	0
	AND	$9B			;scroll wrap screen.
	LD	H, A			;screen y fixed.

	LD	A, (level_bank_map)	;map tile.
	LD	($2000), A
	XOR	A
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char.

	LD	A, (level_bank_attr)	;map tile attributes.
	LD	($2000), A
	LD	A, %00000001
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char attributes.

	LD	A, C
	ADD	E
	LD	C, A
	LD	A, B
	ADC	0
	LD	B, A			;map y fixed.

	LD	A, L
	ADD	32
	LD	L, A
	LD	A, H
	ADC	0
	AND	$9B			;scroll wrap screen.
	LD	H, A			;screen y fixed.

	DEC	D
	JR	NZ, _SCREEN_COPY_LEFT_LOOP

_SCREEN_COPY_HORIZONTAL_DONE:

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; draw vertical?
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

	LD	HL, work_vbi
	BIT	4, (HL)
	JP	NZ, _SCREEN_COPY_UP
	BIT	5, (HL)
	JP	Z, _SCREEN_COPY_DONE

_SCREEN_COPY_DOWN:
	LD	HL, level_dx_x18
	LD	C, (HL)
	INC	HL
	LD	B, (HL)
	LD	A, (player_x8)
	SUB	10
	LD	E, A
	LD	D, 0
	LD	HL, screen_origo
	LDI	A, (HL)
	LD	L, (HL)
	LD	H, A
	ADD	HL, DE
	ADD	HL, BC			;hl = map position.
	PUSH	HL

	LD	A, (screen_x)
	SRL	A
	SRL	A
	SRL	A
	LD	C, A
	LD	A, (screen_y)
	SRL	A
	SRL	A
	AND	%11111110
	LD	E, A
	LD	HL, mul_32
	ADD	HL, DE
	LDI	A, (HL)
	LD	H, (HL)
	ADD	C
	LD	L, A			;hl = screen y + screen x.
	LD	DE, $9800
	LD	BC, $0240
	ADD	HL, DE
	ADD	HL, BC

	LD	A, H
	AND	$9B
	LD	H, A			;scroll wrap.

	POP	BC			;bc = map position.
	LD	E, 11			;11 * 2 tiles.
	LD	A, L
	AND	%11100000
	LD	D, A			;d = wrap mask.

_SCREEN_COPY_DOWN_LOOP:
	LD	A, (level_bank_map)	;map tile.
	LD	($2000), A
	XOR	A
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char.

	LD	A, (level_bank_attr)	;map tile attributes.
	LD	($2000), A
	LD	A, %00000001
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char attributes.

	INC	BC
	LD	A, L
	INC	A
	AND	%00011111
	OR	D
	LD	L, A

	LD	A, (level_bank_map)	;map tile.
	LD	($2000), A
	XOR	A
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char.

	LD	A, (level_bank_attr)	;map tile attributes.
	LD	($2000), A
	LD	A, %00000001
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char attributes.

	INC	BC
	LD	A, L
	INC	A
	AND	%00011111
	OR	D
	LD	L, A

	DEC	E
	JR	NZ, _SCREEN_COPY_DOWN_LOOP
	JP	_SCREEN_COPY_DONE

_SCREEN_COPY_UP:
	LD	A, (player_x8)
	SUB	10
	LD	E, A
	LD	D, 0
	LD	HL, screen_origo
	LDI	A, (HL)
	LD	L, (HL)
	LD	H, A
	ADD	HL, DE			;hl = map position.
	PUSH	HL

	LD	A, (screen_x)
	SRL	A
	SRL	A
	SRL	A
	LD	C, A
	LD	A, (screen_y)
	SRL	A
	SRL	A
	AND	%11111110
	LD	E, A
	LD	HL, mul_32
	ADD	HL, DE
	LDI	A, (HL)
	LD	H, (HL)
	ADD	C
	LD	L, A			;hl = screen y + screen x.
	LD	DE, $9800
	ADD	HL, DE

	LD	A, H
	AND	$9B
	LD	H, A			;scroll wrap.

	POP	BC			;bc = map position.
	LD	E, 11			;11 * 2 tiles.
	LD	A, L
	AND	%11100000
	LD	D, A			;d = wrap mask.

_SCREEN_COPY_UP_LOOP:
	LD	A, (level_bank_map)	;map tile.
	LD	($2000), A
	XOR	A
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char.

	LD	A, (level_bank_attr)	;map tile attributes.
	LD	($2000), A
	LD	A, %00000001
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char attributes.

	INC	BC
	LD	A, L
	INC	A
	AND	%00011111
	OR	D
	LD	L, A

	LD	A, (level_bank_map)	;map tile.
	LD	($2000), A
	XOR	A
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char.

	LD	A, (level_bank_attr)	;map tile attributes.
	LD	($2000), A
	LD	A, %00000001
	LDH	(R_VBK), A

	LD	A, (BC)
	LD	(HL), A			;move tile char attributes.

	INC	BC
	LD	A, L
	INC	A
	AND	%00011111
	OR	D
	LD	L, A

	DEC	E
	JR	NZ, _SCREEN_COPY_UP_LOOP

_SCREEN_COPY_DONE:

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; add counter
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

	LD	HL, vbi_counter
	INC	(HL)

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; do sprites
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

	CALL	$FF80			;LOAD_SPRITES_DMA in high ram.

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; exit
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

	LD	A, (main_bank_rom)	;restore rom bank.
	LD	($2000), A
	LD	A, (main_bank_dram)	;restore display ram bank.
	LDH	(R_VBK), A

	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RETI

.ENDS
