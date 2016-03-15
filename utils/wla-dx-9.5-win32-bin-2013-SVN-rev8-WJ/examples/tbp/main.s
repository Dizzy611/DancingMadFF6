
.MACRO IFNDEF
.IFNDEF \1
.DEFINE \1 \2
.ENDIF
.ENDM

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; tank bomb panic
; written by ville helin <vhelin@cc.hut.fi> in 2000
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

.INCLUDE "defines.i"

IFNDEF JOO 1

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; main
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

.BANK 0 SLOT 0
.ORG $150

MAIN:	DI
	LD	SP, $FFFE
	CALL	SET_CPU_SPEED_2X

	LD	A, $D9			;reti.
	LD	(irq_lcd), A		;empty unused interrupts.
	LD	(irq_tim), A
	LD	(irq_ser), A
	LD	(irq_htl), A

	LD	HL, irq_vbi
	LD	A, $C3			;jp.
	LDI	(HL), A
	LD	BC, VBI_INITIAL
	LD	A, C
	LDI	(HL), A
	LD	(HL), B

	CALL	WAIT_VBI_POWER

	LD	A, %10000001
	LDH	(R_LCDC), A		;lcd control.

	LD	HL, $FF80		;init sprite loader.
	LD	DE, LOAD_SPRITES_DMA
	LD	C, 12
	CALL	COPY_TO_RAM

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; load level 1
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

	XOR	A
	LD	(player_x), A
	LD	A, 20
	LD	(player_x8), A

	XOR	A
	LD	(player_y), A
	LD	A, 20
	LD	(player_y8), A

	LD	A, 8
	LD	(screen_x), A
	LD	A, 8
	LD	(screen_y), A

	LD	A, %10000000
	LDH	(R_BCPS), A		;load all colours.
	LD	HL, BCPD		;load gb palette 0 data.
	LD	A, %00011000
	LD	(HL), A
	LD	A, %01111111
	LD	(HL), A
	LD	A, %01010010
	LD	(HL), A
	LD	A, %01110010
	LD	(HL), A
	LD	A, %11001110
	LD	(HL), A
	LD	A, %01100001
	LD	(HL), A
	LD	A, %01001010
	LD	(HL), A
	LD	A, %01010001
	LD	(HL), A

	LD	A, %10001000
	LDH	(R_BCPS), A		;load all colours.
	LD	A, %00011000
	LD	(HL), A
	LD	A, %01111111
	LD	(HL), A
	LD	A, %11011100
	LD	(HL), A
	LD	A, %00010111
	LD	(HL), A
	LD	A, %00010101
	LD	(HL), A
	LD	A, %00001111
	LD	(HL), A
	XOR	A
	LD	(HL), A
	LD	(HL), A

	LD	A, %10010000
	LDH	(R_BCPS), A		;load all colours.
	LD	A, %00011000
	LD	(HL), A
	LD	A, %01111111
	LD	(HL), A
	LD	A, %00011111
	LD	(HL), A
	LD	A, %01100001
	LD	(HL), A
	LD	A, %00011001
	LD	(HL), A
	LD	A, %01011000
	LD	(HL), A
	XOR	A
	LD	(HL), A
	LD	(HL), A

	LD	A, %10011000
	LDH	(R_BCPS), A		;load all colours.
	LD	A, %11001110
	LD	(HL), A
	LD	A, %01100001
	LD	(HL), A
	XOR	A
	LD	(HL), A
	LD	(HL), A
	LD	A, %00000000
	LD	(HL), A
	LD	A, %00000001
	LD	(HL), A
	LD	A, %01000000
	LD	(HL), A
	LD	A, %00000001
	LD	(HL), A

	LD	A, 1			;level 1.
	CALL	LOAD_LEVEL
	CALL	DRAW_MAP

	LD	A, (level_bank_tiles)
	LD	(main_bank_rom), A
	LD	($2000), A
	XOR	A
	LD	(main_bank_dram), A
	LDH	(R_VBK), A

	LD	HL, $9000
	LD	DE, level_tiles
	LD	C, 29
	CALL	COPY_TILES_TO_VRAM

	LD	A, %00000001
	LDH	(R_IE), A		;enable vbi.
	EI

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; 
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

_LOOP:
	HALT
	JR	_LOOP

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; draw map
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

DRAW_MAP:
	LD	A, 20
	LD	(work_main), A		;do 20 lines.

	LD	A, (player_y8)
	SUB	9			;y center.
	LD	B, A			;b = start y.

	LD	A, (player_x8)
	SUB	10			;x center.
	LD	E, A			;e = start x.

	LD	A, (level_dx)
	LD	C, A			;c = level_dx.
	SUB	22
	LD	D, A			;d = add d to map x after each line.

	LD	HL, level_map
	PUSH	DE
	LD	D, 0
	LD	E, C

	XOR	A
	CP	B
	JR	Z, _DRAW_MAP_GET_START_EXIT

_DRAW_MAP_GET_START:
	ADD	HL, DE			;next map y.
	DEC	B
	JR	NZ, _DRAW_MAP_GET_START

_DRAW_MAP_GET_START_EXIT:
	POP	DE
	LD	C, E
	ADD	HL, BC			;start x added.
	LD	C, D
	LD	DE, $9821

