#!/usr/bin/env python3
"""
conversion.py — Convert extracted PSX OPEN.STR to SNES MSU-1 video + audio data.

Part of the Dancing Mad FF6 project: PSX intro video implementation.
Takes the raw-sector .STR file produced by extraction.py and converts it into
two files consumable by the SNES MSU-1 hardware:

    .msu  — Video frame data (sequential frames of palette + 4bpp tile data).
             Read by the SNES via the MSU-1 data port ($2004).
    .pcm  — Audio data in MSU-1 format (44100 Hz 16-bit signed LE stereo).
             Played by the SNES via the MSU-1 audio port.

System dependencies:
    Python 3.6+
    numpy               — pip install numpy
    ffmpeg 4.0+         — Must include 'psxstr' demuxer and 'mdec' decoder.
                          Standard builds include both.

SNES video format overview:
    The SNES PPU in Mode 1 uses 4bpp tiles (16 colors per tile) on BG1.
    Each tile references one of 8 sub-palettes via its tilemap entry.
    We divide the 256x144 display into 8 fixed spatial regions (4 columns x
    2 rows), each assigned a dedicated sub-palette of 16 colors, giving us
    128 unique colors per frame. The tilemap is set once at initialization
    and never updated during playback — only palette and tile data change.

    Aspect ratio handling:
        The PSX source is 320x240 with 40px letterbox bars top and bottom.
        The actual content is 320x160 (2:1 widescreen). We crop the bars,
        then scale to 256x144 — which, with the SNES 8:7 pixel aspect
        ratio, displays as approximately 2.03:1 (1.6% error, imperceptible).
        The SNES screen is 256x224; the 144-line image is centered with
        40 lines of black above and below (single letterbox, not double).

    Per-frame data (DMA'd to SNES during VBlank across 4 SNES frames):
        Palette:   256 bytes  (8 sub-palettes x 16 colors x 2 bytes BGR555)
        Tile data: 18,432 bytes  (576 tiles x 32 bytes each, 4bpp)
        Total:     18,688 bytes per video frame

    At 15 fps video into 60 fps SNES, each video frame spans 4 SNES frames.
    VBlank DMA budget: ~5,700 bytes/VBlank x 4 = ~22,800 bytes. Comfortable fit.

Region layout (fixed sub-palette assignment):
    The 256x176 pixel display is 32 tiles wide x 22 tiles tall = 704 tiles.
    These are divided into 8 rectangular regions for sub-palette assignment:

        Region 0: cols  0-7,  rows  0-8   (top-left,      palette 0)
        Region 1: cols  8-15, rows  0-8   (top-center-L,  palette 1)
        Region 2: cols 16-23, rows  0-8   (top-center-R,  palette 2)
        Region 3: cols 24-31, rows  0-8   (top-right,     palette 3)
        Region 4: cols  0-7,  rows  9-17  (bottom-left,   palette 4)
        Region 5: cols  8-15, rows  9-17  (bottom-center-L, palette 5)
        Region 6: cols 16-23, rows  9-17  (bottom-center-R, palette 6)
        Region 7: cols 24-31, rows  9-17  (bottom-right,  palette 7)

    Each region: 64x72 pixels = 8x9 tiles = 72 tiles.
    Palette assignment is baked into the tilemap at init time — the converter
    only needs to store palette + tile data per frame.

Usage:
    python3 conversion.py <input.str> [-o output_base]

    Outputs:
        output_base.msu   — video frame data
        output_base.pcm   — audio data (MSU-1 format)

    If -o is omitted, output_base defaults to the input filename without extension.
"""

import argparse
import os
import struct
import subprocess
import sys
import time
from pathlib import Path

import numpy as np

# =============================================================================
# Constants
# =============================================================================

# Source video crop parameters.
# The PSX FMV is 320x240 but the actual content is letterboxed within that
# frame: 40 pixels of black at top and bottom, with 320x160 of real content.
# The content aspect ratio is 320:160 = 2:1 (widescreen cinematic).
SOURCE_CROP_TOP    = 40
SOURCE_CROP_BOTTOM = 40
SOURCE_CONTENT_H   = 160    # 240 - 40 - 40

