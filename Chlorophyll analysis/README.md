# Chlorophyll analysis

Destructive UV-Vis spectrophotometric determination of leaf chlorophyll, used
both as a vitality indicator and as the laboratory reference for validating the
PhotoFolia field method.

## Files

- `chlorophyll_full_data.csv` — all individual readings (per leaf surface, per tree)
- `summary_by_tree.csv` — mean and SD of Chl a, Chl b, and total chlorophyll per tree (n = 24 readings/tree)
- `summary_by_treatment.csv` — group-level means (bokashi, untreated, healthy reference)
- `chlorophyll_analysis.R` — extraction-to-result processing and plotting script
- `Chlorophyll_Equations_and_Calculations.xlsx` — pigment equations and worked calculations
- `SWECC004_chlorophyll_description.docx` — written methods and results description

## Method notes

A 10 mm leaf disc was extracted in 3 mL of 80 % acetone (dark, 4 °C, 24 h),
centrifuged, and absorbance read at 663 nm and 646 nm. Chl a, Chl b, total
chlorophyll, and the Chl a:b ratio were calculated using the Lichtenthaler
(1987) trichromatic equations for 80 % acetone. Concentrations are expressed in
µg mL⁻¹ of subsample.

## Key pattern

Group mean total chlorophyll: healthy reference HT07 13.66 µg mL⁻¹ >
bokashi 10.61 > untreated 9.80. Bokashi exceeded untreated by ~8 %; within-group
spreads overlapped.
