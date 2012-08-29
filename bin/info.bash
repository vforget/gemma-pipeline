#!/bin/bash

INFO_FILES=($@)
INFO_MIN_FREQ=0.4
TMPDIR=~/tempdata

tail -q -n +2 ${INFO_FILES[@]} | awk "{ if (\$5 >= ${INFO_MIN_FREQ}){ print \$2 }}" | sort -k1,1 -T ${TMPDIR}