# Understanding the Role of Fairness in User Adoption of Two-Sided Recommender Systems

A research project for CS-498 (Research Project in Computer Science II) at EPFL, supervised by Pearl Pu from the Human Computer Interaction Lab. This study investigates whether perceived fairness influences user adoption of TikTok, using Structural Equation Modeling (SEM).

## Research Question

Two-sided recommender systems (2SRS) like TikTok serve both content creators and consumers. This study asks: Does users' perception of fairness affect their attitudes and intentions to use the platform?

## The FAIR Model

We extended the Technology Acceptance Model (TAM) by adding Perceived Fairness as a construct, creating the "FAIR model":

![FAIR Model](figures/fair_model.png)

### Constructs

| Construct             | Questions | Description                                         |
| --------------------- | --------- | --------------------------------------------------- |
| System Quality        | Q0-Q5     | Navigation, design, response time, security         |
| Service Quality       | Q6-Q15    | Recommendation accuracy, novelty, adaptability      |
| Perceived Fairness    | Q16-Q23   | Whether recommendations are limited by demographics |
| Perceived Ease of Use | Q24-Q28   | Usability of the platform                           |
| Perceived Usefulness  | Q29-Q35   | Entertainment value, curiosity stimulation          |
| Attitude Toward Use   | Q36-Q39   | Overall attitude toward using TikTok                |
| Behavioral Intention  | Q40-Q44   | Intention to continue using TikTok                  |

## Method

- **Platform**: TikTok
- **Survey**: 45 Likert-scale questions (1-5)
- **Participants**: 429 MTurk workers (filtered from 630 using reverse-worded attention checks)
- **Demographics**: Mostly ages 25-44, 50/50 gender split, 6+ months TikTok experience

### Data Preprocessing

Eight questions were phrased negatively to serve as attention checks. Respondents who gave logically inconsistent answers to these paired items were excluded as inattentive, reducing the sample from 630 to 429. During analysis, these items are reverse-coded (1<->5, 2<->4) so they combine properly with other items in their construct.

| Item | Text                                         |
| ---- | -------------------------------------------- |
| Q2   | TikTok has an unclear app navigation         |
| Q7   | TikTok wrongly infers my interests           |
| Q9   | TikTok recommended items are repetitive      |
| Q15  | TikTok displays too many advertisements      |
| Q25  | Using TikTok requires a lot of mental effort |
| Q31  | Using TikTok is dull and boring              |
| Q37  | Using TikTok is a bad idea                   |
| Q42  | I don't intend to use TikTok in the future   |

## Findings

![Hypothesis Results](figures/hypothesis_results.png)

### Supported Hypotheses (p < 0.05)

| Path                                         | $\beta$ | p-value |
| -------------------------------------------- | ------- | ------- |
| Service Quality -> Perceived Ease of Use     | 0.931   | < 0.001 |
| System Quality -> Perceived Usefulness       | 0.767   | 0.018   |
| Perceived Ease of Use -> Attitude Toward Use | 0.873   | < 0.001 |
| Attitude Toward Use -> Behavioral Intention  | 1.000   | < 0.001 |

### Marginal Support (p < 0.10)

| Path                                 | $\beta$ | p-value |
| ------------------------------------ | ------- | ------- |
| System Quality -> Perceived Fairness | 0.272   | 0.059   |

### Not Supported

The core fairness hypotheses were not supported:

- Service Quality -> Perceived Fairness ($\beta$ = 0.062, p = 0.686)
- Perceived Fairness -> Perceived Usefulness ($\beta$ = 0.046, p = 0.321)
- Perceived Fairness -> Attitude Toward Use ($\beta$ = -0.024, p = 0.584)

### Model Fit

| Index | Value | Threshold | Status |
| ----- | ----- | --------- | ------ |
| CFI   | 0.833 | >= 0.90   | Below  |
| TLI   | 0.819 | >= 0.90   | Below  |
| RMSEA | 0.062 | <= 0.08   | Good   |
| SRMR  | 0.061 | <= 0.08   | Good   |

The below-threshold CFI/TLI values suggest the model structure may need refinement, though RMSEA and SRMR are acceptable.

