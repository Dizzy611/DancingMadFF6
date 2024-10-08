/* BSD 2-Clause License

Copyright (c) 2017-2024, Dylan "Dizzy" O'Malley-Morrison <dizzy@domad.science>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Disclaimer of Trademark and of Association with Rights Holders
"Final Fantasy","Final Fantasy III", and "Final Fantasy VI" are registered trademarks
of Square Enix Holdings Co., Ltd, hereafter "Square Enix". This is NOT a licensed product
of Square Enix. The developers are not affiliated with or sponsored by Square Enix or any other
rights holders.

This patch is intended to be used only with a legally obtained copy of Final Fantasy III. */


// code partially based on snestools from the pvsneslib library (https://github.com/alekmaul/pvsneslib/blob/master/tools/snestools/snestools.c), used under the following license:

/*---------------------------------------------------------------------------------

    Copyright (C) 2012-2021
        Alekmaul

    This software is provided 'as-is', without any express or implied
    warranty.  In no event will the authors be held liable for any
    damages arising from the use of this software.

    Permission is granted to anyone to use this software for any
    purpose, including commercial applications, and to alter it and
    redistribute it freely, subject to the following restrictions:

    1.	The origin of this software must not be misrepresented; you
        must not claim that you wrote the original software. If you use
        this software in a product, an acknowledgment in the product
        documentation would be appreciated but is not required.
    2.	Altered source versions must be plainly marked as such, and
        must not be misrepresented as being the original software.
    3.	This notice may not be removed or altered from any source
        distribution.

    Header checker / modifier for snes.
    Some parts are based on Snes mess driver.

---------------------------------------------------------------------------------*/

#include "rom_validator.h"
#include <cstring>
#include <string>
#include <iostream>
#include <fstream>
#include <vector>
#include <cstdint>
#include <iomanip>
#include <QFile>
#include <QCryptographicHash>
#include "dmlogger.h"

struct ROMValid validate_rom(std::string filename, DMLogger *logger) {
    struct ROMValid output;
    memset(&output, 0, sizeof(struct ROMValid));

    // load rom
    FILE *fp = fopen(filename.c_str(), "r");

    // get rom size
    fseek(fp, 0, SEEK_END);
    int rom_size = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    // check for an extra copier header
    bool has_copier_header = false;
    unsigned char header[16];
    if (fread(&header, sizeof(header), 1, fp) < 1) {
        output.return_code = ERROR_NO_HEADER;
        output.error_string = "Invalid ROM: No valid header found in ROM.";
        return output;
    }
    if ((header[8] == 0xaa) && (header[9] == 0xbb) && (header[10] == 0x04)) {
        // SWC header
        has_copier_header = true;
    } else if ((header[0] | (header[1] << 8)) == (((rom_size - 512) / 1024) / 8)) {
        // unknown header with ROM size at start
        has_copier_header = true;
    } else if ((rom_size % 0x8000) == 512) {
        // unknown header, extra 512 bytes of data compared to valid SNES ROM size
        has_copier_header = true;
    } else {
        has_copier_header = false;
    }

    // seek past any copier header and to internal header
    int offset = 0x7fb0 + has_copier_header * 512;
    fseek(fp, offset, SEEK_SET);

    // read internal header
    snes_header snesheader;
    if (fread(&snesheader, sizeof(snes_header), 1, fp) < 1) {
        output.return_code = ERROR_NO_HEADER;
        output.error_string = "Invalid ROM: No valid header found in ROM.";
        return output;
    }

    // seek back to earlier ofset
    fseek(fp, offset, SEEK_SET);

    // check for LoROM or HiROM
    if (!((snesheader.checksum + snesheader.checksum_c ) == 0xffff && (snesheader.checksum != 0) && (snesheader.checksum_c != 0))) {
        // seek past any copier header and to HiROM internal header
        offset = 0xffb0 + has_copier_header * 512;
        fseek(fp, offset, SEEK_SET);

        // read and validate the hirom header
        if ((fread(&snesheader, sizeof(snes_header), 1, fp) < 1) || !((snesheader.checksum + snesheader.checksum_c) == 0xffff && (snesheader.checksum != 0) && (snesheader.checksum_c != 0))) {
            output.return_code = ERROR_NO_HEADER;
            output.error_string = "Invalid ROM: No valid header found in ROM.";
            return output;
        }
    }
    fclose(fp);

