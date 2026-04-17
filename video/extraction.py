#!/usr/bin/env python3
"""
extraction.py — Extract the intro cutscene (OPEN.STR) from an FF6 PSX disc image.

Part of the Dancing Mad FF6 project: PSX intro video implementation.
Extracts the MOVIE/OPEN.STR FMV from a Final Fantasy Anthology (FF6) disc image
and outputs it in raw-sector format for further processing by conversion.py.

System dependencies:
    Python 3.6+         — No external Python packages required.
    ffmpeg 4.0+         — NOT required by this script; used later by conversion.py.
                          Must include the 'psxstr' demuxer and 'mdec' decoder.
                          (Standard builds include both.)

Supported input formats:
    .bin/.cue            — Raw CD image (MODE2/2352, 2352 bytes/sector).
                          Provide the .cue file as input; the .bin is found automatically.
                          ** PREFERRED ** — preserves both video and XA audio.
    .iso                 — Standard ISO 9660 image (2048 bytes/sector).
                          WARNING: XA audio sectors are Mode 2 Form 2 (2328 bytes of
                          data per sector), but .iso only stores 2048 bytes. The audio
                          data is irrecoverably truncated. Video-only extraction will
                          work, but the audio track will be silent/corrupt.
                          Use .bin/.cue for full audio+video extraction.

Supported disc versions:
    Final Fantasy Anthology: FF6 (USA) v1.0   (.bin and .iso)
    Final Fantasy Anthology: FF6 (USA) v1.1   (.iso only — add .bin hash when available)

Platform support:
    Linux, macOS, Windows — pure Python, no platform-specific code.

Usage:
    python3 extraction.py <input.cue|input.iso> [output.str]

    If output path is omitted, writes OPEN.STR in the current directory.
"""

import argparse
import hashlib
import os
import struct
import sys
from pathlib import Path

# =============================================================================
# Constants
# =============================================================================

SECTOR_RAW = 2352       # Full raw CD sector (sync + header + subheader + data + EDC/ECC)
SECTOR_DATA = 2048      # ISO 9660 user data per sector
SYNC_OFFSET = 0         # Offset of sync pattern within a raw sector
HEADER_OFFSET = 12      # Offset of sector header (4 bytes: MSF + mode)
SUBHEADER_OFFSET = 16   # Offset of subheader (8 bytes: 4 bytes duplicated)
DATA_OFFSET = 24        # Offset of user data within a raw sector

# CD sync pattern: signals the start of every raw sector
CD_SYNC = bytes([0x00] + [0xFF] * 10 + [0x00])

# PSX STR video sector identifier (little-endian u16 at start of user data)
STR_VIDEO_MAGIC = 0x0160

# The file we're looking for on the disc.
# v1.0 uses "OPEN.STR", v1.1 renamed it to "OPENING.STR". We try both.
TARGET_FILES = [
    "MOVIE/OPEN.STR",
    "MOVIE/OPENING.STR",
]

# =============================================================================
# Known-good disc checksums (SHA-1)
# =============================================================================
# Maps SHA-1 hex digest -> (human-readable version name, file type)
# These are verified against known good dumps. If a disc image doesn't match,
# the script warns but still attempts extraction.

KNOWN_CHECKSUMS = {
    # .bin files (raw 2352-byte sectors)
    "1ac7200bfed1edb47e8b74fc27865ea5031e6d03": "USA v1.0 (.bin)",
    # .iso files (2048-byte sectors, e.g. from bchunk conversion)
    "baffd1fa3dd515288d7ecbecdc07c1ac67d9c27c": "USA v1.0 (.iso)",
    "72de55b1ebdebab550b9ddcca8eedb1057ca311f": "USA v1.1 (.iso)",
    # TODO: Add JP and EU checksums when available
}

# =============================================================================
# BCD / MSF helpers
# =============================================================================

