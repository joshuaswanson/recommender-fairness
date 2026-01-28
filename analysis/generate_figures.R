# Generate figures for the FAIR model analysis
#
# Run from project root:
#   Rscript -e "renv::activate(); source('analysis/generate_figures.R')"

library(ggplot2)
library(corrplot)
library(dplyr)

# ------------------------------------------------------------------------------
# FAIR Model Diagram
# ------------------------------------------------------------------------------

generate_fair_model_diagram <- function() {
  nodes <- data.frame(
    name = c("System\nQuality", "Service\nQuality", "Perceived\nFairness",
             "Perceived\nUsefulness", "Perceived\nEase of Use",
             "Attitude", "Behavioral\nIntention"),
    short = c("SQ", "SeQ", "PF", "PU", "PEOU", "ATT", "BI"),
    x = c(0, 0, 3, 3, 3, 6, 9),
    y = c(4, -1, 4, 1.5, -1, 1.5, 1.5),
    stringsAsFactors = FALSE
  )

  edges <- data.frame(
    from = c("SQ", "SeQ", "PF", "PF", "SQ", "SeQ", "SQ", "SeQ", "PEOU", "PEOU", "PU", "ATT"),
    to = c("PF", "PF", "PU", "ATT", "PEOU", "PEOU", "PU", "PU", "PU", "ATT", "ATT", "BI"),
    beta = c(0.27, 0.06, 0.05, -0.02, 0.05, 0.93, 0.77, -1.57, 1.74, 0.87, 0.00, 1.00),
    pval = c(0.059, 0.686, 0.321, 0.584, 0.756, 0.000, 0.018, 0.400, 0.316, 0.000, 0.996, 0.000),
    stringsAsFactors = FALSE
  )

  edges$sig <- ifelse(edges$pval < 0.05, "sig",
               ifelse(edges$pval < 0.10, "marginal", "ns"))

  edges$x_start <- nodes$x[match(edges$from, nodes$short)]
  edges$y_start <- nodes$y[match(edges$from, nodes$short)]
  edges$x_end <- nodes$x[match(edges$to, nodes$short)]
  edges$y_end <- nodes$y[match(edges$to, nodes$short)]

  edges$x_mid <- (edges$x_start + edges$x_end) / 2
  edges$y_mid <- (edges$y_start + edges$y_end) / 2

  # Manual offsets to avoid label overlap
  edges$x_off <- 0
  edges$y_off <- 0
  edges$y_off[edges$from == "SQ" & edges$to == "PU"] <- 0.4
  edges$y_off[edges$from == "SeQ" & edges$to == "PU"] <- -0.4
  edges$x_off[edges$from == "PF" & edges$to == "PU"] <- -0.5
  edges$x_off[edges$from == "PEOU" & edges$to == "PU"] <- -0.5
  edges$y_off[edges$from == "PEOU" & edges$to == "ATT"] <- -0.35
  edges$y_off[edges$from == "PU" & edges$to == "ATT"] <- 0.35
  edges$y_off[edges$from == "PF" & edges$to == "ATT"] <- 0.4

  p <- ggplot() +
    geom_segment(
      data = edges,
      aes(x = x_start, y = y_start, xend = x_end, yend = y_end,
          color = sig, linewidth = sig),
      arrow = arrow(length = unit(0.35, "cm"), type = "closed")
    ) +
    geom_label(
      data = edges,
      aes(x = x_mid + x_off, y = y_mid + y_off,
          label = sprintf("%.2f", beta), fill = sig),
      size = 5, label.padding = unit(0.25, "lines"),
      color = "white", fontface = "bold"
    ) +
    geom_point(
      data = nodes,
      aes(x = x, y = y),
      shape = 21, size = 32, fill = "white", color = "gray30", stroke = 2
    ) +
    geom_text(
      data = nodes,
      aes(x = x, y = y, label = name),
      size = 4.5, lineheight = 0.85
    ) +
    scale_color_manual(
      values = c("sig" = "#2E8B57", "marginal" = "#E69500", "ns" = "#999999"),
      labels = c("sig" = "p < 0.05", "marginal" = "p < 0.10", "ns" = "Not significant"),
      name = NULL
    ) +
    scale_fill_manual(
      values = c("sig" = "#2E8B57", "marginal" = "#E69500", "ns" = "#999999"),
      guide = "none"
    ) +
    scale_linewidth_manual(
      values = c("sig" = 2, "marginal" = 1.5, "ns" = 0.8),
      guide = "none"
    ) +
    theme_void() +
    theme(
      legend.position = "bottom",
      legend.text = element_text(size = 14),
      plot.title = element_text(hjust = 0.5, face = "bold", size = 20),
      plot.subtitle = element_text(hjust = 0.5, size = 14, color = "gray40"),
      plot.margin = margin(20, 20, 20, 20)
    ) +
    labs(
      title = "FAIR Model: Path Coefficients",
      subtitle = "Standardized coefficients shown on paths"
    ) +
    coord_fixed(ratio = 0.5, xlim = c(-1.8, 10.8), ylim = c(-2.5, 5.5))

  ggsave("figures/fair_model.png", p, width = 16, height = 10, dpi = 150, bg = "white")
  cat("Saved: figures/fair_model.png\n")
}

