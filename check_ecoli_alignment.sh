#!/bin/bash

set -u
set -e

### SANITY CHECKS ###
if [ $# -ne 1 ] || [ ! -d $1 ]; then
	echo "Usage: check_ecoli_alignment <input folder>"
	exit 1
fi

### VARIABLES ###
INFOLDER=$1
BWA=~/bin/bwa
SAMTOOLS=/usr/bin/samtools
WORKING_DIR=$(mktemp -d temp.XXXX)
REF_DIR=$(mktemp -d temp.XXXX)
REF_LINK=http://ftp-private.ncbi.nlm.nih.gov/genomes/refseq/bacteria/Escherichia_coli/reference/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz
REF_PATH=$REF_DIR/ecoli_ref.fasta


### FUNCTIONS ###
function finish {
	rm -rv $REF_DIR
	rm -rv $WORKING_DIR
}


### TRAPS ###
trap finish EXIT ERR INT


### MAIN LOOP ###

wget -O - $REF_LINK | gunzip -c > $REF_PATH
$BWA index $REF_PATH

for fwd_read in $(find $INFOLDER -name "*_1.fastq.gz"); do
	rev_read=${fwd_read/_1.fastq.gz/_2.fastq.gz}
	samfile=$WORKING_DIR/$(basename ${fwd_read%_1.fastq.gz}).sam
	bamfile=$WORKING_DIR/$(basename ${fwd_read%_1.fastq.gz}).bam

	$BWA mem -t 16 -M -R '@RG\tID:foo\tSM:bar' $REF_PATH $fwd_read $rev_read > $samfile
	$SAMTOOLS view -bS $samfile | $SAMTOOLS sort - ${bamfile%.bam}
	NO_POSTS=$($SAMTOOLS view -c $bamfile)
	NO_ALIGNED=$($SAMTOOLS view -c -F 4 $bamfile)
	echo ${bamfile%.bam} $NO_POSTS $NO_ALIGNED >> results.log
	 	
done
