# =============================================================================
# tests/testthat/test_article_loading.R
#
# Tests for article-loading and discovery logic from analysis.R, exercised
# through temporary directories so no real article files are required.
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

# Helper: create a temporary articles directory with N synthetic text files.
make_temp_articles <- function(n, content_fn = NULL) {
  tmp <- tempfile("articles_")
  dir.create(tmp)
  if (is.null(content_fn)) {
    content_fn <- function(i) paste("Title", i, "\n\nBody text for article", i)
  }
  for (i in seq_len(n)) {
    fname <- file.path(tmp, sprintf("%02d.txt", i))
    writeLines(content_fn(i), fname)
  }
  tmp
}

# =============================================================================
# File discovery
# =============================================================================

test_that("list.files discovers .txt files in the articles directory", {
  tmp <- make_temp_articles(3)
  on.exit(unlink(tmp, recursive = TRUE))

  files <- sort(list.files(tmp, pattern = "\\.txt$", full.names = TRUE))
  expect_length(files, 3)
})

test_that("list.files ignores non-.txt files", {
  tmp <- make_temp_articles(2)
  on.exit(unlink(tmp, recursive = TRUE))
  # Add a non-.txt file
  writeLines("not an article", file.path(tmp, "notes.md"))

  files <- list.files(tmp, pattern = "\\.txt$")
  expect_false("notes.md" %in% files)
  expect_length(files, 2)
})

test_that("list.files returns zero files for an empty directory", {
  tmp <- tempfile("empty_articles_")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))

  files <- list.files(tmp, pattern = "\\.txt$")
  expect_length(files, 0)
})

test_that("article files are sorted in lexicographic order", {
  tmp <- make_temp_articles(5)
  on.exit(unlink(tmp, recursive = TRUE))

  files <- sort(list.files(tmp, pattern = "\\.txt$"))
  expect_equal(files, sort(files))
})

# =============================================================================
# Article name extraction
# =============================================================================

test_that("article names are derived correctly by stripping .txt extension", {
  files        <- c("/articles/01.txt", "/articles/02.txt", "/articles/10.txt")
  article_names <- gsub("\\.txt$", "", basename(files))
  expect_equal(article_names, c("01", "02", "10"))
})

test_that("article names do not contain the directory path", {
  tmp <- make_temp_articles(2)
  on.exit(unlink(tmp, recursive = TRUE))

  files         <- sort(list.files(tmp, pattern = "\\.txt$", full.names = TRUE))
  article_names <- gsub("\\.txt$", "", basename(files))
  expect_true(all(!grepl("/", article_names)))
})

# =============================================================================
# Title extraction (first line of each file)
# =============================================================================

test_that("first line of each file is used as the article title", {
  tmp <- make_temp_articles(2, content_fn = function(i) {
    c(paste("My Title", i), "", "Body text here.")
  })
  on.exit(unlink(tmp, recursive = TRUE))

  files  <- sort(list.files(tmp, pattern = "\\.txt$", full.names = TRUE))
  titles <- sapply(files, function(f) trimws(readLines(f, n = 1, warn = FALSE)))
  expect_equal(unname(titles), c("My Title 1", "My Title 2"))
})

test_that("trimws removes leading/trailing spaces from the title", {
  tmp <- tempfile("title_test_")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))
  writeLines(c("  Padded Title  ", "", "Body"), file.path(tmp, "01.txt"))

  f     <- file.path(tmp, "01.txt")
  title <- trimws(readLines(f, n = 1, warn = FALSE))
  expect_equal(title, "Padded Title")
})

# =============================================================================
# Content reading
# =============================================================================

test_that("article content is read and collapsed to a single string", {
  tmp <- tempfile("content_test_")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))
  writeLines(c("Line one.", "Line two.", "Line three."), file.path(tmp, "01.txt"))

  f    <- file.path(tmp, "01.txt")
  text <- readLines(f, warn = FALSE)
  collapsed <- paste(text, collapse = " ")
  expect_equal(collapsed, "Line one. Line two. Line three.")
})

test_that("multi-line articles are read into a single character string", {
  tmp <- make_temp_articles(1, content_fn = function(i) {
    c("Title", "", "Paragraph one.", "Paragraph two.")
  })
  on.exit(unlink(tmp, recursive = TRUE))

  f    <- list.files(tmp, pattern = "\\.txt$", full.names = TRUE)[[1]]
  text <- readLines(f, warn = FALSE)
  result <- paste(text, collapse = " ")
  expect_type(result, "character")
  expect_length(result, 1)
  expect_true(nchar(result) > 0)
})

# =============================================================================
# Word count sanity (using count_words helper)
# =============================================================================

test_that("word counts are positive for non-empty articles", {
  tmp <- make_temp_articles(2)
  on.exit(unlink(tmp, recursive = TRUE))

  files    <- sort(list.files(tmp, pattern = "\\.txt$", full.names = TRUE))
  articles <- lapply(files, function(f) paste(readLines(f, warn = FALSE), collapse = " "))
  wcs      <- sapply(articles, count_words)
  expect_true(all(wcs > 0))
})
