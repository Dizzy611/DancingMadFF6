; Includes
.include "Header.inc"
.include "SNES_Registers.inc"
.include "MSU.inc" 
.include "MSUPlay.inc"
.include "Snes_Init.asm"

VBlank:

	rep #$30		;A/Mem=16bits, X/Y=16bits
	phb
	pha
	phx
	phy
	phd

	sep #$20		; mem/A = 8 bit, X/Y = 16 bit
	lda #$01
	
	sta $2121
	lda STATUS_COLORL
	sta $2122
	lda STATUS_COLORH
	sta $2122
	
	lda #$00		;set DataBank = $00
	pha
	plb
	
	;JSR StatusColor - later, when we've at least got the MSU/tile stuff working.
	;update the joypad data
	JSR GetInput
	
	lda $4210		;clear NMI Flag
	rep #$30		;A/Mem=16bits, X/Y=16bits
	
	pld 
	ply 
	plx 
	pla 
	plb 
    rti
.include "2input.asm"


; Macros

; LoadPalette - Loads palette info into CGRAM
; In: SRC_ADDR, START, SIZE
; Mods: A,X
; Reqs: A/mem = 8 bit, X/Y = 16 bit
; out: Nothing.
.macro LoadPalette
	lda #\2        ;Load:  START COLOR
	sta $2121      ;Write: SELECT COLOR
	lda #:\1       ;Load:  SOURCE BANK
	ldx #\1        ;Load:  SOURCE ADDRESS
	ldy #(\3 * 2) ;Load:  SOURCE SIZE
	jsr DMAPalette
.endm

;LoadBlockToVRAM SRC_ADDRESS, DEST, SIZE
;   requires:  mem/A = 8 bit, X/Y = 16 bit
.macro LoadBlockToVRAM
	lda #$80
	sta $2115       ; Set VRAM transfer mode to word-access, increment by 1

	ldx #\2         ; DEST
	stx $2116       ; $2116: Word address for accessing VRAM.
	lda #:\1        ; SRCBANK
	ldx #\1         ; SRCOFFSET
	ldy #\3         ; SIZE
	jsr LoadVRAM
.endm

;MSUFadeIn      Fades a track in from 0 at a rate of one tick per vblank.
;   requires: mem/A = 8 bit, CURR_VOLUME is 0 for it not to be jarring.
;   modifies: A
;   input: Non
;   output: None

.macro MSUFadeIn
	lda #$00
	sta CURR_VOLUME
	sta MSU_VOLUME
volin\@:
	lda CURR_VOLUME
	cmp #$FF
	beq volidone\@
	adc 1
	sta MSU_VOLUME
	sta CURR_VOLUME
	wai
	jmp volin\@
volidone\@:
.endm

;MSUFadeOut, see above, but backwards. Don't call if volume already 0.
.macro MSUFadeOut
volout\@:
	lda CURR_VOLUME
	cmp #$00
	beq volodone\@
	sbc 1
	sta MSU_VOLUME
	sta CURR_VOLUME
	wai
	jmp volout\@
volodone\@:
.endm
	

;MSUChangeVolume. Simple, input: desired volume, changes A, outputs nothing.
.macro MSUChangeVolume
	lda \1
	sta MSU_VOLUME
.endm

;MSUPlay. Input either 1 (play without loop) or 3 (play with loop). This is a LONG one, as it also handles status display to some degree.
.macro MSUPlay
	lda CURR_TRACK
	sta MSU_TRACK
	stz MSU_TRACK+1
stilloading\@:	      ; Wait for the MSU to be done loading.
	lda MSU_STATUS    ;Bad Track?
	and #%00001000
	cmp #%00001000
	beq trkerr\@
	lda MSU_STATUS
	and #%01000000    ;Loading?
	cmp #%01000000
	wai
	beq stilloading\@
	lda #\1
	sta MSU_CONTROL
	wai
	jmp lastcheck\@