    // begin validity checks vs FF3 ROM

    // check country (done early to simplify later code)
    bool japanese;
    if (snesheader.countrycode == 0) {
        japanese = true;
    } else if (snesheader.countrycode == 1) {
        japanese = false;
    } else {
        output.return_code = ERROR_INVALID_COUNTRY;
        output.error_string = "Invalid ROM: Country code not US or Japan.";
        return output;
    }


    // check for company or licensor ID == "C3" (Square)
    if (!japanese) {
        char company_id[2];
        for (int i = 0; i < 2; i++) {
            company_id[i] = snesheader.extended[i];
        }
        if ((company_id[0] == 0x43) && (company_id[1] == 0x33)) {
            logger->doLog("DEBUG: Company ID is correct (U)");
        } else {
            output.return_code = ERROR_WRONG_COMPANY;
            output.error_string = "Not a Final Fantasy 3/6 ROM: Company ID does not match.";
            return output;
        }
    } else {
        if (snesheader.license == 0xC3) {
            logger->doLog("DEBUG: Licensor ID is correct (J)");
        } else {
            output.return_code = ERROR_WRONG_COMPANY;
            output.error_string = "Not a Final Fantasy 3/6 ROM: Licensor ID does not match.";
            return output;
        }
    }

    if ((!japanese) && (snesheader.license = 0x33)) {
        char rom_id[5];
        for (int i = 0; i < 4; i++) {
            rom_id[i] = snesheader.extended[2 + i];
        }
        rom_id[4] = '\0';
        if(strcmp(rom_id, "F6  ") != 0) {
            output.return_code = ERROR_WRONG_ROM;
            output.error_string = "Not a Final Fantasy 3/6 ROM: ROM ID does not match";
            return output;
        } else {
            logger->doLog("DEBUG: ROM ID is correct (US V1.0 or V1.1 ROM)");
        }
    }

    // check for title == "FINAL FANTASY 3" or "FINAL FANTASY 6"
    char title[22];
    for (int i = 0; i < 21; i++) {
        title[i] = snesheader.title[i];
    }
    title[21] = '\0';
    if (japanese && (strcmp(title, "FINAL FANTASY 6      ") == 0)) {
        logger->doLog("DEBUG: Title is correct for Japanese ROM.");
    } else if (strcmp(title, "FINAL FANTASY 3      ") == 0) {
        logger->doLog("DEBUG: Title is correct for US ROM.");
    } else {
        output.return_code = ERROR_WRONG_TITLE;
        output.error_string = "Not a Final Fantasy 3/6 ROM: Title does not match.";
        return output;
    }

    // check version
    int version = 0;
    if (!japanese) { // japanese ROM only has one version
        if (snesheader.version == 1) {
            logger->doLog("DEBUG: Version is 1.1");
            version = 1;
        }
    }

    // check ROM type
    bool rom_is_lorom = snesheader.romlayout & 0x01 ? false : true; // TODO: Is rom_type header check from above sufficient for this, or do we need to use romlayout?
    if (rom_is_lorom) {
        output.return_code = ERROR_WRONG_ROM_TYPE;
        output.error_string = "Not a Final Fantasy 3/6 ROM: LoROM type instead of HiROM.";
        return output;
    } else {
        logger->doLog("DEBUG: ROM type is correct.");
    }

    // check ROM size
    if (!(snesheader.ROMsize == 0x0c)) { // check for 4MB / 32Megabits ROM, correct for all versions of FF3/6
        output.return_code = ERROR_WRONG_SIZE;
        output.error_string = "Not a Final Fantasy 3/6 ROM: Wrong ROM size.";
        return output;
    } else {
        logger->doLog("DEBUG: ROM size is correct.");
    }

