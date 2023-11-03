# read in appropriate libraries

library(tidyverse) # a package for tidy working in R
library(openxlsx2) # for writing excel files


# for the R equivalent of 'log', you can go to file -> compile -> pdf document. 
# for this to wowrk you need to have rmarkdown and LaTeX installed. 


# Set working directory for where the files you need are saved

setwd("Z:/Group_work/Alex/Georgie's code translation/Inputs/")




# Enter directory to save files in

savedir <- "Z:/Group_work/Alex/Georgie's code translation/Outputs/"



filename <- "smoking_status"

#capture log close
#log using `filename', text replace




# Import latest product browser 
# read in 'prodcode' and 'dmdcode' to be string variable, or will lose data

medbro <- read.delim("Z:/Database guidelines and info/CPRD/CPRD_CodeBrowser_202105_Aurum/202105_EMISMedicalDictionary.txt",
                     colClasses = "character")


# in later versions Can convert Observations back to integer
#medbro$Observations <- as.integer(medbro$Observations)






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


# // STEP 1. IDENTIFY SEARCH TERMS
# //===============================

smoking_list <- c("smok", "cigar", "tobac")


# // STEP 2. SEARCH THE MEDICAL TERMINOLOGY DICTIONARY USING THE SEARCH TERMS
# //==========================================================================


medbro <- searchMedBro(medbro, smoking_list)

table(medbro$allterms)

medbro <- medbro %>% rename(smokingstatus = allterms)

medbro <- medbro %>% filter(smokingstatus == 1)

# // (OPTIONAL) STEP 3. PERFORM A SECONDARY SEARCH TO EXCLUDE BROAD UNDESIRED TERMS
# //================================================================================

# Note that instead of *, you need to use .*

misc_list <- c("accident", "allergen", "asthma", "burn", "diesel", "leaf.*specific", "lighter",
               "virus.*group", "waste.*management", "wheeze", "socio-economic", "assist-lite")

animal_list <- c("cheese", "cockroach", "fish", "frog", "haddock", "mackerel", "rabbit", "salmon", "smoked.*cod", 
                 "smoky.*gilled.*woodlover", "smoky.*madtom", "trout")

bacteria_list <- c("bacill", "bacter")

fire_list <- c("conflagration", "fire", "smoke.*alarm", "smoke.*inhalation")

garments_list <- c("garment", "sigvaris")

occupation_list <- c("blender", "grader", "industry", "maker", "operator", "preparer", "processor", "stripper", 
                     "tobacconist")

exclude_list <- list(misc = misc_list, animal = animal_list, bacteria = bacteria_list, fire = fire_list,
                     garments = garments_list, occupation = occupation_list)

medbro <- searchMedBro(medbro, exclude_list)

table(medbro$bacteria)

# look at what you're going to exclude
medbro %>% filter(misc == 1 | animal == 1 | bacteria == 1 | fire == 1 | garments == 1 | occupation == 1) %>%
  arrange(misc, animal, bacteria, fire, garments, occupation) %>% 
  select(misc, animal, bacteria, fire, garments, occupation, Term)

medbro <- medbro %>% filter(misc == 0 & animal == 0 & bacteria == 0 & fire == 0 & garments == 0 & occupation == 0) 
medbro <- medbro %>% select(-(misc:occupation)) 
summary(medbro)
table(medbro$drugs)

# STEP 4. MANUAL SCREEN OF CODELIST TO REMOVE UNDESIRED TERMS
# =============================================================
  
initial_remove <- c("1834611000006117", "8285811000006114", "4153251000006115", "8285791000006110", "9211501000006113",
                    "8285721000006113", "6542461000006112", "2703821000006119", "8285781000006112", "5172291000006114",
                    "11930621000006114", "1865641000006112", "8285801000006111", "1856551000006114", "2866001000006114")

# change searchin to 'medcodeid'
medbro <- searchMedBro(medbro, initial_remove, searchin = "MedCodeId")

