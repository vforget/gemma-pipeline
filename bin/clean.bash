#!/bin/bash

PREFIX=$1
BETA_UPPER=$2
BETA_LOWER=$3
SE_LIMIT=$4
FILTER=$5
INFO_FILE=$6
GEMMA_RES="output/${PREFIX}.assoc.txt"

# Get header

if [ $FILTER -eq 1 ]; then
    ln -s ${PREFIX}.assoc.txt ${GEMMA_RES}.clean
    exit
fi

if [[ -n $INFO_FILE ]]; then
    head -n 1 ${GEMMA_RES} > ${GEMMA_RES}.clean
    tail -n +2 ${GEMMA_RES} | sort -k2,2 | \
	join -1 2 -2 1 - ${INFO_FILE} | \
	awk '{ print $2, $1, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12 }' | \
	awk "{ if ( (\$6 >= ${BETA_LOWER}) && (\$6 <= ${BETA_UPPER}) && (\$7 >= ${SE_LIMIT}) ) print \$0 }" \
	>> ${GEMMA_RES}.clean

else
    head -n 1 ${GEMMA_RES} > ${GEMMA_RES}.clean
    tail -n +2 ${GEMMA_RES} | sort -k2,2 | \
	awk "{ if ( (\$6 >= ${BETA_LOWER}) && (\$6 <= ${BETA_UPPER}) && (\$7 >= ${SE_LIMIT}) ) print \$0 }" \
	>> ${GEMMA_RES}.clean  
fi

# rm ${GEMMA_RES}