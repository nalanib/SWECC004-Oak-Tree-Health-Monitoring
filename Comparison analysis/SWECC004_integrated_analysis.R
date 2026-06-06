# ============================================================================
#  SWECC004 — Integrated leaf + soil comparison  (v2 — raw-data version)
#
#  Companion to SWECC04_analysis.R (leaves) and WECC03_soil_analysis.R (soil).
#  Merges every per-tree indicator into one tidy table and produces the six
#  cross-substrate comparison figures used in SWECC004_integrated_comparison.docx.
#
#  Tree-code convention used throughout:
#     FT01 = T1   FT02 = T2   FT03 = T3   (Bokashi)
#     NFT04 = T4  NFT05 = T5  NFT06 = T6  (Untreated)
#     HT07 = T7                            (Healthy reference)
#
#  Required inputs in the working folder (all CSVs extracted from the soil
#  team's "Calibration curves and results.xlsx" — no inline values, no
#  graph-transcription):
#     leaf_per_tree.csv              — per-tree leaf MP-AES means
#     soil_concentrations.csv        — soil MP-AES quadratic-calibrated conc
#     fungal_diversity_per_tree.csv  — abundance, richness, Shannon, evenness
#     soil_pH.csv                    — pH KCl / CaCl2 / demi-water
#     soil_hach_lange.csv            — NO3, PO4, NH4 mg/kg
#     soil_water_content.csv         — mean gravimetric water (mL / 10 g soil)
#     soil_infiltration.csv          — mean flow rate (mm/min) + SD
#     soil_earthworms.csv            — worms/m²
#
#  Leaf total chlorophyll per tree is read from
#     Chlorophyll_Equations_and_Calculations.xlsx  (sheet "Summary by Tree").
# ============================================================================

suppressPackageStartupMessages({
  library(readr); library(readxl); library(dplyr); library(tidyr)
  library(ggplot2); library(scales); library(stringr); library(purrr)
})

fig_dir <- "figures_integrated"; out_dir <- "output_integrated"
dir.create(fig_dir, showWarnings = FALSE)
dir.create(out_dir, showWarnings = FALSE)

save_png <- function(plot, file, w = 10, h = 7, dpi = 300) {
  ggsave(file.path(fig_dir, file), plot, width = w, height = h,
         dpi = dpi, bg = "white")
}

group_pal <- c("Bokashi"     = "#228833",
               "Untreated"   = "#EE6677",
               "Healthy ref" = "#4477AA")

samp_to_tree <- c("FT01" = "T1", "FT02" = "T2", "FT03" = "T3",
                  "NFT04" = "T4", "NFT05" = "T5", "NFT06" = "T6",
                  "HT07" = "T7")

# ---------------------------------------------------------------------------
# 1. Load + merge every per-tree indicator
# ---------------------------------------------------------------------------
chl <- read_excel("Chlorophyll_Equations_and_Calculations.xlsx",
                  sheet = "Summary by Tree", skip = 2) |>
  transmute(tree = Tree, leaf_chl_total = `Mean Total`) |>
  filter(!is.na(tree))

leaf_w <- read_csv("leaf_per_tree.csv", show_col_types = FALSE) |>
  pivot_wider(id_cols = tree, names_from = element, values_from = conc) |>
  select(tree, K, Mg, Zn, Mn, Cu, Al) |>
  rename_with(~ paste0("leaf_", .x), -tree)

soil_w <- read_csv("soil_concentrations.csv", show_col_types = FALSE) |>
  mutate(tree = samp_to_tree[sample]) |>
  pivot_wider(id_cols = tree, names_from = element, values_from = conc_quad) |>
  rename_with(~ paste0("soil_", .x), -tree)

ph     <- read_csv("soil_pH.csv", show_col_types = FALSE) |>
  select(tree, soil_pH_KCl = pH_KCl, soil_pH_CaCl2 = pH_CaCl2,
         soil_pH_demi = pH_demi)

hl     <- read_csv("soil_hach_lange.csv", show_col_types = FALSE) |>
  select(tree, soil_NO3 = NO3_mg_kg, soil_PO4 = PO4_mg_kg, soil_NH4 = NH4_mg_kg)

