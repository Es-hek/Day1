# =============================================================================
# functions.R
# Pure helper functions extracted from analysis.R.
# Sourced by analysis.R and by the test suite (tests/testthat/).
# =============================================================================

# --- Package helpers ---------------------------------------------------------

#' Install a package from CRAN if it is not already available.
#'
#' @param pkg Character scalar – the package name.
install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

# --- Text helpers ------------------------------------------------------------

#' Count whole-word occurrences of each keyword in a text string.
#'
#' The match is case-insensitive and uses word-boundary anchors so that,
#' for example, "bank" does NOT match inside "banking".
#'
#' @param text     Character scalar – the text to search.
#' @param keywords Character vector – the keywords to count.
#' @return Integer scalar – total occurrences summed across all keywords.
count_keywords <- function(text, keywords) {
  if (length(keywords) == 0 || nchar(trimws(text)) == 0) return(0L)
  text_lower <- tolower(text)
  sum(sapply(keywords, function(kw) {
    stringr::str_count(text_lower, paste0("\\b", kw, "\\b"))
  }))
}

#' Count the number of whitespace-delimited words in a text string.
#'
#' @param text Character scalar.
#' @return Integer scalar – word count (0 for blank/empty strings).
count_words <- function(text) {
  trimmed <- trimws(text)
  if (nchar(trimmed) == 0L) return(0L)
  length(unlist(strsplit(trimmed, "\\s+")))
}

# --- Similarity --------------------------------------------------------------

#' Compute the cosine similarity between two numeric vectors.
#'
#' Returns 0 when either vector is the zero-vector (avoids division by zero).
#'
#' @param a,b Numeric vectors of equal length.
#' @return Numeric scalar in [0, 1] for non-negative inputs.
cosine_similarity <- function(a, b) {
  denom <- sqrt(sum(a^2)) * sqrt(sum(b^2))
  if (denom == 0) return(0)
  sum(a * b) / denom
}

# --- Visualisation helpers ---------------------------------------------------

#' Build a named colour vector for a set of articles.
#'
#' Uses a fixed palette for up to 8 articles; interpolates a larger palette
#' via RColorBrewer for more.
#'
#' @param article_names Character vector of article identifiers.
#' @return Named character vector of hex colour codes.
build_article_colours <- function(article_names) {
  n <- length(article_names)
  if (n == 0) return(character(0))
  if (n <= 8) {
    colours <- head(c("#3498DB", "#F39C12", "#2ECC71", "#E74C3C",
                      "#9B59B6", "#1ABC9C", "#E67E22", "#34495E"), n)
  } else {
    colours <- grDevices::colorRampPalette(
      RColorBrewer::brewer.pal(8, "Set2")
    )(n)
  }
  setNames(colours, article_names)
}

#' Build human-readable labels for articles.
#'
#' Format: "<name> – <first 40 chars of title>..."
#'
#' @param article_names   Character vector of article identifiers (e.g. "01").
#' @param article_titles  Named character vector mapping each name to its title.
#' @return Named character vector of labels.
build_article_labels <- function(article_names, article_titles) {
  labels <- paste0(article_names, " \u2013 ",
                   substr(article_titles[article_names], 1, 40), "...")
  setNames(labels, article_names)
}

# --- Keyword analysis --------------------------------------------------------

#' Convert raw keyword counts to percentage shares per article.
#'
#' If an article has zero keyword matches across all categories the
#' percentages are all set to 0 (not NaN).
#'
#' @param keyword_df  Data frame with a column per category plus an "article"
#'                    column, as produced by the keyword analysis block.
#' @param categories  Character vector of column names to convert.
#' @return The same data frame with the category columns replaced by
#'         percentage values (0–100).
compute_keyword_percentages <- function(keyword_df, categories) {
  row_totals <- rowSums(keyword_df[, categories, drop = FALSE])
  for (cat_name in categories) {
    keyword_df[[cat_name]] <- ifelse(
      row_totals == 0, 0,
      keyword_df[[cat_name]] / row_totals * 100
    )
  }
  keyword_df
}
