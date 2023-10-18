###############################################################################
# CPRD Product Code Browser Searching
# 23/09/2020	ELA #    Updated by PWS on 2022-06-22  #  Updated by ELG for Product Browsing 2022-04-11
# 2 Dec 2022
# Emily Graul
# Codelist: BNF, 0205 HTN and Heart Failure RX
# 
###############################################################################/
  
# STEPS
# 1) Define drug class(es) of interest and collate list of terms
# 2) Searching CPRD Aurum Product Browser
# 3) Remove any irrelevant codes / exclusions
#    Nothing equivalent to merging and comparing with SNOMED concept IDs
# 4) Cleaning, resort, tag
# 5) Compare with previous list(s) if applicable / mapping to NHSBSA
#    Final order, export for clinician review, tag file
# 6) Send raw codelist for clinician review - for study-specific codelist
# 7) Keep 'master' codelist with all versions & tags
#
  
  # NB You shouldn't need to change any code within loops, apart from local-macro names, e.g., searchterm, exclude_route, exclude_term, etc.

###############################################################################
#1) Define drug class(es) of interest - collate list of terms for value sets
	 #(refer to Appendix __ spreadsheet)

###############################################################################/

###############################################################################
#2) Searching CPRD Aurum Product Browser
###############################################################################/


# read in appropraite libraries

library(tidyverse) # a package for tidy working in R
library(openxlsx2) # for writing excel files


# this is the function I've made:

source("H:/GitHub/CPRD_R_code/searchProdBro.R")




# for the R equivalent of 'log', you can go to file -> compile -> pdf document. 
# for this to wowrk you need to have rmarkdown and LaTeX installed. 


# Set working directory for where the files you need are saved

setwd("Z:/Group_work/Alex/Emily's product browsing/Inputs/")




# Enter directory to save files in

savedir <- "Z:/Group_work/Alex/Emily's product browsing/Outputs/"



filename <- "COPDrx_inhalers_checked"

#capture log close
#log using `filename', text replace



# Import latest product browser 
# read in 'prodcode' and 'dmdcode' to be string variable, or will lose data

prodbro <- read.delim("Z:/Database guidelines and info/CPRD/CPRD_CodeBrowser_202202_Aurum/CPRDAurumProduct.txt", colClasses = "character")

# Can convert DrugIssues back to integer

prodbro$DrugIssues <- as.integer(prodbro$DrugIssues)

glimpse(prodbro)


# no lookupfile required (unlike medical code browsing)



######
  #  2a. Chemical + proprietary name searchterms
######
  #Insert your search terms into each local as shown below, change local names according to chemical name, then group chemical macros into bnfsubsection macro

# "trimbow" (Beclometasone dipropionate/ Formoterol fumarate dihydrate/ Glycopyrronium bromide) is a combo, 
# listed in 3.1.1 single in Open Prescribing, but moved to triple macro for purposes of repository

# Compound bronchodilators by type
# LAMA
aclidinium_list <- c("aclidinium", "eklira")
glycopyrronium_list <- c("glycopyrronium", "seebri")
tiotropium_list <- c("tiotropium", "acopair", "braltus", "spiriva", "tiogiva")
umeclidinium_list <- c("umeclidinium", "incruse")

lama_030102 <- c(aclidinium_list, glycopyrronium_list, tiotropium_list, umeclidinium_list)

# LABA
formoterol_list <- c("formoterol", "atimos", "foradil", "oxis")
indacaterol_list <- c("indacaterol", "onbrez")
olodaterol_list <- c("olodaterol", "striverdi")
salmeterol_list <- c("salmeterol", "neovent", "serevent", "soltel", "vertine")

laba_030101 <- c(formoterol_list, indacaterol_list, olodaterol_list, salmeterol_list)

# SABA
salbutamol_list <- c("salbutamol", "aerolin", "airomir", "airsalb", "asmasal", "asmavent", "maxivent", "pulvinal salbutamol", "salamol", "salapin", 
                     "salbulin", "ventmax", "ventodisks", "ventolin", "volmax", "aerocrom")
fenoterol_list <- c("fenoterol", "berotec")
terbutaline_list <- c("terbutaline", "bricanyl", "monovent")

saba_030101 <- c(salbutamol_list, terbutaline_list, fenoterol_list)

# SAMA
ipratropium_list <- c("ipratropium", "atrovent", "inhalvent", "respontin", "tropiovent")

sama_030102 <- ipratropium_list

# ICS
beclometasone_list <- c("beclometasone", "aerobec", "asmabec", "beclazone", "becloforte", "becodisks", "becotide", "clenil", "filair", 
                        "kelhale", "pulvinal beclometasone", "qvar", "soprobec")
