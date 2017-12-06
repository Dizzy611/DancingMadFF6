sources = [ "OST", "FFT", "SSC", "OCR", "OTH", "OCR2", "SPC" ]

class Song:
	def __init__(self):
		self.name = ""
		self.pcms = []
		self.sources = []
		self.number = -1
	def sourceCheck(self, source):
		if source in self.sources:
			return True