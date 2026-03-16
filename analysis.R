# =============================================================================
# Text Mining Analysis: Blockchain and Cryptocurrency Trends
# Topic: Media analysis of fintech and digital banking trends
# Subtopic: Blockchain and cryptocurrency
# =============================================================================

# --- 1. Install and Load Required Libraries ---
required_packages <- c("tm", "SnowballC", "wordcloud", "RColorBrewer",
                        "ggplot2", "tidytext", "dplyr", "tidyr",
                        "stringr")

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

invisible(lapply(required_packages, install_if_missing))

library(tm)
library(SnowballC)
library(wordcloud)
library(RColorBrewer)
library(ggplot2)
library(tidytext)
library(dplyr)
library(tidyr)
library(stringr)

# --- 2. Load Articles ---
articles_dir <- file.path(getwd(), "articles")
cat("Loading articles from:", articles_dir, "\n")

article_files <- list.files(articles_dir, pattern = "\\.txt$", full.names = TRUE)
cat("Found", length(article_files), "articles\n")

articles <- lapply(article_files, function(f) {
  text <- readLines(f, warn = FALSE)
  paste(text, collapse = " ")
})

article_names <- gsub("\\.txt$", "", basename(article_files))
names(articles) <- article_names

# Print word counts
for (name in names(articles)) {
  word_count <- length(unlist(strsplit(articles[[name]], "\\s+")))
  cat(sprintf("Article %s: %d words\n", name, word_count))
}

# --- 3. Create Corpus and Preprocess ---
corpus <- VCorpus(VectorSource(articles))

corpus_clean <- tm_map(corpus, content_transformer(tolower))
corpus_clean <- tm_map(corpus_clean, removePunctuation)
corpus_clean <- tm_map(corpus_clean, removeNumbers)
corpus_clean <- tm_map(corpus_clean, removeWords, stopwords("english"))

# Custom stop words specific to filler words in articles
custom_stopwords <- c("also", "can", "will", "one", "may", "including",
                      "approximately", "billion", "million", "dollars",
                      "according", "however", "us", "per", "new", "since")
corpus_clean <- tm_map(corpus_clean, removeWords, custom_stopwords)
corpus_clean <- tm_map(corpus_clean, stripWhitespace)
corpus_clean <- tm_map(corpus_clean, stemDocument)

# --- 4. Create Document-Term Matrix ---
dtm <- DocumentTermMatrix(corpus_clean)
cat("\nDocument-Term Matrix dimensions:", dim(dtm), "\n")
cat("Number of terms:", ncol(dtm), "\n")
cat("Number of documents:", nrow(dtm), "\n")

# Remove sparse terms (keep terms appearing in at least 1 document)
dtm_dense <- removeSparseTerms(dtm, 0.99)
cat("After removing sparse terms:", ncol(dtm_dense), "terms remain\n")

# --- 5. Term Frequency Analysis ---
term_freq <- colSums(as.matrix(dtm))
term_freq_sorted <- sort(term_freq, decreasing = TRUE)

cat("\n--- Top 30 Most Frequent Terms ---\n")
print(head(term_freq_sorted, 30))

# Create data frame for plotting
top_terms <- data.frame(
  term = names(head(term_freq_sorted, 20)),
  frequency = as.numeric(head(term_freq_sorted, 20)),
  stringsAsFactors = FALSE
)
top_terms$term <- factor(top_terms$term, levels = rev(top_terms$term))

