# Solutions to the ToDo exercises in "A (very) short introduction to R"
# (Torfs & Brauer). Set the working directory to this folder first, e.g.
# setwd("D:/R intro ToDos/"), then run section by section with CTRL+ENTER.

# ---- 3.1 Calculator --------------------------------------------------------
# Percentage of your life spent at this university.
# Started at university in 2022, born in 2004.
(2026 - 2022) / (2026 - 2004) * 100      # 18.18 %

# ---- 3.2 Workspace ---------------------------------------------------------
# Same computation, with several steps in between.
current_year = 2026
start_year = 2022
birth_year = 2004
years_at_uni = current_year - start_year
age = current_year - birth_year
fraction = years_at_uni / age
percentage = fraction * 100
percentage

# ---- 3.4 Functions ---------------------------------------------------------
# Sum of 4, 5, 8 and 11.
v = c(4, 5, 8, 11)
sum(v)                         # 28

# ---- 3.5 Plots -------------------------------------------------------------
# Plot 100 normal random numbers.
plot(rnorm(100))

# ---- 4 Help and documentation ----------------------------------------------
# Find help for the sqrt function.
help(sqrt)                     # or ?sqrt

# ---- 5 Scripts -------------------------------------------------------------
# See firstscript.R in this folder; run it several times:
source("firstscript.R")

# ---- 6.2 Matrices ----------------------------------------------------------
# Numbers 31 to 60 in a vector P and a 6 x 5 matrix Q.
P = seq(from = 31, to = 60)
Q = matrix(data = P, nrow = 6, ncol = 5)
P
Q
# In the environment window P shows as "int [1:30] 31 32 33 ..." (a vector),
# Q as "int [1:6, 1:5] 31 32 33 ..." (a matrix) and a scalar such as
# percentage just as its value.

# ---- 6.3 Data frames -------------------------------------------------------
# Three random normal vectors and a data frame with their cumulative sums.
x1 = rnorm(100)
x2 = rnorm(100)
x3 = rnorm(100)
t = data.frame(a = x1, b = x1 + x2, c = x1 + x2 + x3)
plot(t)
# plot(t) gives a scatterplot matrix: every column plotted against every
# other column. a, b and c share terms, so they are positively correlated:
# b against a and c against b show clear upward clouds, c against a a weaker
# one. Each rerun gives new random numbers but the same pattern.

# ---- 7 Graphics ------------------------------------------------------------
plot(t$a, type = "l", ylim = range(t),
     lwd = 3, col = rgb(1, 0, 0, 0.3))
lines(t$b, type = "s", lwd = 2,
      col = rgb(0.3, 0.4, 0.3, 0.9))
points(t$c, pch = 20, cex = 4,
       col = rgb(0, 0, 1, 0.3))
# rgb(red, green, blue, alpha): a colour mixed from red, green and blue
#   intensities between 0 and 1. The last argument, alpha, is the opacity
#   (0 = fully transparent, 1 = fully opaque), so overlapping points show
#   through each other.
# lwd: line width (1 is the default, larger is thicker).
# pch: plotting character, i.e. the point symbol (20 is a small filled dot,
#   1 an open circle, 2 a triangle, ...).
# cex: character expansion, the size of the points/text relative to the
#   default (cex = 4 is four times as large).

# ---- 8 Reading and writing data files --------------------------------------
# tst1.txt (in this folder) contains the table from Figure 4.
d = read.table(file = "tst1.txt", header = TRUE)
d$g = d$g * 5
write.table(d, file = "tst2.txt", row.names = FALSE)
d

# ---- 9 Not available data --------------------------------------------------
# Mean of the square root of 100 random numbers.
r = rnorm(100)
mean(sqrt(r))
# About half of the numbers are negative and the square root of a negative
# number is not a real number, so sqrt gives NaN ("Not a Number") for them
# together with a warning. The mean of a vector containing NaN is NaN.
# Ignoring those values works the same way as for NA:
mean(sqrt(r), na.rm = TRUE)

# ---- 10.2 Dates ------------------------------------------------------------
# Presents on today, Sinterklaas 2017 and your next birthday.
# Next birthday: 22 May 2027.
dates = strptime(c("20261005", "20171205", "20270522"), format = "%Y%m%d")
presents = c(0, 3, 2)
plot(dates, presents, type = "p", pch = 20, cex = 2,
     xlab = "Date", ylab = "Number of presents")

# ---- 11.2 For-loop ---------------------------------------------------------
# Multiply elements < 5 and > 90 by 10, all other elements by 0.1.
h = seq(from = 1, to = 100)
s = c()
for (i in 1:100)
{
  if (h[i] < 5 | h[i] > 90)
  {
    s[i] = h[i] * 10
  } else {
    s[i] = h[i] * 0.1
  }
}
s

# ---- 11.3 Writing your own functions ---------------------------------------
# The same computation as a function that works on any vector.
multiply_vector = function(vec)
{
  result = c()
  for (i in 1:length(vec))
  {
    if (vec[i] < 5 | vec[i] > 90)
    {
      result[i] = vec[i] * 10
    } else {
      result[i] = vec[i] * 0.1
    }
  }
  return(result)
}
multiply_vector(seq(from = 1, to = 100))
multiply_vector(c(3, 50, 95))  # 30 5 950

# As footnote 9 says, this can also be done without a for-loop:
vec = 1:100
ifelse(vec < 5 | vec > 90, vec * 10, vec * 0.1)
