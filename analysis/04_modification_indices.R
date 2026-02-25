# Modification Indices Analysis
#
# Extracts modification indices from the FAIR SEM model to identify
# cross-loadings and error covariances that could improve model fit.
# Must be run after 01_reliability.Rmd, 02_cfa.Rmd, and 03_sem.Rmd.

library(lavaan)
library(semTools)
library(dplyr)

# Load saved objects from the pipeline
constructs <- readRDS("constructs_final.rds")
df_items <- readRDS("df_items.rds")

construct_labels <- c(
  system_quality = "System Quality",
  service_quality = "Service Quality",
  perceived_fairness = "Perceived Fairness",
  perceived_ease_of_use = "Perceived Ease of Use",
  perceived_usefulness = "Perceived Usefulness",
  attitude_toward_use = "Attitude Toward Use",
  behavioral_intention = "Behavioral Intention"
)

# Rebuild and fit the FAIR model
build_sem_model <- function(constructs, structural_paths) {
  measurement <- sapply(names(constructs), function(name) {
    items <- constructs[[name]]
    paste0(name, " =~ ", paste(items, collapse = " + "))
  })
  paste(c(measurement, "", "# Structural paths", structural_paths), collapse = "\n")
}

fair_paths <- c(
  "perceived_fairness ~ system_quality + service_quality",
  "perceived_ease_of_use ~ system_quality + service_quality",
  "perceived_usefulness ~ system_quality + service_quality + perceived_fairness + perceived_ease_of_use",
  "attitude_toward_use ~ perceived_fairness + perceived_ease_of_use + perceived_usefulness",
  "behavioral_intention ~ attitude_toward_use"
)

fair_model <- build_sem_model(constructs, fair_paths)
fit_fair <- sem(fair_model, data = df_items, std.lv = TRUE, estimator = "MLM")

# Current model fit
cat("=== Current Model Fit ===\n\n")
fit_measures <- fitMeasures(fit_fair, c("cfi", "tli", "rmsea", "srmr"))
for (name in names(fit_measures)) {
  cat(sprintf("  %s: %.3f\n", toupper(name), fit_measures[name]))
}

# Modification indices
cat("\n=== Top 30 Modification Indices ===\n\n")
mi <- modificationIndices(fit_fair, sort. = TRUE, minimum.value = 3.84)
mi_top <- head(mi, 30)
mi_top$label_lhs <- ifelse(mi_top$lhs %in% names(construct_labels),
                            construct_labels[mi_top$lhs], mi_top$lhs)
mi_top$label_rhs <- ifelse(mi_top$rhs %in% names(construct_labels),
                            construct_labels[mi_top$rhs], mi_top$rhs)

print(as.data.frame(mi_top %>% select(lhs, op, rhs, mi, epc, sepc.all)))

# Separate by type
cat("\n=== Cross-Loadings (item loading on non-parent construct) ===\n\n")
mi_crossload <- mi %>%
  filter(op == "=~") %>%
  head(15)
if (nrow(mi_crossload) > 0) {
  mi_crossload$construct <- construct_labels[mi_crossload$lhs]
  print(as.data.frame(mi_crossload %>% select(construct, rhs, mi, epc, sepc.all)))
} else {
  cat("No significant cross-loadings suggested.\n")
}

cat("\n=== Error Covariances (correlated residuals between items) ===\n\n")
mi_errcov <- mi %>%
  filter(op == "~~", !lhs %in% names(construct_labels), !rhs %in% names(construct_labels)) %>%
  head(15)
if (nrow(mi_errcov) > 0) {
  print(as.data.frame(mi_errcov %>% select(lhs, rhs, mi, epc, sepc.all)))
} else {
  cat("No significant error covariances suggested.\n")
}

# Save original paths for later comparison
paths_orig <- standardizedSolution(fit_fair) %>%
  filter(op == "~") %>%
  select(lhs, rhs, beta_orig = est.std, p_orig = pvalue)

