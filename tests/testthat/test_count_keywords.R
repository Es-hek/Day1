# =============================================================================
# tests/testthat/test_count_keywords.R
#
# Tests for the count_keywords() helper function defined in functions.R.
# =============================================================================

# Locate functions.R robustly: when testthat runs with chdir=TRUE the working
# directory is tests/testthat/; when called directly it is the repo root.
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
suppressPackageStartupMessages(library(stringr))   # needed by count_keywords

# --- basic matching ----------------------------------------------------------

test_that("count_keywords returns 0 for text that contains no keywords", {
  expect_equal(count_keywords("the weather is nice today", c("bitcoin", "blockchain")), 0L)
})

test_that("count_keywords returns 1 when keyword appears once", {
  expect_equal(count_keywords("bitcoin is a cryptocurrency", c("bitcoin")), 1L)
})

test_that("count_keywords sums across multiple keywords", {
  text <- "blockchain technology and bitcoin payments"
  expect_equal(count_keywords(text, c("blockchain", "bitcoin")), 2L)
})

test_that("count_keywords counts multiple occurrences of the same keyword", {
  text <- "bitcoin is popular. bitcoin is volatile. bitcoin is digital."
  expect_equal(count_keywords(text, c("bitcoin")), 3L)
})

# --- case insensitivity -------------------------------------------------------

test_that("count_keywords is case-insensitive (uppercase input)", {
  expect_equal(count_keywords("BITCOIN price surged", c("bitcoin")), 1L)
})

test_that("count_keywords is case-insensitive (mixed case)", {
  expect_equal(count_keywords("The Blockchain network is decentralized", c("blockchain")), 1L)
})

# --- word boundary enforcement -----------------------------------------------

test_that("count_keywords does NOT match keyword as a substring of a longer word", {
  # 'bank' should NOT match inside 'banking' or 'bankroll'
  expect_equal(count_keywords("banking and bankroll are common words", c("bank")), 0L)
})

test_that("count_keywords matches keyword at the start of text", {
  expect_equal(count_keywords("bitcoin leads the market", c("bitcoin")), 1L)
})

test_that("count_keywords matches keyword at the end of text", {
  expect_equal(count_keywords("the price of bitcoin", c("bitcoin")), 1L)
})

test_that("count_keywords matches keyword surrounded by punctuation", {
  expect_equal(count_keywords("price of bitcoin, which is volatile", c("bitcoin")), 1L)
})

# --- edge cases ---------------------------------------------------------------

test_that("count_keywords returns 0 for empty text", {
  expect_equal(count_keywords("", c("bitcoin")), 0L)
})

test_that("count_keywords returns 0 for whitespace-only text", {
  expect_equal(count_keywords("   ", c("bitcoin")), 0L)
})

test_that("count_keywords returns 0 for empty keywords vector", {
  expect_equal(count_keywords("bitcoin blockchain crypto", character(0)), 0L)
})

test_that("count_keywords handles single-character keywords", {
  # Should not match 'i' inside 'bitcoin'
  expect_equal(count_keywords("the letter i appears in bitcoin", c("i")), 1L)
})

# --- multi-keyword category totals -------------------------------------------

test_that("count_keywords sums counts across a keyword list correctly", {
  text <- "blockchain distributed ledger smart contract"
  keywords <- c("blockchain", "distributed", "ledger", "smart", "contract")
  # Each word appears once
  expect_equal(count_keywords(text, keywords), 5L)
})

test_that("count_keywords handles overlapping-sound but distinct keywords", {
  text <- "ethereum and ether are different terms"
  expect_equal(count_keywords(text, c("ethereum", "ether")), 2L)
})
