#!/bin/sh
grep "gl.*;"|tr "\t" " "|tr -s " "| cut -d " " -f 2
