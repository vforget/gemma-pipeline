#!/bin/bash

FILES=($@)
REGEXP="[0-9]+"
for GENFILE in ${FILES[@]}
do
    # This variant works when the chromosome number is in the file name e.g. chr22.gen
    BASE=$(basename ${GENFILE} .gen)
    CHROM=
    # Try to parse chrom number from filename
    if [[ ${BASE} =~ [0-9]+ ]]; then
	CHROM=$BASE
    else
	CHROM=`echo ${GENFILE} | perl -p -e "s/.*chr([0-9]+).*/\1/;"`
    fi
    
    # Test that parsing was suscessful
    if [[ ! ${CHROM} =~ [0-9]+ ]]; then
	echo "Could not parse chromosome number from filename: ${GENFILE}"
	exit(1)
    fi
    
    # if parsing was OK, generate annotation file
    awk "{ print \$2\",\"\$3\",\"${CHROM} }" ${GENFILE} > ${BASE}.ann
    
    # This variant work with MGF files, and only works when snp is named #-######, e.g. 9-1200000
    # BASE=$(basename ${MGFFILE} .gen)
    # perl -p -e "s/(^[0-9]+)\-([0-9]+).*/\1-\2,\2,\1/g;" ${MGFFILE} > ${BASE}.ann
done
