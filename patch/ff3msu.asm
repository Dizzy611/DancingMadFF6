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
.DEFINE DMOverlayInit      $1E36
.DEFINE MSULastTrackSet    $7EF001

; Runtime copy of ROM metadata for debugger visibility during title flow.
; 14 bytes mirrored from C4:B000 to high WRAM to avoid FMV state overlap.
.DEFINE DMMetaMirror       $7EF440

; FMV RAM allocations ($1E20-$1E2F are unused in FF6)
.DEFINE FMVState           $1E20
.DEFINE FMVNMIReady        $1E21
.DEFINE FMVSubFrame        $1E22
.DEFINE FMVActiveBuffer    $1E23
.DEFINE FMVFrameCount      $1E24   ; 16-bit
.DEFINE FMVFrameCurrent    $1E26   ; 16-bit
.DEFINE FMVPrevButtons     $1E28   ; 16-bit
.DEFINE FMVNewButtons      $1E2A   ; 16-bit
.DEFINE FMVSavedCmd1300    $1E2C
.DEFINE FMVSavedTrack1301  $1E2D
.DEFINE FMVSavedVol1302    $1E2E
.DEFINE FMVFlags           $1E2F

.DEFINE FMVPaletteBuffer   $7EF300 ; 256 bytes: $7EF300-$7EF3FF
.DEFINE FMVHeaderScratch   $7EF400 ; 16 bytes:  $7EF400-$7EF40F
.DEFINE FMVDebugMarker     $7EF418

; FMV constants
.DEFINE FMVTrack           $68
.DEFINE FMVHeaderSize      $10
.DEFINE TitleScreenExt2    $7E5000
.DEFINE TitleInitRoutine   $7E507F
.DEFINE TitlePlaySong      $7E5093
.DEFINE TitleState01Patch  $5280

; CPU/PPU I/O used by FMV helpers
.DEFINE JOY1L              $4218
.DEFINE JOY1H              $4219
.DEFINE INIDISP            $2100
.DEFINE BGMODE             $2105
.DEFINE BG1SC              $2107
.DEFINE BG12NBA            $210B
.DEFINE BG1HOFS            $210D
.DEFINE BG1VOFS            $210E
.DEFINE TS                 $212D
.DEFINE VMAIN              $2115
.DEFINE VMADDL             $2116
.DEFINE VMADDH             $2117
.DEFINE VMDATAL            $2118
.DEFINE VMDATAH            $2119
.DEFINE TM                 $212C
.DEFINE CGADD              $2121
.DEFINE CGDATA             $2122
.DEFINE DMAEN              $420B
.DEFINE DMA0CTRL           $4300
.DEFINE DMA0DEST           $4301
.DEFINE DMA0SRCL           $4302
.DEFINE DMA0SRCH           $4303
.DEFINE DMA0SRCB           $4304
.DEFINE DMA0SIZEL          $4305
.DEFINE DMA0SIZEH          $4306
.DEFINE DMA1CTRL           $4310
.DEFINE DMA1DEST           $4311
.DEFINE DMA1SRCL           $4312
.DEFINE DMA1SRCH           $4313
.DEFINE DMA1SRCB           $4314
.DEFINE DMA1SIZEL          $4315
.DEFINE DMA1SIZEH          $4316

; FMV video layout constants
.DEFINE TILE_COLS          32
.DEFINE TILE_ROWS          18
.DEFINE TOTAL_TILES        576
.DEFINE BLANK_TILE_INDEX   767 ; Reserved zero tile kept outside streamed 0-575 range.
.DEFINE PALETTE_BYTES      256
.DEFINE TILEMAP_VRAM       $0000
.DEFINE TILEDATA_A         $1000
.DEFINE TILEDATA_B         $4000
.DEFINE BG1_BASE_A         $01
.DEFINE BG1_BASE_B         $04
.DEFINE BG1SC_VALUE        $00
.DEFINE SUBFRAMES_PER_FRAME 4
.DEFINE TILE_CHUNK_0       4736
.DEFINE TILE_CHUNK_1       5120
.DEFINE TILE_CHUNK_2       5120
.DEFINE TILE_CHUNK_3       3456

; FMV transient scratch in high WRAM
.DEFINE FMVScratch0        $7EF410 ; 16-bit
.DEFINE FMVScratch1        $7EF412 ; 16-bit
.DEFINE FMVScratch2        $7EF414 ; 16-bit


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

.BANK 2
.ORG $680F
.SECTION "TitleScreenHook" SIZE 4 OVERWRITE

jml TitleScreenHook

.ENDS


; Patch metadata block for diagnostics/versioning.
; File offset: 0x04B000 (PC offset in 4MB HiROM image).
; Layout:
;   +0x00..0x03: magic "DMVS"
;   +0x04..0x09: build date ASCII YYMMDD
;   +0x0A: installer option flags (bit0=TWUE, bit1=MP, bit2=CSR)
;   +0x0B: metadata version
;   +0x0C..0x0D: reserved
.BANK 4
.ORG $B000
.SECTION "PATCHMETADATA" SIZE 14 OVERWRITE

