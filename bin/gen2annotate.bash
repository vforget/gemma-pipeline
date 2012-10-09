#!/bin/bash

# Script only works when the chromosome number is in the file name e.g. chr22.gen or 22.gen

FILES=($@)
REGEXP="[0-9]+"
for GENFILE in ${FILES[@]}
do
    BASE=$(basename ${GENFILE} .gen)
    CHROM=
    # Try to parse chrom number from filename
    if [[ ${BASE} =~ ^[0-9]+$ ]]; then
	CHROM=$BASE
    else
	CHROM=`echo ${GENFILE} | perl -p -e "s/.*chr([0-9]+).*/\1/;"`
    fi
    
    # Test that parsing was suscessful
    if [[ ! ${CHROM} =~ ^[0-9]+$ ]]; then
	echo "Could not parse chromosome number from filename: ${GENFILE}"
	exit
    fi
    
    # if parsing was OK, generate annotation file
    awk "{ print \$2\",\"\$3\",${CHROM}\" }" ${GENFILE} > ${BASE}.ann
    
done
