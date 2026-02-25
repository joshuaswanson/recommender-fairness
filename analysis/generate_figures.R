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
# Path Coefficients
# ------------------------------------------------------------------------------

generate_path_coefficients <- function() {
  library(lavaan)

  constructs <- readRDS("analysis/constructs_final.rds")
  df_items <- readRDS("analysis/df_items.rds")

  construct_labels <- c(
    system_quality = "System Quality",
    service_quality = "Service Quality",
    perceived_fairness = "Perceived Fairness",
    perceived_ease_of_use = "Perceived Ease of Use",
    perceived_usefulness = "Perceived Usefulness",
    attitude_toward_use = "Attitude Toward Use",
    behavioral_intention = "Behavioral Intention"
  )

  # Build and fit model
  measurement <- sapply(names(constructs), function(name) {
    paste0(name, " =~ ", paste(constructs[[name]], collapse = " + "))
  })
  structural <- c(
    "perceived_fairness ~ system_quality + service_quality",
    "perceived_ease_of_use ~ system_quality + service_quality",
    "perceived_usefulness ~ system_quality + service_quality + perceived_fairness + perceived_ease_of_use",
    "attitude_toward_use ~ perceived_fairness + perceived_ease_of_use + perceived_usefulness",
    "behavioral_intention ~ attitude_toward_use"
  )
  model <- paste(c(measurement, "", structural), collapse = "\n")
  fit <- sem(model, data = df_items, std.lv = TRUE, estimator = "MLM")

  paths <- standardizedSolution(fit) %>%
    filter(op == "~") %>%
    mutate(
      outcome_label = construct_labels[lhs],
      predictor_label = construct_labels[rhs],
      path = paste(predictor_label, "->", outcome_label),
      path = factor(path, levels = rev(path)),
      significant = pvalue < 0.05
    )

  p <- ggplot(paths, aes(x = path, y = est.std)) +
    geom_col(aes(fill = significant), width = 0.7) +
    geom_errorbar(aes(ymin = est.std - 1.96*se, ymax = est.std + 1.96*se), width = 0.2) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    coord_flip() +
    scale_fill_manual(
      values = c("TRUE" = "steelblue", "FALSE" = "gray70"),
      labels = c("TRUE" = "p < 0.05", "FALSE" = "Not significant"),
      name = NULL
    ) +
    labs(
      title = "FAIR Model: Standardized Path Coefficients",
      subtitle = "Error bars show 95% confidence intervals",
      x = NULL,
      y = "Standardized Beta"
    ) +
    theme(
      plot.title = element_text(face = "bold"),
      legend.position = "bottom"
    )

  ggsave("figures/path_coefficients.png", p, width = 10, height = 6, dpi = 150, bg = "white")
  cat("Saved: figures/path_coefficients.png\n")
}

# ------------------------------------------------------------------------------
# Hypothesis Results
# ------------------------------------------------------------------------------

