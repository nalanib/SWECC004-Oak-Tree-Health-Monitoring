# ============================================================================
#  SWECC04 — MP-AES leaf-mineral analysis
#  Calibration curves, visual inspection, and treatment comparison
#
#  Experiment
#  ----------
#  Agilent MP-AES export. 8 elements (Al, Ca, Cu, Fe, K, Mg, Mn, Zn),
#  each measured at 2 emission lines. Blank + 6 standards define the
#  calibration; unknown leaf digests (T1..T7, each in duplicate .1/.2)
#  are read off the inverted calibration.
#
#  Treatment mapping (provided by user):
#     T1, T2, T3  -> Bokashi
#     T4, T5, T6  -> Untreated (no bokashi)
#     T7          -> Healthy reference
#
#  Notes on the raw file
#  ---------------------
#  * 2 metadata lines precede the header; skip them.
#  * UTF-8 BOM, CRLF line endings.
#  * European locale: decimal comma, "-" used for missing numerics.
#  * Standards carry their KNOWN concentration in the Concentration column;
#    samples are flagged "Uncal" there, so we recompute them ourselves.
#  * Flags column (Agilent): "x"=over range, "m"=below cal/poor, "u"=under
#    range, "!"=outside QC, blank=ok. Kept for inspection, not auto-dropped.
# ============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(purrr)
  library(ggplot2)
  library(broom)
  library(scales)
})

# ragg gives crisp anti-aliased PNGs for publication; fall back gracefully.
have_ragg <- requireNamespace("ragg", quietly = TRUE)

set.seed(1)

# Parse European-formatted numeric strings ("0,10", "5838,91", "####", "Uncal")
# into numerics. Comma -> dot; anything non-numeric (Uncal, ####, -) -> NA.
euro_num <- function(x) {
  x <- as.character(x)
  x <- str_replace(x, ",", ".")
  suppressWarnings(as.numeric(x))
}

# ---- paths ----------------------------------------------------------------
data_file <- "SWECC04.csv"
fig_dir   <- "figures"
out_dir   <- "output"
dir.create(fig_dir, showWarnings = FALSE)
dir.create(out_dir, showWarnings = FALSE)

# helper: save a ggplot as a paper-worthy PNG (300 dpi)
save_png <- function(plot, file, width = 9, height = 6, dpi = 300) {
  path <- file.path(fig_dir, file)
  if (have_ragg) {
    ggsave(path, plot, width = width, height = height, dpi = dpi,
           device = ragg::agg_png, bg = "white")
  } else {
    ggsave(path, plot, width = width, height = height, dpi = dpi, bg = "white")
  }
  message("wrote ", path)
}

# ============================================================================
# 1. READ + TIDY
# ============================================================================
raw <- read_delim(
  data_file,
  delim = ",",
  skip = 2,                 # drop the two metadata lines
  locale = locale(encoding = "UTF-8"),
  na = c("", "NA"),         # keep "-" / "Uncal" / "####" as text; euro_num -> NA
  col_types = cols(.default = col_character()),
  show_col_types = FALSE
)

# Keep the columns we actually need and give them clean names.
dat <- raw %>%
  transmute(
    label        = Label,
    type         = Type,
    line         = Element,            # e.g. "Zn 472,215"
    element      = `Element Label`,    # e.g. "Zn"
    flag         = Flags,
    conc_given   = euro_num(Concentration), # NA for "Uncal" / "####"
    intensity    = euro_num(Intensity),
    intensity_sd = euro_num(`Intensity SD`),
    rep1 = euro_num(`Intensity Replicate 1`),
    rep2 = euro_num(`Intensity Replicate 2`),
    rep3 = euro_num(`Intensity Replicate 3`)
  ) %>%
  # tidy the line name: "Zn 472,215" -> wavelength 472.215
  mutate(
    wavelength = line %>%
      str_extract("[0-9]+,[0-9]+") %>%
      str_replace(",", ".") %>%
      as.numeric(),
    line_lab = paste0(element, " ", format(wavelength, nsmall = 3))
  )

# ---- treatment metadata for the unknowns ----------------------------------
# Sample labels look like "T1.1", "T.5.1" (note the stray dot), "T5.2" ...
# Extract the treatment number robustly, then the replicate.
samples <- dat %>%
  filter(type == "Sample") %>%
  mutate(
    treatment_no = label %>% str_extract("(?<=T\\.?)[0-9]+") %>% as.integer(),
    replicate    = label %>% str_extract("[0-9]+$") %>% as.integer(),
    group = case_when(
      treatment_no %in% 1:3 ~ "Bokashi",
      treatment_no %in% 4:6 ~ "Untreated",
      treatment_no == 7     ~ "Healthy ref",
      TRUE                  ~ NA_character_
    ),
    group = factor(group, levels = c("Untreated", "Bokashi", "Healthy ref"))
  )