# SNES pixel aspect ratio (PAR).
# On a real CRT (or a properly configured emulator like bsnes, or an FXPak
# Pro on a 4:3 TV), the SNES 256-wide output is stretched horizontally to
# fill the 4:3 display.  Each pixel appears 8/7 as wide as it is tall:
#   PAR = (4/3) / (256/224) = 8/7 ≈ 1.143
# We must account for this stretch when choosing our frame height, so that
# the source video's aspect ratio is preserved on the *actual display*,
# not in raw pixel coordinates.
SNES_PAR = 8 / 7

# Display dimensions.
# To preserve the source 2:1 aspect ratio on a 4:3-corrected display:
#   Displayed width  = 256 * (8/7) = 292.57 square-pixel-equivalents
#   Correct height   = 292.57 / 2  = 146.3 pixels
#   Nearest tile-aligned height = 144 (18 tiles) → DAR = 2.032:1 (1.6% error)
# This is imperceptible and keeps regions evenly divisible (9 tiles per row).
#
# NOTE: If we did NOT account for PAR (targeting old uncorrected emulators
# that treat pixels as square), we'd need height = 128 (16 tiles) for a
# 256:128 = 2:1 raw pixel ratio.  But on a real CRT that would display as
# 292.57:128 = 2.29:1 — noticeably too wide.  We target real hardware.
SCREEN_WIDTH  = 256
SCREEN_HEIGHT = 144

# SNES tile metrics
TILE_SIZE = 8                                       # 8x8 pixel tiles
TILE_COLS = SCREEN_WIDTH  // TILE_SIZE              # 32 tile columns
TILE_ROWS = SCREEN_HEIGHT // TILE_SIZE              # 18 tile rows
TOTAL_TILES = TILE_COLS * TILE_ROWS                 # 576 tiles per frame

# Sub-palette configuration
NUM_SUBPALETTES    = 8                              # 8 fixed spatial regions
COLORS_PER_PALETTE = 16                             # 4bpp = 16 colors per sub-palette
TOTAL_COLORS       = NUM_SUBPALETTES * COLORS_PER_PALETTE  # 128 colors max

# Data sizes per frame
BYTES_PER_TILE = 32                                 # 4bpp SNES tile = 32 bytes
PALETTE_BYTES  = TOTAL_COLORS * 2                   # 128 colors x 2 bytes BGR555 = 256
TILE_DATA_BYTES = TOTAL_TILES * BYTES_PER_TILE      # 576 x 32 = 18,432
FRAME_BYTES    = PALETTE_BYTES + TILE_DATA_BYTES    # 18,688 bytes per video frame

# Video timing
VIDEO_FPS = 15                                      # PSX source is 15 fps

# Frame pixel size for raw RGB24 pipe
FRAME_SIZE_RGB24 = SCREEN_WIDTH * SCREEN_HEIGHT * 3  # 256 x 144 x 3 = 110,592

# MSU-1 .msu header
MSU_HEADER_SIZE = 16

# MSU-1 .pcm header
PCM_HEADER_SIZE = 8
PCM_SAMPLE_RATE = 44100

# Region layout: 4 columns x 2 rows = 8 regions
REGION_COLS = 4     # 4 region columns (each 8 tiles = 64 pixels wide)
REGION_ROWS = 2     # 2 region rows (each 9 tiles = 72 pixels tall)
REGION_TILE_W = TILE_COLS // REGION_COLS    # 8 tiles per region column
REGION_TILE_H = TILE_ROWS // REGION_ROWS   # 9 tiles per region row
# Darkness threshold for black reservation. Pixels where all channels are
# below this value are treated as "black" — they map to palette index 0
# (forced black) and are excluded from median-cut quantization. This prevents
# letterbox bars and dark scene edges from wasting palette slots or getting
# dithered into near-black noise. Value 24 catches PSX compression artifacts
# that make "black" pixels slightly non-zero (typically R,G,B < 10).
BLACK_THRESHOLD = 24
# Bayer 4x4 ordered dithering matrix, normalized to [-0.5, +0.4375]
# This pattern produces a characteristic crosshatch that looks natural on
# low-color-depth displays. The matrix tiles seamlessly across the frame.
BAYER_4x4 = np.array([
    [ 0,  8,  2, 10],
    [12,  4, 14,  6],
    [ 3, 11,  1,  9],
    [15,  7, 13,  5],
], dtype=np.float32) / 16.0 - 0.5


# =============================================================================
# Color quantization — Median Cut
# =============================================================================