trkerr\@:             ;Flash track-error colors forever.
	lda RED_L
	sta STATUS_COLORL
	lda RED_H
	sta STATUS_COLORH
	wai
	lda YELLOW_L
	sta STATUS_COLORL
	lda YELLOW_H
	sta STATUS_COLORH
	wai
	jmp trkerr\@
lastcheck\@:          ;Flash yellow and green while we're waiting for it to be playing
	lda MSU_STATUS
	and #%00010000    ; Playing?
	cmp #%00010000
	beq loaddone\@
	lda GREEN_L
	sta STATUS_COLORL
	lda GREEN_H
	sta STATUS_COLORH
	wai
	lda YELLOW_L
	sta STATUS_COLORL
	lda YELLOW_H
	sta STATUS_COLORH
	wai
	jmp lastcheck\@
loaddone\@:
.endm

;WaitDSec: Wait a specified number of deciseconds by WAI, vblank NMI must be enabled.
;   input: Anything!
;   requires: Nothing!
;   output: Nothing!
.macro WaitDSec
.repeat (\1*6)
	wai
.endr
.endm
; Code


.bank 0
.section "MainCode"
 
Start:
	Snes_Init
	rep #$10
	sep #$20
	lda #RED_L             ; Initialize status color to the default red.
	sta STATUS_COLORL
	lda #RED_H 
	sta STATUS_COLORH
	jsr MSUCheck   ; check for MSU, set $0000 to $01 if it exists.
	lda MSU_EXISTS ; dummied out for now
	cmp #$01
	beq MSUFound
	jmp Forever
	
MSUFound:
	LoadPalette BG_Palette, 0, 4 ; Palette
	LoadBlockToVRAM Tiles, $0000, $07F0 ; Tiles
	LoadBlockToVRAM TileMap, $0400, $0800 ; Map
	jsr SetupVideo  ; setup the video mode
	jsr JoyInit     ; start joystick polling and enable vblank
	nop
	lda #$01        ; CURR_TRACK keeps record of what track we're at. Start off at 1.
	sta CURR_TRACK  ;
	lda #$FF        ; CURR_VOLUME tracks the current volume. Start it at max.
	sta CURR_VOLUME ;
	
Play:
	MSUChangeVolume CURR_VOLUME 
	lda #YELLOW_L     ; Change the red to yellow to signify loading.
	sta STATUS_COLORL
	lda #YELLOW_H
	sta STATUS_COLORH
	wai
	MSUPlay 3 	; Have the msu play CURR_TRACK
	
Playing:
	lda #GREEN_L                      ; Change the yellow to green to signify playing.
	sta STATUS_COLORL
	lda #GREEN_H
	sta STATUS_COLORH                 
	MSUChangeVolume CURR_VOLUME       ; Make sure the volume is where we want it.
	stz Joy1Press                     ; Clear the "buttons pressed" variable.
	stz Joy1Press+1
WaitButton:
; nothing here yet
	lda MSU_STATUS
	and #%00010000    ; Playing?
	cmp #%00010000
	bne Forever
	lda Joy1Press+1                   ; Check the controller, specifically we're interested in the 
	and #%00000001                    ; Right pressed?
	cmp #%00000001
	beq RightPressed
	lda Joy1Press+1
	and #%00000010                    ; Left pressed?
	cmp #%00000010           
	beq LeftPressed
	lda Joy1Press+1
	and #%00000100                    ; Down pressed? Try some prozac!
	cmp #%00000100
	beq DownPressed
	lda Joy1Press+1
	and #%00001000
	cmp #%00001000
	beq UpPressed                     ; Rise against your UpPressers!
	wai
	jmp WaitButton

RightPressed:                         ; Skip forward a track.
	lda CURR_TRACK                    
	cmp #$FF                          ; First, check if we're already at track 255. If so, don't bother.
	beq Playing                       ;
	inc A                             
	sta CURR_TRACK                    
	lda #CYAN_L						  ; Change the color to cyan so the user knows we're switching tracks.
	sta STATUS_COLORL
	lda #CYAN_H
	sta STATUS_COLORH
	jmp Play
	
