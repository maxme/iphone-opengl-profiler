#!/bin/sh

if [ "$1"x = x ]; then
    echo "Usage: $0 FILE"
    echo "Example: $0 glFunctions.txt"
    exit 1
fi

# Header
echo "set breakpoint pending on"

for i in $(cat $1); do
    echo break $i
    echo commands
    echo silent
    echo frame 1
    echo c
    echo end
done

# Footer
echo "c"