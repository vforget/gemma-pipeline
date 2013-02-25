#!/bin/bash

usage()
{
cat << EOF
usage: $(basename $0) options *.mgf

Run the GEMMA pipeline.

EXAMPLE:

run_pipeline.sh [-h] [-m file -p file] [options] *.mgf

MGF files are mean genotype files named with a .mgf extension.

-h                  Show this message

Primary options:
-m    [filename]    Relatedness matrix file (required)
-p    [filename]    Phenotype file (required)
-t    [directory]   Temporary directory (optional, default ~/tempdata/)

GEMMA options:
-g    [string]      GEMMA options (optional, default "-lmm 4")
-a    [float]       GEMMA minor allele frequency cutoff (default 0.01)
-n    [float]       GEMMA missigness percent cutoff (default 0.05)

Output options:
-o    [string]      Prefix for output files (optional, default "genome")
-s    [float]       P-value cutoff for top SNPs table (default 5e-06)
-q    [string]      Grid Engine queue to submit jobs (default all.q)

Filter options:
-f                  Apply filters below to plots.
-i    [filename]    Use file to filter SNPs (optional, default no filtering)
-e    [float]       Standard error cutoff value (default 0.01)
-b    [float]       Absolute value of beta cutoff (default 1.5)

EOF
}

# REQUIRED USER PARAMETERS
PHENO_FILE=
MATRIX_FILE=
FILES=

# DEFAULT PARAMETER VALUES
TMPDIR="~/tempdata/"
GEMMA_OPTIONS=""
INFO_FILE=""
RESULT_PREFIX="genome"
FILTER=1
PVALUE_CUTOFF="5e-06"
BETA_CUTOFF="1.5"
BETA_UPPER="1.5"
BETA_LOWER="\-1.5"
SE_CUTOFF="0.01"
GE_QUEUE="all.q"
MAF_CUTOFF="0.01"
MISS_CUTOFF="0.05"

# PARSE AND VALIDATE PARAMETER VALUES
while getopts hm:p:t:g:a:n:o:s:q:fi:e:b: OPTION
do
    case $OPTION in
	h)
	    usage
	    exit
	    ;;
	m)
	    MATRIX_FILE=$OPTARG
	    if [[ ! -r ${MATRIX_FILE} ]]; then
		echo "${progname} -- Matrix file non-existent or non-readable"
		exit 1
	    fi
	    ;;
	p)
	    PHENO_FILE=$OPTARG
	    if [[ ! -r ${PHENO_FILE} ]]; then
		echo "${progname} -- Phenotype file non-existent or non-readable"
		exit 1
	    fi
	    ;;
	i)
	    INFO_FILE=$OPTARG
	    if [[ ! -r ${INFO_FILE} ]]; then
		echo "${progname} -- Filter file non-existent or non-readable"
		exit 1
	    fi
	    ;;
	t)
	    TMPDIR=$OPTARG
	    if [[ ! -d ${TMPDIR} ]]; then
		echo "${progname} -- Temporary directory is non-existent"
		exit 1
	    fi
	    ;;
	g) 
	    GEMMA_OPTIONS=$OPTARG
	    echo $GEMMA_OPTIONS | awk '{ if ($1 ~ /\-(lmm|o)/) exit 1 }'
	    if [ $? -eq 1 ]; then
		echo "${progname} -- Not allowed to change the GEMMA -fa or -o parameter."
		exit 1
	    fi
	    ;;
	o) 
	    RESULT_PREFIX=$OPTARG
	    ;;
	f)
	    FILTER=0
	    ;;
	s) 
	    PVALUE_CUTOFF=$OPTARG
	    echo $PVALUE_CUTOFF | awk '{ if (($1 < 0) || ($1 > 1)) exit 1 }'
	    if [ $? -eq 1 ]; then
		echo "${progname} -- P-value cutoff must be between 0 and 1."
		exit 1
	    fi
	    ;;
	b)
	    BETA_CUTOFF=$OPTARG
	    echo $BETA_CUTOFF | awk '{ if ($1 < 0) exit 1 }'
	    if [ $? -eq 1 ]; then
		echo "${progname} -- Beta cutoff must be >= 0."
		exit 1
	    fi
	    BETA_UPPER=$BETA_CUTOFF
	    BETA_LOWER=$(echo ${BETA_CUTOFF} | awk "{ printf \"%f\", \$0 * -1 }")
	    ;;
	e)
	    SE_CUTOFF=$OPTARG
	    echo $SE_CUTOFF | awk '{ if ($1 < 0) exit 1 }'
	    if [ $? -eq 1 ]; then
		echo "${progname} -- SE cutoff must be >= 0."
		exit 1
	    fi
	    ;;
	q) 
	    GE_QUEUE=$OPTARG
	    ;;
	a) 
	    MAF_CUTOFF=$OPTARG
	    echo $MAF_CUTOFF | awk '{ if ($1 < 0) exit 1 }'
	    if [ $? -eq 1 ]; then
		echo "${progname} -- MAF cutoff must be >= 0."
		exit 1
	    fi
	    ;;
	n) 
	    MISS_CUTOFF=$OPTARG
	    echo $MISS_CUTOFF | awk '{ if ($1 < 0) exit 1 }'
	    if [ $? -eq 1 ]; then
		echo "${progname} -- Missing cutoff must be >= 0."
		exit 1
	    fi
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
echo "Parameters:"
echo -e "\tMATRIX_FILE = $MATRIX_FILE"
echo -e "\tPHENO_FILE = $PHENO_FILE"
echo -e "\tINFO_FILE = $INFO_FILE"
echo -e "\tTMPDIR = $TMPDIR"
echo -e "\tGEMMA_OPTIONS = $GEMMA_OPTIONS"
echo -e "\tRESULT_PREFIX = $RESULT_PREFIX"
echo -e "\tPVALUE_CUTOFF = $PVALUE_CUTOFF"
echo -e "\tBETA_CUTOFF = $BETA_CUTOFF"
echo -e "\tBETA_UPPER = $BETA_UPPER"
echo -e "\tBETA_LOWER = $BETA_LOWER"
echo -e "\tSE_CUTOFF = $SE_CUTOFF"
echo -e "\tGE_QUEUE = $GE_QUEUE"
echo -e "\tMAF_CUTOFF = $MAF_CUTOFF"
echo -e "\tMISS_CUTOFF = $MISS_CUTOFF"
echo -e "\tFILTER = $FILTER"

