#!/usr/bin/env python

import sys
import json
import pprint

while True:
  line = sys.stdin.readline()
  data = json.loads(line)
  pprint.pprint(data)
  print