.DB "DMVS"
.INCLUDE "build_date.inc"
.DB $00
.DB $01
.DB $00
.DB $00

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
    ; Same track already playing - normally a no-op (matches vanilla SPC).
    ; If vanilla forces a replay by writing $FF to CurrentTrack, sync volume.
    lda CurrentTrack
    cmp.b #$FF
    bne +
    lda PlayVolume
    sta MSUCurrentVolume
    sta MSUVolume
+
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
    cmp #$38   ; Nighty Night
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

; NMI handler keeps normal fade processing outside FMV, but while FMV is active
; it only publishes VBlank availability (counter semantics) for the FMV loop.
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
    lda FMVState
    beq _NMIHandleNormal
    inc FMVNMIReady
    bra _NMIHandleDone
_NMIHandleNormal:
    jsr FadeRoutine
    ; Gate: only call overlay when title cutscene code is present at $7E5000.
    sep #$20
    lda.l $7E5000
    cmp.b #$4C
    bne _SkipOverlay
    jsl TitleMetadataOverlay
_SkipOverlay:
_NMIHandleDone:
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
    bne +
    stz MSUControl          ; volume hit zero: stop MSU so AudioPlaying clears
+
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

.BANK 4
.ORG $BA00
.SECTION "TITLEOVERLAY" SIZE 1036 OVERWRITE

; If title code is active, install a date overlay once by patching the title
; sprite table in WRAM and uploading digit glyph tiles into OBJ VRAM.
TitleMetadataOverlay:
    sep #$20
    lda.l $7E5280
    cmp.b #$A4
    beq _TitleOverlaySignatureOK
    ; After FMV hook install, $7E5280 = $22 (JSL), $7E5283 = $C4 (bank).
    cmp.b #$22
    bne _TitleOverlayNotActive
    lda.l $7E5283
    cmp.b #$C4
    beq _TitleOverlaySignatureOK
    bra _TitleOverlayNotActive
_TitleOverlaySignatureOK:
    ; Valid title context — either original state or our FMV hook.

    lda DMOverlayInit
    cmp.b #$01
    beq _TitleOverlayDone

    jsr TitleMetadataPrepareSprites
    lda.b #$01
    sta DMOverlayInit
    ; Self-seal NMI gate: the title JMP at $7E5000 has already executed
    ; during cutscene init and is never re-entered.  Clearing it ensures
    ; no future NMI (gameplay, save/load) can reach this overlay code.
    ; Soft reset re-decompresses the cutscene blob, restoring $4C.
    lda.b #$00
    sta.l $7E5000
    bra _TitleOverlayDone

_TitleOverlayNotActive:
    stz DMOverlayInit

_TitleOverlayDone:
    rep #$30
    rtl

TitleMetadataPrepareSprites:
    rep #$10               ; Ensure 16-bit index — callers may have 8-bit (sep #$30).
    ; Mirror metadata from ROM to WRAM in case this NMI path initializes first.
    ldx.w #$0000
_MetaMirrorLoop:
    lda.l $C4B000,x
    sta.l DMMetaMirror,x
    inx
    cpx.w #$000E
    bne _MetaMirrorLoop

    ; --- Build display: "DM" + date + optional flag indicators ---
    ; Task base is ($90,$A0). Nintendo's 4 entries are untouched.
    ; All sprites at y_off=$20 (screen Y=$C0, below Nintendo at $B0).
    ; "DM" at x_off $00/$08, date at $10-$48, flags starting at $50.
    ; All offsets have bit7 clear → "small" (16x16 under OBSEL=$63).
    phb
    lda.b #$7E
    pha
    plb

    ldy.w #$0010           ; byte offset past Nintendo's 4 entries

    ; --- "D" prefix sprite ---
    lda.b #$00
    sta $7A98,y            ; x_off
    lda.b #$20
    sta $7A99,y            ; y_off
    lda.b #$A4             ; tile# for "D"
    sta $7A9A,y
    lda.b #$33
    sta $7A9B,y            ; attr
    iny
    iny
    iny
    iny

    ; --- "M" prefix sprite ---
    lda.b #$08
    sta $7A98,y
    lda.b #$20
    sta $7A99,y
    lda.b #$A6             ; tile# for "M"
    sta $7A9A,y
    lda.b #$33
    sta $7A9B,y
    iny
    iny
    iny
    iny

    ; --- 6 date-digit sprites (YYMMDD, skip century) ---
    ldx.w #$0000           ; digit index 0-5
_DateSpriteLoop:
    lda.l DMMetaMirror+4,x ; ASCII char from build date (YYMMDD)
    sec
    sbc.b #$30             ; ASCII '0' → 0
    cmp.b #$0A
    bcc +
    lda.b #$00             ; clamp non-digit to 0
