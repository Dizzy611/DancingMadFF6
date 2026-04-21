# DancingMadFF6 `patch/ff3msu.asm` Detailed Walkthrough

## Purpose and audience
This document explains the current code in `patch/ff3msu.asm` for someone who already reads 65c816 + WLA-DX, but is new to SNES audio/video hardware and FF6 internals.

It focuses on:
- What each major section does.
- Why specific hook points were chosen.
- How FF6 vanilla behavior is preserved or intentionally changed.
- What hardware concepts matter for understanding this patch.

## Maintainer note/disclosure

This walkthrough was written and rewritten as part of a deep back and forth with an LLM. It is accurate, but it is not written entirely in my style/hand, merely corrected where necessary. Future maintainers should use this document as a guideline for developing an understanding of the hows and whys before beginning work. Obviously, if code contradicts, the code is truth, but effort should be made to keep this document up to date.

## What this patch is, at a high level
`patch/ff3msu.asm` is a combined patch with one core feature and two extras:

1. **MSU-1 music replacement** (core purpose): intercepts FF6's SPC sound commands and routes audio through the MSU-1 where `.pcm` track files are available, falling back to SPC when they are not.
2. **Title metadata overlay** (diagnostic): renders a small build-date + option-flag OSD on the title screen so anyone testing the patch can confirm which build they are running.
3. **FMV playback** (bonus feature): streams video frames from MSU-1 data and DMA-transfers them to VRAM for full-motion video on the title flow.

These share a single file because they all hook into NMI timing and/or the title-screen execution context:
- FF6 command processing (song/fade commands).
- NMI/vblank timing behavior.
- Title/cutscene flow in decompressed WRAM code.

## SNES concepts you need for this file

### CPU + NMI timing
- The main game logic runs in normal code flow.
- NMI fires once per frame during vblank.
- Vblank is the safe window for most VRAM/CGRAM/OAM updates.
- This patch hooks NMI and uses it for:
  - Music fade stepping during normal gameplay.
  - A vblank-ready counter during FMV playback.
  - Optional title overlay setup.

### SPC vs APUIO ports
FF6 uses the SPC700 sound engine through CPU I/O ports:
- `$2140-$2143` (`APUIO0-3`) are command/status handoff ports.
- Vanilla FF6 event command `$FA` checks `$2143` to detect "song ended".

This patch sometimes bypasses SPC music via MSU, so it must emulate expected behavior where scripts still depend on SPC-side state.

### MSU-1 registers used here
- `$2000` status / data-seek registers.
- `$2001` data read stream.
- `$2002-$2007` ID / audio control.

Important status bits used:
- `AudioBusy`, `AudioPlaying`, `BadTrack`, `DataBusy`.

Control values used:
- Stop, pause, play loop, play no-loop.

### PPU resources used by title/FMV code
- VRAM tile/tilemap writes through `$2115-$2119`.
- CGRAM writes through `$2121-$2122`.
- BG mode/layers via `$2105`, `$212C`, `$212D`, etc.
- DMA channels through `$430x/$431x` and `$420B`.

The FMV path is mostly: read frame chunks from MSU -> DMA to VRAM over subframes -> show via BG1.

## File layout and hook map

### Core hooks patched into vanilla code
These are short overwrite stubs near the top of the file.

1. `C0/FF10` NMI vector jump:
- Patched to `jml NMIHandle`.
- Vanilla reference: `external/ff6/notes/ff3u.asm` shows `C0/FF10: JML $001500`.

2. `C5/0148` SPC command dispatcher:
- Patched to `jml CommandHandle`.
- Vanilla reference: `C5/0148` loads command from DP `$00`.

3. `C5/0182` play-song entry:
- Patched to `jsl MSUMain`.
- Vanilla reference: `C5/0182` starts song-index handling path.

4. `C0/B8C7` event command `$FA` (wait for song end):
- Patched to `jml EventCmdFAHook`.
- Vanilla reference: checks `$2143`, then returns/wakes event VM.

5. `C2/680F` title cutscene jump:
- Patched to `jml TitleScreenHook`.
- Vanilla reference: `JML $7E5000` after cutscene decompression.

## RAM/state model used by this patch

### FF6 direct-page sound command block ($1300–$130B)
This range is vanilla FF6's SPC command workspace. The patch preserves most of it and repurposes one byte:
- `$1300-$1302`: pending play command/track/volume (`PlayCommand`, `PlayTrack`, `PlayVolume`).
- `$1304-$1306`: "current" command/track/volume snapshots.
- `$1308-$130A`: last command/track/volume snapshots.
- `$130B`: in vanilla, this is "previous command byte 3" (the fourth byte of the prior-command snapshot). The patch repurposes it as `FadeFlag` — MSU fade mode (0=none, 1=fade-to-zero, 2=fade-down, 3=fade-up). The vanilla engine no longer references this byte once the patch takes over SPC command routing.

