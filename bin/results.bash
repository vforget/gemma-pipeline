#!/bin/bash

PREFIX=$1
LOGDIR=$2
TMPDIR=$3
P_VALUE=$4
BINDIR=$(dirname $0)

RESULT_FILE=${PREFIX}.assoc.txt.clean

head -n 1 `ls output/*.assoc.txt.clean | head -n 1` > ${RESULT_FILE}
tail -q -n +2 output/*.assoc.txt.clean | sort -T ${TMPDIR} -k 1n,1 -k 3n,3 >> ${RESULT_FILE}

cat > ${LOGDIR}/results_${PREFIX}.r << EOT
library(gap)

res = read.table("${RESULT_FILE}", header=T)
png(filename="qqplot_${PREFIX}.png", width=480, height=480)
par(lty=3)
qqunif(res\$p_score, pch=20, col="#6699CC", lcol=1, ci=T, main=paste(c(length(res\$p_score), " SNPs"),sep=" ", collapse=""))
dev.off()

png("boxplots_${PREFIX}.png", width=480, height=480)
par(mfrow=c(1,2))

b = boxplot(res\$beta, plot=F); 
boxplot(res\$beta, outline=F, ylim=c(min(b\$out), max(b\$out)), boxwex=0.5, main="Beta")
points(rep(1,length(b\$out)), b\$out, pch=20, col="#6699CC")

b = boxplot(res\$se, plot=F); 
boxplot(res\$beta, outline=F, ylim=c(min(b\$out), max(b\$out)), boxwex=0.5, main="SE")
points(rep(1,length(b\$out)), b\$out, pch=20, col="#6699CC")
dev.off()

source("${BINDIR}/manhattan.r")
png("mhtplot_${PREFIX}.png", width=10, height=13, unit="in", res=200)
e=data.frame(SNP=res\$rs, CHR=res\$chr, BP=res\$ps, P=res\$p_score)
manhattan(e)
dev.off()
quit()
EOT

R --no-save < ${LOGDIR}/results_${PREFIX}.r &> ${LOGDIR}/results_${PREFIX}.log

# TOP SNPs

head -n 1 ${RESULT_FILE} > ${RESULT_FILE}.top_snps
awk "{ if (\$11 <= ${P_VALUE}) print \$0 }" ${RESULT_FILE} >> ${RESULT_FILE}.top_snps
