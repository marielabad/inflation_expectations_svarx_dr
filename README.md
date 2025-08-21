## The Expectations Channel of Monetary Policy Transmission in the Dominican Republic: Evidence from a SVAR-X Model
Code, data and materials used for MSc dissertation: The Expectations Channel of Monetary Policy Transmission in the Dominican Republic: Evidence from a SVAR-X Model

## Overview
This repository contains the full workflow for my MSc dissertation at King's College London. The project examines the role of inflation expectations in the Dominican Republic's monetary policy transmission, estimated through a Structural Vector Autoregressive model with exogenous variables (SVAR-X).

The repo includes scripts for data cleaning, estimation, robustness checks, tests, and the generation of figures used in the dissertation.

## Repository Structure
inflation_expectations_svarx_dr/
├─ data/
│   └─ data_ce.xlsx
├─ scripts/
│   ├─ 01_packages.R
│   ├─ 02_utilities.R
│   ├─ 03_clean_build_data.R
│   ├─ 04_estimate_svarx.R
│   ├─ 05_figures_tables.R
│   └─ 06_robustness_check.R
├─ .DS_Store   👈 (macOS junk file)
├─ .gitignore
├─ README.md
└─ inflation_expectations_svarx_dr.Rproj


## Reproducibility

This project uses [`renv`](https://rstudio.github.io/renv/) to manage package versions.  

To reproduce the analysis:  

```r
# 1. Install renv if not installed
install.packages("renv")

# 2. Restore packages
renv::restore()

# 3. Run scripts in order
source("scripts/03_clean_build_data.R")
source("scripts/04_estimate_svarx.R")
source("scripts/05_figures_tables.R")
source("scripts/06_robustness_check.R")

```

## Data Sources
## Variables
The mayority of variables were obtained from the Central Bank of the Dominican Republic 

## Outputs
The outputs are impulse response functions (IRF), figures, and tables.

## Citation
If you use this code or data preparation steps, please cite: 

@misc{Abad2025,
  author       = {Mariel Abad},
  title        = {inflation_expectations_svarx_dr: Code and Data for MSc Dissertation},
  year         = {2025},
  url          = {https://github.com/marielabad/inflation_expectations_svarx_dr}
}
