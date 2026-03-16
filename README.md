# Media Analysis of Fintech and Digital Banking Trends Using Text Mining Techniques

## Subtopic: Blockchain and Cryptocurrency

### Project Overview

This R project applies text mining and classification techniques to analyze trends in blockchain and cryptocurrency within the fintech and digital banking sector. The analysis uses a corpus of articles to identify key themes, compare term frequencies, perform sentiment analysis, and classify content by topic categories.

### Repository Structure

```
├── articles/           # Text article corpus
│   ├── 01.txt          # Blockchain Technology Reshaping Digital Banking (2729 words)
│   └── 02.txt          # Cryptocurrency Regulation and Adoption Trends (3085 words)
├── analysis.R          # Main R script for text mining and analysis
├── .gitignore
└── README.md
```

### Articles

| File   | Title | Words | Focus |
|--------|-------|-------|-------|
| 01.txt | Blockchain Technology Reshaping the Future of Digital Banking and Financial Services | 2,729 | Blockchain in banking, cross-border payments, DeFi, CBDCs, tokenization, trade finance |
| 02.txt | Cryptocurrency Regulation and Adoption Trends Transforming Digital Finance | 3,085 | Crypto market dynamics, Bitcoin ETFs, global regulation, stablecoins, institutional adoption |

### Analysis Features

The R script (`analysis.R`) performs the following analyses:

1. **Text Preprocessing** — Tokenization, stopword removal, stemming via the `tm` package
2. **Term Frequency Analysis** — Top 20 most frequent terms with bar chart visualization
3. **Word Cloud** — Visual representation of term frequency across all articles
4. **TF-IDF Analysis** — Identifies distinctive terms per article using Term Frequency–Inverse Document Frequency
5. **Comparative Term Frequency** — Side-by-side comparison of shared terms between articles
6. **Sentiment Analysis** — Positive/negative sentiment classification using the Bing lexicon
7. **Keyword Category Analysis** — Classification of content into blockchain, cryptocurrency, regulation, and banking categories
8. **Document Similarity** — Cosine similarity measurement between articles

### How to Run

1. Install R (version 4.0 or higher)
2. Open a terminal in the project root directory
3. Run:

```bash
Rscript analysis.R
```

The script will automatically install any missing R packages and generate five visualization PNG files:
- `top_terms_barplot.png` — Top 20 frequent terms
- `wordcloud.png` — Word cloud of all terms
- `term_comparison.png` — Term frequency comparison between articles
- `sentiment_analysis.png` — Sentiment analysis results
- `keyword_trends.png` — Keyword category distribution

### Required R Packages

- `tm` — Text mining framework
- `SnowballC` — Stemming
- `wordcloud` — Word cloud visualization
- `RColorBrewer` — Color palettes
- `ggplot2` — Data visualization
- `tidytext` — Tidy text mining
- `dplyr`, `tidyr`, `stringr` — Data manipulation