generate_hypothesis_results <- function() {
  library(lavaan)

  constructs <- readRDS("analysis/constructs_final.rds")
  df_items <- readRDS("analysis/df_items.rds")

  construct_labels <- c(
    system_quality = "System Quality",
    service_quality = "Service Quality",
    perceived_fairness = "Perceived Fairness",
    perceived_ease_of_use = "Perceived Ease of Use",
    perceived_usefulness = "Perceived Usefulness",
    attitude_toward_use = "Attitude Toward Use",
    behavioral_intention = "Behavioral Intention"
  )

  # Build and fit model
  measurement <- sapply(names(constructs), function(name) {
    paste0(name, " =~ ", paste(constructs[[name]], collapse = " + "))
  })
  structural <- c(
    "perceived_fairness ~ system_quality + service_quality",
    "perceived_ease_of_use ~ system_quality + service_quality",
    "perceived_usefulness ~ system_quality + service_quality + perceived_fairness + perceived_ease_of_use",
    "attitude_toward_use ~ perceived_fairness + perceived_ease_of_use + perceived_usefulness",
    "behavioral_intention ~ attitude_toward_use"
  )
  model <- paste(c(measurement, "", structural), collapse = "\n")
  fit <- sem(model, data = df_items, std.lv = TRUE, estimator = "MLM")

  paths <- standardizedSolution(fit) %>%
    filter(op == "~") %>%
    mutate(
      outcome_label = construct_labels[lhs],
      predictor_label = construct_labels[rhs]
    )

  hypotheses <- data.frame(
    Hypothesis = paste0("H", 1:12),
    Path = c(
      "System Quality -> Perceived Fairness",
      "Service Quality -> Perceived Fairness",
      "Perceived Fairness -> Perceived Usefulness",
      "Perceived Fairness -> Attitude Toward Use",
      "System Quality -> Perceived Ease of Use",
      "Service Quality -> Perceived Ease of Use",
      "System Quality -> Perceived Usefulness",
      "Service Quality -> Perceived Usefulness",
      "Perceived Ease of Use -> Perceived Usefulness",
      "Perceived Ease of Use -> Attitude Toward Use",
      "Perceived Usefulness -> Attitude Toward Use",
      "Attitude Toward Use -> Behavioral Intention"
    ),
    stringsAsFactors = FALSE
  )

  hypotheses$Beta <- NA
  hypotheses$p_value <- NA
  hypotheses$Result <- NA

  for (i in 1:nrow(hypotheses)) {
    parts <- strsplit(hypotheses$Path[i], " -> ")[[1]]
    pred <- names(construct_labels)[construct_labels == parts[1]]
    out <- names(construct_labels)[construct_labels == parts[2]]
    match <- paths %>% filter(rhs == pred, lhs == out)
    if (nrow(match) == 1) {
      hypotheses$Beta[i] <- round(match$est.std, 3)
      hypotheses$p_value[i] <- match$pvalue
      hypotheses$Result[i] <- ifelse(match$pvalue < 0.05 & match$est.std > 0, "Supported",
                                      ifelse(match$pvalue < 0.10 & match$est.std > 0, "Marginal", "Not supported"))
    }
  }

  hypotheses$Result <- factor(hypotheses$Result,
                               levels = c("Supported", "Marginal", "Not supported"))
  hypotheses$Hypothesis <- factor(hypotheses$Hypothesis,
                                   levels = rev(paste0("H", 1:12)))

  p <- ggplot(hypotheses, aes(x = Hypothesis, y = Beta)) +
    geom_col(aes(fill = Result), width = 0.7) +
    geom_text(aes(label = sprintf("p = %.3f", p_value)),
              hjust = ifelse(hypotheses$Beta >= 0, -0.1, 1.1), size = 3.5) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    coord_flip() +
    scale_fill_manual(
      values = c("Supported" = "#2E8B57", "Marginal" = "#E69500", "Not supported" = "gray70"),
      name = NULL
    ) +
    labs(
      title = "Hypothesis Testing Results",
      subtitle = "Standardized path coefficients with p-values",
      x = NULL,
      y = "Standardized Beta"
    ) +
    theme(
      plot.title = element_text(face = "bold"),
      legend.position = "bottom"
    )

  ggsave("figures/hypothesis_results.png", p, width = 10, height = 6, dpi = 150, bg = "white")
  cat("Saved: figures/hypothesis_results.png\n")
}

# ------------------------------------------------------------------------------
# Run all
# ------------------------------------------------------------------------------

if (!interactive()) {
  cat("Generating FAIR model diagram...\n")
  generate_fair_model_diagram()

  cat("\nGenerating correlation matrices...\n")
  generate_correlation_matrices()

  cat("\nGenerating path coefficients...\n")
  generate_path_coefficients()

  cat("\nGenerating hypothesis results...\n")
  generate_hypothesis_results()

  cat("\nDone!\n")
}