standards <- dat %>% filter(type %in% c("STD", "BLK"))

message("Sample treatment check:")
print(samples %>% distinct(label, treatment_no, replicate, group) %>% arrange(treatment_no, replicate))

# ============================================================================
# 2. CALIBRATION  (inverse / chemometric model, one per ELEMENT)
#
#     Direction: concentration is the OUTCOME, intensities are PREDICTORS.
#     This is the correct direction for predicting unknowns: the standards'
#     concentrations are known with negligible error, the intensities carry
#     the instrument noise. Both emission lines enter as predictors so the
#     model uses all spectral information jointly:
#
#         conc = b0 + b1 * I_line1 + b2 * I_line2
#
#     Blank + 6 standards = up to 7 calibration points per element.
#     Honesty check: with 7 points and 2 predictors, in-sample R^2 flatters.
#     We therefore also report leave-one-out cross-validated RMSE (LOO-RMSE),
#     which only improves if the second line carries real signal rather than
#     noise. A single-line model is fit alongside for comparison.
# ============================================================================

# Reshape standards + samples to WIDE: one row per (label, element) with the
# two emission-line intensities side by side (I1 = lower wavelength line).
wide <- dat %>%
  group_by(element) %>%
  mutate(line_idx = dense_rank(wavelength)) %>%   # 1 = first line, 2 = second
  ungroup() %>%
  select(label, type, element, line_idx, intensity, conc_given) %>%
  pivot_wider(
    id_cols = c(label, type, element),
    names_from = line_idx,
    values_from = c(intensity, conc_given),
    names_sep = "_"
  ) %>%
  # one known concentration per standard row (identical across lines)
  mutate(conc_known = dplyr::coalesce(conc_given_1, conc_given_2)) %>%
  select(label, type, element, I1 = intensity_1, I2 = intensity_2, conc_known)

cal_wide <- wide %>%
  filter(type %in% c("STD", "BLK"), !is.na(conc_known))

# Fit per element. Return coefficients, in-sample R^2, and LOO-RMSE for both
# the two-line model and the better single line (for comparison).
loo_rmse <- function(formula, data) {
  n <- nrow(data); err <- numeric(n)
  for (i in seq_len(n)) {
    fit <- lm(formula, data = data[-i, , drop = FALSE])
    err[i] <- data$conc_known[i] - predict(fit, newdata = data[i, , drop = FALSE])
  }
  sqrt(mean(err^2))
}

cal_models <- cal_wide %>%
  group_by(element) %>%
  group_modify(~{
    d <- .x %>% filter(!is.na(I1), !is.na(I2), !is.na(conc_known))
    np <- nrow(d)
    # two-line model needs >= 4 points (3 params + 1 residual df)
    if (np < 4) {
      return(tibble(model = "insufficient", n_points = np,
                    b0 = NA, b1 = NA, b2 = NA,
                    r2 = NA_real_, loo_rmse = NA_real_))
    }
    f2 <- lm(conc_known ~ I1 + I2, data = d)
    co <- coef(f2)
    tibble(
      model    = "two_line",
      n_points = np,
      b0 = co[["(Intercept)"]],
      b1 = co[["I1"]],
      b2 = if ("I2" %in% names(co)) co[["I2"]] else NA_real_,
      r2 = summary(f2)$r.squared,
      loo_rmse = loo_rmse(conc_known ~ I1 + I2, d)
    )
  }) %>%
  ungroup()

# Single-line comparison (best individual line) per element, same LOO metric.
cal_single <- cal_wide %>%
  group_by(element) %>%
  group_modify(~{
    d <- .x %>% filter(!is.na(conc_known))
    out <- lapply(c("I1","I2"), function(v) {
      dd <- d %>% filter(!is.na(.data[[v]]))
      if (nrow(dd) < 3) return(NULL)
      f <- lm(reformulate(v, "conc_known"), data = dd)
      tibble(line = v, r2 = summary(f)$r.squared,
             loo_rmse = loo_rmse(reformulate(v, "conc_known"), dd))
    })
    bind_rows(out)
  }) %>%
  ungroup()

message("\nMultivariate inverse calibration (conc ~ I1 + I2) per element:")
print(cal_models %>% mutate(across(where(is.numeric), ~signif(., 4))))