+
    phx
    rep #$20               ; 16-bit A to clear B (high byte of C)
    and.w #$00FF
    tax
    sep #$20
    lda.l DigitTileNumTbl,x
    plx
    sta $7A9A,y            ; tile number

    txa                    ; digit index
    asl a
    asl a
    asl a                  ; × 8
    clc
    adc.b #$10             ; shift right for "DM" prefix
    sta $7A98,y            ; x_off
    lda.b #$20
    sta $7A99,y            ; y_off
    lda.b #$33
    sta $7A9B,y            ; attr

    iny
    iny
    iny
    iny
    inx
    cpx.w #$0006
    bne _DateSpriteLoop

    ; --- Optional flag indicator sprites ---
    ; Flags byte at DMMetaMirror+$0A: bit0=TWUE, bit1=MP, bit2=CSR.
    ; Displayed as single letters T, P, C at x_off $40+ in 8px steps.
    lda.b #$40
    pha                    ; running x_off on stack

    lda.l DMMetaMirror+$0A
    and.b #$01             ; TWUE?
    beq _SkipTWUE
    pla
    sta $7A98,y
    clc
    adc.b #$08
    pha
    lda.b #$20
    sta $7A99,y
    lda.b #$A8             ; tile# for "T"
    sta $7A9A,y
    lda.b #$33
    sta $7A9B,y
    iny
    iny
    iny
    iny
_SkipTWUE:

    lda.l DMMetaMirror+$0A
    and.b #$02             ; MP?
    beq _SkipMP
    pla
    sta $7A98,y
    clc
    adc.b #$08
    pha
    lda.b #$20
    sta $7A99,y
    lda.b #$AA             ; tile# for "P"
    sta $7A9A,y
    lda.b #$33
    sta $7A9B,y
    iny
    iny
    iny
    iny
_SkipMP:

    lda.l DMMetaMirror+$0A
    and.b #$04             ; CSR?
    beq _SkipCSR
    pla
    sta $7A98,y
    clc
    adc.b #$08
    pha
    lda.b #$20
    sta $7A99,y
    lda.b #$AC             ; tile# for "C"
    sta $7A9A,y
    lda.b #$33
    sta $7A9B,y
    iny
    iny
    iny
    iny
_SkipCSR:

    pla                    ; discard running x_off

    ; Compute and store final sprite count.
    ; Y = byte offset past all entries.  Entries = (Y-$10)/4 + 4 Nintendo.
    tya
    sec
    sbc.b #$10
    lsr a
    lsr a
    clc
    adc.b #$04
    sta $7A97

    plb

    ; --- Upload digit font tiles into OBJ VRAM ---
    ; OBSEL=$63 → OBJ first table at VRAM $6000, second table at $7000.
    ; Attr bit 0 = 1 ($33) selects name table 1 at $7000.
    ; 16x16 sprite at tile N uses sub-tiles N, N+1, N+16, N+17.
    ; We write the 8x8 digit glyph into the top-left sub-tile only;
    ; the other three sub-tiles are already zero (ClearVRAM during InitTitle).
    ;
    ; VMAIN ($2115) must be $80 (increment after high-byte write) for 16-bit
    ; STA $2118.  The engine also expects $80, so we set it and leave it.
    ;
    ; IMPORTANT: This function may be called with any DBR (NMI uses $00,
    ; TitleScreenHook uses $7E).  ROM table reads already use lda.l.
    ; I/O register writes MUST use absolute long addressing (sta.l) so
    ; they always hit bank $00 hardware regardless of DBR.
    sep #$20
    lda.b #$80
    sta.l $002115

    ; Upload each glyph's 8x8 tile into its top-left sub-tile VRAM slot.
    ; No zero-fill needed: ClearVRAM zeroed all VRAM during title init, and
    ; our tile area ($7800+) is not touched by LoadTitleGfx.
    rep #$30
    ldx.w #$0000           ; outer digit index (0-9)
_UploadDigitLoop:
    ; Set VRAM destination for this digit's TL sub-tile.
    phx
    txa
    asl a                  ; × 2 (word-sized table entries)
    tax
    lda.l DigitVramAddrTbl,x  ; long,X → reads from bank $C4 ✓
    sta.l $002116
    plx

    ; Compute font source byte offset: digit × 32 bytes.
    phx
    txa
    asl a
    asl a
    asl a
    asl a
    asl a                  ; × 32
    tax                    ; X = source byte offset

    ; Upload 16 words (32 bytes = one 8x8 4bpp tile).
    ldy.w #$0010
_UploadTileLoop:
    lda.l DigitFontTiles,x    ; long,X → reads from bank $C4 ✓
    sta.l $002118
    inx
    inx
    dey
    bne _UploadTileLoop

    plx                    ; restore outer digit index
    inx
    cpx.w #$000F           ; 10 digits + 5 letters
    bne _UploadDigitLoop

    ; Leave VMAIN=$80 — this is the engine's expected state.
    sep #$20
    rts

; Tile number lookup: digits 0-9, then letters D, M, T, P, C.
; 16x16 sprites need stride-2 tile numbers to avoid sub-tile overlap.
; Tiles at $80+ map to VRAM $7800+, ABOVE LoadTitleGfx range ($7000-$77DB).
; TR/BL/BR sub-tiles stay zeroed from ClearVRAM (transparent).
DigitTileNumTbl:
    .DB $80,$82,$84,$86,$88,$8A,$8C,$8E,$A0,$A2
    .DB $A4,$A6,$A8,$AA,$AC             ; D, M, T, P, C

