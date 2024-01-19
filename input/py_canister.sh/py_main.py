#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import datetime
import sys

import pytz
import tzlocal

#import pkg_structure

def main():
    """
    ____@@NAME@@____
    Example code skeleton: Just greeting
    """
    argpsr = argparse.ArgumentParser(description='Example: showing greeting words')
    argpsr.add_argument('name', nargs='*', type=str, default=['World'],  help='your name')
    argpsr.add_argument('-d', '--date', action='store_true', help='Show current date & time')
    args = argpsr.parse_args()
    if args.date:
        tz_local = tzlocal.get_localzone()
        datestr  = datetime.datetime.now(tz=tz_local).strftime(" It is \"%c.\"")
    else:
        datestr = ''

    print("Hello, %s!%s" % (' '.join(args.name), datestr))
    print("Python : %d.%d.%d " % sys.version_info[0:3]+ "(%s)" % sys.executable)
    hdr_str = "Python path: "
    for i,p in enumerate(sys.path):
        print("%-2d : %s" % (i+1, p))
        hdr_str = ""

    #pkg_info   = pkg_structure.PkgStructure(script_path=sys.argv[0])
    #pkg_info.dump(relpath=False, with_seperator=True)

if __name__ == '__main__':
    main()

