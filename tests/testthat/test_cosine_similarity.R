# =============================================================================
# tests/testthat/test_cosine_similarity.R
#
# Tests for the cosine_similarity() helper function defined in functions.R.
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

# --- identity and zero -------------------------------------------------------

test_that("cosine_similarity of a vector with itself is 1", {
  v <- c(1, 2, 3, 4, 5)
  expect_equal(cosine_similarity(v, v), 1)
})

test_that("cosine_similarity of a zero vector with any vector returns 0", {
  expect_equal(cosine_similarity(c(0, 0, 0), c(1, 2, 3)), 0)
  expect_equal(cosine_similarity(c(1, 2, 3), c(0, 0, 0)), 0)
  expect_equal(cosine_similarity(c(0, 0, 0), c(0, 0, 0)), 0)
})

# --- orthogonality -----------------------------------------------------------

test_that("orthogonal vectors have cosine similarity of 0", {
  a <- c(1, 0, 0)
  b <- c(0, 1, 0)
  expect_equal(cosine_similarity(a, b), 0)
})

test_that("another pair of orthogonal vectors has cosine similarity of 0", {
  a <- c(3, 0)
  b <- c(0, 7)
  expect_equal(cosine_similarity(a, b), 0)
})

# --- known values ------------------------------------------------------------

test_that("cosine similarity of [1,0] and [1,1] equals 1/sqrt(2)", {
  a <- c(1, 0)
  b <- c(1, 1)
  expected <- 1 / sqrt(2)
  expect_equal(cosine_similarity(a, b), expected, tolerance = 1e-10)
})

test_that("cosine similarity of [1,1] and [2,2] (same direction) equals 1", {
  a <- c(1, 1)
  b <- c(2, 2)
  expect_equal(cosine_similarity(a, b), 1, tolerance = 1e-10)
})

test_that("cosine similarity is symmetric", {
  a <- c(2, 3, 5)
  b <- c(1, 4, 2)
  expect_equal(cosine_similarity(a, b), cosine_similarity(b, a))
})

# --- longer vectors (TF-IDF-like scenario) ------------------------------------

test_that("cosine similarity returns a value between 0 and 1 for non-negative vectors", {
  set.seed(42)
  a <- abs(rnorm(50))
  b <- abs(rnorm(50))
  result <- cosine_similarity(a, b)
  expect_gte(result, 0)
  expect_lte(result, 1)
})

test_that("vectors with high overlap produce high cosine similarity", {
  a <- c(5, 3, 0, 1, 2)
  b <- c(4, 3, 0, 1, 2)
  # Very similar; expect > 0.99
  expect_gt(cosine_similarity(a, b), 0.99)
})

test_that("vectors with no shared non-zero entries have cosine similarity 0", {
  a <- c(1, 2, 0, 0)
  b <- c(0, 0, 3, 4)
  expect_equal(cosine_similarity(a, b), 0)
})

# --- scalar handling ---------------------------------------------------------

test_that("cosine similarity works for length-1 vectors", {
  expect_equal(cosine_similarity(3, 5), 1)   # same sign → 1
  expect_equal(cosine_similarity(0, 5), 0)   # zero vector → 0
})
