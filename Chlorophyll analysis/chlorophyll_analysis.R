# ============================================================================
# CHLOROPHYLL ANALYSIS — Quercus robur leaf samples
# Lichtenthaler & Welburn (1983) equations, 80% acetone extraction
# A645 nm and A663 nm spectrophotometer readings
#
# Reads:  spec_meter_readings.xltx (raw absorbance readings)
# Writes: Figure1_Chlorophyll_BarChart.png
#         Figure2_Chlorophyll_BoxPlot_byTree.png
#         summary_by_treatment.csv
#         summary_by_tree.csv
#         chlorophyll_full_data.csv
# ============================================================================

# ---- Packages ----
# install.packages(c("readxl", "dplyr", "tidyr", "stringr", "ggplot2"))
library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)

# ---- Paths ----
# Edit if your working directory differs
INPUT_FILE  <- "spec_meter_readings.xltx"
OUT_DIR     <- "."

# ---- 1. Load raw spectrophotometer data ----
# The file is in wide format: repeating groups of columns
# (Sample | Chl_a_absorbance | Chl_b_absorbance | <blank>) for each tree per row.
raw <- read_excel(INPUT_FILE, sheet = 1)

# Pivot the repeating column groups into long format
df_list <- list()
for (i in seq(1, ncol(raw), by = 4)) {
  if (i + 2 <= ncol(raw)) {
    block <- raw[, i:(i + 2)]
    names(block) <- c("Sample", "A645", "A663")
    block <- block %>%
      filter(!is.na(Sample), Sample != "") %>%
      filter(!str_detect(Sample, "FIRST|aprox"))
    if (nrow(block) > 0) df_list[[length(df_list) + 1]] <- block
  }
}

df <- bind_rows(df_list) %>%
  mutate(A645 = as.numeric(A645),
         A663 = as.numeric(A663)) %>%
  filter(!is.na(A645), !is.na(A663))

cat(sprintf("Loaded %d valid samples\n", nrow(df)))

# ---- 2. Apply Lichtenthaler & Welburn (1983) equations ----
# Chl a   (μg/mL) = 12.21 * A663 - 2.81 * A645
# Chl b   (μg/mL) = 20.13 * A645 - 5.03 * A663
# Total   (μg/mL) = 17.76 * A645 + 7.43 * A663
df <- df %>%
  mutate(
    Chl_a     = 12.21 * A663 - 2.81 * A645,
    Chl_b     = 20.13 * A645 - 5.03 * A663,
    Total_Chl = 17.76 * A645 + 7.43 * A663,
    Tree      = str_extract(Sample, "T\\d"),
    Treatment = case_when(
      Tree %in% c("T1", "T2", "T3") ~ "Bokashi Treated",
      Tree %in% c("T4", "T5", "T6") ~ "Untreated (Unhealthy)",
      Tree == "T7"                   ~ "Healthy Reference",
      TRUE                           ~ NA_character_
    ),
    Treatment = factor(Treatment, levels = c("Bokashi Treated",
                                             "Untreated (Unhealthy)",
                                             "Healthy Reference"))
  )

# ---- 3. Summary statistics ----
summary_treatment <- df %>%
  group_by(Treatment) %>%
  summarise(
    N           = n(),
    Mean_Chl_a  = mean(Chl_a),     SD_Chl_a  = sd(Chl_a),
    Mean_Chl_b  = mean(Chl_b),     SD_Chl_b  = sd(Chl_b),
    Mean_Total  = mean(Total_Chl), SD_Total  = sd(Total_Chl),
    Min_Total   = min(Total_Chl),  Max_Total = max(Total_Chl),
    .groups = "drop"
  )

summary_tree <- df %>%
  group_by(Tree, Treatment) %>%
  summarise(
    N           = n(),
    Mean_Chl_a  = mean(Chl_a),     SD_Chl_a  = sd(Chl_a),
    Mean_Chl_b  = mean(Chl_b),     SD_Chl_b  = sd(Chl_b),
    Mean_Total  = mean(Total_Chl), SD_Total  = sd(Total_Chl),
    .groups = "drop"
  ) %>%
  arrange(Tree)

print(summary_treatment)
print(summary_tree)

# ---- 4. Write CSV outputs ----
write.csv(df,                file.path(OUT_DIR, "chlorophyll_full_data.csv"),  row.names = FALSE)
write.csv(summary_treatment, file.path(OUT_DIR, "summary_by_treatment.csv"),   row.names = FALSE)
write.csv(summary_tree,      file.path(OUT_DIR, "summary_by_tree.csv"),        row.names = FALSE)