_DRAW_MAP_Y_LOOP:
	LD	B, 22			;do 22 tiles a line.

_DRAW_MAP_X_LOOP:
	LD	A, (level_bank_map)	;map tile.
	LD	(main_bank_rom), A
	LD	($2000), A
	XOR	A
	LD	(main_bank_dram), A
	LDH	(R_VBK), A

_DRAW_MAP_WAIT_VRAM_ACCESS:
	LDH	A, (R_STAT)
        AND	$02
        JR	NZ, _DRAW_MAP_WAIT_VRAM_ACCESS

	LD	A, (HL)
	LD	(DE), A

	LD	A, (level_bank_attr)	;map tile attributes.
	LD	(main_bank_rom), A
	LD	($2000), A
	LD	A, %00000001
	LD	(main_bank_dram), A
	LDH	(R_VBK), A

	LDI	A, (HL)
	LD	(DE), A
	INC	DE

	DEC	B
	JR	NZ, _DRAW_MAP_X_LOOP

	ADD	HL, BC			;input adjusted.
	PUSH	HL
	LD	HL, 10
	ADD	HL, DE
	LD	D, H
	LD	E, L			;output adjusted.

	LD	HL, work_main
	DEC	(HL)
	POP	HL
	JR	NZ, _DRAW_MAP_Y_LOOP

	RET

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; load level x
; A = level x (bank x)
; 1 < x < n
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

LOAD_LEVEL:
	DEC	A
	LD	B, A
	ADD	B
	ADD	B
	INC	A			;a = a * 3 (each level takes 3 banks).
	LD	(level_bank_tiles), A
	INC	A
	LD	(level_bank_map), A
	INC	A
	LD	(level_bank_attr), A
	SUB	2
	LD	(main_bank_rom), A
	LD	($2000), A		;load 'data + tiles' rom bank.
	CALL	INIT_LEVEL		;init level x.

	LD	A, (player_y8)
	SUB	9
	LD	B, A
	XOR	A
	LD	HL, level_map
	CP	B
	JR	Z, _LOAD_LEVEL_LOOP_DONE

	LD	HL, level_dx
	LD	D, A			;a = 0.
	LD	E, (HL)
	LD	HL, level_map

_LOAD_LEVEL_LOOP:
	ADD	HL, DE
	DEC	B
	JR	NZ, _LOAD_LEVEL_LOOP

_LOAD_LEVEL_LOOP_DONE:
	LD	A, H
	LD	B, L
	LD	HL, screen_origo
	LDI	(HL), A
	LD	(HL), B
	RET

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; copy to memory (max 256 bytes)
; C  = amount of bytes
; DE = source
; HL = destination
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

COPY_TO_RAM:
	LD	A, (DE)
	INC	DE
	LDI	(HL), A
	DEC	C
	JR	NZ, COPY_TO_RAM
	RET

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; copy to video memory (max 256 bytes)
; C  = amount of bytes
; DE = source
; HL = destination
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

COPY_TO_VRAM:
	LDH	A, (R_STAT)
        AND	$02
        JR	NZ, COPY_TO_VRAM

	LD	A, (DE)
	INC	DE
	LDI	(HL), A
	DEC	C
	JR	NZ, COPY_TO_RAM
	RET

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; copy tiles to video memory (max 256 tiles)
; C  = amount of tiles
; DE = source
; HL = destination
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

COPY_TILES_TO_VRAM:
	LD	B, 16

_COPY_TILES_TO_VRAM_LOOP:
	LDH	A, (R_STAT)
        AND	$02
        JR	NZ, _COPY_TILES_TO_VRAM_LOOP

	LD	A, (DE)
	INC	DE
	LDI	(HL), A

	DEC	B
	JR	NZ, _COPY_TILES_TO_VRAM_LOOP
	DEC	C
	JR	NZ, COPY_TILES_TO_VRAM
	RET

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; set memory
; A  = byte to set the memory to
; HL = output start
; BC = amount of bytes (B * C)
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

SET_RAM:
	LD	D, C

SET_RAM_LOOP:
	LDI	(HL), A
	DEC	C
	JR	NZ, SET_RAM_LOOP
	LD	C, D			;return the counter.

	DEC	B
	JR	NZ, SET_RAM_LOOP

	RET

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; wait for the next vbi - power consumer
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

WAIT_VBI_POWER:
	PUSH	AF

WAIT_VBI_POWER_LOOP:
	LDH	A, (R_LY)
	CP	$90
	JR	NZ, WAIT_VBI_POWER_LOOP
	POP	AF
	RET

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; load sprites
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

LOAD_SPRITES_DMA:
        PUSH	AF
        LD	A, $C0
        LDH	(R_DMA), A
        LD	A, $28

_LOAD_SPRITES_DMA_WAIT:
        DEC	A
	JR	NZ, _LOAD_SPRITES_DMA_WAIT
	POP	AF
	RET

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; 32x32 multiplication table
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

mul_32: .DW 0 32 64 96 128 160 192 224 256 288 320 352
	.DW 384 416 448 480 512 544 576 608 640 672 704 736
	.DW 768 800 832 864 896 928 960 992
