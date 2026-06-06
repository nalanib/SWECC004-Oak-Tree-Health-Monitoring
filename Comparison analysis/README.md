# Comparison analysis

The integrated, cross-substrate dataset that combines every leaf, soil-chemistry,
and soil-biology indicator onto a single per-tree table for joint analysis. This
is where the leaf and soil results are brought together to assess whether the
bokashi signal is consistent across both matrices.

## Files

- `SWECC004_integrated_per_tree.csv` — one row per tree with all leaf, soil-chemistry, soil-physical, and soil-biology indicators
- `SWECC004_integrated_analysis.R` — builds the z-score profiles, group comparisons, and cross-substrate correlations
- `SWECC004_integrated_comparison.docx` — written methods and results description

## Method notes

Every indicator is placed on a common per-tree z-score scale so that variables
measured in different units can be compared on one axis. Cross-substrate
relationships (e.g. leaf chlorophyll vs single soil indicators) are summarised
with Pearson correlations across the treated trees.

## Key findings

Soil chemistry — especially phosphate and ammonium — is the strongest
quantitative evidence for a positive bokashi effect; leaf minerals (K, Mg, Zn)
and chlorophyll move in the same direction at smaller magnitude. Per-tree
correlations between leaf chlorophyll and any single soil indicator are weak, so
the interpretation relies on the overall multi-indicator profile rather than any
one bivariate relationship. FT01 (bokashi) and NFT04 (untreated) recur as
within-group outliers across several indicators.