# ---- 5. Plot colours ----
# Untreated = RED (concern), Bokashi = GREEN, Healthy = BLUE
treatment_colors <- c(
  "Bokashi Treated"        = "#27ae60",
  "Untreated (Unhealthy)"  = "#c0392b",
  "Healthy Reference"      = "#2980b9"
)

# ---- 6. FIGURE 1: Bar chart of treatment means ± SD ----
fig1_data <- summary_treatment %>%
  mutate(label = sprintf("%.2f ± %.2f\n(n=%d)", Mean_Total, SD_Total, N))

fig1 <- ggplot(fig1_data,
               aes(x = Treatment, y = Mean_Total, fill = Treatment)) +
  geom_col(alpha = 0.85, colour = "black", linewidth = 0.6, width = 0.7) +
  geom_errorbar(aes(ymin = Mean_Total - SD_Total,
                    ymax = Mean_Total + SD_Total),
                width = 0.2, linewidth = 0.8) +
  geom_text(aes(label = label,
                y = Mean_Total + SD_Total + 0.5),
            fontface = "bold", size = 3.5) +
  scale_fill_manual(values = treatment_colors, guide = "none") +
  scale_y_continuous(limits = c(0, 17.5), expand = c(0, 0)) +
  labs(
    title    = "Figure 1. Total chlorophyll concentration by treatment group in Quercus robur leaves",
    subtitle = "Lichtenthaler & Welburn (1983); 80% acetone; mean ± SD",
    x = "Treatment Group",
    y = "Mean Total Chlorophyll (μg/mL)"
  ) +
  theme_bw(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold", hjust = 0.5, size = 12),
    plot.subtitle = element_text(hjust = 0.5),
    axis.title    = element_text(face = "bold"),
    panel.grid.major.x = element_blank()
  )

ggsave(file.path(OUT_DIR, "Figure1_Chlorophyll_BarChart.png"),
       fig1, width = 10, height = 7, dpi = 300, bg = "white")

# ---- 7. FIGURE 2: Box plot by individual tree ----
tree_order <- paste0("T", 1:7)

# Each tree inherits its treatment colour
tree_treatment <- df %>% distinct(Tree, Treatment)

# Per-tree means for annotation labels
tree_means <- df %>%
  group_by(Tree) %>%
  summarise(mean_val = mean(Total_Chl),
            max_val  = max(Total_Chl), .groups = "drop")

fig2 <- ggplot(df, aes(x = Tree, y = Total_Chl, fill = Treatment)) +
  geom_boxplot(alpha = 0.85, outlier.shape = 21, outlier.size = 1.5,
               colour = "black", linewidth = 0.5, width = 0.6) +
  geom_jitter(width = 0.15, alpha = 0.3, size = 1.2, colour = "black") +
  geom_text(data = tree_means,
            aes(x = Tree, y = max_val + 0.8,
                label = sprintf("μ=%.2f", mean_val)),
            fontface = "italic", size = 3.2, inherit.aes = FALSE) +
  scale_fill_manual(
    values = treatment_colors,
    breaks = c("Bokashi Treated", "Untreated (Unhealthy)", "Healthy Reference"),
    labels = c("Bokashi Treated (T1–T3)",
               "Untreated — Unhealthy (T4–T6)",
               "Healthy Reference (T7)")
  ) +
  scale_y_continuous(limits = c(3.5, 24)) +
  scale_x_discrete(limits = tree_order) +
  labs(
    title    = "Figure 2. Total chlorophyll variation by individual tree in Quercus robur",
    subtitle = "n=24 measurements per tree; boxes show median, IQR, and range",
    x = "Individual Tree",
    y = "Total Chlorophyll (μg/mL)",
    fill = NULL
  ) +
  theme_bw(base_size = 11) +
  theme(
    plot.title         = element_text(face = "bold", hjust = 0.5, size = 12),
    plot.subtitle      = element_text(hjust = 0.5),
    axis.title         = element_text(face = "bold"),
    legend.position    = "bottom",
    legend.box         = "horizontal",
    panel.grid.major.x = element_blank()
  )

ggsave(file.path(OUT_DIR, "Figure2_Chlorophyll_BoxPlot_byTree.png"),
       fig2, width = 12, height = 7, dpi = 300, bg = "white")

cat("\nAll outputs written to:", normalizePath(OUT_DIR), "\n")
cat(" - Figure1_Chlorophyll_BarChart.png\n")
cat(" - Figure2_Chlorophyll_BoxPlot_byTree.png\n")
cat(" - chlorophyll_full_data.csv\n")
cat(" - summary_by_treatment.csv\n")
cat(" - summary_by_tree.csv\n")