def median_cut(pixels, num_colors):
    """Quantize an array of RGB pixels down to num_colors representative colors.

    Uses the median-cut algorithm:
      1. Start with all pixels in one "box" (the full RGB color cube).
      2. Find the box with the greatest range along any single color channel.
      3. Split that box at the median of that channel, creating two smaller boxes.
      4. Repeat until we have num_colors boxes.
      5. Each box's centroid (mean color) becomes one palette entry.

    Index 0 is always reserved as pure black (0,0,0). Near-black pixels
    (all channels < BLACK_THRESHOLD) are filtered out before quantization,
    and the remaining pixels are quantized to num_colors-1 colors placed
    at indices 1..num_colors-1. This ensures letterbox bars and dark
    scene regions render as true black without dithering artifacts.

    Args:
        pixels:     ndarray of shape (N, 3), dtype uint8 — RGB pixel values.
        num_colors: int — target palette size (e.g. 16).

    Returns:
        ndarray of shape (num_colors, 3), dtype uint8 — the palette.
        Index 0 is always (0, 0, 0).
    """
    if len(pixels) == 0:
        return np.zeros((num_colors, 3), dtype=np.uint8)

    # Filter out near-black pixels — they'll use the reserved index 0.
    flat = pixels.reshape(-1, 3)
    non_black_mask = flat.max(axis=1) >= BLACK_THRESHOLD
    non_black = flat[non_black_mask]

    # Reserve index 0 for black; quantize remaining to num_colors-1.
    usable_colors = num_colors - 1

    # Build the palette with black at index 0.
    palette = np.zeros((num_colors, 3), dtype=np.uint8)

    if len(non_black) == 0:
        # Entire region is black — palette is all zeros, which is fine.
        return palette

    # Deduplicate to speed up range calculations on large pixel arrays.
    # For a 64x88 region (~5632 pixels), unique colors are typically < 2000.
    unique_pixels = np.unique(non_black, axis=0)
    if len(unique_pixels) <= usable_colors:
        # Fewer unique colors than requested — place them starting at index 1.
        palette[1:1+len(unique_pixels)] = unique_pixels
        return palette

    # Each "box" is just a subset of the unique pixel array.
    boxes = [unique_pixels.astype(np.float64)]

    while len(boxes) < usable_colors:
        # Find the box with the largest range in any channel.
        best_idx = -1
        best_range = -1
        best_channel = -1

        for i, box in enumerate(boxes):
            if len(box) < 2:
                continue
            # Channel ranges: max - min for R, G, B
            ranges = box.max(axis=0) - box.min(axis=0)
            ch = int(ranges.argmax())
            r = ranges[ch]
            if r > best_range:
                best_range = r
                best_idx = i
                best_channel = ch

        if best_idx == -1:
            break  # All boxes have 1 pixel or identical pixels.

        # Split the chosen box at the median of the chosen channel.
        box = boxes.pop(best_idx)
        median_val = np.median(box[:, best_channel])
        left_mask = box[:, best_channel] <= median_val
        right_mask = ~left_mask

        left = box[left_mask]
        right = box[right_mask]

        # Guard against empty splits (all values equal to median).
        if len(left) == 0:
            left = box[:1]
        if len(right) == 0:
            right = box[-1:]

        boxes.append(left)
        boxes.append(right)

    # Compute each box's centroid as the palette color.
    # Index 0 is already black; place quantized colors at indices 1+.
    for i in range(min(len(boxes), usable_colors)):
        palette[1 + i] = np.clip(boxes[i].mean(axis=0), 0, 255).astype(np.uint8)

    return palette


# =============================================================================
# SNES BGR555 color encoding
# =============================================================================

def rgb_to_bgr555(r, g, b):
    """Convert 8-bit RGB to SNES 15-bit BGR555.

    SNES color format (16-bit word, little-endian):
        Bit 15:    always 0
        Bits 14-10: blue  (5 bits, 0-31)
        Bits 9-5:   green (5 bits, 0-31)
        Bits 4-0:   red   (5 bits, 0-31)

    The conversion truncates the lower 3 bits of each channel:
        5-bit value = 8-bit value >> 3
    """
    return ((int(b) >> 3) << 10) | ((int(g) >> 3) << 5) | (int(r) >> 3)