LeftPressed:                          ; Skip back a track                     
	lda CURR_TRACK
	cmp #$01
	beq Playing
	dec A
	sta CURR_TRACK
	lda #CYAN_L
	sta STATUS_COLORL
	lda #CYAN_H
	sta STATUS_COLORH
	jmp Play
	
UpPressed:                            ; Increase volume by 5
	lda CURR_VOLUME                   ; First, check if the volume is already 255, if so, don't bother.
	cmp #$FF
	beq Playing
	adc #$05
	sta CURR_VOLUME
	jmp Playing
	
DownPressed:                          ; Decrease volume by 5  
	lda CURR_VOLUME                  
	cmp #$00
	beq Playing
	sbc #$05
	sta CURR_VOLUME
	jmp Playing
	
Forever:
	lda #RED_L                       ; Return to normal colors
	sta STATUS_COLORL 
	lda #RED_H
	sta STATUS_COLORH
	wai
	jmp Forever

 ; Subroutines

SetupVideo:
	php       ; Push registers
	
	lda #$00
	sta $2105 ; Video mode 0: 8x8 tiles, 256 colors per tile, 1 palette, 256 colors    
	          ; ;	total. 1 layer.
			  
    lda #$04   
	sta $2107 ; Our tile map is at $0400 (in the VRAM)
	
	stz $210B ; Our char map is at $0000 (in the VRAM)
	
	lda #$01  ; Enable BG1
	sta $212c
	
	lda #$FF  ; Scrolling stuff? Not explained yet.
	sta $210E
	sta $210E 

	lda #$0F  ; Screen on, fullbright!
	sta $2100 ;
	
	plp       ; Pop registers
	rts
	
DMAPalette:

	php       ; Push registers.
	
	stx $4302 ; Write: DMA source
	sta $4304 ; Write: DMA bank
	sty $4305 ; Write: DMA transaction size
	stz $4300 ; Zero:  DMA mode (byte with no increment)
	
	lda #$22  ; Destination: $2122 - Color Data
	sta $4301 ; 
	
	lda #$01  ; Initialize transfer
	sta $420b ;
	
	plp       ; Pop registers.
	rts       ; Return

LoadVRAM:
    phb
    php         ; Preserve Registers

    stx $4302   ; Store Data offset into DMA source offset
    sta $4304   ; Store data Bank into DMA source bank
    sty $4305   ; Store size of data block

    lda #$01
    sta $4300   ; Set DMA mode (word, normal increment)
    lda #$18    ; Set the destination register (VRAM write register)
    sta $4301
    lda #$01    ; Initiate DMA transfer (channel 1)
    sta $420B

    plp         ; restore registers
    plb
    rts         ; return

MSUCheck:
	lda MSU_ID
	cmp #$53	; 'S'
	bne NoMSU	; Stop checking if it's wrong
	lda MSU_ID+1
	cmp #$2D	; '-'
	bne NoMSU
	lda MSU_ID+2
	cmp #$4D	; 'M'
	bne NoMSU
	lda MSU_ID+3
	cmp #$53	; 'S'
	bne NoMSU
	lda MSU_ID+4
	cmp #$55	; 'U'
	bne NoMSU
	lda MSU_ID+5
	cmp #$31	; '1'
	bne NoMSU
	lda #$01
	sta MSU_EXISTS
	rts
NoMSU:
	stz MSU_EXISTS
	rts
	
StatusColor: ; Dummied out for now. Increment color while we're playing.
	lda MSU_EXISTS
	cmp #$01
	lda #$01  ; Select color 1 (red by default)
	sta $2121
	ldx $213b ; Read current color
	inx       ; Increment.
	lda #$01  ; Reset position in CGRAM
	sta $2121
	stx $2122 ; Store current color
	rts
	
	
	
.ends


	
 ; Data

.bank 1 slot 0
.org 0 
.section "TileData"
.include "tiles.inc"
.ends
