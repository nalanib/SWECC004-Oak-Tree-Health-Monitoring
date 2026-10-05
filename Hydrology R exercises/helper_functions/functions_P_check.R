
hints_thiessen_function = function(){writeLines(
  "If R says: `Error in h(simpleError(msg, call)) : 
error in evaluating the argument 'x' in selecting a method for function 
't': object 'P' not found':
Scroll up to where you read the data and extracted the P column (lines 34-41).
There should be data called 'P' listed in the Environment Window.
  
If R says: `could not find function 'thiessen'':
Run the line where you loaded the script with the function (line 70) 
There should be a function called 'thiessen listed in the Environment Window.'
  
If R says: `Error: [interpNear] expecting a matrix with three columns':
check if you entered the date in the format: yyyymmddhh")
}


check_yearsum_gauges = function(){
  if(length(yearsum_gauges)>42){
    writeLines("This is not correct, because your vector has too many elements.
You probably summed stations instead of hours.")
  }else{
    if(mean(yearsum_gauges)<1000){
    print("The number of elements in the vector is correct, but your values are too low.")
    }else{
    print("That seems about right!")  
    }
  }
}


check_P_ar = function(){
  if(length(P_ar)==1){
    writeLines("Your vector is only one element long, instead of having a value for each hour.
You probably used the wrong function.")
  }else{
    if(length(P_ar)<8000){
      writeLines("This is not correct, because your vector has too few elements.
Maybe you averaged over hours instead of over stations?")
    }else{
      if(sum(P_ar)>1300){
        print("The number of elements in the vector is correct, but your values are too high.")
      }else{
        print("That seems to be correct!")  
      }
    }
  }
}


check_P_one = function(){
  if(length(P_one)==1){
    writeLines("Your vector is only one element long, instead of having a value for each hour.
You probably used the wrong function.")
  }else{
    if(length(P_one)<8000){
      writeLines("This is not correct, because your vector has too few elements.
Maybe you averaged over hours instead of over stations?")
    }else{
      if(sum(P_one)>1700){
        print("The number of elements in the vector is correct, but your values are too high.")
      }else{
        print("That looks right!")  
      }
    }
  }
}