def encode_palette(palettes):
    """Encode 8 sub-palettes as 256 bytes of BGR555 data.

    Args:
        palettes: list of 8 ndarrays, each shape (16, 3), dtype uint8.

    Returns:
        bytes — 256 bytes (8 x 16 x 2).
    """
    data = bytearray(PALETTE_BYTES)
    offset = 0
    for pal in palettes:
        for i in range(COLORS_PER_PALETTE):
            r, g, b = int(pal[i, 0]), int(pal[i, 1]), int(pal[i, 2])
            bgr555 = rgb_to_bgr555(r, g, b)
            struct.pack_into('<H', data, offset, bgr555)
            offset += 2
    return bytes(data)


# =============================================================================
# Ordered dithering + palette mapping
# =============================================================================

def dither_and_index_tile(tile_rgb, palette, tile_col, tile_row, dither_strength):
    """Apply Bayer ordered dithering and map each pixel to the nearest palette color.

    Ordered dithering works by adding a position-dependent bias to each pixel's
    color before finding the nearest palette match. The Bayer matrix provides a
    regular pattern of thresholds that, when applied across the image, create the
    illusion of intermediate colors through spatial mixing.

    The dither pattern tiles seamlessly across the full frame because we use
    global pixel coordinates (not tile-local) for the Bayer matrix lookup.

    Args:
        tile_rgb:        ndarray (8, 8, 3) uint8 — the tile's RGB pixels.
        palette:         ndarray (16, 3) uint8 — the sub-palette for this tile.
        tile_col:        int — tile's column position (0-31) for global Bayer alignment.
        tile_row:        int — tile's row position (0-21) for global Bayer alignment.
        dither_strength: float — dither intensity in RGB levels (e.g. 24-32).

    Returns:
        ndarray (8, 8) uint8 — palette indices (0-15) for each pixel.
    """
    # Build the 8x8 Bayer threshold matrix for this tile's global position.
    # The 4x4 Bayer pattern is tiled to cover the 8x8 tile.
    gy = np.arange(8) + tile_row * 8   # global Y coordinates
    gx = np.arange(8) + tile_col * 8   # global X coordinates
    bayer = BAYER_4x4[gy[:, None] % 4, gx[None, :] % 4]  # shape (8, 8)

    # Identify near-black pixels — these map directly to index 0 (reserved
    # black) without dithering, preventing noise in letterbox bars.
    is_black = tile_rgb.max(axis=2) < BLACK_THRESHOLD   # shape (8, 8)

    # Add dither noise: each pixel gets a bias of bayer_value * strength.
    # This shifts the color slightly before nearest-neighbor matching,
    # creating the ordered dithering effect.
    dithered = tile_rgb.astype(np.float32) + bayer[:, :, None] * dither_strength
    dithered = np.clip(dithered, 0.0, 255.0)

    # Find the nearest palette color for each pixel.
    # Broadcasting: dithered is (8, 8, 1, 3), palette is (1, 1, 16, 3).
    # Squared Euclidean distance in RGB space.
    diff = dithered[:, :, None, :] - palette[None, None, :, :].astype(np.float32)
    dist_sq = (diff * diff).sum(axis=3)     # shape (8, 8, 16)
    indices = dist_sq.argmin(axis=2)         # shape (8, 8)

    # Force near-black pixels to index 0 (pure black).
    indices[is_black] = 0

    return indices.astype(np.uint8)


# =============================================================================
# SNES 4bpp tile encoding
# =============================================================================

