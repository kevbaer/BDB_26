library(tidyverse)
library(arrow)

input <- read_parquet("data/input.parquet")
output <- read_parquet("data/output.parquet")

a <- read_csv("data/supplementary_data.csv")
