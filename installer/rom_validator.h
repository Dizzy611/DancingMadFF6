#ifndef ROM_VALIDATOR_H
#define ROM_VALIDATOR_H

#include <string>

typedef struct
{
    char extended[16];                  // extra information for header
    /*
                                        1	$00:FFB0	0x0081B0	2 bytes	Maker code
                                        2	$00:FFB2	0x0081B2	4 bytes	Game code
                                        3	$00:FFB6	0x0081B6	7 bytes	Fixed Value ($00)
                                        4	$00:FFBD	0x0081BD	1 byte	Expansion RAM size
                                        5	$00:FFBE	0x0081BE	1 byte	Special version
                                        6	$00:FFBF	0x0081BF	1 byte	Cartridge type
                                    */
    /*FFC0*/ char title[21];            // Name of the ROM, typically in ASCII, using spaces to pad the name to 21 bytes.
    /*FFD5*/ unsigned char romlayout;   // ROM layout, typically $20 for LoROM, or $21 for HiROM. Add $10 for FastROM.
    /*FFD6*/ unsigned char cardtype;    // Cartridge type, typically $00 for ROM only, or $02 for ROM with save-RAM.
    /*FFD7*/ unsigned char ROMsize;     // ROM size byte.
    /*FFD8*/ unsigned char SRAMsize;    // RAM size byte.
    /*FFD9*/ unsigned char countrycode; // Country code, which selects the video in the emulator. Values $00, $01, $0d use NTSC. Values in range $02..$0c use PAL. Other values are invalid.
    /*FFDA*/ unsigned char license;     // Licensee code. If this value is $33, then the ROM has an extended header with ID at $ffb2..$ffb5.
    /*FFDB*/ unsigned char version;     // Version number, typically $00.
    /*FFDC*/ unsigned short checksum_c; // Checksum complement, which is the bitwise-xor of the checksum and $ffff.
    /*FFDE*/ unsigned short checksum;   // SNES checksum, an unsigned 16-bit checksum of bytes.
    unsigned int unknow;                // Unknown.
    unsigned short cop_vecs;            // Table of interrupt vectors for native mode
    unsigned short brk_vecs;
    unsigned short abort_vecs;
    unsigned short nmi_vecs;
    unsigned short unused_vecs;
    unsigned short irq_vecs;
    unsigned int unknow1;     // Unknown.
    unsigned short ecop_vecs; // Table of interrupt vectors for emulation mode.
    unsigned short eunused_vecs;
    unsigned short eabort_vecs;
    unsigned short enmi_vecs;
    unsigned short ereset_vecs;
    unsigned short eirq_vecs;
} snes_header;

struct ROMValid {
    int return_code;
    std::string error_string;
};

struct ROMValid validate_rom(std::string filename);

#define VALID_US_V10 0
#define VALID_US_V11 1
#define VALID_JP 2
#define WARN_PATCHED 3
#define ERROR_NO_HEADER 4
#define ERROR_WRONG_COMPANY 5
#define ERROR_WRONG_ROM 6
#define ERROR_INVALID_COUNTRY 7
#define ERROR_WRONG_ROM_TYPE 8
#define ERROR_WRONG_SIZE 9
#define ERROR_WRONG_SRAM 10
#define ERROR_WRONG_TITLE 11

#endif // ROM_VALIDATOR_H
