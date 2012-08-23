#!/bin/bash

FILES=($@)

for MGFFILE in ${FILES[@]}
do
    BASE=$(basename ${MGFFILE} .mgf)
    perl -p -e "s/(^[0-9]+)\-([0-9]+).*/\1-\2,\2,\1/g;" ${MGFFILE} > ${BASE}.ann
done