# INTERNAL PARAMETERS
BINDIR=$(dirname $0)
LOGDIR="log"
SGEDIR="ge_log"
SGE_OPTIONS="-V -cwd -o ${SGEDIR} -e ${SGEDIR} -q ${GE_QUEUE}"
progname=$(basename $0 .bash)
mkdir -p ${LOGDIR}
mkdir -p ${SGEDIR}

JOB_IDS="$RANDOM"

echo "${progname} -- Pipleline started at "`date`

for MGFFILE in ${FILES[@]}
do
    if [ ! -r ${MGFFILE} ]; then
	echo "${progname} -- Genotype file ${MGFFILE} is non-existent."
	exit 1
    fi
    PREFIX=$(basename ${MGFFILE} .mgf)
    DIRNAME=$(dirname ${MGFFILE})
    echo "${progname} -- Processing ${MGFFILE}"
    # STEP 1: Run GEMMA
    cmd="${BINDIR}/gemma.x -lmm 4 -g ${MGFFILE} -a ${DIRNAME}/${PREFIX}.ann -p ${PHENO_FILE} -k ${MATRIX_FILE} -o ${PREFIX} -miss ${MISS_CUTOFF} -maf ${MAF_CUTOFF} ${GEMMA_OPTIONS}"
    echo "${progname} Step 1 Running GEMMA: $cmd"
    echo $cmd | qsub -N gemma_${PREFIX} ${SGE_OPTIONS}
    
    # STEP 2: Clean SNPs for low informativity, etc.
    cmd="${BINDIR}/clean.bash ${PREFIX} ${BETA_UPPER} ${BETA_LOWER} ${SE_CUTOFF} ${FILTER} ${INFO_FILE}"
    echo "${progname} Step 2 Filtering SNPs: $cmd"
    JOB_IDS=${JOB_IDS},$(echo $cmd | qsub -hold_jid gemma_${PREFIX} -N clean_${PREFIX} ${SGE_OPTIONS} | sed 's/^Your job \([0-9]\+\) .*/\1/g');
    
    # STEP 3: Generate graphs for individual files
    cmd="${BINDIR}/graphs.bash ${PREFIX} ${LOGDIR}"
    echo "${progname} Step 3 Generating graphs: $cmd"
    echo $cmd | qsub -hold_jid clean_${PREFIX} -N graphs_${PREFIX} ${SGE_OPTIONS}
done

# STEP 4: Generate results for the whole dataset. Holds until all results from STEP 2 are complete.
cmd="${BINDIR}/results.bash ${RESULT_PREFIX} ${LOGDIR} ${TMPDIR} ${PVALUE_CUTOFF}"
echo "${progname} -- Merging results: $cmd"
echo $cmd | qsub -hold_jid ${JOB_IDS} -N gemma_results ${SGE_OPTIONS}

echo "${progname} -- Pipleline ended at "`date`