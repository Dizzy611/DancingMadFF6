; Header stuff. Needed to put our routines in the right place in ROM.

.MEMORYMAP 
    SLOTSIZE $10000
    DEFAULTSLOT 0
    SLOT 0 $0000
.ENDME
.ROMBANKSIZE $10000
.ROMBANKS 48

.HIROM
.FASTROM
.BASE $C0 ; Needed to fix ExHiROM compat.

.BACKGROUND "ff3.sfc"

; Defines

.DEFINE PlayCommand $1300
.DEFINE PlayTrack $1301
.DEFINE PlayVolume $1302

.DEFINE CurrentCommand $1304
.DEFINE CurrentTrack $1305
.DEFINE CurrentVolume $1306

.DEFINE LastCommand $1308
.DEFINE LastTrack $1309
.DEFINE LastVolume $130A
.DEFINE FadeFlag $130B
.DEFINE APUIO0 $2140
.DEFINE APUIO2 $2142

.DEFINE FadeStep $20
.DEFINE FadeStepClamp $E0
.DEFINE FadeInStartVolume $20

.DEFINE OriginalNMIHandler $1500
.DEFINE ReturnCommand 
; Was using $1E00-$1E07 earlier, but these are used for storing Veldt monsters. $1E20-$1E27 are unused. 
; $1E30-$1E38 are in $1600-$1FFF, which FF6 save/load copies to SRAM. Keep MSULastTrackSet outside
; that region so this state does not persist across save/load.
; MSULastTrackSet currently uses $7EF001 because the in-engine sound DP candidates are active at runtime.


.DEFINE MSUExists          $1E30
.DEFINE MSUCurrentTrack    $1E31
.DEFINE MSUCurrentVolume   $1E32
.DEFINE SPCCommandTemp     $1E33
.DEFINE SPCVolumeTemp      $1E34
.DEFINE DancingFlag        $1E35
.DEFINE TrainFlag          $1E36
.DEFINE SPCMusicMuteFlag   $1E37
.DEFINE FadeInPending      $1E38
.DEFINE MSULastTrackSet    $7EF001


; MSU Registers

.DEFINE MSUStatus        $2000
.DEFINE MSUDRead         $2001
.DEFINE MSUID            $2002
.DEFINE MSUDSeek         $2000
.DEFINE MSUTrack         $2004
.DEFINE MSUVolume        $2006
.DEFINE MSUControl       $2007

; MSU Status Flags Definition

.DEFINE MSUStatus_DataBusy     %10000000
.DEFINE MSUStatus_AudioBusy    %01000000
.DEFINE MSUStatus_AudioLooping %00100000
.DEFINE MSUStatus_AudioPlaying %00010000
.DEFINE MSUStatus_BadTrack     %00001000

; MSU Control Values Definition
.DEFINE MSUControl_Pause       %00000100
.DEFINE MSUControl_PlayNoLoop  %00000001
.DEFINE MSUControl_PlayLoop    %00000011
.DEFINE MSUControl_Stop        %00000000

; SPC Commands
.DEFINE SPCSubSong $82
.DEFINE SPCFade $81
.DEFINE SPCPlaySong $10
.DEFINE SPCInterrupt $14 ; TODO: Find out what this actually does. Is it a pause? A stop? Something else?
.DEFINE SPC89 $89
.DEFINE SPCSFX $18

; Subroutine hooks

.BANK 0
.ORG $ff10
.SECTION "NMIOverride" SIZE 4 OVERWRITE

jml NMIHandle

.ENDS

.BANK 5
.ORG $148
.SECTION "PlayCommand" SIZE 4 OVERWRITE

jml CommandHandle

.ENDS

.BANK 5
.ORG $182
.SECTION "TrackLoader" SIZE 4 OVERWRITE

jsl MSUMain

.ENDS

.BANK 5
.ORG $1A6
.SECTION "SPCSongLoadHook" SIZE 4 OVERWRITE

jml SPCSongLoadHook

.ENDS


; Overriding Shadow cutscene event code to add our own stuff
.BANK 10
.ORG $CD6F
.SECTION "CUTSCENEFIX" SIZE 4 OVERWRITE
.DB $B2 $EA $FF $08 ; Jump to $D2FFEA
.ENDS