### Patch-owned runtime state
- `$1E30-$1E36`: MSU/overlay booleans and current MSU state.
- `$7EF001`: `MSULastTrackSet` stored outside save-copied area.
- `$7EF300+`: FMV palette and scratch buffers.
- `$7EF440+`: mirrored metadata block for title overlay.

Key design point: comments explain why some state moved out of SRAM-copied ranges, so patch-only state does not accidentally persist across save/load.

## Music command path: detailed behavior

## 1) `CommandHandle`
`CommandHandle` intercepts specific SPC commands from `PlayCommand`:
- `$82` (`SPCSubSong`) -> `SubSongHandle`
- `$81` (`SPCFade`) -> `FadeCommandHandle`
- `$89` ("continue to next song part") -> `SPC89Handle`
- anything else -> `OriginalCommand`

`OriginalCommand` re-enters vanilla dispatcher at:
- `C5/014C` when command nonzero.
- `C5/0171` when command is zero.

So the patch only special-cases select commands and leaves the rest of FF6's dispatcher intact.

## 2) `SubSongHandle` and Dancing Mad progression
This path handles special transitions for Dancing Mad parts:
- Uses `MSULastTrackSet` + `DancingFlag` to avoid a first-call false positive.
- Converts progression to play tracks `$66` and `$67` for part 2/3 when conditions match.

If conditions do not match, it falls back to vanilla path.

## 3) `FadeCommandHandle` — and how fading works end-to-end

Fading is one of the trickiest parts of the MSU-1 integration, so this section provides full background before explaining the patch code.

### How vanilla FF6 fading works (background)

Vanilla FF6 has exactly one fade-related SPC command: `$81`. The game writes three bytes to the command block at `$1300`:

| `$1300` | `$1301` | `$1302` |
|---------|---------|----------|
| `$81` (fade) | fade **speed** (SPC ticks) | **target volume** (0–FF) |

The game sends this command and then **forgets about it**. All the actual volume stepping happens inside the SPC700 sound processor:

1. The SPC's `Interrupt_81` handler reads the speed and target volume.
2. It calculates a per-frame step rate: (current volume − target volume) / speed.
3. The SPC DSP envelope hardware then applies that step rate automatically, frame by frame, with no further involvement from the main CPU.

There is no fade loop on the 65816 side. There is no per-frame polling. The SPC DSP does all the work.

The game issues command `$81` in these situations:

| Caller | Speed | Target | Purpose |
|--------|-------|--------|---------|
| EventCmd_f1 (play song + fade in) | event param | `$FF` | Start song at volume `$20`, fade to full |
| EventCmd_f2 (fade out current song) | event param | `$00` | Fade current song to silence |
| EventCmd_f3 (restore previous song) | event param | `$FF` | Restart previous song at volume `$00`, fade to full |
| BtlGfx_09 (enter battle) | `$10` | `$00` | Quick fade to silence for battle transition |
| BtlGfx_0c (final battle phase) | `$80` | `$00` | Slower fade to silence |
| World map cutscenes | varies | `$00` | Fade music for scripted sequences |

Note that EventCmd_f1 and f3 are two-step sequences: they first send a play-song command (`$10`) at a specific starting volume, then *immediately* send `$81` to fade from there. This matters for the patch.

### Why the patch must replace this

The MSU-1 volume register (`$2006`) is a dumb write-only byte: write a value, audio instantly plays at that level. There is no envelope hardware, no fade support, no timing. So the patch must **build its own per-frame fade loop on the 65816 side** to replace what the SPC DSP used to handle automatically.

### How the patch implements fading

The fade implementation is split into two halves: **intent capture** (`FadeCommandHandle`, runs when the game sends command `$81`) and **execution** (`FadeRoutine`, runs every NMI frame).

#### Intent capture: `FadeCommandHandle`

When command `$81` arrives, `FadeCommandHandle` does **not** perform the actual fade. It records intent:

- Compute `FadeTickInterval = PlayTrack >> 2` (PlayTrack holds the SPC fade duration in this command). Minimum interval is 1 — never zero. Resets `FadeTickCounter` for an immediate first step.
- Latch `FadeTargetVolume = PlayVolume` (immune to later `PlayVolume` overwrites by SFX or other commands — the *PlayVolume aliasing* problem).
- Compare `FadeTargetVolume` against `MSUCurrentVolume` to set `FadeFlag`:
  - Target = 0 → `FadeFlag = 1` (fade to zero)
  - Target < current → `FadeFlag = 2` (fade down to target)
  - Target > current → `FadeFlag = 3` (fade up to target)
  - Target = current → clear flag, nothing to do

