#!/bin/bash

FILES=($@)
BINDIR=$(dirname $0)
POOL_SIZE=5
TMPDIR=~/tempdata

mkdir sge_log
for GENFILE in ${FILES[@]}
do
    echo "${BINDIR}/gen2bimbam.bash ${GENFILE} ${TMPDIR} ${POOL_SIZE}" | qsub -V -cwd -pe grinux_pe ${POOL_SIZE} -N g2b${PREFIX} -o sge_log -e sge_log
done