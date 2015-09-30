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

; Was using $1E00-$1E07 earlier, but these are used for storing Veldt monsters. $1E20-$1E27 are unused. 
; $7EF001 appears to be unused and is used so that the data for what track the MSU is currently playing 
; can persist across saved games.

; EXPERIMENTAL TEST: Remove MSUExists variable, do direct checks against the MSU each track jump instead.
;.DEFINE MSUExists $1E20
.DEFINE MSUCurrentTrack  $1E21
.DEFINE MSUCurrentVolume $1E22
.DEFINE SPCTrackTemp     $1E23
.DEFINE SPCVolumeTemp    $1E24
.DEFINE FadeType         $1E25
.DEFINE FadeVolume       $1E26
.DEFINE TrackFade        $1E27
.DEFINE MSULastTrackSet  $7EF001
.DEFINE MSUCodeErrorFlag $7EF002

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

; Internal error flags

.DEFINE MSUCodeError_NotPlayingNotBusy $01
.DEFINE MSUCodeError_BadTrack $02

; Subroutine hooks

.BANK 0
.ORG $ff10
.SECTION "NMIOverride" SIZE 4 OVERWRITE

jml NMIHandle

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

; End Macros

; Main Code

MSUMain:
	; Check for MSU presence
    ; REMINDER. We removed the variable here to check if this fixes the SD2SNES bug.
	jsr MSUCheck
	cmp #$01
	beq MSUFound
	; If not found, do the original SPC code
	jmp OriginalCode
MSUFound:
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
	sta MSUTrack
	stz MSUTrack+1
	; Wait for the MSU to either be done loading or to return a track error
WaitMSU:
	lda MSUStatus
	and #MSUStatus_BadTrack
	cmp #MSUStatus_BadTrack
	bne KeepWaiting
	; If we've gotten bad track, just stop and let the SPC handle things
	jmp ShutUpAndLetMeTalk
KeepWaiting:
	lda MSUStatus
	and #MSUStatus_AudioBusy
	cmp #MSUStatus_AudioBusy
	beq WaitMSU
	; Set the MSU Volume to the requested volume. 
	ChangeVolume PlayVolume
PlayerTime:
	; Set our currently playing track to this one.
	lda PlayTrack
    ; Write the last track set to an unused area of HiRAM
    sta MSULastTrackSet
	sta MSUCurrentTrack
	; Check against our looping track list. This subroutine will return the proper MSUControl value in A.
	jsr WillItLoop
	cmp #$00         ; If we're stopping, stop cleanly.
	bne TimeToPlay
	jmp ShutUp
TimeToPlay:
	sta MSUControl
	; We should now be playing the track. 
    ; Check if the MSU audio is playing or busy at this point? Is this necessary? Throwing shit at the wall and
    ; seeing what sticks to try to fix SD2SNES bug.
WaitToPlay:
    lda MSUStatus
    and #MSUStatus_AudioPlaying
    cmp #MSUStatus_AudioPlaying
    beq MSUDone
    lda MSUStatus
    and #MSUStatus_AudioBusy
    cmp #MSUStatus_AudioBusy
    beq WaitToPlay
    ; We shouldn't get here! Put a flag in RAM indicating an error (Can we debug on the SD2SNES?) and
    ; check to see if we have BadTrack. If so, increment the error flag by one (we shouldn't be getting badtrack down here)
    ; and go back to start. If not, try to tell the MSU-1 to play again? Could result in an infinite loop...
    lda #MSUCodeError_NotPlayingNotBusy
    sta MSUCodeErrorFlag
    lda MSUStatus
    and #MSUStatus_BadTrack
    cmp #MSUStatus_BadTrack
    beq Weirdness
    jml PlayerTime
Weirdness:
    lda #MSUCodeError_BadTrack
    sta MSUCodeErrorFlag
    jml MSUMain
    
MSUDone:
    ; Silence the SPC music and return
	jmp SilenceAndReturn

; End Main Code
	
; Subroutines



; Check for MSU. If it's found, A and MSUExists will be $01

MSUCheck:
	lda MSUID
	cmp #$53	; 'S'
	bne +	; Stop checking if it's wrong
	lda MSUID+1
	cmp #$2D	; '-'
	bne +
	lda MSUID+2
	cmp #$4D	; 'M'
	bne +
	lda MSUID+3
	cmp #$53	; 'S'
	bne +
	lda MSUID+4
	cmp #$55	; 'U'
	bne +
	lda MSUID+5
	cmp #$31	; '1'
	bne +
    lda #$01
	rts
+
	lda #$00
	rts

; Check if the track to play is in our list of non-looping tracks, if so return $01 in A, if not, return $03 in A. Also, certain tracks essentially mean "stop", so handle those too.
WillItLoop:
	lda PlayTrack
	cmp #$02   ; Opening part 1
	beq WILNope
	cmp #$03   ; Opening part 2
	beq WILNope
	cmp #$04   ; Opening part 3
	beq WILNope
	cmp #$27   ; Aria de Mezzo Carattare
	beq WILNope
	cmp #$53   ; Ending part 1
	beq WILNope
	cmp #$54   ; Ending part 2
	beq WILNope
	lda #$03
	rts
WILNope:
	lda #$01
	rts


; Return routines

ShutUp:
	stz MSUVolume
	stz MSUTrack
    lda #$0000
    sta MSULastTrackSet
	stz MSUTrack+1
	stz MSUControl
SilenceAndReturn:
	stz PlayVolume
	; Attempt to avoid the 'double play' problem by telling the SPC routine we're playing silence. May 
	; have unintended effects.
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
    lda #$0000
    sta MSULastTrackSet
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