.BANK 10 
.ORG $CDE7 
.SECTION "CUTSCENEFIX2" SIZE 15 OVERWRITE
.DB $B2 $D0 $FF $08 $FD $FD $FD $FD $FD $FD $FD $FD $FD $FD $FD ; Jump to $D2FFD0, then lots of NOPs.
.ENDS

;.BANK 10
;.ORG $CDF6
;.SECTION "CUTSCENEFIX2" SIZE 5 OVERWRITE
;.DB $B2 $F1 $FF $08 $FD ; Jump to $D2FFF1, then NOP
;.ENDS

.BANK 10
.ORG $CE5D
.SECTION "CUTSCENEFIX3" SIZE 4 OVERWRITE
.DB $B2 $F8 $FF $08 ; Jump to $D2FFF8
.ENDS

.BANK 10
.ORG $CF0A
.SECTION "CUTSCENEFIX4" SIZE 4 OVERWRITE
.DB $B2 $E3 $FF $08 ; Jump to $D2FFE3
.ENDS


; Our free space to put our own stuff.

.BANK 18
.ORG $FA72
.SECTION "MSU" SIZE 1400 OVERWRITE

; Macros

; Input: Address of RAM with volume to change to (in SNES notation)
; Modifies: A
; No output.
.MACRO ChangeVolume
    lda \1
    bmi forcesub\@; If we're negative, since it's unsigned, we want to skip the comparisons and subtract.
    cmp #$00      ; If we're being asked to silence, we don't want to change silence.
    beq skip\@
    cmp #$0A      ; Don't subtract if volume is already less than 10
    bcc skip\@
    sbc #$40      ; Subtract 64
    cmp #$0A      ; If it's now less than 10, set it to 10.
    bcs skip\@
    lda #$0A
skip\@:
    sta MSUCurrentVolume
    sta MSUVolume
    jmp done\@
forcesub\@:
    sbc #$20
    jmp skip\@
done\@:
.ENDM

; Input: Error character to indicate (uses FF3 character table)
; $80-$99 A-Z $9A-$B3 a-z $B4-BD 0-9 
; Modifies: Terra's name in RAM to "ERROR(number)" (addresses $1602 through $1607 modified)
; Output: None

.MACRO SignalError
    lda \1
    sta $1607
    lda #$84 ; E
    sta $1602
    lda #$91 ; R
    sta $1603
    sta $1604 
    sta $1606
    lda #$8E ; O
    sta $1605
.ENDM

; End Macros

; Main Code

CommandHandle:
    ; Check for specific commands
    lda PlayCommand
    cmp #SPCSubSong
    bne +
    jmp SubSongHandle
+
    cmp #SPCFade
    bne +
    jmp FadeCommandHandle
+
    cmp #SPC89
    bne +
    jmp SPC89Handle
+
    jmp OriginalCommand
    
    
SubSongHandle: ; Handle subsong changes, primarily used during Dancing Mad
    ; Are we currently playing a Dancing Mad part?
    lda MSULastTrackSet
    cmp #$65
    bne +
    ; The first time this is called during Dancing Mad Part 1 it seems to be a sort of 'false positive' at the start, and causes this code to skip part 1 entirely.
    ; so wait until it's called the second time.
    lda DancingFlag
    cmp #$01
    bne setflag
    jmp DancingMadPart2
+
    cmp #$66
    bne +
    jmp DancingMadPart3
+
    jmp OriginalCommand
setflag:
    lda #$01
    sta DancingFlag
    jmp OriginalCommand

FadeCommandHandle:
    lda PlayVolume
    beq +
    lda #$01
    sta FadeInPending
    jmp OriginalCommand
+
    stz FadeInPending
    jmp OriginalCommand
    
SPC89Handle: ; Seems to be a different subsong change, used during Phantom Train to switch to the music from the sound effects.
    lda PlayTrack
    cmp #$20
    bne +
    lda #$01
    sta TrainFlag
    lda #$ff
    sta PlayVolume
    jsl MSUMain
