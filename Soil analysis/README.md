# Soil analysis

Soil chemistry, biology, and physics measured on the same seven trees by the
parallel WECC03 soil team. This is the substrate-side dataset that the leaf
results are compared against.

## Files

- `soil_pH.csv` — pH in three extractants (KCl, CaCl₂, demi-water) per tree
- `soil_hach_lange.csv` — Hach-Lange colorimetric nitrate, phosphate, ammonium (mg kg⁻¹ dry soil)
- `soil_concentrations.csv` — MP-AES mineral concentrations (Al, Fe, Mn, Cu, Zn) in mg L⁻¹ of digest, with emission wavelengths
- `soil_fungi_raw_counts.csv` — raw fungal colony counts by morphotype (PDA plates, 3 replicates/tree)
- `fungal_diversity_per_tree.csv` — derived diversity indices (abundance, richness, Shannon H′, Simpson, Pielou evenness)
- `soil_earthworms.csv` — earthworm density by mustard extraction (worms m⁻²)
- `soil_water_content.csv` — gravimetric soil water content
- `soil_infiltration.csv` — double-ring infiltrometer flow rate (mm min⁻¹), with replicate counts and SD
- `WECC03_soil_analysis.R` — processing, diversity (vegan), and plotting script
- `SWECC004_soil_description.docx` — written methods and results description

## Method notes

Soil minerals used a classical quadratic calibration (`I = a·C² + b·C + d`), which
is required for the soil run because broken Mn/Cu lines contaminate an inverse
model. Concentrations are reported per litre of digest, not per kg dry soil.

## Key patterns

Phosphate is the clearest treatment signal: every bokashi soil (4.2–6.0 mg kg⁻¹)
exceeds every untreated soil (0.6–1.4), with ammonium and soil aluminium
following more weakly. Soil pH (uniformly ~3.1–3.4 in CaCl₂), fungal diversity,
infiltration, and single-round earthworm density did **not** separate the
treatments. FT01 is a recurring outlier on the soil-physical indicators (very
slow infiltration) and on raw fungal abundance.
