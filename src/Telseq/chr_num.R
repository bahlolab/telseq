args <- commandArgs(trailingOnly = TRUE)

# Check if correct number of arguments are provided
if (length(args) != 1) {
  stop("Usage: Rscript chr_num.R <chrcalc_final.txt> ")
}

# Assign input and output file paths from command-line arguments
input_file <- args[1]

# Read the data from the input file
chrs <- read.table(input_file, sep = "\t", header = TRUE)

total_chromosomes <- 0

# Loop through the data and apply the conditions for counting chromosomes
for (i in 1:nrow(chrs)) {
  norm_value <- chrs$norm.reads.per.base[i]
  
  if (norm_value > 0.70 & norm_value < 1.5) {
    total_chromosomes <- total_chromosomes + 2
  } else if (norm_value > 0.20 & norm_value < 0.6) {
    total_chromosomes <- total_chromosomes + 1
  } else if (norm_value >= 0 & norm_value < 0.19) {
    total_chromosomes <- total_chromosomes + 0
  }
}

# Output the total number of chromosomes in a format suitable for terminal use
cat(total_chromosomes)
