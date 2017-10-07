# I would use pysox but it lacks support for raw pcm files and depends on the existence of a "grep" command on the calling OS. Also it just calls SoX from the command line itself, anyway, so...
import os
import glob
import subprocess
import re
import shutil
import ntpath

# Set this to your SoX exe.
sox = "C:\Program Files (x86)\sox-14-4-2\sox.exe"

# List of PCM sources
sources = ["OCR", "OTH", "FFT", "OST", "SSC"]
# List of PCM file directories (aligns with above)
dirs = ["./OCR", "./OTH", "./FFT", "./OST", "./SSC"]
# List of destination directories (aligns with above)
destdirs = ["./deamp-OCR", "./deamp-OTH", "./deamp-FFT", "./deamp-OST", "./deamp-SSC"]

# Default deamplification value
default = -7.5
# List of additions to normal deamplification. Uses a tuple of the format 
# (source, number, gain) where source is the source from above list, number is 
# the track number, and gain is the (de)amplification to apply, added
# to the base (-7.5 as of this writing).
# A total gain of 0 will cause the script to simply copy the file over.
additions = [
    #("SSC", 29, 3.5),
    #("FFT", 46, 1),
    #("SSC", 46, 3.5),
    #("SSC", 50, 1.5),
    ("OCR", 47, -0.5),
    ("OCR", 62, 2.5),
    ("OCR", 78, 3.5),
    ("OST", 82, 2.5),
    ("OST", 83, 1),
    ("OST", 101, 1),
    ("OST", 102, 1),
    ("OST", 103, 1.5),
    ("SSC", 2, -0.5),
    ("SSC", 5, -0.5),
    ("SSC", 9, -1),
    ("SSC", 10, -3),
    ("SSC", 12, -1),
    ("SSC", 13, -1.5),
    ("SSC", 18, -0.5),
    ("SSC", 20, -2),
    ("SSC", 22, -2),
    ("SSC", 23, -1.5),
    ("SSC", 25, -3.5),
    ("SSC", 26, -3),
    ("SSC", 29, -1),
    ("SSC", 31, -2),
    ("SSC", 32, 3.5),
    ("SSC", 35, -1.5),
    ("SSC", 36, -1.5),
    ("SSC", 42, -0.5),
    ("SSC", 46, -0.5),
    ("SSC", 47, -1),
    ("SSC", 50, -1),
    ("FFT", 2, 1.5),
    ("FFT", 10, -0.5),
    ("FFT", 12, -0.5),
    ("FFT", 13, -1),
    ("FFT", 24, -1),
    ("FFT", 28, -1.5),
    ("FFT", 32, -1),
    ("FFT", 35, -0.5),
    ("FFT", 36, -1),
    ("FFT", 46, -0.5),
    ("FFT", 50, -1),
    ("OTH", 34, 7.5),
    ("OTH", 70, -0.5)
]

def grab_track_number(filename):
    rx = re.compile(r'\d+')
    retlist = [int(x) for x in rx.findall(filename)]
    if len(retlist) >= 2:
        return retlist[1]
    else:
        return 0
    
for idx,dir in enumerate(dirs):
    dir_type = sources[idx]
    dir_dest = destdirs[idx]
    print("Working with " + dir_type + " source.")
    pcmfiles = glob.glob(dir + "/*.pcm")
    for file in pcmfiles:
        if os.name == 'nt':
            file = file.replace("\\", "/") # Make my life easier.
        tracknum = grab_track_number(file)
        volume = default
        for addition in additions:
            if addition[0] == dir_type and addition[1] == tracknum:
                volume = volume + addition[2]
        noext = file[:-4]
        if volume != 0:
            try:
                with open(file, "rb") as f:
                    msu1bytes = f.read(4)
                    if msu1bytes != b'MSU1':
                        raise ValueError('File does not have MSU-1 bytes. Missing header/invalid PCM file.')
                    loopraw = f.read(4)
                    pcm = f.read()
            except ValueError as e:
                print("File " + file + " does not appear to be a valid MSU-1 PCM file. Skipping. Detailed error: " + e.strerror)
                continue # Hopefully this works... Dunno if continue is still valid from within an exception block.
            except IOError as e:
                print("Unable to open and read " + file + ", skipping. Detailed error: " + e.strerror)
                continue
            try:
                with open(noext + ".tmp", "wb") as g:
                    g.write(pcm)
            except IOError as e:
                print("Unable to open and write " + noext + ".tmp, skipping. Detailed error: " + e.strerror)
                continue            
            print("Deamplifying " + file + " by " + str(volume) + " using SoX")
            try:
                output = subprocess.check_output([sox, "-t", "raw", "-e", "signed", "-b", "16", "-r", "44100", "-c", "2", "-L", noext + ".tmp", "-t", "raw", "-L", noext + "-deamp.tmp", "vol", str(volume) + "dB"])
                if output:
                    print(output)
            except FileNotFoundError as e:
                print("Unable to find/run SoX. Quitting.")
                raise e
                break
            except subprocess.CalledProcessError as e:
                print("Unable to deamplify " + file + ", skipping. Detailed error: " + e.strerror)
                continue
            print("Succeeded.")
            try:
                with open(noext + "-deamp.tmp", "rb") as f:
                    newpcm = f.read()
            except IOError as e:
                print("Unable to open and read " + noext + "-deamp.tmp, skipping. Detailed error: " + e.strerror)
                continue
            print("Writing new PCM file with old header data.")
            try:
                with open(noext + "-deamp.pcm", "wb") as f:
                    f.write(msu1bytes)
                    f.write(loopraw)
                    f.write(newpcm)
            except IOError as e:
                print("Unable to open and write " + noext + "-deamp.pcm, skipping. Detailed error: " + e.strerror)
                continue
            print("Wrote new PCM file. Deleting temporary files.")
            os.remove(noext + ".tmp")
            os.remove(noext + "-deamp.tmp")
            print("Done. Moving to next file.")
        else:
            print("Deamplification value is zero. Copying " + file + " to " + noext + "-deamp.pcm without altering it.")
            shutil.copy2(file, noext + "-deamp.pcm")
            print("Done. Moving to next file.")
    print("Moving deamplified PCMs to destination directory.")
    deampfiles = glob.glob(dir + "/*-deamp.pcm")
    for file in deampfiles:
        if os.name == 'nt':
            file.replace("\\", "/") # Make my life easier.
        final_dest = dir_dest + "/" + ntpath.basename(file).replace("-deamp","")
        print("Moving " + file + " to " + final_dest)
        shutil.move(file, final_dest)
print("Finished.")