; VRAM word addresses for each glyph's top-left sub-tile.
; Name table 1 base $7000 + tile_number × $10.
DigitVramAddrTbl:
    .DW $7800,$7820,$7840,$7860,$7880,$78A0,$78C0,$78E0,$7A00,$7A20
    .DW $7A40,$7A60,$7A80,$7AA0,$7AC0   ; D, M, T, P, C

; 8x8 4bpp glyph font: digits 0-9, then letters D, M, T, P, C.
; Format: 16 bytes planes 0-1 interleaved, then 16 bytes planes 2-3.
; Planes 2-3 mirror planes 0-1 so set pixels hit color index 5 ($77BD,
; the brightest color in OBJ palette 1 — matches the Nintendo text).
DigitFontTiles:
    ; 0
    .DB $3C,$00,$66,$00,$6E,$00,$76,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    .DB $3C,$00,$66,$00,$6E,$00,$76,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    ; 1
    .DB $18,$00,$38,$00,$18,$00,$18,$00,$18,$00,$18,$00,$7E,$00,$00,$00
    .DB $18,$00,$38,$00,$18,$00,$18,$00,$18,$00,$18,$00,$7E,$00,$00,$00
    ; 2
    .DB $3C,$00,$66,$00,$06,$00,$0C,$00,$30,$00,$60,$00,$7E,$00,$00,$00
    .DB $3C,$00,$66,$00,$06,$00,$0C,$00,$30,$00,$60,$00,$7E,$00,$00,$00
    ; 3
    .DB $3C,$00,$66,$00,$06,$00,$1C,$00,$06,$00,$66,$00,$3C,$00,$00,$00
    .DB $3C,$00,$66,$00,$06,$00,$1C,$00,$06,$00,$66,$00,$3C,$00,$00,$00
    ; 4
    .DB $0C,$00,$1C,$00,$3C,$00,$6C,$00,$7E,$00,$0C,$00,$0C,$00,$00,$00
    .DB $0C,$00,$1C,$00,$3C,$00,$6C,$00,$7E,$00,$0C,$00,$0C,$00,$00,$00
    ; 5
    .DB $7E,$00,$60,$00,$7C,$00,$06,$00,$06,$00,$66,$00,$3C,$00,$00,$00
    .DB $7E,$00,$60,$00,$7C,$00,$06,$00,$06,$00,$66,$00,$3C,$00,$00,$00
    ; 6
    .DB $1C,$00,$30,$00,$60,$00,$7C,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    .DB $1C,$00,$30,$00,$60,$00,$7C,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    ; 7
    .DB $7E,$00,$66,$00,$06,$00,$0C,$00,$18,$00,$18,$00,$18,$00,$00,$00
    .DB $7E,$00,$66,$00,$06,$00,$0C,$00,$18,$00,$18,$00,$18,$00,$00,$00
    ; 8
    .DB $3C,$00,$66,$00,$66,$00,$3C,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    .DB $3C,$00,$66,$00,$66,$00,$3C,$00,$66,$00,$66,$00,$3C,$00,$00,$00
    ; 9
    .DB $3C,$00,$66,$00,$66,$00,$3E,$00,$06,$00,$0C,$00,$38,$00,$00,$00
    .DB $3C,$00,$66,$00,$66,$00,$3E,$00,$06,$00,$0C,$00,$38,$00,$00,$00
    ; D
    .DB $7C,$00,$66,$00,$66,$00,$66,$00,$66,$00,$66,$00,$7C,$00,$00,$00
    .DB $7C,$00,$66,$00,$66,$00,$66,$00,$66,$00,$66,$00,$7C,$00,$00,$00
    ; M
    .DB $C6,$00,$EE,$00,$FE,$00,$D6,$00,$C6,$00,$C6,$00,$C6,$00,$00,$00
    .DB $C6,$00,$EE,$00,$FE,$00,$D6,$00,$C6,$00,$C6,$00,$C6,$00,$00,$00
    ; T
    .DB $7E,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$00,$00
    .DB $7E,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$18,$00,$00,$00
    ; P
    .DB $7C,$00,$66,$00,$66,$00,$7C,$00,$60,$00,$60,$00,$60,$00,$00,$00
    .DB $7C,$00,$66,$00,$66,$00,$7C,$00,$60,$00,$60,$00,$60,$00,$00,$00
    ; C
    .DB $3C,$00,$66,$00,$60,$00,$60,$00,$60,$00,$66,$00,$3C,$00,$00,$00
    .DB $3C,$00,$66,$00,$60,$00,$60,$00,$60,$00,$66,$00,$3C,$00,$00,$00

.ENDS

; FMV code region at $C4:A4C0.
.BANK 4
.ORG $A4C0
.SECTION "FMVCODE" SIZE 5440 OVERWRITE

; WLA-DX width state can leak across sections. Set known 8-bit entry widths
; before any bare immediates in this JML/JSL hook region.
.ACCU 8
.INDEX 8