budesonide_list <- c("budesonide", "budelin", "pulmicort")
ciclesonide_list <- c("ciclesonide", "alvesco")
fluticasone_list <- c("fluticasone", "campona", "flixotide", "seffalair")
mometasone_list <- c("mometasone", "asmanex")

ics_0302 <- c(beclometasone_list, budesonide_list, ciclesonide_list, fluticasone_list, mometasone_list)

# Combos
# 3.1.4 Compound bronchodilators x type
# may be mutually exclusive w/above - sort later

# laba-lama
aclidinium_formoterol_list <- c("duaklir")
glycopyrronium_formoterol_list <- c("bevespi")
glycopyrronium_indacaterol_list <- c("ultibro")
tiotropium_olodaterol_list <- c("spiolto")
umeclidinium_vilanterol_list <- c("anoro")

labalama_30104 <- c(aclidinium_formoterol_list, glycopyrronium_formoterol_list, glycopyrronium_indacaterol_list, tiotropium_olodaterol_list, umeclidinium_vilanterol_list)

# saba-sama
salbutamol_ipratropium_list <- c("ipramol", "combiprasal")
fenoterol_ipratropium_list <- c("duovent")
sabasama_30104 <- c(salbutamol_ipratropium_list, fenoterol_ipratropium_list)

# laba-ics
beclometasone_formoterol_list <- c("fostair", "luforbec")
budesonide_formoterol_list <- c("duoresp", "fobumix", "symbicort", "wockair")
mometasone_indacaterol_list <- c("atectura")
fluticasone_salmetrol_list <- c("aerivio", "airFluSal", "aloflute", "avenor", "combisal", "fusacomb", "fixkoh", "Sereflo", "seretide", "sirdupla", "stalpex")
fluticasone_vilanterol_list <- c("relvar")
fluticasone_formoterol_list <- c("flutiform")
icslaba_0302 <- c(beclometasone_formoterol_list, budesonide_formoterol_list, mometasone_indacaterol_list, fluticasone_salmetrol_list, 
                  fluticasone_vilanterol_list, fluticasone_formoterol_list)

# triple
beclometasone_triple <- c("trimbow")
budesonide_triple <- c("trixeo")
fluticasone_triple <- c("trelegy")
mometasone_triple <- c("enerzair")
triple_0302 <- c(beclometasone_triple, budesonide_triple, fluticasone_triple, mometasone_triple)


# add all search groups into a named list:

searchlist <- list(
  laba_030101 = laba_030101,
  saba_030101 = saba_030101,
  lama_030102 = lama_030102,
  sama_030102 = sama_030102,
  sabasama_30104 = sabasama_30104,
  labalama_30104 = labalama_30104,
  ics_0302 = ics_0302,
  icslaba_0302 = icslaba_0302,
  triple_0302 = triple_0302
)





# also, create your chapters that you want to search through as well, and put them in a vector:

chapterstarts <- c(301, 302)

# (we will have to remove these later though as there are specific subsections we don't want)




# sum(str_detect(string = prodbro$BNFChapter,  pattern = paste0("/ ", chapterstarts, collapse = "|")))


prodbro <- searchProdBro(prodbro, searchlist, chapterstarts)



# we need to add in additional chapter starts to remove - unfortunately the way I've made the function
# means we need a search list in order to do this.

# first we rename chapterstarts

prodbro <- prodbro %>% dplyr::rename(chapterstartskeep = chapterstarts)

# now we run the function again with the ones we want to get rid of and a dummy searchlist
table(prodbro$chapterstartskeep)

# prodbro %>% filter(chapterstartskeep == 1) %>% select(BNFChapter)

chapterstartsexclude <- c(30103, 30105)


prodbro <- searchProdBro(prodbro, searchlist = NULL, chapterstartsexclude)

prodbro <- prodbro %>% dplyr::rename(chapterstartsexclude = chapterstarts)
nrow(prodbro)

table(prodbro$chapterstartsexclude)

# change the chapterstartskeep variable based on the chapterstartsexclude variable

prodbro$chapterstartskeep[prodbro$chapterstartsexclude == 1] <- 0
prodbro$chapterstartsexclude <- NULL

# now just keep the ones with a hit.


prodbro <- prodbro %>% filter(if_any(laba_030101:chapterstartskeep) == 1)

nrow(prodbro)
# check to see whether there are *additional* BNF codes(proprietary or chemical names) not initially searched on?