message("\nSingle-line comparison (in-sample R^2 and LOO-RMSE):")
print(cal_single %>% mutate(across(where(is.numeric), ~signif(., 4))))

# ---- predict sample concentrations from the two-line model -----------------
samp_wide <- wide %>% filter(type == "Sample")

predict_conc <- function(el, I1, I2) {
  m <- cal_models %>% filter(element == el)
  if (nrow(m) == 0 || is.na(m$b1)) return(NA_real_)
  b2 <- ifelse(is.na(m$b2), 0, m$b2)
  m$b0 + m$b1 * I1 + b2 * I2
}

samp_pred <- samp_wide %>%
  rowwise() %>%
  mutate(conc_pred = predict_conc(element, I1, I2)) %>%
  ungroup() %>%
  # re-attach treatment metadata
  left_join(
    samples %>% distinct(label, treatment_no, replicate, group),
    by = "label"
  )

write_csv(samp_pred,    file.path(out_dir, "sample_concentrations.csv"))
write_csv(cal_models,   file.path(out_dir, "calibration_fits.csv"))

# Build a tidy long object the downstream plots/stats expect, named to match.
samples_conc <- samp_pred %>%
  transmute(label, element, treatment_no, replicate, group,
            conc_calc = conc_pred)

# ============================================================================
# 3. VISUAL INSPECTION
# ============================================================================
elem_levels <- sort(unique(dat$element))
elem_pal <- setNames(
  c("#4477AA","#EE6677","#228833","#CCBB44","#66CCEE","#AA3377","#BBBBBB","#000000")[seq_along(elem_levels)],
  elem_levels
)
group_pal <- c("Untreated" = "#EE6677", "Bokashi" = "#228833", "Healthy ref" = "#4477AA")

# Element display order: reliable first, broken (Ca, Fe) LAST so they can be
# visually quarantined. Tree symbols: each tree its own shape within its group.
elem_order <- c("K","Mg","Zn","Al","Mn","Cu","Fe","Ca")  # Fe, Ca last = untrustworthy
untrustworthy <- c("Fe","Ca")
tree_shapes <- c("T1"=16,"T2"=16,"T3"=16,    # Bokashi   -> circle
                 "T4"=17,"T5"=17,"T6"=17,    # Untreated -> triangle
                 "T7"=18)                      # Healthy   -> diamond

samples_conc <- samples_conc %>%
  mutate(tree = paste0("T", treatment_no),
         element = factor(element, levels = elem_order))

base_theme <- theme_bw(base_size = 13) +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_rect(fill = "grey92", colour = NA),
        strip.text = element_text(face = "bold"),
        legend.position = "right")

# ---- 3a. Calibration fit: predicted vs known concentration -----------------
# For a multivariate inverse model the meaningful diagnostic is how well the
# fitted model reproduces the known standard concentrations (1:1 line).
cal_fitted <- cal_wide %>%
  filter(!is.na(I1), !is.na(I2), !is.na(conc_known)) %>%
  left_join(cal_models %>% select(element, b0, b1, b2), by = "element") %>%
  mutate(conc_fit = b0 + b1 * I1 + ifelse(is.na(b2), 0, b2) * I2,
         element = factor(element, levels = elem_order))

p_cal <- ggplot(cal_fitted, aes(conc_known, conc_fit, colour = element)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey50") +
  geom_point(size = 2.4) +
  facet_wrap(~ element, scales = "free", ncol = 4) +
  scale_colour_manual(values = elem_pal, guide = "none") +
  labs(title = "Calibration fit: predicted vs known concentration",
       subtitle = "Inverse model  conc ~ I(line1) + I(line2)  per element; dashed = 1:1",
       x = "Known concentration (ppm)", y = "Model-predicted concentration (ppm)") +
  base_theme
save_png(p_cal, "01_calibration_fit.png", width = 12, height = 6)

# ---- 3c. Sample concentrations by treatment, every TREE its own symbol ------
# Each point is one reading; shape = tree, colour = treatment. Crossbar = group
# mean. Ca & Fe are faceted last and boxed red: their values are over-range /
# below detection and must not be trusted.
samp_plot <- samples_conc %>% filter(!is.na(group))

# data frame marking which facets get a red "untrustworthy" outline
quarantine <- tibble(element = factor(untrustworthy, levels = elem_order))

p_samp <- ggplot(samp_plot, aes(group, conc_calc, colour = group, shape = tree)) +
  # red background rectangle behind the untrustworthy facets
  geom_rect(data = quarantine, inherit.aes = FALSE,
            xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf,
            fill = NA, colour = "red", linewidth = 1.4) +
  geom_jitter(width = 0.12, height = 0, size = 2.8, alpha = 0.9) +
  stat_summary(aes(group = group), fun = mean, geom = "crossbar",
               width = 0.5, linewidth = 0.3, colour = "grey25") +
  facet_wrap(~ element, scales = "free_y", ncol = 4) +
  scale_colour_manual(values = group_pal, name = "Treatment") +
  scale_shape_manual(values = tree_shapes, name = "Tree", na.translate = FALSE) +
  labs(title = "Leaf mineral concentrations by treatment and tree",
       subtitle = "Point = one reading (shape = tree, colour = treatment); bar = group mean.\nRed-boxed Fe & Ca = over-range / below detection \u2014 NOT trustworthy.",
       x = NULL, y = "Concentration (ppm in digest)") +
  base_theme +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))
