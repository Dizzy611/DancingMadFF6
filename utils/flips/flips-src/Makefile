CFLAGS_gtk = -DFLIPS_GTK $(GTKFLAGS) $(GTKLIBS)
CFLAGS_windows := -DFLIPS_WINDOWS -mwindows -lgdi32 -lcomdlg32
CFLAGS_win := $(CFLAGS_windows)
CFLAGS_cli := -DFLIPS_CLI

FNAME_gtk := flips
FNAME_windows := flips.exe
FNAME_win := $(FNAME_windows)
FNAME_cli := flips

ifeq ($(TARGET),)
  targetmachine := $(shell $(CC) -dumpmachine)
  ifneq ($(findstring mingw,$(targetmachine)),)
    TARGET := windows
  else ifneq ($(findstring linux,$(targetmachine)),)
    TARGET := gtk
  else
    TARGET := cli
  endif
endif

ifeq ($(TARGET),win)
  override TARGET := windows
endif

ifeq ($(TARGET),)
  uname := $(shell uname -a)
  ifeq ($(uname),)
    TARGET := windows
  else ifneq ($(findstring CYGWIN,$(uname)),)
    TARGET := windows
  else ifneq ($(findstring Darwin,$(uname)),)
    TARGET := cli
  else
    TARGET := gtk
  endif
endif

ifeq ($(TARGET),gtk)
  ifeq ($(GTKFLAGS),)
    GTKFLAGS := $(shell pkg-config --cflags --libs gtk+-3.0 2>/dev/null)
  endif
  ifeq ($(GTKFLAGS),)
    $(warning pkg-config can't find gtk+-3.0 (or pkg-config itself can't be found); assuming they're included somewhere)
    $(warning if you have the needed files installed, specify their locations and names with `make 'GTKFLAGS=-I/usr/include' 'GTKLIBS=-L/usr/lib -lgtk'')
    $(warning if not, the package name under Debian and derivates is `libgtk-3-dev'; on other distros, consult a search engine)
  endif
endif

$(FNAME_$(TARGET)): *.c
	$(CC) $^ -std=c99 $(CFLAGS) $(LFLAGS) $(CFLAGS_$(TARGET)) -o$@