+
    jmp OriginalCommand
    
DancingMadPart2:
    ; Play Part 2 of Dancing Mad
    lda #$66
    sta PlayTrack
    lda #$ff
    sta PlayVolume
    jsl MSUMain
    jmp OriginalCommand
    
DancingMadPart3:
    ; Play Part 3 of Dancing Mad
    lda #$67
    sta PlayTrack
    lda #$ff
    sta PlayVolume
    jsl MSUMain
    jmp OriginalCommand

OriginalCommand:
    lda PlayCommand
    beq +
    jml $c5014c
+
    jml $c50171
    
    
MSUMain:
    ; Has the MSU already been found? If so, skip this step
    lda MSUExists
    cmp #$01
    beq MSUFound
    ; Check for MSU presence
    jsr MSUCheck
    cmp #$01
    beq MSUFound
    ; If not found, do the original SPC code
    stz SPCMusicMuteFlag
    jmp OriginalCode
MSUFound:
TFCheck: ; Phantom train flag clearing. Clears the phantom train flag if any track other than the phantom train is played.
    lda TrainFlag
    cmp #$01
    bne BattleCheck
    lda PlayTrack
    cmp #$20
    beq BattleCheck
    cmp #$24 ; Avoid clearing the flag during battle/victory sequence.
    beq BattleCheck
    cmp #$2f
    beq BattleCheck
    stz TrainFlag
BattleCheck:
    ; --- Special track handling via jump table ---
    ; Direct table indexed by PlayTrack for O(1) dispatch.
    .DEFINE SpecialTrackLimit $55

SpecialTrackDispatch:
    lda PlayTrack
    cmp.b #SpecialTrackLimit
    bcs NormalTrackHandler
    asl a
    tax
    jmp (SpecialTrackHandlers,x)

NormalTrackHandler:
    jmp SpecialHandlingBack

; Handlers by track ID ($00-$54)
SpecialTrackHandlers:
    ; $00-$0F
    .DW SilenceHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler

    ; $10-$1F
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler

    ; $20-$2F
    .DW PhantomTrainHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW BattleThemeHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler

    ; $30-$3F
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW Kefka1Handler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler

    ; $40-$4F
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler
    .DW NormalTrackHandler

    ; $50-$54
    .DW Kefka5Handler
    .DW RePlayHandler
    .DW NormalTrackHandler
    .DW Ending1Handler
    .DW Ending2Handler

; --- Individual handlers ---

SilenceHandler:
    ; Silence (FF6 does a *lot* of track 0 requests, we're specifically masking
    ; this one to reduce calls to the MSU.)
    jmp ShutUpAndLetMeTalk

PhantomTrainHandler:
    jml PhantomTrain

BattleThemeHandler:
    jml BattleTheme

Kefka1Handler:
    ; Kefka's Dancing Mad Parts 1-3: remap to part 1 and continue normal processing.
    lda #$65
    sta PlayTrack
    jmp SpecialHandlingBack

Kefka5Handler:
    jml Kefka5

RePlayHandler:
    ; Track $51 is a signal to re-play the last track.
    lda MSUCurrentTrack
    sta PlayTrack
    jmp SpecialHandlingBack

Ending1Handler:
    jml Ending1

Ending2Handler:
    jml Ending2

; --- End jump table handlers ---

SpecialHandlingBack:
    ; Are we playing it?
    lda PlayTrack
    cmp MSULastTrackSet
    ; If not, skip to NotPlaying
    bne NotPlaying
    ; Are we *really* playing it?
    lda MSUStatus
    and #MSUStatus_AudioPlaying
    beq NotPlaying
    ; If so, is the volume the same?
    lda PlayVolume
    cmp MSUCurrentVolume
    beq DoNothing
    ; If not, change our volume to match the new value.
    ; TODO: Fade to the new volume
    ChangeVolume PlayVolume
DoNothing:
    ; Either way, silence the SPC volume and return
    jmp SilenceAndReturn
NotPlaying:
    ; Okay, so we're not currently playing this track. Is the volume $00?
    lda PlayVolume
    cmp #$00
    ; If not, continue, if so, set our current volume to 00 and tell the MSU to stop, then do the SPC code.
    bne ContinueToPlay
    jmp ShutUpAndLetMeTalk
