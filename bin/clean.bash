#!/bin/bash


PREFIX=$1
INFO_FILE=$2

GEMMA_RES="output/${PREFIX}.assoc.txt"
BETA_LOWER=-1.5
BETA_UPPER=1.5
SE_LIMIT=0.01

# Get header
if [[ -z $INFO_FILE ]]; then
    head -n 1 ${GEMMA_RES} > ${GEMMA_RES}.clean
    tail -n +2 ${GEMMA_RES} | sort -k2,2 | \
	awk "{ if ( (\$5 >= ${BETA_LOWER}) && (\$5 <= ${BETA_UPPER}) && (\$6 >= ${SE_LIMIT}) ) print \$0 }" \
	>> ${GEMMA_RES}.clean
else
    head -n 1 ${GEMMA_RES} > ${GEMMA_RES}.clean
    tail -n +2 ${GEMMA_RES} | sort -k2,2 | \
	join -1 2 -2 1 - ${INFO_FILE} | \
	awk '{ print $2, $1, $3, $4, $5, $6, $7, $8, $9, $10, $11 }' | \
	awk "{ if ( (\$5 >= ${BETA_LOWER}) && (\$5 <= ${BETA_UPPER}) && (\$6 >= ${SE_LIMIT}) ) print \$0 }" \
	>> ${GEMMA_RES}.clean
fi

