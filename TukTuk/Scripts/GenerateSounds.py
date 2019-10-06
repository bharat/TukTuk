#!/usr/bin/env python
# -*- coding: utf-8 -*-
#  GenerateSounds.py
#  TukTuk
#
#  Created by Bharat Mediratta on 10/5/19.
#  Copyright © 2019 Menalto. All rights reserved.

import os
import re

def main():
    lines = []
    for dirName, subdirList, fileList in os.walk('TukTuk/Media'):
        for fname in fileList:
            full = dirName + '/' + fname
            match = re.match('^TukTuk/Media/(.*?)/Audio/(.*).mp3$', full)
            if match:
                lines.append('\tstatic let %(cat)s_%(name)s = Media.%(cat)s.sound("%(name)s")' % { 'cat': match.group(1), 'name': match.group(2) })

    print('extension Sound {')
    for line in sorted(lines):
        print(line)
    print('}')

if __name__ == '__main__':
    main()
