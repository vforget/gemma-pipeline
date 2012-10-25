#!/bin/bash

GENFILE=$1
TMPDIR=$2
POOL_SIZE=$3
BINDIR=$(dirname $0)

PREFIX=$(basename ${GENFILE} .gen.gz)
mkdir -p ${TMPDIR}/${PREFIX}
zcat ${GENFILE} | ${BINDIR}/gen2bimbam.py ${PREFIX} ${POOL_SIZE} ${TMPDIR}/${PREFIX}
cat $(find ${TMPDIR}/${PREFIX}/ -name "${PREFIX}.*.d" | sort -V) > ${PREFIX}.mgf
rm ${TMPDIR}/${PREFIX}/${PREFIX}.*.d
