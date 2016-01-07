#!/usr/bin/env python3

import os
import sys
from os.path import dirname

# import from 'cmdtest.py' in other directory
sys.path.insert(0, dirname(dirname(os.path.abspath(__file__))))
from cmdtest import cmdtest_in_dir, Statistics

def main():
    dirpath = sys.argv[1]
    statistics = cmdtest_in_dir(dirpath)
    print(statistics)
    exit(0 if statistics.errors == 0 and statistics.fatals == 0 else 1)

if __name__ == '__main__':
    main()
