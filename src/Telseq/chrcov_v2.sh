#!/bin/bash
chmod +x "$0"

# Initialize variable for telseq command
TELSEQ_COMMAND=""

# Check if the number of arguments is correct
if [ "$#" -lt 4 ]; then
    echo "Usage: $0 <input.bam> <intermediate_output.txt> <final_output.txt> -t '<telseq command>'"
    exit 1
fi

# Assign positional arguments
BAM_FILE="$1"
INTERMEDIATE_OUTPUT="$2"
FINAL_OUTPUT="$3"

# Parse the -t flag and its argument
if [ "$4" != "-t" ]; then
    echo "Error: The fourth argument must be '-t' followed by the telseq command."
    exit 1
fi

TELSEQ_COMMAND="${@:5}"

# Check if input BAM file exists
if [ ! -f "$BAM_FILE" ]; then
    echo "Error: BAM file '$BAM_FILE' not found!"
    exit 1
fi

# Run samtools idxstats and save output to intermediate file
echo -e "Chromosome Name\tChromosome Length\tNumber of Mapped Reads\tNumber of Unmapped Reads" > "$INTERMEDIATE_OUTPUT"
echo "Running samtools idxstats on $BAM_FILE..."
module load samtools
module load R
samtools idxstats "$BAM_FILE" >> "$INTERMEDIATE_OUTPUT"

# Check if samtools idxstats was successful
if [ $? -ne 0 ]; then
    echo "Error: samtools idxstats failed!"
    exit 1
fi

echo "Chromosome coverage saved to $INTERMEDIATE_OUTPUT"

# Run R script for further processing
echo "Running chr_calc.R with $INTERMEDIATE_OUTPUT..."
Rscript chr_calc.R "$INTERMEDIATE_OUTPUT" "$FINAL_OUTPUT"

# Check if R script executed successfully
if [ $? -ne 0 ]; then
    echo "Error: R script execution failed!"
    exit 1
fi

echo "Analysis completed successfully! Final results saved to $FINAL_OUTPUT"

# Extract the output file from the telseq command
TELSEQ_OUTPUT=$(echo "$TELSEQ_COMMAND" | grep -oP '(?<=-o\s)[^\s]+')

# Run R script to get chromosome count
total_chromosomes=45 # $(Rscript chr_num.R "$FINAL_OUTPUT")

# Run telseq based on chromosome count
if [ "$total_chromosomes" -eq 46 ]; then
  echo "Total chromosomes is 46, running telseq with the provided command $TELSEQ_COMMAND"
  eval "$TELSEQ_COMMAND"
else
  echo "Total chromosomes is $total_chromosomes not 46, running telseq and processing the output with command $TELSEQ_COMMAND"
  eval "$TELSEQ_COMMAND"

  # Extract LENGTH_ESTIMATE from the output file
  length_estimate=$(awk -F'\t' '
    NR==1 { for (i=1; i<=NF; i++) if ($i == "LENGTH_ESTIMATE") col=i }
    NR>1 && col { print $col }' "$TELSEQ_OUTPUT")

  # Calculate new LENGTH_ESTIMATE value
  new_length_estimate=$(echo "$length_estimate * 46 / $total_chromosomes" | bc -l)
  new_length_estimate=$(printf "%.5f" "$new_length_estimate")

  echo "Original estimate: ${length_estimate}; New estimate: ${new_length_estimate}"

  # Replace LENGTH_ESTIMATE in the output file
  awk -F'\t' -v new_length="$new_length_estimate" '
    NR==1 { for (i=1; i<=NF; i++) if ($i == "LENGTH_ESTIMATE") col=i }
    NR>1 && col { $col=new_length }
    { print }' OFS='\t' "$TELSEQ_OUTPUT" > temp_output

  # Rename files
  mv "$TELSEQ_OUTPUT" "${TELSEQ_OUTPUT}_orig.txt"
  mv temp_output "$TELSEQ_OUTPUT"
fi

echo "Task completed"
