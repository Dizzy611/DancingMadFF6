
# Selections for different presets.
from installermodule import song
# 0 = OST, 1 = FFT, 2 = SSC, 3 = OCR, 4 = OTH, 5 = OCR2, 6 = None/SPC

tmpsonglist = song.parseSongXML("songs.xml")

def selectionToNumbers(name):
    mypreset = tmpsonglist.presets[name]
    returnpreset = [0]*60
    for idx,source in enumerate(tmpsonglist.sources):
        if source in mypreset:
            for mysong in mypreset[source]:
                returnpreset[mysong] = idx
    return returnpreset

# TEMPORARY! Stop using these constants and start using named presets, soon.
SELECTION_RECOMMENDED = selectionToNumbers("sid")
SELECTION_OST = selectionToNumbers("ost")
SELECTION_FFT = selectionToNumbers("fft") # 16 FFT tracks and 43 OST tracks
SELECTION_SSC = selectionToNumbers("ssc") # 25 SSC tracks and 34 OST tracks
SELECTION_OCR = selectionToNumbers("ocr") # 56 OCR tracks, with 3 OST tracks in various missing spots.
SELECTION_OCRALT = selectionToNumbers("ocr2") # 56 OCR tracks, alternate loops, with 3 OST tracks in various missing spots.

