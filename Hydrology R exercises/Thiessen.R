
##################
# GETTING STARTED 
##################

# This statement removes everything from R's memory.
rm(list=ls())


# Set working directory, either by typing the path or clicking:
# Go to Session > Set working directory > To source file location.
# For more explanation, read section 2.4 of the R intro.
setwd("C:/.../")

# Load packages that are used for spatial plotting.
# First install the packages (see R intro 2.5) and then run the following lines.
library(terra)

# You can ignore warnings, but don't ignore the errors.
# If you get an error like
# "Error in library(terra) : there is no package called 'terra'"
# then you need to install the package first.

# Load helper functions with hints and checks.
# If you get the error "Cannot open file...", then you probably didn't
# set the working directory correctly. (Did you unzip before opening the script?)
source("helper_functions/functions_P_check.R")



############
# READ DATA
############

# Read file with rainfall data 
Pdata = read.table("data/P_hour_Ourthe_2002.txt", header=TRUE)

# The date of the P measurement is in the first column.
date  = Pdata[,1]

# The P measurements at each station are in the other columns.
P     = Pdata[,2:ncol(Pdata)]


# Read file with locations and elevations of raingauges.
Gauges       = read.table("data/XYZ_Raingauges_Ourthe.txt", header=TRUE) 
Gauges_names = Gauges [,1]
Gauges_XY    = Gauges [,2:3]
Gauges_Z     = Gauges [,4]

# Read files with catchment boundary (called "shapefiles").
# If you get an error "Error in vect... " you probably forgot to load the package (line 18).
boundary = vect("data/angleurBoundary_UTM31N.shp")

# Read file with area within catchment (called "mask").
# This is used to remove the pixels outside the catchment.
mask     = rast("data/catchment_1km.asc")       



###################
# COMPUTE POLYGONS
###################


# 1.READ thiessen FUNCTION


# Read the function from another R script.
# The command "source" reads the whole script at once (Section 5 of the R intro)
source("Thiessen_function.R")

# This function has one argument: the date in format yyyymmddhh.
# If you call it with a certain date (for example 2002010101), it will:
#   1. Select the rainfall measured at that date at each rain gauge from all rainfall data.
#   2. Compute Thiessen polygons.
#   3. Compute rainfall sum per pixel
#   4. Compute the catchment average rainfall (shown as a number in the Console).
#   5. Plot the rainfall sum for each pixel (shown in the Plots window).


# 2. CALL thiessen FUNCTION

# Type for which day and hour you want to make a figure and compute the Thiessen areal rainfall.
# Example days: 26 Jan, 12 Feb, 20 Feb, 19 Mar, 3 Jul, 25 Oct, 10 Nov, 22 Dec
# fill the right date in yourself (format: yyyymmddhh)
thiessen(2002122101)

# If it doesn't work: type: hints_thiessen_function()
# (you don't have to add anything between the brackets). 

# To follow one rain storm, run several dates after each other.
# Click the arrows in the plot window to follow the rain storm.
# The cloud that passed between 10 Nov 19:00 and 11 Nov 04:00:
thiessen(2002111019)
thiessen(2002111020)
thiessen(2002111021)
thiessen(2002111022)
thiessen(2002111023)
thiessen(2002111100)
thiessen(2002111101)
thiessen(2002111102)
thiessen(2002111103)
thiessen(2002111104)




######################
# DETERMINE FRACTIONS
######################

# Determine the contribution of each polygon once to compute 
# the catchment average precipitation later.

# There are as many raingauges as there are columns in the data file
N_gauges = ncol(P)

# Make a vector from the first to the last raingauge
gauge_number = seq(1:N_gauges)

# Combine coordinates and rainfall in one matrix
xyz = cbind(x=Gauges$X, y=Gauges$Y, z=gauge_number)

# Use Nearest neighbour interpolation
P_map_th = interpNear(mask, xyz, radius=100000)

# Cut off the pixels outside the catchment
P_map_th_inside_catchment = P_map_th * mask

# Compute the mean of al points within the catchment.
# This is the catchment average precipitation. 
Polygons = as.matrix(P_map_th_inside_catchment, wide=T)