water  <- read_csv("soil_water_content.csv", show_col_types = FALSE) |>
  select(tree, soil_water = water_content_mL)

infil  <- read_csv("soil_infiltration.csv", show_col_types = FALSE) |>
  select(tree, infiltration = mean_flow_mm_min)

ew     <- read_csv("soil_earthworms.csv", show_col_types = FALSE) |>
  select(tree, earthworms = worms_per_m2)

fung   <- read_csv("fungal_diversity_per_tree.csv", show_col_types = FALSE) |>
  mutate(tree = samp_to_tree[tree]) |>
  select(tree,
         fung_abundance = abundance, fung_richness = richness,
         fung_shannon   = shannon,   fung_evenness = evenness)

df <- chl |>
  left_join(leaf_w, by = "tree") |>
  left_join(soil_w, by = "tree") |>
  left_join(ph,     by = "tree") |>
  left_join(hl,     by = "tree") |>
  left_join(water,  by = "tree") |>
  left_join(infil,  by = "tree") |>
  left_join(ew,     by = "tree") |>
  left_join(fung,   by = "tree") |>
  mutate(group = case_when(tree %in% c("T1","T2","T3") ~ "Bokashi",
                           tree %in% c("T4","T5","T6") ~ "Untreated",
                           tree == "T7"                ~ "Healthy ref"),
         group  = factor(group, levels = c("Untreated","Bokashi","Healthy ref")),
         sample = names(samp_to_tree)[match(tree, samp_to_tree)]) |>
  relocate(tree, sample, group)

write_csv(df, file.path(out_dir, "SWECC004_integrated_per_tree.csv"))

# ---------------------------------------------------------------------------
# 2. Tidy long form used by the plots
# ---------------------------------------------------------------------------
metric_labels <- c(
  leaf_chl_total = "Leaf chlorophyll",
  leaf_K = "Leaf K", leaf_Mg = "Leaf Mg", leaf_Zn = "Leaf Zn",
  leaf_Mn = "Leaf Mn", leaf_Cu = "Leaf Cu",
  soil_PO4 = "Soil PO4", soil_NO3 = "Soil NO3", soil_NH4 = "Soil NH4",
  soil_pH_CaCl2 = "Soil pH (CaCl2)",
  soil_water = "Soil water", infiltration = "Infiltration",
  earthworms = "Earthworms",
  fung_abundance = "Fungal abund.", fung_richness = "Fungal richness",
  fung_shannon   = "Fungal Shannon", fung_evenness = "Fungal evenness",
  soil_Fe = "Soil Fe", soil_Mn = "Soil Mn",
  soil_Cu = "Soil Cu", soil_Zn = "Soil Zn", soil_Al = "Soil Al"
)

z_long <- df |>
  select(tree, group, all_of(names(metric_labels))) |>
  mutate(across(-c(tree, group), ~ (.x - mean(.x, na.rm = TRUE)) /
                                     sd(.x, na.rm = TRUE))) |>
  pivot_longer(-c(tree, group), names_to = "metric", values_to = "z") |>
  mutate(label = metric_labels[metric],
         label = factor(label, levels = metric_labels))

# ---------------------------------------------------------------------------
# Fig 1 — per-tree z-score heatmap (earthworms included)
# ---------------------------------------------------------------------------
p1 <- ggplot(z_long, aes(tree, label, fill = z)) +
  geom_tile(colour = "white", linewidth = 0.4) +
  geom_text(aes(label = sprintf("%+.1f", z)), size = 3) +
  scale_fill_gradient2(low = "#3B7BB7", mid = "white", high = "#C0392B",
                       midpoint = 0, limits = c(-2.2, 2.2),
                       oob = scales::squish, name = "z-score") +
  scale_y_discrete(limits = rev(levels(z_long$label))) +
  labs(title = "Integrated indicator profile per tree (z across seven trees)",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 12) +
  theme(panel.grid = element_blank(),
        axis.text.x = element_text(face = "bold",
                                   colour = group_pal[as.character(
                                     df$group[match(levels(factor(z_long$tree)),
                                                    df$tree)])]))