medbro %>% filter(allterms == 1) %>% select(Term)

medbro <- medbro %>% filter(allterms != 1) %>% select(-allterms)

# // STEP 5. USE THE SNOMED CT CONCEPT ID TO FIND ADDITIONAL SYNONYMOUS TERMS
# //==========================================================================

medbro_extra <- read.delim("Z:/Database guidelines and info/CPRD/CPRD_CodeBrowser_202105_Aurum/202105_EMISMedicalDictionary.txt",
                           colClasses = "character")


medbro_extra <- medbro_extra %>% filter(SnomedCTConceptId %in% medbro$SnomedCTConceptId)

# 34 more terms

medbro_extra <- medbro_extra %>% filter(!(MedCodeId %in% medbro$MedCodeId))

# look at the terms

medbro_extra$Term


# keep which ever ones you like, and then add the rest back in.

length(unique(medbro$SnomedCTConceptId))

medbro %>% group_by(SnomedCTConceptId) %>% add_tally() %>% ungroup() %>% select(n) %>% table()

medbro %>% group_by(SnomedCTConceptId) %>% add_tally() %>% filter(n > 1) %>% arrange(SnomedCTConceptId) %>% 
  select(SnomedCTConceptId, misc:occupation) %>% slice(1) %>% nrow()

# 82 snomedCTconceptIDs with more than 1 associated medcode. have these all been classified the same way?

medbro %>% group_by(SnomedCTConceptId) %>% add_tally() %>% filter(n > 1) %>% arrange(SnomedCTConceptId) %>% 
  select(SnomedCTConceptId, misc:occupation) %>% unique() %>% nrow()

# yes!

# Therefore we can use the classification for the concept and apply it to the newly found ones

medbro_extra <- left_join(medbro_extra, unique(select(medbro, SnomedCTConceptId, smokingstatus:occupation)), by = "SnomedCTConceptId")


ncol(medbro)
ncol(medbro_extra)

medbro_extra

colnames(medbro)
colnames(medbro_extra)

# and now just add it to the bottom of the data

medbro <- bind_rows(medbro, medbro_extra)

# // (OPTIONAL) STEP 6. USE ANOTHER SEARCH TO AUTOMATE THE CATEGORISATION OF CODES
# //===============================================================================
  
#  //Comment out this section if not required.

# //**Search terms for each categorisation desired**
  
current_list <- c("current", "smokes", "smoker", "smoking", "refer", "cessation", "stop.*smoking", "cigarette", "tobacco", "assessment", "advice", "trying", "restart", "increase", "education", "poisoning", "nicotine")

ex_list <- c("ex ", "ex-", "past.*smoker", "abstinent", "current.*non-", "current.*non ", "stopped", "age.*cessation", "ceased", "carbon.*monoxide.*non", "smoked", "withdrawal", "smoker.*before", "history.*of.*smok")

never_list <- c("never", "non.*smok", "does.*not")

smokeless_tobacco_list <- c("snuff", "chew", "moist", "powdered", "smokeless")

unknown_list <- c("refusal.*to", "declined.*to", "smoking.*status", "pack.*years", "^age", " age",  "weeks", "amount", "habits", "time.*since", "consumption", "total", "tobacco.*use", "smoking.*behaviour")

passive_list <- c("passive", "second.*hand", "household", "parent", "carer", "mother", "father", "family", "in.*public", "expos.*smoke", "smoke.*exposure", "smokefree.*home", "smoker.*home", "involuntary", "secondary.*exposure", "child.*exam")

vape_list <- c("vape", "electronic", "^e-", " e-")

drugs_list <- c("heroin", "cannabis", "methadone", "diamorphine", "impregnate", "dragon", "smokes.*drugs")

vague_follow_up_list <- c("follow*up", "f/u", "monitor")

