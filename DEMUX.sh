#!/bin/bash

set -u

if [[ ("$#" -ne 1) || ($1 == '-h') ]]; then
    echo "Usage: DEMUX.sh [runfolder]"
    exit 1
fi

#Change these as it strikes your fancy
SBATCH=/proj/b2012050/run_deplex.sh
BCL2FASTA=/sw/apps/bioinfo/CASAVA/1.8.2/kalkyl/bin/configureBclToFastq.pl


RUNFOLDER=$1
SAMPLESHEET=${RUNFOLDER}/SampleSheet.csv
DEMUXSHEET=${RUNFOLDER}/deplex_sheet.csv

IFS='_' read -r -a arr <<< "$RUNFOLDER"
FCID=${arr[@]: -1:1}


#Sanitize samplesheet
sed -i 's/^M/\n/g; s/ //g' $SAMPLESHEET 


awk -F, -v OFS=',' -v FCID=${FCID%/} 'BEGIN {print "FCID,Lane,SampleID,SampleRef,Index,Description,Control,Recipe,Operator,SampleProject"} \
    {if (NR>17) print FCID, 1, $1, "hg19", $6"-"$8, $5, "N", "R1", "MS", $5 }' $SAMPLESHEET > $DEMUXSHEET


$BCL2FASTA --input-dir ${RUNFOLDER}/Data/Intensities/BaseCalls \
            --output-dir ${RUNFOLDER}/Unaligned \
            --sample-sheet $DEMUXSHEET \
            --use-bases-mask Y300n,I8,I8,Y300n


#Change permissions
find ${RUNFOLDER} -type d -exec chmod g+x {} \;
chmod -R g+rw ${RUNFOLDER}


#copy sbatch script
cp $SBATCH ${RUNFOLDER}


#run job
sbatch ${RUNFOLDER}/$(basename $SBATCH)
