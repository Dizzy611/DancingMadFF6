# OS detection
ifeq ($(OS),Windows_NT)
		ASM      = ../utils/wla-dx/wla-65816.exe
        ASMFLAGS = -v -o
        LD       = ../utils/wla-dx/wlalink.exe
        LDFLAGS  = -v -r
        DELETE   = rm -f
else
		ASM      = wla-65816
        ASMFLAGS = -v -o
        LD       = wlalink
        LDFLAGS  = -v -r
        DELETE   = rm -f
endif

# Pseudo-automake-style verbosity
V = 0
AT_0 := @
AT_1 :=
AT = $(AT_$(V))

# Due to the way wla works, we want to make doubly sure there's no existing
# object files/completed sfcs in the same directory when we start.

all: clean build

build: video-player-test.sfc

.PHONY: all clean build

video-player-test.obj: video-player-test.asm
	@echo "Assembling..."
	$(AT)$(ASM) $(ASMFLAGS) video-player-test.obj video-player-test.asm

video-player-test.link:
	@echo "Creating linker directives..."
	$(AT)echo "[objects]" > video-player-test.link
	$(AT)echo "video-player-test.obj" >> video-player-test.link

video-player-test.sfc: video-player-test.link video-player-test.obj
	@echo "Linking..."
	$(AT)$(LD) $(LDFLAGS) video-player-test.link video-player-test.sfc

clean:
	@echo "Cleaning up..."
	$(AT)$(DELETE) *.obj video-player-test.sfc video-player-test.link
