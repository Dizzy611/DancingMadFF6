; video-player-test.asm
; Standalone SNES test ROM — MSU-1 FMV video player.
;
; Behavior:
;   - On boot, checks for MSU-1 hardware by reading the "S-MSU1" ID string
;     at $2002-$2007.
;   - If MSU-1 is NOT detected: displays a red screen (error indicator).
;     A button does nothing.
;   - If MSU-1 IS detected: displays a blue screen (idle/ready).
;     Press A to start video playback. The player reads sequential frame data
;     from the MSU-1 data port ($2001) containing palette + 4bpp tile data,
;     and DMA-transfers it into CGRAM and VRAM each VBlank. Audio plays
;     simultaneously via the MSU-1 audio channel.
;     Press A during playback to stop and return to blue screen.
;
; Video format (produced by conversion.py):
;   The .msu file begins with a 16-byte header:
;     $00: "FFVI" magic (4 bytes)
;     $04: frame count (u16le)
;     $06: width in pixels (u16le) — 256
;     $08: height in pixels (u16le) — 144
;     $0A: bytes per frame (u16le) — 18,688
;     $0C: tile columns (u8) — 32
;     $0D: tile rows (u8) — 18
;     $0E: sub-palettes (u8) — 8
;     $0F: fps (u8) — 15
;
;   After the header, frames are stored sequentially:
;     256 bytes: palette data (8 sub-palettes × 16 colors × 2 bytes BGR555)
;     18,432 bytes: tile data (576 tiles × 32 bytes, 4bpp interleaved bitplane)
;     = 18,688 bytes per frame
;
;   At 15 fps video on a 60 fps SNES, each video frame is displayed for 4
;   SNES frames. Tile data is streamed directly from $2001 to VRAM across
;   those 4 VBlanks, while palette bytes are staged and applied at frame
;   completion to keep tile/palette presentation synchronized.
;
;   Double buffering: two tile data regions in VRAM (buffer A and buffer B).
;   While one buffer is displayed, the other is being written to. The tilemap
;   is updated to point to the newly-completed buffer once all 4 DMA passes
;   are done.
;
; SNES PPU configuration:
;   Mode 1, BG1 4bpp, 32×18 tiles visible (256×144 pixels).
;   8 sub-palettes assigned by fixed spatial region (4 columns × 2 rows).
;   Tilemap set up once at init; only palette and tile data change per frame.
;   BG1 V-scroll offsets the display to center 144 lines in the 256×224 screen
;   (scroll = -(224-144)/2 = -40 → $FFD8 as unsigned, but we use the visible
;   region approach: scroll = 256 - 40 = 216 = $00D8... actually the standard
;   approach is to just set the vertical scroll to position the BG, and let
;   the top/bottom 40 lines show backdrop color 0 = black).
;
; Audio:
;   MSU-1 audio track 1 is played when video starts.  The .pcm file contains
;   the intro cutscene audio at 44100 Hz 16-bit signed LE stereo.
;   Track 1 with no loop, full volume ($FF).
;
; Memory map:
;   This is a standalone HiROM ROM (not a patch), 2 banks (64KB).
;   Code lives at $C0:8000+, mirrored at $00:8000+ in HiROM.
;   WRAM $0000-$00FF: direct page variables.
;   WRAM $0100-$1FFF: stack + scratch.
;
; Learning notes:
;   This file is intentionally over-commented as a SNES development reference.
;   Key concepts demonstrated:
;     - MSU-1 detection and data/audio register usage
;     - DMA transfers to CGRAM (palette) and VRAM (tiles)
;     - Double-buffered VRAM tile data
;     - Tilemap initialization with per-tile palette assignment
;     - VBlank-synchronized multi-pass DMA
;     - Controller input with edge detection

; =====================================================================
; Memory Map Configuration
; =====================================================================

.MEMORYMAP
    SLOTSIZE $10000
    DEFAULTSLOT 0
    SLOT 0 $0000
.ENDME
.ROMBANKSIZE $10000
.ROMBANKS 2

.HIROM
.FASTROM
.BASE $C0

; =====================================================================
; SNES Header & Vectors
; =====================================================================
; In HiROM, the header lives at ROM offset $FFB0-$FFDF and vectors at
; $FFE0-$FFFF. Since .BASE is $C0, these map to $C0:FFB0-$C0:FFFF.

.BANK 0
.ORGA $FFB0

; --- Internal ROM Header ($FFB0-$FFDF) ---
.DB "      "                ; $FFB0-$FFB5: Maker/Game code (unused)
.DB $00                     ; $FFB6: Fixed value byte
.DB $00                     ; $FFB7: Expansion RAM size
.DB $00                     ; $FFB8: Special version
.DB $00                     ; $FFB9: Cartridge sub-type
.DB $00, $00, $00, $00      ; $FFBA-$FFBD: Reserved
.DB $00, $00                ; $FFBE-$FFBF: Reserved
.DB "MSU1 VIDEO PLAYER    " ; $FFC0-$FFD4: ROM name (21 bytes, space-padded)
.DB $31                     ; $FFD5: Map mode ($31 = HiROM + FastROM)
.DB $00                     ; $FFD6: Cartridge type ($00 = ROM only)
.DB $09                     ; $FFD7: ROM size ($09 = 4Mbit/512KB)
.DB $00                     ; $FFD8: RAM size ($00 = no SRAM)
.DB $01                     ; $FFD9: Country ($01 = North America)
.DB $00                     ; $FFDA: Developer ID
.DB $00                     ; $FFDB: ROM version
.DW $FFFF                   ; $FFDC-$FFDD: Checksum complement (placeholder)
.DW $0000                   ; $FFDE-$FFDF: Checksum (placeholder)

; --- Native Mode Vectors ($FFE0-$FFEF) ---
.DW $0000                   ; $FFE0: Reserved
.DW $0000                   ; $FFE2: Reserved
.DW EmptyHandler            ; $FFE4: COP
.DW EmptyHandler            ; $FFE6: BRK
.DW EmptyHandler            ; $FFE8: ABORT
.DW NMIHandler              ; $FFEA: NMI (VBlank)
.DW $0000                   ; $FFEC: Reserved
.DW EmptyHandler            ; $FFEE: IRQ

; --- Emulation Mode Vectors ($FFF0-$FFFF) ---
.DW $0000                   ; $FFF0: Reserved
.DW $0000                   ; $FFF2: Reserved
.DW EmptyHandler            ; $FFF4: COP
.DW $0000                   ; $FFF6: Reserved
.DW EmptyHandler            ; $FFF8: ABORT
.DW EmptyHandler            ; $FFFA: NMI (emulation)
.DW Reset                   ; $FFFC: RESET entry point
.DW EmptyHandler            ; $FFFE: IRQ/BRK

; =====================================================================
; Register Definitions
; =====================================================================

; --- PPU Registers ---
.DEFINE INIDISP   $2100     ; Screen display (bit 7 = force blank, bits 0-3 = brightness)
.DEFINE OBSEL     $2101     ; Object size & base
.DEFINE BGMODE    $2105     ; BG mode and tile size
.DEFINE BG1SC     $2107     ; BG1 tilemap address & size (bits 2-7 = base >> 10)
.DEFINE BG12NBA   $210B     ; BG1/BG2 tile character data base address
.DEFINE BG1HOFS   $210D     ; BG1 horizontal scroll (write twice: low then high)
.DEFINE BG1VOFS   $210E     ; BG1 vertical scroll (write twice: low then high)
.DEFINE VMAIN     $2115     ; VRAM address increment mode
.DEFINE VMADDL    $2116     ; VRAM address low byte
.DEFINE VMADDH    $2117     ; VRAM address high byte
.DEFINE VMDATAL   $2118     ; VRAM data write low byte
.DEFINE VMDATAH   $2119     ; VRAM data write high byte
.DEFINE TM        $212C     ; Main screen designation (which BGs/OBJ to show)
.DEFINE CGADD     $2121     ; CGRAM address (palette index)
.DEFINE CGDATA    $2122     ; CGRAM data write (palette data, write twice per color)

