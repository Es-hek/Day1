# =============================================================================
# Text Mining Analysis: Blockchain and Cryptocurrency Trends
# Topic: Media analysis of fintech and digital banking trends
# Subtopic: Blockchain and cryptocurrency
#
# HOW TO ADD NEW ARTICLES:
#   1. Save your article as a plain text (.txt) file
#   2. Name it sequentially: 03.txt, 04.txt, 05.txt, etc.
#   3. Place it in the "articles/" folder
#   4. Re-run this script — all charts and analysis update automatically
#
# No code changes are needed when adding new articles.
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

# --- 2. Load Articles (auto-detects every .txt in articles/) ---
articles_dir <- file.path(getwd(), "articles")
cat("Loading articles from:", articles_dir, "\n")

article_files <- sort(list.files(articles_dir, pattern = "\\.txt$",
                                  full.names = TRUE))
num_articles  <- length(article_files)
cat("Found", num_articles, "article(s)\n")

if (num_articles == 0) {
  stop("No .txt files found in articles/ — add at least one article and re-run.")
}

articles <- lapply(article_files, function(f) {
  text <- readLines(f, warn = FALSE)
  paste(text, collapse = " ")
})

article_names <- gsub("\\.txt$", "", basename(article_files))
names(articles) <- article_names

# Extract the first line of each file as its title
article_titles <- sapply(article_files, function(f) {
  trimws(readLines(f, n = 1, warn = FALSE))
})
names(article_titles) <- article_names

# Build a friendly label for each article: "01 – Blockchain Technology …"
article_labels <- setNames(
  paste0(article_names, " \u2013 ", substr(article_titles, 1, 40), "..."),
  article_names
)

# Dynamic colour palette that grows with the number of articles
if (num_articles <= 8) {
  article_colours <- setNames(
    head(c("#3498DB", "#F39C12", "#2ECC71", "#E74C3C",
           "#9B59B6", "#1ABC9C", "#E67E22", "#34495E"), num_articles),
    article_names
  )
} else {
  article_colours <- setNames(
    colorRampPalette(brewer.pal(8, "Set2"))(num_articles),
    article_names
  )
}

# Print word counts
cat("\n--- Article Summary ---\n")
for (name in article_names) {
  wc <- length(unlist(strsplit(articles[[name]], "\\s+")))
  cat(sprintf("  Article %s : %d words  |  %s\n", name, wc, article_titles[name]))
}

# --- 3. Create Corpus and Preprocess ---
corpus <- VCorpus(VectorSource(articles))

corpus_clean <- tm_map(corpus, content_transformer(tolower))
corpus_clean <- tm_map(corpus_clean, removePunctuation)
corpus_clean <- tm_map(corpus_clean, removeNumbers)
corpus_clean <- tm_map(corpus_clean, removeWords, stopwords("english"))

custom_stopwords <- c("also", "can", "will", "one", "may", "including",
                      "approximately", "billion", "million", "dollars",
                      "according", "however", "us", "per", "new", "since")
corpus_clean <- tm_map(corpus_clean, removeWords, custom_stopwords)
corpus_clean <- tm_map(corpus_clean, stripWhitespace)
corpus_clean <- tm_map(corpus_clean, stemDocument)

# --- 4. Create Document-Term Matrix ---
dtm <- DocumentTermMatrix(corpus_clean)
cat("\nDocument-Term Matrix:", nrow(dtm), "documents x", ncol(dtm), "terms\n")

# --- 5. Overall Term Frequency ---
term_freq <- colSums(as.matrix(dtm))
term_freq_sorted <- sort(term_freq, decreasing = TRUE)

cat("\n--- Top 30 Most Frequent Terms ---\n")
print(head(term_freq_sorted, 30))

top_terms <- data.frame(
  term      = names(head(term_freq_sorted, 20)),
  frequency = as.numeric(head(term_freq_sorted, 20)),
  stringsAsFactors = FALSE
)
top_terms$term <- factor(top_terms$term, levels = rev(top_terms$term))

