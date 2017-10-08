import os
import glob
import subprocess
import ntpath
from msu_normalize import msu_normalize

# Set this to where the binary for nongnu normalize is
nongnu_normalize = "C:\\msys64\\home\\dmorrison\\DancingMadFF6\\utils\\normalize\\"

# List of PCM sources
sources = ["OCR", "OTH", "FFT", "OST", "SSC"]
# List of PCM file directories (aligns with above)
dirs = ["./OCR", "./OTH", "./FFT", "./OST", "./SSC"]
# List of destination directories (aligns with above)
destdirs = ["./nrml-OCR", "./nrml-OTH", "./nrml-FFT", "./nrml-OST", "./nrml-SSC"]

# RMS normalization value (in dBFS)
dbfs_level = -18

for idx,dir in enumerate(dirs):
    dir_type = sources[idx]
    dir_dest = destdirs[idx]
    if not os.path.exists(dir_dest):
        os.makedirs(dir_dest)
    print("Working with " + dir_type + " source.")
    pcmfiles = glob.glob(dir + "/*.pcm")
    for file in pcmfiles:
        print("Normalizing " + file)
        msu_normalize(file, dir_dest + "/" + ntpath.basename(file), dbfs_level, nongnu_normalize)
print("Finished.")