# Plot: Top 20 terms bar chart
png("top_terms_barplot.png", width = 900, height = 600, res = 120)
print(ggplot(top_terms, aes(x = term, y = frequency, fill = frequency)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  scale_fill_gradient(low = "#56B4E9", high = "#D55E00") +
  labs(title = "Top 20 Most Frequent Terms in Blockchain & Cryptocurrency Articles",
       x = "Term", y = "Frequency") +
  theme_minimal() +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold", size = 12)))
dev.off()
cat("Saved: top_terms_barplot.png\n")

# --- 6. Word Cloud ---
png("wordcloud.png", width = 800, height = 800, res = 120)
wordcloud(names(term_freq), term_freq,
          min.freq = 2, max.words = 100,
          random.order = FALSE,
          colors = brewer.pal(8, "Dark2"),
          scale = c(3, 0.5))
title(main = "Word Cloud: Blockchain & Cryptocurrency Articles")
dev.off()
cat("Saved: wordcloud.png\n")

# --- 7. TF-IDF Analysis ---
dtm_tfidf <- DocumentTermMatrix(corpus_clean,
                                 control = list(weighting = weightTfIdf))

tfidf_matrix <- as.matrix(dtm_tfidf)

cat("\n--- Top TF-IDF Terms per Article ---\n")
for (i in seq_len(nrow(tfidf_matrix))) {
  top_idx <- order(tfidf_matrix[i, ], decreasing = TRUE)[1:10]
  cat(sprintf("\nArticle %s - Top 10 distinctive terms:\n", article_names[i]))
  for (j in top_idx) {
    if (tfidf_matrix[i, j] > 0) {
      cat(sprintf("  %-20s  TF-IDF: %.4f\n",
                  colnames(tfidf_matrix)[j], tfidf_matrix[i, j]))
    }
  }
}

# --- 8. Comparative Term Frequency Between Articles ---
freq_by_doc <- as.data.frame(as.matrix(dtm))
rownames(freq_by_doc) <- article_names

# Get terms that appear in both documents
common_terms <- colnames(freq_by_doc)[colSums(freq_by_doc > 0) == nrow(freq_by_doc)]
cat("\nNumber of terms common to all articles:", length(common_terms), "\n")

if (length(common_terms) > 0) {
  common_df <- data.frame(
    term = common_terms,
    article_01 = as.numeric(freq_by_doc["01", common_terms]),
    article_02 = as.numeric(freq_by_doc["02", common_terms]),
    stringsAsFactors = FALSE
  )
  common_df$total <- common_df$article_01 + common_df$article_02
  common_df <- common_df[order(-common_df$total), ]

  cat("\n--- Top 15 Shared Terms Across Articles ---\n")
  print(head(common_df, 15))

  # Plot comparison
  top_common <- head(common_df, 15)
  plot_data <- tidyr::pivot_longer(top_common,
                                    cols = c("article_01", "article_02"),
                                    names_to = "article",
                                    values_to = "count")
  plot_data$term <- factor(plot_data$term,
                            levels = rev(top_common$term))

  png("term_comparison.png", width = 900, height = 600, res = 120)
  p <- ggplot(plot_data, aes(x = term, y = count, fill = article)) +
    geom_bar(stat = "identity", position = "dodge") +
    coord_flip() +
    scale_fill_manual(values = c("article_01" = "#0072B2", "article_02" = "#E69F00"),
                      labels = c("Article 01 (Blockchain in Banking)",
                                 "Article 02 (Crypto Regulation)")) +
    labs(title = "Term Frequency Comparison Across Articles",
         x = "Term", y = "Frequency", fill = "Article") +
    theme_minimal() +
    theme(plot.title = element_text(face = "bold", size = 12))
  print(p)
  dev.off()
  cat("Saved: term_comparison.png\n")
}

# --- 9. Sentiment Analysis ---
cat("\n--- Sentiment Analysis ---\n")

tidy_list <- lapply(seq_along(articles), function(i) {
  words <- unlist(strsplit(tolower(articles[[i]]), "[^a-z']+"))
  words <- words[words != ""]
  data.frame(article = article_names[i], word = words, stringsAsFactors = FALSE)
})
tidy_articles <- do.call(rbind, tidy_list)

# Use Bing sentiment lexicon
bing <- get_sentiments("bing")

sentiment_results <- tidy_articles %>%
  inner_join(bing, by = "word") %>%
  group_by(article, sentiment) %>%
  summarise(count = n(), .groups = "drop")

cat("\nSentiment counts per article:\n")
print(as.data.frame(sentiment_results))

# Plot sentiment analysis
png("sentiment_analysis.png", width = 800, height = 500, res = 120)
print(ggplot(sentiment_results, aes(x = article, y = count, fill = sentiment)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c("negative" = "#E74C3C", "positive" = "#2ECC71")) +
  labs(title = "Sentiment Analysis: Blockchain & Cryptocurrency Articles",
       x = "Article", y = "Word Count", fill = "Sentiment") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12)))