colnames(prodbro)
prodbro %>% filter(chapterstartskeep == 1) %>% filter(if_all(laba_030101:triple_0302, ~ . == 0)) %>% 
  dplyr::select(-(laba_030101:triple_0302)) %>% select(DrugSubstanceName) %>% table()

prodbro %>% filter(chapterstartskeep == 1) %>% filter(if_all(laba_030101:triple_0302, ~ . == 0)) %>% 
  dplyr::select(-(laba_030101:triple_0302)) %>% select(Term.from.EMIS) %>% table()


# we don't want any of these that we've found, so we drop them.
nrow(prodbro)
prodbro <- prodbro %>% filter(!(chapterstartskeep == 1 & if_all(laba_030101:triple_0302, ~ . == 0)))

nrow(prodbro)




#############################################################
# 3.) Remove any irrelevant codes
#############################################################



exclude_routes1 <- list(exclude_routes1 =  c("nasal", "oral", "rectal", "intra", "cutaneous", "cream", "ointment", "nebulis", "tablet"))

# this time we're searching through the drug routes and formulation
prodbro <- searchProdBro(prodbro, exclude_routes1, searchin = c("RouteOfAdministration", "Formulation"))
table(prodbro$exclude_routes1)

# so now we get rid of these routes we don't want.
prodbro <- prodbro %>% filter(exclude_routes1 == 0) %>% dplyr::select(-exclude_routes1) 
nrow(prodbro)

# and we do it again for a different group of terms:
exclude_terms2 <- list(exclude_terms2 = c("nebulis", "nebules", "tablets", "nasal", "injection", "ileostomy", "ointment",
                                          "cream", "ventide"))



prodbro <- searchProdBro(prodbro, exclude_terms2, searchin = c("Term.from.EMIS", "DrugSubstanceName"))

prodbro %>% filter(exclude_terms2 == 1) %>% select(Term.from.EMIS, DrugSubstanceName) 

table(prodbro$exclude_terms2)

# so now we get rid of these routes we don't want.
prodbro <- prodbro %>% filter(exclude_terms2 == 0) %>% dplyr::select(-exclude_terms2) 
nrow(prodbro)

#exclude by FORMULATION - N/A

#exclude by BNFCHAPTER - not recommended since very incomplete data


#############################################################
# 4.) Cleaning / resorting
#############################################################


#######
# 4a. flag the codes in multiple BNF subsections / mutually exclusive - that should NOT be + make not mutually exclusive
#######
# this may be more important for chapters with subsections that may have overlap in resulting found terms, if your search is specific/broad enough (e.g., in Ch. 2.2 Diuretics, searching just on "furosemide" would lead to found terms in both 2.2.2 and 2.2.4 and 2.2.8, that should not be )

# vilanterol is a laba only in compounds, not singles - picked up in single search but move to compound macros

prodbro <- searchProdBro(prodbro, searchlist = list(vilanterol = "vilanterol"), searchin = "DrugSubstanceName")

# add in to the compounds and then remove as a single

prodbro$labalama_30104[prodbro$lama_030102 == 1 & prodbro$vilanterol == 1 & prodbro$ics_0302 == 0 & prodbro$triple_0302 == 0] <- 1
prodbro$icslaba_0302[prodbro$lama_030102 == 0 & prodbro$vilanterol == 1 & prodbro$ics_0302 == 1 & prodbro$triple_0302 == 0] <- 1
prodbro$triple_0302[prodbro$lama_030102 == 1 & prodbro$vilanterol == 1 & prodbro$ics_0302 == 1] <- 1
prodbro$lama_030102[prodbro$lama_030102 == 1 & prodbro$vilanterol == 1 & prodbro$ics_0302 == 0 & prodbro$triple_0302 == 0] <- 1


# replace labalama_30104=1 if lama_030102==1 & strmatch(lower(drugsubstancename), "*vilanterol*") & ics_0302==. & triple_0302==.
# replace lama_030102=. if lama_030102==1 & strmatch(lower(drugsubstancename), "*vilanterol*") & ics_0302==. & triple_0302==.
# replace icslaba_0302=1 if ics_0302==1 & strmatch(lower(drugsubstancename), "*vilanterol*") & triple_0302==. & lama_030102 == .

# combinations

prodbro$labalama_30104[prodbro$laba_030101 == 1 & prodbro$lama_030102 == 1 & prodbro$ics_0302 == 0 & prodbro$icslaba_0302 == 0 & prodbro$triple_0302 == 0] <- 1 
prodbro$icslaba_0302[prodbro$laba_030101 == 1 & prodbro$lama_030102 == 0 & prodbro$ics_0302 == 1 & prodbro$triple_0302 == 0] <- 1 
prodbro$triple_0302[prodbro$laba_030101 == 1 & prodbro$lama_030102 == 1 & prodbro$ics_0302 == 1] <- 1 
prodbro$sabasama_30104[prodbro$saba_030101 == 1 & prodbro$sama_030102 == 1] <- 1

