

check_ETact_year = function(){
  if(anyNA(ETact_year)==T){
    writeLines("ETact has missing values, which should not be the case.
Check in the Workspace Window if P_year and Q_year have any missing values
and fix the code in the for-loop if there are.")
  }else{
    if(mean(ETact_year) > 300 & mean(ETact_year) < 400){
      writeLines("That looks good!")
    }else{
      writeLines("The values seem off.")
    }
  }
}

hint_Budyko_curve_1 = function(){
  writeLines("Use the vectors P_year, ETpot_year and ETact_year.
Look up in the lecture notes what should be on the x-axis and what on the y-axis.
The vectors needed for the x-axis should be entered before the comma
and the vectors needed for the y-axis should be entered after the comma.")
}

hint_Budyko_curve_2 = function(){
  writeLines("You should have ETpot/P on the x-axis and ETact/P on the y-axis.")
}

hint_Budyko_curve_3 = function(){
  writeLines("Type:
plot(ETpot_year/P_year, ETact_year/P_year, xlim=c(0,3), ylim=c(0,1.1))")
}

hint_Zhang_curve_1 = function(){
  writeLines("Don't type 'ETpot/P' in the expression for the curve,
because R doesn't know that that is what the x axis means.
Type 'x' instead of 'ETpot/P'.")
}


hint_Zhang_curve_2 = function(){
  writeLines("Don't use too many brackets to keep the overview. 
All programming languages use this order of execution of commands:
1. powers and logarithms
2. multiplications and divisions
3. additions and subtractions.
So you only need to add brackets if you want to e.g. subtract before multiplying.")
}

hint_Zhang_curve_3 = function(){
  writeLines("Type:
curve(1+x-(1+x^w)^(1/w), add=TRUE, col='green', lty=3")
}


check_matrix_size = function(){
  if(nrow(P_m)==12 & ncol(P_m)==8){
    print("That is the right size!")
  }else{
    print("That is not the right size yet.")
  }
}






