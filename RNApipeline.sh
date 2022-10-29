#!/bin/bash

## RNApipeline.sh

# Gong lab bulk RNA-Seq pipeline (strand specific & PE fastqs) 
# Mon Oct 24 21:47:59 2022 ZY

## This pipeline assume clean fastq inputs and only perform two key steps of RNA-Seq analysis, i.e., alignment and reads counting;
## input 1. fastq files (PE absolute path); 2. destinated folder (should be exist); 3. ref index path (absolute path); 4. sample ID; 5. threads (default 4; optional); 6. gtf file
## 
## For reference genome, you can used pre-indexed refs for hg38 and mm10:
## hg38 pre-built index: /public/home/gonglianggroup/Gonglab/software/hg38/STAR_index
## mm10 pre-built index: /public/home/gonglianggroup/Gonglab/software/mm10/STAR_Index

## Usage:
## RNApipeline.sh -1 fastq1 -2 fastq2 -o outdir -r hg38 -s A1 -t 8 -g hg38.gtf
## make sure STAR and htseq-count in your env path



helpFunc()
{
	echo ""
 	echo "Usage: ./RNApipeline.sh -1 <input abs path fastq1> -2 <input abs path fastq2> -o <output directory> -r <ref index path> -s <sample ID string> -t <thread default 4> -g <gtf annotation> -h <showing this message>"
 	echo ""
 }



thread=4
while getopts "1:2:o:r:s:t:g:h" opt; do
  case $opt in
    1 ) fastq1="$OPTARG"
    ;;
    2 ) fastq2="$OPTARG"
    ;;
    o ) output="$OPTARG"
    ;;
    r ) refindex="$OPTARG"
    ;;
    s ) sample="$OPTARG"
    ;;
    t ) thread="$OPTARG"
    ;;
    g ) gtf="$OPTARG"
    ;;
    h ) helpFunc ; exit 0
    ;;
    \? )
     echo "Invalid Option" 
     exit 1
    ;;
  esac
done


if [[ $(($# / 2)) -lt 6 ]]; then
	echo ""
  	echo "only $(($# / 2)) arguments listed"
  	helpFunc
  	exit 2
fi


if [ -d ${fastq1} ] || [ -d ${fastq2} ] || [ -d ${gtf} ]; then
	echo ""
	echo "Please input absolute path for fastq files and gtf file; not just folder"
	helpFunc
	exit 2
fi


if [[ ! -d ${output} ]]; then
  echo ""
  echo "output folder: ${output} doesn't exist"
  helpFunc
  exit 2
fi


echo ${fastq1}
echo ${fastq2}
echo ${output}
echo ${refindex}
echo ${sample}
echo ${thread}
echo ${gtf}


echo "Start running STAR......"

cd ${output}
STAR --runThreadN ${thread} --genomeDir ${refindex} \
--readFilesIn ${fastq1} ${fastq2} --readFilesCommand zcat --limitBAMsortRAM 44178937863 --outFileNamePrefix ${sample} \
--outSAMtype BAM SortedByCoordinate --outSAMattrRGline ID:Gong PU:MGI SM:${sample} --outFilterType BySJout --alignMatesGapMax 1000000 \
--outFilterIntronMotifs RemoveNoncanonical --seedSearchStartLmax 50 --alignIntronMin 21 --alignIntronMax 1000000 --alignSJoverhangMin 8 \
--alignSJDBoverhangMin 1 --chimSegmentMin 15 chimSegmentReadGapMax 0 --quantMode TranscriptomeSAM GeneCounts --twopassMode Basic &&

echo "STAR alignment completed....."
echo "Start counting....."

htseq-count \
-f bam ${sample}Aligned.sortedByCoord.out.bam ${gtf} -s reverse -m union > ${sample}_htseq.counts &&

echo "Counting finished....."