png("top_terms_barplot.png", width = 900, height = 600, res = 120)
print(ggplot(top_terms, aes(x = term, y = frequency, fill = frequency)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  scale_fill_gradient(low = "#56B4E9", high = "#D55E00") +
  labs(title = "Top 20 Most Frequent Terms Across All Articles",
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
dtm_tfidf    <- DocumentTermMatrix(corpus_clean,
                                    control = list(weighting = weightTfIdf))
tfidf_matrix <- as.matrix(dtm_tfidf)

cat("\n--- Top TF-IDF Terms per Article ---\n")
for (i in seq_len(nrow(tfidf_matrix))) {
  top_idx <- order(tfidf_matrix[i, ], decreasing = TRUE)[1:10]
  cat(sprintf("\nArticle %s – Top 10 distinctive terms:\n", article_names[i]))
  for (j in top_idx) {
    if (tfidf_matrix[i, j] > 0) {
      cat(sprintf("  %-20s  TF-IDF: %.4f\n",
                  colnames(tfidf_matrix)[j], tfidf_matrix[i, j]))
    }
  }
}

# --- 8. Comparative Term Frequency (dynamic for N articles) ---
freq_by_doc <- as.data.frame(as.matrix(dtm))
rownames(freq_by_doc) <- article_names

common_terms <- colnames(freq_by_doc)[colSums(freq_by_doc > 0) == num_articles]
cat("\nTerms common to ALL articles:", length(common_terms), "\n")

if (length(common_terms) > 0) {
  # Build a data-frame with one column per article
  common_df <- data.frame(term = common_terms, stringsAsFactors = FALSE)
  for (name in article_names) {
    common_df[[name]] <- as.numeric(freq_by_doc[name, common_terms])
  }
  common_df$total <- rowSums(common_df[, article_names, drop = FALSE])
  common_df <- common_df[order(-common_df$total), ]

  cat("\n--- Top 15 Shared Terms ---\n")
  print(head(common_df, 15))

  top_common <- head(common_df, 15)
  plot_data  <- tidyr::pivot_longer(top_common,
                                     cols      = all_of(article_names),
                                     names_to  = "article",
                                     values_to = "count")
  plot_data$term <- factor(plot_data$term, levels = rev(top_common$term))

  png("term_comparison.png", width = 900, height = 600, res = 120)
  p <- ggplot(plot_data, aes(x = term, y = count, fill = article)) +
    geom_bar(stat = "identity", position = "dodge") +
    coord_flip() +
    scale_fill_manual(values = article_colours, labels = article_labels) +
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

bing <- get_sentiments("bing")

sentiment_results <- tidy_articles %>%
  inner_join(bing, by = "word") %>%
  group_by(article, sentiment) %>%
  summarise(count = n(), .groups = "drop")

cat("\nSentiment counts per article:\n")
print(as.data.frame(sentiment_results))

png("sentiment_analysis.png", width = max(600, num_articles * 200), height = 500, res = 120)
print(ggplot(sentiment_results, aes(x = article, y = count, fill = sentiment)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c("negative" = "#E74C3C", "positive" = "#2ECC71")) +
  labs(title = "Sentiment Analysis: Positive vs Negative Words per Article",
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

# --- 10. Sentiment Trend Across Articles ---
png("sentiment_trend.png", width = max(600, num_articles * 200), height = 500, res = 120)
ns_df <- as.data.frame(net_sentiment)
ns_df$article <- factor(ns_df$article, levels = article_names)
print(ggplot(ns_df, aes(x = article, y = net, group = 1)) +
  geom_line(colour = "#2980B9", linewidth = 1.2) +
  geom_point(colour = "#2980B9", size = 3) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  labs(title = "Net Sentiment Trend Across Articles",
       subtitle = "Positive values = optimistic tone; negative = pessimistic tone",
       x = "Article", y = "Net Sentiment (positive \u2013 negative)") +
  theme_minimal() +
  theme(plot.title    = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(size = 9, colour = "grey40")))
dev.off()
cat("Saved: sentiment_trend.png\n")

# --- 11. Topic-Specific Keyword Trend Analysis ---
cat("\n--- Topic-Specific Keyword Analysis ---\n")

blockchain_keywords  <- c("blockchain", "distributed", "ledger", "smart",
                           "contract", "decentralized", "consensus", "node",
                           "immutable", "transparent", "token", "protocol")
crypto_keywords      <- c("bitcoin", "ethereum", "cryptocurrency", "crypto",
                           "mining", "wallet", "exchange", "stablecoin",
                           "defi", "nft", "altcoin", "coin")
regulation_keywords  <- c("regulation", "regulatory", "compliance", "sec",
                           "license", "framework", "policy", "law",
                           "legislation", "oversight", "ban", "tax")
banking_keywords     <- c("bank", "banking", "payment", "finance", "financial",
                           "institution", "deposit", "lending", "credit",
                           "transaction", "settlement", "custody")

count_keywords <- function(text, keywords) {
  text_lower <- tolower(text)
  sum(sapply(keywords, function(kw) {
    str_count(text_lower, paste0("\\b", kw, "\\b"))
  }))
}

keyword_analysis <- data.frame(
  article        = article_names,
  blockchain     = sapply(articles, count_keywords, blockchain_keywords),
  cryptocurrency = sapply(articles, count_keywords, crypto_keywords),
  regulation     = sapply(articles, count_keywords, regulation_keywords),
  banking        = sapply(articles, count_keywords, banking_keywords),
  stringsAsFactors = FALSE
)

cat("\nKeyword category counts per article:\n")
print(keyword_analysis)

keyword_long <- tidyr::pivot_longer(keyword_analysis,
                                     cols      = -article,
                                     names_to  = "category",
                                     values_to = "count")

png("keyword_trends.png", width = max(700, num_articles * 200), height = 500, res = 120)
print(ggplot(keyword_long, aes(x = category, y = count, fill = article)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = article_colours, labels = article_labels) +
  labs(title = "Keyword Category Distribution Across Articles",
       x = "Topic Category", y = "Keyword Occurrences", fill = "Article") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12)))
dev.off()
cat("Saved: keyword_trends.png\n")

# --- 12. Topic Trend Line (keyword proportions across articles) ---
keyword_pct <- keyword_analysis
for (cat_name in c("blockchain", "cryptocurrency", "regulation", "banking")) {
  keyword_pct[[cat_name]] <- keyword_analysis[[cat_name]] /
    rowSums(keyword_analysis[, c("blockchain", "cryptocurrency",
                                  "regulation", "banking")]) * 100
}

keyword_pct_long <- tidyr::pivot_longer(keyword_pct,
                                         cols      = -article,
                                         names_to  = "category",
                                         values_to = "percentage")
keyword_pct_long$article <- factor(keyword_pct_long$article,
                                    levels = article_names)

png("topic_trend.png", width = max(700, num_articles * 200), height = 500, res = 120)
print(ggplot(keyword_pct_long, aes(x = article, y = percentage,
                                    colour = category, group = category)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_colour_manual(values = c(blockchain     = "#3498DB",
                                  cryptocurrency = "#F39C12",
                                  regulation     = "#E74C3C",
                                  banking        = "#2ECC71")) +
  labs(title = "Topic Focus Trend Across Articles",
       subtitle = "Shows how each article's emphasis shifts between topics",
       x = "Article", y = "Share of Keywords (%)", colour = "Topic") +
  theme_minimal() +
  theme(plot.title    = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(size = 9, colour = "grey40")))
dev.off()
cat("Saved: topic_trend.png\n")

# --- 13. Per-Article Word Clouds ---
for (i in seq_along(articles)) {
  name <- article_names[i]
  doc_freq <- as.matrix(dtm)[i, ]
  doc_freq <- doc_freq[doc_freq > 0]

  fname <- paste0("wordcloud_", name, ".png")
  png(fname, width = 700, height = 700, res = 120)
  wordcloud(names(doc_freq), doc_freq,
            min.freq = 1, max.words = 80,
            random.order = FALSE,
            colors = brewer.pal(8, "Dark2"),
            scale = c(3, 0.4))
  title(main = paste("Word Cloud: Article", name))
  dev.off()
  cat(sprintf("Saved: %s\n", fname))
}

# --- 14. Document Similarity (pairwise cosine matrix) ---
cat("\n--- Document Similarity Matrix ---\n")

cosine_similarity <- function(a, b) {
  denom <- sqrt(sum(a^2)) * sqrt(sum(b^2))
  if (denom == 0) return(0)
  sum(a * b) / denom
}

dtm_mat <- as.matrix(dtm)
sim_matrix <- matrix(0, nrow = num_articles, ncol = num_articles,
                      dimnames = list(article_names, article_names))

for (i in seq_len(num_articles)) {
  for (j in seq_len(num_articles)) {
    sim_matrix[i, j] <- cosine_similarity(dtm_mat[i, ], dtm_mat[j, ])
  }
}

print(round(sim_matrix, 4))
cat("(1.0 = identical, 0.0 = completely different)\n")

# Heatmap of similarity (useful once there are 3+ articles)
if (num_articles >= 2) {
  sim_df <- as.data.frame(as.table(sim_matrix))
  colnames(sim_df) <- c("Article_A", "Article_B", "Similarity")

  png("similarity_heatmap.png", width = max(500, num_articles * 120),
      height = max(400, num_articles * 100), res = 120)
  print(ggplot(sim_df, aes(x = Article_A, y = Article_B, fill = Similarity)) +
    geom_tile(colour = "white") +
    geom_text(aes(label = sprintf("%.2f", Similarity)), size = 3.5) +
    scale_fill_gradient(low = "#F9E79F", high = "#1A5276") +
    labs(title = "Document Similarity Heatmap (Cosine)",
         x = "", y = "") +
    theme_minimal() +
    theme(plot.title = element_text(face = "bold", size = 12)))
  dev.off()
  cat("Saved: similarity_heatmap.png\n")
}

# --- 15. Summary ---
cat("\n========================================\n")
cat("SUMMARY OF TEXT MINING ANALYSIS\n")
cat("========================================\n")
cat(sprintf("Total articles analyzed : %d\n", num_articles))
cat(sprintf("Total unique terms      : %d\n", ncol(dtm)))
cat(sprintf("Terms common to all     : %d\n", length(common_terms)))
cat("\nVisualizations generated:\n")
cat("  1. top_terms_barplot.png   – Top 20 frequent terms\n")
cat("  2. wordcloud.png           – Combined word cloud\n")
cat("  3. term_comparison.png     – Per-article term comparison\n")
cat("  4. sentiment_analysis.png  – Sentiment bar chart\n")
cat("  5. sentiment_trend.png     – Net sentiment trend line\n")
cat("  6. keyword_trends.png      – Keyword category bars\n")
cat("  7. topic_trend.png         – Topic focus trend lines\n")
for (name in article_names) {
  cat(sprintf("  *  wordcloud_%s.png       – Word cloud for article %s\n", name, name))
}
cat("  *  similarity_heatmap.png  – Document similarity heatmap\n")
cat("========================================\n")
cat("\nTo add more articles, place new .txt files in articles/ and re-run.\n")
