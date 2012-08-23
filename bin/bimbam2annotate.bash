#!/bin/bash

FILES=($@)

for GENFILE in ${FILES[@]}
do
    # This variant works when the chromosome number is in the file name e.g. chr22.gen
    BASE=$(basename ${GENFILE} .gen)
    CHROM=`echo ${GENFILE} | perl -p -e "s/.*chr([0-9XY]+).*/\1/;"`
    awk "{ print \$2\",\"\$3\",\"${CHROM} }" ${GENFILE} > ${BASE}.ann
    
    # This variant work with MGF files, and only works when snp is named #-######, e.g. 9-1200000
    # BASE=$(basename ${MGFFILE} .gen)
    # perl -p -e "s/(^[0-9]+)\-([0-9]+).*/\1-\2,\2,\1/g;" ${MGFFILE} > ${BASE}.ann
done
