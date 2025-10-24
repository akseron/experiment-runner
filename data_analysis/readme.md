# Data Analysis

These scripts can be used to clean, process, and statistically analyse the results from the OCR energy experiments.

## Installation

RStudio version 2021.09.0+351 should be installed with R version 4.1.1.

The following R packages need to be installed:

```r
install.packages("ggplot2")
install.packages("plyr")
install.packages("effsize")
install.packages("tidyr")
install.packages("dplyr")
install.packages("gridExtra")
install.packages("broom")

## Usage

The recommended workflow for analyzing the OCR experiment data is as follows:

1. **Clean and prepare data** — `clean_data.R`  
   Removes incomplete rows and redundant columns from the raw dataset.  
   **Outputs:**  
   - `final_data.txt` — cleaned dataset  
   - `tested_libraries.txt` — list of tested OCR libraries (if present)

2. **Descriptive statistics and visualizations** — `statistics.R`  
   Performs summary statistics, normality checks, and creates visualizations.  
   **Outputs:**  
   - `results/final_descriptive_statistics.csv` — aggregated statistics  
   - `results/descriptive_statistics.csv` — detailed statistics per factor  
   - `results/normality_tests.csv` — Shapiro-Wilk normality test results  
   - `figures/` — boxplots, density plots, scatter plots, Q-Q plots

3. **Outlier detection** — `outliers.R`  
   Detects outliers using the IQR method and Chauvenet’s criterion.  
   **Outputs:**  
   - `results/outliers_detected.csv` — CSV with outlier flags  
   - `figures/` — boxplots highlighting outliers

4. **Visualization report** — `statistics_report.R`  
   Creates violin and density plots comparing Tesseract vs Paddle for different datasets and sample sizes.  
   **Outputs:**  
   - `figures/` — individual violin plots, 2x2 grid plots

5. **Statistical tests and effect sizes** — `tests.R`  
   Performs paired tests between Paddle and Tesseract (t-test or Wilcoxon) and calculates effect sizes (Cohen's d or Cliff’s delta).  
   **Outputs:**  
   - `results/stat_tests_RQ1.csv` — statistical test results per document type and sample size
