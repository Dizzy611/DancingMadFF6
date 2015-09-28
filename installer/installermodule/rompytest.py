import rom
import os


    
filename = "../rom/ff3msu.sfc"
print("ROM.py Tester")
print("Loading" + filename)
myrom = rom.SNESRom(filename)
myrom.parse()
print("Loaded")
print("Title: |" + myrom.title.decode("ASCII") + "|")
if myrom.destcode == 0:
    print("Made for: Japan (NTSC)")
elif myrom.destcode == 1:
    print("Made for: USA (NTSC)")
elif myrom.destcode == 2:
    print("Made for: Europe (PAL)")
elif myrom.destcode == 3:
    print("Made for: Scandinavia (PAL)")
elif myrom.destcode == 6:
    print("Made for: French-speaking Europe (SECAM)")
elif myrom.destcode == 7:
    print("Made for: The Netherlands (PAL)")
elif myrom.destcode == 8:
    print("Made for: Spain (PAL)")
elif myrom.destcode == 9:
    print("Made for: Germany (PAL)")
elif myrom.destcode == 10:
    print("Made for: Italy (PAL)")
elif myrom.destcode == 11:
    print("Made for: China (PAL)")
elif myrom.destcode == 13:
    print("Made for: Korea (NTSC likely, PAL in North (are there any north korean SNES roms?))")
elif myrom.destcode == 14:
    print("Made for: Common PAL Territory?")
elif myrom.destcode == 15:
    print("Made for: Canada (NTSC)")
elif myrom.destcode == 16:
    print("Made for: Brazil (PAL-M)")
elif myrom.destcode == 17: 
    print("Made for: Australia (PAL)")
elif myrom.destcode <= 20:
    print("Made for: Other")
else:
    print("Invalid destcode")
print("Version: " + str(int(myrom.version)))
print("Reported Checksum: " + str(myrom.checksum))
checksum = rom.compute_snes_checksum(filename)
print("Actual Checksum: " + str(checksum))
romfile = open(filename, 'rb')
filesize = os.fstat(romfile.fileno()).st_size
romfile.close()
print("Filesize: " + str(filesize))
print("Reported ROM Size: " + str(int(myrom.rom_size / 1024 * 8)) + "Mbit")
print("Actual ROM Size: " + str(int(filesize / 1024 / 1024 * 8)) + "Mbit")