# then deal with mutually exclusive individual drugs

prodbro$laba_030101[prodbro$labalama_30104 == 1 | prodbro$icslaba_0302 == 1 | prodbro$triple_0302 == 1] <- 0
prodbro$lama_030102[prodbro$labalama_30104 == 1 | prodbro$triple_0302 == 1] <- 0
prodbro$ics_0302[prodbro$icslaba_0302 == 1 | prodbro$triple_0302 == 1] <- 0
prodbro$saba_030101[prodbro$sabasama_30104 == 1] <- 0
prodbro$sama_030102[prodbro$sabasama_30104 == 1] <- 0

# check that everyone is mutually exclusive


prodbro %>% select(laba_030101:triple_0302) %>% rowSums() %>% table() # everyone's '1' so all good!



summary(prodbro)
#make not mutually exclusive - resort based on missing & complete data on drug substance name
	#N/A

######
# 4b. Flag codes in multiple BNF subsections, that SHOULD be - for clinician & covariate analysis
######

	#flagging 0202 diuretics

also_0303_cromo <- c("cromoglicate")
		
	#flagging 0206 Ca2+ channel blockers


		flagcodes <- list(also_0303_cromo = also_0303_cromo)
		
		prodbro <- searchProdBro(prodbro, searchlist = flagcodes, searchin = c("Term.from.EMIS", "DrugSubstanceName"))
		colnames(prodbro)
		
		
		
# quickly look at what we've got:
		
		for (i in colnames(prodbro)[11:22]) {
		  prodbro %>% select(!!!i) %>% table() %>% print()
		}
		
		
		
######		
# 4c. Combine your searchterms into one BNF sub-subsection, if applicable
######

		# N/A
		
		
#############################################################
# 5.) Compare with previous list(s) if applicable
#############################################################
	#as necessary / if available
	#e.g., codelist from previous CPRD Aurum version


	
#############################################################
#Final order, export for clinician review, generate study-specific codelist, tag file

# 6) Send raw codelist for clinician review - for study-specific codelist
# 7) Keep 'master' codelist with all versions & tags
#############################################################

colnames(prodbro)

# arrange it
prodbro <- prodbro %>% arrange(laba_030101, saba_030101, lama_030102, sama_030102, sabasama_30104, labalama_30104,
                               ics_0302, icslaba_0302,  triple_0302, also_0303_cromo)

# how many rows?
nrow(prodbro)



# export (v0 no clinician, raw)

summary(prodbro)


# save what you're made. In R, this is commonly saved used an RDS file.

saveRDS(prodbro, paste0(savedir, filename, ".RDS"))

openxlsx2::write_xlsx(prodbro, file = paste0(savedir, filename, ".xlsx")) #, sheetName = "Sheet1", 
#           col.names = TRUE, row.names = FALSE, append = FALSE)

write.csv(prodbro, file = paste0(savedir, filename, ".csv"), row.names = FALSE)




# example versions:
# v0 = Raw codelist 
# v1 = Clinician1 1/2/0s
# v2 = Clinician2 1/2/0s, without Clinician1's 0s)
# v3 = Clinician1 & Clinician2's 1/2/0s merged (i.e., v0-v3 merged)
# v4 = Final, project-specific Codelist- discordancies resolved, final project-specific list
# 
# keep v0 raw, v3 merged, and v4 project-specific
# 
# 


# Generate tag file for codelist repository

tagfile <- file(paste0(savedir, filename, ".tag"))

writeLines(paste(
  
  # = Update details here, everything else is automated ==========================
  "0301 0302 BNF Rx COPD inhalers", # description
  "ELG", # author
  "February 2023", # date
  "prod browsing", # code_type
  "CPRD Aurum", # database
  "February 2022", # database_version
  "Adapted codelist from previous. Value sets organised by how Rx prescribed and roughly by BNF subsection. 
  Combines searches for all RX into a single file. Picks up extra codes primarly for ics, saba, and new codes 
  for sama-saba and triple. Flag for overlap with BNF 0303. **NB Flag for new paeds code. If update this codelist, 
  should only need to add new brands or additional chemicals to the nested macros prn. Clinician 1s are for [x study].", 
  "February 2023", # date clinician_approved
  # ==============================================================================
  sep = "\n"), tagfile)

close(tagfile)