# Identify reverse-coded items in the error covariances
reverse_items <- c("Q2", "Q7", "Q9", "Q15", "Q25", "Q31", "Q37", "Q42")
cat("\n=== Reverse-Coded Items in Top Error Covariances ===\n\n")
mi_errcov_check <- mi %>%
  filter(op == "~~", !lhs %in% names(construct_labels), !rhs %in% names(construct_labels)) %>%
  head(15) %>%
  mutate(
    lhs_reversed = lhs %in% reverse_items,
    rhs_reversed = rhs %in% reverse_items,
    both_reversed = lhs_reversed & rhs_reversed
  )
print(as.data.frame(mi_errcov_check %>%
  select(lhs, rhs, mi, both_reversed) %>%
  mutate(mi = round(mi, 1))))

# Try refit with just the top 3 error covariances (all reverse-coded pairs)
cat("\n=== Refit with Top 3 Reverse-Coded Error Covariances ===\n\n")
extra_covs <- c("Q31 ~~ Q37", "Q37 ~~ Q42", "Q31 ~~ Q42")
cat("Adding error covariances:\n")
for (cov in extra_covs) cat("  ", cov, "\n")

fair_model_v2 <- paste(c(fair_model, "", "# Reverse-coded item covariances", extra_covs),
                        collapse = "\n")
fit_v2 <- tryCatch(
  sem(fair_model_v2, data = df_items, std.lv = TRUE, estimator = "MLM"),
  warning = function(w) {
    cat("Warning:", conditionMessage(w), "\n")
    suppressWarnings(sem(fair_model_v2, data = df_items, std.lv = TRUE, estimator = "MLM"))
  }
)

if (lavInspect(fit_v2, "converged")) {
  cat("\nModel converged.\n\n")
  fit_v2_measures <- fitMeasures(fit_v2, c("cfi", "tli", "rmsea", "srmr"))
  cat("Modified model fit:\n")
  for (name in names(fit_v2_measures)) {
    cat(sprintf("  %s: %.3f (was %.3f, delta = %+.3f)\n",
                toupper(name), fit_v2_measures[name], fit_measures[name],
                fit_v2_measures[name] - fit_measures[name]))
  }

  cat("\n=== Path Coefficients Comparison (Original vs Modified) ===\n\n")
  paths_v2 <- standardizedSolution(fit_v2) %>%
    filter(op == "~") %>%
    select(lhs, rhs, beta_mod = est.std, p_mod = pvalue)

  comparison <- merge(paths_orig, paths_v2, by = c("lhs", "rhs"))
  comparison$lhs_label <- construct_labels[comparison$lhs]
  comparison$rhs_label <- construct_labels[comparison$rhs]
  comparison$delta_beta <- comparison$beta_mod - comparison$beta_orig

  print(as.data.frame(comparison %>%
    select(Path_To = lhs_label, Path_From = rhs_label,
           Beta_Orig = beta_orig, Beta_Mod = beta_mod, Delta = delta_beta,
           p_Orig = p_orig, p_Mod = p_mod) %>%
    mutate(across(where(is.numeric), ~round(., 3)))))
} else {
  cat("Model did not converge.\n")
}

# Try a method factor approach for all reverse-coded items still in the model
cat("\n=== Refit with Reverse-Coded Method Factor ===\n\n")
items_in_model <- unlist(constructs)
reverse_in_model <- intersect(reverse_items, items_in_model)
cat("Reverse-coded items still in model:", paste(reverse_in_model, collapse = ", "), "\n")

method_factor <- paste0("method =~ ", paste(reverse_in_model, collapse = " + "))
cat("Method factor:", method_factor, "\n\n")

fair_model_method <- paste(c(fair_model, "", "# Method factor for reverse-coded items",
                              method_factor,
                              "method ~~ 0*system_quality",
                              "method ~~ 0*service_quality",
                              "method ~~ 0*perceived_fairness",
                              "method ~~ 0*perceived_ease_of_use",
                              "method ~~ 0*perceived_usefulness",
                              "method ~~ 0*attitude_toward_use",
                              "method ~~ 0*behavioral_intention"),
                            collapse = "\n")

