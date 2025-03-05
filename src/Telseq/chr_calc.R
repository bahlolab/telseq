# Get input arguments from the command line
args <- commandArgs(trailingOnly = TRUE)

# Check if correct number of arguments are provided
if (length(args) != 2) {
  stop("Usage: Rscript chr_calc.R <input_file> <output_file>")
}

# Assign input and output file paths from command-line arguments
input_file <- args[1]
output_file <- args[2]

# Read the data from the input file
df <- read.table(input_file, sep = "\t", header = TRUE)

# Subset data for first 24 chromosomes (assuming these are the autosomes and X chromosome)
chrs <- df[seq(1, 24, 1),]

# Calculate reads per base (Number of Mapped Reads / Chromosome Length)
chrs$reads.per.base <- chrs$Number.of.Mapped.Reads / chrs$Chromosome.Length

# Calculate median read depth
median.depth <- median(chrs$reads.per.base)

# Normalize reads per base by dividing by the median depth
chrs$norm.reads.per.base <- chrs$reads.per.base / median.depth

# Write the results to the output file
write.table(chrs, output_file, sep = "\t", row.names = FALSE, quote = FALSE)

# Print message to confirm successful completion
cat("Analysis completed. Results saved to", output_file, "\n")