; --- CPU I/O Registers ---
.DEFINE NMITIMEN  $4200     ; Interrupt enable (bit 7 = NMI, bit 0 = auto joypad)
.DEFINE RDNMI     $4210     ; NMI flag / CPU version (read to acknowledge NMI)
.DEFINE HVBJOY    $4212     ; H/V blank flags and joypad busy status
.DEFINE JOY1L     $4218     ; Joypad 1 data (low byte)
.DEFINE JOY1H     $4219     ; Joypad 1 data (high byte)

; --- APU I/O Ports (CPU side of SPC communication) ---
.DEFINE APUIO0    $2140
.DEFINE APUIO1    $2141
.DEFINE APUIO2    $2142
.DEFINE APUIO3    $2143

; --- DMA Registers ---
; The SNES has 8 DMA channels (0-7). Each channel has registers at $43x0-$43xA.
; We use channel 0 for palette DMA and channel 1 for tile DMA.
;
; DMA register layout per channel (channel N at $4300 + N*$10):
;   $43N0: DMA control (transfer direction, mode)
;   $43N1: Destination register (PPU address, low byte only — $21xx implied)
;   $43N2-$43N4: Source address (24-bit: low, high, bank)
;   $43N5-$43N6: Transfer size (16-bit, or indirect table address for HDMA)
;
; DMA control byte ($43N0):
;   Bit 7: Direction (0 = CPU→PPU, 1 = PPU→CPU)
;   Bits 0-2: Transfer mode:
;     0 = 1 byte  to $21xx           (e.g. CGDATA)
;     1 = 2 bytes to $21xx/$21(xx+1) (e.g. VMDATAL/VMDATAH)
.DEFINE DMAEN     $420B     ; DMA channel enable (write bit N to trigger channel N)
.DEFINE DMA0CTRL  $4300     ; Channel 0 control
.DEFINE DMA0DEST  $4301     ; Channel 0 destination register
.DEFINE DMA0SRCL  $4302     ; Channel 0 source address low
.DEFINE DMA0SRCH  $4303     ; Channel 0 source address high
.DEFINE DMA0SRCB  $4304     ; Channel 0 source bank
.DEFINE DMA0SIZEL $4305     ; Channel 0 transfer size low
.DEFINE DMA0SIZEH $4306     ; Channel 0 transfer size high
.DEFINE DMA1CTRL  $4310     ; Channel 1 control
.DEFINE DMA1DEST  $4311     ; Channel 1 destination register
.DEFINE DMA1SRCL  $4312     ; Channel 1 source address low
.DEFINE DMA1SRCH  $4313     ; Channel 1 source address high
.DEFINE DMA1SRCB  $4314     ; Channel 1 source bank
.DEFINE DMA1SIZEL $4315     ; Channel 1 transfer size low
.DEFINE DMA1SIZEH $4316     ; Channel 1 transfer size high

; --- MSU-1 Registers ---
; The MSU-1 is a custom coprocessor providing large data and CD-quality audio.
; It is mapped to $2000-$2007 in the SNES address space. On real hardware it
; lives in the cartridge (FXPak Pro); in emulators it's built-in (bsnes, etc).
;
; $2000-$2003 (write): Data seek — set the 32-bit read offset into the .msu file.
;                Write one byte to each of $2000 (bits 0-7), $2001 (bits 8-15),
;                $2002 (bits 16-23), $2003 (bits 24-31). The seek is initiated
;                and data_busy is cleared when $2003 is written.
; $2000 (read):  Status register:
;                  Bit 7: Data busy (1 = seek in progress, wait before reading)
;                  Bit 6: Audio busy (1 = track loading, wait before playing)
;                  Bit 5: Audio looping (1 = currently looping)
;                  Bit 4: Audio playing (1 = currently playing)
;                  Bit 3: Audio error (1 = requested track not found)
;
; $2001 (read):  Data read port. Each read returns the next byte from the .msu
;                file at the current offset, then auto-increments the offset.
;
; $2002-$2007 (read): MSU-1 identification string "S-MSU1".
;                      If these bytes don't read as "S-MSU1", no MSU-1 is present.
;
; $2004-$2005 (write): Audio track number (16-bit, low then high).
;                       Writing this loads the corresponding .pcm file.
;
; $2006 (write): Audio volume (0-255, $FF = max).
;
; $2007 (write): Audio control:
;                  Bit 0: Play (1 = start/resume, 0 = stop)
;                  Bit 1: Loop (1 = loop at loop point, 0 = play once)
;                  Bit 2: Pause (1 = pause, resumable)
.DEFINE MSUStatus   $2000   ; Read: status flags / Write: data seek (4 bytes)
.DEFINE MSUDataRead $2001   ; Read: next data byte (auto-increment)
.DEFINE MSUID       $2002   ; Read: ID string start ("S-MSU1" at $2002-$2007)
.DEFINE MSUSeek     $2000   ; Write: data seek offset (alias for clarity)
.DEFINE MSUTrack    $2004   ; Write: audio track number (16-bit LE)
.DEFINE MSUVolume   $2006   ; Write: audio volume (0-255)
.DEFINE MSUControl  $2007   ; Write: audio control (play/loop/pause)

; MSU-1 status flag bits
.DEFINE MSU_DATA_BUSY    %10000000
.DEFINE MSU_AUDIO_BUSY   %01000000
.DEFINE MSU_AUDIO_PLAY   %00010000
.DEFINE MSU_AUDIO_ERROR  %00001000

; MSU-1 audio control values
.DEFINE MSU_PLAY_ONCE    %00000001  ; Play, no loop
.DEFINE MSU_PLAY_LOOP    %00000011  ; Play, loop
.DEFINE MSU_STOP         %00000000  ; Stop playback

; SPC upload constants
.DEFINE SPC_UPLOAD_ADDR  $0200
.DEFINE SPC_INIT_SIZE    32

; =====================================================================
; RAM Variables (Direct Page $0000-$00FF)
; =====================================================================

; --- State Machine ---
.DEFINE GameState    $0010   ; 0 = idle (blue screen), 1 = playing video
.DEFINE MSUDetected  $0011   ; 0 = no MSU-1, 1 = MSU-1 present
.DEFINE NMIReady     $0012   ; Set by NMI handler each VBlank

; --- Controller ---
.DEFINE PrevButtons  $0014   ; Previous frame's button state (16-bit)
.DEFINE NewButtons   $0016   ; Newly pressed buttons this frame (16-bit)

; Palette staging buffer (256 bytes). Kept separate from tile DMA buffer so
; each frame's palette can be applied only when its tile data is complete.
.DEFINE PaletteBuffer $0100

; --- Video Playback State ---
.DEFINE FrameCount   $0018   ; Total frames in the video (16-bit, from .msu header)
.DEFINE FrameCurrent $001A   ; Current frame number being displayed (16-bit)
.DEFINE SubFrame     $001C   ; Which of the 4 VBlanks for the current video frame (0-3)
.DEFINE ActiveBuffer $001D   ; Which VRAM tile buffer is being displayed (0 or 1)

