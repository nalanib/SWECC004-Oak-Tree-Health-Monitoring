# Leaf nutrient analysis

Foliar elemental analysis of the seven study oaks by microwave plasma atomic
emission spectrometry (MP-AES). Leaf powder was acid-digested (HNO₃, microwave)
and measured against a matrix-matched multi-element calibration series.

## Files

- `SWECC04.csv` — raw MP-AES output (intensities/concentrations per emission line, all samples and blanks)
- `SWECC04_analysis.R` — calibration and processing script: inverse multivariate calibration (`conc ~ I_line1 + I_line2`), per-element reliability screening, blank correction, and per-tree plots
- `leaf_per_tree_concentrations.csv` — processed foliar concentrations (ppm) per tree for each element
- `leaf_per_tree.csv` — intermediate per-tree summary
- `SWECC004_leaf_nutrient_description.docx` — written methods and results description

## Method notes

Eight elements were targeted: K, Ca, Mg, Mn, Al, Fe, Zn, Cu. Aluminium was added
beyond the original plan to allow Ca:Al / Mg:Al acid-stress diagnostics. Each
element was measured at two emission wavelengths for cross-validation.

**Reliable elements:** K, Mg, Zn, Al, Mn, Cu.
**Excluded:** Ca (over the top calibration standard, >50 mg L⁻¹) and Fe (intensity
below blank for every untreated tree).

## Key pattern

Bokashi-treated trees showed higher leaf K, Mg, and Zn; untreated trees showed
higher leaf Mn and Al — the direction expected for acid-stress micronutrient
uptake. The statistical unit is the tree (n = 3 per treated group); all
comparisons are descriptive.
