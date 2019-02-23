PREFIX?=/usr/local
MAN1?=${PREFIX}/share/man/man1

build:
	swift build --disable-sandbox -c release -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

install: build
	mkdir -p ${PREFIX}/bin
	cp -f .build/release/cbeacon ${PREFIX}/bin/
	cp -f man/cbeacon.1 ${MAN1}/

clean:
	swift package clean
	rm -rf .build
