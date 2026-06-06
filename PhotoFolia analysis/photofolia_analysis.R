# ============================================================================
#  SWECC004 — PhotoFolia analysis + UV-Vis spectrophotometer validation
#                                  + leaf-nutrient correlation
#
#  Reads:
#     photofolia log raw data.xltx              (CIE Lab + HSV per leaf surface)
#     spec_meter_readings.xltx                  (A645 / A663 per leaf surface)
#     leaf_per_tree.csv                         (per-tree MP-AES nutrient means)
#
#  Writes (in ./figures_pf):
#     pf_fig1_metrics_by_tree.png
#     pf_fig2_design_check.png
#     pf_fig3_group_means.png
#     pf_fig4_validation_per_leaf.png
#     pf_fig5_validation_per_tree.png
#     pf_fig6_calibration.png
#     pf_fig7_vs_nutrients.png
#
#  Sample-ID handling: the PhotoFolia file uses inconsistent tree codes
#  (FT1, FT2, T03, NFT4, NFT5/NFT05, NFT6, BT7, HT07) — they all map to T1..T7.
#  The spectrophotometer file uses T1..T7 throughout. Matching is on
#  (tree, direction, leaf number, surface).
# ============================================================================

suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(tidyr); library(stringr)
  library(ggplot2); library(scales); library(purrr)
})

fig_dir <- "figures_pf"; out_dir <- "output_pf"
dir.create(fig_dir, showWarnings = FALSE)
dir.create(out_dir, showWarnings = FALSE)

save_png <- function(p, file, w = 10, h = 7, dpi = 300)
  ggsave(file.path(fig_dir, file), p, width = w, height = h, dpi = dpi, bg = "white")

group_pal <- c("Bokashi" = "#228833",
               "Untreated" = "#EE6677",
               "Healthy ref" = "#4477AA")

pf_to_t <- c("FT1"="T1","FT2"="T2","FT3"="T3","T03"="T3",
             "NFT1"="T4","NFT4"="T4",
             "NFT2"="T5","NFT5"="T5","NFT05"="T5",
             "NFT3"="T6","NFT6"="T6",
             "HT"="T7","HT07"="T7","BT7"="T7")
tree_to_group <- c("T1"="Bokashi","T2"="Bokashi","T3"="Bokashi",
                   "T4"="Untreated","T5"="Untreated","T6"="Untreated",
                   "T7"="Healthy ref")

# ---------------------------------------------------------------------------
# 1. Load PhotoFolia colour measurements
# ---------------------------------------------------------------------------
pf <- read_excel("photofolia log raw data.xltx", sheet = "Color Measurements") |>
  filter(!is.na(Sensor)) |>
  mutate(
    pf_tree = str_extract(Sensor, "^[A-Z]+0*\\d+"),
    dir     = str_extract(Sensor, "(?<=-)[NSEW](?=-)"),
    leaf    = as.integer(str_extract(Sensor, "(?<=-L)\\d")),
    side    = ifelse(str_detect(Sensor, "Top$"), "T", "B"),
    tree    = pf_to_t[pf_tree],
    group   = factor(tree_to_group[tree],
                     levels = c("Untreated","Bokashi","Healthy ref"))
  ) |>
  filter(!is.na(tree)) |>
  mutate(leaf_key = paste(tree, dir, paste0("L", leaf), side, sep = "_"))

# ---------------------------------------------------------------------------
# 2. Load UV-Vis spectrophotometer absorbances and compute chlorophyll
# ---------------------------------------------------------------------------
raw_spec <- read_excel("spec_meter_readings.xltx", sheet = 1)
spec <- list()
for (i in seq(1, ncol(raw_spec), by = 4)) {
  if (i + 2 <= ncol(raw_spec)) {
    blk <- raw_spec[, i:(i + 2)]; names(blk) <- c("sample","A645","A663")
    spec[[length(spec) + 1]] <- blk |> filter(!is.na(sample))
  }
}
sp <- bind_rows(spec) |>
  filter(str_detect(sample, "^T\\d L\\d [NSEW]-[TB]$"),
         !is.na(A645), !is.na(A663)) |>
  mutate(A645 = as.numeric(A645), A663 = as.numeric(A663),
         tree = str_extract(sample, "T\\d"),
         leaf = as.integer(str_extract(sample, "(?<=L)\\d")),
         dir  = str_extract(sample, "[NSEW](?=-)"),
         side = str_extract(sample, "[TB]$"),
         leaf_key = paste(tree, dir, paste0("L", leaf), side, sep = "_"),
         Chl_a = 12.21 * A663 - 2.81 * A645,
         Chl_b = 20.13 * A645 - 5.03 * A663,
         Total_Chl = 17.76 * A645 + 7.43 * A663)

