# Media Analysis of Fintech and Digital Banking Trends Using Text Mining Techniques

## Subtopic: Blockchain and Cryptocurrency

### Project Overview

This R project applies text mining and classification techniques to analyze trends in blockchain and cryptocurrency within the fintech and digital banking sector. The analysis uses a corpus of articles to identify key themes, compare term frequencies, perform sentiment analysis, and classify content by topic categories.

The code is designed so that **teammates can add new articles without changing any R code** — simply drop a new `.txt` file into the `articles/` folder and re-run.

### Repository Structure

```
├── articles/           # Text article corpus (add new .txt files here)
│   ├── 01.txt          # Blockchain Technology Reshaping Digital Banking
│   └── 02.txt          # Cryptocurrency Regulation and Adoption Trends
├── analysis.R          # Main R script — fully dynamic, no hardcoded article count
├── .gitignore
└── README.md
```

### Articles

| File   | Title | Words | Focus |
|--------|-------|-------|-------|
| 01.txt | Blockchain Technology Reshaping the Future of Digital Banking and Financial Services | 2,729 | Blockchain in banking, cross-border payments, DeFi, CBDCs, tokenization, trade finance |
| 02.txt | Cryptocurrency Regulation and Adoption Trends Transforming Digital Finance | 3,085 | Crypto market dynamics, Bitcoin ETFs, global regulation, stablecoins, institutional adoption |

### How to Add a New Article

1. Write or collect an article (minimum 2,000 words recommended).
2. Save it as a **plain text file** (`.txt`) in the `articles/` folder.
3. Name it with the next sequential number: `03.txt`, `04.txt`, etc.
4. Re-run the script:

```bash
Rscript analysis.R
```

All charts, comparisons, and trend lines will update automatically — **no code changes needed**.

### Analysis Features

The R script (`analysis.R`) performs the following analyses:

1. **Text Preprocessing** — Tokenization, stopword removal, stemming via the `tm` package
2. **Term Frequency Analysis** — Top 20 most frequent terms with bar chart
3. **Word Cloud** — Combined word cloud across all articles + per-article word clouds
4. **TF-IDF Analysis** — Identifies distinctive terms per article
5. **Comparative Term Frequency** — Side-by-side term comparison across all articles
6. **Sentiment Analysis** — Positive/negative word counts using the Bing lexicon
7. **Sentiment Trend** — Net sentiment trend line across articles
8. **Keyword Category Analysis** — Classifies content into blockchain, cryptocurrency, regulation, and banking topics
9. **Topic Focus Trend** — Shows how each article's emphasis shifts between topics
10. **Document Similarity** — Pairwise cosine similarity heatmap

### Generated Visualizations

| File | Description |
|------|-------------|
| `top_terms_barplot.png` | Top 20 frequent terms across all articles |
| `wordcloud.png` | Combined word cloud |
| `wordcloud_01.png`, `wordcloud_02.png`, … | Per-article word clouds |
| `term_comparison.png` | Shared term frequency comparison |
| `sentiment_analysis.png` | Positive vs negative sentiment per article |
| `sentiment_trend.png` | Net sentiment trend line |
| `keyword_trends.png` | Keyword category distribution bars |
| `topic_trend.png` | Topic focus trend lines |
| `similarity_heatmap.png` | Cosine similarity heatmap |

### Required R Packages

- `tm` — Text mining framework
- `SnowballC` — Stemming
- `wordcloud` — Word cloud visualization
- `RColorBrewer` — Color palettes
- `ggplot2` — Data visualization
- `tidytext` — Tidy text mining
- `dplyr`, `tidyr`, `stringr` — Data manipulation

All packages are installed automatically when you run the script.