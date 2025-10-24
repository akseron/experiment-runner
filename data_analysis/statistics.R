
# =============================================================================
# OCR Energy Usage Analysis
# -----------------------------------------------------------------------------
# This script analyzes energy, runtime, and memory usage of OCR libraries
# (Tesseract and Paddle) on two datasets (Omni and Noisy).
#
# Features:
#   - Descriptive statistics (mean, median, SD) for energy, runtime, memory
#   - Visualizations: boxplots, density plots, scatter plots, 2x2 grids, Q-Q plots
#   - Assumption checks: Shapiro-Wilk normality, paired difference normality
#   - RQ1: Paired comparisons (t-test or Wilcoxon) + effect sizes (Cohen's d / Cliff's delta)
#   - RQ2: Correlations (Pearson or Spearman)
#   - Generic pairwise Wilcoxon + Cliff's delta for all two-level factors
#   - Exports results in "results/" and figures in "figures/"
# 
# Adapted from the replication package by Malavolta et al., EASE 2022:
# https://doi.org/10.1145/3530019.3530033
# =============================================================================

rm(list=ls())

library(ggplot2)
library(gridExtra)
library(dplyr)
library(tidyr)
library(effsize)

# ------------------------------
# Load data
# ------------------------------
data <- read.csv("final_data.txt")
cat_cols <- c("ocr_library", "document_type", "dataset", "language", "sample_size")
data[cat_cols] <- lapply(data[cat_cols], as.factor)
data$ocr_library <- recode(data$ocr_library, "tesseract"="Tesseract", "paddle"="Paddle")

# Create directories
if(!dir.exists("figures")) dir.create("figures")
if(!dir.exists("results")) dir.create("results")

# ------------------------------
# Descriptive statistics
# ------------------------------
# Aggregated by OCR library, dataset, and sample size
final_stats <- data %>%
  mutate(
    Treatment = ifelse(ocr_library=="Tesseract", "L1", "L2"),
    DatasetLabel = ifelse(dataset=="Omni_Dataset", "D1", "D2"),
    Size = ifelse(sample_size==1, "S", "B")
  ) %>%
  group_by(Treatment, DatasetLabel, Size) %>%
  summarise(
    mean_energy = mean(energy, na.rm=TRUE),
    median_energy = median(energy, na.rm=TRUE),
    sd_energy = sd(energy, na.rm=TRUE),
    mean_runtime = mean(runtime, na.rm=TRUE),
    median_runtime = median(runtime, na.rm=TRUE),
    sd_runtime = sd(runtime, na.rm=TRUE),
    mean_memory = mean(memory, na.rm=TRUE),
    median_memory = median(memory, na.rm=TRUE),
    sd_memory = sd(memory, na.rm=TRUE),
    .groups="drop"
  )
write.csv(final_stats, "results/final_descriptive_statistics.csv", row.names=FALSE)

# More detailed descriptive statistics
desc_stats <- data %>%
  group_by(ocr_library, document_type, dataset, language, sample_size) %>%
  summarise(
    mean_energy = mean(energy, na.rm=TRUE),
    sd_energy = sd(energy, na.rm=TRUE),
    mean_runtime = mean(runtime, na.rm=TRUE),
    sd_runtime = sd(runtime, na.rm=TRUE),
    mean_memory = mean(memory, na.rm=TRUE),
    sd_memory = sd(memory, na.rm=TRUE),
    .groups="drop"
  )
write.csv(desc_stats, "results/descriptive_statistics.csv", row.names=FALSE)

# ------------------------------
# Visualizations
# ------------------------------
plot_metric <- function(metric, ylab_title, factor_col, filename) {
  p <- ggplot(data, aes_string(x=factor_col, y=metric)) +
    geom_boxplot() +
    stat_summary(fun=mean, geom="point", shape=23, size=4) +
    xlab(factor_col) + ylab(ylab_title) +
    theme(plot.title = element_text(size=13, hjust=0.5, face="bold"),
          text = element_text(size=12))
  ggsave(filename, p, width=8, height=6)
}

plot_density <- function(metric,factor_col,filename){
  factor_levels <- levels(data[[factor_col]])
  colors <- rainbow(length(factor_levels))
  png(filename, width=800, height=600)
  plot(density(data[data[[factor_col]]==factor_levels[1], metric]),
       main=paste("Density of", metric, "by", factor_col),
       xlab=metric, col=colors[1], lwd=2)
  if(length(factor_levels)>1){
    for(i in 2:length(factor_levels)){
      lines(density(data[data[[factor_col]]==factor_levels[i], metric]), col=colors[i], lwd=2)
    }
  }
  legend("topright", legend=factor_levels, col=colors, lwd=2)
  dev.off()
}

plot_scatter <- function(x_metric, y_metric, factor_col, filename){
  factor_levels <- levels(data[[factor_col]])
  colors <- rainbow(length(factor_levels))
  png(filename, width=800, height=600)
  plot(data[[x_metric]], data[[y_metric]], col=colors[as.numeric(data[[factor_col]])],
       pch=19, xlab=x_metric, ylab=y_metric,
       main=paste("Scatter of", y_metric,"vs",x_metric,"by",factor_col))
  legend("topright", legend=factor_levels, col=colors, pch=19)
  dev.off()
}

