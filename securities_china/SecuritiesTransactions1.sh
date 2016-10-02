#!/usr/bin/bash

ls /cygdrive/c/Users/riverlei/Documents/*资金流水查询.xls | xargs awk '$2 ~ /^="[0-9]{6}/{print $1,$2,$4,$5,$6,$7,$8}' | iconv -f GBK -t UTF-8 | sed 's/"//g' | sed 's/=//g'
