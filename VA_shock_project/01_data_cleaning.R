################################################################################
#
# Acute vs chronic modelling with VA data
#
# Author: Daniel Molling <daniel.molling@gmail.com>
#
################################################################################

# 01_data_cleaning.r -----------------------------------------------------------
#
# The file contains the code used to clean data and create lists of 
# features to be used in later modeling for the cited paper below:
# Viglianti EM, Bagshaw SM, Bellomo R, McPeake J, Molling DJ, Wang XQ, Seelye S, Iwashyna TJ. 
# "Late Vasopressor Administration in Patients in the ICU: A Retrospective Cohort Study". 
# Chest. 2020 Aug
# The raw data file contains daily observations for all VA ICU stays in the year 2017
# This file creates and cleans a hospitalization level dataset 

# Note: if I wrote this today I'd use mutate_at() commands to do more of the data cleaning
# and this file would be significantly shorter. 

# Load required packages
library(readr)
library(haven)
library(lubridate)
library(stringr)
library(dplyr)
library(tidyr)
library(forcats)
library(rsample)
library(recipes)

#load and save raw dataset from the CDW (generated using SQL/SAS):
#df = read_sas("data/icu_shock_20190517.sas7bdat") 
#saveRDS(df, "data/icu_shock_20190517.rds")

df = readRDS("data/icu_shock_20190517.rds")
df = df %>% 
  filter(new_ICU_day_bedsection == 1) %>% #keep only observations from first day in ICU
  select(
    ### acute vars ###
    ## lab scores ##
    albval_sc,                 
    glucose_sc,                  
    creat_sc,                  
    bili_sc,                    
    bun_sc,                     
    na_sc,                      
    wbc_sc,                      
    hct_sc,                      
    pao2_sc,                     
    ph_sc,
    #pc02
    ##individual ccs grouping diagnosis codes ##
    singlelevel_ccs,
    ## multi-level CCS groupings
    multilevel1_ccs,
    ## other
    any_pressor_daily = any_pressor, #indicator if every given any pressor during stay
    proccode_mechvent_hosp, #indicator if ever mechanically ventilated during hospitalization
    
    ### chronic vars ###
    ## demographics ##
    age = age,
    race = Race,
    female = Gender,
    ## elixhauser comorbidities ##
    chf,
    cardic_arrhym,
    valvular_d2,
    pulm_circ,
    pvd,
    htn_combined,
    paralysis,
    neuro,
    pulm,
    dm_uncomp,
    dm_comp,
    hypothyroid,
    renal,
    liver,
    pud,
    ah,
    lymphoma,
    cancer_met,
    cancer_nonmet,
    ra,
    coag,
    obesity,
    wtloss,
    fen,
    anemia_cbl,
    anemia_def,
    etoh,
    drug,
    psychoses,
    depression,
    ##Other non-clinical information ##
    Isa_readm30, #readmission indicator
    patienticn = patienticn,
    scrssn = scrssn,
    inpatientsid = inpatientsid,
    patientsid = patientsid,
    dob = DOB,
    sta3n = sta3n,
    specialty = specialty,
    acute = acute,
    sta6a = sta6a,
    icu = icu,
    admityear = admityear,
    newadmitdate = new_admitdate2,
    newdischargedate = new_dischargedate2, 
    dod_09212018_pull = dod_09212018_pull,
    inhosp_mort = inhospmort, #indicator if patient died during icu stay
    mort30_admit = mort30, #indicator for death within 30 days of icu admission
    datevalue = datevalue,
    icdtype = icdtype,
    sum_elixhauser_count = sum_Elixhauser_count,
    hosp_los = hosp_LOS, #length of entire hospital stay - days
    icu_los_bedsection = new_SUM_ICU_days_bedsection, #length of icu stay - days
    elixhauser_vanwalraven = elixhauser_VanWalraven,
    unique_hosp_count_id = unique_hosp_count_id,
    va_risk_score = VA_risk_scores #constructed VA risk score 
  ) %>% 
