# -----------------------------------------------------------------------------
# This script adapts methods from the replication package by Ivano Malavolta et al.
# 
# Original work: Malavolta, I., Janssen, K., Pelle, T., de Geus, L., van der Gronden, R., & Islam, T. 
# "On the impact of the critical CSS technique on the performance and energy consumption of mobile browsers."
# Proceedings of the 27th ACM International Conference on Evaluation and Assessment in Software Engineering (EASE 2022), 
# 13–15 June 2022, Gothenburg, Sweden. https://doi.org/10.1145/3530019.3530033
#
# This script cleans and processes experimental data in a similar manner to the original replication package.
# -----------------------------------------------------------------------------

# ===============================================
# clean_data.R
# Remove incomplete rows and export final dataset
# ===============================================

# Load required libraries
library(tidyr)   # drop_na()
library(dplyr)   # data manipulation

# -------------------------
# Load raw dataset
# -------------------------
data <- read.csv("../results/runtables/run_table_energibridge.csv")

# -------------------------
# Remove incomplete rows in essential columns
# -------------------------
essential_cols <- c("energy", "memory", "runtime")
data_clean <- drop_na(data, all_of(essential_cols))

# -------------------------
# Remove redundant/unneeded columns
# -------------------------
cols_to_remove <- c("X__done", "X", "i")  # remove if exist
data_clean <- data_clean %>% select(-any_of(cols_to_remove))

# -------------------------
# Export cleaned dataset
# -------------------------
write.table(data_clean, "final_data.txt", sep = ",", dec = ".",
            row.names = FALSE, col.names = TRUE, quote = FALSE)
cat("Cleaned dataset exported: final_data.txt\n")

# Export list of tested libraries/sites (if relevant)
if("ocr_library" %in% colnames(data_clean)){
  write.table(sort(unique(data_clean$ocr_library)), "tested_libraries.txt",
              sep = ",", col.names = FALSE, row.names = FALSE, quote = FALSE)
  cat("Tested libraries exported: tested_libraries.txt\n")
}

