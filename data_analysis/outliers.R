# =============================================================================
# OCR Energy Usage Outlier Detection
# -----------------------------------------------------------------------------
# This script detects outliers in energy, runtime, and memory measurements
# across OCR libraries, datasets, document types, languages, and sample sizes.
# Methods:
#   - IQR method
#   - Chauvenet's criterion (requires near-normality)
# Outputs CSV with outlier flags and saves boxplots highlighting outliers.
# =============================================================================

rm(list=ls())
library(dplyr)
library(ggplot2)

# ------------------------------
# Load data
# ------------------------------
data <- read.csv("final_data.txt")
cat_cols <- c("ocr_library", "document_type", "dataset", "language", "sample_size")
data[cat_cols] <- lapply(data[cat_cols], as.factor)

metrics <- c("energy","runtime","memory")

# ------------------------------
# Function: IQR Outlier Detection
# ------------------------------
iqr_outlier_flag <- function(x){
  Q1 <- quantile(x, 0.25, na.rm=TRUE)
  Q3 <- quantile(x, 0.75, na.rm=TRUE)
  IQR <- Q3-Q1
  lower <- Q1 - 1.5*IQR
  upper <- Q3 + 1.5*IQR
  return(ifelse(x < lower | x > upper, TRUE, FALSE))
}

# ------------------------------
# Function: Chauvenet's Criterion
# ------------------------------
chauvenet_flag <- function(x){
  n <- length(x)
  mean_x <- mean(x, na.rm=TRUE)
  sd_x <- sd(x, na.rm=TRUE)
  if(sd_x == 0) return(rep(FALSE, n))
  z <- abs((x - mean_x)/sd_x)
  prob <- 1 - pnorm(z)
  return(prob < 1/(2*n))
}

# ------------------------------
# Detect outliers
# ------------------------------
outlier_results <- data

for(metric in metrics){
  # IQR method
  outlier_results[[paste0(metric,"_outlier_iqr")]] <- FALSE
  for(group in cat_cols){
    outlier_results[[paste0(metric,"_outlier_iqr")]] <- with(outlier_results,
                                                             ave(get(metric), get(group), FUN=iqr_outlier_flag) | outlier_results[[paste0(metric,"_outlier_iqr")]]
    )
  }
  
  # Chauvenet's criterion
  outlier_results[[paste0(metric,"_outlier_chauvenet")]] <- FALSE
  for(group in cat_cols){
    outlier_results[[paste0(metric,"_outlier_chauvenet")]] <- with(outlier_results,
                                                                   ave(get(metric), get(group), FUN=chauvenet_flag) | outlier_results[[paste0(metric,"_outlier_chauvenet")]]
    )
  }
}

# ------------------------------
# Save results
# ------------------------------
if(!dir.exists("results")) dir.create("results")
write.csv(outlier_results, "results/outliers_detected.csv", row.names=FALSE)

# ------------------------------
# Optional: Boxplots with outliers
# ------------------------------
if(!dir.exists("figures")) dir.create("figures")
for(metric in metrics){
  p <- ggplot(outlier_results, aes(x=ocr_library, y=get(metric), color=get(paste0(metric,"_outlier_iqr")))) +
    geom_boxplot() +
    geom_jitter(width=0.2, alpha=0.5) +
    scale_color_manual(values=c("black","red"), name="IQR Outlier") +
    labs(title=paste("Boxplot of", metric, "with IQR Outliers"), y=metric) +
    theme_minimal()
  ggsave(paste0("figures/boxplot_",metric,"_outliers.png"), p, width=8, height=6)
}

cat("Outlier detection complete. Results in ./results/outliers_detected.csv, figures in ./figures/\n")
