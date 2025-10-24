# =============================================================================
# Statistical Comparison of OCR Libraries (RQ1)
# -----------------------------------------------------------------------------
# This script compares PaddleOCR and Tesseract across energy, runtime, and
# memory measurements. For each document type and sample size, it performs:
#   - Normality check using Shapiro–Wilk
#   - Paired t-test (with Cohen's d) for normally distributed differences
#   - Wilcoxon signed-rank test (with Cliff's Delta) otherwise
#
# Outputs: results/stat_tests_RQ1.csv
# =============================================================================

library(broom)

# --- Helper functions ---

# Safe Shapiro-Wilk test
safe_shapiro <- function(x) {
  if(length(x) < 3) return(NA)
  shapiro.test(x)$p.value
}

# Compute test and effect size only
compute_test <- function(paddle_vals, tesseract_vals) {
  n <- min(length(paddle_vals), length(tesseract_vals))
  
  # Too few observations
  if(n < 2) return(data.frame(
    p_value = NA, effect_size = NA, effect_type = NA
  ))
  
  paddle_vals <- paddle_vals[1:n]
  tesseract_vals <- tesseract_vals[1:n]
  diff <- paddle_vals - tesseract_vals
  
  # Handle all identical differences
  if(all(diff == 0)) {
    return(data.frame(
      p_value = NA,
      effect_size = 0,
      effect_type = "No variation"
    ))
  }
  
  shapiro_p <- safe_shapiro(diff)
  
  if(!is.na(shapiro_p) && shapiro_p >= 0.05) {
    # Paired t-test
    test <- t.test(paddle_vals, tesseract_vals, paired = TRUE)
    d <- cohen.d(paddle_vals, tesseract_vals, paired = TRUE)$estimate
    
    data.frame(
      p_value = test$p.value,
      effect_size = d,
      effect_type = "Cohen's d"
    )
    
  } else {
    # Wilcoxon signed-rank test
    test <- wilcox.test(paddle_vals, tesseract_vals, paired = TRUE, exact = FALSE)
    delta <- cliff.delta(paddle_vals, tesseract_vals)$estimate
    
    data.frame(
      p_value = test$p.value,
      effect_size = delta,
      effect_type = "Cliff's Delta"
    )
  }
}

# --- Apply tests per document type and sample size ---
results <- data %>%
  group_by(document_type, sample_size) %>%
  summarise(
    energy_test  = list(compute_test(energy[ocr_library == "Paddle"], energy[ocr_library == "Tesseract"])),
    runtime_test = list(compute_test(runtime[ocr_library == "Paddle"], runtime[ocr_library == "Tesseract"])),
    memory_test  = list(compute_test(memory[ocr_library == "Paddle"], memory[ocr_library == "Tesseract"])),
    .groups = "drop"
  ) %>%
  unnest_wider(energy_test, names_sep = "_energy") %>%
  unnest_wider(runtime_test, names_sep = "_runtime") %>%
  unnest_wider(memory_test, names_sep = "_memory")

# --- Save results ---
if(!dir.exists("results")) dir.create("results")
write.csv(results, "results/stat_tests_RQ1.csv", row.names = FALSE)
