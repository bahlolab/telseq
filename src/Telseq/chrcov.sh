#!/bin/bash

# Check if correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <input.bam> <intermediate_output.txt> <final_output.txt>"
    exit 1
fi

# Assign arguments
BAM_FILE="$1"
INTERMEDIATE_OUTPUT="$2"
FINAL_OUTPUT="$3"

# Check if input BAM file exists
if [ ! -f "$BAM_FILE" ]; then
    echo "Error: BAM file '$BAM_FILE' not found!"
    exit 1
fi

# Run samtools idxstats and save output to intermediate file
echo "Running samtools idxstats on $BAM_FILE..."
samtools idxstats "$BAM_FILE" > "$INTERMEDIATE_OUTPUT"

# Check if samtools idxstats was successful
if [ $? -ne 0 ]; then
    echo "Error: samtools idxstats failed!"
    exit 1
fi

echo "Chromosome coverage saved to $INTERMEDIATE_OUTPUT"

# Run R script in the cwd for further processing, with specified output file
echo "Running chr_calc.R with $INTERMEDIATE_OUTPUT..."
Rscript chr_calc.R "$INTERMEDIATE_OUTPUT" "$FINAL_OUTPUT"

# Check if R script executed successfully
if [ $? -ne 0 ]; then
    echo "Error: R script execution failed!"
    exit 1
fi

echo "Analysis completed successfully! Final results saved to $FINAL_OUTPUT"
