#!/bin/sh

if [ "$1"x = x ]; then
    echo "Usage: $0 FILE.app/binary"
    echo "Example: $0 build/Debug-iphonesimulator/TestGL.app/TestGL"
    exit 1
fi

otool -tVv $1 |grep " _gl[A-Z]"|tr -s " " | cut -d " " -f 5|sed "s/_//"|sort |uniq
