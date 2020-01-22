################################################################################
#
# Acute vs chronic modelling with Scotland data
#
# Date: 2019-09-16
# Version: 1.3
# Author: Daniel Molling <daniel.molling@va.gov>
#
################################################################################

# figures.r ---------------------------------------------------------
# load packages
library(dplyr)
library(ggplot2)
library(yardstick)
library(broom)

los_model_fits <- readRDS("data/los_model_fits.rds")

los_model_fits  %>%
  unnest() %>%
  select(-.estimator, -.estimator1, -id, -id1, -.metric1) %>%
  rename(metric = .metric,
         acute = .estimate,
         antecedent = .estimate1) %>%
  gather("type", "value", -unit_los, -metric) %>%
  mutate(type = fct_recode(type, Acute = "acute", Antecedent = "antecedent")) %>%
  group_by(unit_los, type, metric) %>%
  summarise(med = median(value),
            lo = quantile(value, probs = 0.025),
            hi = quantile(value, probs = 0.975)) %>%
  filter(metric == "roc_auc") %>%
  
  ggplot(aes(x = unit_los, y = med, colour = type)) + 
  geom_line() +
  geom_ribbon(aes(ymin = lo, ymax = hi, fill = type), alpha = 0.25, linetype = 0) +
  ylab("AUROC") +
  xlab("ICU length of stay (days)") +
  coord_cartesian(ylim = c(0,1)) 

ggsave("figures/auroc_comparison_1000.jpeg", device = "jpeg", width = 10, height = 7, units = "in")