; Patch WRAM TitleState_01 to jump into our FMV hook after title decompression.
TitleScreenHook:
    php
    sep #$30
    phb
    lda.b #$7e
    pha
    plb
    ; Only patch if WRAM has the expected bytes — this hook can fire from non-title flows too.
    lda TitleState01Patch
    cmp.b #$a4
    bne _TitleScreenHookDone
    lda TitleState01Patch+1
    cmp.b #$15
    bne _TitleScreenHookDone
    lda TitleState01Patch+2
    cmp.b #$d0
    bne _TitleScreenHookDone
    lda TitleState01Patch+3
    cmp.b #$12
    bne _TitleScreenHookDone
    lda TitleState01Patch+4
    cmp.b #$e6
    bne _TitleScreenHookDone

    ; Mirror patch metadata for debugger visibility and overlay rendering.
    ldx.b #$00
_TitleHookCopyLoop:
    lda.l $C4B000,x
    sta.l DMMetaMirror,x
    inx
    cpx.b #$0E
    bne _TitleHookCopyLoop

    stz DMOverlayInit      ; force overlay re-init (VRAM wiped by soft reset)

    stz FMVState
    stz FMVFlags
    lda.b #$10
    sta FMVDebugMarker
    ; Write JSL FMV_TitleState01Hook + RTS over the 5 bytes
    lda.b #$22                          ; JSL opcode
    sta TitleState01Patch
    lda.b #<FMV_TitleState01Hook
    sta TitleState01Patch+1
    lda.b #>FMV_TitleState01Hook
    sta TitleState01Patch+2
    lda.b #$c4                          ; Bank $C4
    sta TitleState01Patch+3
    lda.b #$60                          ; RTS opcode
    sta TitleState01Patch+4
_TitleScreenHookDone:
    plb
    plp
    jml TitleScreenExt2

; Replaces TitleState_01 in WRAM. First visit runs FMV, second visit restores
; the original bytes and lets the native title do its thing.
FMV_TitleState01Hook:
    php
    sep #$30
    
    ; Blank screen immediately so we don't flash stale graphics
    lda #$80
    sta INIDISP
    
    lda #$20
    sta FMVDebugMarker

    lda FMVState
    bne _TitleState01Restore

    lda #$01
    sta FMVState
    stz FMVFlags
    lda #$21
    sta FMVDebugMarker
    jsr FMV_RunPlayback
    bcs _TitleState01Reinit

    lda #$22
    sta FMVDebugMarker
    lda FMVFlags
    bne _TitleState01Skip

_TitleState01Restore:
    lda #$23
    sta FMVDebugMarker
    jsr FMV_RestoreTitleState01
    plp
    rtl

_TitleState01Reinit:
    lda #$24
    sta FMVDebugMarker
    jsr FMV_RestoreTitleState01
    stz $19
    stz $15
    plp
    rtl

_TitleState01Skip:
    lda #$25
    sta FMVDebugMarker
    jsr FMV_RestoreTitleState01
    lda #$80
    sta $06
    plp
    rtl

FMV_RestoreTitleState01:
    sep #$30
    stz FMVState
    stz FMVNMIReady
    stz FMVFlags
    lda #$a4
    sta TitleState01Patch
    lda #$15
    sta TitleState01Patch+1
    lda #$d0
    sta TitleState01Patch+2
    lda #$12
    sta TitleState01Patch+3
    lda #$e6
    sta TitleState01Patch+4
    rts

; Check for MSU-1 hardware. Carry set = found, carry clear = missing.
FMV_CheckMSU:
    lda MSUExists
    cmp #$01
    beq _FMVCheckMSUFound

    lda MSUID
    cmp #$53
    bne _FMVCheckMSUMissing
    lda MSUID+1
    cmp #$2D
    bne _FMVCheckMSUMissing
    lda MSUID+2
    cmp #$4D
    bne _FMVCheckMSUMissing
    lda MSUID+3
    cmp #$53
    bne _FMVCheckMSUMissing
    lda MSUID+4
    cmp #$55
    bne _FMVCheckMSUMissing
    lda MSUID+5
    cmp #$31
    bne _FMVCheckMSUMissing

    lda #$01
    sta MSUExists
_FMVCheckMSUFound:
    sec
    rts

_FMVCheckMSUMissing:
    stz MSUExists
    clc
    rts

; Bootstrap: read the FMV header and start audio. Carry set = success.
FMV_RunBootstrap:
    php
    phb
    phd
    rep #$30
    sep #$20
    lda #$00
    pha
    plb

    stz FMVFlags
    stz FMVNMIReady

    jsr FMV_CheckMSU
    bcc _FMVBootstrapFail

    jsr FMV_ReadHeader
    bcc _FMVBootstrapFail

    jsr FMV_StartAudio
    sec
    bra _FMVBootstrapDone

_FMVBootstrapFail:
    clc

_FMVBootstrapDone:
    rep #$30
    pld
    plb
    plp
    rtl

