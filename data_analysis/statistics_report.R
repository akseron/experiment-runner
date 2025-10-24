# =============================================================================
# OCR Energy Usage Visualization
# -----------------------------------------------------------------------------
# Loads "final_data.txt" and compares Tesseract vs Paddle energy usage.
# Creates 2x2 grids (density + violin, small & big samples) for:
#   - Omni Dataset (clean)
#   - Noisy Dataset (noisy)
# Custom colors, fonts, and axis/legend sizing for clear presentation.
# Exports grids as PNG files in "figures/" folder.
# =============================================================================


library(ggplot2)
library(gridExtra)
library(dplyr)

# Load data
data <- read.csv("final_data.txt")
data$ocr_library <- as.factor(data$ocr_library)
data$ocr_library <- recode(data$ocr_library, 
                           "tesseract" = "Tesseract", 
                           "paddle" = "Paddle")
data$sample_size <- as.factor(data$sample_size)

# -----------------------------
# Density plots
# -----------------------------
plot_density <- function(df, title) {
  ggplot(df, aes(x=energy, fill=ocr_library)) +
    geom_density(alpha=0.5) +
    scale_fill_manual(name="Distribution", values=c("Tesseract"="#DB7F8E", "Paddle"="#50C9CE")) +
    ggtitle(title) +
    xlab("Energy (J)") + ylab("Density") +
    theme_minimal(base_family = "Helvetica") +
    theme(
      plot.title = element_text(hjust=0.5, size=12),
      axis.title = element_text(size=10),
      axis.text = element_text(size=8),
      legend.title = element_text(size=7),
      legend.text = element_text(size=7)
    )
}

# -----------------------------
# Violin plots
# -----------------------------
plot_violin <- function(df, title) {
  ggplot(df, aes(x=ocr_library, y=energy, fill=ocr_library)) +
    geom_violin(trim=FALSE) +
    stat_summary(fun=mean, geom="point", shape=23, size=3, color="black") +
    scale_fill_manual(name="Distribution", values=c("Tesseract"="#DB7F8E", "Paddle"="#50C9CE")) +
    ggtitle(title) +
    xlab("OCR Library") + ylab("Energy usage (J)") +
    theme_minimal(base_family = "Helvetica") +
    theme(
      plot.title = element_text(hjust=0.5, size=12),
      axis.title = element_text(size=10),
      axis.text = element_text(size=8),
      legend.title = element_text(size=7),
      legend.text = element_text(size=7)
    )
  
}

# -----------------------------
# Function to create 2x2 grid for a dataset
# -----------------------------
plot_dataset_grid <- function(df) {
  df_small <- filter(df, sample_size == 1)
  df_big   <- filter(df, sample_size == 20)
  
  dens_small <- plot_density(df_small, "Density Plot - Small Sample Size")
  dens_big   <- plot_density(df_big,   "Density Plot - Big Sample Size")
  violin_small <- plot_violin(df_small, "Violin Plot - Small Sample Size")
  violin_big   <- plot_violin(df_big,   "Violin Plot - Big Sample Size")
  
  grid.arrange(dens_small, dens_big, violin_small, violin_big, ncol=2)
}

# -----------------------------
# Plot for Omni Dataset
# -----------------------------
omni_data <- filter(data, dataset == "Omni_Dataset")
plot_dataset_grid(omni_data)

# -----------------------------
# Plot for Noisy Dataset
# -----------------------------
noisy_data <- filter(data, dataset == "Noisy_Dataset")
plot_dataset_grid(noisy_data)


# -----------------------------
# Export Plots
# -----------------------------

# Export Noisy Dataset grid
png("figures/noisy_dataset_grid.png", width = 1200, height = 800, res = 150)
plot_dataset_grid(noisy_data)
dev.off()

# Export Omni Dataset grid
png("figures/omni_dataset_grid.png", width = 1200, height = 800, res = 150)
plot_dataset_grid(omni_data)
dev.off()