Then it **always falls through to `OriginalCommand`**, so the SPC also receives the `$81`. This is harmless because the SPC is either playing silence or a masked-off track when MSU is active.

#### The `FadeInPending` problem (EventCmd_f3)

EventCmd_f3 sends: play previous song at volume 0, then `$81` fade to `$FF`.

The fade command `$81` can arrive *before* the MSU track actually starts playing (because `MSUMain` hasn't run yet for the new track). At that moment `MSUCurrentTrack = 0`, so `FadeCommandHandle` can't set up a fade on a nonexistent track.

Solution: if `MSUCurrentTrack = 0` and target volume > 0, set `FadeInPending = 1` instead of `FadeFlag`. Later, when `MSUMain` starts the track at `PlayMSU`, it checks `FadeInPending`:
- If set: seed `MSUCurrentVolume` at a low value (`FadeInStartVolume = $20`) and set `FadeFlag = 3` so the NMI fade ramps the track up.
- If not set: play at `PlayVolume` directly.

`FadeFlag` values summary:
- `0` — no fade active.
- `1` — fade toward zero (stops MSU hardware when complete).
- `2` — fade down toward `FadeTargetVolume`.
- `3` — fade up toward `FadeTargetVolume`.

### Historical note: the contrib code

The fade system descends from Conn's original implementation in `contrib/ff3_fade_orgNMI-handler.asm`. The original had one additional feature: a **`setFadeFlag` auto-detect block**. When `FadeFlag = 0`, it would compare `PlayVolume` to `MSUCurrentVolume` every NMI frame and auto-start a fade if they differed — a "safety net" that self-corrected mismatches.

This was removed in commit `49ce2c2` because `PlayVolume` can be stale from an earlier command. The auto-detect would see a mismatch that wasn't a real fade request and trigger unintended volume changes. Now `FadeFlag` is only set by `FadeCommandHandle` (actual `$81` commands) or by `PlayMSU` (deferred `FadeInPending` at track start).

The step size also changed: Conn's original used `dec dec dec` (step of 3 per NMI), the current code uses `FadeStep = $20` (step of 32 per NMI) — roughly 10× faster per frame.

### Known structural fragility: `PlayVolume` as intent signal

`PlayVolume` (`$1302`) is a vanilla SPC mailbox. The game writes it when issuing a sound command and the SPC reads it within microseconds; after that, vanilla code considers it undefined — it will be overwritten by any subsequent sound command, SFX alias, or `OriginalCode` side-effect. The patch reads `PlayVolume` at `$81` intercept time to decide fade direction, which is safe. However, `DoNothing`'s guard `lda PlayVolume / beq _skip` re-reads it later to determine whether a fade-to-silence is still in progress — and `PlayVolume` can be zero for reasons unrelated to an active fade (e.g. the old `$43` position-marker zero-vol path caused this). The `FadeTargetVolume` latch introduced in `bad74d2` reduces but does not fully eliminate this exposure.

A clean architectural fix would be a single byte `MSUFadeIntent` ($1E3A, adjacent to `FadeTickCounter`) that captures fade *direction* at `$81` intercept time and is only written by MSU layer code — never by vanilla event commands or `OriginalCode`. This would make `DoNothing`'s guard read semantic state ("was a fade-to-silence explicitly requested?") instead of an ambiguous shared register. The full design is in `doc/msu-fade-intent-design.md`. **Do not implement partially** — a partial implementation would leave stale-intent bugs subtler than the current model. The current code is correct for all known scenarios; `MSUFadeIntent` is worth implementing only if a future track addition or new code path re-triggers an Opera-class contamination bug.

## 4) `SPC89Handle` — "continue to next song part"
Vanilla SPC command `$89` tells the sound engine to advance to the next part of a multi-part song. It is triggered by event command `$F7` ("continue song"). In vanilla FF6 this is used for the Phantom Train sequence, where the music transitions from ambient sound effects to the actual train theme.

The patch intercepts `$89` only when the current track is `$20` (Phantom Train):
- Sets `TrainFlag` so downstream MSU logic knows a train-music transition is in progress.
- Forces `PlayVolume = $FF`.
- Calls `MSUMain` to load the appropriate MSU track.

For any other track, `$89` passes through to the vanilla SPC handler unchanged.

## 5) `MSUMain`: central track selection and fallback logic
`MSUMain` does the core "MSU if possible, SPC otherwise" routing.

Flow:
1. Ensure MSU presence (`MSUCheck`), otherwise jump to `OriginalCode`.
2. Handle special flags (train state clear rules).
3. Dispatch per-track special handling via jump table for IDs `< $55`.
4. Determine whether to start/stop/reuse track.
5. Write track to MSU registers, wait busy clear, handle missing-track fallback.
6. Set volume and fade state.
7. Set loop/no-loop mode via `WillItLoop`.
8. Return into `OriginalCode` (SPC masking logic).

### Special track handlers
Notable remaps/logic:
- `SilenceHandler`: route to stop/mask handling.
- `RePlayHandler` (`$51`): replay current MSU track.
- `BattleTheme`: pause current track before handoff logic.
- `Kefka1`: rewrites to `$65`.
- `Kefka5`: avoid restarting if `$52` already playing and active.
- `Ending1/Ending2`: avoid restart or bypass second segment due to piggyback design.
- `PhantomTrain`: honor `TrainFlag`, otherwise silence/MSU stop path.

### Missing-track fallback
The MSU-1 status bit `BadTrack` (the hardware's name for this flag) means the requested `.pcm` file is not present on disk. This is not necessarily an error — some MSU packs intentionally omit certain tracks (e.g. ambient-only or SFX-only songs that the pack author chose not to replace). The SPC engine serves as the natural fallback.

When a track is missing:
- For `$65/$66/$67` (Dancing Mad segments), fall back to SPC track `$3B`.
- Otherwise stop MSU and let the SPC path proceed.

### SPC masking strategy in `OriginalCode`
When MSU-1 owns audio, the SPC still receives play commands from the game engine. `OriginalCode` decides what to do with them. The naïve approach — just let the SPC play everything at zero volume — doesn't work, because **SPC song data can contain embedded volume changes**. The SPC's DSP operates independently of the CPU; a song's instrument envelopes or explicit volume-up commands in the song script will override any volume the CPU set, and there is no CPU-side mechanism to catch or prevent this. The result would be audible SPC bleed during MSU playback.

An alternative tried early in the project's history was sending `$F0` (stop) to the SPC instead of loading any track. This silences the SPC reliably but leaves it in a "stopped" state that the game engine never normally sustains for long periods. The game's event scripts, battle system, and menu code all assume the SPC is actively playing *something* — a stopped SPC risks subtle misbehavior in status checks and transition logic.

The solution the patch settled on is **track `$51` masking**: replace most play commands with `$51`, which is a silence track with near-zero duration. This keeps the SPC in a normal operating cycle — it loads a track, plays it, finishes it almost instantly, and reports "done" through its status ports. The SPC never enters an abnormal state, and the near-instant completion means it can't bleed audio.

The exception is tracks whose SPC playback state matters for event script synchronization:
- **Position-marker tracks** (`$27`, `$41`–`$46`, `$53`–`$54`) pass through at zero volume so the SPC updates APUIO1 for `$F9` position waits. These specific tracks are safe at zero volume because their song data does not contain embedded volume increases. (`$43` was experimentally added to this list but caused the feared double-play problem and was subsequently removed.)
The looping-FA track problem (see EventCmdFAHook section) was resolved without expanding this list — `FadeRoutine` now stops the MSU hardware when volume reaches zero, clearing `AudioPlaying` directly.

## Event command integration

## `EventCmdFAHook`
Vanilla event command `$FA` ("wait for end of song") pauses the event script interpreter until the currently playing song finishes. The vanilla implementation polls `APUIO3` (`$2143`) — the SPC700 reports playback status through this port.

The patch hooks `$FA` at `C0/B8C7` because when MSU-1 audio is active, the SPC may not be playing anything meaningful, so `$2143` would give a misleading "done" signal.

### The looping-track problem

In vanilla, `$FA` is commonly used in `fade_out_song` + `wait_song` sequences — the fade tells the SPC to wind down a song, and `$FA` waits for the SPC to confirm the track actually stopped. Many of the songs faded this way are looping tracks (KIDS_RUN_THROUGH_THE_CITY, UNDER_MARTIAL_LAW, AWAKENING, NARSHE, CYAN, GAU, etc.). The SPC clears APUIO3 once the fade completes and the track truly stops, so vanilla `$FA` returns cleanly.

Under MSU-1, this breaks. `FadeRoutine` steps MSU volume to zero and clears `FadeFlag`, but **never issues a stop command** — the track continues looping silently. `AudioPlaying` stays latched, and the hook's `MSUStatus & AudioPlaying` check spins forever. This is not an obscure edge case; it affects roughly half the `$FA` call sites in the game's event scripts.

### Hook behavior

- If an MSU track is active (except ending tracks `$53/$54`), check MSU-1 `AudioPlaying` instead of `$2143`.
- If MSU audio is still playing → wait. If stopped → advance.
- If no active MSU track, or the track is an ending exception → vanilla `$2143` check.

For non-looping tracks (opera segments, grand finale, etc.) this works correctly — `AudioPlaying` clears when the track reaches its natural end.

### Fix for looping tracks (commit `8f78db8`)

The straightforward approach would have been to fall through to the vanilla APUIO3 check for looping tracks, requiring the SPC to run those tracks silently — but that risks SPC song data overriding the zero volume. The simpler alternative chosen: **when `FadeRoutine` fades MSU volume to exactly zero, it now issues `stz MSUControl` to actually stop the MSU hardware**. This clears the `AudioPlaying` status bit, so EventCmdFAHook's existing check sees "stopped" and advances normally. The hook itself is unchanged.

The non-loop list (`WillItLoop`) was also updated in this commit: NIGHTY_NIGHT (`$38`) is explicitly listed as non-looping (confirmed from MML data — it is a one-shot jingle with no loop markers). Previously absent from the list, which was harmless only because NIGHTY_NIGHT's `$FA` wait sites are in jingle-then-resume contexts where the timing gap is large enough to be forgiving.

See `doc/session-log-fa-loop-analysis.md` for the full analysis of affected tracks and the path that led to this fix.

## NMI and fade path

## `NMIHandle`
NMI wrapper prologue/epilogue saves/restores CPU state and DBR.

Main branch:
- If `FMVState != 0`: do not run normal fade/overlay logic; just increment `FMVNMIReady` and exit.
- Else: run `FadeRoutine`, then conditionally run `TitleMetadataOverlay` if title WRAM gate indicates title code context.

Then chain to original NMI handler via `jml OriginalNMIHandler` (`$1500`).

## `FadeRoutine`
Runs every NMI frame. Checks `FadeFlag` and steps MSU volume toward its target.

Three new RAM variables work alongside `FadeFlag`:
- **`FadeTargetVolume` (`$1E37`)**: the target volume, latched at `FadeCommandHandle` time. This is separate from `PlayVolume` (`$1302`) because `PlayVolume` can be overwritten by subsequent SFX/music commands before the fade completes — a race known as *PlayVolume aliasing*. Latching the target at intent-capture time makes fades immune to this.
- **`FadeTickInterval` (`$1E38`)**: NMI frames to skip between steps. Derived from the SPC fade duration (`PlayTrack` byte in the `$81` command, which encodes duration in ~29.3 Hz ticks). `FadeTickInterval = duration >> 2`. This maps the SPC's timing rate to NMI frame rate (~60 Hz) within ~2% error.
- **`FadeTickCounter` (`$1E39`)**: countdown to next active step.

### Frame-skip threshold

The tick interval is only applied selectively:

- **Fade-up (`FadeFlag = 3`)**: always frame-skip. The song already loaded (at `FadeInStartVolume`) before the ramp begins, so there is no race condition.
- **Fade-down/zero (`FadeFlag = 1/2`)**: frame-skip only when `FadeTickInterval ≥ $08` (i.e. SPC duration ≥ `$20`, roughly 1092 ms). Short fades run every NMI frame at the legacy ~133 ms speed.

The reasoning: short fades (e.g. battle exits) are often followed by an immediate hard-cut `play_song`. If a short fade applied frame-skipping it would still be at high volume when that cut hits, causing an audible pop. Long fades occur in event-script transitions gated on `wait_fade` (screen fade), giving audio time to complete even at SPC-matched speed. Below the threshold, the legacy 133 ms worst-case is short enough to be imperceptible.

### Flag values and step logic

- **Flag = 0**: return immediately.
- **Flag = 1** (fade to zero): subtract `FadeStep` ($20 = 32) from `MSUCurrentVolume`. If underflow or result < `FadeStep`, snap to 0 and clear flag. **Then issue `stz MSUControl` to stop MSU hardware** — this clears `AudioPlaying`, unblocking any `$FA` event wait on the now-silent looping track.
- **Flag = 2** (fade down): subtract `FadeStep`. If result ≤ `FadeTargetVolume`, snap to target and clear flag.
- **Flag = 3** (fade up): add `FadeStep`. If result ≥ `FadeTargetVolume` or overflow, snap to target and clear flag.

Each step writes both `MSUVolume` (hardware register `$2006`) and `MSUCurrentVolume` (`$1E32`).

### Where patch fading diverges from vanilla

**Speed**: the SPC calculates a precise step rate from the duration parameter. The patch now derives `FadeTickInterval` from the same duration value, matching vanilla speed within ~2% for long fades. Short fades (duration < `$20`) still run at the legacy every-frame speed, which is faster than vanilla but short enough to be imperceptible.

**Fade-up seeding**: when `FadeInPending` is set (EventCmd_f3 scenario), `PlayMSU` seeds `MSUCurrentVolume` at `FadeInStartVolume` and sets `FadeFlag = 3` with a default interval of 4 frames (~533 ms). The track loads and begins audible immediately rather than starting silent.

**Vanilla fades but we don't (harmless)**: if `$81` arrives while `MSUCurrentTrack = 0` and `PlayVolume = 0`, the patch does nothing — correctly, since there is no MSU audio to fade.

**We fade but vanilla wouldn't**: no such case exists currently. `FadeFlag` is only set by `FadeCommandHandle` (actual `$81` commands) or by `PlayMSU` (deferred `FadeInPending` at track start).

## Title metadata overlay system

This is a **maintainer/tester diagnostic tool**, not a gameplay feature. It stamps a small OSD onto the title screen showing the patch build date and compile-time option flags (T/P/C), so anyone testing the ROM can immediately confirm which build they are running without checking file hashes.

Code lives in `TITLEOVERLAY` section at bank `C4:BA00`.

## `TitleMetadataOverlay`
- Checks signature in WRAM title state area (`$7E5280`) to ensure this is title context.
- Accepts either original title bytes or FMV-hooked form.
- Runs one-time initialization (`DMOverlayInit`) per title load.
- Self-seals by clearing `$7E5000` gate so gameplay NMIs cannot hit overlay logic later.

## `TitleMetadataPrepareSprites`
Tasks:
1. Mirror metadata bytes (`C4:B000` -> `DMMetaMirror`).
2. Write extra sprite entries to title sprite table in WRAM (`$7A98+`).
3. Build text: "DM" + YYMMDD + optional flags (T/P/C from metadata bits).
4. Compute final sprite count (`$7A97`).
5. Upload custom glyph tiles to OBJ VRAM (table 1 region).

Hardware-sensitive details in code comments:
- Keeps `VMAIN = $80` as expected engine state.
- Uses `sta.l $00xxxx` for PPU register writes to avoid DBR-dependent miswrites.
- Relies on ClearVRAM behavior for transparent sub-tiles.

## FMV system walkthrough

FMV code is in bank `C4:A4C0`, section `FMVCODE`.

### Background: what DBR is
The 65816 has a register called the **Data Bank Register (DBR)**. When code uses a 16-bit ("absolute") address like `sta $5280`, the CPU combines it with DBR to form a 24-bit address: if DBR = `$7E`, then `sta $5280` writes to `$7E:5280` (WRAM). If DBR = `$00`, the same instruction writes to `$00:5280` (I/O register space). DBR determines which 64 KB bank "bare" addresses resolve into. Code that needs to access a specific bank either sets DBR explicitly (push a byte, `plb`) or uses 24-bit "absolute long" addressing (`sta.l $7E5280`) to bypass DBR entirely.

### Why `.ACCU 8` / `.INDEX 8` appears here
The file explicitly sets width defaults at FMV hook entry region to avoid assembler-width ambiguity in hook code. This is a defensive measure for WLA-DX width-state leakage across sections/hook boundaries.

## 1) `TitleScreenHook`
Called from patched `C2/680F` path. This is the entry point that lets the FMV system intercept the title screen before the normal title code runs.

What it does, step by step:
- Sets DBR to `$7E` so that subsequent 16-bit addresses resolve into WRAM (where the decompressed title-screen code lives).
- Reads 5 bytes at `TitleState01Patch` (`$7E5280`) and checks whether they match the expected vanilla title-state code. If they don't match, this isn't actually a title-screen context (the hook address can also fire from non-title flows), so it skips everything.
- Mirrors the patch metadata block to WRAM for the title overlay diagnostic.
- Resets FMV state flags to prepare for a fresh playback attempt.
- Overwrites the 5 bytes at `$7E5280` with `JSL FMV_TitleState01Hook` + `RTS`. This means the next time the title state machine reaches that point, it will call the FMV code instead of the normal title logic.
- Jumps to `TitleScreenExt2`, which continues the normal title initialization that was already in progress when this hook fired. The FMV doesn't play yet — it plays later, when the rewritten `$7E5280` code is reached by the title state machine.

## 2) `FMV_TitleState01Hook`
This is the replacement routine injected into title state code.

Behavior by state:
- First visit (`FMVState==0`): mark active, run `FMV_RunPlayback`.
- On success/failure/skip conditions: restore original title bytes via `FMV_RestoreTitleState01`.
- Adjust title state vars (`$19`, `$15`, `$06`) to control whether title reinit/skip happens.

`FMVDebugMarker` is updated along the way to help trace execution stage.

## 3) `FMV_RunBootstrap` / `FMV_ReadHeader` / `FMV_CheckMSU`
These support routines do hardware/file sanity checks:
- Verify MSU-1 ID string (`S-MSU1`).
- Seek data stream to 0.
- Read 16-byte FMV header from MSU data stream.
- Validate magic `FFVI` and read frame count.

Carry flag convention:
- Set carry on success, clear on failure.

### Why MSU-1 presence is checked again here
`FMV_CheckMSU` duplicates the `S-MSU1` string check that `MSUCheck` (in the music code) already performs. This is intentional: the FMV subsystem is designed to be self-contained, because it can run before any music command has executed. The music path sets `MSUExists` the first time a song is requested, but the title screen FMV hook fires during title initialization — potentially before the game has played any music at all. Rather than depend on the music subsystem's initialization order, the FMV code verifies MSU-1 hardware directly. (It does check the `MSUExists` flag first as a fast path, and sets it if the hardware check succeeds, so subsequent music commands benefit.)

## 4) `FMV_StartAudio` and `FMV_StopAudio`
Before FMV audio starts:
- Save current `PlayCommand/Track/Volume` into `FMVSaved*`.
- Request fixed FMV track (`$68`) via `MSUMain`.
- Force no-loop playback.

After FMV ends/aborts:
- Stop MSU registers and clear fade state.
- Restore saved FF6 play command/track/volume.

## 5) `FMV_RunPlayback` main loop
Sequence:
1. Validate MSU + header.
2. Initialize video state (`FMV_InitVideo`).
3. Enable NMI (`$4200 = $81`) and reset counters.
4. Start FMV audio.
5. Loop over subframes 0..3 repeatedly.
6. After each full frame:
   - increment `FMVFrameCurrent`.
   - compare to `FMVFrameCount`.
   - poll controller edge transitions once/frame.
   - allow skip on new B press (`$0080`).
7. Stop video/audio and return carry set (natural end) or clear (interrupt/fail).

## 6) `FMV_WaitVBlank` handoff model
This function waits on `FMVNMIReady` counter.

NMI side increments counter while FMV active.
Playback side decrements when consuming a vblank.

This avoids lost wakeups that can happen with simple binary flags when producer/consumer overlap.

## 7) `FMV_InitVideo` / `FMV_StopVideo`
`FMV_InitVideo`:
- Blanks display.
- Configures BG1 mode and base addresses.
- Builds tilemap for 32x18 video area and letterbox blank rows.
- Clears a dedicated blank tile in both tile buffers.
- Sets scroll/layer registers.
- Re-enables display.

`FMV_StopVideo` restores a minimal safe non-FMV display state.

## 8) Subframe DMA strategy (`FMV_DoSubFrame0..3`)
Each video frame is split into 4 vblank transfers:
- Subframe 0: read palette from MSU into WRAM, then DMA tile chunk 0.
- Subframe 1: DMA tile chunk 1.
- Subframe 2: DMA tile chunk 2.
- Subframe 3: DMA palette WRAM->CGRAM and tile chunk 3, then flip active buffer base.

Double-buffering:
- Tile data alternates between `TILEDATA_A` and `TILEDATA_B`.
- BG1 tile-data base (`BG12NBA`) flips each completed frame.

This keeps display coherent while streaming from MSU.

## Patch metadata block
At `C4:B000` (`PATCHMETADATA`):
- 4-byte magic "DMVS".
- Build date YYMMDD from `build_date.inc`.
- Installer option flags byte.
- Metadata version + reserved bytes.

This block is mirrored to WRAM for the title overlay diagnostic tool (see "Title metadata overlay system" above).

## Event cutscene fix blobs (Shadow's dream sequences)

The end of the file contains raw `.DB` byte blobs that are **not** 65816 CPU instructions — they are FF6 event script bytecode, interpreted by the game's event command engine. These fix a specific bug (GitHub issue #73) related to MSU-1 timing mismatches during Shadow's dream sequences.

### What problem these fix

When the player sleeps at an inn with Shadow in the party, FF6 triggers one of Shadow's dream cutscenes. The vanilla game's sleep/wake cycle has a strict contract: no music other than the "nighty night" jingle should be playing between sleep and wake-up, because the engine uses the current-song state to know what to resume afterward.

With the MSU-1 patch, this contract can break. MSU tracks may not stop or transition at the same moments SPC tracks would, so the town music from the inn can persist into the dream sequence instead of silencing. The result: wrong music playing during dreams, and potentially corrupted song-resume state on wake-up.

These fixes (originally guided by madsiur and implemented around 2018, PR #81) are a last resort. Editing event scripts risks compatibility with other FF6 patches, so it's only done when no cleaner interception point exists. The approach: inject `call` opcodes at the four dream-sequence entry points in the event script, redirecting to short helper routines that explicitly silence music and set up the correct visual state.

### How the encoding works

Event command `$B2` is `call` — it takes a 24-bit pointer as an offset from the event script base address (`CA:0000`). So `B2 EA FF 08` calls offset `$08FFEA`, which is absolute address `D2:FFEA`. All four call sites use this pattern.

Command `$FD` is a no-op/dummy — used as inert padding when the replacement is shorter than the original bytes it overwrites.

### The four patched call sites (bank 10, event script space)

| Label | ROM address | Calls | Dream sequence |
|-------|------------|-------|----------------|
| `CUTSCENEFIX` | `CA:CD6F` | `D2:FFEA` | Shadow dream 1 |
| `CUTSCENEFIX2` | `CA:CDE7` | `D2:FFD0` | Shadow dream 2 (padded with `$FD` fillers) |
| `CUTSCENEFIX3` | `CA:CE5D` | `D2:FFF8` | Shadow dream 3 |
| `CUTSCENEFIX4` | `CA:CF0A` | `D2:FFE3` | Shadow dream 4 |

### The helper routines (bank 18, near end of ROM)

Every helper starts with `F0 00` (`play_song $00` — request silence), satisfying the sleep contract. Each then applies visual effects appropriate to that dream's transition:

**Dream 1** (`D2:FFEA`): silence music, then `create_obj $10` + `show_obj $10` — spawns a character object needed by the dream scene setup.

**Dream 2** (`D2:FFD0`): silence music, then loop 31 times over three `mod_bg_pal` commands. Each command uses control byte `$DF`, which means "increment colors back toward original palette" (function BGColorUnDec) across all RGB channels at maximum intensity. This gradually restores three specific BG color entries (`$37`, `$05`, `$29`) from a modified state — likely undoing a screen-darkening effect from the preceding inn sequence so the dream starts with correct colors.

**Dream 3** (`D2:FFF8`): silence music, then `mod_bg_pal $BC` + `mod_sprite_pal $BC`. Control byte `$BC` means "subtract fixed color" (function ColorDecFlash) across all RGB channels — this darkens both BG colors 4–119 and all sprite colors, creating the visual dimming effect for the dream transition.

**Dream 4** (`D2:FFE3`): silence music, then `filter_pal $07, $04, $FF` — converts nearly the entire active palette (colors 4–255) to grayscale. This produces the washed-out look appropriate for this particular dream.

### Why raw bytes instead of event macros

These were space-constrained hotfix insertions — the replacement must be exactly the same size as the original event bytes at each address. Using raw `.DB` gives strict byte-for-byte control. The `$FD` no-op padding in `CUTSCENEFIX2` fills the gap when the replacement `call` instruction is shorter than the original sequence it overwrites.

### Known tradeoffs

- There may be 1–2 frames of wrong music audible during scene load, before the event script runs — unavoidable since music loads before event scripts execute.
- After waking from dreams, inns may have a brief silence before music resumes — a side effect of explicitly silencing music to protect the sleep contract.

### Byte-level decode reference

For the full opcode-by-opcode breakdown of each helper routine's bytes (including palette command bitfield semantics), see the `mmmrgbii` bitfield format documented in `external/ff6/src/field/event.asm` (`InitColorMod`) and the detailed decode in git history of this document.

## Cross-reference summary to vanilla disassembly
Primary comparisons used:
- `external/ff6/notes/ff3u.asm`
  - `C0/FF10` NMI vector (`JML $001500`).
  - `C5/0148` SPC command dispatch entry.
  - `C5/0182` Play Song entry.
  - `C0/B8C7` event command `$FA` wait-for-song-end.
  - `C2/680F` title jump to decompressed WRAM code (`$7E5000`).

These are the exact hook/rejoin points this patch intercepts.

## Practical modification checklist
When editing this file, verify all of these:

1. Hook width safety:
- In hook-target code paths, force immediate operand sizes (`.b`/`.w`) where needed.

2. Register width at runtime:
- Any routine called from mixed contexts should set its own `rep/sep` expectations on entry.

3. DBR safety for hardware I/O:
- If DBR might vary by caller, write PPU/APU/MSU registers with absolute-long form.

4. NMI/FMV isolation:
- Keep FMV-state gate in NMI so FMV counter semantics do not affect normal gameplay fades.

5. SPC compatibility:
- If MSU suppresses SPC behavior, preserve FF6 logic assumptions that scripts depend on (position/ending waits, current-track comparisons).

6. Save/load behavior:
- Avoid storing patch-only transient state in ranges copied to SRAM unless persistence is intended.

## Quick mental model
If you need a one-line mental model of this file:

"Intercept FF6 song and title flow, route music/video through MSU and PPU DMA when available, but preserve enough SPC-facing behavior that vanilla event and state logic still works."
