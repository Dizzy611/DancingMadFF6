from queue import Queue
from threading import Thread
from urllib.parse import unquote
import os
import pycurl
import urllib
import time
import certifi
import hashlib

def file_as_bytes(file):
    with file:
        return file.read()
        
class Downloader():
        Initializing = 1
        Downloading = 2
        Waiting = 3
        Complete = 4
        Skipping = 5
        Summing = 6
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
                elif self.status == self.Skipping:
                        return "Skipping file"
                elif self.status == self.Summing:
                        return "Checksumming local file against remote file"
                        
        def work(self, threadQueue):
                self.size = 0
                self.status = self.Downloading
                urls = threadQueue.get()
                urls = list(urls)
                self.progress = 0
                myurl = None
                for url in urls:
                    try:
                        print("Attempting to open connection to URL " + url + " to check size")
                        sizecurl = pycurl.Curl()
                        sizecurl.setopt(sizecurl.URL, url)
                        sizecurl.setopt(sizecurl.NOBODY, True)
                        sizecurl.setopt(sizecurl.FAILONERROR, True)
                        sizecurl.setopt(sizecurl.CAINFO, certifi.where())
                        sizecurl.setopt(sizecurl.TIMEOUT, 15)
                        sizecurl.perform()
                        str_error = None
                    except pycurl.error as e:
                        str_error = e
                        pass                        
                    if str_error is not None:
                        time.sleep(1)
                    else:
                        myurl = url
                        break
                if (str_error is not None) or (myurl is None):
                    self.status = self.Error
                    print("Downloader encountered ERROR Details: URL: " + url)
                    self.errormessage = "cURL Error: " + str_error.args[1]
                    threadQueue.task_done()
                    return
                else:
                    print("Succeeded in grabbing size of " + myurl)
                destfilename = unquote(myurl.rsplit('/',1)[1])
                fulldestination = os.path.join(self.destination,destfilename)
                if os.path.isfile(fulldestination):
                    self.status = self.Summing
                    print("File already exists. Computing MD5SUM and checking against server...")
                    sum = hashlib.md5(file_as_bytes(open(fulldestination, 'rb'))).hexdigest()
                    print("Current file md5sum is " + sum)
                    try: 
                        print("Downloading remote MD5SUM...")
                        with open(fulldestination + ".md5sum", 'wb') as f:
                            md5curl = pycurl.Curl()
                            md5curl.setopt(md5curl.URL, myurl + ".md5sum")
                            md5curl.setopt(md5curl.FAILONERROR, True)
                            md5curl.setopt(md5curl.CAINFO, certifi.where())
                            md5curl.setopt(md5curl.TIMEOUT, 15)
                            md5curl.setopt(md5curl.WRITEDATA, f)
                            md5curl.setopt(md5curl.FAILONERROR, True)
                            md5curl.perform()
                        str_error = None
                    except pycurl.error as e:
                        str_error = repr(e)
                        pass
                    if str_error is not None:
                        print("Unable to grab remote MD5SUM. Downloading file anyway.")
                    else:
                        with open(fulldestination + ".md5sum", 'r') as f:
                            remotemd5sum = f.read().split(" ")[0].strip()
                            print("Remote file md5sum is " + remotemd5sum)
                        os.remove(fulldestination + ".md5sum")
                        if remotemd5sum == sum:
                            self.size = 0
                            self.status = self.Skipping
                            print("Skipping URL " + myurl + " as existing file matches.")
                            threadQueue.task_done()
                            if threadQueue.empty():
                                self.status = self.Complete
                            else:
                                self.status = self.Waiting
                            return
                        else:
                            self.status = self.Downloading
                            print("Existing file does not match. Downloading as normal.")
                self.size = sizecurl.getinfo(sizecurl.CONTENT_LENGTH_DOWNLOAD)
                try:
                        with open(fulldestination, 'wb') as f:
                                print("Attempting to open connection to URL " + myurl + " to download")
                                filecurl = pycurl.Curl()    
                                filecurl.setopt(filecurl.URL, myurl)
                                filecurl.setopt(filecurl.NOPROGRESS, False)
                                filecurl.setopt(filecurl.PROGRESSFUNCTION, self.progressFunction)
                                filecurl.setopt(filecurl.WRITEDATA, f)
                                filecurl.setopt(filecurl.FAILONERROR, True)
                                filecurl.setopt(filecurl.CAINFO, certifi.where())
                                filecurl.perform()
                                print("Succeeded in downloading from URL " + myurl)
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
                        for url in urls:
                            try:
                                os.remove(self.destination)
                            except:
                                pass
                            try:
                                with open(fulldestination, 'wb') as f:
                                    print("Attempting to open connection to URL " + url + " to download")
                                    filecurl = pycurl.Curl()
                                    filecurl.setopt(filecurl.URL, url)
                                    filecurl.setopt(filecurl.NOPROGRESS, False)
                                    filecurl.setopt(filecurl.PROGRESSFUNCTION, self.progressFunction)
                                    filecurl.setopt(filecurl.WRITEDATA, f)
                                    filecurl.setopt(filecurl.FAILONERROR, True)
                                    filecurl.perform()
                                    print("Succeeded in downloading from URL " + url)
                                    threadQueue.task_done()
                                    if threadQueue.empty():
                                        self.status = self.Complete
                                    else:
                                        self.status = self.Waiting
                                str_error = None
                            except IOError as e:
                                str_error = e
                                self.status = self.Error
                                self.errormessage = "IOError: " + e.strerror
                                threadQueue.task_done()
                                break
                            except pycurl.error as e:
                                str_error = e
                                pass
                            if str_error:
                                time.sleep(2)
                            else:
                                break
                        if str_error:
                            self.status = self.Error
                            print("DEBUG: Downloader encountered ERROR Details: URL: " + url +"," + " Destination: " + fulldestination)
                            self.errormessage = "cURL Error: " + e.args[1] 
                            threadQueue.task_done()
                            
        def progressFunction(self, download_t, download_d, upload_t, upload_d):
                self.progress = download_d