# ---------------------------------------------------------------------------
# 3. Match leaf-by-leaf
# ---------------------------------------------------------------------------
m <- pf |>
  inner_join(sp |> select(leaf_key, A645, A663, Chl_a, Chl_b, Total_Chl),
             by = "leaf_key")
cat("Matched leaf surfaces:", nrow(m), "\n")
write.csv(m, file.path(out_dir, "photofolia_matched_with_spectro.csv"), row.names = FALSE)

base_theme <- theme_bw(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_rect(fill = "grey92", colour = NA),
        strip.text = element_text(face = "bold"))

# ---------------------------------------------------------------------------
# Fig 1 — PhotoFolia metrics by tree
# ---------------------------------------------------------------------------
metric_long <- pf |>
  select(tree, group, `a*` = `a*`, `L*` = `L*`, S) |>
  pivot_longer(c(`a*`,`L*`, S), names_to = "metric")
p1 <- ggplot(metric_long, aes(tree, value, fill = group)) +
  geom_boxplot(width = 0.6, alpha = 0.7, outlier.size = 0.8) +
  facet_wrap(~ metric, scales = "free_y") +
  scale_fill_manual(values = group_pal, guide = "none") +
  labs(title = "PhotoFolia colour metrics by tree",
       subtitle = "24 readings per tree (4 directions × 3 leaves × 2 surfaces)",
       x = NULL, y = NULL) +
  base_theme
save_png(p1, "pf_fig1_metrics_by_tree.png", w = 13, h = 5)

# ---------------------------------------------------------------------------
# Fig 4 — Per-leaf validation: PhotoFolia metrics vs UV-Vis total Chl
# ---------------------------------------------------------------------------
val_long <- m |>
  select(group, Total_Chl, `a*`, `b*`, h, S, `L*`, `C*`) |>
  pivot_longer(c(`a*`,`L*`, `a*`, `b*`), names_to = "metric")
r_lab <- val_long |>
  group_by(metric) |>
  summarise(r = cor(value, Total_Chl), n = n(), .groups = "drop") |>
  mutate(label = sprintf("r = %+.2f   n = %d", r, n))

p4 <- ggplot(val_long, aes(value, Total_Chl, colour = group)) +
  geom_point(size = 1.8, alpha = 0.55) +
  geom_smooth(method = "lm", se = FALSE, colour = "black",
              linewidth = 0.6, linetype = "dashed") +
  geom_label(data = r_lab, aes(label = label),
             x = -Inf, y = Inf, hjust = -0.05, vjust = 1.3,
             inherit.aes = FALSE, size = 3.2, label.size = 0,
             fill = "white", alpha = 0.85) +
  facet_wrap(~ metric, scales = "free_x", ncol = 3) +
  scale_colour_manual(values = group_pal, name = "Treatment") +
  labs(title = "VALIDATION — PhotoFolia colour metrics vs UV-Vis chlorophyll (per leaf)",
       x = NULL, y = "Total Chlorophyll (μg/mL)") +
  base_theme
save_png(p4, "pf_fig4_validation_per_leaf.png", w = 14, h = 8.5)

# ---------------------------------------------------------------------------
# Fig 5 — Per-tree validation
# ---------------------------------------------------------------------------
tree_mean <- m |>
  group_by(tree, group) |>
  summarise(across(c(`L*`,`a*`,`b*`,`C*`, h, S, Total_Chl, Chl_a, Chl_b),
                  mean, na.rm = TRUE),
            .groups = "drop")
write.csv(tree_mean, file.path(out_dir, "photofolia_per_tree_means.csv"), row.names = FALSE)

