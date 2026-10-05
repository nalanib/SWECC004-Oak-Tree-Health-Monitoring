


hint_UHO_example_1 = function(){
  writeLines("The unit hydrograph ordinates specify how 1 mm of rain 
is divided over the next hours as discharge.")
}


hint_UHO_example_2 = function(){
  writeLines("Make a vector which consists of 3 numbers.")
}


check_UHO_example= function(){
  if(length(UHO_example)==3 & UHO_example[1]==0.3 & sum(UHO_example)==1){
    print("That's it!")
  }else{
    print("That vector doesn't contain the right numbers yet.")  
    }
}


hint_P_example_1 = function(){
  writeLines("The rainfall time series specifies how many mm of rain fell each hour.")
}


hint_P_example_2 = function(){
  writeLines("Make a vector which consists of 6 numbers.")
}


check_P_example= function(){
  if(P_example[1]==10 & sum(P_example)==21){
    if(length(P_example)==6){
        print("That's it!")
    }else{
        writeLines("Expand your vector with two zeroes, 
so you will be able to see the whole discharge hydroghraph later.")
    }
  }else{
    print("That vector doesn't contain the right numbers yet.")  
  }
}



check_triangleUH = function(){
  UHcheck = triangleUH(tt=10,tp=2)
  if(sum(UHcheck) != 1){
    print("Something went wrong. The ordinates don't add up to 1.")
  }else{
    if(length(UHcheck) != 10){
      print("Something went wrong. The vector with ordinates is not as long as tt.")
    }else{
      if(which(UHcheck == max(UHcheck)) != 2){
        print("Something went wrong. The maximum is not at tp hours.")
      }else{
        print("That looks right!") 
      }
    }
  }
}
  
  

check_DR = function(){
  if(length(DR) < 24){
    print("Your vector is quite short. Did you use the whole discharge time series?")
  }else{
    if(length(DR) != length(Q_event)){
      print("The time series of direct runoff should have the same length as the time series of the discharge.")
    }else{
      if(sum(DR) >= sum(Q_event)){
        print("The direct runoff equals or exceeds the discharge, which is not possible.")
      }else{
        print("That seems to be the right form and numbers!")
      }
    }
  }
}




check_P_eff = function(){
  if(length(P_eff) < 24){
    print("Your vector is quite short. Did you use the whole rainfall time series?")
  }else{
    if(length(P_eff) != length(P_event)){
      print("The time series of effective rainfall should have the same length as the time series of the rainfall.")
    }else{
      if(sum(P_eff) >= sum(P_event)){
        print("The effective rainfall equals or exceeds the rainfall, which is not possible.")
      }else{
        if(min(P_eff) < 0){
          print("The effective rainfall has negative values, which is not possible.")
        }else{
          print("That seems to be the right form and numbers!")
        }
      }
    }
  }
}




check_jvalue = function(){
  jcheck = jvalue(mu=0.1, L=200, k=1, D=1)
  if(jcheck > 10000){
    print("Something went wrong. The j value is too large.")
  }else{
    if(jcheck < 9000){
      print("Something went wrong. The j value is too small. Did you check the units?")
    }else{
      print("That looks about right!") 
    }
  }
}


check_jmodel = function(){
  jcheck = jmodel(j=10000)
  if(round(sum(jcheck), digits=7) != 1){
    print("Something went wrong. The ordinates don't add up to 1.")
  }else{
    if(jcheck[1] < 0.0009){
      print("Something went wrong. The ordinate values are too small.")
    }else{
      if(jcheck[1] > 0.0011){
        print("Something went wrong. The ordinate values are too large.")
      }else{
        if(jcheck[10] - jcheck[1] > 0){
          print("The ordinates increase in time. Did you perhaps forget the minus sign in the exponent?") 
        }else{
          print("Looks good!") 
        }
      }
    }
  }
}