- **CFI** (Comparative Fit Index): Compares the specified model against a baseline (null) model in which all observed variables are uncorrelated. Values range from 0 to 1, with >= 0.90 indicating acceptable fit.
- **TLI** (Tucker-Lewis Index): Similar to CFI but includes a penalty for model complexity, rewarding parsimony. Also ranges from 0 to 1 with a >= 0.90 threshold.
- **RMSEA** (Root Mean Square Error of Approximation): Estimates the amount of error per degree of freedom, quantifying how well the model would fit the population covariance matrix. Values <= 0.08 indicate acceptable fit; <= 0.05 indicates close fit.
- **SRMR** (Standardized Root Mean Square Residual): Measures the average discrepancy between observed correlations and those predicted by the model. Values <= 0.08 indicate acceptable fit.

### Path Coefficients

![Path Coefficients](figures/path_coefficients.png)

### Correlation Matrices

![Construct Correlations](figures/construct_correlations.png)

<p align="center">
  <img src="figures/system_quality_correlation.png" width="49%"><img src="figures/service_quality_correlation.png" width="49%">
</p>

<p align="center">
  <img src="figures/perceived_fairness_correlation.png" width="49%"><img src="figures/perceived_ease_of_use_correlation.png" width="49%">
</p>

<p align="center">
  <img src="figures/perceived_usefulness_correlation.png" width="49%"><img src="figures/attitude_toward_use_correlation.png" width="49%">
</p>

<p align="center">
  <img src="figures/behavioral_intention_correlation.png" width="49%">
</p>

### Modified FAIR Model

We also tested a modified version combining Perceived Ease of Use and Perceived Usefulness into a single "Perceived Effectiveness" construct (6 constructs instead of 7). This model did not converge, so results are not reported.

## Post-Hoc Analysis

Post-hoc analyses were conducted to investigate the sources of below-threshold model fit and to test a theoretically motivated alternative specification. Code is in `analysis/04_modification_indices.Rmd`.

### Modification Indices and Method Factor

Lavaan's modification indices identify which additions to the model would most improve fit. The largest modification indices are all error covariances between reverse-coded items (e.g., Q31~~Q37, MI = 49.4; Q37~~Q42, MI = 35.2; Q31~~Q42, MI = 32.6). These negatively-worded questions are more correlated with each other than the model expects, not because they measure the same construct, but because respondents tend to answer negatively-phrased items in a similar way regardless of content.

Adding an orthogonal method factor for the five reverse-coded items still in the model (Q2, Q7, Q31, Q37, Q42) improves fit while leaving the structural path estimates essentially unchanged:

| Index | Original | With Method Factor | Change |
| ----- | -------- | ------------------ | ------ |
| CFI   | 0.833    | 0.865              | +0.032 |
| TLI   | 0.819    | 0.852              | +0.034 |
| RMSEA | 0.062    | 0.056              | -0.006 |
| SRMR  | 0.061    | 0.057              | -0.003 |

The fairness paths remain non-significant under the method factor model ($\beta$ = 0.053, p = 0.231 for Perceived Fairness -> Perceived Usefulness; $\beta$ = -0.012, p = 0.790 for Perceived Fairness -> Attitude Toward Use), confirming that the null result is not an artifact of poor model fit. The below-threshold CFI/TLI values reflect a survey design artifact (shared method variance from reverse-coded item wording) rather than substantive model misspecification.

### Direct Perceived Usefulness -> Behavioral Intention Path

The original TAM (Davis, 1989) includes a direct path from Perceived Usefulness to Behavioral Intention, which the FAIR model omits by routing all effects through Attitude Toward Use. Modification indices also flagged this path (MI = 39.8). However, adding this path produced a model with identification problems: the information matrix could not be inverted, and standard errors were not computable. This is likely because Attitude Toward Use already predicts Behavioral Intention at the boundary ($\beta$ = 1.000), leaving no identifiable variance for a second predictor to explain. The original FAIR model specification is therefore retained.

## Limitations

Several methodological factors may constrain the interpretability of the null fairness results and should be considered before concluding that perceived fairness plays no role in user adoption of two-sided recommender systems.