save_png(p_samp, "03_samples_by_tree.png", width = 13, height = 7)

# ---- 3d. group summary table ----------------------------------------------
summary_tbl <- samples_conc %>%
  filter(!is.na(group)) %>%
  group_by(element, group) %>%
  summarise(mean_ppm = mean(conc_calc, na.rm = TRUE),
            sd_ppm   = sd(conc_calc,  na.rm = TRUE),
            n = n(), .groups = "drop")

# ============================================================================
# 4. DESCRIPTIVE COMPARISON  (NOT formal significance testing)
#
#    Design reality: 3 trees per treatment (T1-3 Bokashi, T4-6 Untreated),
#    1 tree for Healthy (T7). The .1/.2 are technical replicate readings of
#    the SAME tree, NOT independent biological replicates. True n = 3 per
#    group. Treating the two readings as independent would be pseudoreplication
#    and would produce misleadingly small p-values.
#
#    Therefore: NO headline significance tests. We summarise per tree and per
#    group descriptively. Inferential testing is deferred to the larger study
#    (soil data + more trees). One heavily-caveated exploratory t-test is kept
#    at the very end on reliable elements only, with tree as the unit, purely
#    as hypothesis-generation -- not to be reported as a result.
# ============================================================================

# Collapse technical replicates -> one value per TREE (the real unit).
tree_level <- samples_conc %>%
  filter(!is.na(group)) %>%
  group_by(group, tree, treatment_no, element) %>%
  summarise(conc_tree = mean(conc_calc, na.rm = TRUE), .groups = "drop")

# Group summary built on the tree-level means (honest n = number of trees).
group_desc <- tree_level %>%
  group_by(element, group) %>%
  summarise(mean_ppm = mean(conc_tree, na.rm = TRUE),
            sd_ppm   = sd(conc_tree, na.rm = TRUE),
            n_trees  = n(), .groups = "drop")

message("\nDescriptive group summary (unit = tree, n = trees):")
print(group_desc %>% mutate(across(where(is.numeric), ~round(., 2))) %>%
        arrange(factor(element, levels = elem_order)))

write_csv(tree_level, file.path(out_dir, "sample_concentrations.csv"))

# -- Exploratory only: Bokashi vs Untreated on RELIABLE elements, tree as unit.
#    Flagged clearly as underpowered (n=3 vs 3). Hypothesis-generating only.
reliable <- c("K","Mg","Zn","Al","Mn")
explore <- tree_level %>%
  filter(group %in% c("Bokashi","Untreated"), element %in% reliable) %>%
  group_by(element) %>%
  group_modify(~{
    x <- .x$conc_tree[.x$group=="Bokashi"]
    y <- .x$conc_tree[.x$group=="Untreated"]
    tt <- tryCatch(t.test(x, y), error = function(e) NULL)
    tibble(mean_bokashi = mean(x), mean_untreated = mean(y),
           diff = mean(x)-mean(y),
           p_exploratory = if (is.null(tt)) NA_real_ else tt$p.value)
  }) %>% ungroup()

message("\nEXPLORATORY ONLY (n=3 vs 3, underpowered -- do NOT report as result):")
print(explore %>% mutate(across(where(is.numeric), ~round(., 3))))

