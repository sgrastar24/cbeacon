swift build -c release -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"
cp -i .build/release/cbeacon /usr/local/bin/
