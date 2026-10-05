
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
source("helper_functions/functions_Q_check.R")




###########################
###########################
# USING THE UNIT HYDROGRAPH 
###########################
###########################


# First define the unit hydrograph ordinates
UHO_example = c(0.3, 0.6, 0.1)

# Type hint_UHO_example_1() if you are stuck.
# Type hint_UHO_example_2() if you are still stuck.

check_UHO_example()


# make a barplot of UHO_example
barplot(UHO_example, names.arg=1:length(UHO_example), xlab="t [h]", ylab="UHO [-]")



# define the rainfall time series
# 4 hours of rain plus two zeroes, so the whole hydrograph fits
P_example = c(10, 2, 1, 8, 0, 0)

# Type hint_P_example_1() if you are stuck.
# Type hint_P_example_2() if you are still stuck.

check_P_example()

# make a barplot of P_example
barplot(P_example, names.arg=1:length(P_example), xlab="t [h]", ylab="P [mm/h]")




#####################
# conv FUNCTION
#####################

# This function makes a convolution hydrograph from 
# rainfall and unit hydrograph input.
# (partly made by Klaas Thomas Jellema in his BSc thesis)
# This function has two arguments: 
# 1. P: a vector with rainfall 
# 2. U: a vector with the ordinates of the unit hydrograph
conv=function(P,UHO)
  {
  # compute number of time steps (rain measurements)
  nP = length(P)
  # compute number of unit hydrograph ordinates 
  nUHO = length(UHO)
  # make a vector for discharge with the same number of 
  # time steps (so same length as P) with zeroes in each element
  Q = rep(0,nP)
  # run a for-loop over each time step
  for (iP in 1:nP)
    {
    # run a for-loop over each unit hydrograph ordinate
    for (iUHO in 1:nUHO)
      {
      # check if the the element exists
      if(iP >= iUHO)
        {
        # Compute the discharge at time n:
        # Multiply the precipitation of "iUHO" hours ago with the "iOHU"th ordinate
        # and add that to the value you already had.
        # For example: On the 3rd hour, you want to get
        # Q[3] = P[3] * UHO[1] + P[2] * UHO[2] + P[1] * UHO[3] + etc.
        # So, when you go over this loop, the first time (so when iUHO=1),
        # you will get: Q[3] = 0 + P[3] * UHO[1] (because you started with 
        # a vector of zeros, so Q[3] = 0 at first).
        # The second round (iUHO=2), you add P[2] * UHO[2] to this number, 
        # The third round (iUHO=3), you add P[1] * UHO[3] to this number, etc.
        Q[iP] = Q[iP] + P[iP-iUHO+1] * UHO[iUHO]
        }
      }
    }
  return(Q)
  }



### CALL FUNCTION

# use the function
Q_example = conv(P=P_example, UHO=UHO_example)

# plot the discharge as a barplot
barplot(Q_example, names.arg=1:length(Q_example), xlab="t [h]", ylab="Q [mm/h]")



##############################
##############################
# BOTTOM-UP: THE TRIANGULAR UH
##############################
##############################

######################
# triangleUH FUNCTION 
######################

# the function triangle UH makes a UH with:
# base length tt - total time (time after P when all water 
#                   has been discharged)
# and time tp - time to peak (time after P when peak occurs)
# area one (all effective precipitation must be discharged)

triangleUH = function(tt,tp)
{
  # compute the discharge peak
  # area of the triangle = 0.5 * tt * Qp = 1
  Qp = 2 / tt
  # make an empty array for the discharge
  Q=c()
  # for-loop over the whole discharge event
  for(t in 1:tt)
  {
    # if before the peak
    if(t<tp)
    {
      # compute ordinate
      Q[t] = Qp * t / tp
      # if after the peak
    }else{
      # compute ordinate
      Q[t] = Qp * (tt - t) / (tt - tp)
    }
  }
  
  return(Q)
}


check_triangleUH()


# call function triangleUH
UHOt = triangleUH(tt=10,tp=2)

# make barplot
barplot(UHOt)



        


####################
# CALIBRATION PERIOD
####################

# read data: hourly discharge, precipitation, evapotranspiration 
# and groundwater data from the Hupsel Brook catchment
data = read.table("data/QPEG_Hupsel_hour_2002_2003.txt", header=TRUE)

# define start and end of the event 
# example events: 
#  4 Feb 2002 -  9 Feb 2002    
# 19 Feb 2002 - 22 Feb 2002
# 22 Dec 2002 - 24 Dec 2002
# 29 Dec 2002 -  2 Jan 2003
#  2 Feb 2003 -  7 Feb 2003    
    
    
# for hourly data: format: yyyymmddhh
start = 2002020400
end   = 2002020900

P_event    = data$P   [data$date >= start & data$date < end]
Q_event    = data$Q   [data$date >= start & data$date < end]

# this means: select those elements from the vector "Q" 
# for which the date is greater than or equal to the starting date
# and the date is smaller than or equal to the end date
# (so when date is in between start and end)
# and call this shorter vector "Q_event"

# make a graph to see what the hyeteograph and hydrograph look like
plot( P_event, col="green", type="h")
lines(Q_event, col="dodgerblue")





#####################
# BASEFLOW SEPARATION
#####################
    
# assume that the baseflow is constant and that it is the minimum 
# discharge over the period
BF = min(Q_event)