ContinueToPlay:
    ; Grab our track to play and push it at the MSU if it's not silence.
    lda PlayTrack
    cmp #$00
    bne SetTrack
    jmp ShutUpAndLetMeTalk
SetTrack:
    ; Fix for Sabin/Figaro bug: set $1309 to the actual last track set before changing LastTrackSet.
    ; fix for the fix: if MSULastTrackSet is the same as PlayTrack, don't clobber LastTrack
    lda MSULastTrackSet
    cmp PlayTrack
    beq +
    sta LastTrack
+
    lda MSUCurrentVolume
    sta LastVolume
    lda PlayTrack
    sta MSUTrack
    ; Write the last track set to an unused area of HiRAM, this should persist even after a load game.
    sta MSULastTrackSet
    stz MSUTrack+1
    ; Wait for the MSU to either be done loading or to return a track error
WaitMSU:
    lda MSUStatus
    and #MSUStatus_AudioBusy
    bne WaitMSU
    lda MSUStatus
    and #MSUStatus_BadTrack
    beq PlayMSU ; If it's not a bad track, don't jump to the SPC code 
    lda PlayTrack ; If it's a bad track and we're playing track 65, 66, or 67 (Dancing Mad tracks), play track 3b instead (original dancing mad trio)
    cmp #$65
    beq +
    cmp #$66
    beq +
    cmp #$67
    beq +
    jmp ShutUpAndLetMeTalk
+
    lda #$3b
    sta PlayTrack
    jmp ShutUpAndLetMeTalk
PlayMSU:
    ; Fade-in only when the SPC explicitly requested a non-zero fade.
    lda FadeInPending
    cmp #$01
    bne _PlayMSUImmediateVolume
    stz FadeInPending
    lda PlayVolume
    cmp.b #FadeInStartVolume
    bcc _PlayMSUImmediateVolume
    lda.b #FadeInStartVolume
    sta MSUCurrentVolume
    sta MSUVolume
    lda.b #$03
    sta FadeFlag
    bra _PlayMSUVolumeReady
_PlayMSUImmediateVolume:
    lda PlayVolume
    sta MSUCurrentVolume
    sta MSUVolume
    stz FadeFlag
_PlayMSUVolumeReady:
    ; Set our currently playing track to this one.
    lda PlayTrack
    sta MSUCurrentTrack
    ; Check against our looping track list. This subroutine will return the proper MSUControl value in A.
    jsr WillItLoop
    cmp #$00         ; If we're stopping, stop cleanly.
    bne TimeToPlay
    jmp ShutUp
TimeToPlay:
    sta MSUControl
    ; We're now playing the track. Silence the SPC music and return
    jmp SilenceAndReturn

; End Main Code

; Subroutines



; Check for MSU. If it's found, A and MSUExists will be $01

MSUCheck:
    lda MSUID
    cmp #$53    ; 'S'
    bne +   ; Stop checking if it's wrong
    lda MSUID+1
    cmp #$2D    ; '-'
    bne +
    lda MSUID+2
    cmp #$4D    ; 'M'
    bne +
    lda MSUID+3
    cmp #$53    ; 'S'
    bne +
    lda MSUID+4
    cmp #$55    ; 'U'
    bne +
    lda MSUID+5
    cmp #$31    ; '1'
    bne +
    lda #$01
    sta MSUExists
    rts
+
    lda #$00
    stz MSUExists
    rts

; Check if the track to play is in our list of non-looping tracks, if so return $01 in A, if not, return $03 in A. Also, certain tracks essentially mean "stop", so handle those too.
WillItLoop:
    lda PlayTrack
    cmp #$00   ; Silence
    beq WILStop
    cmp #$02   ; Opening part 1
    beq WILNope
    cmp #$03   ; Opening part 2
    beq WILNope
    cmp #$04   ; Opening part 3
    beq WILNope
    cmp #$27   ; Aria de Mezzo Carattare
    beq WILNope
    cmp #$51   ; Silence
    beq WILStop
    cmp #$53   ; Ending part 1
    beq WILNope
    cmp #$54   ; Ending part 2
    beq WILNope
    lda #MSUControl_PlayLoop
    rts
