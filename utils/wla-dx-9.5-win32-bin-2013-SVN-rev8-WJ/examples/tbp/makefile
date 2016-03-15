
CC = wla-gb
CFLAGS = -o
LD = wlalink
LDFLAGS = -vs

SFILES = main.s setup.s level_01.s vbi.s
IFILES = defines.i
OFILES = main.o setup.o level_01.o vbi.o
LFILES = ../lib/speed.lib

all: $(OFILES) $(LFILES) makefile
	$(LD) $(LDFLAGS) linkfile tbp.cgb

main.o: main.s defines.i
	$(CC) $(CFLAGS) main.s

setup.o: setup.s defines.i
	$(CC) $(CFLAGS) setup.s

level_01.o: level_01.s defines.i
	$(CC) $(CFLAGS) level_01.s

vbi.o: vbi.s defines.i
	$(CC) $(CFLAGS) vbi.s

$(OFILES): $(HFILES)


clean:
	rm -f $(OFILES) core *~ tbp.cgb tbp.sym
