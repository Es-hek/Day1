#!/usr/bin/env Rscript
# =============================================================================
# tests/run_tests.R
#
# Runs the full testthat test suite for this project.
#
# Usage (from the repository root):
#   Rscript tests/run_tests.R
#
# All required packages are installed automatically if not already present.
# =============================================================================

# Ensure testthat and stringr are available.
if (!requireNamespace("testthat",  quietly = TRUE))
  install.packages("testthat",  repos = "https://cloud.r-project.org")
if (!requireNamespace("stringr",   quietly = TRUE))
  install.packages("stringr",   repos = "https://cloud.r-project.org")
if (!requireNamespace("RColorBrewer", quietly = TRUE))
  install.packages("RColorBrewer", repos = "https://cloud.r-project.org")

suppressPackageStartupMessages({
  library(testthat)
  library(stringr)
  library(RColorBrewer)
})

# Locate the tests/testthat directory relative to this script.
script_path <- tryCatch({
  args     <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
  } else {
    file.path(getwd(), "tests", "run_tests.R")
  }
}, error = function(e) file.path(getwd(), "tests", "run_tests.R"))

tests_dir <- file.path(dirname(script_path), "testthat")

cat("Running tests in:", tests_dir, "\n\n")
result <- testthat::test_dir(tests_dir, reporter = "progress", stop_on_failure = FALSE)

# Print a summary and exit with a non-zero status on failures.
summary_df <- as.data.frame(result)
n_fail     <- sum(summary_df$failed, na.rm = TRUE)
n_error    <- sum(summary_df$error,  na.rm = TRUE)

if (n_fail + n_error > 0) {
  cat(sprintf("\n%d failure(s) / %d error(s) detected.\n", n_fail, n_error))
  quit(status = 1)
} else {
  cat("\nAll tests passed.\n")
  quit(status = 0)
}