    // check SRAM size
    if (!(snesheader.SRAMsize == 0x03)) { // check for 8KB / 64Kilobits SRAM, correct for all versions of FF3/6
        output.return_code = ERROR_WRONG_SRAM;
        output.error_string = "Not a Final Fantasy 3/6 ROM: Wrong SRAM size.";
    } else {
        logger->doLog("DEBUG: SRAM size is correct.");
    }

    // check checksum
    int correct_checksum = 0;
    if (japanese) {
        correct_checksum = 41330;
    } else if (version == 1) {
        correct_checksum = 35424;
    } else {
        correct_checksum = 24370;
    }
    if (snesheader.checksum != correct_checksum) {
        output.return_code = WARN_PATCHED;
        output.error_string = "Possible patched ROM: Checksum value not recognized.";
        return output;
    } else {
        logger->doLog("DEBUG: Checksum value is correct.");
    }

    // compute checksum
    std::ifstream cppfile(filename, std::ios::binary | std::ios::ate);
    std::streamsize filesize = cppfile.tellg();
    cppfile.seekg(0, std::ios::beg);
    if (has_copier_header) {
        logger->doLog("Skipping copier header in checksum");
        filesize = filesize - 512;
        cppfile.seekg(512, std::ios::beg);
    }
    const std::streamsize first_chunk_size = 2097152;
    std::vector<uint8_t> buffer1(first_chunk_size);
    cppfile.read(reinterpret_cast<char*>(buffer1.data()), std::min(first_chunk_size, filesize));
    uint32_t checksum = 0;
    for (uint8_t byte : buffer1) {
        checksum += byte;
    }
    const std::streamsize second_chunk_size = 1048576;
    std::vector<uint8_t> buffer2(second_chunk_size);
    cppfile.read(reinterpret_cast<char*>(buffer2.data()), std::min(second_chunk_size, filesize - first_chunk_size));
    uint32_t tempsum = 0;
    for (uint8_t byte : buffer2) {
        tempsum += byte;
    }
    checksum += tempsum * 2;
    checksum &= 0xFFFF;
    if (checksum != correct_checksum) {
        output.return_code = WARN_PATCHED;
        output.error_string = "Possible patched ROM: Computed checksum does not match value.";
        return output;
    }
    cppfile.close();
    // compute SHA256 sum


    std::string correct_sha256sum = "";
    if (japanese) {
        correct_sha256sum = "7187333502021addc80ce27d5b0b4316dcac9318871e1c3ed5ed474b10177b65";
    } else if (version == 1) {
        correct_sha256sum = "10eccc5d2fab81346dd759f6be478dcb682eef981e8d3d662da176e1f9a996bc";
    } else {
        correct_sha256sum = "0f51b4fca41b7fd509e4b8f9d543151f68efa5e97b08493e4b2a0c06f5d8d5e2";
    }

    // new SHA256 using QCryptographicHash
    QFile file(QString::fromStdString(filename));
    file.open(QIODevice::ReadOnly);
    QCryptographicHash hash(QCryptographicHash::Sha256);
    if (!has_copier_header) {
        hash.addData(&file);
    } else {
        file.seek(512);
        QByteArray myData = file.readAll();
        hash.addData(myData);
    }
    QByteArray hash_string = hash.result().toHex();
    file.close();

    if (hash_string.toStdString() != correct_sha256sum) {
        output.return_code = WARN_PATCHED;
        output.error_string = "Possible patched ROM: Computed SHA256 hash does not match expected value.";
        return output;
    } else {
        logger->doLog("DEBUG: SHA256sum is correct.");
    }

    // We've gotten to the bottom, so we've got a fully valid ROM. Return an "error" code indicating a valid ROM of the given region and version
    if (japanese) {
        output.return_code = VALID_JP;
        output.error_string = "Valid Japanese rom. Disabling optional patches as they are not supported with this configuration.";
    } else if (version == 1) {
        output.return_code = VALID_US_V11;
        output.error_string = "Valid US V1.1 rom. Disabling optional patches as they are not supported with this configuration.";
    } else {
        output.return_code = VALID_US_V10;
        output.error_string = "Valid US V1.0 rom.";
    }
    return output;
}
