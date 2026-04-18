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
.DEFINE APUIO1 $2141
.DEFINE APUIO2 $2142
.DEFINE APUIO3 $2143

.DEFINE FadeStep $20
.DEFINE FadeStepClamp $E0
.DEFINE FadeInStartVolume $20

.DEFINE OriginalNMIHandler $1500

; Was using $1E00-$1E07 earlier, but these are used for storing Veldt monsters. $1E20-$1E27 are unused. 
; $1E30-$1E38 are in $1600-$1FFF, which FF6 save/load copies to SRAM. Keep MSULastTrackSet outside
; that region so this state does not persist across save/load.
; MSULastTrackSet currently uses $7EF001 because the in-engine sound DP candidates are active at runtime.


.DEFINE MSUExists          $1E30
.DEFINE MSUCurrentTrack    $1E31
.DEFINE MSUCurrentVolume   $1E32
.DEFINE DancingFlag        $1E33
.DEFINE TrainFlag          $1E34
.DEFINE FadeInPending      $1E35
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
.DEFINE SPCInterrupt $14
.DEFINE SPC89 $89
.DEFINE SPCSFX $18

; Constants 
.DEFINE SpecialTrackLimit $55

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

.BANK 0
.ORG $B8C7
.SECTION "EventCmdFAHook" SIZE 4 OVERWRITE

jml EventCmdFAHook

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
    ; If MSU is playing, apply fade intent now. This matters for EventCmd_f3 which
    ; loads the previous song at volume 0 then sends a separate $81 fade-up.
    lda MSUCurrentTrack
    beq _FadeCmdNoActiveMSU

    lda PlayVolume
    beq _FadeCmdToZero

    cmp MSUCurrentVolume
    beq _FadeCmdClearPending
    bcs _FadeCmdUp

    lda #$02
    sta FadeFlag
    stz FadeInPending
    jmp OriginalCommand

_FadeCmdUp:
    lda #$03
    sta FadeFlag
    ; Seed from silence so fade-up is audible right away.
    lda MSUCurrentVolume
    bne _FadeCmdClearPending
    lda PlayVolume
    cmp.b #FadeInStartVolume
    bcc _FadeCmdClearPending
    lda.b #FadeInStartVolume
    sta MSUCurrentVolume
    sta MSUVolume
    bra _FadeCmdClearPending

_FadeCmdToZero:
    lda #$01
    sta FadeFlag

_FadeCmdClearPending:
    stz FadeInPending
    jmp OriginalCommand

_FadeCmdNoActiveMSU:
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
    ; Special track handling via jump table


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

RePlayHandler:
    ; If we're seeing track $51, the game read back its own RAM and found
    ; the silence track we substituted. Re-play whatever the MSU has.
    lda MSUCurrentTrack
    beq +
    sta PlayTrack
+
    jmp SpecialHandlingBack

PhantomTrainHandler:
    jml PhantomTrain

BattleThemeHandler:
    jml BattleTheme

Kefka1Handler:
    lda #$65
    sta PlayTrack
    jmp SpecialHandlingBack

Kefka5Handler:
    jml Kefka5

Ending1Handler:
    jml Ending1

Ending2Handler:
    jml Ending2

; --- End jump table handlers ---

SpecialHandlingBack:
    ; Are we playing it?
    lda PlayTrack
    cmp MSUCurrentTrack
    ; If not, skip to NotPlaying
    bne NotPlaying
    ; Are we *really* playing it?
    lda MSUStatus
    and #MSUStatus_AudioPlaying
    beq NotPlaying
DoNothing:
    jmp OriginalCode
NotPlaying:
    ; Fall through even on volume=0. EventCmd_f3 sends volume=0 play then a
    ; separate $81 fade-up, so we need MSUCurrentTrack set for that to work.
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
    ; If a fade-in is pending, seed a low volume and let the NMI fade handle it.
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
    ; We're now playing the track. Return
    jmp OriginalCode

; End Main Code

; Subroutines

; Event command $FA hook: wait for song end.
; When MSU is playing, check MSU status instead of APUIO3.
EventCmdFAHook:
    lda MSUCurrentTrack
    beq _EventCmdFAVanilla
    ; Ending tracks ($53, $54) are one continuous MSU file; don't block on MSU status here.
    cmp #$53
    beq _EventCmdFAVanilla
    cmp #$54
    beq _EventCmdFAVanilla

    lda MSUStatus
    and #MSUStatus_AudioPlaying
    bne _EventCmdFAWait
    jml $c0b8cd

_EventCmdFAVanilla:
    lda APUIO3
    beq _EventCmdFAAdvance

_EventCmdFAWait:
    jml $c0b8cc

_EventCmdFAAdvance:
    jml $c0b8cd



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
    cmp #$41   ; Overture part 1
    beq WILNope
    cmp #$42   ; Overture part 2
    beq WILNope
    cmp #$43   ; Overture part 3
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
    jml OriginalCode
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
; We don't use this track, instead piggybacking onto the end of Ending Part 1, so just return.
    jml OriginalCode

; Try to stop it from repeatedly restarting ending part 1
Ending1:
    lda MSUCurrentTrack
    cmp #$53
    bne +
    lda MSUStatus
    and #MSUStatus_AudioPlaying
    beq +
    jml OriginalCode
+
    jml SpecialHandlingBack

; Return routines

ShutUp:
    stz MSUCurrentTrack
    stz FadeInPending
    stz FadeFlag
    stz MSUVolume
    stz MSUTrack
    stz MSUTrack+1
    stz MSUControl
OriginalCode:
    ; When MSU is playing, mask PlayTrack for the SPC:
    ; - Position-marker tracks ($27, $41-$46, $53-$54) pass through at zero volume
    ;   so the SPC keeps updating APUIO1 for EventCmd_f9.
    ; - Everything else gets masked to $51 to avoid the double-play problem.
    lda MSUCurrentTrack
    beq _OrigCodeDone
    lda PlayTrack
    cmp.b #$27
    beq _OrigCodeZeroVol
    cmp.b #$41
    bcc _OrigCodeMask
    cmp.b #$47
    bcc _OrigCodeZeroVol
    cmp.b #$53
    bcc _OrigCodeMask
    cmp.b #$55
    bcc _OrigCodeZeroVol
_OrigCodeMask:
    lda.b #$51
    sta PlayTrack
    bra _OrigCodeDone
_OrigCodeZeroVol:
    stz PlayVolume
_OrigCodeDone:
    lda PlayTrack
    cmp CurrentTrack
    rtl

ShutUpAndLetMeTalk:
    stz MSUCurrentTrack
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

; End Subroutines

; Fade routine - Credit goes to Conn
FadeRoutine:
    sep #$20
    lda FadeFlag
    beq _EndFadeRoutine
    cmp.b #$01
    beq _FadeZero
    cmp.b #$02
    beq _FadeDown
    cmp.b #$03
    beq _FadeUp
    stz FadeFlag
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

