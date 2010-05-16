#!/usr/bin/env python

import sys
import re
from pprint import pprint

funcre = re.compile("[0-9]+\s+((gl[^\(]+)\((.*)\))")

def analyze_GLStates(data):
    enabled = []
    disabled = []
    allEnabled = []
    allDisabled = []
    for i in data:
        if "Enable" in i[0]:
            enabled.append(i[0])
            allEnabled.append(i[0])
            dis = i[0].replace("Enable", "Disable")
            if dis in disabled:
                disabled.remove(dis)
            else:
                #print "useless: ", i[0], i [2]
                pass
        if "Disable" in i[0]:
            disabled.append(i[0])
            allDisabled.append(i[0])
            en = i[0].replace("Disable", "Enable")
            if en in enabled:
                enabled.remove(en)
            else:
                #print "useless: ", i[0], i [2]
                pass

    print "Useless gl*Enable*: %d/%d" % (len(enabled), len(allEnabled))
    print "Useless gl*Disable*: %d/%d" % (len(disabled), len(allDisabled))

def count_GLDraw(data):
    draws = {}
    for i in data:
        if "gl" in i[1]:
            if i[1] in draws:
                draws[i[1]] += 1
            else:
                draws[i[1]] = 1
    l = draws.items()
    l.sort(key=lambda x:x[1], reverse=True)
    pprint(l)

def analyze_list(l):
    # parse data
    data = []
    for i, j in zip(l, l[1:]):
        match = funcre.match(j)
        if match:
            full = match.group(1)
            funcName = match.group(2)
            args = match.group(3)
            if args:
                args = args.split(",")
            data.append((full, funcName, i, args))

    # check useless Enable / Disable
    analyze_GLStates(data)
    count_GLDraw(data)

def analyze(stream):
    res = []
    for i in stream.readlines():
        res.append(i.strip())
    analyze_list(res)

if __name__ == "__main__":
    if len(sys.argv) == 2:
        analyze(open(sys.argv[1]))
    else:
        print "Analyzing stdin"
        analyze(sys.stdin)

