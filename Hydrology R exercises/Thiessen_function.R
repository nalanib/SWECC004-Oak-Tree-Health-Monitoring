# Script made by Olda Rakovec and Claudia Brauer
# Hydrology and Quantitative Water Management Group,
# Wageningen University, The Netherlands


#########################################################
# COMPUTE RAINFALL PER PIXEL PER TIME STEP WITH THIESSEN
#########################################################

# The aim is to compute the catchment average rainfall 
# with the Thiessen method. 

# You do NOT have to change anything in the function.
# Run the function once including all the brackets,
# so R has it in its memory (see the workspace window)
# or use "source("Thiessen_function.R")" to run the whole script at once. 
# Later, in the main script, you can call the function with different arguments.

thiessen = function(date_select)
{  
  
  # Extract rainfall from this time step at all raingauges
  P_select  = t(P[date==date_select,])

  # Combine coordinates and rainfall in one matrix
  xyz      = cbind(x=Gauges$X, y=Gauges$Y, z=P_select)
  
  # Use Nearest neighbour interpolation
  P_map_th = interpNear(mask, xyz, radius=100000)
  
  # Compute the location of the polygons
  areas_th = voronoi(vect(data.frame(xyz), geom=c("x", "y")))
  
  # Cut off the pixels outside the catchment
  P_map_th_inside_catchment = P_map_th * mask
  
  # Compute the mean of al points within the catchment.
  # This is the catchment average precipitation. 
  P_av_th = mean(as.matrix(P_map_th_inside_catchment, wide=T), na.rm=TRUE)
  
  
  # MAKE FIGURE  
  
  # Define color scale for figure
  colors=c(colorRampPalette(c("white","dodgerblue","blue","darkblue"))(10),
           colorRampPalette(c("darkblue","red"))(30))
  
  # Plot Thiessen polygons
  plot(P_map_th, col=colors, range=c(0,40))
  lines(areas_th)
  
  # Add location and name of rain gauges
  points(Gauges$X, Gauges$Y, pch = "+", cex = 0.5)  
  text(x=Gauges$X, y=Gauges$Y+3000, labels=Gauges_names,cex=0.5)
  
  # Add catchment boundary
  plot(boundary, add=TRUE, lwd=2)
  
  # Add text with the date
  text(x=720000,y=5530000,labels=date_select)
  
  # Add legend with colors
  legend(as.character(c(seq(0,10,2),seq(20,40,10))), 
         col=colors[c(1,seq(2,10,2),seq(20,40,10))], 
         pch=15,x="topleft", bty="n")
  
  # Print catchment average rainfall in the Console
  return(P_av_th)
  
} # end of the function

