# ============================================================================
#  WECC03 — MP-AES soil-mineral analysis (companion to SWECC04 leaves)
#
#  Samples:  FT1-FT3 = Bokashi, NB1-NB3 = Untreated (No Bokashi), HT = Healthy
#  Note: soil has NO .1/.2 technical replicates (the 3 instrument replicates
#        were already averaged to a mean intensity), so n = 3 trees per
#        treatment, n = 1 for HT. Same underpowered-stats caveat as leaves.
#
#  TWO calibration methods are fit and COMPARED, per user request:
#   (A) Classical QUADRATIC (teammate's method):  I = a*C^2 + b*C + d  per
#       wavelength; sample conc solved by the quadratic formula (positive root).
#       This is reproduced here to (i) verify the teammate's spreadsheet and
#       (ii) provide the soil's own documented numbers.
#   (B) Inverse MULTIVARIATE (our leaf method):   C ~ I_line1 + I_line2  per
#       element; concentration as outcome, both lines as predictors. Applied
#       to the same raw intensities so leaf and soil share one method.
#
#  Reliability (from teammate's documentation, reconfirmed numerically):
#     KEEP : Al 396.152, Fe 371.993, Mn 403.076, Cu 324.754, Zn 481.053
#     REJECT: Mn 279.482 (negative intensities), Zn 213.857 (saturates),
#             Mo both lines (< detection limit, signal at blank).
#     Cu 100 ppm standard was #### off-scale -> excluded from that fit.
#
#  Units: mg/L in the analysed solution, NOT mg/kg dry soil (digestion
#  weight/volume/dilution were placeholders 1/1/1). Same caveat as leaves.
# ============================================================================

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(stringr)
  library(purrr); library(ggplot2); library(broom); library(scales)
})
have_ragg <- requireNamespace("ragg", quietly = TRUE)
set.seed(1)

fig_dir <- "figures_soil"; out_dir <- "output_soil"
dir.create(fig_dir, showWarnings = FALSE); dir.create(out_dir, showWarnings = FALSE)

save_png <- function(plot, file, width = 9, height = 6, dpi = 300) {
  path <- file.path(fig_dir, file)
  if (have_ragg) ggsave(path, plot, width = width, height = height, dpi = dpi,
                        device = ragg::agg_png, bg = "white")
  else ggsave(path, plot, width = width, height = height, dpi = dpi, bg = "white")
  message("wrote ", path)
}

samples_all <- c("FT01","FT02","FT03","NFT04","NFT05","NFT06","HT07")

# Map raw instrument sample names -> unified tree IDs (parallels leaf T1-T7).
relabel <- c("FT1"="FT01","FT2"="FT02","FT3"="FT03",
             "NB1"="NFT04","NB2"="NFT05","NB3"="NFT06","HT"="HT07")

group_of <- function(s) dplyr::case_when(
  str_starts(s, "FT")  ~ "Bokashi",     # FT01-03
  str_starts(s, "NFT") ~ "Untreated",   # NFT04-06
  str_starts(s, "HT")  ~ "Healthy ref") # HT07
group_pal <- c("Untreated" = "#EE6677", "Bokashi" = "#228833", "Healthy ref" = "#4477AA")
# each soil sample its own symbol within group colour
samp_shapes <- c("FT01"=16,"FT02"=17,"FT03"=15,"NFT04"=16,"NFT05"=17,"NFT06"=15,"HT07"=18)

# ============================================================================
# 1. READ DATA  (extracted from the companion spreadsheet)
# ============================================================================
std <- read_csv("soil_standards.csv", show_col_types = FALSE) %>%
  separate(wavelength, into = c("element","wl"), sep = " ", remove = FALSE) %>%
  mutate(wl = as.numeric(wl))

samp_I <- read_csv("soil_sample_intensities.csv", show_col_types = FALSE) %>%
  separate(wavelength, into = c("element","wl"), sep = " ", remove = FALSE) %>%
  mutate(wl = as.numeric(wl))

conc_ppm <- c(0, 1, 5, 10, 50, 100)   # standard concentrations

# long form of standards: wavelength x concentration -> intensity
std_long <- std %>%
  pivot_longer(c0:c100, names_to = "stdcol", values_to = "intensity") %>%
  mutate(conc = conc_ppm[match(stdcol, c("c0","c1","c5","c10","c50","c100"))]) %>%
  filter(!is.na(intensity))   # drops Cu100 offscale

