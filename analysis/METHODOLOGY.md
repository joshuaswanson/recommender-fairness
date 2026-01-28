# Analysis Methodology

This document describes the Structural Equation Modeling (SEM) analysis procedure.

## Data Preprocessing

Before analysis, responses were filtered using reverse-worded attention checks:

- **Original sample**: 630 MTurk responses
- **Filtered sample**: 429 responses (used in analysis)

Eight questions were phrased negatively (e.g., "TikTok has unclear navigation" vs "TikTok is easy to navigate"). Respondents who gave logically inconsistent answers to these paired items were excluded, as this indicates inattentive responding.

**Reverse-worded items**:
| Item | Text |
|------|------|
| Q2 | TikTok has an unclear app navigation |
| Q7 | TikTok wrongly infers my interests |
| Q9 | TikTok recommended items are repetitive |
| Q15 | TikTok displays too many advertisements |
| Q25 | Using TikTok requires a lot of mental effort |
| Q31 | Using TikTok is dull and boring |
| Q37 | Using TikTok is a bad idea |
| Q42 | I don't intend to use TikTok in the future |

During analysis, these items are reverse-coded (1<->5, 2<->4) so they can be properly combined with other items in their construct.

## Overview

The analysis follows a three-step process:

1. **Reliability Analysis** (`01_reliability.Rmd`): Evaluate internal consistency
2. **Confirmatory Factor Analysis** (`02_cfa.Rmd`): Validate measurement model
3. **Structural Equation Modeling** (`03_sem.Rmd`): Test hypothesized paths

## Item Selection Criteria

Items are removed based on **psychometric criteria only**:

| Criterion | Threshold | Rationale |
|-----------|-----------|-----------|
| Item-total correlation | >= 0.3 | Items should correlate with their construct |
| Factor loading | >= 0.4 | Items should load meaningfully on their factor |

Items are not removed based on whether they produce significant path coefficients.

## Step 1: Reliability Analysis

For each construct:

1. Calculate Cronbach's $\alpha$
2. Compute corrected item-total correlations
3. Flag items with item-total correlation < 0.3
4. Remove flagged items
5. Recalculate $\alpha$ for revised constructs

**Acceptable reliability**: $\alpha \geq 0.6$ (exploratory), $\alpha \geq 0.7$ (confirmatory)

## Step 2: Confirmatory Factor Analysis

1. Specify measurement model with remaining items
2. Fit model using robust maximum likelihood (MLM estimator)
3. Evaluate factor loadings; remove items with loading < 0.4
4. Assess model fit indices
5. Check discriminant validity (inter-construct correlations < 0.85)
6. Calculate AVE and composite reliability

**Recommended fit thresholds**:

| Index | Threshold |
|-------|-----------|
| CFI | >= 0.90 |
| TLI | >= 0.90 |
| RMSEA | <= 0.08 |
| SRMR | <= 0.08 |

## Step 3: Structural Equation Modeling

1. Specify structural paths based on FAIR model theory
2. Fit full SEM (measurement + structural)
3. Report **all** path coefficients regardless of significance
4. Test both FAIR (7 constructs) and Modified FAIR (6 constructs) models
5. Compare model fit (if both models converge)

**Note**: The Modified FAIR model (which combines Perceived Ease of Use and Perceived Usefulness into "Perceived Effectiveness") may not converge with all datasets. If it fails to converge, only the standard FAIR model results are reported.

## Software

This project uses [renv](https://rstudio.github.io/renv/) for reproducible package management. Run `renv::restore()` to install the exact package versions used.

- **R** (4.5.2)
- **lavaan**: SEM model fitting
- **semTools**: Model diagnostics (composite reliability, AVE)
- **ltm**: Cronbach's alpha
- **semPlot**: Path diagrams
- **ggplot2**: Visualizations
- **dplyr**: Data manipulation
- **kableExtra**: HTML table formatting
- **corrplot**: Correlation matrices