classification_list <- list(current = current_list, ex = ex_list, never = never_list, smokeless_tobacco = smokeless_tobacco_list,
                            unknown = unknown_list, passive = passive_list, vape = vape_list, drugs = drugs_list,
                            vague_follow_up = vague_follow_up_list)


nrow(medbro)


medbro <- searchMedBro(medbro, classification_list)

table(medbro$current, medbro$ex)

medbro %>% mutate(multiple = current + ex + never) %>% filter(multiple > 1)

# some are flagged for multiple variables. mostly need to be recoded from current to other, which is why it's done this way:

medbro$smoking_status <- NA
medbro$smoking_status[medbro$current == 1] <- "Current smoker"
medbro$smoking_status[medbro$never == 1] <- "Never smoker"
medbro$smoking_status[medbro$ex == 1] <- "Ex-smoker"
medbro$smoking_status[medbro$unknown == 1 | medbro$drugs == 1 | medbro$passive == 1 | 
                        medbro$vape == 1 | medbro$smokeless_tobacco == 1] <- NA

# Need to make a few changes (using conceptIDs:

# nevers
medbro$smoking_status[medbro$SnomedCTConceptId %in% c("266919005", "221000119102")] <- "Never smoker"

# exs

exs <- c("160618006", "395177003", "8517006", "1221000119103", "1092511000000105", "904221000006106", "1626121000006100", 
         "1873511000006102", "904091000006100", "191889006", "191889006", "201931000000109", "710081004", "37311000006101", 
         "904201000006101", "201941000000100", "440012000", "85931000119105", "852121000006105", "909391000006101", "713700008", 
         "1974571000006100", "1221000175102", "137761000006105", "228486009", "1092031000000108", "266928006", "384742004")

medbro$smoking_status[medbro$SnomedCTConceptId %in% exs] <- "Ex-smoker"

# current

current <- c("10761391000119102", "266918002", "228487000", "230057008", "1974421000006100", "230058003", "857871000000107", 
             "89765005", "413173009", "470041000000100", "191887008", "470041000000100", "266927001", "724697004", "160613002", 
             "1421000175103", "697956009", "722497008", "314538009", "30483005", "57264008", "711028002", "365982000", "110483000",
             "230056004", "405140009", "143461000000103", "1110971000000101")

medbro$smoking_status[medbro$SnomedCTConceptId %in% current] <- "Current smoker"

table(medbro$smoking_status)

# vague smoking statuses.

medbro$smoking_status[medbro$vague_follow_up == 1] <- NA

# Vague smoking status
vague <- c("365980008", "365981007", "108333003", "904051000006106", "904211000006103", "171209009", 
           "102408007", "717761000000101", "716391000000109", "999000891000000102", "229819007", 
           "1833971000006100", "16581000006107", "408398007", "720201000000102", "102407002",
           "717771000000108", "390900001", "698289004", "904191000006104", "714021000000104",
           "751661000000106", "1431000175100", "852131000006108", "228487000", "1873511000006102",
           "374361000000100", "750851000000104")

medbro$smoking_status[medbro$SnomedCTConceptId %in% vague] <- NA

# Remove from list completely
remove <- c("83086008", "421693007", "75856009", "37921004", "27743007", "45349003", "465409000", "82958007", "30795006", "855801000006100")

medbro <- medbro %>% filter(!(SnomedCTConceptId %in% remove))

# Passive smoking - Unexposed & codes to remove

medbro$passive[!is.na(medbro$smoking_status) | medbro$passive == 0] <- NA
table(medbro$passive)
unexposed <- c("1899561000006105", "1899581000006100", "438618001", "1911921000006104", "1888821000006108", "394885002", "315213009", "448755007", "394964001", "711563001", "443847005")

medbro$passive[medbro$SnomedCTConceptId %in% unexposed] <- 0

passive_remove <- c("1104251000000106", "1899541000006106", "1033041000000104", "1934421000006103")

medbro <- medbro %>% filter(!(SnomedCTConceptId %in% passive_remove))