for(factor_col in cat_cols){
  plot_metric("energy","Energy (J)",factor_col,paste0("figures/boxplot_energy_",factor_col,".png"))
  plot_metric("runtime","Runtime (s)",factor_col,paste0("figures/boxplot_runtime_",factor_col,".png"))
  plot_metric("memory","Memory (bytes)",factor_col,paste0("figures/boxplot_memory_",factor_col,".png"))
  
  plot_density("energy", factor_col, paste0("figures/density_energy_",factor_col,".png"))
  plot_density("runtime", factor_col, paste0("figures/density_runtime_",factor_col,".png"))
  plot_density("memory", factor_col, paste0("figures/density_memory_",factor_col,".png"))
}

plot_scatter("runtime","energy","ocr_library","figures/scatter_energy_vs_runtime.png")
plot_scatter("memory","energy","ocr_library","figures/scatter_energy_vs_memory.png")

# Optional Q-Q plots
for(metric in c("energy","runtime","memory")){
  for(factor_col in cat_cols){
    for(level in levels(data[[factor_col]])){
      subset_data <- data[[metric]][data[[factor_col]]==level]
      if(length(subset_data)>=3){
        png(paste0("figures/qq_",metric,"_",factor_col,"_",level,".png"),width=800,height=600)
        qqnorm(subset_data, main=paste("Q-Q plot of", metric,"for",level))
        qqline(subset_data, col="red")
        dev.off()
      }
    }
  }
}

# ------------------------------
# Normality Tests
# ------------------------------
normality_results <- data.frame()
for(factor_col in cat_cols){
  for(level in levels(data[[factor_col]])){
    for(metric in c("energy","runtime","memory")){
      subset_data <- data[[metric]][data[[factor_col]]==level]
      p_val <- if(length(subset_data)<3) NA else shapiro.test(subset_data)$p.value
      normality_results <- rbind(normality_results,
                                 data.frame(factor=factor_col, level=level, metric=metric, shapiro_p=p_val))
    }
  }
}
write.csv(normality_results,"results/normality_tests.csv", row.names=FALSE)

# ------------------------------
# RQ1: Paired Comparisons & Effect Sizes
# ------------------------------
paired_results <- data.frame()
for(metric in c("energy","runtime","memory")){
  for(dataset_name in unique(data$dataset)){
    for(size in unique(data$sample_size)){
      subset_df <- data %>% filter(dataset==dataset_name, sample_size==size)
      if(all(c("Tesseract","Paddle") %in% subset_df$ocr_library)){
        diff_vec <- subset_df %>%
          pivot_wider(names_from=ocr_library, values_from=!!sym(metric)) %>%
          mutate(diff=Tesseract-Paddle) %>%
          pull(diff)
        shapiro_p <- if(length(diff_vec)>=3) shapiro.test(diff_vec)$p.value else NA
        if(!is.na(shapiro_p) && shapiro_p>0.05){
          test_res <- t.test(diff_vec, paired=TRUE)
          effect_size <- mean(diff_vec)/sd(diff_vec)
          test_type <- "paired t-test"
        } else {
          test_res <- wilcox.test(diff_vec, paired=TRUE)
          effect_size <- cliff.delta(diff_vec, rep(0,length(diff_vec)))$estimate
          test_type <- "Wilcoxon signed-rank"
        }
        paired_results <- rbind(paired_results,
                                data.frame(metric=metric,dataset=dataset_name,
                                           sample_size=size,test=test_type,
                                           p_value=test_res$p.value,effect_size=effect_size))
      }
    }
  }
}
write.csv(paired_results,"results/paired_tests.csv",row.names=FALSE)

# ------------------------------
# RQ2: Correlations
# ------------------------------
cor_results <- data.frame()
for(metric in c("runtime","memory")){
  for(dataset_name in unique(data$dataset)){
    subset_df <- data %>% filter(dataset==dataset_name)
    if(shapiro.test(subset_df$energy)$p.value>0.05 &&
       shapiro.test(subset_df[[metric]])$p.value>0.05){
      cor_test <- cor.test(subset_df$energy, subset_df[[metric]], method="pearson")
      method_used <- "Pearson"
    } else {
      cor_test <- cor.test(subset_df$energy, subset_df[[metric]], method="spearman")
      method_used <- "Spearman"
    }
    cor_results <- rbind(cor_results,data.frame(dataset=dataset_name,
                                                metric=metric,
                                                correlation=cor_test$estimate,
                                                p_value=cor_test$p.value,
                                                method=method_used))
  }
}
write.csv(cor_results,"results/correlations.csv",row.names=FALSE)

# ------------------------------
# Generic Pairwise Wilcoxon + Cliff's delta
# ------------------------------
pairwise_results <- data.frame()
for(metric in c("energy","runtime","memory")){
  for(factor_col in cat_cols){
    factor_levels <- levels(data[[factor_col]])
    if(length(factor_levels)==2){
      x <- data[[metric]][data[[factor_col]]==factor_levels[1]]
      y <- data[[metric]][data[[factor_col]]==factor_levels[2]]
      wilcox_p <- wilcox.test(x,y,paired=FALSE)$p.value
      cliff_d <- cliff.delta(x,y)$estimate
      pairwise_results <- rbind(pairwise_results,
                                data.frame(metric=metric,factor=factor_col,
                                           level1=factor_levels[1],level2=factor_levels[2],
                                           wilcox_p=wilcox_p,cliff_d=cliff_d))
    }
  }
}
write.csv(pairwise_results,"results/pairwise_tests_generic.csv",row.names=FALSE)

cat("Analysis complete. Figures in ./figures/, statistics in ./results/\n")

