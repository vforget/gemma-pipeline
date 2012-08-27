#!/bin/bash

usage()
{
cat << EOF
usage: $(basename $0) options *.mgf

Run GEMMA pipeline.

EXAMPLE:

run_pipeline.sh [-h] [-m file -p file] [options] *.mgf

MGF files are mean genotype files named with a .mgf extension.

OPTIONS:

-h                  Show this message
-m    [filename]    Relatedness matrix file (required)
-p    [filename]    Phenotype file (required)

-i    [filename]    Informative SNPs file (optional, default no filtering)
-t    [directory]   Temporary directory (optional, default ~/tempdata/)
-g    [string]      GEMMA options (optional, default "-fa 4")
-o    [string]      Prefix for output files (optional, default "genome")

EOF
}

# REQUIRED USER PARAMETERS
PHENO_FILE=
MATRIX_FILE=
FILES=
# OPTIONAL USER PARAMETERS
TMPDIR="~/tempdata/"
GEMMA_OPTIONS="-fa 4"
INFO_FILE=
RESULT_PREFIX="genome"

# PARSE PARAMETERS
while getopts “h:m:p:i:t:f:g:o:” OPTION
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
	g) 
	    GEMMA_OPTIONS=$OPTARG
	    ;;
	o) 
	    RESULT_PREFIX=$OPTARG
	    ;;
	\?)
	    usage
	    exit
	    ;;
    esac
done

shift $((OPTIND-1))
FILES=($@)

if [[ -z $PHENO_FILE ]] || [[ -z $MATRIX_FILE ]] || [[ -z $FILES ]]
then
    usage
    exit 1
fi

echo "MATRIX_FILE = $MATRIX_FILE"
echo "PHENO_FILE = $PHENO_FILE"
echo "INFO_FILE = $INFO_FILE"
echo "TMPDIR = $TMPDIR"
echo "GEMMA_OPTIONS = $GEMMA_OPTIONS"
echo "RESULT_PREFIX = $RESULT_PREFIX"
# INTERNAL PARAMETERS
BINDIR=$(dirname $0)
LOGDIR="log"
SGE_OPTIONS="-V -cwd -o sge_log -e sge_log -q all.q"

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
    JOB_IDS=${JOB_IDS},$(echo "${BINDIR}/clean.bash ${PREFIX} ${INFO_FILE}" | qsub -hold_jid gemma_${PREFIX} -N clean_${PREFIX} ${SGE_OPTIONS} | sed 's/^Your job \([0-9]\+\) .*/\1/g');
    
    # STEP 3: Generate graphs for individual files
    echo "${BINDIR}/graphs.bash ${PREFIX} ${LOGDIR}" | qsub -hold_jid clean_${PREFIX} -N  graphs_${PREFIX} ${SGE_OPTIONS}
done

# STEP 4: Generate results for the whole dataset. Holds until all results from STEP 2 are complete.
if [ -z "$JOB_IDS" ]; then
    echo "${BINDIR}/results.bash ${RESULT_PREFIX} ${LOGDIR} ${TMPDIR}" | qsub -N gemma_results ${SGE_OPTIONS}
else
    echo "${BINDIR}/results.bash ${RESULT_PREFIX} ${LOGDIR} ${TMPDIR}" | qsub -hold_jid ${JOB_IDS} -N gemma_results ${SGE_OPTIONS}
fi