mutate( 
  ### Formatting variables
  inhosp_mort = as.factor(inhosp_mort),
  ### acute vars ###
  ## lab scores ##
  albval_sc = as.factor(albval_sc),                 
  glucose_sc = as.factor(glucose_sc),                  
  creat_sc = as.factor(creat_sc),                  
  bili_sc = as.factor(bili_sc),                    
  bun_sc = as.factor(bun_sc),                     
  na_sc = as.factor(na_sc),                      
  wbc_sc = as.factor(wbc_sc),                      
  hct_sc = as.factor(hct_sc),                      
  pao2_sc = as.factor(pao2_sc),                     
  ph_sc = as.factor(ph_sc),
  #pc02
  ## Creating indicators for the 20 most common individual ccs diagnosis codes ##
  ccs1  = as.factor(if_else(singlelevel_ccs == 2, 1, 0, missing = 0)),
  ccs2  = as.factor(if_else(singlelevel_ccs == 131, 1, 0, missing = 0)),
  ccs3  = as.factor(if_else(singlelevel_ccs == 101, 1, 0, missing = 0)),
  ccs4  = as.factor(if_else(singlelevel_ccs == 100, 1, 0, missing = 0)),
  ccs5  = as.factor(if_else(singlelevel_ccs == 106, 1, 0, missing = 0)),
  ccs6  = as.factor(if_else(singlelevel_ccs == 108, 1, 0, missing = 0)),
  ccs7  = as.factor(if_else(singlelevel_ccs == 19, 1, 0, missing = 0)),
  ccs8  = as.factor(if_else(singlelevel_ccs == 96, 1, 0, missing = 0)),
  ccs9  = as.factor(if_else(singlelevel_ccs == 115, 1, 0, missing = 0)),
  ccs10 = as.factor(if_else(singlelevel_ccs == 660, 1, 0, missing = 0)),
  ccs11 = as.factor(if_else(singlelevel_ccs == 122, 1, 0, missing = 0)),
  ccs12 = as.factor(if_else(singlelevel_ccs == 153, 1, 0, missing = 0)),
  ccs13 = as.factor(if_else(singlelevel_ccs == 127, 1, 0, missing = 0)),
  ccs14 = as.factor(if_else(singlelevel_ccs == 237, 1, 0, missing = 0)),
  ccs15 = as.factor(if_else(singlelevel_ccs == 50, 1, 0, missing = 0)),
  ccs16 = as.factor(if_else(singlelevel_ccs == 114, 1, 0, missing = 0)),
  ccs17 = as.factor(if_else(singlelevel_ccs == 238, 1, 0, missing = 0)),
  ccs18 = as.factor(if_else(singlelevel_ccs == 99, 1, 0, missing = 0)),
  ccs19 = as.factor(if_else(singlelevel_ccs == 205, 1, 0, missing = 0)),
  ccs20 = as.factor(if_else(singlelevel_ccs == 14, 1, 0, missing = 0)),
  ## multi-level CCS grouping
  multilevel1_ccs = as.factor(multilevel1_ccs),
  ## other
  any_pressor_daily = as.factor(any_pressor_daily),
  proccode_mechvent_hosp = as.factor(proccode_mechvent_hosp),
  ### chronic vars ###
  ## demographics ##
  age = as.numeric(age),
  race = as.factor(race),
  female = as.factor(female),
  ## elixhauser comorbidities ##
  chf = as.factor(chf),
  cardic_arrhym = as.factor(cardic_arrhym),
  valvular_d2 = as.factor(valvular_d2),
  pulm_circ = as.factor(pulm_circ),
  pvd = as.factor(pvd),
  htn_combined = as.factor(htn_combined),
  paralysis = as.factor(paralysis),
  neuro = as.factor(neuro),
  pulm = as.factor(pulm),
  dm_uncomp = as.factor(dm_uncomp),
  dm_comp = as.factor(dm_comp),
  hypothyroid = as.factor(hypothyroid),
  renal = as.factor(renal),
  liver = as.factor(liver),
  pud = as.factor(pud),
  ah = as.factor(ah),
  lymphoma = as.factor(lymphoma),
  cancer_met = as.factor(cancer_met),
  cancer_nonmet = as.factor(cancer_nonmet),
  ra = as.factor(ra),
  coag = as.factor(coag),
  obesity = as.factor(obesity),
  wtloss = as.factor(wtloss),
  fen = as.factor(fen),
  anemia_cbl = as.factor(anemia_cbl),
  anemia_def = as.factor(anemia_def),
  etoh = as.factor(etoh),
  drug = as.factor(drug),
  psychoses = as.factor(psychoses),
  depression = as.factor(depression),
  ##readmission indicator ##
  Isa_readm30 = as.factor(Isa_readm30)
  ) 