dev.off()
cat("Saved: sentiment_analysis.png\n")

# Net sentiment per article
net_sentiment <- sentiment_results %>%
  pivot_wider(names_from = sentiment, values_from = count, values_fill = 0) %>%
  mutate(net = positive - negative)

cat("\nNet sentiment per article:\n")
print(as.data.frame(net_sentiment))

# --- 10. Topic-Specific Keyword Trend Analysis ---
cat("\n--- Topic-Specific Keyword Analysis ---\n")

blockchain_keywords <- c("blockchain", "distributed", "ledger", "smart",
                          "contract", "decentralized", "consensus", "node",
                          "immutable", "transparent", "token", "protocol")

crypto_keywords <- c("bitcoin", "ethereum", "cryptocurrency", "crypto",
                      "mining", "wallet", "exchange", "stablecoin",
                      "defi", "nft", "altcoin", "coin")

regulation_keywords <- c("regulation", "regulatory", "compliance", "sec",
                          "license", "framework", "policy", "law",
                          "legislation", "oversight", "ban", "tax")

banking_keywords <- c("bank", "banking", "payment", "finance", "financial",
                       "institution", "deposit", "lending", "credit",
                       "transaction", "settlement", "custody")

count_keywords <- function(text, keywords) {
  text_lower <- tolower(text)
  sum(sapply(keywords, function(kw) {
    str_count(text_lower, paste0("\\b", kw, "\\b"))
  }))
}

keyword_analysis <- data.frame(
  article = article_names,
  blockchain = sapply(articles, count_keywords, blockchain_keywords),
  cryptocurrency = sapply(articles, count_keywords, crypto_keywords),
  regulation = sapply(articles, count_keywords, regulation_keywords),
  banking = sapply(articles, count_keywords, banking_keywords),
  stringsAsFactors = FALSE
)

cat("\nKeyword category counts per article:\n")
print(keyword_analysis)

# Plot keyword analysis
keyword_long <- tidyr::pivot_longer(keyword_analysis,
                                     cols = -article,
                                     names_to = "category",
                                     values_to = "count")

png("keyword_trends.png", width = 800, height = 500, res = 120)
print(ggplot(keyword_long, aes(x = category, y = count, fill = article)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c("01" = "#3498DB", "02" = "#F39C12"),
                    labels = c("Article 01 (Blockchain in Banking)",
                               "Article 02 (Crypto Regulation)")) +
  labs(title = "Keyword Category Distribution Across Articles",
       x = "Topic Category", y = "Keyword Occurrences", fill = "Article") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12)))
dev.off()
cat("Saved: keyword_trends.png\n")

# --- 11. Document Similarity (Cosine Similarity) ---
cat("\n--- Document Similarity ---\n")

cosine_similarity <- function(a, b) {
  sum(a * b) / (sqrt(sum(a^2)) * sqrt(sum(b^2)))
}

dtm_mat <- as.matrix(dtm)
if (nrow(dtm_mat) >= 2) {
  sim <- cosine_similarity(dtm_mat[1, ], dtm_mat[2, ])
  cat(sprintf("Cosine similarity between Article 01 and Article 02: %.4f\n", sim))
  cat("(1.0 = identical, 0.0 = completely different)\n")
}

# --- 12. Summary Statistics ---
cat("\n========================================\n")
cat("SUMMARY OF TEXT MINING ANALYSIS\n")
cat("========================================\n")
cat(sprintf("Total articles analyzed: %d\n", length(articles)))
cat(sprintf("Total unique terms: %d\n", ncol(dtm)))
cat(sprintf("Total common terms: %d\n", length(common_terms)))
cat(sprintf("Document similarity: %.4f\n", sim))
cat("\nVisualizations generated:\n")
cat("  1. top_terms_barplot.png  - Top 20 frequent terms\n")
cat("  2. wordcloud.png         - Word cloud of all terms\n")
cat("  3. term_comparison.png   - Term frequency comparison\n")
cat("  4. sentiment_analysis.png - Sentiment analysis\n")
cat("  5. keyword_trends.png    - Keyword category trends\n")
cat("========================================\n")