# ============================================================================
# 5. MODEL QUALITY PLOT  (figure 09)
#    R^2 and leave-one-out RMSE per element for the two-line inverse model.
#    R^2 alone flatters a 2-predictor / 7-point fit, so LOO-RMSE is shown
#    alongside as the honest predictive-accuracy metric.
# ============================================================================
p_r2 <- cal_models %>%
  filter(!is.na(r2)) %>%
  ggplot(aes(reorder(element, r2), r2, fill = element)) +
  geom_col(width = 0.7) +
  geom_hline(yintercept = 0.99, linetype = "dashed", colour = "red") +
  geom_text(aes(label = sprintf("R\u00b2=%.3f\nLOO-RMSE=%.2f", r2, loo_rmse)),
            hjust = 1.05, size = 3, colour = "white") +
  coord_flip() +
  scale_fill_manual(values = elem_pal, guide = "none") +
  scale_y_continuous(limits = c(0, 1.0), oob = scales::squish) +
  labs(title = "Calibration model quality per element (two-line inverse model)",
       subtitle = "conc ~ I(line1) + I(line2); dashed = R\u00b2 0.99; LOO-RMSE in ppm (lower = better)",
       x = NULL, y = expression(R^2)) +
  base_theme
save_png(p_r2, "09_model_R2.png", width = 10, height = 6)

# ============================================================================
# 6. PRINCIPAL COMPONENT ANALYSIS  (figure 10)
#
#    Goal: look for grouping of trees by treatment in multivariate mineral
#    space. Uses the 5 reliable variables only -- K, Mg, Zn, Al, Mn -- because
#    Cu (neg in 10/14), Fe (10/14 neg + over-range) and Ca (11/14 over-range)
#    are broken and would either force row deletion (NAs) or inject
#    detection-limit noise. Dropping ONLY the provably-broken variables keeps
#    the matrix full-rank without over-curating; Al & Mn are kept so the
#    loadings can reveal whether they carry signal or noise.
#
#    Unit = tree (technical replicates averaged). Data standardised
#    (correlation PCA) because K (tens of ppm) would otherwise dominate
#    Zn/Mn (near 0) purely by scale. Healthy ref (T7) included, marked.
# ============================================================================
pca_vars <- c("K","Mg","Zn","Al","Mn")

pca_mat <- tree_level %>%
  filter(element %in% pca_vars) %>%
  select(tree, group, element, conc_tree) %>%
  pivot_wider(names_from = element, values_from = conc_tree) %>%
  arrange(tree)

X <- pca_mat %>% select(all_of(pca_vars)) %>% as.matrix()
rownames(X) <- pca_mat$tree
stopifnot(!anyNA(X))                       # full, complete matrix
cat("\nPCA matrix rank:", qr(scale(X))$rank, "of", ncol(X), "variables\n")

pca <- prcomp(X, center = TRUE, scale. = TRUE)
ve  <- 100 * pca$sdev^2 / sum(pca$sdev^2)  # % variance explained

scores <- as_tibble(pca$x[, 1:2], rownames = "tree") %>%
  left_join(pca_mat %>% select(tree, group), by = "tree")

load <- as_tibble(pca$rotation[, 1:2], rownames = "element")
arrow_scale <- 0.9 * max(abs(scores$PC1), abs(scores$PC2))

p_pca <- ggplot(scores, aes(PC1, PC2, colour = group, shape = tree)) +
  geom_hline(yintercept = 0, colour = "grey85") +
  geom_vline(xintercept = 0, colour = "grey85") +
  # loading arrows
  geom_segment(data = load, inherit.aes = FALSE,
               aes(x = 0, y = 0,
                   xend = PC1 * arrow_scale, yend = PC2 * arrow_scale),
               arrow = arrow(length = unit(0.18, "cm")),
               colour = "grey45", linewidth = 0.4) +
  geom_text(data = load, inherit.aes = FALSE,
            aes(x = PC1 * arrow_scale * 1.12, y = PC2 * arrow_scale * 1.12,
                label = element), colour = "grey30", size = 4, fontface = "bold") +
  geom_point(size = 4, stroke = 1) +
  geom_text(aes(label = tree), vjust = -1.1, size = 3, show.legend = FALSE) +
  scale_colour_manual(values = group_pal, name = "Treatment") +
  scale_shape_manual(values = tree_shapes, name = "Tree", na.translate = FALSE) +
  labs(title = "PCA of leaf minerals (K, Mg, Zn, Al, Mn; standardised)",
       subtitle = "Each point one tree; colour = treatment, shape = tree. Arrows = element loadings.",
       x = sprintf("PC1 (%.1f%%)", ve[1]),
       y = sprintf("PC2 (%.1f%%)", ve[2])) +
  base_theme +
  coord_equal()
save_png(p_pca, "10_pca.png", width = 9, height = 7)

message("\nPCA variance explained (%): ", paste(sprintf('%.1f', ve), collapse = ", "))
message("PC1/PC2 loadings:")
print(load %>% mutate(across(where(is.numeric), ~round(., 3))))

message("\nDONE. Figures in ./figures, tables in ./output")