; --- DMA Staging Buffer ---
; WRAM scratch buffer used for header reads and tilemap setup temporaries.
.DEFINE DMABuffer    $0200   ; WRAM address of the DMA staging buffer

; =====================================================================
; Video Format Constants
; =====================================================================

; These match the output of conversion.py. The .msu header is read at
; runtime for validation, but we hardcode the layout here since the SNES
; player is purpose-built for this specific format.

.DEFINE MSU_HEADER_SIZE  16       ; 16-byte file header
.DEFINE SCREEN_W         256      ; Display width in pixels
.DEFINE SCREEN_H         144      ; Display height in pixels
.DEFINE TILE_COLS        32       ; Tiles per row
.DEFINE TILE_ROWS        18       ; Tiles per column
.DEFINE TOTAL_TILES      576      ; 32 × 18
.DEFINE BLANK_TILE_INDEX 576      ; Dedicated zero tile for letterbox rows
.DEFINE PALETTE_BYTES    256      ; 8 palettes × 16 colors × 2 bytes
.DEFINE TILE_DATA_BYTES  18432    ; 576 tiles × 32 bytes
.DEFINE BYTES_PER_TILE   32       ; 4bpp tile = 32 bytes

; --- VRAM Layout ---
; VRAM is 64KB, addressed in 16-bit words (32K word addresses: $0000-$7FFF).
;
; Tilemap:
;   BG1 tilemap at VRAM word address $0000 (byte address $0000).
;   A 32×32 tilemap = 2,048 bytes = 1,024 words. Only the top-left 32×18
;   portion is visible; the rest is off-screen and left as zeros.
;
; Tile data (double buffered):
;   Buffer A: VRAM word address $1000 (byte address $2000).
;   Buffer B: VRAM word address $3800 (byte address $7000).
;   Each buffer: 576 tiles × 32 bytes = 18,432 bytes = 9,216 words.
;
; Buffer A range: $1000-$33FF (word) = $2000-$67FF (byte)  [18,432 bytes]
; Buffer B range: $3800-$5BFF (word) = $7000-$B7FF (byte)  [18,432 bytes]
; Tilemap range:  $0000-$03FF (word) = $0000-$07FF (byte)  [2,048 bytes]
; Total used:     18,432 × 2 + 2,048 = 38,912 bytes of 65,536 VRAM.
;
; The tile character base address register (BG12NBA / $210B) uses the top
; nibble of the word address >> 12. So:
;   Buffer A base = $1000 → BG12NBA low nibble = $01
;   Buffer B base = $3800 → BG12NBA low nibble = $03
; Wait — BG12NBA uses bits 0-3 for BG1 in units of $2000 words (16KB).
; Actually: bits 0-3 = BG1 base address in units of $1000 words (8KB).
;   $01 → word address $1000 ✓ (buffer A)
;   $03 → word address $3000 — that's not $3800!
; The character base granularity is $1000 words (8KB = 256 tiles). So valid
; bases are $0000, $1000, $2000, $3000, $4000, $5000, $6000, $7000.
; We need buffer B at a $1000-aligned boundary. Let's use $4000 instead:
;   Buffer B: $4000-$63FF (word) = $8000-$C7FF (byte)
;   BG12NBA low nibble = $04
;
; Revised layout:
;   Tilemap:   $0000-$03FF words ($0000-$07FF bytes, 2 KB)
;   Buffer A:  $1000-$33FF words ($2000-$67FF bytes, 18,432 bytes)
;   Buffer B:  $4000-$63FF words ($8000-$C7FF bytes, 18,432 bytes)
;   Total:     2,048 + 18,432 + 18,432 = 38,912 bytes

.DEFINE TILEMAP_VRAM   $0000   ; Tilemap word address
.DEFINE TILEDATA_A     $1000   ; Buffer A tile data word address
.DEFINE TILEDATA_B     $4000   ; Buffer B tile data word address
.DEFINE BG1_BASE_A     $01     ; BG12NBA value for buffer A ($1000 words)
.DEFINE BG1_BASE_B     $04     ; BG12NBA value for buffer B ($4000 words)

; The tilemap base address register (BG1SC / $2107) uses bits 2-7 for the
; base address in units of $400 words (2KB).
;   $0000 / $400 = 0 → bits 2-7 = 0, so BG1SC = $00.
; Bits 0-1 control tilemap size: 00 = 32×32 (what we want).
.DEFINE BG1SC_VALUE    $00     ; Tilemap at $0000, 32×32

; Tile index offsets for each buffer (tile number that the tilemap points to):
;   BG12NBA sets the base, and tile indices in the tilemap are relative to it.
;   Buffer A at $1000 with BG12NBA=$01 → tile 0 is at $1000. Tilemap uses
;   tile index 0 for the first tile.
;   Buffer B at $4000 with BG12NBA=$04 → tile 0 is at $4000. Tilemap uses
;   tile index 0 for the first tile.
; So in both cases, the tilemap stays the same — we just switch BG12NBA!

; Sub-palette region assignment:
; The 32×18 tile grid is divided into 8 regions (4 cols × 2 rows).
; Region column = tile_col / 8 (0-3), Region row = tile_row / 9 (0-1).
; Palette index = row * 4 + col (0-7).
; This is encoded in the tilemap entry's high byte, bits 2-4 (palette number).

; Number of VBlank sub-frames per video frame
.DEFINE SUBFRAMES_PER_FRAME  4

; DMA sizes for each sub-frame:
; Sub-frame 0: palette read + tile chunk 0 (4736 bytes to VRAM)
; Sub-frame 1: tile chunk 1 (5120 bytes to VRAM)
; Sub-frame 2: tile chunk 2 (5120 bytes to VRAM)
; Sub-frame 3: tile chunk 3 (remaining 3456 bytes to VRAM)
; Total tile data: 4736 + 5120 + 5120 + 3456 = 18,432 ✓
;
; We keep sub-frame 0's tile chunk smaller to leave room for the palette DMA
; in the same VBlank. The other chunks are sized to fit VBlank's ~5,700 byte
; budget comfortably.
.DEFINE TILE_CHUNK_0  4736    ; 148 tiles × 32 bytes
.DEFINE TILE_CHUNK_1  5120    ; 160 tiles × 32 bytes
.DEFINE TILE_CHUNK_2  5120    ; 160 tiles × 32 bytes
.DEFINE TILE_CHUNK_3  3456    ; 108 tiles × 32 bytes (remainder)
; Verify: 148 + 160 + 160 + 108 = 576 tiles ✓

; BGR555 color constants: 0bbbbbgg gggrrrrr
.DEFINE COLOR_BLUE   $7C00   ; R=0, G=0, B=31
.DEFINE COLOR_RED    $001F   ; R=31, G=0, B=0
.DEFINE COLOR_BLACK  $0000   ; R=0, G=0, B=0

; =====================================================================
; Bank $C0 — Code
; =====================================================================
.BANK 0
.ORG $8000   ; Maps to $C0:8000, mirrored at $00:8000 in HiROM.
             ; Code MUST be at $8000+ because bank $00 only maps ROM
             ; in the upper half ($8000-$FFFF). The lower half ($0000-$7FFF)
             ; is WRAM, PPU ports, CPU registers, and DMA ports.