save_png(p1, "fig1_integrated_zscore_heatmap.png", w = 9, h = 9.5)

# ---------------------------------------------------------------------------
# Fig 2 — group means across all indicators (earthworms swapped in)
# ---------------------------------------------------------------------------
panel_order <- c(
  "leaf_chl_total","leaf_K","leaf_Mg","leaf_Zn","leaf_Mn","leaf_Cu",
  "soil_pH_CaCl2","soil_PO4","soil_NO3","soil_NH4","soil_Fe","soil_Mn",
  "earthworms","fung_abundance","fung_shannon","fung_evenness",
  "soil_water","infiltration"
)
p2_data <- df |>
  select(tree, group, all_of(panel_order)) |>
  pivot_longer(-c(tree, group), names_to = "metric", values_to = "value") |>
  mutate(metric = factor(metric, levels = panel_order,
                         labels = metric_labels[panel_order]))

p2 <- ggplot(p2_data, aes(group, value, fill = group)) +
  stat_summary(geom = "col", fun = mean, colour = "black", linewidth = 0.3,
               alpha = 0.85) +
  stat_summary(geom = "errorbar", fun.data = mean_sdl, fun.args = list(mult = 1),
               width = 0.25) +
  geom_jitter(width = 0.12, height = 0, size = 1.6, colour = "black",
              alpha = 0.8) +
  facet_wrap(~ metric, scales = "free_y", ncol = 6) +
  scale_fill_manual(values = group_pal, guide = "none") +
  labs(title = "Group comparison across leaf, soil-chemistry and soil-biology indicators",
       x = NULL, y = NULL) +
  theme_bw(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_rect(fill = "grey92", colour = NA),
        strip.text = element_text(face = "bold"),
        axis.text.x = element_text(angle = 25, hjust = 1))
save_png(p2, "fig2_group_means_all_indicators.png", w = 14, h = 9)

# ---------------------------------------------------------------------------
# Fig 3 — leaf chlorophyll vs six soil indicators (now includes earthworms)
# ---------------------------------------------------------------------------
predictors <- c(soil_PO4      = "Soil phosphate (mg/kg)",
                soil_NH4      = "Soil ammonium (mg/kg)",
                soil_NO3      = "Soil nitrate (mg/kg)",
                soil_pH_CaCl2 = "Soil pH (CaCl2)",
                earthworms    = "Earthworms (n/m²)",
                fung_shannon  = "Fungal Shannon H'")
p3_data <- df |>
  pivot_longer(all_of(names(predictors)),
               names_to = "metric", values_to = "x") |>
  mutate(metric = factor(metric, levels = names(predictors),
                         labels = predictors))
ann <- p3_data |>
  filter(group %in% c("Bokashi","Untreated"),
         !is.na(x), !is.na(leaf_chl_total)) |>
  group_by(metric) |>
  summarise(r = cor(x, leaf_chl_total), .groups = "drop") |>
  mutate(label = sprintf("r = %+.2f  (n=6 treated)", r))

p3 <- ggplot(p3_data, aes(x, leaf_chl_total)) +
  geom_point(aes(colour = group), size = 3) +
  geom_text(aes(label = tree), nudge_y = 0.35, size = 3.2) +
  geom_label(data = ann, aes(label = label),
             x = -Inf, y = Inf, hjust = -0.05, vjust = 1.3,
             inherit.aes = FALSE, size = 3.1, label.size = 0,
             fill = "white", alpha = 0.85) +
  facet_wrap(~ metric, scales = "free_x", ncol = 3) +
  scale_colour_manual(values = group_pal, name = "Treatment") +
  labs(title = "Leaf chlorophyll vs soil indicators (one point = one tree)",
       x = NULL, y = "Leaf total chlorophyll (μg/mL)") +
  theme_bw(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_rect(fill = "grey92", colour = NA),
        strip.text = element_text(face = "bold"))
save_png(p3, "fig3_chl_vs_soil.png", w = 14, h = 8)

