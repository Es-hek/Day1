# =============================================================================
# tests/testthat/test_helpers.R
#
# Tests for the remaining helper functions in functions.R:
#   - install_if_missing()
#   - count_words()
#   - build_article_colours()
#   - build_article_labels()
#   - compute_keyword_percentages()
# =============================================================================

.functions_r <- local({
  candidates <- c(
    file.path(getwd(), "functions.R"),
    file.path(getwd(), "..", "functions.R"),
    file.path(getwd(), "..", "..", "functions.R")
  )
  found <- Filter(file.exists, candidates)
  if (length(found) == 0L) stop("Cannot locate functions.R")
  normalizePath(found[[1L]])
})
source(.functions_r)

suppressPackageStartupMessages(library(testthat))

# =============================================================================
# install_if_missing
# =============================================================================

test_that("install_if_missing does not call install.packages for an installed package", {
  # 'base' is always installed.  If install.packages were called, the test
  # would throw (no CRAN mirror in CI) or at least produce a warning.
  expect_silent(install_if_missing("base"))
})

test_that("install_if_missing is silent for any already-installed package", {
  pkgs <- c("methods", "utils", "stats")
  for (p in pkgs) expect_silent(install_if_missing(p))
})

# =============================================================================
# count_words
# =============================================================================

test_that("count_words returns correct count for a simple sentence", {
  expect_equal(count_words("blockchain and crypto are trending"), 5L)
})

test_that("count_words returns 1 for a single word", {
  expect_equal(count_words("blockchain"), 1L)
})

test_that("count_words handles leading and trailing whitespace", {
  expect_equal(count_words("  hello world  "), 2L)
})

test_that("count_words handles multiple internal spaces", {
  expect_equal(count_words("hello   world"), 2L)
})

test_that("count_words returns 0 for empty string", {
  expect_equal(count_words(""), 0L)
})

# =============================================================================
# build_article_colours
# =============================================================================

test_that("build_article_colours returns a named vector", {
  colours <- build_article_colours(c("01", "02"))
  expect_named(colours, c("01", "02"))
})

test_that("build_article_colours returns the right length", {
  for (n in 1:8) {
    names_n <- paste0(sprintf("%02d", seq_len(n)))
    expect_length(build_article_colours(names_n), n)
  }
})

test_that("build_article_colours uses the fixed palette for 1-8 articles", {
  fixed <- c("#3498DB", "#F39C12", "#2ECC71", "#E74C3C",
             "#9B59B6", "#1ABC9C", "#E67E22", "#34495E")
  for (n in 1:8) {
    names_n <- paste0(sprintf("%02d", seq_len(n)))
    colours  <- build_article_colours(names_n)
    expect_equal(unname(colours), head(fixed, n))
  }
})

test_that("build_article_colours uses an interpolated palette for >8 articles", {
  suppressPackageStartupMessages(library(RColorBrewer))
  names_9 <- paste0(sprintf("%02d", 1:9))
  colours  <- build_article_colours(names_9)
  expect_length(colours, 9)
  # Values should be hex colour strings
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", colours)))
})

test_that("build_article_colours returns empty vector for zero articles", {
  expect_length(build_article_colours(character(0)), 0)
})

# =============================================================================
# build_article_labels
# =============================================================================

test_that("build_article_labels returns a named character vector", {
  names  <- c("01", "02")
  titles <- c("01" = "Blockchain in Banking",
               "02" = "Crypto Regulation")
  labels <- build_article_labels(names, titles)
  expect_type(labels, "character")
  expect_named(labels, names)
})

test_that("build_article_labels truncates long titles to 40 characters", {
  long_title <- paste(rep("word", 20), collapse = " ")   # 99 chars
  names  <- "01"
  titles <- c("01" = long_title)
  label  <- build_article_labels(names, titles)
  # The title portion should be at most 40 chars (substr does the truncation)
  title_part <- sub("^01 \u2013 ", "", label)
  title_part <- sub("\\.\\.\\.$", "", title_part)
  expect_lte(nchar(title_part), 40)
})

test_that("build_article_labels format is '<name> – <title>...'", {
  names  <- "03"
  titles <- c("03" = "Test Article Title")
  label  <- build_article_labels(names, titles)
  expect_true(startsWith(label[["03"]], "03 \u2013 "))
  expect_true(endsWith(label[["03"]], "..."))
})

# =============================================================================
# compute_keyword_percentages
# =============================================================================

test_that("compute_keyword_percentages sums to 100 per row when totals > 0", {
  df <- data.frame(
    article        = c("01", "02"),
    blockchain     = c(10L, 5L),
    cryptocurrency = c(20L, 5L),
    regulation     = c(10L, 0L),
    banking        = c(10L, 10L),
    stringsAsFactors = FALSE
  )
  cats    <- c("blockchain", "cryptocurrency", "regulation", "banking")
  result  <- compute_keyword_percentages(df, cats)
  row_sums <- rowSums(result[, cats])
  expect_equal(row_sums, c(100, 100), tolerance = 1e-10)
})

test_that("compute_keyword_percentages returns 0 for a row with all-zero counts", {
  df <- data.frame(
    article        = "01",
    blockchain     = 0L,
    cryptocurrency = 0L,
    regulation     = 0L,
    banking        = 0L,
    stringsAsFactors = FALSE
  )
  cats   <- c("blockchain", "cryptocurrency", "regulation", "banking")
  result <- compute_keyword_percentages(df, cats)
  expect_equal(unlist(result[1, cats]), c(blockchain = 0, cryptocurrency = 0,
                                          regulation = 0, banking = 0))
})

test_that("compute_keyword_percentages does not modify the 'article' column", {
  df <- data.frame(
    article        = c("01", "02"),
    blockchain     = c(3L, 7L),
    cryptocurrency = c(7L, 3L),
    stringsAsFactors = FALSE
  )
  result <- compute_keyword_percentages(df, c("blockchain", "cryptocurrency"))
  expect_equal(result$article, c("01", "02"))
})

test_that("compute_keyword_percentages produces correct percentages", {
  df <- data.frame(
    article    = "01",
    blockchain = 1L,
    regulation = 3L,
    stringsAsFactors = FALSE
  )
  cats   <- c("blockchain", "regulation")
  result <- compute_keyword_percentages(df, cats)
  expect_equal(result$blockchain,  25, tolerance = 1e-10)
  expect_equal(result$regulation,  75, tolerance = 1e-10)
})