def encode_4bpp_tile(indices):
    """Encode an 8x8 tile of palette indices as a 32-byte SNES 4bpp tile.

    SNES 4bpp tile byte layout (32 bytes total):

        Bytes 0-15:  Bitplanes 0 and 1, interleaved by row.
            Byte 0:  row 0, bitplane 0  (bit 7 = leftmost pixel)
            Byte 1:  row 0, bitplane 1
            Byte 2:  row 1, bitplane 0
            Byte 3:  row 1, bitplane 1
            ...
            Byte 14: row 7, bitplane 0
            Byte 15: row 7, bitplane 1

        Bytes 16-31: Bitplanes 2 and 3, interleaved by row.
            Byte 16: row 0, bitplane 2
            Byte 17: row 0, bitplane 3
            Byte 18: row 1, bitplane 2
            Byte 19: row 1, bitplane 3
            ...
            Byte 30: row 7, bitplane 2
            Byte 31: row 7, bitplane 3

    Each pixel's 4-bit palette index is split across the four bitplanes:
        Bitplane 0 = bit 0 of the index (least significant)
        Bitplane 1 = bit 1
        Bitplane 2 = bit 2
        Bitplane 3 = bit 3 (most significant)

    Within each bitplane byte, bit 7 is the leftmost pixel and bit 0 is the
    rightmost — standard SNES convention.

    Args:
        indices: ndarray (8, 8) uint8 — palette indices 0-15.

    Returns:
        bytes — 32-byte SNES 4bpp tile.
    """
    data = bytearray(32)

    for row in range(8):
        bp0 = 0
        bp1 = 0
        bp2 = 0
        bp3 = 0

        for col in range(8):
            idx = int(indices[row, col])
            bit = 7 - col   # MSB = leftmost pixel

            bp0 |= ((idx >> 0) & 1) << bit
            bp1 |= ((idx >> 1) & 1) << bit
            bp2 |= ((idx >> 2) & 1) << bit
            bp3 |= ((idx >> 3) & 1) << bit

        # Bitplanes 0-1 block (bytes 0-15)
        data[row * 2]     = bp0
        data[row * 2 + 1] = bp1
        # Bitplanes 2-3 block (bytes 16-31)
        data[16 + row * 2]     = bp2
        data[16 + row * 2 + 1] = bp3

    return bytes(data)


# =============================================================================
# Region / tile helpers
# =============================================================================

