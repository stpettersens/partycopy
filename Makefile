o=.o
exe=
rm=rm

uname := $(shell uname)

# https://github.com/stpettersens/uname-windows
ifeq ($(uname),Windows)
	o=.obj
	exe=.exe
	rm=del
endif

ifeq ($(uname),CYGWIN_NT-10.0-19044)
	o=.obj
	exe=.exe
endif

make:
	ldc2 partycopy.d
	$(rm) partycopy$(o)

compress:
	upx -9 partycopy$(exe)

clean:
	$(rm) partycopy$(exe)

install:
	@echo "Please run as sudo/doas."
	mkdir -p /etc/partycopy
	cp partycopy /usr/local/bin
	ln -sf /usr/local/bin/partycopy /usr/local/bin/pcp
	mkdir -p /usr/share/partycopy
	cp LICENSE /usr/share/partycopy
