#
# Configuration
#

# Repository
OWNER=sgrastar24
REPO=cbeacon

# Build info
BUILD_DIR=.build

# Path info
PREFIX?=/usr/local
MAN1?=$(PREFIX)/share/man/man1

#
# Rules
#

build:
	swift build --disable-sandbox -c release -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

install: build
	mkdir -p $(PREFIX)/bin
	cp -f $(BUILD_DIR)/release/cbeacon $(PREFIX)/bin/
	cp -f man/cbeacon.1 $(MAN1)/

xcodeproj:
	swift package generate-xcodeproj

clean:
	swift package clean
	rm -rf $(BUILD_DIR)

sha256: VERSION=$(shell git tag -l '*.*.*' | tail -n 1)
sha256:
	@echo VERSION=${VERSION}
	(curl -f -L https://github.com/sgrastar24/cbeacon/archive/refs/tags/${VERSION}.tar.gz | shasum -a 256)

