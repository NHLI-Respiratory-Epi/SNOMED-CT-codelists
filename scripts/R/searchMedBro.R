# This is the function to do the searching for all the elements named in the list:

searchMedBro <- function(medbro, searchlist, searchin = c("Term")) {
  
  # This will automatically search through the Term column. If you are searching through different columns,
  # or you've renamed the column names from the original ones read into R, then you need to change the column names by providing a 
  # vector to 'searchin'
  
  # This part of the code names the list if it is an unnamed  vector. The output have a column named 'allterms' if an unnamed vector is provided
  if (typeof(searchlist) != "list") {
    searchlist <- list(allterms = searchlist) 
  }
  
  # then, for each of the search terms in 'searchlist', search through the 'searchin' columns for a match.
  # slightly different process required for if there is 1 or greater than 1 'searchin' element
  
  for (i in names(searchlist)) {
    
    # first element in 'searchin'
    tempdat <- data.frame(V1 = grepl(paste0(searchlist[[i]], collapse = "|"), medbro[[searchin[1]]], ignore.case = TRUE))
    colnames(tempdat) <- searchin[1]
    
    # for greater than 1 element in 'searchin'
    if (length(searchin) > 1) {
      
      for (j in searchin[2:length(searchin)]) {
        
        #  tempdat[[j]] <- grepl(paste0(searchlist[[i]], collapse = "|"), medbro[[searchin[j]]], ignore.case = TRUE)
        tempdat[[j]] <- grepl(paste0(searchlist[[i]], collapse = "|"), medbro[[j]], ignore.case = TRUE)
        
      }
    }
    
    # greater than 1 element in 'searchin', use rowSums  
    if (length(searchin) > 1) {
      
      medbro[[i]] <- rowSums(tempdat[ , 1:length(searchin)])
      medbro[[i]][medbro[[i]] > 1] <- 1
      
    } else {
      
      # 1 element in 'searchin', just convert colum to numeric (from logical) 
      medbro[[i]] <- as.numeric(tempdat[ , 1])
    }
    
    tempdat <- NULL
    
  }
  
  
  # then, if chapter starts is specified:
  
    print("Newly added columns: ")
    print(names(searchlist))
  
  return(medbro)
}
