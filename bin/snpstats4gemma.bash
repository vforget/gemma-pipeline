#!/bin/bash

# Merge GEMMA results to SNP statistics from QCTOOL.
# Usage:
# qctool4gemma.bash <gemma_in> <bgen_dir>
#
# Where parameters are:
# gemma_in: GEMMA results file. Column #2 should be the SNP name.
# bgen_dir: Directory with QCTOOL snp-stats files. File should be named {1..22}.snp-stats.
#           Column 2 should be the SNP name.
#
# Output: <gemma_in>.snp-stats
#
# Example:
# bash qctool4gemma.bash genome.assoc.txt.clean ~/tempdata/shared/common/t123TUK/imputed/1kGenomes.Phase1/bgen/

gemma_in=$1
bgen_dir=$2

# Split genome-wide GEMMA results per chromosome
echo "Splitting GEMMA results by chromosome:"
rm -f $gemma_in.*
tail -n +2 $1 | awk "{ print \$0 >> \"$gemma_in.\"\$1 }"

# Validate that number of SNPs split is equal to original count
echo "** Lines in input **"
tail -n +2 $gemma_in | wc -l 
echo "** Lines in output **"
wc -l $gemma_in.*

for i in {1..22}
do
    echo "Merging results for chrom $i"
    rm -f $gemma_in.snp-stats.$i
    # Join GEMMA results to QCTOOL snp-stats
    join -t "	" -1 2 -2 2 <(sort -k2,2 $gemma_in.$i) <(tail -n +2 $bgen_dir/$i.snp-stats | sort -k2,2) | sort -k3,3n >> $gemma_in.snp-stats.$i
done

# Header
(head -n 1 $gemma_in | cut -f 1,3-; head -n 1 $bgen_dir/$i.snp-stats  | cut -f 1,3-;) | perl -p -e "s/\n/\t/g;" | awk '{ print "rs\t"$0 }' > $gemma_in.snp-stats
# Merge all chroms
cat $gemma_in.snp-stats.{1..22} >> $gemma_in.snp-stats
rm $gemma_in.snp-stats.*