; Read and validate the 16-byte FMV header (magic "FFVI", then frame count).
FMV_ReadHeader:
    sep #$20
    rep #$10
    lda #$40
    sta FMVDebugMarker
    ; Seek to start of .msu data stream
    lda #$00
    sta MSUDSeek
    sta MSUDSeek+1
    sta MSUDSeek+2
    sta MSUDSeek+3

_FMVWaitSeek:
    lda MSUStatus
    and #MSUStatus_DataBusy
    bne _FMVWaitSeek

    lda #$41
    sta FMVDebugMarker
    ldx #$0000
_FMVReadHeaderLoop:
    lda MSUDRead
    sta FMVHeaderScratch,x
    inx
    cpx #FMVHeaderSize
    bne _FMVReadHeaderLoop

    lda #$42
    sta FMVDebugMarker
    lda FMVHeaderScratch+0
    cmp #$46
    bne _FMVBadHeader
    lda FMVHeaderScratch+1
    cmp #$46
    bne _FMVBadHeader
    lda FMVHeaderScratch+2
    cmp #$56
    bne _FMVBadHeader
    lda FMVHeaderScratch+3
    cmp #$49
    bne _FMVBadHeader

    rep #$20
    lda FMVHeaderScratch+4
    sta FMVFrameCount
    sep #$20

    lda #$43
    sta FMVDebugMarker
    sec
    rts

_FMVBadHeader:
    lda #$4f
    sta FMVDebugMarker
    rep #$20
    stz FMVFrameCount
    sep #$20
    clc
    rts

; Save current audio state and start the FMV track through MSUMain.
FMV_StartAudio:
    sep #$20
    rep #$10
    lda PlayCommand
    sta FMVSavedCmd1300
    lda PlayTrack
    sta FMVSavedTrack1301
    lda PlayVolume
    sta FMVSavedVol1302

    lda #FMVTrack
    sta PlayTrack
    lda #$ff
    sta PlayVolume
    jsl MSUMain
    lda #MSUControl_PlayNoLoop
    sta MSUControl
    rts

; Restore pre-FMV audio state.
FMV_StopAudio:
    sep #$20
    rep #$10
    stz MSUCurrentTrack
    stz FadeInPending
    stz FadeFlag
    stz MSUVolume
    stz MSUTrack
    stz MSUTrack+1
    stz MSUControl
    lda FMVSavedCmd1300
    sta PlayCommand
    lda FMVSavedTrack1301
    sta PlayTrack
    lda FMVSavedVol1302
    sta PlayVolume
    rts

; Wait for one VBlank tick from NMI. FMVNMIReady is a counter so we don't
; lose a frame boundary on transient overlap.
FMV_WaitVBlank:
    sep #$20
    rep #$10
_FMVWaitNMI:
    lda FMVNMIReady
    beq _FMVWaitNMI
    dec FMVNMIReady
    rts

; Read JOY1, compute rising-edge presses into FMVNewButtons.
FMV_ReadController:
    rep #$30
    lda JOY1L
    pha
    eor FMVPrevButtons
    and $01,s
    sta FMVNewButtons
    pla
    sta FMVPrevButtons
    sep #$20
    rts

; Main FMV playback loop. Carry set = natural end, clear = interrupted/failed.
FMV_RunPlayback:
    php
    phb
    phd
    rep #$30
    sep #$20
    lda #$00
    pha
    plb

    lda #$30
    sta FMVDebugMarker
    stz FMVFlags
    stz FMVNMIReady

    jsr FMV_CheckMSU
    bcs _FMVPlaybackHaveMSU
    jmp _FMVPlaybackFail
_FMVPlaybackHaveMSU:

    lda #$31
    sta FMVDebugMarker

    jsr FMV_ReadHeader
    bcs _FMVPlaybackHaveHeader
    jmp _FMVPlaybackFail
_FMVPlaybackHaveHeader:

    lda #$32
    sta FMVDebugMarker

    jsr FMV_InitVideo
    lda #$33
    sta FMVDebugMarker
    lda #$81
    sta $4200
    stz FMVNMIReady
    jsr FMV_StartAudio
    lda #$34
    sta FMVDebugMarker

    rep #$20
    stz FMVFrameCurrent
    sep #$20
    stz FMVSubFrame
    stz FMVActiveBuffer
    stz FMVPrevButtons
    stz FMVPrevButtons+1
    stz FMVNewButtons
    stz FMVNewButtons+1

_FMVMainLoop:
    lda #$35
    sta FMVDebugMarker

    lda FMVSubFrame
    beq _FMVDo0
    cmp #$01
    beq _FMVDo1
    cmp #$02
    beq _FMVDo2
    jsr FMV_DoSubFrame3
    bra _FMVAfterSubFrame
_FMVDo0:
    jsr FMV_DoSubFrame0
    bra _FMVAfterSubFrame
_FMVDo1:
    jsr FMV_DoSubFrame1
    bra _FMVAfterSubFrame
_FMVDo2:
    jsr FMV_DoSubFrame2