# ---------------------------------------------------------------------------
# Fig 4 — leaf vs soil for the four shared elements
# ---------------------------------------------------------------------------
shared <- c("Cu","Mn","Zn","Al")
p4_data <- map_dfr(shared, function(el) {
  df |> transmute(tree, group, element = el,
                  leaf = .data[[paste0("leaf_", el)]],
                  soil = .data[[paste0("soil_", el)]])
}) |>
  mutate(element = factor(element, levels = shared))

p4 <- ggplot(p4_data, aes(soil, leaf, colour = group)) +
  geom_point(size = 3) +
  geom_text(aes(label = tree),
            nudge_y = 0.04 * diff(range(p4_data$leaf, na.rm = TRUE)),
            size = 3.2) +
  facet_wrap(~ element, scales = "free", nrow = 1) +
  scale_colour_manual(values = group_pal, name = "Treatment") +
  labs(title = "Leaf vs soil concentration for shared elements",
       x = "Soil concentration (mg/L)", y = "Leaf concentration (ppm)") +
  theme_bw(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_rect(fill = "grey92", colour = NA),
        strip.text = element_text(face = "bold"))
save_png(p4, "fig4_leaf_vs_soil_elements.png", w = 14, h = 4.5)

# ---------------------------------------------------------------------------
# Fig 5 — per-tree integrated dashboard (earthworms row included)
# ---------------------------------------------------------------------------
dash_metrics <- c("leaf_chl_total","leaf_K","leaf_Mg","leaf_Zn","leaf_Mn",
                  "leaf_Cu",
                  "soil_pH_CaCl2","soil_PO4","soil_NO3","soil_NH4",
                  "soil_water","infiltration","earthworms",
                  "fung_abundance","fung_shannon")
p5_data <- z_long |>
  filter(metric %in% dash_metrics) |>
  mutate(metric = factor(metric, levels = rev(dash_metrics),
                         labels = rev(metric_labels[dash_metrics])),
         sign = case_when(z >  0.5 ~ "above",
                          z < -0.5 ~ "below",
                          TRUE      ~ "neutral"))
p5 <- ggplot(p5_data, aes(z, metric, fill = sign)) +
  geom_col(colour = "black", linewidth = 0.3) +
  geom_vline(xintercept = 0) +
  scale_fill_manual(values = c(above = "#1a9850", below = "#d73027",
                               neutral = "grey70"), guide = "none") +
  facet_wrap(~ tree, ncol = 4) +
  labs(title = "Per-tree integrated profile (green = above-average, red = below-average)",
       x = "z-score", y = NULL) +
  theme_bw(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_rect(fill = "grey92", colour = NA),
        strip.text = element_text(face = "bold"))
save_png(p5, "fig5_per_tree_dashboard.png", w = 14, h = 8.5)

# ---------------------------------------------------------------------------
# Fig 6 — pairwise correlations (treated trees only)
# ---------------------------------------------------------------------------
pool <- df |>
  filter(group %in% c("Bokashi","Untreated")) |>
  select(all_of(names(metric_labels))) |>
  select(where(~ sum(!is.na(.x)) >= 4))
cor_m <- cor(pool, use = "pairwise.complete.obs")
cor_long <- as_tibble(cor_m, rownames = "x") |>
  pivot_longer(-x, names_to = "y", values_to = "r") |>
  mutate(x = factor(x, levels = colnames(cor_m)),
         y = factor(y, levels = rev(colnames(cor_m))))

p6 <- ggplot(cor_long, aes(x, y, fill = r)) +
  geom_tile(colour = "white", linewidth = 0.4) +
  geom_text(aes(label = sprintf("%+.1f", r)), size = 2.5) +
  scale_fill_gradient2(low = "#3B7BB7", mid = "white", high = "#C0392B",
                       midpoint = 0, limits = c(-1, 1), name = "Pearson r") +
  labs(title = "Pairwise correlations across all indicators (treated trees, n = 6)",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 11) +
  theme(panel.grid = element_blank(),
        axis.text.x = element_text(angle = 50, hjust = 1))
save_png(p6, "fig6_correlation_heatmap.png", w = 11.5, h = 9.5)

message("\nDONE. Figures in ./", fig_dir, "; integrated table in ./", out_dir)
