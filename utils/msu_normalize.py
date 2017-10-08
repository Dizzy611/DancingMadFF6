from struct import *
import subprocess
import os

class chunk:
    def __init__(self):
        self.id = ""
        self.chunk_size = 0
        self.format = None
        self.subchunks = []
    def doPack(self, size=None):
        mylen = 0
        mydata = bytes()
        for myChunk in self.subchunks:
            mydata += myChunk.doPack()
        if self.format is not None:
            struct_format = "<4sL4s" + str(len(mydata)) + "s"
            if size is not None:
                self.chunk_size = size
            else:
                temp = pack(struct_format, self.id, 0, self.format, mydata)
                self.chunk_size = len(temp) - 8
            return pack(struct_format, self.id, self.chunk_size, self.format, mydata)
        else:
            struct_format = "<4sL" + str(len(mydata)) + "s"
            temp = pack(struct_format, self.id, 0, mydata)
            if size is not None:
                self.chunk_size = size
            else:
                temp = pack(struct_format, self.id, 0, mydata)
                self.chunk_size = len(temp) - 8
            return pack(struct_format, self.id, self.chunk_size, mydata)


class fmt_subchunk(chunk):
    def __init__(self):
        super().__init__()
        self.id = b"fmt "
        self.chunk_size = 0
        self.audio_format = 0 
        self.num_channels = 0
        self.sample_rate = 0
        self.sample_size = 0
        self.byte_rate = 0
        self.block_align = 0
        self.struct_format = "<4sL2H2L2H"
    def doPack(self):
        self.block_align = int(self.num_channels * self.sample_size / 8)
        self.byte_rate = int(self.num_channels * self.sample_size * self.sample_rate / 8)
        temp = pack(self.struct_format, self.id, 0, self.audio_format, self.num_channels, self.sample_rate, self.byte_rate, self.block_align, self.sample_size)
        self.chunk_size = len(temp) - 8
        return pack(self.struct_format, self.id, self.chunk_size, self.audio_format, self.num_channels, self.sample_rate, self.byte_rate, self.block_align, self.sample_size)

class riff_hdr:
    def __init__(self):
        self.chunk_1 = chunk()
        self.chunk_2 = chunk()
    def write(self):
        part1 = self.chunk_1.doPack()
        part2 = self.chunk_2.doPack()
        size = len(part1+part2) - 8
        part1 = self.chunk_1.doPack(size)
        return part1 + part2

class data_subchunk(chunk):
    def __init__(self):
        self.data = bytes()
    def doPack(self):
        return self.data
    
def msuToWav(msufile):
    header = riff_hdr()
    header.chunk_1.id = b"RIFF"
    header.chunk_1.format = b"WAVE"
    header.chunk_1.subchunks.append(fmt_subchunk())
    header.chunk_1.subchunks[0].id = b"fmt "
    header.chunk_1.subchunks[0].audio_format = 1
    header.chunk_1.subchunks[0].num_channels = 2
    header.chunk_1.subchunks[0].sample_rate = 44100
    header.chunk_1.subchunks[0].sample_size = 16
    header.chunk_2.id = b"data"
    header.chunk_2.subchunks.append(data_subchunk())
    with open(msufile, "rb") as f:
        msucheck = f.read(4)
        loopraw = f.read(4)
        if msucheck == b"MSU1":
            header.chunk_2.subchunks[0].data = f.read()
        else:
            return False
    return header.write(), loopraw

# in order, arguements are the file to normalize, the destination msu file to write when all is said and done, 
# the RMS normalization value in dBFS, the path to the normalize binary, and whether or not to print the output
# of nongnu normalize.
def msu_normalize(msufile, destfile, level, path="", silent=False):
    tmpfile = msufile[:-4] + "-tmp.wav"
    nongnu_normalize = path + "normalize"
    if os.name == 'nt':
        nongnu_normalize = nongnu_normalize + ".exe"
    with open(tmpfile, "wb") as f:
        tmp, loopraw = msuToWav(msufile)
        f.write(tmp)
    to_call = [nongnu_normalize, "-a", str(level) + "dBFS", tmpfile]
    try:
        if silent == True:
            subprocess.check_call(to_call)
        else: 
            print(subprocess.check_output(to_call))
    except subprocess.CalledProcessError as e:
        return False
    with open(tmpfile, "rb") as f:
        f.seek(44) # Skip WAV header.
        tmp = f.read()
    with open(destfile, "wb") as f:
        f.write(b"MSU1")
        f.write(loopraw)
        f.write(tmp)
    os.remove(tmpfile)
    return True