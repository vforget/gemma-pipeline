#!/bin/bash


PREFIX=$1
INFO_FILE=$2
TMPDIR=$3

GEMMA_RES="output/${PREFIX}.assoc.txt"
# Get header
head -n 1 ${GEMMA_RES} > ${GEMMA_RES}.clean
# Sort by SNP name
tail -n +2 ${GEMMA_RES} | sort -k2,2 > ${GEMMA_RES}.sort
# Filter for informativity >= 0.4
join -1 2 -2 1 ${GEMMA_RES}.sort ${INFO_FILE} | awk '{ print $2, $1, $3, $4, $5, $6, $7, $8, $9, $10, $11 }' | sort -k2,2 >> ${GEMMA_RES}.clean
# Delete tmp file(s)
rm ${GEMMA_RES}.sort

