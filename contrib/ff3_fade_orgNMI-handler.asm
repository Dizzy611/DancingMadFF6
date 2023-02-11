hirom

; MSUCurrentVolume   $1E32
; PlayVolume $1302 (target volume)
; fade Flag $130b (01: zero, 02: down, 03: up)

; hijack nmi Handler
org $d2fd49
JSR $fdb0
nop



; reset mute volume to allow fading
; line 238 stz MSUVolume
; line 239 stz MSUCurrentVolume
org $d2fab8
nop
nop
nop
nop
nop
nop

; overwrite the stz $1302 at line 552
org $d2fd0c
nop
nop
nop



;-----------------------------------------

org $d2fdb0
SEP #$20
LDA $130B
BEQ setFadeFlag
cmp #$01
Beq fadeZero
cmp #$02
Beq fadeDown
cmp #$03
Beq fadeUp
STZ $130b
REP #$30 
RTS

; 130b is a new flag which is set if target volume not equal current msu volume
; value 01: fade to zero, value 02: fade down, value 03: fade up
; dunno whether the game features fades up or down to a specific value
setFadeFlag:
LDA $1302 ; target volume
CMP $1E32 ; current msu volume
BEQ endNMI
cmp #$00 ; target volume =0, fade to zero
BNE $07
LDA #$01
STA $130b ;fadeZero
bra endNMI

LDA $1302 ; target volume
CMP $1E32 ; current msu volume
BCS $07 ; target volume > current volume? fade down
LDA #$02
STA $130b ;fade down
bra endNMI
LDA #$03
STA $130b ;fade up
endNMI:
REP #$30 
RTS

fadeZero:
lda $1E32 ; current volume
dec
dec
dec
cmp #$10
bcs $05
lda #$00
sta $130b ; erase Fade Flag
sta $002006
sta $1E32 ; current volume=target volume
REP #$30 
RTS

fadeDown:
lda $1E32
dec
dec
dec
cmp $1302 ;did we reach the target volume?
bcs $06
stz $130b
lda $1302 ; current volume=target volume
sta $1E32  
sta $002006
REP #$30 
RTS

fadeUp:
lda $1E32
inc
inc
inc
cmp #$fb; safety, if above it will mute and rise again
bcc $07
lda #$FF
STA $1302
bra $05
cmp $1302 ; did we reach the target volume?
bcc $06
stz $130b
lda $1302; current volume=target volume 
sta $1E32 
sta $002006
REP #$30 
RTS