# Compute the area for each rain gauge
# Run this for-loop in one go and not line by line.
N_Pixels=c()
for(i in 1:N_gauges)
{
  N_Pixels[i] = length(Polygons[Polygons==i & is.na(Polygons)==FALSE])
}

# Determine the relative contribution of each raingauge
# The sum of the contributions of all rain gauges should be 1
weights = N_Pixels / sum(N_Pixels) 

# Round off at 3 digits
weights = round(weights,3)

# Write data to file with names of rain gauges
write.table(weights, row.names=Gauges_names,"weights_Thiessen.dat")






#######################################
# Analyze differences between stations
#######################################

# Compute the yearly sum of all rain gauges.
# Look up the functions rowSums, rowMeans, colSums and colMeans 
# in reference list on the last pages of the R intro.
# or in the help function. Use one of these funtions to compute the yearly sums
# P has one column per gauge, so sum each column.
yearsum_gauges = colSums(P, na.rm=TRUE)

check_yearsum_gauges()

# make barplot of the yearly sums of all stations
# (look up how to make barplots in R intro if necessary)
barplot(yearsum_gauges, names.arg=Gauges_names, las=2, cex.names=0.6,
        ylab="Yearly rainfall sum 2002 [mm]")

# compute the largest and smallest yearly sum of all stations
mean_year_sum_gauges = mean(yearsum_gauges)
sd_year_sum_gauges   = sd(yearsum_gauges)
max_year_sum_gauges  = max(yearsum_gauges)
min_year_sum_gauges  = min(yearsum_gauges)

# plot yearly sum of rain gauges as a function of rain gauge elevation
plot(Gauges_Z, yearsum_gauges, pch=20,
     xlab="Elevation [m]", ylab="Yearly rainfall sum 2002 [mm]")




##########################################
# COMPUTE CATCHMENT AVERAGE PRECIPITATION
##########################################

# 1. THIESSEN METHOD

# Multiply the rainfall time series measured at each station 
# with its contribution and sum them up to get the catchment average P

# First make a vector with as many zeroes as the time series is long.
# This will become the new rainfall time series.
P_th = rep(0,nrow(P))

# Run a for-loop over each station. In each loop, the contribution 
# of one station is multiplied with the vector with rainfall measured 
# at that station and it is added to the total
# Run this for-loop in one go and not line by line.
for(i in 1:42) 
{
  P_th = P_th + weights[i] * P[,i]
}


# 2. ARITHMETIC MEAN METHOD

# Also compute the spatial mean precipitation for each time step.
# This is called the arithmetic mean method to obtain catchment 
# average rainfall.
# You can compute this by averaging the measurements of all stations 
# for each time step. 
# Use either the function rowMeans or colMeans and the matrix 
# with all the rainfall data called P.
# P has one row per time step, so average each row.
P_ar = rowMeans(P, na.rm=TRUE)

check_P_ar()


# 3. ONE SINGLE RAIN GAUGE
# Use the gauge with the largest Thiessen weight.
P_one = P[, which.max(weights)]

check_P_one()


########################################################
# Analyze differences between catchment average methods
########################################################

# The yearly rainfall sums for the three methods
yearsum_ar     = sum(P_ar , na.rm=TRUE)
yearsum_th     = sum(P_th , na.rm=TRUE)
yearsum_one    = sum(P_one, na.rm=TRUE)

# The maximum hourly rainfall sums for the three methods
max_ar     = max(P_ar , na.rm=TRUE)
max_th     = max(P_th , na.rm=TRUE)
max_one    = max(P_one, na.rm=TRUE)

# plot P_th as a function of P_ar
plot(P_ar, P_th, pch=20, xlab="P arithmetic mean [mm/h]", ylab="P Thiessen [mm/h]")
abline(a=0, b=1, col="red")

# plot P_th as a function of the station with the largest contribution
plot(P_one, P_th, pch=20,
     xlab=paste("P", Gauges_names[which.max(weights)], "[mm/h]"), ylab="P Thiessen [mm/h]")
abline(a=0, b=1, col="red")








