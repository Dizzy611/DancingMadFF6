from installermodule import song
import sys

if len(sys.argv) != 2:
    print("Error: Invalid syntax. Syntax is " + sys.argv[0] + " foo.xml ")
    print("(Where foo.xml is the XML file to validate as a song list.)")
else:
    print("Loading and parsing xml...")
    tovalidate = song.parseSongXML(sys.argv[1])
    if tovalidate.presets != {}:
        for presetname, preset in tovalidate.presets.items():
            checkpreset = [0] * 60
            for source, songs in preset.items():
                for song in songs:
                    if checkpreset[song] == 0:
                        checkpreset[song] = 1
                    if source not in tovalidate.songs[song].sources:
                        if source != 'spc':
                            tovalidate.validationError("Found invalid source choice '" + source + "' for song '" + tovalidate.songs[song].name + "' in preset '" + presetname + "'")
            for idx, song in enumerate(checkpreset):
                if song == 0:
                    tovalidate.validationError("Preset '" + presetname + "' is missing an entry for song #" + str(idx) + " ('" + tovalidate.songs[idx].name + "')")
    else:
        tovalidate.validationError("Preset list empty!")
    if tovalidate.validity_suspect == True:
        print("Found " + str(len(tovalidate.validity_warnings)) + " errors in validation. Printing now.")
        for idx, error in enumerate(tovalidate.validity_warnings):
            print("Warning #" + str(idx) + ": " + error)
    else:
        print("Validated successfully with no errors.")
        