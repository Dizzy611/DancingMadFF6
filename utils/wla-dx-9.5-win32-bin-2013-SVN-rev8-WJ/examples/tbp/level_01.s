
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; tank bomb panic
; written by ville helin <vhelin@cc.hut.fi> in 2000
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

.INCLUDE "defines.i"

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; level x
;
; bank a
; - level dimensions
; - level related routines
; - tile data
;
; bank a+1
; - level map
;
; bank a+2
; - level map tile attributes
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

.BANK 1
.ORG $0

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; init level
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

INIT_LEVEL:
	LD	HL, level_dx
	LD	A, 128
	LD	(HL), A
	LD	HL, level_dy
	LD	A, 64
	LD	(HL), A
	LD	HL, level_dx_x18
	XOR	A
	LDI	(HL), A			;level_dx_x18 = 2304 = $900.
	LD	A, $09
	LD	(HL), A    
	RET

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; level data (char map)
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

.INCDIR "/dosd/tiles/"

level_tiles:
.INCBIN "LEVEL_01T.BIN"

.BANK 2
.ORG $0

level_map:
.INCBIN "LEVEL_01M.BIN"

.BANK 3
.ORG $0

level_map_attributes:
.INCBIN "LEVEL_01MA.BIN"
