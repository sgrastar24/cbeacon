PREFIX?=/usr/local
MAN1?=${PREFIX}/share/man/man1

build:
	swift build -c release -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

install: build
	mkdir -p ${PREFIX}/bin
	cp -f .build/release/cbeacon ${PREFIX}/bin/
	cp -f man/cbeacon.1 ${MAN1}/
