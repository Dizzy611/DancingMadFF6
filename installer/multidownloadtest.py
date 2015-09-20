from queue import Queue
from decimal import Decimal
from downloader import Downloader
import sys

urlbase = "http://www.somebodyelsesproblem.org/ff6data/"
urllist = ["FFT/ff3-2.pcm", "FFT/ff3-3.pcm", "FFT/ff3-4.pcm", "FFT/ff3-5.pcm", "FFT/ff3-10.pcm", "FFT/ff3-13.pcm", "FFT/ff3-22.pcm", "FFT/ff3-23.pcm", "FFT/ff3-35.pcm", "FFT/ff3-36.pcm", "FFT/ff3-46.pcm", "FFT/ff3-47.pcm"]
destination = "dest"

print("Creating queue...")
urlqueue = Queue(maxsize=60)
donecount = 0
totaltodo = len(urllist)
for url in urllist:
        urlqueue.put(urlbase + url)
print("Instantiating Downloader object...")
mydownloader = Downloader(urlqueue,destination)

print("Checking Downloader status... (Should be initializing)")
print("Status is " + mydownloader.statustext())
if mydownloader.status == mydownloader.Initializing:
        print("Telling Downloader to start...")
        mydownloader.start()
        print("Checking Downloader status... (Should be Downloading)")
        print("Status is " + mydownloader.statustext())
        if mydownloader.status == mydownloader.Downloading:
                done = False
                while done != True:
                        curr = len(urllist) - mydownloader.count()
                        total = len(urllist)
                        progress = Decimal(mydownloader.progress)
                        size = Decimal(mydownloader.size)
                        if (size == 0):
                                percentage = 0
                        else:
                                percentage = (progress / size) * 100
                        sys.stdout.write("\033[K")
                        print("Downloading {0}/{1}: {2}% ({3}/{4} kB)".format(curr,total,round(percentage,2),round(progress/1024,2),round(size/1024,2)),end='\r')
                        if mydownloader.status == mydownloader.Waiting:
                                print("")
                                donecount = donecount + 1
                                print("Downloader is waiting, starting next download...")
                                mydownloader.start()
                        elif mydownloader.status == mydownloader.Error:
                                print("")
                                print("Downloader encountered error: " + mydownloader.errormessage + ". Quitting.")
                                errors = True
                                done = True
                        elif mydownloader.status == mydownloader.Complete:
                                print("")
                                donecount = donecount + 1
                                print("Downloader finished! Quitting.")
                                errors = False
                                done = True
                        else:
                                pass
                print("Downloading process finished. Checking...")
                print("Downloaded " + str(donecount) + " out of " + str(totaltodo) + " files.")
                if donecount == totaltodo:
                        print("Download finished!")
                else:
                        print("Download not finished. :(")
                if errors == True:
                        print("Encountered errors in downloading process.")
        else:
                print("Encountered unknown error: Downloader status not correct.")
                errors = True
else:
        print("Encountered unknown error: Downloader status not correct.")