###Initial outcomes and eligibility criteria ----------------------------
  df <- df %>%
  #constructing var for number of days from icu discharge until death
  mutate(time_from_hosp_discharge = if_else(!is.na(dod_09212018_pull),
                                            as.numeric(difftime(dod_09212018_pull,
                                                                newdischargedate,
                                                                units = "days")),
                                            as.numeric(difftime(ymd("2018-12-31"),
                                                                newdischargedate,
                                                                units = "days"))), 
         unit_stay = if_else(icu_los_bedsection >= 28, "28+", as.character(icu_los_bedsection)),
         strata_var = paste0(as.character(inhosp_mort),"_",as.character(unit_stay)))  %>%
  filter(age > 16, age < 110) %>%
  #filtering to keep only patients that died outside hospital
  filter(time_from_hosp_discharge >= 0)

#### Create basic acute features and list candidate variables for model inclusion --------------
acute_vars <- inhosp_mort ~ albval_sc + glucose_sc + creat_sc + bili_sc + bun_sc + 
  na_sc + wbc_sc + hct_sc + pao2_sc + ph_sc + ccs1 + ccs2 + ccs3 + ccs4 + ccs5 + ccs6 + ccs7 +
  ccs8 + ccs9 + ccs10 + ccs11 + ccs12 + ccs13 + ccs14 + ccs15 + ccs16 + ccs17 + ccs18 + ccs19 + 
  ccs20 + multilevel1_ccs + any_pressor_daily + proccode_mechvent_hosp + Isa_readm30

acute_rec <- recipe(acute_vars, data = cleaned_per_patient_flt2) %>%
  step_mutate(
    #creating new explicit category within each categorical variable if data is missing
    albval_sc = fct_explicit_na(albval_sc),
    glucose_sc = fct_explicit_na(glucose_sc),
    creat_sc = fct_explicit_na(creat_sc),
    bili_sc = fct_explicit_na(bili_sc),
    bun_sc = fct_explicit_na(bun_sc),
    na_sc = fct_explicit_na(na_sc),
    wbc_sc = fct_explicit_na(wbc_sc),
    hct_sc = fct_explicit_na(hct_sc),
    pao2_sc = fct_explicit_na(pao2_sc),
    ph_sc = fct_explicit_na(ph_sc),
    multilevel1_ccs = fct_explicit_na(multilevel1_ccs ),
    any_pressor_daily = fct_explicit_na(any_pressor_daily ),
    proccode_mechvent_hosp = fct_explicit_na(proccode_mechvent_hosp), 
    Isa_readm30 = fct_explicit_na(Isa_readm30)) %>%
  #step_meanimpute(all_numeric()) %>% #note: no numerical variables included in acute model
  #step_dummy(all_nominal()) %>%
  #step_bin2factor(all_outcomes()) %>%
  prep()
#prep(training = training_data)


# Create basic chronic features list candidate variables for model inclusion----------------------
chronic_vars <- inhosp_mort ~ age + race +  female + chf + cardic_arrhym + valvular_d2 + pulm_circ + 
  pvd + htn_combined + paralysis + neuro + pulm + dm_uncomp + dm_comp + hypothyroid +
  renal + liver + pud + ah + lymphoma + cancer_met + cancer_nonmet + ra + coag + obesity +
  wtloss + fen + anemia_cbl + anemia_def + etoh + drug + psychoses + depression + Isa_readm30

chronic_rec <- recipe(chronic_vars, data = cleaned_per_patient_flt2) %>%
  #step_mutate( )#,
  #step_dummy(all_nominal()) %>%
  #for simplicity, impute all numeric vars with their mean as there is very little missing data
  step_medianimpute(all_numeric()) %>% 
  prep()

saveRDS(df, file = "data/cleaned_per_patient.rds")
rm(df)




