#!/usr/bin/env python

import sys
 
# This code was written by Krzysztof Kowalczyk (http://blog.kowalczyk.info)
# and is placed in public domain.

# Modified by Jason Agress 10/18/2012 to take command line arguments and print 1 if true.
 
def v2fhelper(v, suff, version, weight):
    parts = v.split(suff)
    if 2 != len(parts):
        return v
    version[4] = weight
    version[5] = parts[1]
    return parts[0]
 
# Convert a Mozilla-style version string into a floating-point number
#   1.2.3.4, 1.2a5, 2.3.4b1pre, 3.0rc2, etc
def version2float(v):
    version = [
        0, 0, 0, 0, # 4-part numerical revision
        4, # Alpha, beta, RC or (default) final
        0, # Alpha, beta, or RC version revision
        1  # Pre or (default) final
    ]
    parts = v.split("pre")
    if 2 == len(parts):
        version[6] = 0
        v = parts[0]
 
    v = v2fhelper(v, "a",  version, 1)
    v = v2fhelper(v, "b",  version, 2)
    v = v2fhelper(v, "rc", version, 3)
 
    parts = v.split(".")[:4]
    for (p, i) in zip(parts, range(len(parts))):
        version[i] = p
    ver = float(version[0])
    ver += float(version[1]) / 100.
    ver += float(version[2]) / 10000.
    ver += float(version[3]) / 1000000.
    ver += float(version[4]) / 100000000.
    ver += float(version[5]) / 10000000000.
    ver += float(version[6]) / 1000000000000.
    return ver
 
 
# Return True if ver1 > ver2 using semantics of comparing version
# numbers
def ProgramVersionGreater(ver1, ver2):
    v1f = version2float(ver1)
    v2f = version2float(ver2)
    return v1f > v2f
 
if (ProgramVersionGreater(sys.argv[1], sys.argv[2]) == True):
	print 1
