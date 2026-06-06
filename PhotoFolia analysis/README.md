# PhotoFolia analysis

Non-destructive smartphone-based leaf colour analysis (PhotoFolia / Colourworker)
and its validation against the UV-Vis chlorophyll reference. PhotoFolia produces
a Leaf Greenness Value and CIE L\*a\*b\* colour metrics from standardised leaf
photographs.

## Files

- `photofolia_matched_with_spectro.csv` — leaf-by-leaf PhotoFolia colour readings paired with the matching UV-Vis chlorophyll value (168 leaf surfaces)
- `photofolia_per_tree_means.csv` — mean L\*, a\*, b\* (and derived metrics) per tree
- `leaf_per_tree.csv` — per-tree summary
- `photofolia_analysis.R` — correlation, calibration, and plotting script
- `SWECC004_photofolia_description.docx` — written methods and results description

## Method notes

168 readings were taken from the adaxial leaf surface (proximal and distal
positions) across the four cardinal directions. Only the three independent CIE
Lab axes (L\*, a\*, b\*) were analysed; C\*, h, and S are mathematical functions of
them and carry no extra information.

## Key result

The yellow–blue axis b\* was the best single predictor of chlorophyll
(leaf-level Pearson r = −0.81, n = 168; per-tree r = −0.95, n = 7). A one-line
calibration fitted on all paired observations gave:

```
Total_Chl (µg mL⁻¹) = −0.501 · b* + 20.44      (R² = 0.66, RMSE = 1.61 µg mL⁻¹)
```

This supports PhotoFolia as a usable rapid field proxy for oak leaf chlorophyll
at this site.