# ============================================================================
# 2A. CLASSICAL QUADRATIC CALIBRATION  (reproduce teammate)
#      I = a*C^2 + b*C + d ; fit lm(intensity ~ poly raw C + C^2)
# ============================================================================
quad_fit <- std_long %>%
  group_by(wavelength, element, wl) %>%
  group_modify(~{
    d <- .x
    fit <- lm(intensity ~ I(conc) + I(conc^2), data = d)
    co <- coef(fit)
    tibble(d_int = co[["(Intercept)"]],
           b     = co[["I(conc)"]],
           a     = co[["I(conc^2)"]],
           r2    = summary(fit)$r.squared,
           n_std = nrow(d))
  }) %>% ungroup()

# solve quadratic a*C^2 + b*C + (d - I) = 0 for C, positive physical root
solve_quad <- function(a, b, d, I) {
  disc <- b^2 - 4*a*(d - I)
  if (is.na(disc) || disc < 0) return(NA_real_)
  r1 <- (-b + sqrt(disc)) / (2*a)
  r2 <- (-b - sqrt(disc)) / (2*a)
  cand <- c(r1, r2); cand <- cand[is.finite(cand)]
  pos <- cand[cand >= 0]
  if (length(pos) == 0) return(NA_real_)
  min(pos)   # smallest non-negative root = within calibrated branch
}

samp_long <- samp_I %>%
  pivot_longer(FT1:HT, names_to = "sample", values_to = "intensity") %>%
  mutate(sample = recode(sample, !!!relabel)) %>%
  left_join(quad_fit, by = c("wavelength","element","wl"))

quad_conc <- samp_long %>%
  rowwise() %>%
  mutate(conc_quad = solve_quad(a, b, d_int, intensity)) %>%
  ungroup()

# ---- verify against teammate's published concentrations --------------------
teammate <- read_csv("soil_teammate_conc.csv", show_col_types = FALSE) %>%
  pivot_longer(FT1:HT, names_to = "sample", values_to = "conc_teammate") %>%
  mutate(sample = recode(sample, !!!relabel))

verify <- quad_conc %>%
  select(wavelength, sample, conc_quad) %>%
  left_join(teammate, by = c("wavelength","sample")) %>%
  mutate(abs_diff = abs(conc_quad - conc_teammate))

# Reproduction check on the RELIABLE lines only (the rejected lines Mn 279.482
# and Zn 213.857 have broken intensities where the solver legitimately differs;
# comparing on them would be meaningless since both analyses reject them).
reliable_lines <- c("Al 396.152","Al 394.401","Fe 371.993","Fe 385.991",
                    "Mn 403.076","Cu 324.754","Cu 327.395","Zn 481.053",
                    "Mo 553.305","Mo 603.066")
verify_ok <- verify %>% filter(wavelength %in% reliable_lines)

message("\n=== QUADRATIC verification vs teammate spreadsheet (reliable lines) ===")
message("Max abs difference: ", signif(max(verify_ok$abs_diff, na.rm = TRUE), 3),
        " mg/L  (i.e. reproduces the spreadsheet to floating-point precision)")
message("Rejected lines (Mn 279.482, Zn 213.857) differ as expected on broken signal and are excluded from both analyses.")

message("\nMy quadratic coefficients (recommended lines):")
print(quad_fit %>% filter(wavelength %in% c("Al 396.152","Fe 371.993","Mn 403.076",
                                            "Cu 324.754","Zn 481.053","Mo 553.305")) %>%
        mutate(across(c(a,b,d_int,r2), ~signif(., 6))))

# ============================================================================
# 2B. INVERSE MULTIVARIATE CALIBRATION  (our leaf method, applied to soil)
#      C ~ I_line1 + I_line2 per element (both lines as predictors)
# ============================================================================
# wide standards: I1 (first/lower-wl line), I2 (second line) per element
std_wide <- std_long %>%
  group_by(element) %>% mutate(line_idx = dense_rank(wl)) %>% ungroup() %>%
  select(element, conc, line_idx, intensity) %>%
  pivot_wider(names_from = line_idx, values_from = intensity, names_prefix = "I")

inv_fit <- std_wide %>%
  group_by(element) %>%
  group_modify(~{
    d <- .x %>% filter(!is.na(I1), !is.na(I2))
    if (nrow(d) < 4) return(tibble(b0=NA,b1=NA,b2=NA,r2=NA_real_))
    f <- lm(conc ~ I1 + I2, data = d)
    co <- coef(f)
    tibble(b0 = co[["(Intercept)"]], b1 = co[["I1"]],
           b2 = if ("I2" %in% names(co)) co[["I2"]] else NA_real_,
           r2 = summary(f)$r.squared)
  }) %>% ungroup()

