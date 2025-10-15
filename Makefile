o=.o
exe=
rm=rm

uname := $(shell uname)
arch := $(shell uname -m)

sha256sumA=sha256sum partycopy_linux_$(arch).tar.gz > partycopy_linux_$(arch)_sha256.txt
sha256sumB=sha256sum setup-partycopy.sh > setup-partycopy_sha256.txt

# https://github.com/stpettersens/uname-windows
# https://github.com/stpettersens/sha256_chksum
ifeq ($(uname),Windows)
	sha256sumA=sha256_chksum partycopy_win64.zip
	sha256sumB=sha256_chksum partycopy-setup.ps1
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

win_package:
	7z u -tzip partycopy_win64.zip partycopy$(exe) LICENSE
	$(sha256sumA)

linux_package:
	tar -czf partycopy_linux_$(arch).tar.gz partycopy LICENSE
	$(sha256sumA)

install:
	@echo "Please run as sudo/doas."
	mkdir -p /etc/partycopy
	cp partycopy /usr/local/bin
	ln -sf /usr/local/bin/partycopy /usr/local/bin/pcp
	mkdir -p /usr/share/partycopy
	cp LICENSE /usr/share/partycopy

upload:
	$(sha256sumB)
	@echo
	@copyparty_sync