# Direct runoff is observed runoff minus baseflow
DR = Q_event - BF

check_DR()

# add direct runoff to the previous graph
lines(DR, col="blue")
legend(c("P","Q","DR"), col=c("green","dodgerblue","blue"), 
       x="topright", bty="n", lty=1)

# compute sums of P and DR for event
Psum   = sum(P_event)
DRsum  = sum(DR)

# runoff ratio
RR = DRsum / Psum





#########################
# EFFECTIVE PRECIPITATION
#########################

# correct for losses
# Assume a constant fraction of P is lost (runoff coefficient method),
# so the sum of P_eff equals the sum of direct runoff.
P_eff = P_event * RR

check_P_eff()


# plot P and P_eff
plot(P_event, col="green" , type="h")
points(P_eff, col="purple", type="h")
legend(c("P","P eff"), col=c("green","purple"), 
       x="topright", bty="n", lty=1)

    

    

##############
# OPTIMIZATION
##############

# call functions triangleUH and conv
# best fit (highest Nash-Sutcliffe) for 4-9 Feb 2002: tt = 87 h, tp = 11 h
UHOt   = triangleUH(tt=87, tp=11)
DR_mod = conv(P=P_eff, UHO=UHOt) 

# plot P and observed and modeled direct runoff.  
plot(P_eff  , col="green", type="h")
lines(DR    , col="blue")
lines(DR_mod, col="red" )  
legend(c("P eff","DR obs","DR mod"), col=c("green","blue","red"), 
       x="topright", bty="n", lty=1)





##################
# GOODNESS OF FIT
##################

# Nash-Sutcliffe
NS = 1-sum((DR-DR_mod)^2) / sum((DR-mean(DR))^2)    




############
# VALIDATION
############

# Scroll up to select another period, subtract baseflow, 
# compute effective precipitation, run the model
# and compute the Nash-Sutcliffe efficiency.
# Validation period used: 29 Dec 2002 - 2 Jan 2003
# (start = 2002122900, end = 2003010200), NS = 0.29.





################################
################################
# TOP-DOWN APPROACH: THE J-MODEL 
################################
################################

# the jvalue function computes the reservoir coefficient j
jvalue = function(mu, L, k, D)
{
  # Compute the j value. Take care that the units are correct.
  # The inputs of the function are in d and m/d, 
  # but the j value that this function returns should have 
  # the unit h because you use hourly rainfall data.
  # Kraijenhoff van de Leur: j = mu * L^2 / (pi^2 * k * D)  [d]
  # multiplied by 24 to convert days to hours.
  j = mu * L^2 / (pi^2 * k * D) * 24
  return(j)
}


check_jvalue()


# the jmodel function makes a unit hydrograph with:
jmodel = function(j)
{
  # make a vector t from 1 to 1000 for 1000 time steps of one hour
  t = seq(1,1000)
  # compute the unit hydrograph ordinates from the time t
  # first term of the Fourier series: u = 8/pi^2 * 1/j * exp(-t/j)
  u = 8 / pi^2 * 1/j * exp(-t/j)
  # Below: a small trick to make sure the sum of the unit hydrograph 
  # ordinates is 1. (Rounding off sometimes causes the unit hydrograph 
  # to be less, which is of course not supposed to happen since all 
  # effective rainfall should become direct runoff).  
  u = u / sum(u)
  
  return(u)
}

check_jmodel()



# call function jvalue to compute the j value from field observations
# L = A / (2 * ll) = 6.5e6 m2 / (2 * 15000 m) = 217 m;
# mu, k and D are the middle of the ranges given in the assignment.
# Smallest j: jvalue(mu=0.05, L=217, k=5, D=8) = 143 h
# Largest j:  jvalue(mu=0.1 , L=217, k=1, D=1) = 11451 h
j_obs = jvalue(mu=0.075, L=217, k=3, D=4)   # 716 h

# call function jmodel with j value based on observations
UHOj_obs = jmodel(j=j_obs)

# make barplot of the ordinates
# (there are 1000 bars for all 1000 ordinates, resulting in a black figure)
barplot(UHOj_obs)





############
# VALIDATION
############
    
# compute direct runoff    
DR_mod = conv(P=P_eff, UHO=UHOj_obs)
    
# plot P and observed and modeled direct runoff. 
plot(P_eff        , col="green", type="h")
lines(DR          , col="blue")
lines(DR_mod, col="red" )  
legend(c("P eff","DR obs","DR mod"), col=c("green","blue","red"), 
       x="topright", bty="n", lty=1)
    





#############
# CALIBRATION
#############

# fitting the best values    
# best fit (highest Nash-Sutcliffe) for 4-9 Feb 2002: j = 40 h
UHOj_cal = jmodel(j=40)
DR_mod = conv(P=P_eff, UHO=UHOj_cal)
    
# plot P and observed and modeled direct runoff.   
plot(P_eff        , col="green", type="h", 
     main="P_eff (green), DR_obs (blue), DR_mod (red)")
lines(DR          , col="blue")
lines(DR_mod      , col="red" )
legend(c("P eff","DR obs","DR mod"), col=c("green","blue","red"), 
       x="topright", bty="n", lty=1)


# Scroll up to select another period, subtract baseflow, 
# compute effective precipitation, run the model
# and compute the Nash-Sutcliffe efficiency.




