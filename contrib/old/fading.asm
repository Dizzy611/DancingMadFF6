hirom

; MSUCurrentVolume   $1E32
; PlayVolume $1302 (target volume)
; fade Flag $130b (01: zero, 02: down, 03: up)



; reset current nmi handler to original
; line 82-line88 jml NMIHandle
org $00FF10
JML $001500 

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

;------------------------------
;new nmi hooks
;new nmi Hook 1 in rOm
org $C00196
JSL $7ef000
nop 
nop
; original is  LDA $4210 STZ $420B

;new nmi Hook 2 in rAm 
org $C31398
JSL $7Ef010  
NOP 
; original is LDA $4210 LDA #$00

;new nmi Hook 3 in rAm 
org $C2826b
JSR $f020  
; original is LDX #$0000 

;new nmi Hook 4 in rOm 
org $C10BB7
JSL $7ef030  
; original is LDA $004210

;---------------------------------
; new nmi handlers in ram

; this will be in rom $7ef000 nmi Hook 1
org $d2fd60
LDA $4210
STZ $420b
JSR $f050
RTL

;this will be in ram $7ef010 nmi Hook 2
org $d2fd70
LDA $4210 
JSR $f050
LDA #$00
RTL


;this will be in ram $7ef020 nmi Hook 3
org $d2fd80
LDX #$0000 
JSR $f050
RTS

;this will be in ram $7ef030 nmi Hook 4
org $d2fd90
LDA $004210
JSR $f050
RTL


;-----------------------------------------
;this will be in ram 7ef050
org $d2fdb0
LDA $130B
BEQ setFadeFlag
cmp #$01
Beq fadeZero
cmp #$02
Beq fadeDown
cmp #$03
Beq fadeUp
STZ $130b
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
RTS


;------------------------------
;move code to ram
org $C0004F
JSL moveToRAM

org $d2fe80
moveToRAM:
PHP
REP #$30
PHA
PHX
PHY
PHB
LDA #$0150 ; transfer $150 bytes, give more if you need
LDX #$FD60 ; rom origin address $(D2)FD00
LDY #$f000 ; ram destination address ($(7E)f000
MVN $D27E ; bank D2 -> 7E
PLB
PLY
PLX
PLA
PLP
JSL $C50000
RTL