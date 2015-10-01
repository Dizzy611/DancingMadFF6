#!/usr/bin/env python

import os
import struct

# Modified (hacked, more like) by Dylan Morrison for specific use in the Dancing Mad installer.
# LoROM support is back, instead of using the struct.error sanity check we now check for the presence
# of the fixed value 0x33 at position 26 in the header.
#
# Also modified to read Destcode and checksum, and a checksum calculator and destcode reader function 
# were added.
#

__author__ = ('David Anderson <dave@natulte.net>',
              'Maxime Petazzoni <maxime.petazzoni@bulix.org>',
              'Dylan Morrison <insidious@gmail.com')



# SMC ROM files may have an additional 512-byte SMC header at the beginning:
#   offset  size in bytes    contents
#  ----------------------------------------------------------------------------
#   0       2                ROM dump size, in units of 8kB (little-endian).
#   2       1                Binary flags for the ROM layout and save-RAM size.
#   3       509              All zero.

SMC_HEADER_SIZE = 512
SMC_HEADER_SIZE_NON_ZERO = 3
SMC_HEADER_FORMAT = '@HB'

SMC_ROM_LAYOUT_LOROM = 0x00
SMC_ROM_LAYOUT_HIROM = 0x30
SMC_SAVERAM_SIZE_32KB = 0x00
SMC_SAVERAM_SIZE_8KB = 0x04
SMC_SAVERAM_SIZE_4KB = 0x08
SMC_SAVERAM_SIZE_0kB = 0x0c

# SNES ROM headers are located at addresses 0x7fc0 for LoROM images and 0xffc0
# for HiROM images. These values may need to be offseted by 512 bytes when a
# SMC ROM header is present (respectively 0x81c0 and 0x101c0).
# See http://romhack.wikia.com/wiki/SNES_header for more information on SNES
# header fields and their values.

SNES_HEADER_SIZE = 64
SNES_HEADER_SIZE_PARSED = 32
SNES_HEADER_OFFSET_LOROM = 0x7fc0
SNES_HEADER_OFFSET_HIROM = 0xffc0

# SNES header format:
#   offset  size in bytes    contents
#  ----------------------------------------------------------------------------
#   0       21               Space-padded ASCII game title.
#   21      1                ROM layout (LoROM / HiROM / FastROM).
#   22      1                Cartridge type (ROM-only / with save-RAM).
#   23      1                ROM byte size.
#   24      1                RAM byte size.
#   25      1                Destination code.
#   26      1                Sanity check value (0x33)
#   27      1                Version #
#   28      2                Complement check
#   30      2                Checksum

SNES_HEADER_FORMAT = '@21sBBBBBBBHH'

SNES_ROM_LAYOUT_LOROM = 0x20
SNES_ROM_LAYOUT_HIROM = 0x21
SNES_ROM_LAYOUT_FASTROM = 0x10

SNES_CARTRIDGE_TYPE_ROM_ONLY = 0x00
SNES_CARTRIDGE_TYPE_SAVERAM = 0x02

# Compute the SNES checksum of a ROM file.
def compute_snes_checksum(filename):
    romfile = open(filename, 'rb')
    filesize = os.fstat(romfile.fileno()).st_size
    rem = filesize % 1024
    if rem == 512:
        _ = romfile.read(512) # Skip header
        filesize = filesize - 512 # Remove header from size calculations.
    elif rem != 0:
        # Invalid SNES ROM.
        return 0
    else:
        pass
        
    if (filesize == 1048576) or (filesize == 2097152) or (filesize == 4194304):
        sumbuf = romfile.read()
        checksum = sum(bytearray(sumbuf))
        checksum = checksum & 65535
    elif filesize == 524288:
        sumbuf = romfile.read(524288)
        checksum = sum(bytearray(sumbuf))
        checksum = checksum * 2
        checksum = checksum & 65535
    elif filesize == 1572864:
        sumbuf = romfile.read(1048576)
        checksum = sum(bytearray(sumbuf))
        sumbuf = romfile.read(524288)
        tempsum = sum(bytearray(sumbuf))
        checksum += tempsum*2
        checksum = checksum & 65535
    elif filesize == 2621440:
        sumbuf = romfile.read(2097152)
        checksum = sum(bytearray(sumbuf))
        sumbuf = romfile.read(524288)
        tempsum = sum(bytearray(sumbuf))
        checksum += tempsum*2
        checksum = checksum & 65535
    elif (filesize == 3145728) or (filesize == 3670016):    
        sumbuf = romfile.read(2097152)
        checksum = sum(bytearray(sumbuf))
        sumbuf = romfile.read(1048576)
        tempsum = sum(bytearray(sumbuf))
        checksum += tempsum*2
        checksum = checksum & 65535
    elif filesize == 6291456:
        sumbuf = romfile.read(4194304)
        checksum = sum(bytearray(sumbuf))
    else: 
        # Invalid SNES rom
        checksum = 0
    return checksum

# Decode SNES destcodes to GoodTools Country Code
def decode_destcode(destcode):
    if destcode == 0:
        return("J")
    elif destcode == 1:
        return("U")
    elif destcode == 2:
        return("E")
    elif destcode == 3:
        return("SwNo")
    elif destcode == 6:
        return("F")
    elif destcode == 7:
        return("Nl")
    elif destcode == 8:
        return("S")
    elif destcode == 9:
        return("G")
    elif destcode == 10:
        return("I")
    elif destcode == 11:
        return("Ch")
    elif destcode == 13:
        return("K")
    elif destcode == 14:
        return("Unk") # Maybe should be W or JUE?
    elif destcode == 15:
        return("C")
    elif destcode == 16:
        return("B")
    elif destcode == 17: 
        return("A")
    elif destcode <= 20:
        return("Unk")
        