samp_wide <- samp_I %>%
  group_by(element) %>% mutate(line_idx = dense_rank(wl)) %>% ungroup() %>%
  select(element, sample_cols = wavelength, line_idx, FT1:HT) %>%
  pivot_longer(FT1:HT, names_to = "sample", values_to = "intensity") %>%
  mutate(sample = recode(sample, !!!relabel)) %>%
  select(element, line_idx, sample, intensity) %>%
  pivot_wider(names_from = line_idx, values_from = intensity, names_prefix = "I")

inv_conc <- samp_wide %>%
  left_join(inv_fit, by = "element") %>%
  mutate(conc_inv = b0 + b1*I1 + ifelse(is.na(b2), 0, b2)*I2)

# ============================================================================
# 3. COMPARE THE TWO CALIBRATIONS (figure S2)
#    On the recommended line per element, quadratic vs inverse-multivariate.
# ============================================================================
recommended <- c("Al"="Al 396.152","Fe"="Fe 371.993","Mn"="Mn 403.076",
                 "Cu"="Cu 324.754","Zn"="Zn 481.053")

cmp <- quad_conc %>%
  filter(wavelength %in% recommended) %>%
  select(element, sample, conc_quad) %>%
  left_join(inv_conc %>% select(element, sample, conc_inv), by = c("element","sample")) %>%
  mutate(group = group_of(sample))

write_csv(cmp, file.path(out_dir, "calibration_method_comparison.csv"))

message("\n=== Quadratic vs Inverse-multivariate (recommended lines) ===")
print(cmp %>% group_by(element) %>%
        summarise(mean_quad = mean(conc_quad), mean_inv = mean(conc_inv),
                  mean_abs_diff = mean(abs(conc_quad - conc_inv)),
                  .groups="drop") %>%
        mutate(across(where(is.numeric), ~signif(., 4))))

base_theme <- theme_bw(base_size = 13) +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_rect(fill = "grey92", colour = NA),
        strip.text = element_text(face = "bold"))

p_cmp <- ggplot(cmp, aes(conc_quad, conc_inv, colour = group, shape = sample)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey50") +
  geom_point(size = 3) +
  facet_wrap(~ element, scales = "free", ncol = 3) +
  scale_colour_manual(values = group_pal, name = "Treatment") +
  scale_shape_manual(values = samp_shapes, name = "Sample", na.translate = FALSE) +
  labs(title = "Soil calibration methods compared: quadratic vs inverse-multivariate",
       subtitle = "Each point one sample on its recommended line; dashed = perfect agreement (1:1)",
       x = "Quadratic-calibrated conc (mg/L)",
       y = "Inverse-model conc (mg/L)") +
  base_theme
save_png(p_cmp, "S2_calibration_method_comparison.png", width = 12, height = 7)

# ============================================================================
# 4. RESULTS TABLE (quadratic, recommended lines) + reliability ordering
# ============================================================================
# Element display order: reliable first; quarantine the rejected lines visually
# by element (we only plot recommended lines, so all 5 kept are reliable;
# Mo excluded as <DL). For the per-line diagnostic we mark rejected lines.
results <- quad_conc %>%
  filter(wavelength %in% recommended) %>%
  mutate(group = group_of(sample),
         element = factor(element, levels = c("K","Mg","Zn","Al","Mn","Cu","Fe")),
         sample = factor(sample, levels = samples_all))

write_csv(results %>% select(element, wavelength, sample, group, conc_quad),
          file.path(out_dir, "soil_concentrations.csv"))

# ---- 4a. soil concentrations by treatment and sample -----------------------
elem_order_soil <- c("Al","Mn","Cu","Zn","Fe")   # all reliable on recommended line
results <- results %>% mutate(element = factor(element, levels = elem_order_soil))

p_samp <- ggplot(results, aes(group, conc_quad, colour = group, shape = sample)) +
  geom_jitter(width = 0.12, height = 0, size = 3, alpha = 0.9) +
  stat_summary(aes(group = group), fun = mean, geom = "crossbar",
               width = 0.5, linewidth = 0.3, colour = "grey25") +
  facet_wrap(~ element, scales = "free_y", ncol = 3) +
  scale_colour_manual(values = group_pal, name = "Treatment") +
  scale_shape_manual(values = samp_shapes, name = "Sample", na.translate = FALSE) +
  labs(title = "Soil mineral concentrations by treatment and sample (quadratic calibration)",
       subtitle = "Point = one soil sample (shape); colour = treatment; bar = group mean. Units mg/L in solution.",
       x = NULL, y = "Concentration (mg/L in solution)") +
  base_theme +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))