fit_method <- tryCatch(
  sem(fair_model_method, data = df_items, std.lv = TRUE, estimator = "MLM"),
  warning = function(w) {
    cat("Warning:", conditionMessage(w), "\n")
    suppressWarnings(sem(fair_model_method, data = df_items, std.lv = TRUE, estimator = "MLM"))
  }
)

if (lavInspect(fit_method, "converged")) {
  cat("Model converged.\n\n")
  fit_method_measures <- fitMeasures(fit_method, c("cfi", "tli", "rmsea", "srmr"))
  cat("Method factor model fit:\n")
  for (name in names(fit_method_measures)) {
    cat(sprintf("  %s: %.3f (was %.3f, delta = %+.3f)\n",
                toupper(name), fit_method_measures[name], fit_measures[name],
                fit_method_measures[name] - fit_measures[name]))
  }

  cat("\n=== Path Coefficients with Method Factor ===\n\n")
  paths_method <- standardizedSolution(fit_method) %>%
    filter(op == "~") %>%
    select(lhs, rhs, beta_method = est.std, p_method = pvalue)

  comparison2 <- merge(paths_orig, paths_method, by = c("lhs", "rhs"))
  comparison2$lhs_label <- construct_labels[comparison2$lhs]
  comparison2$rhs_label <- construct_labels[comparison2$rhs]
  comparison2$delta_beta <- comparison2$beta_method - comparison2$beta_orig

  print(as.data.frame(comparison2 %>%
    select(Path_To = lhs_label, Path_From = rhs_label,
           Beta_Orig = beta_orig, Beta_Method = beta_method, Delta = delta_beta,
           p_Orig = p_orig, p_Method = p_method) %>%
    mutate(across(where(is.numeric), ~round(., 3)))))

  # Show method factor loadings
  cat("\n=== Method Factor Loadings ===\n\n")
  method_loadings <- standardizedSolution(fit_method) %>%
    filter(op == "=~", lhs == "method") %>%
    select(item = rhs, loading = est.std, pvalue)
  print(as.data.frame(method_loadings %>%
    mutate(loading = round(loading, 3), pvalue = round(pvalue, 4))))
} else {
  cat("Method factor model did not converge.\n")
}

# Test model with direct Perceived Usefulness -> Behavioral Intention path
# This path exists in the original TAM (Davis, 1989) but was omitted in the FAIR model.
cat("\n=== FAIR Model + Direct PU -> BI Path (TAM-supported) ===\n\n")

fair_paths_pu_bi <- c(
  "perceived_fairness ~ system_quality + service_quality",
  "perceived_ease_of_use ~ system_quality + service_quality",
  "perceived_usefulness ~ system_quality + service_quality + perceived_fairness + perceived_ease_of_use",
  "attitude_toward_use ~ perceived_fairness + perceived_ease_of_use + perceived_usefulness",
  "behavioral_intention ~ attitude_toward_use + perceived_usefulness"
)

fair_model_pu_bi <- build_sem_model(constructs, fair_paths_pu_bi)
cat("Added path: behavioral_intention ~ perceived_usefulness\n\n")

fit_pu_bi <- tryCatch(
  sem(fair_model_pu_bi, data = df_items, std.lv = TRUE, estimator = "MLM"),
  warning = function(w) {
    cat("Warning:", conditionMessage(w), "\n")
    suppressWarnings(sem(fair_model_pu_bi, data = df_items, std.lv = TRUE, estimator = "MLM"))
  }
)

