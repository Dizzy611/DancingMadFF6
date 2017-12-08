import xml.etree.ElementTree as etree

DEBUG = True
STRICT = False

class SongListException(Exception):
    def __init__(self, value):
        self.parameter = value
    def __str__(self):
        return repr(self.parameter)


class SongList:
    def __init__(self, xmlroot):
        self.presets = {}
        self.deferredpresets = {}
        self.songs = []
        self.sources = []
        self.xmlroot = xmlroot
        self.songs_need_validation = False
        self.validity_suspect = False 
        self.validity_warnings = []
        for element in xmlroot:
            if element.tag == "sources":
                self.buildSources(element)
            elif element.tag == "presets":
                self.buildPresets(element)
            elif element.tag == "songs":
                self.buildSongList(element)
            else:
                self.validationError("Unknown tag <" + element.tag + "> under XML root.")
        self.buildDeferredPresets()

    def validationError(self, error, minor=False):
        self.validity_suspect = True
        self.validity_warnings.append(error)
        if STRICT == True and minor == False:
            raise SongListException("Validation Error (Strict is On): " + error)
        elif (STRICT == True and minor == True) or DEBUG == True:
            print("Validation Error (Strict is Off): " + error)
                
    def buildSources(self, element):
        self.sources = []
        for source in element:
            if source.tag != "source":
                self.validationError("Unknown tag <" + element.tag + "> in <sources> when constructing source list.")
                return False
            if source.text not in self.sources:
                self.sources.append(source.text)
            else:
                self.validationError("Duplicate source '" + source.text + "' in list of valid sources.")
        return True
    
    def buildPresets(self, element):
        self.presets = {}
        for preset in element:
            if preset.tag == "preset" and 'name' in preset.attrib:
                thisone = preset.attrib['name']
                if 'type' in preset.attrib and preset.attrib['type'] == "per-song":
                    self.presets[thisone] = "TMP-DEFERRED"
                else: 
                    self.presets[thisone] = {}
                    for source in preset:
                        if 'range' in source.attrib:
                            raw = source.attrib['range']
                            self.presets[thisone][source.tag] = self.parseRange(raw)
                        else:
                            self.validationError("Source '" + source.tag + "' in preset '" + thisone + "' lacks 'range' tag.")
            else:
                self.validationError("Unknown tag or missing nam attribute in presets list.")
                            
                
    def buildSongList(self, element):
        songnum = 0
        slwarn = False
        for song in element:
            newsong = Song()
            for songtag in song:
                if songtag.tag == "name":
                    newsong.name = songtag.text
                elif songtag.tag == "pcms":
                    newsong.pcms = self.parseRange(songtag.text)
                elif songtag.tag == "preset":
                    if songtag.attrib['name'] not in self.deferredpresets:
                        self.deferredpresets[songtag.attrib['name']] = {}
                    if songtag[0].tag not in self.deferredpresets[songtag.attrib['name']]:
                        self.deferredpresets[songtag.attrib['name']][songtag[0].tag] = []
                    self.deferredpresets[songtag.attrib['name']][songtag[0].tag].append(songnum)
                else:
                    if self.sources == []: # We haven't built a sources list yet, or building one failed.
                        # Assume the tag is a valid source and add it to the sources for this song.
                        newsong.sources.append(songtag.tag)
                        # Mark the song list as needing validation
                        self.songs_need_validation = True
                        if slwarn == False:
                            self.validationError("Song list parsed before sources list, or sources list empty. This is not an error but not ideal.", True)
                            slwarn = True # Suppress repeatedly printing this warning.
                    else:
                        if songtag.tag in self.sources:
                            newsong.sources.append(songtag.tag)
                        else:
                            self.validationError("Received a source for a song that was not in the valid sources list. Tag skipped. Offending song: " + songnum + " Offending tag: " + songtag.tag)
            newsong.number = songnum
            if newsong.validate():
                self.songs.append(newsong)
            else:
                self.validationError("Song '" + newsong.name + "' failed to validate and was not added to song list!")
            songnum = songnum + 1
            
    def buildDeferredPresets(self):
        if self.songs == [] or self.presets == {}: # Can't build deferred presets without a song list and presets.
            self.validationError("Attempted to build deferred presets without a valid song and/or preset list.")
            return False
        elif self.deferredpresets == {}: # Nothing was added to the deferred presets by the song building routine!
            for key, value in self.presets.items():
                if value == "TMP-DEFERRED":
                    self.presets[key] = { "ost" : list(range(0,59)), "spc" : [59] } # Default to OST for all but sound effects.
            self.validationError("Attempted to build deferred presets but no entries were added by songlist routine! Filling deferred presets with safe defaults.", True)
        else:
            for key, value in self.presets.items():
                if value == "TMP-DEFERRED":
                    if key in self.deferredpresets:
                        self.presets[key] = self.deferredpresets[key]
                    else:
                        self.presets[key] = { "ost" : list(range(0,59)), "spc" : [59] } # Default to OST for all but sound effects.
                        self.validationError("Attempting to build deferred presets, but preset '" + key + "' has no valid data! Filling preset with safe default.", True)
                            
    def parseRange(self, rangestring):
        ranges = []
        retlist = []
        if "," not in rangestring:
            ranges.append(rangestring)
        else:
            ranges = rangestring.split(",")
        for myrange in ranges:
            if "-" in myrange:
                tmp = myrange.split("-")
                lower = tmp[0]
                upper = tmp[1]
                retlist = retlist + list(range(int(lower), int(upper)+1))
            else:
                retlist.append(int(myrange))
        return retlist
        
class Song:
    def __init__(self):
        self.name = ""
        self.pcms = []
        self.sources = []
        self.number = -1
        
    def sourceCheck(self, source):
        if source in self.sources:
            return True
            
    def validate(self):
        if self.name == "":
            if DEBUG == True:
                print("Warning: Song failed validation: No name!")
            return False
        if self.pcms == []:
            if DEBUG == True:
                print("Warning: Song failed validation: No PCMs!")
            return False
        for pcm in self.pcms:
            if not isinstance(pcm, int):
                if DEBUG == True:
                    print("Warning: Song failed validation: PCM not an integer!")
                return False
        if self.sources == []:
            if DEBUG == True:
                print("Warning: Song failed validation: No sources!")
            return False
        for source in self.sources:
            if not isinstance(source, str) or len(source) > 4:
                if DEBUG == True:
                    print("Warning: Song failed validation: Source not string, or string is > 4 characters long!")
                return False
        if self.number == -1:
            if DEBUG == True:
                print("Warning: Song failed validation: No number!")
            return False
        return True

def parseSongXML(filename):
    tree = etree.parse(filename)
    root = tree.getroot()
    return SongList(root)
    