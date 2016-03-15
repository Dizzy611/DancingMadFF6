# OS detection
ifeq ($(OS),Windows_NT)
	ASM      = ../utils/wla-dx-9.5-win32-bin-2013-SVN-rev8-WJ/wla-65816.exe
        ASMFLAGS = -vo
        LD       = ../utils/wla-dx-9.5-win32-bin-2013-SVN-rev8-WJ/wlalink.exe
        LDFLAGS  = -vr
        IPS      = ../utils/flips.exe
        IPSFLAGS = --create --ips
        DELETE   = del
else
	ASM      = wla-65816
        ASMFLAGS = -vo
        LD       = wlalink
        LDFLAGS  = -vr
        IPS      = flips
        IPSFLAGS = --create --ips
        DELETE   = rm -f
endif

# Pseudo-automake-style verbosity
V = 0
AT_0 := @
AT_1 :=
AT = $(AT_$(V))

# Due to the way wla works, we want to make doubly sure there's no existing
# object files/completed sfcs/ipses in the same directory when we start.

all: clean build

build: ff3msu.ips ff3msu.sfc

.PHONY: all clean build

ff3msu.obj: ff3.sfc ff3msu.asm
	@echo "Assembling..."
	$(AT)$(ASM) $(ASMFLAGS) ff3msu.asm ff3msu.obj

ff3msu.link:
	@echo "Creating linker directives..."
	$(AT)echo "[objects]" > ff3msu.link
	$(AT)echo "ff3msu.obj" >> ff3msu.link

ff3msu.sfc: ff3msu.link ff3msu.obj
	@echo "Linking..."
	$(AT)$(LD) $(LDFLAGS) ff3msu.link ff3msu.sfc

ff3msu.ips: ff3.sfc ff3msu.sfc
	@echo "Creating IPS..."
	$(AT)$(IPS) $(IPSFLAGS) ff3.sfc ff3msu.sfc ff3msu.ips

clean:
	@echo "Cleaning up..."
	$(AT)$(DELETE) *.obj ff3msu.sfc ff3msu.ips ff3msu.link
