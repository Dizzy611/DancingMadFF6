from queue import Queue
from threading import Thread
from urllib.parse import unquote
import os
import pycurl
import urllib


class Downloader():
        Initializing = 1
        Downloading = 2
        Waiting = 3
        Complete = 4
        Error = -1
        def __init__(self, urlqueue, destination):
                self.urlqueue = urlqueue
                self.errormessage = ""
                self.destination = os.path.join(".",destination)
                self.size = 0
                self.progress = 0
                self.status = self.Initializing
        
        def add(self, url):
                try:
                        self.urlqueue.put(url)
                except queue.Full:
                        return False
                return True

        def count(self):
                if self.urlqueue.empty():
                        return 0
                else:
                        return self.urlqueue.qsize()

        def start(self):
                self.worker = Thread(target=self.work, args=(self.urlqueue,))
                self.worker.setDaemon(True)
                self.worker.start()

        def statustext(self):
                if self.status == self.Initializing:
                        return "Initializing"
                elif self.status == self.Downloading:
                        return "Downloading"
                elif self.status == self.Waiting:
                        return "Waiting"
                elif self.status == self.Error:
                        return "Error"
                elif self.status == self.Complete:
                        return "Complete"

        def work(self, threadQueue):
                self.status = self.Downloading
                url = threadQueue.get()
                sizecurl = pycurl.Curl()
                sizecurl.setopt(sizecurl.URL, url)
                sizecurl.setopt(sizecurl.NOBODY, True)
                sizecurl.perform()
                destfilename = unquote(url.rsplit('/',1)[1])
                fulldestination = os.path.join(self.destination,destfilename)
                self.size = sizecurl.getinfo(sizecurl.CONTENT_LENGTH_DOWNLOAD)
                try:
                        with open(fulldestination, 'wb') as f:
                                filecurl = pycurl.Curl()
                                filecurl.setopt(filecurl.URL, url)
                                filecurl.setopt(filecurl.NOPROGRESS, False)
                                filecurl.setopt(filecurl.PROGRESSFUNCTION, self.progressFunction)
                                filecurl.setopt(filecurl.WRITEDATA, f)
                                filecurl.setopt(filecurl.FAILONERROR, True)
                                filecurl.perform()
                                threadQueue.task_done()
                                if threadQueue.empty():
                                        self.status = self.Complete
                                else:
                                        self.status = self.Waiting

                except IOError as e:
                        self.status = self.Error
                        self.errormessage = "IOError: " + e.strerror
                        threadQueue.task_done()
                except pycurl.error as e:
                        try:
                                os.remove(self.destination)
                        except:
                                pass
                        self.status = self.Error
                        print("DEBUG: Downloader encountered ERROR Details: URL: " + url +"," + " Destination: " + fulldestination)
                        self.errormessage = "cURL Error: " + e.args[1] 
                        threadQueue.task_done()

        def progressFunction(self, download_t, download_d, upload_t, upload_d):
                self.progress = download_d



