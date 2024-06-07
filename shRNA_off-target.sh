#!/bin/bash

# Introduction and user instructions for file format
echo "Welcome to the shRNA off-target analysis script."
echo "Please ensure your input file is formatted with two columns in .txt file:"
echo "  1st column: Sequence Name or ID"
echo "  2nd column: Sequence (DNA/RNA)"
echo "Example:"
echo "  ID001 ATGCGTACGTAGCTAGCT"
echo "  ID002 CGTAGCTAGCTAGCTAAC"
echo "Please enter the name of your guide sequence file:"
read input_file
mkdir output
## running the shRNA analysis
echo "--Converting your input file into fasta format!"

# Use the user-provided file name
awk '{print ">"$1"\n"$2}' $input_file > output/guide_seqs.fasta

echo "--shRNA off-target analysis Started!"
blastn -task blastn-short -db db/mouse_genomes -query output/guide_seqs.fasta -dust no -ungapped -parse_deflines -evalue 1000 -outfmt "6 qseqid sseqid length mismatch gapopen qstart qend sstart send evalue bitscore sstrand" | grep minus | awk '($4<1 && $6<6 && $3>7){print}'> output/Blast_results.txt
blastn -task blastn-short -db db/mouse_genomes -query output/guide_seqs.fasta -dust no -ungapped -parse_deflines -evalue 1000 -out output/Blast_results_with_details.txt
Rscript processing_blast_results.R
echo "--shRNA off-target analysis Finished!"
echo "--Please find your results in excel file-Final report.xlsx!"

