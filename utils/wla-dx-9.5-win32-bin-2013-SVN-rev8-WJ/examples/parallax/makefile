
AC = wla-gb
AFLAGS = -o
LD = wlalink
LDFLAGS = -v

SFILES  = test.s
OFILES  = test.o
ROMFILE = parallax.gb

all: $(OFILES) makefile
	$(LD) $(LDFLAGS) linkfile $(ROMFILE)

test.o: test.s
	$(AC) $(AFLAGS) test.s


$(OFILES): $(IFILES)


clean:
	rm -f $(OFILES) core *~ $(ROMFILE) *.sym *.asc *.sav