def get_region_index(tile_col, tile_row):
    """Get the sub-palette region index (0-7) for a tile at (tile_col, tile_row).

    Region layout: 4 columns x 2 rows.
      Region column = tile_col // 8   (0-3)
      Region row    = tile_row // 9   (0-1)
      Region index  = region_row * 4 + region_col  (0-7)
    """
    rcol = min(tile_col // REGION_TILE_W, REGION_COLS - 1)
    rrow = min(tile_row // REGION_TILE_H, REGION_ROWS - 1)
    return rrow * REGION_COLS + rcol


def extract_region_pixels(frame_rgb, region_idx):
    """Extract all pixels belonging to a spatial region.

    Args:
        frame_rgb:  ndarray (144, 256, 3) uint8 — full frame.
        region_idx: int 0-7 — which region.

    Returns:
        ndarray (N, 3) uint8 — flattened pixel array for the region.
    """
    rcol = region_idx % REGION_COLS
    rrow = region_idx // REGION_COLS

    x0 = rcol * REGION_TILE_W * TILE_SIZE
    y0 = rrow * REGION_TILE_H * TILE_SIZE
    x1 = x0 + REGION_TILE_W * TILE_SIZE
    y1 = y0 + REGION_TILE_H * TILE_SIZE

    region = frame_rgb[y0:y1, x0:x1]  # shape (72, 64, 3)
    return region.reshape(-1, 3)


# =============================================================================
# Frame processing pipeline
# =============================================================================

def process_frame(frame_rgb, dither_strength=28):
    """Convert one 256x144 RGB frame to SNES palette + tile data.

    Pipeline:
      1. For each of the 8 spatial regions, extract pixel data.
      2. Quantize each region to 16 colors using median cut.
      3. For each 8x8 tile, apply ordered dithering against its region's palette.
      4. Encode each tile as a 32-byte SNES 4bpp tile.
      5. Assemble the 256-byte palette block (all 8 sub-palettes concatenated).

    Args:
        frame_rgb:       ndarray (144, 256, 3) uint8.
        dither_strength: float — Bayer dither intensity (default 28).

    Returns:
        tuple (palette_bytes, tile_data_bytes):
            palette_bytes:   bytes, length 256
            tile_data_bytes: bytes, length 18,432
    """
    # --- Step 1 & 2: Quantize each region to 16 colors ---
    palettes = []
    for region_idx in range(NUM_SUBPALETTES):
        region_pixels = extract_region_pixels(frame_rgb, region_idx)
        pal = median_cut(region_pixels, COLORS_PER_PALETTE)
        palettes.append(pal)

    # --- Step 3 & 4: Dither + encode each tile ---
    tile_data = bytearray()

    # Tiles are stored in row-major order (left to right, top to bottom),
    # matching the sequential tile numbering in the SNES VRAM layout.
    for tile_row in range(TILE_ROWS):
        for tile_col in range(TILE_COLS):
            # Determine which region (sub-palette) this tile belongs to.
            region_idx = get_region_index(tile_col, tile_row)
            pal = palettes[region_idx]

            # Extract the 8x8 pixel block from the frame.
            y0 = tile_row * TILE_SIZE
            x0 = tile_col * TILE_SIZE
            tile_pixels = frame_rgb[y0:y0+TILE_SIZE, x0:x0+TILE_SIZE]

            # Apply ordered dithering and map to palette indices.
            indices = dither_and_index_tile(tile_pixels, pal, tile_col, tile_row,
                                            dither_strength)

            # Encode as SNES 4bpp tile format.
            tile_data.extend(encode_4bpp_tile(indices))

    # --- Step 5: Encode the palette block ---
    palette_bytes = encode_palette(palettes)

    return palette_bytes, bytes(tile_data)


# =============================================================================
# ffmpeg subprocess helpers
# =============================================================================

def find_ffmpeg():
    """Locate the ffmpeg binary, preferring PATH."""
    import shutil
    path = shutil.which('ffmpeg')
    if path is None:
        print("ERROR: ffmpeg not found. Install ffmpeg 4.0+ and ensure it's in PATH.",
              file=sys.stderr)
        sys.exit(1)
    return path


def count_video_frames(ffmpeg_path, input_path):
    """Count video frames in the .STR file using ffprobe.

    Falls back to decoding and counting if ffprobe isn't available.
    """
    ffprobe_path = ffmpeg_path.replace('ffmpeg', 'ffprobe')

    try:
        result = subprocess.run(
            [ffprobe_path, '-v', 'error',
             '-select_streams', 'v:0',
             '-count_frames',
             '-show_entries', 'stream=nb_read_frames',
             '-of', 'csv=p=0',
             '-f', 'psxstr', str(input_path)],
            capture_output=True, text=True, timeout=120
        )
        if result.returncode == 0 and result.stdout.strip().isdigit():
            return int(result.stdout.strip())
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

    # Fallback: decode video and count frames (slower but reliable).
    print("  ffprobe not available, counting frames by decoding (may take a moment)...")
    result = subprocess.run(
        [ffmpeg_path, '-f', 'psxstr', '-i', str(input_path),
         '-vf', 'scale=1:1',       # Tiny output to minimize work
         '-f', 'rawvideo', '-pix_fmt', 'gray',
         '-v', 'error', '-'],
        capture_output=True, timeout=300
    )
    return len(result.stdout)  # 1 byte per pixel, 1x1 frame = 1 byte per frame


def open_video_pipe(ffmpeg_path, input_path):
    """Open an ffmpeg subprocess that pipes decoded, scaled RGB24 frames to stdout.

    ffmpeg pipeline:
        Input:   PSX STR container (psxstr demuxer → MDEC decoder)
        Filter:  Crop source letterbox bars (320x240 → 320x160 content),
                 then Lanczos scale to 256x144 for SNES display.
        Output:  Raw RGB24 frames piped to stdout.

    The source FMV is 320x240 with 40px black bars at top and bottom
    (widescreen 2:1 content letterboxed in a 4:3 frame). We crop these
    before scaling to avoid double-letterboxing on the SNES, which adds
    its own bars to display the 144-line image in a 224-line screen.

    Returns:
        subprocess.Popen object. Read FRAME_SIZE_RGB24 bytes at a time from stdout.
    """
    # Crop to content area, then scale to SNES target resolution.
    # crop=w:h:x:y — keep 320x160 starting at (0,40).
    vf = (f'crop=320:{SOURCE_CONTENT_H}:0:{SOURCE_CROP_TOP},'
          f'scale={SCREEN_WIDTH}:{SCREEN_HEIGHT}:flags=lanczos')
    cmd = [
        ffmpeg_path,
        '-f', 'psxstr',                         # PSX STR demuxer
        '-i', str(input_path),                   # Input .STR file
        '-vf', vf,
        '-pix_fmt', 'rgb24',                     # 3 bytes per pixel, R G B
        '-f', 'rawvideo',                        # Raw frame output (no container)
        '-v', 'error',                           # Suppress ffmpeg banner/info
        'pipe:1'                                 # Write to stdout
    ]
    return subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


# =============================================================================
# MSU-1 .msu file output
# =============================================================================

def write_msu_header(f, frame_count):
    """Write the 16-byte .msu video data header.

    Header layout:
        Offset  Size  Field
        0x00    4     Magic bytes: "FFVI"
        0x04    2     Frame count (u16le)
        0x06    2     Frame width in pixels (u16le) — 256
        0x08    2     Frame height in pixels (u16le) — 144
        0x0A    2     Bytes per frame (u16le) — 18,688
        0x0C    1     Tile columns (u8) — 32
        0x0D    1     Tile rows (u8) — 22
        0x0E    1     Number of sub-palettes (u8) — 8
        0x0F    1     Frames per second (u8) — 15

    The SNES player reads this header to configure VRAM layout and DMA.
    """
    header = struct.pack('<4sHHHHBBBB',
        b'FFVI',
        frame_count,
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
        FRAME_BYTES,
        TILE_COLS,
        TILE_ROWS,
        NUM_SUBPALETTES,
        VIDEO_FPS
    )
    assert len(header) == MSU_HEADER_SIZE
    f.write(header)


# =============================================================================
# MSU-1 .pcm audio conversion
# =============================================================================

def convert_audio(ffmpeg_path, input_str, output_pcm):
    """Extract audio from STR and convert to MSU-1 .pcm format.

    MSU-1 .pcm file layout:
        Offset  Size     Field
        0x00    4        Magic bytes: "MSU1"
        0x04    4        Loop point (u32le) — sample index to loop to.
                         0 = no loop (play once and stop).
        0x08    ...      Raw audio samples: 44100 Hz, 16-bit signed LE, stereo.
                         Interleaved: L sample, R sample, L sample, R sample, ...

    The PSX source audio is XA ADPCM at 37800 Hz stereo. ffmpeg resamples to
    44100 Hz and outputs the raw PCM data. We prepend the 8-byte MSU-1 header.

    Note: If the .STR was extracted from a .iso file (not .bin/.cue), the audio
    data is likely corrupt/missing because .iso format truncates XA sectors.
    In that case ffmpeg may produce silence or error — the video will still work
    but playback will have no audio.

    Args:
        ffmpeg_path: str — path to ffmpeg binary.
        input_str:   Path — input .STR file.
        output_pcm:  Path — output .pcm file.
    """
    print(f"  Extracting audio to {output_pcm.name}...")

    cmd = [
        ffmpeg_path,
        '-f', 'psxstr',
        '-i', str(input_str),
        '-vn',                      # No video
        '-ar', str(PCM_SAMPLE_RATE), # Resample to 44100 Hz
        '-ac', '2',                  # Stereo
        '-f', 's16le',               # Raw 16-bit signed LE
        '-acodec', 'pcm_s16le',
        '-v', 'error',
        'pipe:1'
    ]

    result = subprocess.run(cmd, capture_output=True, timeout=600)

    if result.returncode != 0:
        stderr_msg = result.stderr.decode('utf-8', errors='replace').strip()
        if stderr_msg:
            print(f"  WARNING: ffmpeg audio extraction reported errors:\n  {stderr_msg}",
                  file=sys.stderr)

    audio_data = result.stdout

    if len(audio_data) == 0:
        print("  WARNING: No audio data extracted. The .STR may lack audio\n"
              "           (common with .iso-sourced files). Video will still work.",
              file=sys.stderr)
        # Write a minimal .pcm with just the header (silent).
        with open(output_pcm, 'wb') as f:
            f.write(b'MSU1')
            f.write(struct.pack('<I', 0))
        return

    # Calculate audio duration for info display.
    sample_count = len(audio_data) // 4     # 4 bytes per stereo sample (2x s16)
    duration_sec = sample_count / PCM_SAMPLE_RATE

    with open(output_pcm, 'wb') as f:
        # MSU-1 header: magic + loop point (0 = no loop)
        f.write(b'MSU1')
        f.write(struct.pack('<I', 0))
        f.write(audio_data)

    print(f"  Audio: {sample_count:,} samples, {duration_sec:.1f}s, "
          f"{os.path.getsize(output_pcm):,} bytes")


# =============================================================================
# Main conversion pipeline
# =============================================================================

def convert_video(ffmpeg_path, input_str, output_msu, dither_strength=28):
    """Decode video frames from .STR and write the .msu video data file.

    Args:
        ffmpeg_path:     str — path to ffmpeg binary.
        input_str:       Path — input .STR file.
        output_msu:      Path — output .msu file.
        dither_strength: float — Bayer dither intensity.
    """
    # Count frames first for the header and progress display.
    print("  Counting video frames...")
    frame_count = count_video_frames(ffmpeg_path, str(input_str))
    print(f"  Found {frame_count} frames ({frame_count / VIDEO_FPS:.1f}s at {VIDEO_FPS} fps)")

    expected_size = MSU_HEADER_SIZE + frame_count * FRAME_BYTES
    print(f"  Expected .msu size: {expected_size:,} bytes ({expected_size / 1024 / 1024:.1f} MB)")

    # Open ffmpeg video pipe.
    proc = open_video_pipe(ffmpeg_path, input_str)

    with open(output_msu, 'wb') as f:
        write_msu_header(f, frame_count)

        frame_num = 0
        start_time = time.time()

        while True:
            # Read one raw RGB24 frame from the pipe.
            raw = proc.stdout.read(FRAME_SIZE_RGB24)
            if len(raw) < FRAME_SIZE_RGB24:
                break  # End of video stream.

            # Reshape to (height, width, 3) array.
            frame_rgb = np.frombuffer(raw, dtype=np.uint8).reshape(
                (SCREEN_HEIGHT, SCREEN_WIDTH, 3))

            # Convert frame to SNES format.
            palette_bytes, tile_bytes = process_frame(frame_rgb, dither_strength)

            # Write palette first, then tile data (matches SNES DMA order).
            f.write(palette_bytes)
            f.write(tile_bytes)

            frame_num += 1

            # Progress display every 100 frames.
            if frame_num % 100 == 0 or frame_num == frame_count:
                elapsed = time.time() - start_time
                fps = frame_num / elapsed if elapsed > 0 else 0
                pct = frame_num / frame_count * 100 if frame_count > 0 else 0
                print(f"\r  Frame {frame_num}/{frame_count} "
                      f"({pct:.0f}%) — {fps:.1f} frames/sec", end='', flush=True)

        print()  # Newline after progress.

    # Clean up ffmpeg process.
    proc.stdout.close()
    proc.wait()

    if proc.returncode != 0:
        stderr_msg = proc.stderr.read().decode('utf-8', errors='replace').strip()
        if stderr_msg:
            print(f"  WARNING: ffmpeg reported: {stderr_msg}", file=sys.stderr)
    proc.stderr.close()

    actual_size = os.path.getsize(output_msu)
    print(f"  Video: {frame_num} frames, {actual_size:,} bytes ({actual_size/1024/1024:.1f} MB)")

    if frame_num != frame_count:
        print(f"  WARNING: Expected {frame_count} frames but got {frame_num}.",
              file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(
        description='Convert PSX OPEN.STR to SNES MSU-1 video + audio data.',
        epilog='Requires ffmpeg 4.0+ and numpy.')
    parser.add_argument('input', type=Path,
                        help='Input .STR file (from extraction.py)')
    parser.add_argument('-o', '--output', type=str, default=None,
                        help='Output base name (without extension). '
                             'Produces <base>.msu and <base>.pcm. '
                             'Default: same as input filename.')
    parser.add_argument('--dither', type=float, default=28,
                        help='Bayer dither strength in RGB levels (default: 28). '
                             'Higher = more dithering, lower = less. '
                             '0 = no dithering (nearest-color only).')
    parser.add_argument('--video-only', action='store_true',
                        help='Skip audio extraction (produce .msu only).')
    parser.add_argument('--audio-only', action='store_true',
                        help='Skip video conversion (produce .pcm only).')

    args = parser.parse_args()

    # Validate input.
    if not args.input.is_file():
        print(f"ERROR: Input file not found: {args.input}", file=sys.stderr)
        sys.exit(1)

    # Determine output base name.
    if args.output:
        output_base = Path(args.output)
    else:
        output_base = args.input.with_suffix('')

    output_msu = output_base.with_suffix('.msu')
    output_pcm = output_base.with_suffix('.pcm')

    ffmpeg_path = find_ffmpeg()

    print(f"Input:  {args.input}")
    print(f"Output: {output_msu.name} + {output_pcm.name}")
    print(f"Dither strength: {args.dither}")
    print()

    if not args.audio_only:
        print("=== Video conversion ===")
        convert_video(ffmpeg_path, args.input, output_msu, args.dither)
        print()

    if not args.video_only:
        print("=== Audio conversion ===")
        convert_audio(ffmpeg_path, args.input, output_pcm)
        print()

    print("Done.")


if __name__ == '__main__':
    main()