_FMVAfterSubFrame:
    inc FMVSubFrame
    lda FMVSubFrame
    cmp #SUBFRAMES_PER_FRAME
    bne _FMVMainLoop

    stz FMVSubFrame
    rep #$20
    lda FMVFrameCurrent
    inc a
    sta FMVFrameCurrent
    cmp FMVFrameCount
    bcc _FMVPlaybackCheckInput
    sep #$20
    jsr FMV_StopVideo
    jsr FMV_StopAudio
    sec
    bra _FMVPlaybackDone

_FMVPlaybackCheckInput:
    ; Poll input once per completed video frame (after subframe 3)
    sep #$20
    jsr FMV_ReadController
    rep #$20
    lda FMVNewButtons
    and #$0080
    beq +
    sep #$20
    lda #$01
    sta FMVFlags
    jsr FMV_StopVideo
    jsr FMV_StopAudio
    clc
    bra _FMVPlaybackDone
+
    sep #$20
    bra _FMVMainLoop

_FMVPlaybackFail:
    lda #$3f
    sta FMVDebugMarker
    clc

_FMVPlaybackDone:
    lda #$3e
    sta FMVDebugMarker
    rep #$30
    pld
    plb
    plp
    rts

; Set up PPU for FMV display.
FMV_InitVideo:
    sep #$20
    rep #$10
    lda #$80
    sta INIDISP

    lda #$01
    sta BGMODE
    lda #BG1SC_VALUE
    sta BG1SC
    lda #BG1_BASE_A
    sta BG12NBA

    lda #$80
    sta VMAIN
    rep #$20

    ; Clear the blank tile in both buffers (used for letterbox rows)
    lda #TILEDATA_A + (BLANK_TILE_INDEX * 16)
    sta VMADDL
    sep #$20
    ldy #$0010
_FMVZeroBlankA:
    stz VMDATAL
    stz VMDATAH
    dey
    bne _FMVZeroBlankA

    rep #$20
    lda #TILEDATA_B + (BLANK_TILE_INDEX * 16)
    sta VMADDL
    sep #$20
    ldy #$0010
_FMVZeroBlankB:
    stz VMDATAL
    stz VMDATAH
    dey
    bne _FMVZeroBlankB

    sep #$20
    lda #$80
    sta VMAIN

    lda #<TILEMAP_VRAM
    sta VMADDL
    lda #>TILEMAP_VRAM
    sta VMADDH

    rep #$30
    ldy #$0000
    ldx #$0000
_FMVTilemapRow:
    cpx #TILE_ROWS
    bcs _FMVBlankRows

    phx
    txa
    cmp #$0009
    bcc _FMVTopHalfRow
    lda #$0004
    bra _FMVRowBaseReady
_FMVTopHalfRow:
    lda #$0000
_FMVRowBaseReady:
    sta FMVScratch0

    sep #$20
    lda #$00
    sta FMVFlags
_FMVTilemapCol:
    tya
    sta VMDATAL
    lda FMVFlags
    lsr a
    lsr a
    lsr a
    clc
    adc FMVScratch0
    asl a
    asl a
    pha
    rep #$20
    tya
    sta FMVScratch1
    sep #$20
    lda FMVScratch1+1
    and #$03
    sta FMVScratch2
    pla
    ora FMVScratch2
    sta VMDATAH
    iny
    lda FMVFlags
    inc a
    sta FMVFlags
    cmp #TILE_COLS
    bne _FMVTilemapCol

    rep #$20
    plx
    inx
    bra _FMVTilemapRow

_FMVBlankRows:
    sep #$20
    ldy #448
_FMVBlankLoop:
    lda #<BLANK_TILE_INDEX
    sta VMDATAL
    lda #>BLANK_TILE_INDEX
    and #$03
    sta VMDATAH
    dey
    bne _FMVBlankLoop

    lda #216
    sta BG1VOFS
    stz BG1VOFS
    stz BG1HOFS
    stz BG1HOFS
    lda #$01
    sta TM
    stz TS
    stz CGADD
    stz CGDATA
    stz CGDATA
    lda #$80
    sta INIDISP
    rts

; Tear down FMV PPU state.
FMV_StopVideo:
    lda #$80
    sta INIDISP
    stz BGMODE
    stz TM
    stz BG12NBA
    stz BG1HOFS
    stz BG1HOFS
    stz BG1VOFS
    stz BG1VOFS
    lda #$0F
    sta INIDISP
    rts

; Subframes 0-3: each vblank we DMA one tile chunk. Palette is read at
; subframe 0 but applied at subframe 3 to stay in sync with the tiles.
FMV_DoSubFrame0:
    rep #$10
    sep #$20

    ; Read palette into WRAM buffer first, then wait for vblank
    ldx #$0000
_FMVReadPaletteLoop:
    lda MSUDRead
    sta FMVPaletteBuffer,x
    inx
    cpx #PALETTE_BYTES
    bne _FMVReadPaletteLoop

    jsr FMV_WaitVBlank

    ; DMA tile chunk 0 to the inactive buffer
    lda FMVActiveBuffer
    beq _FMVSubFrame0UseBufferA
    lda #<TILEDATA_B
    sta VMADDL
    lda #>TILEDATA_B
    sta VMADDH
    bra _FMVSubFrame0BufferReady