; =====================================================================
; Reset — Entry Point (CPU starts in emulation mode)
; =====================================================================
Reset:
    sei                     ; Disable interrupts during init
    clc
    xce                     ; Switch to native 65816 mode (clear emulation flag)
    rep #$30                ; A/X/Y = 16-bit
    .16bit

    ; Force Data Bank to $00 so absolute MMIO accesses hit $00:21xx/$00:42xx.
    ; (PPU/CPU registers are only decoded in bank $00-$3F/$80-$BF.)
    sep #$20
    .8bit
    lda #$00
    pha
    plb
    rep #$30
    .16bit

    ; Set up stack at top of available low WRAM
    lda #$1FFF
    tcs

    ; Set Direct Page to $0000 for fast access to our variables
    lda #$0000
    tcd

    sep #$20                ; A = 8-bit for hardware register writes
    .8bit

    ; --- Force blank (screen off during initialization) ---
    ; Setting bit 7 of INIDISP turns the screen off but keeps the PPU
    ; accessible for VRAM/CGRAM/OAM writes at any time (not just VBlank).
    lda #$80
    sta INIDISP

    ; --- Clear PPU registers ---
    ; Zero all key PPU registers to establish a known state.
    ; These are write-only registers, so we can't read-modify-write;
    ; we just write the desired initial values.
    stz OBSEL               ; $2101: Object size & base
    stz $2102               ; OAM address low
    stz $2103               ; OAM address high
    stz BGMODE              ; $2105: BG Mode 0 (will set Mode 1 later)
    stz $2106               ; Mosaic: disabled
    stz BG1SC               ; $2107: BG1 tilemap at $0000, 32×32
    stz $2108               ; BG2 tilemap
    stz $2109               ; BG3 tilemap
    stz $210A               ; BG4 tilemap
    stz BG12NBA             ; $210B: BG1/BG2 character base
    stz $210C               ; BG3/BG4 character base
    stz BG1HOFS             ; BG1 H scroll low
    stz BG1HOFS             ; BG1 H scroll high
    stz BG1VOFS             ; BG1 V scroll low
    stz BG1VOFS             ; BG1 V scroll high
    stz $210F               ; BG2 H scroll (x2)
    stz $210F
    stz $2110               ; BG2 V scroll (x2)
    stz $2110
    stz $2111               ; BG3 H scroll (x2)
    stz $2111
    stz $2112               ; BG3 V scroll (x2)
    stz $2112
    stz $2113               ; BG4 H scroll (x2)
    stz $2113
    stz $2114               ; BG4 V scroll (x2)
    stz $2114
    stz VMAIN               ; $2115: VRAM increment mode
    stz VMADDL              ; $2116: VRAM address low
    stz VMADDH              ; $2117: VRAM address high
    stz $211A               ; Mode 7 settings
    stz $2123               ; Window mask BG1/BG2
    stz $2124               ; Window mask BG3/BG4
    stz $2125               ; Window mask OBJ/Color
    stz $2126               ; Window 1 left
    stz $2127               ; Window 1 right
    stz $2128               ; Window 2 left
    stz $2129               ; Window 2 right
    stz $212A               ; Window logic BG
    stz $212B               ; Window logic OBJ/Color
    stz TM                  ; $212C: Main screen (nothing enabled yet)
    stz $212D               ; Sub screen
    stz $212E               ; Window mask main screen
    stz $212F               ; Window mask sub screen
    lda #$30
    sta $2130               ; Color math control A (standard)
    stz $2131               ; Color math control B
    lda #$E0
    sta $2132               ; Fixed color data (black backdrop)
    stz $2133               ; Screen mode/interlace select

    ; --- Clear CPU I/O registers ---
    stz NMITIMEN            ; $4200: disable NMI and auto-joypad
    lda #$FF
    sta $4201               ; Programmable I/O (default open bus)
    stz $4202               ; Multiplicand A
    stz $4203               ; Multiplicand B
    stz $4204               ; Dividend low
    stz $4205               ; Dividend high
    stz $4206               ; Divisor
    stz $4207               ; H-count timer low
    stz $4208               ; H-count timer high
    stz $4209               ; V-count timer low
    stz $420A               ; V-count timer high
    stz DMAEN               ; $420B: DMA disable
    stz $420C               ; HDMA disable
    stz $420D               ; FastROM disable (enable later)

    ; --- Clear WRAM (first 8KB) ---
    ; This zeros our direct page variables, stack area, and DMA buffer.
    rep #$30                ; 16-bit A/X
    .16bit
    lda #$0000
    ldx #$0000
    @ClearWRAM:
        sta $0000,x
        inx
        inx
        cpx #$2000
        bne @ClearWRAM

    sep #$20                ; Back to 8-bit A
    .8bit

    ; --- Initialize SPC mixer state for MSU audio ---
    ; In a standalone test ROM there is no game sound driver to initialize the
    ; S-DSP master volume / mute/reset flags. MSU audio routes through the APU
    ; output path, so we upload a tiny SPC program that unmutes DSP and sets
    ; MVOL L/R to max.
    jsr InitSPCForMSU

    ; --- Check for MSU-1 ---
    ; Read the identification string at $2002-$2007. If it reads "S-MSU1",
    ; the MSU-1 coprocessor is present (FXPak Pro or compatible emulator).
    jsr CheckMSU

    ; --- Set backdrop color based on MSU detection ---
    ; Blue = MSU detected (ready for playback)
    ; Red  = no MSU (error — can't play video)
    stz CGADD               ; Palette index 0 = backdrop color
    lda MSUDetected
    bne @MSUFound

    ; No MSU — set backdrop to red
    lda #<COLOR_RED
    sta CGDATA
    lda #>COLOR_RED
    sta CGDATA
    bra @ColorDone

@MSUFound:
    ; MSU present — set backdrop to blue
    lda #<COLOR_BLUE
    sta CGDATA
    lda #>COLOR_BLUE
    sta CGDATA

@ColorDone:

    ; --- Enable NMI and auto-joypad read ---
    lda #$81                ; Bit 7 = NMI enable, bit 0 = auto-joypad enable
    sta NMITIMEN

    ; --- Enable FastROM ---
    lda #$01
    sta $420D

    ; --- Turn screen on (full brightness, no force blank) ---
    lda #$0F
    sta INIDISP

    ; --- Clear any pending NMI ---
    lda RDNMI

    ; --- Enable interrupts and enter main loop ---
    cli

; =====================================================================
; Main Loop — Idle State
; =====================================================================
; Wait for VBlank, read controller, and respond to A button.
; In idle state: blue screen, waiting for A press to start video.
; If MSU not detected: red screen, A does nothing.

MainLoop:
    ; Wait for NMI (VBlank)
    @WaitNMI:
        lda NMIReady
        beq @WaitNMI
    stz NMIReady            ; Acknowledge

    ; Wait for auto-joypad read to complete (bit 0 of HVBJOY = 1 while busy)
    @WaitJoy:
        lda HVBJOY
        and #$01
        bne @WaitJoy

    ; --- Read controller and compute newly pressed buttons ---
    jsr ReadController

    ; Check GameState
    lda GameState
    bne PlaybackLoop_Entry   ; If state=1, we're in video playback

    ; --- Idle state: check for A button press ---
    ; A button is bit 7 of JOY1L ($4218), which is bit 7 of the low byte
    ; in our 16-bit NewButtons read.
    lda NewButtons          ; Low byte of newly pressed buttons
    and #$80                ; A button mask
    beq MainLoop            ; Not pressed — keep waiting

    ; A was pressed. Do we have MSU-1?
    lda MSUDetected
    beq MainLoop            ; No MSU — ignore the press, stay on red screen

    ; --- Start video playback ---
    jsr StartPlayback

    jmp MainLoop

; =====================================================================
; Playback Main Loop
; =====================================================================
; Entered when GameState = 1. Each iteration handles one VBlank sub-frame.

PlaybackLoop_Entry:
    ; We already have an NMI ready from the MainLoop entry above.
    ; Fall through to process this sub-frame.

PlaybackLoop:
    ; --- Check for A press to stop playback ---
    lda NewButtons
    and #$80                ; A button
    beq @NoStop
    jsr StopPlayback
    jmp MainLoop
@NoStop:

    ; --- Process current sub-frame ---
    ; SubFrame counts 0..3, telling us which DMA chunk to transfer this VBlank.
    lda SubFrame

    cmp #$00
    bne @NotSub0
    jsr DoSubFrame0         ; Palette + first tile chunk
    bra @SubFrameDone
@NotSub0:
    cmp #$01
    bne @NotSub1
    jsr DoSubFrame1         ; Tile chunk 1
    bra @SubFrameDone
@NotSub1:
    cmp #$02
    bne @NotSub2
    jsr DoSubFrame2         ; Tile chunk 2
    bra @SubFrameDone
@NotSub2:
    ; SubFrame == 3
    jsr DoSubFrame3         ; Final tile chunk + swap buffers

@SubFrameDone:
    ; Advance sub-frame counter
    lda SubFrame
    inc a
    cmp #SUBFRAMES_PER_FRAME
    bne @NoWrap

    ; All 4 sub-frames done — advance to next video frame
    stz SubFrame

    ; Advance frame counter
    rep #$20
    .16bit
    lda FrameCurrent
    inc a
    sta FrameCurrent
    sep #$20
    .8bit

    rep #$20
    .16bit
    lda FrameCurrent
    cmp FrameCount          ; Have we reached the end?
    sep #$20
    .8bit
    bcc @NotDone            ; Carry clear = current < total → keep going

    ; Video finished — return to idle
    jsr StopPlayback
    jmp MainLoop

@NotDone:
    bra @WaitNextFrameInput

@NoWrap:
    sta SubFrame
    ; Keep processing sub-frames immediately; controller polling is done once
    ; per completed video frame to reduce per-subframe overhead.
    jmp PlaybackLoop

@WaitNextFrameInput:
    ; Poll input once per completed video frame.
    @WaitJoy2:
        lda HVBJOY
        and #$01
        bne @WaitJoy2
    jsr ReadController
    jmp PlaybackLoop

; =====================================================================
; CheckMSU — Detect MSU-1 Presence
; =====================================================================
; Reads the 6-byte identification string at $2002-$2007.
; If it matches "S-MSU1", sets MSUDetected = 1, else MSUDetected = 0.

CheckMSU:
    lda MSUID               ; $2002 → should be 'S' ($53)
    cmp #$53
    bne @NoMSU
    lda MSUID+1             ; $2003 → should be '-' ($2D)
    cmp #$2D
    bne @NoMSU
    lda MSUID+2             ; $2004 → should be 'M' ($4D)
    cmp #$4D
    bne @NoMSU
    lda MSUID+3             ; $2005 → should be 'S' ($53)
    cmp #$53
    bne @NoMSU
    lda MSUID+4             ; $2006 → should be 'U' ($55)
    cmp #$55
    bne @NoMSU
    lda MSUID+5             ; $2007 → should be '1' ($31)
    cmp #$31
    bne @NoMSU

    lda #$01
    sta MSUDetected
    rts

@NoMSU:
    stz MSUDetected
    rts

; =====================================================================
; ReadController — Read Joypad 1 with Edge Detection
; =====================================================================
; Reads the 16-bit controller state from JOY1L/JOY1H, computes newly
; pressed buttons (rising edges), and stores in NewButtons.

ReadController:
    rep #$30
    .16bit

    lda JOY1L               ; Read 16-bit joypad (JOY1L is low, JOY1H is high)

    ; Edge detection: newly pressed = current AND NOT previous
    ; (current XOR previous) gives changed bits; AND with current gives
    ; only bits that are now pressed but weren't before.
    pha                     ; Save current
    eor PrevButtons         ; Changed bits
    and $01,s               ; Only newly-pressed bits
    sta NewButtons

    pla                     ; Restore current
    sta PrevButtons         ; Save for next frame

    sep #$20
    .8bit
    rts

; =====================================================================
; InitSPCForMSU — Minimal APU/DSP init for standalone MSU audio
; =====================================================================
; Uploads a tiny SPC700 program to $0200 via IPL protocol:
;   - DSP FLG ($6C) = $00  (clear soft-reset and mute)
;   - DSP MVOL L/R ($0C/$1C) = $7F (max)
;   - DSP EVOL L/R ($2C/$3C) = $00
; Then executes that program and leaves SPC idling.

InitSPCForMSU:
    ; Wait for SPC IPL ready signature on ports 0/1 = $AA/$BB
@WaitReady:
    lda APUIO0
    cmp #$AA
    bne @WaitReady
    lda APUIO1
    cmp #$BB
    bne @WaitReady

    ; Stage transfer: nonzero in port1, target address in ports2/3, then $CC in port0
    lda #$01
    sta APUIO1
    lda #<SPC_UPLOAD_ADDR
    sta APUIO2
    lda #>SPC_UPLOAD_ADDR
    sta APUIO3
    lda #$CC
    sta APUIO0

@WaitCCAck:
    cmp APUIO0
    bne @WaitCCAck

    ; Transfer SPC init program bytes
    ldx #$0000
    lda #$00                ; transfer counter value mirrored by SPC on port0
@SendByte:
    pha                     ; save counter
    lda.w SPCInitProgram,x
    sta APUIO1              ; payload byte
    pla                     ; restore counter
    sta APUIO0              ; transfer counter
@WaitByteAck:
    cmp APUIO0
    bne @WaitByteAck
    inc a
    inx
    cpx #SPC_INIT_SIZE
    bne @SendByte

    ; Start uploaded code at SPC_UPLOAD_ADDR
    ; Port1=0 indicates execution request, port2/3 carry entry point,
    ; port0 must be previous counter + 2 (or more)
    sta $0000               ; save final counter in scratch
    stz APUIO1
    lda #<SPC_UPLOAD_ADDR
    sta APUIO2
    lda #>SPC_UPLOAD_ADDR
    sta APUIO3
    lda $0000
    clc
    adc #$02
    sta APUIO0

@WaitStartAck:
    cmp APUIO0
    bne @WaitStartAck

    rts

; =====================================================================
; StartPlayback — Initialize and Begin Video Playback
; =====================================================================
; Configures BG mode, tilemap, VRAM, reads the .msu header, seeks past
; the header, starts audio, and sets GameState = 1.

StartPlayback:
    ; --- Force blank (screen off while we reconfigure PPU) ---
    lda #$80
    sta INIDISP

    ; --- Set BG Mode 1 with BG1 as 4bpp ---
    ; Mode 1: BG1 = 4bpp (16 colors/tile from one of 8 sub-palettes)
    ;         BG2 = 4bpp, BG3 = 2bpp (both unused, not enabled on TM)
    lda #$01                ; Mode 1, no 16x16 tiles
    sta BGMODE

    ; --- Set BG1 tilemap address ---
    ; BG1SC register ($2107):
    ;   Bits 2-7: tilemap base in $400-word increments
    ;   Bits 0-1: tilemap size (00 = 32×32 entries)
    ; We want tilemap at VRAM $0000 → bits 2-7 = 0 → BG1SC = $00
    lda #BG1SC_VALUE
    sta BG1SC

    ; --- Set BG1 character (tile data) base to buffer A ---
    ; BG12NBA ($210B):
    ;   Bits 0-3: BG1 base in $1000-word increments
    ;   Bits 4-7: BG2 base (unused)
    ; Buffer A at VRAM $1000 words → value $01
    lda #BG1_BASE_A
    sta BG12NBA

    ; --- Initialize dedicated blank tile in both tile buffers ---
    ; We reserve tile index 576 (first tile after streamed video tiles) as a
    ; constant all-zero tile so letterbox rows never sample live video data.
    ; Tile address = buffer_base + (tile_index * 16 words).
    lda #$80                ; Increment VRAM address after high-byte writes
    sta VMAIN
    rep #$20
    .16bit

    ; Clear blank tile in buffer A
    lda #TILEDATA_A + (BLANK_TILE_INDEX * 16)
    sta VMADDL
    ldy #$0010              ; 16 words = 32 bytes per 4bpp tile
@ZeroBlankA:
    stz VMDATAL
    stz VMDATAH
    dey
    bne @ZeroBlankA

    ; Clear blank tile in buffer B
    lda #TILEDATA_B + (BLANK_TILE_INDEX * 16)
    sta VMADDL
    ldy #$0010
@ZeroBlankB:
    stz VMDATAL
    stz VMDATAH
    dey
    bne @ZeroBlankB

    sep #$20
    .8bit

    ; --- Set VRAM increment mode ---
    ; VMAIN ($2115): after writing $2118/$2119, increment VRAM address.
    ;   Bit 7 = 1: increment after writing $2119 (high byte)
    ;   Bits 0-1 = 00: increment by 1 word
    lda #$80
    sta VMAIN

    ; --- Initialize tilemap ---
    ; Write 32×32 = 1024 tilemap entries (2 bytes each).
    ; For the visible 32×18 area, each entry contains:
    ;   Low byte:  tile number (0-575, sequential)
    ;   High byte: attributes (priority=0, flip=none, palette=region_idx in bits 2-4)
    ; For the remaining rows 18-31, entries are $0000 (blank tile).
    ;
    ; Tilemap entry format:
    ;   Low byte:  TTTTTTTT  (tile number bits 0-7)
    ;   High byte: VHOPPPtt  V=vflip, H=hflip, O=priority,
    ;              PPP=palette(0-7), tt=tile bits 9-8
    ;
    ; Our tile numbering is sequential: row 0 col 0 = tile 0, row 0 col 1
    ; = tile 1, etc. up to tile 575 (32×18-1).

    ; Set VRAM address to tilemap start
    lda #<TILEMAP_VRAM
    sta VMADDL
    lda #>TILEMAP_VRAM
    sta VMADDH

    ; We use 16-bit writes for efficiency: low byte first via $2118,
    ; then high byte via $2119, which also triggers the address increment.
    rep #$30
    .16bit

    ldy #$0000              ; Y = tile index counter
    ldx #$0000              ; X = row counter

@TilemapRow:
    cpx #TILE_ROWS          ; Are we past the visible area?
    bcs @BlankRows

    ; Visible row. Compute palette for this row's vertical region:
    ; row_region = row / 9 (0 for rows 0-8, 1 for rows 9-17)
    ; We compute this per-tile below, but pre-compute the row component.
    phx                     ; Save row counter
    ; X = current tile row. region_row = X / 9
    ; For rows 0-8, region_row = 0. For rows 9-17, region_row = 1.
    txa
    cmp #$0009              ; Row >= 9?
    bcc @TopRegion
    lda #$0004              ; Bottom row: region_row * 4 = 4
    bra @HaveRowPalBase
@TopRegion:
    lda #$0000              ; Top row: region_row * 4 = 0
@HaveRowPalBase:
    sta $0020               ; Temp: row palette base (0 or 4)

    ; Write 32 entries for this row
    sep #$20
    .8bit

    lda #$00                ; Column counter
    sta $0022

@TilemapCol:
    ; Write tile index low byte
    tya                     ; Y = tile number (0-575)
    sta VMDATAL             ; Tile number bits 0-7

    ; Compute high byte: palette in bits 2-4, tile bits 9-8 in bits 0-1
    ; Palette = row_base + col/8
    lda $0022               ; Current column (0-31)
    lsr a
    lsr a
    lsr a                   ; col / 8 = region column (0-3)
    clc
    adc $0020               ; + row palette base (0 or 4) = palette index (0-7)
    asl a
    asl a                   ; Shift to bits 2-4 position
    ; Now add tile number bits 9-8 (for tile numbers > 255)
    pha                     ; Save palette bits
    sty $0026               ; Store 16-bit tile number to temp
    lda $0027               ; High byte of tile number (bits 8-15)
    and #$03                ; Only bits 0-1 (tile bits 9-8)
    sta $0024               ; Temp
    pla                     ; Restore palette bits
    ora $0024               ; Combine palette + tile high bits
    sta VMDATAH             ; Write high byte (triggers VRAM increment)

    iny                     ; Next tile number
    lda $0022
    inc a
    sta $0022
    cmp #TILE_COLS
    bne @TilemapCol

    rep #$20
    .16bit
    plx                     ; Restore row counter
    inx
    bra @TilemapRow

@BlankRows:
    ; Fill remaining rows (18-31) with a dedicated blank tile + palette 0.
    ; Tile 0 is part of the video stream and changes every frame, so using
    ; it here causes garbage in the letterbox bars.
    ; 14 rows × 32 = 448 entries
    sep #$20
    .8bit
    ldy #448               ; (reuse Y as counter here)
@BlankLoop:
    lda #<BLANK_TILE_INDEX
    sta VMDATAL
    lda #>BLANK_TILE_INDEX  ; Bits 0-1 = tile bits 9-8, palette bits stay 0
    and #$03
    sta VMDATAH
    dey
    bne @BlankLoop
    rep #$20
    .16bit

    sep #$20
    .8bit

    ; --- Set BG1 scroll to center 144 lines in 224-line display ---
    ; The SNES display is 224 lines. Our content is 144 lines (18 tiles).
    ; We want the image centered vertically with 40 blank lines top and bottom.
    ; BG scroll = -(224 - 144) / 2 = -40 in signed terms.
    ; The PPU scroll register interprets values as unsigned offset into the
    ; tilemap. For BG modes, the effective range wraps at 256 (for 32-tile maps).
    ; Setting V-scroll to (256 - 40) = 216 would push the content UP by 40 pixels,
    ; showing rows 5-22 of the 32-row tilemap (rows 5-22 = tiles rows 5-22).
    ; But our content is at tilemap rows 0-17, and rows 18-31 are blank.
    ; A V-scroll of 0 keeps the content at the top of the screen.
    ; To center: we want 40 blank lines above. Since rows 18-31 of the tilemap
    ; are blank (14 rows = 112 pixels), scrolling to V = 256 - 40 = 216 would
    ; show 40 pixels of blank tilemap rows (rows 27-31 partial + row 0 starts
    ; at line 40 of the screen). Let's verify:
    ;   V-scroll = 216: first visible tilemap line = line 216.
    ;   Tilemap is 256 lines (32 rows × 8 px). Lines 216-255 are rows 27-31
    ;   (40 lines of blank), then lines 0-183 are rows 0-22 (our 144 lines of
    ;   content appear at rows 0-17 = lines 0-143 within that range).
    ;   Visible: 40 blank + 144 content + 40 blank = 224. ✓
    lda #216                ; V-scroll = 216 ($D8)
    sta BG1VOFS             ; Low byte
    stz BG1VOFS             ; High byte = 0

    ; H-scroll stays at 0 (content is full width)
    stz BG1HOFS
    stz BG1HOFS

    ; --- Enable BG1 on main screen ---
    lda #$01
    sta TM

    ; --- Set backdrop to black (visible in letterbox bars) ---
    stz CGADD
    lda #<COLOR_BLACK
    sta CGDATA
    lda #>COLOR_BLACK
    sta CGDATA

    ; --- Read .msu header ---
    ; Seek to offset 0 in the MSU data file (the .msu file)
    ; The seek offset is written across $2000-$2003 (one byte per register).
    ; The seek is initiated when $2003 (MSB) is written, which also clears
    ; the data_busy flag.
    lda #$00
    sta MSUSeek             ; $2000: Byte 0 of seek address (LSB)
    sta MSUSeek+1           ; $2001: Byte 1
    sta MSUSeek+2           ; $2002: Byte 2
    sta MSUSeek+3           ; $2003: Byte 3 (MSB) — triggers seek

    ; Wait for data to be ready (busy flag clears)
@WaitSeek1:
    lda MSUStatus
    and #MSU_DATA_BUSY
    bne @WaitSeek1

    ; Read the 16-byte header into WRAM starting at DMABuffer
    ; We'll validate the magic bytes and extract the frame count.
    ldx #$0000
@ReadHeader:
    lda MSUDataRead         ; Read one byte (auto-increments MSU offset)
    sta DMABuffer,x
    inx
    cpx #MSU_HEADER_SIZE
    bne @ReadHeader

    ; Validate magic "FFVI" at header bytes 0-3
    lda DMABuffer           ; 'F'
    cmp #$46
    bne @BadHeader
    lda DMABuffer+1         ; 'F'
    cmp #$46
    bne @BadHeader
    lda DMABuffer+2         ; 'V'
    cmp #$56
    bne @BadHeader
    lda DMABuffer+3         ; 'I'
    cmp #$49
    bne @BadHeader

    ; Extract frame count from header bytes 4-5 (u16le)
    rep #$20
    .16bit
    lda DMABuffer+4
    sta FrameCount
    sep #$20
    .8bit

    ; Data port is now positioned right after the header, at offset 16 —
    ; the first byte of frame 0's palette data. We don't need to seek again.

    ; --- Start MSU-1 audio ---
    ; Load audio track 1 (the intro FMV audio, from the .pcm file).
    ; Explicitly stop first to ensure a clean state.
    lda #MSU_STOP
    sta MSUControl

    lda #$01
    sta MSUTrack            ; Track number low byte
    stz MSUTrack+1          ; Track number high byte

    ; Wait for audio track to finish loading
@WaitAudio:
    lda MSUStatus
    and #MSU_AUDIO_BUSY
    bne @WaitAudio

    ; Set volume to maximum
    lda #$FF
    sta MSUVolume

    ; Start playback — no loop (play once)
    lda #MSU_PLAY_ONCE
    sta MSUControl

    ; --- Initialize playback state ---
    rep #$20
    .16bit
    stz FrameCurrent
    sep #$20
    .8bit
    stz SubFrame
    stz ActiveBuffer        ; Start writing to buffer A, displaying... nothing yet

    ; --- Turn screen on ---
    lda #$0F
    sta INIDISP

    ; --- Set game state to playing ---
    lda #$01
    sta GameState

    rts

@BadHeader:
    ; Header validation failed — just return without starting playback.
    ; This shouldn't happen with a properly converted .msu file.
    lda #$0F
    sta INIDISP             ; Turn screen back on
    rts

; =====================================================================
; StopPlayback — Stop Video and Return to Idle
; =====================================================================
StopPlayback:
    ; --- Stop MSU-1 audio ---
    lda #MSU_STOP
    sta MSUControl

    ; --- Force blank while reconfiguring ---
    lda #$80
    sta INIDISP

    ; --- Reset to simple color fill mode ---
    ; Turn off BG1, return to mode 0 (no active backgrounds needed for a
    ; solid color screen — the backdrop color fills the screen).
    stz BGMODE              ; Mode 0
    stz TM                  ; No BGs on main screen
    stz BG12NBA             ; Reset character base

    ; --- Set backdrop back to blue ---
    stz CGADD
    lda #<COLOR_BLUE
    sta CGDATA
    lda #>COLOR_BLUE
    sta CGDATA

    ; Clear BG1 scroll
    stz BG1HOFS
    stz BG1HOFS
    stz BG1VOFS
    stz BG1VOFS

    ; --- Turn screen on ---
    lda #$0F
    sta INIDISP

    ; --- Reset state ---
    stz GameState
    stz SubFrame
    stz ActiveBuffer

    rts

; =====================================================================
; Sub-Frame DMA Routines
; =====================================================================
; These routines stream tile bytes directly from MSU data port $2001 into
; VRAM via DMA fixed-source mode. The MSU-1 auto-increments its internal
; read pointer on each access to $2001, so DMA can repeatedly read the same
; mapped address while consuming sequential stream bytes.
;
; Palette staging is kept from the previous implementation: we still read the
; 256-byte palette into WRAM at sub-frame 0 and apply it at sub-frame 3 so
; tile/palette presentation remains synchronized at frame boundaries.

; --- DoSubFrame0: Palette + First Tile Chunk ---
; Read PALETTE_BYTES from MSU into WRAM palette buffer, then on the next
; VBlank DMA TILE_CHUNK_0 directly from MSU ($2001) to VRAM.

DoSubFrame0:
    rep #$10                ; X/Y = 16-bit for large counters
    sep #$20                ; A = 8-bit for MSU data reads
    .8bit

    ; --- Read palette data (256 bytes) from MSU to WRAM ---
    ldx #$0000
@ReadPal:
    lda MSUDataRead
    sta PaletteBuffer,x
    inx
    cpx #PALETTE_BYTES
    bne @ReadPal

    ; Wait for the next VBlank to do the DMA transfer.
    stz NMIReady
    @WaitVB0:
        lda NMIReady
        beq @WaitVB0
    stz NMIReady

    ; --- DMA channel 1: Tile chunk 0 from MSU ($2001) -> VRAM ---
    lda ActiveBuffer
    beq @WriteToA_0
    lda #<TILEDATA_B
    sta VMADDL
    lda #>TILEDATA_B
    sta VMADDH
    bra @DMASetup0
@WriteToA_0:
    lda #<TILEDATA_A
    sta VMADDL
    lda #>TILEDATA_A
    sta VMADDH
@DMASetup0:
    lda #$80                ; VMAIN: increment after high byte write
    sta VMAIN

    lda #$09                ; CPU->PPU, fixed source, mode 1 ($2118/$2119)
    sta DMA1CTRL
    lda #$18                ; Destination $2118 (VMDATAL)
    sta DMA1DEST
    lda #<MSUDataRead       ; Source $2001 low
    sta DMA1SRCL
    lda #>MSUDataRead       ; Source $2001 high
    sta DMA1SRCH
    lda #$00                ; Source bank for MMIO
    sta DMA1SRCB
    lda #<TILE_CHUNK_0
    sta DMA1SIZEL
    lda #>TILE_CHUNK_0
    sta DMA1SIZEH

    ; Trigger channel 1 only (tile chunk 0). Palette is deferred to
    ; sub-frame 3 so palette and displayed tile data stay in sync.
    lda #$02
    sta DMAEN

    rts

; --- DoSubFrame1: Tile Chunk 1 ---
DoSubFrame1:
    ; Wait for VBlank
    stz NMIReady
    @WaitVB1:
        lda NMIReady
        beq @WaitVB1
    stz NMIReady

    ; Set VRAM address to continue where chunk 0 left off.
    ; Chunk 0 wrote TILE_CHUNK_0 bytes = TILE_CHUNK_0/2 words.
    ; VRAM address = buffer_base + TILE_CHUNK_0/2
    lda ActiveBuffer
    beq @WriteToA_1
    rep #$20
    .16bit
    lda #TILEDATA_B + (TILE_CHUNK_0 / 2)
    bra @SetAddr1
@WriteToA_1:
    rep #$20
    .16bit
    lda #TILEDATA_A + (TILE_CHUNK_0 / 2)
@SetAddr1:
    sta VMADDL              ; 16-bit write to $2116/$2117
    sep #$20
    .8bit

    lda #$80
    sta VMAIN

    lda #$09                ; CPU->PPU, fixed source, mode 1
    sta DMA0CTRL
    lda #$18                ; VMDATAL
    sta DMA0DEST
    lda #<MSUDataRead
    sta DMA0SRCL
    lda #>MSUDataRead
    sta DMA0SRCH
    lda #$00
    sta DMA0SRCB
    lda #<TILE_CHUNK_1
    sta DMA0SIZEL
    lda #>TILE_CHUNK_1
    sta DMA0SIZEH

    lda #$01                ; Trigger channel 0
    sta DMAEN

    rts

; --- DoSubFrame2: Tile Chunk 2 ---
DoSubFrame2:
    ; Wait for VBlank
    stz NMIReady
    @WaitVB2:
        lda NMIReady
        beq @WaitVB2
    stz NMIReady

    ; VRAM address = buffer_base + (TILE_CHUNK_0 + TILE_CHUNK_1) / 2
    lda ActiveBuffer
    beq @WriteToA_2
    rep #$20
    .16bit
    lda #TILEDATA_B + ((TILE_CHUNK_0 + TILE_CHUNK_1) / 2)
    bra @SetAddr2
@WriteToA_2:
    rep #$20
    .16bit
    lda #TILEDATA_A + ((TILE_CHUNK_0 + TILE_CHUNK_1) / 2)
@SetAddr2:
    sta VMADDL
    sep #$20
    .8bit

    lda #$80
    sta VMAIN

    lda #$09
    sta DMA0CTRL
    lda #$18
    sta DMA0DEST
    lda #<MSUDataRead
    sta DMA0SRCL
    lda #>MSUDataRead
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

; --- DoSubFrame3: Final Tile Chunk ---
DoSubFrame3:
    ; Wait for VBlank
    stz NMIReady
    @WaitVB3:
        lda NMIReady
        beq @WaitVB3
    stz NMIReady

    ; --- DMA channel 0: Palette → CGRAM ---
    ; Apply this frame's palette in the same VBlank where we finish tile
    ; upload and swap display buffers, preventing palette/tile mismatch.
    stz CGADD
    lda #$00                ; CPU→PPU, mode 0
    sta DMA0CTRL
    lda #$22                ; $2122 (CGDATA)
    sta DMA0DEST
    lda #<PaletteBuffer
    sta DMA0SRCL
    lda #>PaletteBuffer
    sta DMA0SRCH
    lda #$7E
    sta DMA0SRCB
    lda #<PALETTE_BYTES
    sta DMA0SIZEL
    lda #>PALETTE_BYTES
    sta DMA0SIZEH

    ; VRAM address = buffer_base + (TILE_CHUNK_0 + TILE_CHUNK_1 + TILE_CHUNK_2) / 2
    lda ActiveBuffer
    beq @WriteToA_3
    rep #$20
    .16bit
    lda #TILEDATA_B + ((TILE_CHUNK_0 + TILE_CHUNK_1 + TILE_CHUNK_2) / 2)
    bra @SetAddr3
@WriteToA_3:
    rep #$20
    .16bit
    lda #TILEDATA_A + ((TILE_CHUNK_0 + TILE_CHUNK_1 + TILE_CHUNK_2) / 2)
@SetAddr3:
    sta VMADDL
    sep #$20
    .8bit

    lda #$80
    sta VMAIN

    lda #$09
    sta DMA1CTRL
    lda #$18
    sta DMA1DEST
    lda #<MSUDataRead
    sta DMA1SRCL
    lda #>MSUDataRead
    sta DMA1SRCH
    lda #$00
    sta DMA1SRCB
    lda #<TILE_CHUNK_3
    sta DMA1SIZEL
    lda #>TILE_CHUNK_3
    sta DMA1SIZEH

    ; Trigger both channels: ch0 palette + ch1 tile chunk 3.
    lda #$03
    sta DMAEN

    ; Swap display/write buffers during VBlank to avoid mid-frame base changes.
    ; After toggling ActiveBuffer, it indicates NEXT write target; we display
    ; the opposite buffer (the one we just finished writing).
    lda ActiveBuffer
    eor #$01
    sta ActiveBuffer
    bne @UseBufferA_3
    lda #BG1_BASE_B
    bra @SetBase_3
@UseBufferA_3:
    lda #BG1_BASE_A
@SetBase_3:
    sta BG12NBA

    rts


; =====================================================================
; NMI Handler (VBlank Interrupt)
; =====================================================================
; Minimal: just acknowledge and set the flag for the main loop.
; All actual VBlank work (DMA) is done in the main loop after checking
; NMIReady, which guarantees we're still in VBlank when we DMA.
;
; CRITICAL: The NMI can fire at ANY point in the main code, including
; sections running in 16-bit accumulator mode (rep #$20). The handler
; MUST explicitly set the accumulator width before using immediate
; operands, otherwise the CPU interprets 1-byte immediates as 2-byte,
; corrupting the instruction stream and causing runaway execution.
;
; Strategy: force 16-bit A for pha/pla (preserve all 16 bits of A),
; then force 8-bit A for the actual handler work. RTI restores the
; original processor status register automatically.

NMIHandler:
    rep #$20                ; Force 16-bit A so pha saves the full accumulator
    .16bit
    pha                     ; Save A (all 16 bits)
    phb                     ; Save data bank
    sep #$20                ; Force 8-bit A for register access
    .8bit
    lda #$00
    pha
    plb                     ; DB=$00 so absolute MMIO accesses are correct
    lda RDNMI               ; Acknowledge NMI by reading $4210
    lda #$01
    sta NMIReady             ; Signal main loop that VBlank occurred
    plb                     ; Restore original data bank
    rep #$20                ; Back to 16-bit for pla
    .16bit
    pla                     ; Restore full 16-bit A
    rti                     ; RTI restores P register → original A/X/Y sizes

; =====================================================================
; Empty Handler (unused vectors)
; =====================================================================
EmptyHandler:
    rti

; =====================================================================
; SPC init payload (uploaded by InitSPCForMSU)
; =====================================================================
; SPC700 code assembled as raw bytes:
;   mov $F2,#$6C ; DSP FLG
;   mov $F3,#$00 ; clear mute/reset
;   mov $F2,#$0C ; MVOL L
;   mov $F3,#$7F
;   mov $F2,#$1C ; MVOL R
;   mov $F3,#$7F
;   mov $F2,#$2C ; EVOL L
;   mov $F3,#$00
;   mov $F2,#$3C ; EVOL R
;   mov $F3,#$00
; loop: bra loop

SPCInitProgram:
    .DB $8F,$6C,$F2,$8F,$00,$F3
    .DB $8F,$0C,$F2,$8F,$7F,$F3
    .DB $8F,$1C,$F2,$8F,$7F,$F3
    .DB $8F,$2C,$F2,$8F,$00,$F3
    .DB $8F,$3C,$F2,$8F,$00,$F3
    .DB $2F,$FE