if (lavInspect(fit_pu_bi, "converged")) {
  cat("Model converged.\n\n")

  fit_pu_bi_measures <- fitMeasures(fit_pu_bi, c("cfi", "tli", "rmsea", "srmr"))
  cat("Model fit:\n")
  for (name in names(fit_pu_bi_measures)) {
    cat(sprintf("  %s: %.3f (original: %.3f, delta = %+.3f)\n",
                toupper(name), fit_pu_bi_measures[name], fit_measures[name],
                fit_pu_bi_measures[name] - fit_measures[name]))
  }

  cat("\n=== All Path Coefficients ===\n\n")
  paths_pu_bi <- standardizedSolution(fit_pu_bi) %>%
    filter(op == "~") %>%
    select(lhs, rhs, beta = est.std, se, pvalue) %>%
    mutate(
      lhs_label = construct_labels[lhs],
      rhs_label = construct_labels[rhs],
      sig = case_when(
        pvalue < 0.001 ~ "***",
        pvalue < 0.01 ~ "**",
        pvalue < 0.05 ~ "*",
        pvalue < 0.10 ~ ".",
        TRUE ~ ""
      )
    )

  print(as.data.frame(paths_pu_bi %>%
    select(Path_To = lhs_label, Path_From = rhs_label,
           Beta = beta, SE = se, p = pvalue, Sig = sig) %>%
    mutate(Beta = round(Beta, 3), SE = round(SE, 3), p = round(p, 4))))

  # R-squared comparison
  cat("\n=== R-squared Comparison ===\n\n")
  r2_orig <- lavInspect(fit_fair, "rsquare")
  r2_new <- lavInspect(fit_pu_bi, "rsquare")
  r2_compare <- data.frame(
    Construct = construct_labels[names(r2_orig)],
    R2_Original = round(r2_orig, 3),
    R2_PU_BI = round(r2_new[names(r2_orig)], 3)
  )
  r2_compare$Delta <- r2_compare$R2_PU_BI - r2_compare$R2_Original
  print(as.data.frame(r2_compare))
} else {
  cat("Model did not converge.\n")
}

# Also test the combined model: method factor + PU -> BI path
cat("\n=== Combined: Method Factor + Direct PU -> BI ===\n\n")

fair_model_combined <- paste(c(
  fair_model_pu_bi, "",
  "# Method factor for reverse-coded items",
  method_factor,
  "method ~~ 0*system_quality",
  "method ~~ 0*service_quality",
  "method ~~ 0*perceived_fairness",
  "method ~~ 0*perceived_ease_of_use",
  "method ~~ 0*perceived_usefulness",
  "method ~~ 0*attitude_toward_use",
  "method ~~ 0*behavioral_intention"
), collapse = "\n")

fit_combined <- tryCatch(
  sem(fair_model_combined, data = df_items, std.lv = TRUE, estimator = "MLM"),
  warning = function(w) {
    cat("Warning:", conditionMessage(w), "\n")
    suppressWarnings(sem(fair_model_combined, data = df_items, std.lv = TRUE, estimator = "MLM"))
  }
)

if (lavInspect(fit_combined, "converged")) {
  cat("Model converged.\n\n")

  fit_comb_measures <- fitMeasures(fit_combined, c("cfi", "tli", "rmsea", "srmr"))
  cat("Combined model fit:\n")
  for (name in names(fit_comb_measures)) {
    cat(sprintf("  %s: %.3f (original: %.3f, delta = %+.3f)\n",
                toupper(name), fit_comb_measures[name], fit_measures[name],
                fit_comb_measures[name] - fit_measures[name]))
  }

  cat("\n=== All Path Coefficients (Combined) ===\n\n")
  paths_comb <- standardizedSolution(fit_combined) %>%
    filter(op == "~") %>%
    select(lhs, rhs, beta = est.std, se, pvalue) %>%
    mutate(
      lhs_label = construct_labels[lhs],
      rhs_label = construct_labels[rhs],
      sig = case_when(
        pvalue < 0.001 ~ "***",
        pvalue < 0.01 ~ "**",
        pvalue < 0.05 ~ "*",
        pvalue < 0.10 ~ ".",
        TRUE ~ ""
      )
    )

  print(as.data.frame(paths_comb %>%
    select(Path_To = lhs_label, Path_From = rhs_label,
           Beta = beta, SE = se, p = pvalue, Sig = sig) %>%
    mutate(Beta = round(Beta, 3), SE = round(SE, 3), p = round(p, 4))))
} else {
  cat("Combined model did not converge.\n")
}
