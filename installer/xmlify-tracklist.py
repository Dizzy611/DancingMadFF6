import csv
from installermodule import song

sources = [ "OST", "FFT", "SSC", "OCR", "OTH", "OCR2", "SPC" ]

# Load old style data files
titles = []
pcms = []
sourcelist = []
with open("trackTitles.dat") as f:
	for line in f:
		titles.append(line)
with open("trackMapping.dat") as f:
	for line in f:
		pcms.append(line)
with open("trackSources.csv") as f:
	mycsv = open("trackSources.csv")
	csvreader = csv.reader(f)
	for row in csvreader:
		sourcelist.append(row)
		
# Check to make sure all datasets have the same number of rows
if len(titles) == len(pcms) == len(sourcelist):
	# Create a set of "Song" objects based on loaded data
	songlist = []
	for idx,mysong in enumerate(titles):
		newsong = song.Song()
		newsong.name = mysong
		newsong.sources = []
		for inneridx,source in enumerate(sourcelist[idx]):
			if source == "1":
				newsong.sources.append(sources[inneridx])
		newsong.pcms = pcms[idx].split(",")
		newsong.number = idx
		songlist.append(newsong)

	# Check if list of songs has been populated with at least one object
	if songlist != []:
		# Begin outputting our XML file
		with open("songs.xml", "w") as f:
			f.write("<songlist>\n")
			for song in songlist:
				f.write("\t<song>\n")
				f.write("\t\t<name>" + song.name.strip() + "</name>\n")
				f.write("\t\t<pcms>" + ",".join(song.pcms).strip() + "</pcms>\n")
				for source in song.sources:
					if source.lower() != "spc":
						f.write("\t\t<" + source.lower() + "/>\n")
				f.write("\t</song>\n")
			f.write("</songlist>\n")
	else:
		print("Aborted: Unknown error, song list empty.")
else:
	print("Aborted: Lengths of different datasets differ. T:" + len(titles) + "M:" + len(pcms) + "S:" + sum(1 for row in csvreader))