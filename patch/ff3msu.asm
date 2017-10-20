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

.DEFINE OriginalNMIHandler $1500
.DEFINE ReturnCommand 
; Was using $1E00-$1E07 earlier, but these are used for storing Veldt monsters. $1E20-$1E27 are unused. 
; $7EF001 appears to be unused and is used so that the data for what track the MSU is currently playing 
; can persist across saved games.


.DEFINE MSUExists          $1E20
.DEFINE MSUCurrentTrack    $1E21
.DEFINE MSUCurrentVolume   $1E22
.DEFINE SPCCommandTemp     $1E23
.DEFINE SPCVolumeTemp      $1E24
.DEFINE DancingFlag        $1E25
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




; Our free space to put our own stuff.

.BANK 18
.ORG $FA72
.SECTION "MSU" SIZE 1422 OVERWRITE

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
    ; Are we being given command 82? (which appears to be switch subsong)
    lda PlayCommand
    cmp #$82
    beq +
    jmp OriginalCommand
+
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
BattleCheck:
    lda PlayTrack
    ; Special track handling section
    cmp #$24 ; Battle theme
    bne Kefka5Check
    jml BattleTheme
Kefka5Check:
    cmp #$50 ; Kefka's Dancing Mad Part 5
    bne Kefka1Check
    jml Kefka5
Kefka1Check:
    cmp #$3b ; Kefka's Dancing Mad Parts 1-3
    bne Ending1Check
    lda #$65 ; Play part 1.
    sta PlayTrack
Ending1Check: ; Ending Part 1
    cmp #$53 ;
    bne Ending2Check
    jml Ending1
Ending2Check: ; Ending Part 2
    cmp #$54 ;
    bne SilenceCheck
    jml Ending2
SilenceCheck:
    cmp #$00 ; Silence (FF6 does a *lot* of track 0 requests, we're specifically masking this one to reduce calls to the MSU.)
    bne RePlayCheck
    jmp ShutUpAndLetMeTalk ; Mute, stop, and have the SPC handle the request for silence.
RePlayCheck:
    cmp #$51 ; Trying to play silence. As far as I can tell, track 0x51 is not actually used by the game at any point, so this can be used
             ; as a signal to re-play our last track: If the code is calling for 0x51, what it's really calling for is the last track played.
    bne SpecialHandlingBack
    lda MSUCurrentTrack
    sta PlayTrack
    lda MSUCurrentVolume
    sta PlayVolume
SpecialHandlingBack:
    ; Are we playing it?
    lda PlayTrack
    cmp MSULastTrackSet
    ; If not, skip to NotPlaying
    bne NotPlaying
    ; Are we *really* playing it?
    lda MSUStatus
    and #MSUStatus_AudioPlaying
    cmp #MSUStatus_AudioPlaying
    bne NotPlaying
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
    cmp #MSUStatus_AudioBusy
    beq WaitMSU
    lda MSUStatus
    and #MSUStatus_BadTrack
    cmp #MSUStatus_BadTrack
    bne PlayMSU ; If it's not a bad track, don't jump to the SPC code 
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
    ; Set the MSU Volume to the requested volume. 
    ChangeVolume PlayVolume
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
    ; Revision check temporarily dummied out for Snes9x-msu compatibility.
    ;lda MSUStatus   ; Are we on Revision 2 or greater? If so, we have Resume support. Handle this specially.
    ;and #%00000111
    ;cmp #$02
    ;bcs ResumeSupportBT
    ;jml SpecialHandlingBack ; If not, do our normal stuff.
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
    cmp #MSUStatus_AudioPlaying
    bne +
    jml SilenceAndReturn
+
    jml SpecialHandlingBack

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
    cmp #MSUStatus_AudioPlaying
    bne +
    jml SilenceAndReturn
+
    jml SpecialHandlingBack

; Return routines

ShutUp:
    stz MSUVolume
    stz MSUTrack
    stz MSUTrack+1
    stz MSUControl
SilenceAndReturn:
    stz PlayVolume
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
    ; Attempt to avoid the 'double play' problem by telling the SPC routine we're playing silence. May 
    ; have unintended effects. May be cause of issues #4, partially #3, and #17. :/
    lda #$51
    sta PlayTrack
    ; End hack
OriginalCode:
    lda PlayTrack
    cmp CurrentTrack
    rtl

ShutUpAndLetMeTalk:
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
    phb
    phd
    sep #$20
;stuff goes here
    rep #$30
    pld
    plb
    ply
    plx
    pla
    plp
    jml OriginalNMIHandler

; End Subroutines
.ENDS
