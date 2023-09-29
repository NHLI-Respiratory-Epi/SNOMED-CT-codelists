# -*- coding: utf-8 -*-
"""
Created on Fri Aug 18 22:04:38 2023

@author: pstone
"""
# Required packages
# =================

import os
import sys
import pandas as pd



# Set working directory and open log file
# =======================================

# Current working directory
cwd = os.getcwd()

# Set new working directory
os.chdir("D:/GitHub/SNOMED-CT-codelists/scripts/python")

# Open log file
#sys.stdout = open('smoking_status.log', 'w')



# Required directories
# ====================

cprdbrowser_dir = "Z:/Database guidelines and info/CPRD/CPRD_CodeBrowser_202202_Aurum"
cprdlookup_dir = "Z:/Database guidelines and info/CPRD/CPRD_Latest_Lookups_Linkages_Denominators/Aurum_Lookups_Feb_2022"



# Import CPRD Aurum medical dictionary
# ====================================

medical = pd.read_csv(
    cprdbrowser_dir + "/CPRDAurumMedical.txt",
    sep="\t",
    usecols=[0, 1, 2, 3, 4, 5, 6, 8], # don't import empty release column
    dtype={5: str, 6: str},           # import snomedctconcept, snomedctdescription as string
    na_filter=False
)

# Make column names lower case
medical.columns = medical.columns.str.lower()

# Label EMIS code categoical variable
emislabel = pd.read_csv(cprdlookup_dir + "/EmisCodeCat.txt", sep="\t", dtype={1: "category"})
emislabel.columns = emislabel.columns.str.lower()
emislabel = emislabel.rename(columns={"emiscodecatid": "emiscodecategoryid"})
medical = medical.merge(emislabel, on=["emiscodecategoryid"], how="left")
medical = medical.drop("emiscodecategoryid", axis=1)
medical = medical.rename(columns={"description": "emiscodecategoryid"})

# Reorder columns
cols = list(medical.columns)
cols = cols[:4] + cols[5:8] + cols[4:5]
medical = medical[cols]

medical.info()



# 1. Define search terms
# ======================

smokingstatus = ["smok", "cigar", "tobac", "pack.*year"]



# 2. Search the medical dictionary
# ================================

# Create a copy of the medical dictionary to modify
codelist = medical.copy()

for searchterm in smokingstatus:
    codelist[searchterm] = codelist['term'].str.contains(searchterm, case=False)

# Just keep the terms with matches
codelist = codelist[codelist[smokingstatus].any(axis=1)]

# Sort by concept, description, readcode, then medcode
codelist.sort_values(by=['snomedctconceptid', 'snomedctdescriptionid', 'originalreadcode', 'medcodeid'], inplace=True)

# Print frequency of each search term
for searchterm in smokingstatus:
    print(codelist[searchterm].value_counts())



# 3. Exclusion search
# ===================

# Exclusion terms

exclude = ["accident", "allergen", "asthma", "burn", "diesel", "leaf.*specific", "lighter", "virus.*group", "waste.*management", "wheeze", "socio-economic", "assist-lite"]
animal = ["cheese", "cockroach", "fish", "frog", "haddock", "mackerel", "rabbit", "salmon", "smoked.*cod", "smoky.*gilled.*woodlover", "smoky.*madtom", "trout"]
bacteria = ["bacill", "bacter"]
fire = ["conflagration", "fire", "smoke.*alarm", "smoke.*inhalation"]
garments = ["garment", "sigvaris"]
occupation = ["blender", "grader", "industry", "maker", "operator", "preparer", "processor", "stripper", "tobacconist"]


# Search for codes to exclude

for excludeterm in exclude + animal + bacteria + fire + garments + occupation:
    codelist[excludeterm] = codelist['term'].str.contains(excludeterm, case=False)


# Print terms that are highlighted for exclusion
for excludeterm in exclude + animal + bacteria + fire + garments + occupation:
    print("Exclusion term:", excludeterm)
    print(codelist[excludeterm].value_counts())
    print(codelist.loc[codelist[excludeterm] == True, 'term'])
    print()

# Drop rows that contain exclusion terms
codelist = codelist[~codelist[exclude + animal + bacteria + fire + garments + occupation].any(axis=1)]

# Drop exclusion term columns
codelist.drop(columns=exclude + animal + bacteria + fire + garments + occupation, inplace=True)

# Print number of remaining rows
print("Terms remaining after exclusion search:", codelist.shape[0])



# TODO: Steps 4 to 9



# Close log file and reset working directory
# ==========================================

# Close log file
#sys.stdout.close()
#sys.stdout = sys.__stdout__

# Restore working directory to its original location
os.chdir(cwd)