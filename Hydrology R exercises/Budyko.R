

##################
# GETTING STARTED 
##################

# This statement removes everything from R's memory.
rm(list=ls())

# Set working directory, either by typing the path or clicking:
# Go to Session > Set working directory > To source file location.
# For more explanation, read section 2.4 of the R intro.
setwd("C:/.../")

# Load helper functions with hints and checks.
# If you get the error "Cannot open file...", then you probably didn't
# set the working directory correctly.
source("helper_functions/functions_ET_check.R")


############
# READ DATA
############

# read data: daily discharge, precipitation, evapotranspiration 
# and groundwater data from different catchments
Gua = read.table("data/PEQ_Guadiana_day.dat"    , header=TRUE)
Hup = read.table("data/PEQ_Hupsel_day.dat"      , header=TRUE)
Mah = read.table("data/PEQ_Mahakam_day.dat"     , header=TRUE)
Met = read.table("data/PEQ_Metuje_day.dat"      , header=TRUE)
Nar = read.table("data/PEQ_Narsjo_day.dat"      , header=TRUE)
Our = read.table("data/PEQ_Ourthe_day.dat"      , header=TRUE)
Ply = read.table("data/PEQ_Plynlimon_day.dat"   , header=TRUE)
Rie = read.table("data/PEQ_Rietholzbach_day.dat", header=TRUE)

# specify the names of the catchments in a vector
ID   = c("Gua","Hup","Mah","Met","Nar","Our","Ply","Rie")
name = c("Guadiana","Hupsel","Mahakam","Metuje",
         "Narsjo","Ourthe","Plynlimon","Rietholzbach")




######################
# WATER BALANCE TERMS
######################

# Most data series have gaps (NA values). 
# You cannot compute the sum over a series with NA,
# but you can use a trick.
# Assuming that the gaps are distributed equally over the seasons,
# you can compute the mean of each term while neglecting the NAs
# and multiply it with 365 to get a yearly sum.

# In the lines below empty vectors are defined. 
# You do NOT have to fill in anything here.
# These lines are just to tell R that these vectors exist before 
# you go into the for-loop (for help, see R intro on for-loops).
P_year     = c()
ETpot_year = c()
Q_year     = c()

# Run a for-loop over all catchments.
# In each loop, you evaluate the data from a different catchment
# and paste the answers in a vector.
# The "get(ID[i])" can be read as ID[i], so "Gua" or "Hup",
# but the get() is necessary to tell R that it's not just a character string.
for(i in 1:8)
  {
    P_year[i]     = mean(get(ID[i])$P,     na.rm=TRUE) * 365
    ETpot_year[i] = mean(get(ID[i])$ETpot, na.rm=TRUE) * 365
    Q_year[i]     = mean(get(ID[i])$Q,     na.rm=TRUE) * 365
  }

# Compute ETact by closing the water balance.
# P = ETact + Q (storage change is ~0 over many years), so ETact = P - Q.
ETact_year = P_year - Q_year

check_ETact_year()

# Make barplot of yearly sums of water balance terms of all catchments. 
PEQ = rbind(P_year, ETpot_year, ETact_year, Q_year) 
barplot(PEQ, beside=TRUE, 
        main=paste("P (blue), ETpot (red), ETact (orange) and Q (green)"), 
        col=c("dodgerblue","red","orange","lawngreen"), names=ID)

# Put all waterbalances in one table.
# ("cbind" binds vectors together in a matrix)
WB = cbind(name, P_year, ETpot_year, ETact_year, Q_year)




###############
# BUDYKO CURVE
###############

# plot the right quantities on the x- and y-axis
# x-axis: aridity index ETpot/P, y-axis: evaporative index ETact/P
plot(ETpot_year/P_year, ETact_year/P_year, xlim=c(0,3), ylim=c(0,1.1),
     xlab="ETpot / P [-]", ylab="ETact / P [-]", pch=20)

# Type hint_Budyko_curve_1() if you are stuck and try again.
# Type hint_Budyko_curve_2() if you are still stuck and try again.
# Type hint_Budyko_curve_3() if you are still stuck and copy the code.

# add text labels
text(ID, x=ETpot_year/P_year+0.2, y=ETact_year/P_year)

lines(c(1,1)  ,c(0,1), col="dodgerblue", lty=2)
lines(c(0,1)  ,c(1,1), col="dodgerblue", lty=2)
lines(c(1,3.5),c(1,1), col="dodgerblue")
curve(x*1  , add=TRUE, col="dodgerblue", xlim=c(0,1))



# add Zhang curves

# Fill in the right equation on the dots. 
# The R function "curve" computes the y-value from an x-value. 
# Example: If you plotted P_year on the x-axis and 
# ETpot_year on the y-axis and you think ETpot_year = P_year * 5,
# you type: curve(x*5, add=TRUE, col="green").
# (But this example is wrong of course.)
# Zhang (Eq. 1): ETact/P = 1 + ETpot/P - (1 + (ETpot/P)^w)^(1/w),
# with x = ETpot/P on the x-axis and w = 1.70, 2.63 and 5.00.
curve(1+x-(1+x^1.70)^(1/1.70), add=TRUE, col="green", lty=3)
curve(1+x-(1+x^2.63)^(1/2.63), add=TRUE, col="green", lty=3)
curve(1+x-(1+x^5.00)^(1/5.00), add=TRUE, col="green", lty=3)

# Type hint_Zhang_curve_1() if you are stuck and try again.
# Type hint_Zhang_curve_2() if you are still stuck and try again.
# Type hint_Zhang_curve_3() if you are still stuck and copy the code.


################ 
# SEASONALITY
################
 
# Define 3 empty matrices with space for 8 catchments and 12 months
# so you need 8 columns and 12 rows. Look in the R intro or use the 
# help function for information about the function "matrix".
P_m     = matrix(nrow=12, ncol=8)
ETpot_m = matrix(nrow=12, ncol=8)
Q_m     = matrix(nrow=12, ncol=8)

check_matrix_size()

# Run a for-loop over all catchments
# in each loop, you evaluate the data from a different catchment
# and paste the answers in a vector.
for(i in 1:8)
  {
  # get the 5th and 6th character from the dates; these denote the month
  m           = substr(as.character(get(ID[i])$date),5,6)
  # the function aggregate takes the mean (because FUN=mean) of all elements of
  # vector P with the same values of m and puts that in a new vector. In this case 
  # you get values for each month and you paste it in the column belonging to the catchment. 
  P_m[,i]     = aggregate(get(ID[i])$P    ,by=list(m), FUN=mean, na.rm=TRUE) [,2]
  ETpot_m[,i] = aggregate(get(ID[i])$ETpot,by=list(m), FUN=mean, na.rm=TRUE) [,2]
  Q_m[,i]     = aggregate(get(ID[i])$Q    ,by=list(m), FUN=mean, na.rm=TRUE) [,2]
  }


# make for each catchment a barplot of monthly means of water balance terms
for(i in 1:8)
  {
  # make a table with 3 rows: (1) P, (2) ETpot and (3) Q
  PEQ = rbind(P_m[,i], ETpot_m[,i], Q_m[,i] ) 
  barplot(PEQ, beside=TRUE, main=name[i], 
          names.arg=c("J","F","M","A","M","J","J","A","S","O","N","D"),
          ylab="P,ET,Q [mm/d]", col=c("dodgerblue","red","lawngreen"))
  legend(c("P","ETpot","Q"), col=c("dodgerblue","red","lawngreen"), 
         pch=15, bty="n", x="topleft")
  }




  
  