# ------------------------------------------------------------------------------
# Correlation Matrices
# ------------------------------------------------------------------------------

generate_correlation_matrices <- function() {
  df <- read.csv("data/Dec2BonusDataset.csv")

  # Reverse-code items
  reverse_items <- c("Q2", "Q7", "Q9", "Q15", "Q25", "Q31", "Q37", "Q42")
  for (item in reverse_items) {
    df[[item]] <- 6 - df[[item]]
  }

  constructs <- list(
    system_quality = paste0("Q", 0:5),
    service_quality = paste0("Q", 6:15),
    perceived_fairness = paste0("Q", 16:23),
    perceived_ease_of_use = paste0("Q", 24:28),
    perceived_usefulness = paste0("Q", 29:35),
    attitude_toward_use = paste0("Q", 36:39),
    behavioral_intention = paste0("Q", 40:44)
  )

  construct_labels <- c(
    system_quality = "System Quality",
    service_quality = "Service Quality",
    perceived_fairness = "Perceived Fairness",
    perceived_ease_of_use = "Perceived Ease of Use",
    perceived_usefulness = "Perceived Usefulness",
    attitude_toward_use = "Attitude Toward Use",
    behavioral_intention = "Behavioral Intention"
  )

  # Per-construct correlation matrices
  for (name in names(constructs)) {
    items <- constructs[[name]]
    subset_df <- df[, items]
    cor_matrix <- cor(subset_df, use = "complete.obs")

    filename <- paste0("figures/", name, "_correlation.png")
    png(filename, width = 600, height = 500, res = 100)
    corrplot(
      cor_matrix,
      method = "color",
      type = "lower",
      addCoef.col = "black",
      tl.col = "black",
      tl.srt = 45,
      col = colorRampPalette(c("steelblue", "white", "firebrick"))(100),
      title = paste(construct_labels[name], "- Item Correlations"),
      mar = c(0, 0, 2, 0),
      number.cex = 0.8
    )
    dev.off()
    cat("Saved:", filename, "\n")
  }

  # Inter-construct correlation matrix
  construct_scores <- data.frame(
    system_quality = rowMeans(df[, constructs$system_quality]),
    service_quality = rowMeans(df[, constructs$service_quality]),
    perceived_fairness = rowMeans(df[, constructs$perceived_fairness]),
    perceived_ease_of_use = rowMeans(df[, constructs$perceived_ease_of_use]),
    perceived_usefulness = rowMeans(df[, constructs$perceived_usefulness]),
    attitude_toward_use = rowMeans(df[, constructs$attitude_toward_use]),
    behavioral_intention = rowMeans(df[, constructs$behavioral_intention])
  )

  cor_constructs <- cor(construct_scores, use = "complete.obs")
  rownames(cor_constructs) <- construct_labels
  colnames(cor_constructs) <- construct_labels

  png("figures/construct_correlations.png", width = 800, height = 700, res = 100)
  corrplot(
    cor_constructs,
    method = "color",
    type = "lower",
    addCoef.col = "black",
    tl.col = "black",
    tl.srt = 45,
    col = colorRampPalette(c("steelblue", "white", "firebrick"))(100),
    title = "Inter-Construct Correlations",
    mar = c(0, 0, 2, 0)
  )
  dev.off()
  cat("Saved: figures/construct_correlations.png\n")
}

# ------------------------------------------------------------------------------
# Run all
# ------------------------------------------------------------------------------

if (!interactive()) {
  cat("Generating FAIR model diagram...\n")
  generate_fair_model_diagram()

  cat("\nGenerating correlation matrices...\n")
  generate_correlation_matrices()

  cat("\nDone!\n")
}
