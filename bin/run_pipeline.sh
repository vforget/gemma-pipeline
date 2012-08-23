#!/bin/bash

# USER PARAMETERS
#PHENO_FILE="~/share/vince.forgetta/0812-gemma-pipeline/pheno/pheno.txt"
#MATRIX_FILE="~/share/vince.forgetta/0812-gemma-pipeline/matrix/317k/merge.bimbam.cXX.txt"
#GEMMA_OPTIONS="-fa 4"
#INFO_FILE="~/share/vince.forgetta/0712-probabel-pipeline/static/tuk.info_0.4"
#TMPDIR="~/tempdata/"



usage()
{
cat << EOF
usage: $0 options *.mgf

Run GEMMA pipeline.

EXAMPLE:

run_pipeline.sh [options] *.mgf

MGF files are mean genotype files named with a .mgf extension.

OPTIONS:
-h                  Show this message
-m    [filename]    Relatedness matrix file
-p    [filename]    Phenotype file
-i    [filename]    Informative SNPs file
-t    [directory]   Temporary directory

** All options are required (except -h) **

EOF
}

# USER PARAMETERS
PHENO_FILE=
MATRIX_FILE=
INFO_FILE=
TMPDIR=
GEMMA_OPTIONS="-fa 4"
FILES=

while getopts “h:m:p:i:t:f:” OPTION
do
    case $OPTION in
	h)
	    usage
	    exit
	    ;;
	m)
	    MATRIX_FILE=$OPTARG
	    ;;
	p)
	    PHENO_FILE=$OPTARG
	    ;;
	i)
	    INFO_FILE=$OPTARG
	    ;;
	t)
	    TMPDIR=$OPTARG
	    ;;
	\?)
	    usage
	    exit
	    ;;
    esac
done

shift $((OPTIND-1))
FILES=($@)

if [[ -z $PHENO_FILE ]] || [[ -z $MATRIX_FILE ]] || [[ -z $INFO_FILE ]] || [[ -z $TMPDIR ]] || [[ -z $FILES ]]
then
    usage
    exit 1
fi

# STATIC PARAMETERS
BINDIR=$(dirname $0)
LOGDIR="log"
SGE_OPTIONS="-V -cwd -o sge_log -e sge_log"

mkdir -p ${LOGDIR}
mkdir -p sge_log

JOB_IDS=""
for MGFFILE in ${FILES[@]}
do
    PREFIX=$(basename ${MGFFILE} .mgf)
    DIRNAME=$(dirname ${MGFFILE})
    
    # STEP 1: Run GEMMA
    echo "${BINDIR}/gemma -g ${MGFFILE} -a ${DIRNAME}/${PREFIX}.ann -p ${PHENO_FILE} -k ${MATRIX_FILE} -o ${PREFIX} ${GEMMA_OPTIONS}" | qsub -N gemma_${PREFIX} ${SGE_OPTIONS}
    
    # STEP 2: Clean SNPs for low informativity, etc.
    JOB_IDS=${JOB_IDS},$(echo "${BINDIR}/clean.bash ${PREFIX} ${INFO_FILE} ${TMPDIR}" | qsub -hold_jid gemma_${PREFIX} -N clean_${PREFIX} ${SGE_OPTIONS} | sed 's/^Your job \([0-9]\+\) .*/\1/g');
    
    # STEP 3: Generate graphs for individual files
    echo "${BINDIR}/graphs.bash ${PREFIX} ${LOGDIR}" | qsub -hold_jid clean_${PREFIX} -N  graphs_${PREFIX} ${SGE_OPTIONS}
done

# STEP 4: Generate results for the whole dataset. Holds until all results from STEP 2 are complete.
if [ -z "$JOB_IDS" ]; then
    echo "${BINDIR}/results.bash results ${LOGDIR} ${TMPDIR}" | qsub -N gemma_results ${SGE_OPTIONS}
else
    echo "${BINDIR}/results.bash results ${LOGDIR} ${TMPDIR}" | qsub -hold_jid ${JOB_IDS} -N gemma_results ${SGE_OPTIONS}
fi