_FMVSubFrame0UseBufferA:
    lda #<TILEDATA_A
    sta VMADDL
    lda #>TILEDATA_A
    sta VMADDH
_FMVSubFrame0BufferReady:
    lda #$80
    sta VMAIN
    lda #$09
    sta DMA1CTRL
    lda #$18
    sta DMA1DEST
    lda #<MSUDRead
    sta DMA1SRCL
    lda #>MSUDRead
    sta DMA1SRCH
    lda #$00
    sta DMA1SRCB
    lda #<TILE_CHUNK_0
    sta DMA1SIZEL
    lda #>TILE_CHUNK_0
    sta DMA1SIZEH
    lda #$02
    sta DMAEN
    rts

FMV_DoSubFrame1:
    jsr FMV_WaitVBlank
    lda FMVActiveBuffer
    beq _FMVSubFrame1UseBufferA
    rep #$20
    lda #TILEDATA_B + (TILE_CHUNK_0 / 2)
    bra _FMVSubFrame1BufferReady
_FMVSubFrame1UseBufferA:
    rep #$20
    lda #TILEDATA_A + (TILE_CHUNK_0 / 2)
_FMVSubFrame1BufferReady:
    sta VMADDL
    sep #$20
    lda #$80
    sta VMAIN
    lda #$09
    sta DMA0CTRL
    lda #$18
    sta DMA0DEST
    lda #<MSUDRead
    sta DMA0SRCL
    lda #>MSUDRead
    sta DMA0SRCH
    lda #$00
    sta DMA0SRCB
    lda #<TILE_CHUNK_1
    sta DMA0SIZEL
    lda #>TILE_CHUNK_1
    sta DMA0SIZEH
    lda #$01
    sta DMAEN
    rts

FMV_DoSubFrame2:
    jsr FMV_WaitVBlank
    lda FMVActiveBuffer
    beq _FMVSubFrame2UseBufferA
    rep #$20
    lda #TILEDATA_B + ((TILE_CHUNK_0 + TILE_CHUNK_1) / 2)
    bra _FMVSubFrame2BufferReady
_FMVSubFrame2UseBufferA:
    rep #$20
    lda #TILEDATA_A + ((TILE_CHUNK_0 + TILE_CHUNK_1) / 2)
_FMVSubFrame2BufferReady:
    sta VMADDL
    sep #$20
    lda #$80
    sta VMAIN
    lda #$09
    sta DMA0CTRL
    lda #$18
    sta DMA0DEST
    lda #<MSUDRead
    sta DMA0SRCL
    lda #>MSUDRead
    sta DMA0SRCH
    lda #$00
    sta DMA0SRCB
    lda #<TILE_CHUNK_2
    sta DMA0SIZEL
    lda #>TILE_CHUNK_2
    sta DMA0SIZEH
    lda #$01
    sta DMAEN
    rts

FMV_DoSubFrame3:
    jsr FMV_WaitVBlank

    ; DMA ch0: palette WRAM->CGRAM, ch1: tile chunk 3 MSU->VRAM
    stz CGADD
    lda #$00
    sta DMA0CTRL
    lda #$22
    sta DMA0DEST
    lda #<FMVPaletteBuffer
    sta DMA0SRCL
    lda #>FMVPaletteBuffer
    sta DMA0SRCH
    lda #$7E
    sta DMA0SRCB
    lda #<PALETTE_BYTES
    sta DMA0SIZEL
    lda #>PALETTE_BYTES
    sta DMA0SIZEH

    lda FMVActiveBuffer
    beq _FMVSubFrame3UseBufferA
    rep #$20
    lda #TILEDATA_B + ((TILE_CHUNK_0 + TILE_CHUNK_1 + TILE_CHUNK_2) / 2)
    bra _FMVSubFrame3BufferReady
_FMVSubFrame3UseBufferA:
    rep #$20
    lda #TILEDATA_A + ((TILE_CHUNK_0 + TILE_CHUNK_1 + TILE_CHUNK_2) / 2)
_FMVSubFrame3BufferReady:
    sta VMADDL
    sep #$20
    lda #$80
    sta VMAIN

    lda #$09
    sta DMA1CTRL
    lda #$18
    sta DMA1DEST
    lda #<MSUDRead
    sta DMA1SRCL
    lda #>MSUDRead
    sta DMA1SRCH
    lda #$00
    sta DMA1SRCB
    lda #<TILE_CHUNK_3
    sta DMA1SIZEL
    lda #>TILE_CHUNK_3
    sta DMA1SIZEH

    lda #$03
    sta DMAEN

    lda FMVActiveBuffer
    eor #$01
    sta FMVActiveBuffer
    bne _FMVSubFrame3SetBaseA
    lda #BG1_BASE_B
    bra _FMVSubFrame3BaseReady
_FMVSubFrame3SetBaseA:
    lda #BG1_BASE_A
_FMVSubFrame3BaseReady:
    sta BG12NBA
    lda #$0F
    sta INIDISP
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