WILNope:
    lda #MSUControl_PlayNoLoop
    rts
WILStop:
    lda #MSUControl_Stop
    rts

; Battle and victory theme handling
BattleTheme:
; Commented out to potentially work around #104
;    lda MSUStatus   ; Are we on Revision 2 or greater? If so, we have Resume support. Handle this specially.
;    and #%00000111
;    cmp #$02
;    bcs ResumeSupportBT
    jmp ResumeSupportBT
;    jml SpecialHandlingBack ; If not, do our normal stuff.
ResumeSupportBT:
    lda #MSUControl_Pause ; Pause the current track.
    sta MSUControl
    jml SpecialHandlingBack

; Kefka 5 handling
Kefka5:
; If MSU-1 currently playing Dancing Mad 4 (which leads directly into 5 in our copy), then continue playing without modifying the MSU-1 state,
; otherwise process the track as normal.
    lda MSUCurrentTrack
    cmp #$52
    bne +
    lda MSUStatus
    and #MSUStatus_AudioPlaying
    beq +
    jml SilenceAndReturn
+
    jml SpecialHandlingBack

; Phantom train handling.

PhantomTrain:
    lda TrainFlag ; If the train flag is on, play the song, otherwise, let the SPC handle it.
    cmp #$01
    bne +
    jml SpecialHandlingBack 
+
    jml ShutUpAndLetMeTalk
    
; Ending part 2 handling.
Ending2:
; We don't use this track, instead piggybacking onto the end of Ending Part 1, so just silence and return.
    jml SilenceAndReturn

; Try to stop it from repeatedly restarting ending part 1
Ending1:
    lda MSUCurrentTrack
    cmp #$53
    bne +
    lda MSUStatus
    and #MSUStatus_AudioPlaying
    beq +
    jml SilenceAndReturn
+
    jml SpecialHandlingBack

; Return routines

ShutUp:
    stz MSUCurrentTrack
    stz SPCMusicMuteFlag
    stz FadeInPending
    stz FadeFlag
    stz MSUVolume
    stz MSUTrack
    stz MSUTrack+1
    stz MSUControl
SilenceAndReturn:
    ; Skip silencing playtrack if we're currently playing problematic tracks (ones that rely on track timing)
    lda PlayTrack
    cmp #$27 ; Opera
    beq OriginalCode
    cmp #$45 ; Opera
    beq OriginalCode
    cmp #$53 ; Ending
    beq OriginalCode
    cmp #$54 ; Ending
    beq OriginalCode
    cmp #$38 ; Good Night jingle
    beq OriginalCode
    lda #$01
    sta SPCMusicMuteFlag
OriginalCode:
    lda PlayTrack
    cmp CurrentTrack
    rtl

ShutUpAndLetMeTalk:
    stz MSUCurrentTrack
    stz SPCMusicMuteFlag
    stz FadeInPending
    stz FadeFlag
    stz MSUVolume
    stz MSUTrack
    stz MSUTrack+1
    stz MSUControl
    jmp OriginalCode

NMIHandle:
    php
    rep #$30
    pha
    phx
    phy
    phd
    phb
    sep #$20
    lda #$00
    pha
    plb
    jsr FadeRoutine
    rep #$30
    plb
    pld
    ply
    plx
    pla
    plp
    jml OriginalNMIHandler

SPCSongLoadHook:
    lda MSUCurrentTrack
    bne _BlockSPCSongLoad
    ; Pass-through path: replay clobbered instructions and resume PlaySong.
    lda $02
    sta APUIO2
    lda $01
    jml $c501ab

_BlockSPCSongLoad:
    ; MSU owns music: send SPC command $F1 (stop song), then exit.
    lda.b #$f1
    sta APUIO0
_WaitStopAck:
    cmp APUIO0
    bne _WaitStopAck
    inc a
    and.b #$7f
    sta $1e
    jml $c50171

; End Subroutines

