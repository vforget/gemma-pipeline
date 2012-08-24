#!/usr/bin/python

## Usage: python match_samples.py <target_sample_order_file> <query_phenotype_file>
##
## Re-order a GenABEL sample file according to another sample order (usually in order of colums in SNPTest .gen file).
##
## Output in GEMMA format.
##
## Target sample order is read from a file, one sample name per line. You can generate this easily using:
## $ cut -d ' ' -f 1  chr1.sample | tail -n +3  > target_sample_order.txt
##
## !!!! Missing samples are given a NA phenotype !!!
##
## Query data is in GenABEL format e.g.,:
##  id sqrt2_dif_tc
## 21 21 .9190645
## 22 22 .8813863
## 31 31 .8357955
## 62 62 .8777122
## .. .. ........

import sys

target_sample_order = tuple([x.strip() for x in open(sys.argv[1])])


query_pheno_dat = {}

## !!!! ASSUMES HEADER IN GENABEL PHENO FILE !!!!
for q in tuple([x.strip().split() for x in open(sys.argv[2]).readlines()[1:]]):
    query_pheno_dat[q[1]] = q[2]

for sid in target_sample_order:
    if sid in query_pheno_dat:
        print query_pheno_dat[sid]
    else:
        print "NA"