class InvalidRomFileException(Exception):
    """The provided ROM file is invalid or not supported."""
    pass

class InvalidHeaderFormatException(Exception):
    """The SNES ROM header could not be parsed in this ROM."""
    pass

class SNESRom:

    def __init__(self, filename):
        self.filename = filename
        self.rom = open(filename, "rb")

        self.filesize = os.fstat(self.rom.fileno()).st_size

        # SMC header data, when present
        self._smc_parsed = False
        self.has_smc_header = None
        self.smc_rom_dumpsize = None
        self.smc_rom_layout = None
        self.smc_saveram_size = None

        # SNES Header data
        self._snes_parsed = False
        self.title = None
        self.rom_layout = None
        self.cartridge_type = None
        self.rom_size = None
        self.ram_size = None

    def _parse_smc_header(self):
        print('Looking for SMC header...')
        rem = self.filesize % 1024
        if rem == 0:
            print('ROM filesize is N*1024 bytes, no SMC header present.')
            self.has_smc_header = False
            self._smc_parsed = True
        elif rem == 512:
            print('Found SMC header, parsing...')
            self.rom.seek(0)
            header = self.rom.read(SMC_HEADER_SIZE_NON_ZERO)
            data = struct.unpack(SMC_HEADER_FORMAT, header)
            print('SMC Header data: %s.', data)

            self.has_smc_header = True
            self.smc_rom_dumpsize = data[0]*8*1024
            # TODO: parse binary flags from SMC header data[1]
            self._smc_parsed = True
        else:
            raise InvalidRomFileException

    def _read_header(self):
        """Read and unpack the SNES header at the given offset, eventually
        taking into account the presence of an SMC header.
        """
        offset = SNES_HEADER_OFFSET_LOROM
        print('Attempting to teading SNES header at LoROM offset %s (has SMC header: %s)...' %
                  (hex(offset), bool(self.has_smc_header)))
        try:
            self.rom.seek(offset + self.has_smc_header*SMC_HEADER_SIZE)
            header = self.rom.read(SNES_HEADER_SIZE_PARSED)
            data = struct.unpack(SNES_HEADER_FORMAT, header)
            if (data[6] != 0x33) or ((data[8] + data[9]) != 0xFFFF): # Probably HIROM
                print('Attempting to teading SNES header at HiROM offset %s (has SMC header: %s)...' %
                  (hex(offset), bool(self.has_smc_header)))
                offset = SNES_HEADER_OFFSET_HIROM
                self.rom.seek(offset + self.has_smc_header*SMC_HEADER_SIZE)
                header = self.rom.read(SNES_HEADER_SIZE_PARSED)
                data = struct.unpack(SNES_HEADER_FORMAT, header)
                if (data[6] != 0x33) or ((data[8] + data[9]) != 0xFFFF): # Invalid Header.
                    raise InvalidHeaderFormatException
                else:
                    print('SNES HiROM header data: %s.' % repr(data))
                    return data
            else:
                print('SNES LoROM header data: %s.' % repr(data))
                return data 
        except struct.error:
            raise InvalidHeaderFormatException
            
    def parse(self):
        """Parses the ROM image to extract information from the SNES header
        (game title, ROM details, etc.)."""

        if self._snes_parsed:
            return

        if not self._smc_parsed:
            self._parse_smc_header()
            
        try:
            header_data = self._read_header()
        except InvalidHeaderFormatException:
            print('Header does not match expected format. '
                      'Giving up!')
            raise InvalidRomFileException

        self.title = header_data[0].strip().title()
        self.rom_layout = header_data[1]
        self.cartridge_type = header_data[2]
        self.rom_size = 2**header_data[3]
        self.ram_size = 2**header_data[4]
        self.destcode = header_data[5]
        self.sanitycheck = header_data[6]
        self.version = header_data[7]
        self.checksum = header_data[9]
        self._snes_parsed = True

    def get_layout_type(self):
        """Returns the display-friendly ROM layout type."""
        assert self._snes_parsed

        if self.rom_layout == SNES_ROM_LAYOUT_LOROM:
            return 'LoROM'
        elif self.rom_layout == SNES_ROM_LAYOUT_HIROM:
            return 'HiROM'
        elif self.rom_layout == SNES_ROM_LAYOUT_FASTROM:
            return 'FastROM'
        else:
            return 'n/a'

    def get_cartridge_type(self):
        """Returns the display-friendly cartridge type."""
        assert self._snes_parsed

        if self.cartridge_type == SNES_CARTRIDGE_TYPE_ROM_ONLY:
            return 'ROM-only'
        elif self.cartridge_type == SNES_CARTRIDGE_TYPE_SAVERAM:
            return 'save-RAM'
        else:
            return 'n/a'

    def get_info_string(self):
        """Returns a display-friendly info string on this ROM."""
        assert self._snes_parsed

        info = '%dkB %s' % (self.rom_size, self.get_layout_type())

        if self.cartridge_type == SNES_CARTRIDGE_TYPE_SAVERAM:
            info += ', with %dkB %s' % (self.ram_size,
                                        self.get_cartridge_type())
        else:
            info += ', %s' % self.get_cartridge_type()

        return info