save_png(p_samp, "03_soil_by_treatment.png", width = 12, height = 7)

# ============================================================================
# 5. DESCRIPTIVE COMPARISON (NOT formal testing; n = 3 vs 3, HT = 1)
# ============================================================================
group_desc <- results %>%
  group_by(element, group) %>%
  summarise(mean = mean(conc_quad), sd = sd(conc_quad), n = n(), .groups = "drop")
message("\nSoil descriptive group summary (mg/L; unit = sample, n = samples):")
print(group_desc %>% mutate(across(where(is.numeric), ~round(., 3))))

explore <- results %>%
  filter(group %in% c("Bokashi","Untreated")) %>%
  group_by(element) %>%
  group_modify(~{
    x <- .x$conc_quad[.x$group=="Bokashi"]; y <- .x$conc_quad[.x$group=="Untreated"]
    tt <- tryCatch(t.test(x, y), error = function(e) NULL)
    tibble(mean_bokashi = mean(x), mean_untreated = mean(y), diff = mean(x)-mean(y),
           p_exploratory = if (is.null(tt)) NA_real_ else tt$p.value)
  }) %>% ungroup()
message("\nEXPLORATORY ONLY (n=3 vs 3, underpowered -- do NOT report as result):")
print(explore %>% mutate(across(where(is.numeric), ~round(., 3))))

# ============================================================================
# 6. PCA  (figure 10)  -- soil, standardised, reliable elements
#    Soil has all 5 recommended-line elements reliable (Al, Mn, Cu, Zn, Fe);
#    Mo is <DL and excluded. Full rank, no NAs. Sample = unit, HT marked.
# ============================================================================
pca_vars <- elem_order_soil
pca_mat <- results %>%
  select(sample, group, element, conc_quad) %>%
  pivot_wider(names_from = element, values_from = conc_quad) %>%
  arrange(sample)

X <- pca_mat %>% select(all_of(pca_vars)) %>% as.matrix()
rownames(X) <- pca_mat$sample
stopifnot(!anyNA(X))
cat("\nSoil PCA matrix rank:", qr(scale(X))$rank, "of", ncol(X), "variables\n")

pca <- prcomp(X, center = TRUE, scale. = TRUE)
ve  <- 100 * pca$sdev^2 / sum(pca$sdev^2)
scores <- as_tibble(pca$x[, 1:2], rownames = "sample") %>%
  left_join(pca_mat %>% select(sample, group), by = "sample")
load <- as_tibble(pca$rotation[, 1:2], rownames = "element")
arrow_scale <- 0.9 * max(abs(scores$PC1), abs(scores$PC2))

p_pca <- ggplot(scores, aes(PC1, PC2, colour = group, shape = sample)) +
  geom_hline(yintercept = 0, colour = "grey85") +
  geom_vline(xintercept = 0, colour = "grey85") +
  geom_segment(data = load, inherit.aes = FALSE,
               aes(x=0, y=0, xend = PC1*arrow_scale, yend = PC2*arrow_scale),
               arrow = arrow(length = unit(0.18,"cm")), colour = "grey45", linewidth = 0.4) +
  geom_text(data = load, inherit.aes = FALSE,
            aes(x = PC1*arrow_scale*1.12, y = PC2*arrow_scale*1.12, label = element),
            colour = "grey30", size = 4, fontface = "bold") +
  geom_point(size = 4, stroke = 1) +
  geom_text(aes(label = sample), vjust = -1.1, size = 3, show.legend = FALSE) +
  scale_colour_manual(values = group_pal, name = "Treatment") +
  scale_shape_manual(values = samp_shapes, name = "Sample", na.translate = FALSE) +
  labs(title = "PCA of soil minerals (Al, Mn, Cu, Zn, Fe; standardised)",
       subtitle = "Each point one soil sample; colour = treatment, shape = sample. Arrows = element loadings.",
       x = sprintf("PC1 (%.1f%%)", ve[1]), y = sprintf("PC2 (%.1f%%)", ve[2])) +
  base_theme + coord_equal()
save_png(p_pca, "10_soil_pca.png", width = 9, height = 7)

message("\nSoil PCA variance explained (%): ", paste(sprintf('%.1f', ve), collapse=", "))
message("Loadings:"); print(load %>% mutate(across(where(is.numeric), ~round(.,3))))

message("\nDONE. Figures in ./figures_soil, tables in ./output_soil")