; Fade routine - Credit goes to Conn
FadeRoutine:
    sep #$20
    lda FadeFlag
    beq _SetFadeFlag
    cmp.b #$01
    beq _FadeZero
    cmp.b #$02
    beq _FadeDown
    cmp.b #$03
    beq _FadeUp
    stz FadeFlag
    rep #$30
    rts

_SetFadeFlag:
    lda PlayVolume          ; target volume
    cmp MSUCurrentVolume    ; current msu volume
    beq _EndFadeRoutine
    cmp.b #$00              ; target volume = 0? fade to zero
    bne +
    lda.b #$01
    sta FadeFlag
    bra _EndFadeRoutine
+
    lda PlayVolume          ; target volume
    cmp MSUCurrentVolume    ; current msu volume
    bcs +                   ; target >= current? fade up
    lda.b #$02
    sta FadeFlag            ; fade down
    bra _EndFadeRoutine
+
    lda.b #$03
    sta FadeFlag            ; fade up
_EndFadeRoutine:
    rep #$30
    rts

_FadeZero:
    lda MSUCurrentVolume    ; current volume
    sec
    sbc.b #FadeStep
    bcs +                   ; no underflow, check if result is near zero
    lda.b #$00              ; underflow: volume was < $0A, snap to zero
    sta FadeFlag            ; erase fade flag
    bra _FadeZeroStore
+
    cmp.b #FadeStep
    bcs _FadeZeroStore      ; result >= $0A, just store it
    lda.b #$00
    sta FadeFlag            ; erase fade flag
_FadeZeroStore:
    sta MSUVolume
    sta MSUCurrentVolume    ; current volume = target volume
    rep #$30
    rts

_FadeDown:
    lda MSUCurrentVolume
    sec
    sbc.b #FadeStep
    bcc +                   ; underflow: snap to PlayVolume
    cmp PlayVolume          ; gone below the target volume?
    bcs _FadeDownStore      ; if still >= target, just store
+
    stz FadeFlag
    lda PlayVolume          ; current volume = target volume
_FadeDownStore:
    sta MSUCurrentVolume
    sta MSUVolume
    rep #$30
    rts

_FadeUp:
    lda MSUCurrentVolume
    clc
    adc.b #FadeStep
    bcs +                   ; overflow: cap to $FF
    cmp.b #FadeStepClamp    ; safety: cap before the next step would wrap
    bcc _FadeUpCheck
+
    lda.b #$FF
    sta PlayVolume
    bra _FadeUpClear
_FadeUpCheck:
    cmp PlayVolume          ; did we reach the target volume?
    bcc _FadeUpStore
_FadeUpClear:
    stz FadeFlag
    lda PlayVolume          ; current volume = target volume
_FadeUpStore:
    sta MSUCurrentVolume
    sta MSUVolume
    rep #$30
    rts

.ENDS

; Ran out of space again...
.BANK 18
.ORG $FFD0
.SECTION "YETMOREEVENTCODE" SIZE 18 OVERWRITE
; (New) Cutscene 2 fix
.DB $F0 $00 $B0 $1F $51 $DF $37 $37 $51 $DF $05 $05 $51 $DF $29 $29 $B1 $FE
.ENDS 

; Ran out of space... >.>
.BANK 18
.ORG $FFE3
.SECTION "MOREEVENTCODE" SIZE 7 OVERWRITE
; Cutscene 4 fix
.DB $F0 $00 $61 $07 $04 $FF $FE
.ENDS

.BANK 18
.ORG $FFEA
.SECTION "EVENTCODE" SIZE 22 OVERWRITE
; Place to store event code and other miscellany.

; Shadow cutscene fix: ask to play track $00 during this scene. $F0 $00 is "play track 0", $3D $10 and $41 $10 are the existing code
; from this event that I've overwritten, $FE is the event code version of an "rtl".
.DB $F0 $00 $3D $10 $41 $10 $FE
; (Old) Cutscene 2 fix. Stubbed out due to a new, much longer fix that doesn't fit here anymore.
.DB $FD $FD $FD $FD $FD $FD $FD 
; Cutscene 3 fix
.DB $F0 $00 $50 $BC $52 $BC $FE
.ENDS