medbro$passive[medbro$passive == 0] <- "Unexposed"
medbro$passive[medbro$passive == 1] <- "Exposed"
table(medbro$vape)
# Vaping - Current & Ex

medbro %>% select(smoking_status, vape) %>% table()

medbro$vape[!is.na(medbro$smoking_status) | medbro$vape == 0] <- NA

ex_vape <- "908781000000104"

table(medbro$vape)

medbro$vape[medbro$SnomedCTConceptId == ex_vape] <- 0

medbro$vape[medbro$vape == 0] <- "Ex-vaper"
medbro$vape[medbro$vape == 1] <- "Current vaper"

table(medbro$passive)

medbro$smokeless_tobacco[medbro$smokeless_tobacco == 0 | !is.na(medbro$smoking_status)] <- NA
medbro$smokeless_tobacco[medbro$smokeless_tobacco == 1] <- "Current smokeless tobacco"

ex_smokeless <- c("228506009", "228520002", "228503001", "228513009", "1599721000006109", "735112005")
never_smokeless <- c("228502006", "228512004", "228511006", "228501004")
remove_smokeless <- c("228499007", "363906001", "228509002", "363907005")

medbro$smokeless_tobacco[medbro$SnomedCTConceptId %in% ex_smokeless] <- "Ex smokeless tobacco"
medbro$smokeless_tobacco[medbro$SnomedCTConceptId %in% never_smokeless] <- "Never smokeless tobacco"

medbro <- medbro %>% filter(!(SnomedCTConceptId %in% remove_smokeless))

final_remove <- c("108333003", "836001000000109", "1809121000006109", "427189007", "169940006", "698289004", "12465801000001106", "720201000000102", "1538681000006102")

medbro <- medbro %>% filter(!(SnomedCTConceptId %in% final_remove))

nrow(medbro)

medbro$drugs[medbro$drugs == 0] <- NA

# //Tidy up and generate variables for all desired categories

medbro <- medbro %>% select(-current, -ex, -never, -unknown, -vague_follow_up, -smokingstatus)

medbro$gp_recorded_smoking <- 0
medbro$gp_recorded_smoking[!is.na(medbro$smoking_status) | !is.na(medbro$vape) | !is.na(medbro$drugs) | 
                             !is.na(medbro$smokeless_tobacco) | !is.na(medbro$passive)] <- 1 

medbro$ever_smoker <- NA
medbro$ever_smoker[medbro$smoking_status %in% c("Ex-smoker", "Current smoker")] <- 1
summary(medbro)
table(medbro$smoking_status, medbro$ever_smoke, useNA = "ifany")




# save what you're made. In R, this is commonly saved used an RDS file.

saveRDS(medbro, paste0(savedir, filename, ".RDS"))

openxlsx2::write_xlsx(medbro, file = paste0(savedir, filename, ".xlsx")) #, sheetName = "Sheet1", 
#           col.names = TRUE, row.names = FALSE, append = FALSE)

write.csv(medbro, file = paste0(savedir, filename, ".csv"), row.names = FALSE)



tagfile <- file(paste0(savedir, filename, ".tag"))

writeLines(paste(
  
  # = Update details here, everything else is automated ==========================
  "Smoking status", # description
  "AA", # author
  "August 2022", # date
  "SNOMED CT", # code_type
  "CPRD Aurum", # database
  "May 2021", # database_version
  "smoking status, tobacco smoking, drug smoking, passive smoking, vaping, smokeless tobacco, GP recording of smoking, ever smoker", # keywords
  "Provides variables for smoking status (current/ex/never), drug smoking, passive smoking (exposed/unexposed), vaping (current/ex), smokless tobacco (current/ex/never), GP record of smoking (not useful for determining smoking status but may be useful for assessing GP performance), and ever smoker (patients labelled as current or ex)", # notes
  "August 2022", # date clinician_approved
  # ==============================================================================
  sep = "\n"), tagfile)

close(tagfile)

