#!/bin/bash

PREFIX=$1
LOGDIR=$2

GEMMA_RES="output/${PREFIX}.assoc.txt.clean"

cat > ${LOGDIR}/graphs_${PREFIX}.r << EOT
library(gap)
res = read.table("${GEMMA_RES}", header=T)
png(filename="qqplot_${PREFIX}.png", width=480, height=480)
par(lty=3)
qqunif(res\$p_score, pch=20, col="#6699CC", lcol=1, ci=T, main=paste(c(length(res\$p_score), " SNPs"),sep=" ", collapse=""))
dev.off()

png("boxplots_${PREFIX}.png", width=480, height=480)
par(mfrow=c(1,2))

b = boxplot(res\$beta, plot=F); 
boxplot(res\$beta, outline=F, ylim=c(min(b\$out), max(b\$out)), boxwex=1, main="Beta")
points(rep(1,length(b\$out)), b\$out, pch=20, col="#666666")

b = boxplot(res\$se, plot=F); 
boxplot(res\$beta, outline=F, ylim=c(min(b\$out), max(b\$out)), boxwex=1, main="SE")
points(rep(1,length(b\$out)), b\$out, pch=20, col="#666666")
dev.off()

quit()
EOT

R --no-save < ${LOGDIR}/graphs_${PREFIX}.r &> ${LOGDIR}/graphs_${PREFIX}.log