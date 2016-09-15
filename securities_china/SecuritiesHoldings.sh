#!/usr/bin/bash

cat /cygdrive/c/Users/riverlei/Documents/资金股份查询.xls | awk '$1 ~ /^="[0-9]{6}/{print gensub(/="([0-9]{6})"$/, "\\1", "g", $1), $3, $5, $6}'