per_tree_long <- tree_mean |>
  select(tree, group, Total_Chl, `a*`, h, S) |>
  pivot_longer(c(`a*`, h, S), names_to = "metric")
p5 <- ggplot(per_tree_long, aes(value, Total_Chl, colour = group)) +
  geom_point(size = 3.5) +
  geom_smooth(method = "lm", se = FALSE, colour = "black",
              linewidth = 0.6, linetype = "dashed") +
  geom_text(aes(label = tree), vjust = -1.1, size = 3.2, show.legend = FALSE) +
  facet_wrap(~ metric, scales = "free_x") +
  scale_colour_manual(values = group_pal, name = "Treatment") +
  labs(title = "VALIDATION — PhotoFolia ↔ UV-Vis at the tree level (n = 7)",
       x = NULL, y = "Total Chl (μg/mL)") +
  base_theme
save_png(p5, "pf_fig5_validation_per_tree.png", w = 13, h = 4.6)

# ---------------------------------------------------------------------------
# Fig 6 — Calibration curve  (h is the strongest per-tree predictor)
# ---------------------------------------------------------------------------
fit <- lm(Total_Chl ~ h, data = m)
r2  <- summary(fit)$r.squared
rmse <- sqrt(mean(residuals(fit)^2))
co  <- coef(fit)
p6 <- ggplot(m, aes(h, Total_Chl)) +
  geom_point(colour = "#666666", alpha = 0.55, size = 1.8) +
  geom_smooth(method = "lm", colour = "#C0392B", fill = "#C0392B", alpha = 0.12) +
  labs(title = sprintf("Calibration: PhotoFolia h → UV-Vis chlorophyll"),
       subtitle = sprintf("Total_Chl = %.3f·h + %.2f   |   R² = %.3f   RMSE = %.2f μg/mL   n = %d",
                          co[["h"]], co[["(Intercept)"]], r2, rmse, nrow(m)),
       x = "PhotoFolia h  (hue angle, higher = pure green)",
       y = "UV-Vis Total Chlorophyll (μg/mL)") +
  base_theme
save_png(p6, "pf_fig6_calibration.png", w = 9, h = 6.5)

# ---------------------------------------------------------------------------
# Fig 7 — PhotoFolia (a*, h) vs leaf nutrients per tree
# ---------------------------------------------------------------------------
leaf <- read.csv("leaf_per_tree.csv") |>
  pivot_wider(id_cols = tree, names_from = element, values_from = conc) |>
  select(tree, K, Mg, Zn, Mn, Cu)
pn <- tree_mean |>
  select(tree, group, `a*`, h, S, `L*`, Total_Chl) |>
  inner_join(leaf, by = "tree")

pn_long <- pn |>
  pivot_longer(c(K, Mg, Zn, Mn, Cu), names_to = "nutrient", values_to = "nval") |>
  pivot_longer(c(`a*`, h), names_to = "pf_metric", values_to = "pv")
p7 <- ggplot(pn_long, aes(pv, nval, colour = group)) +
  geom_point(size = 3) +
  geom_text(aes(label = tree), vjust = -1.1, size = 3, show.legend = FALSE) +
  facet_grid(pf_metric ~ nutrient, scales = "free") +
  scale_colour_manual(values = group_pal, name = "Treatment") +
  labs(title = "PhotoFolia colour vs leaf nutrient concentration (one point = one tree)",
       x = "PhotoFolia metric", y = "Leaf concentration (ppm)") +
  base_theme
save_png(p7, "pf_fig7_vs_nutrients.png", w = 16, h = 7)

cat("\nPer-leaf Pearson r — PhotoFolia vs Total_Chl:\n")
for (met in c("a*","b*","L*","C*","h","S"))
  cat(sprintf("  %s   r = %+.3f   n = %d\n",
              met, cor(m[[met]], m$Total_Chl), nrow(m)))

cat("\nPer-tree Pearson r:\n")
for (met in c("a*","b*","L*","C*","h","S"))
  cat(sprintf("  %s   r = %+.3f\n", met, cor(tree_mean[[met]], tree_mean$Total_Chl)))

message("\nDONE. Figures in ./", fig_dir)
