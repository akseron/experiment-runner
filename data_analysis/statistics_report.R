# =============================================================================
# OCR Energy Usage Visualization
# -----------------------------------------------------------------------------
# Loads "final_data.txt" and compares Tesseract vs Paddle energy usage.
# Creates 2x2 grids (density + violin, small & big samples) for:
#   - Omni Dataset (clean)
#   - Noisy Dataset (noisy)
# Custom colors, fonts, and axis/legend sizing for clear presentation.
# Exports grids as PNG files in "figures/" folder.
# Additionally: option to create each violin plot separately
# =============================================================================


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



# ------------------------------------------------------
# Additional
# Violin Plots - by dataset, library and sample size
# ------------------------------------------------------
plot_single_violin <- function(df, lib, sample, title, base_text_size = 12) {
  df_lib <- filter(df, ocr_library == lib, sample_size == sample)
  
  ggplot(df_lib, aes(x=ocr_library, y=energy, fill=ocr_library)) +
    geom_violin(trim=FALSE, width=0.6) +
    stat_summary(fun=mean, geom="point", shape=23, size=3, color="black") +
    scale_fill_manual(values=c("Tesseract"="#DB7F8E", "Paddle"="#50C9CE")) +
    ggtitle(title) +
    xlab("") + ylab("Energy usage (J)") +
    theme_minimal(base_family = "Helvetica", base_size = base_text_size) +
    theme(
      plot.title = element_text(hjust = 0.5),  # <-- center title
      legend.position = "none",
      axis.title = element_text(size = base_text_size - 2),
      axis.text = element_text(size = base_text_size - 4)
    )
}



# Split data
omni_data  <- filter(data, dataset == "Omni_Dataset")
noisy_data <- filter(data, dataset == "Noisy_Dataset")

# Omni
v_omni_tess_small <- plot_single_violin(omni_data,  "Tesseract", "1",  "Violin Plot - Small Sample Size", base_text_size = 16)
v_omni_tess_big   <- plot_single_violin(omni_data,  "Tesseract", "20", "Violin Plot - Big Sample Size", base_text_size = 16)
v_omni_padd_small <- plot_single_violin(omni_data,  "Paddle",    "1",  "Violin Plot - Small Sample Size", base_text_size = 16)
v_omni_padd_big   <- plot_single_violin(omni_data,  "Paddle",    "20", "Violin Plot - Big Sample Size", base_text_size = 16)

# Noisy
v_noisy_tess_small <- plot_single_violin(noisy_data, "Tesseract", "1",  "Violin Plot - Small Sample Size", base_text_size = 16)
v_noisy_tess_big   <- plot_single_violin(noisy_data, "Tesseract", "20", "Violin Plot - Big Sample Size", base_text_size = 16)
v_noisy_padd_small <- plot_single_violin(noisy_data, "Paddle",    "1",  "Violin Plot - Small Sample Size", base_text_size = 16)
v_noisy_padd_big   <- plot_single_violin(noisy_data, "Paddle",    "20", "Violin Plot - Big Sample Size", base_text_size = 16)

dir.create("figures", showWarnings = FALSE)

ggsave("figures/omni_tesseract_small.png", v_omni_tess_small, width=6, height=4, dpi=150)
ggsave("figures/omni_tesseract_big.png",   v_omni_tess_big,   width=6, height=4, dpi=150)
ggsave("figures/omni_paddle_small.png",    v_omni_padd_small, width=6, height=4, dpi=150)
ggsave("figures/omni_paddle_big.png",      v_omni_padd_big,   width=6, height=4, dpi=150)

ggsave("figures/noisy_tesseract_small.png", v_noisy_tess_small, width=6, height=4, dpi=150)
ggsave("figures/noisy_tesseract_big.png",   v_noisy_tess_big,   width=6, height=4, dpi=150)
ggsave("figures/noisy_paddle_small.png",    v_noisy_padd_small, width=6, height=4, dpi=150)
ggsave("figures/noisy_paddle_big.png",      v_noisy_padd_big,   width=6, height=4, dpi=150)


# ------------------------------------------------------
# For figures displayed in grid 
#-------------------------------------------------------

# For PaddleOCR, Noisy Dataset
grid_noisy_paddle <- grid.arrange(
  v_noisy_padd_small,
  v_noisy_padd_big,
  ncol = 2
)

ggsave("figures/noisy_paddle_grid.png", grid_noisy_paddle,
       width = 12, height = 6, dpi = 150)

# For Tesseract, Noisy Dataset
grid_noisy_tesseract <- grid.arrange(
  v_noisy_tess_small,
  v_noisy_tess_big,
  ncol = 2
)

ggsave("figures/noisy_tesseract_grid.png", grid_noisy_tesseract,
       width = 12, height = 6, dpi = 150)