def _to_bcd(val):
    """Convert an integer (0-99) to BCD encoding."""
    return ((val // 10) << 4) | (val % 10)


def _lba_to_msf(lba):
    """Convert a logical block address to CD MSF (minutes, seconds, frames).

    Includes the standard 150-sector (2-second) pregap offset, which is how
    real CDs number their sectors. The psxstr demuxer doesn't actually use
    MSF values, but producing correct-looking headers is good practice.
    """
    lba += 150  # Standard CD pregap
    minutes = lba // (75 * 60)
    seconds = (lba // 75) % 60
    frames = lba % 75
    return _to_bcd(minutes), _to_bcd(seconds), _to_bcd(frames)

# =============================================================================
# ISO 9660 minimal filesystem parser
# =============================================================================

class Iso9660Parser:
    """Minimal ISO 9660 directory parser.

    Reads just enough of the filesystem to locate a specific file by path.
    Works with any object that provides read_sector_data(lba) -> 2048 bytes.
    """

    def __init__(self, image):
        self.image = image

    def find_file(self, filepath):
        """Locate a file by path (e.g. 'MOVIE/OPEN.STR').

        Returns (lba, size_bytes) or None if not found.
        The path is case-insensitive; ISO 9660 Level 1 stores names in uppercase.
        """
        # Primary Volume Descriptor is always at sector 16
        pvd = self.image.read_sector_data(16)

        # Verify PVD signature: byte 0 = 0x01 (type), bytes 1-5 = 'CD001'
        if pvd[0:1] != b'\x01' or pvd[1:6] != b'CD001':
            raise ValueError("No valid ISO 9660 Primary Volume Descriptor found at sector 16")

        # Root directory record is at PVD offset 156, 34 bytes long
        root_record = pvd[156:156 + 34]
        dir_lba = struct.unpack_from('<I', root_record, 2)[0]
        dir_size = struct.unpack_from('<I', root_record, 10)[0]

        # Walk path components: e.g. ['MOVIE', 'OPEN.STR']
        parts = filepath.upper().split('/')

        for part in parts:
            result = self._find_in_directory(dir_lba, dir_size, part)
            if result is None:
                return None
            dir_lba, dir_size, is_dir = result

            # If this isn't the last component, it must be a directory
            if part != parts[-1] and not is_dir:
                return None

        return (dir_lba, dir_size)

    def _find_in_directory(self, dir_lba, dir_size, target_name):
        """Search a single directory for an entry matching target_name.

        Returns (lba, size, is_directory) or None.
        """
        # Read all sectors that make up this directory
        sectors_needed = (dir_size + SECTOR_DATA - 1) // SECTOR_DATA
        dir_data = b''
        for s in range(sectors_needed):
            dir_data += self.image.read_sector_data(dir_lba + s)

        offset = 0
        while offset < dir_size:
            rec_len = dir_data[offset]

            if rec_len == 0:
                # Directory entries don't span sector boundaries; skip to next sector
                next_sector_offset = ((offset // SECTOR_DATA) + 1) * SECTOR_DATA
                if next_sector_offset >= dir_size:
                    break
                offset = next_sector_offset
                continue

            # Parse the directory record
            entry_lba = struct.unpack_from('<I', dir_data, offset + 2)[0]
            entry_size = struct.unpack_from('<I', dir_data, offset + 10)[0]
            flags = dir_data[offset + 25]
            is_dir = bool(flags & 0x02)
            name_len = dir_data[offset + 32]
            raw_name = dir_data[offset + 33:offset + 33 + name_len].decode('ascii', errors='replace')

            # Strip the ";1" version suffix that ISO 9660 appends to filenames
            name = raw_name.split(';')[0]

            if name.upper() == target_name:
                return (entry_lba, entry_size, is_dir)

            offset += rec_len

        return None

# =============================================================================
# Disc image classes
# =============================================================================

class DiscImage:
    """Base class for reading sectors from a disc image."""

    def __init__(self, path):
        self.path = Path(path)
        self._file = None

    def open(self):
        self._file = open(self.path, 'rb')

    def close(self):
        if self._file:
            self._file.close()
            self._file = None

    def __enter__(self):
        self.open()
        return self

    def __exit__(self, *args):
        self.close()

    def read_sector_data(self, lba):
        """Read the 2048-byte user data portion of a sector."""
        raise NotImplementedError

    def read_sector_raw(self, lba):
        """Read or reconstruct a full 2352-byte raw sector."""
        raise NotImplementedError

    def total_sectors(self):
        raise NotImplementedError


class BinImage(DiscImage):
    """Raw CD image (.bin) with 2352-byte sectors.

    These preserve the complete sector structure including sync, header,
    subheader, user data, and EDC/ECC — exactly what ffmpeg's psxstr
    demuxer expects.
    """

    def read_sector_data(self, lba):
        self._file.seek(lba * SECTOR_RAW + DATA_OFFSET)
        return self._file.read(SECTOR_DATA)

    def read_sector_raw(self, lba):
        self._file.seek(lba * SECTOR_RAW)
        return self._file.read(SECTOR_RAW)

    def total_sectors(self):
        return os.path.getsize(self.path) // SECTOR_RAW


class IsoImage(DiscImage):
    """Standard ISO 9660 image (.iso) with 2048-byte sectors.

    These lack sync, header, subheader, and EDC/ECC data. To produce output
    that ffmpeg's psxstr demuxer can parse, we reconstruct raw sectors by
    generating the missing fields.

    Important limitation: XA audio sectors in Mode 2 Form 2 originally held
    2328 bytes of data, but .iso conversion truncates them to 2048 bytes.
    The audio data is irrecoverably lost. This means .iso input will produce
    a video-only .STR file — the audio track will be silent or corrupt.
    For full audio+video extraction, use a .bin/.cue disc image instead.
    """

    def read_sector_data(self, lba):
        self._file.seek(lba * SECTOR_DATA)
        return self._file.read(SECTOR_DATA)

    def read_sector_raw(self, lba):
        """Reconstruct a raw 2352-byte sector from 2048-byte ISO data.

        Builds a valid-looking Mode 2 sector with:
        - Standard CD sync pattern
        - MSF header derived from LBA
        - Subheader guessed from sector content (video vs. audio/padding)
        - Original 2048 bytes of user data
        - Zeroed EDC/ECC (ffmpeg doesn't validate these)
        """
        data = self.read_sector_data(lba)

        # MSF header
        m, s, f = _lba_to_msf(lba)
        header = bytes([m, s, f, 0x02])  # Mode 2

        # Determine subheader by inspecting the user data:
        # - Video sectors start with the STR magic 0x0160
        # - Everything else is treated as audio/padding
        status = struct.unpack_from('<H', data, 0)[0] if len(data) >= 2 else 0
        if status == STR_VIDEO_MAGIC:
            # Video sector: file=1, channel=1, submode=0x48 (data + real-time)
            subheader = bytes([0x01, 0x01, 0x48, 0x00])
        else:
            # Audio/padding sector: file=1, channel=1, submode=0x64
            # (audio + real-time + Form 2)
            subheader = bytes([0x01, 0x01, 0x64, 0x00])

        # Subheader is written twice (4 bytes × 2 = 8 bytes)
        subheader_pair = subheader + subheader

        # EDC (4 bytes) + ECC (276 bytes) = 280 bytes, zeroed
        edc_ecc = bytes(280)

        return CD_SYNC + header + subheader_pair + data + edc_ecc

    def total_sectors(self):
        return os.path.getsize(self.path) // SECTOR_DATA

# =============================================================================
# Checksum validation
# =============================================================================

def compute_sha1(filepath):
    """Compute SHA-1 hash of a file, with progress reporting for large files."""
    sha1 = hashlib.sha1()
    file_size = os.path.getsize(filepath)
    bytes_read = 0
    chunk_size = 4 * 1024 * 1024  # 4 MB chunks

    with open(filepath, 'rb') as f:
        while True:
            chunk = f.read(chunk_size)
            if not chunk:
                break
            sha1.update(chunk)
            bytes_read += len(chunk)
            pct = bytes_read * 100 // file_size
            print(f"\r  Hashing: {pct}%", end='', flush=True)

    print("\r  Hashing: done.     ")
    return sha1.hexdigest()


def validate_image(filepath):
    """Check a disc image's SHA-1 against known-good checksums.

    Returns the version string if recognized, or None if unknown.
    Prints a warning for unknown images but does NOT block extraction.
    """
    print(f"Validating: {filepath}")
    digest = compute_sha1(filepath)
    print(f"  SHA-1: {digest}")

    version = KNOWN_CHECKSUMS.get(digest)
    if version:
        print(f"  Recognized: {version}")
    else:
        print("  WARNING: Unrecognized disc image.")
        print("  This may be a bad dump, a different region, or an unsupported version.")
        print("  Extraction will be attempted, but results are not guaranteed.")

    return version

# =============================================================================
# Input detection
# =============================================================================

def detect_input(filepath):
    """Detect whether the input is a .bin/.cue pair or a standalone .iso.

    For .cue files, locates and returns the associated .bin.
    Returns a DiscImage subclass instance (not yet opened).
    """
    path = Path(filepath)
    suffix = path.suffix.lower()

    if suffix == '.cue':
        # Parse the .cue sheet to find the .bin file
        bin_path = _parse_cue_for_bin(path)
        print(f"Input: .bin/.cue pair")
        print(f"  .cue: {path}")
        print(f"  .bin: {bin_path}")
        return BinImage(bin_path)

    elif suffix == '.bin':
        # Direct .bin without .cue — assume single data track at sector 0
        print(f"Input: .bin (raw CD image, no .cue)")
        return BinImage(path)

    elif suffix == '.iso':
        print(f"Input: .iso (ISO 9660)")
        print(f"  WARNING: .iso images lose XA audio data during conversion.")
        print(f"  The extracted video will work, but audio will be silent/corrupt.")
        print(f"  For full audio+video, re-dump your disc as .bin/.cue instead.")
        return IsoImage(path)

    else:
        print(f"ERROR: Unsupported file type '{suffix}'.")
        print("Supported: .cue, .bin, .iso")
        sys.exit(1)


def _parse_cue_for_bin(cue_path):
    """Extract the .bin filename from a .cue sheet.

    Handles quoted and unquoted FILE directives. The .bin path is resolved
    relative to the .cue file's directory.
    """
    cue_dir = cue_path.parent

    with open(cue_path, 'r', encoding='utf-8', errors='replace') as f:
        for line in f:
            line = line.strip()
            if line.upper().startswith('FILE'):
                # Parse: FILE "filename.bin" BINARY
                # or:    FILE filename.bin BINARY
                rest = line[4:].strip()
                if rest.startswith('"'):
                    end_quote = rest.index('"', 1)
                    bin_name = rest[1:end_quote]
                else:
                    bin_name = rest.split()[0]

                bin_path = cue_dir / bin_name
                if not bin_path.exists():
                    print(f"ERROR: .bin file referenced by .cue not found: {bin_path}")
                    sys.exit(1)
                return bin_path

    print(f"ERROR: No FILE directive found in .cue: {cue_path}")
    sys.exit(1)

# =============================================================================
# STR extraction
# =============================================================================

def find_str_boundaries(image, file_lba, file_size, found_name):
    """Determine the sector range of the OPEN.STR file.

    Args:
        image: An opened DiscImage instance.
        file_lba: Starting LBA of the file (from ISO 9660 directory entry).
        file_size: File size in bytes (from ISO 9660 directory entry).
        found_name: The actual filename found on disc (for display).

    Returns:
        (start_lba, sector_count): The LBA range to extract.
    """
    sector_count = (file_size + SECTOR_DATA - 1) // SECTOR_DATA

    # Sanity check: verify the first sector is a valid STR video sector
    first_data = image.read_sector_data(file_lba)
    status = struct.unpack_from('<H', first_data, 0)[0]
    if status != STR_VIDEO_MAGIC:
        print(f"  WARNING: First sector at LBA {file_lba} does not start with STR video magic.")
        print(f"  Got 0x{status:04X}, expected 0x{STR_VIDEO_MAGIC:04X}.")
        print(f"  Attempting extraction anyway.")

    # Count video frames for a progress summary
    video_sectors = 0
    max_frame = 0
    for i in range(min(sector_count, 100)):  # Sample first 100 sectors
        data = image.read_sector_data(file_lba + i)
        s = struct.unpack_from('<H', data, 0)[0]
        if s == STR_VIDEO_MAGIC:
            video_sectors += 1
            fn = struct.unpack_from('<I', data, 8)[0]
            if fn > max_frame:
                max_frame = fn

    width = struct.unpack_from('<H', first_data, 0x10)[0]
    height = struct.unpack_from('<H', first_data, 0x12)[0]

    print(f"  File: {found_name}")
    print(f"  LBA: {file_lba}, Sectors: {sector_count}")
    print(f"  Resolution: {width}x{height}")
    print(f"  Sample: {video_sectors} video sectors in first 100, max frame seen: {max_frame}")

    return (file_lba, sector_count)


def extract_str(image, start_lba, sector_count, output_path):
    """Extract sectors to a raw .STR file.

    Reads sectors from the disc image and writes them as 2352-byte raw sectors.
    For .bin images this is a direct copy; for .iso images the raw sector
    structure is reconstructed (see IsoImage.read_sector_raw).
    """
    output_path = Path(output_path)
    total_bytes = sector_count * SECTOR_RAW

    print(f"\nExtracting {sector_count} sectors ({total_bytes / (1024*1024):.1f} MB) to: {output_path}")

    with open(output_path, 'wb') as out:
        for i in range(sector_count):
            raw = image.read_sector_raw(start_lba + i)
            out.write(raw)

            # Progress every 1000 sectors (~2.3 MB)
            if (i + 1) % 1000 == 0 or i == sector_count - 1:
                pct = (i + 1) * 100 // sector_count
                print(f"\r  Progress: {pct}% ({i+1}/{sector_count} sectors)", end='', flush=True)

    print(f"\n  Wrote {os.path.getsize(output_path) / (1024*1024):.1f} MB")

    # Final verification: check that frame count matches expectations
    _verify_output(output_path)


def _verify_output(output_path):
    """Quick sanity check on the extracted .STR file."""
    with open(output_path, 'rb') as f:
        # Read first raw sector and check for valid STR content
        sector = f.read(SECTOR_RAW)
        if len(sector) < SECTOR_RAW:
            print("  WARNING: Output file is smaller than a single sector!")
            return

        # Check sync pattern
        if sector[0:12] != CD_SYNC:
            print("  WARNING: First sector missing CD sync pattern.")
            return

        # Check STR magic in data portion
        status = struct.unpack_from('<H', sector, DATA_OFFSET)[0]
        if status != STR_VIDEO_MAGIC:
            print("  WARNING: First sector is not a video sector.")
            return

        # Count total frames by scanning the file
        file_size = os.path.getsize(output_path)
        total_sectors = file_size // SECTOR_RAW
        f.seek(0)

        max_frame = 0
        for i in range(total_sectors):
            raw = f.read(SECTOR_RAW)
            s = struct.unpack_from('<H', raw, DATA_OFFSET)[0]
            if s == STR_VIDEO_MAGIC:
                fn = struct.unpack_from('<I', raw, DATA_OFFSET + 8)[0]
                if fn > max_frame:
                    max_frame = fn

    print(f"  Verification: {max_frame} video frames found, {total_sectors} total sectors.")
    print(f"  Duration: ~{max_frame / 15:.1f} seconds at 15 fps.")

# =============================================================================
# Main
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Extract OPEN.STR (intro cutscene) from an FF6 PSX disc image.",
        epilog="Supports .bin/.cue and .iso inputs. Output is a raw-sector .STR file."
    )
    parser.add_argument(
        "input",
        help="Path to the disc image (.cue, .bin, or .iso)"
    )
    parser.add_argument(
        "output",
        nargs='?',
        default="OPEN.STR",
        help="Output filename (default: OPEN.STR)"
    )
    parser.add_argument(
        "--skip-checksum",
        action="store_true",
        help="Skip SHA-1 checksum validation (faster, less safe)"
    )
    args = parser.parse_args()

    # Verify input exists
    if not Path(args.input).exists():
        print(f"ERROR: Input file not found: {args.input}")
        sys.exit(1)

    print("=" * 60)
    print("FF6 PSX Intro Video Extractor")
    print("=" * 60)
    print()

    # Step 1: Detect input type
    image = detect_input(args.input)

    # Step 2: Validate checksum
    if not args.skip_checksum:
        print()
        # For .cue input, hash the .bin file (the actual disc data)
        validate_image(image.path)
    else:
        print("\n  Checksum validation skipped.")

    # Step 3: Open image and find the target file
    print(f"\nLocating intro cutscene in disc filesystem...")
    with image:
        fs = Iso9660Parser(image)

        # Try each known filename (v1.0 uses OPEN.STR, v1.1 uses OPENING.STR)
        result = None
        found_name = None
        for candidate in TARGET_FILES:
            result = fs.find_file(candidate)
            if result is not None:
                found_name = candidate
                break

        if result is None:
            tried = ', '.join(TARGET_FILES)
            print(f"  ERROR: Intro video not found on disc.")
            print(f"  Tried: {tried}")
            print("  This may not be an FF6 disc, or the filesystem is damaged.")
            sys.exit(1)

        file_lba, file_size = result
        print(f"  Found: {found_name}")
        print(f"  LBA={file_lba}, Size={file_size} bytes ({file_size / (1024*1024):.1f} MB)")

        # Step 4: Analyze and extract
        start_lba, sector_count = find_str_boundaries(image, file_lba, file_size, found_name)

        # Step 5: Extract
        extract_str(image, start_lba, sector_count, args.output)

    print("\nDone. Use conversion.py to process the extracted video.")


if __name__ == '__main__':
    main()
