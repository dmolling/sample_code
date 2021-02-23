################################################################################
#
# Acute vs chronic modelling
#
# Date: 2019-09-16
# Version: 1.3
# Author: Daniel Molling <daniel.molling@va.gov>
#
################################################################################

# model_fit.r ---------------------------------------------------------
#
# The file contains the code to fit the final tuned versions of acute and chronic models
# 01_data_cleaning.R must be run before this file
# load packages
#Note: the workflow in this script relies heavily on multiple packages in the "tidymodels"
#group, particularly the "recipes" package. See: https://cran.r-project.org/web/packages/recipes/vignettes/Simple_Example.html
#for a nice example and explanation of the package
library(readr)
library(lubridate)
library(stringr)
library(dplyr)
library(tidyr)
library(forcats)
library(purrr)
library(rsample)
library(recipes)
library(yardstick)
library(broom)
library(ggplot2)

# load data --------------------------------------------------------------------
if(!exists("cleaned_per_patient")) {
cleaned_per_patient <- readRDS("data/cleaned_per_patient.rds")
}

# Build/define acute model ------------------------------------------------------
#MARS model allowing interactions of degree 2 with backwards selection
acute_tuned_spec <- mars(mode = "classification", prod_degree = 2, prune_method = "backward") %>%
  set_engine("earth") #num_terms = 63

# Build/define chronic model ----------------------------------------------------
chronic_tuned_spec <- mars(mode = "classification", prod_degree = 2, prune_method = "backward") %>%
  set_engine("earth") 

# Fit a MARS model for each day -----------------------------------------------------------
#cv_fit_metrics2 function:
#1) makes a random training and testing split of the data stratified by inhosp_mort
#2) fits the MARS model to the training set
#3) saves model predictions and computes several metrics of model fit, notably roc curves
cv_fit_metrics2 <- function(dat, rec, spec, times = 3){
  dat %>%
    rsample::mc_cv(times = times, strata = "inhosp_mort") %>%
    mutate(pred = map(splits, ~predict(fit(spec, formula = formula(rec),
                                           data = bake(rec, new_data = analysis(.x))),
                                       new_data = bake(rec, new_data = assessment(.x)),
                                       type = "raw", opts = list("response") ) %>%
                        as_tibble() %>%
                        rename(risk =`1`) %>%
                        bind_cols(assessment(.x) %>% 
                                    select(inhosp_mort)) %>%
                        mutate(inhosp_mort = factor(inhosp_mort, c(0,1), c("Survived","Died")),
                               risk_class = factor(risk > 0.5, c(FALSE, TRUE), c("Survived","Died")))),
           metrics = map(pred, ~metrics(.x, truth = inhosp_mort, estimate = risk_class, probs = risk))) %>%
    select(id, metrics) %>%
    unnest()
}

#los_model_fits function:
#1) splits the dataset into 28 seperate datasets containing only patients with icu
#length of stay >= x days for x in 1:28
#2) applies the cv_fit_metrics2 function to each dataset 100 times (100 different random splits)
#3) stores results including model predictions and metrics
# note: this takes ~10hours to run on VA VINCI servers
microbenchmark::microbenchmark(
  los_model_fits <- tibble(unit_los = 1:28) %>%
    mutate(day_split = map(unit_los, ~ cleaned_per_patient_flt2 %>%
                             filter(icu_los_bedsection >= .x)),
           acute_metrics = map(day_split, cv_fit_metrics2, 
                               rec = acute_rec, 
                               spec = acute_tuned_spec, times = 100),
           chronic_metrics = map(day_split, cv_fit_metrics2, 
                                 rec = chronic_rec, 
                                 spec = chronic_tuned_spec, times = 100))
  , times = 1)

los_model_fits <- los_model_fits %>%
  select(-day_split)

saveRDS(los_model_fits, file = "data/los_model_fits.rds")









