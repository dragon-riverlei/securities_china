#!/usr/bin/bash

ls /cygdrive/c/Users/riverlei/Documents/*.xls | xargs awk '$2 !~ /^="[0-9]{6}/{print $1,$4,$5,$6}' | iconv -f GBK -t UTF-8 | sed 's/"//g' | sed 's/=//g' | awk '$1 ~ /[0-9]{8}/{print}'