**Survivorship bias.** All participants had at least six months of active TikTok use, meaning the sample consists exclusively of users who have already adopted the platform. Users who perceived algorithmic unfairness and discontinued use as a result are systematically excluded. The dependent variable (behavioral intention to continue use) therefore captures retention among a self-selected population rather than initial adoption, which may attenuate any fairness effect that operates primarily at the adoption stage.

**Construct operationalization.** The Perceived Fairness construct (Q16-Q23) is operationalized narrowly around whether recommendations are limited by demographic characteristics such as age, gender, or ethnicity. However, fairness concerns on algorithmic platforms may manifest through other dimensions not captured by these items, including algorithmic transparency, content creator compensation equity, filter bubble effects, or equal visibility of content. If users' fairness perceptions operate through these alternative dimensions, the current instrument would fail to detect them.

**Platform selection.** TikTok's recommendation algorithm is driven primarily by behavioral signals (watch time, replays, shares) rather than explicit demographic targeting. Users may not perceive demographic-based unfairness on TikTok because the platform's recommendation logic does not make demographic factors salient. Platforms where unfairness is more visible to users, such as gig economy marketplaces, job recommendation systems, or content monetization platforms, may yield substantively different results.

## Repo Structure

```
data/
  Dec2BonusDataset.csv    Survey responses (429 filtered participants)
  survey_questions.md     What each Q0-Q44 question asks

analysis/
  01_reliability.Rmd      Step 1: Internal reliability analysis
  02_cfa.Rmd              Step 2: Confirmatory Factor Analysis
  03_sem.Rmd              Step 3: Structural Equation Modeling
  04_modification_indices.Rmd  Step 4: Post-hoc modification indices
  generate_figures.R      Script to regenerate all figures

figures/
  fair_model.png               FAIR model diagram with path coefficients
  path_coefficients.png        Bar chart of all path coefficients with 95% CIs
  hypothesis_results.png       Hypothesis testing summary
  construct_correlations.png   Inter-construct correlation matrix
  *_correlation.png            Item correlation matrices for each construct

renv.lock                 R package lockfile (for reproducibility)
```

## Analysis

The analysis is split into three sequential R Markdown files in `analysis/`:

1. **`01_reliability.Rmd`**: Internal reliability analysis using Cronbach's alpha. Identifies and removes items with item-total correlation < 0.3.

2. **`02_cfa.Rmd`**: Confirmatory Factor Analysis to validate the measurement model. Removes items with factor loadings < 0.4 and checks discriminant/convergent validity.

3. **`03_sem.Rmd`**: Structural Equation Modeling to test the hypothesized paths in the FAIR model and a modified version with combined constructs.

### Item Selection Criteria

Items are removed based on psychometric criteria only, not based on whether they produce significant path coefficients.

| Criterion              | Threshold | Rationale                                      |
| ---------------------- | --------- | ---------------------------------------------- |
| Item-total correlation | >= 0.3    | Items should correlate with their construct    |
| Factor loading         | >= 0.4    | Items should load meaningfully on their factor |

## R Environment Setup

This project uses [renv](https://rstudio.github.io/renv/) for reproducible R package management.

### First-time setup

```bash
# Install renv (if not already installed)
Rscript -e "install.packages('renv')"

# Restore the project library from the lockfile
Rscript -e "renv::restore()"
```

### Running the analysis

The analyses must be run in order since each depends on the previous:

```bash
Rscript -e "renv::activate(); setwd('analysis'); rmarkdown::render('01_reliability.Rmd')"
Rscript -e "renv::activate(); setwd('analysis'); rmarkdown::render('02_cfa.Rmd')"
Rscript -e "renv::activate(); setwd('analysis'); rmarkdown::render('03_sem.Rmd')"
```

This generates HTML notebook outputs (`.nb.html` files) in the `analysis/` directory.

### R packages

| Package    | Purpose                                       |
| ---------- | --------------------------------------------- |
| lavaan     | Structural Equation Modeling                  |
| semTools   | SEM diagnostics (composite reliability, etc.) |
| semPlot    | SEM visualization                             |
| ltm        | Cronbach's alpha calculation                  |
| dplyr      | Data manipulation                             |
| ggplot2    | Visualization                                 |
| kableExtra | HTML tables                                   |
| corrplot   | Correlation matrix visualization              |
