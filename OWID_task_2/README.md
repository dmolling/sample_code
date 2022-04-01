
# Dataset import and estimates for whether locations are on track to have completed the initial vaccination protocol for 70% of the population 

Instructions:

1. Update covid_calculations/__init__.py with the appropriate DATASET_RETRIEVED_DATE, and other constants as needed. Currently, this requires explicitly specifying the DATASET_RETRIEVED_DATE. 

2. Execute `python -m main` from this folder.

The output from running is covid_calculations/output/estimates.csv 

In general, there are some differences between the dataset I generated and the dataset I obtained when dowloading chart data. I attempt to explain the differences below when providing notes on methodology and data below. If you have any additional questions about my results or would like me to update my code to also write intermediate datasets for the purpose of comparison, please let me know. 

## Methodology Notes:
- I calculate vaccination rate based on last 14 days of reported data rather than calendar data (provided that a given location has at least one day of reported data in the past 30 calendar days). This appears to cause some differences between my generated data and the OWID chart data. Anguilla and Botswana are examples of this.

Why I estimated vaccination rate this way:
1. To use a full 14 days of daily_people_vaccinated data rather than average a smaller number of observations
2. To avoid injecting any potential weekly seasonality effects into the rate estimate. 

The potential downside of this method is that it will be less responsive to rapid changes in vaccination rates, and could overstate estimated vaccinations if the reason for lack of reported data in a location is because there have not been additional vaccinations. I'm not familiar enough with the specific reporting practices for locations where this change made a difference to evaluate whether this is a serious concern. Before putting this method into production I'd investigate further. 

- I did not spent time writing tests for the dataset itself. I'm assuming such tests would be part of the process of generating the dataset, and thus I assume the dataset exists, is correct, and will remain in a constant format. Depending on the process OWID uses to do such data checks, I would consider adding some data checks to this code as well.

- Where there wasn't data for a given location in OWID's population dataset (https://github.com/owid/covid-19-data/blob/master/scripts/input/un/population_latest.csv), I used estimated population based on people_vaccinated and people_vaccinated_per_hundred. This will cause some rounding error, so if I were to update this code before putting it into production I'd want to use more precise population numbers.

## Data Notes:
- I have a few more location observations in my generated dataset than what is poputated when I download chart data. I'm not entirely sure why. However, I believe there is an inconsistency in whether locations that have already reached the WHO vaccination target are included in the dataset as all such cases have already met the vaccination target. One example is Falkland Islands.
- When downloading chart data, there are also some observations that already have higher than 70 people_vaccinated_per_hundred in the OWID vaccination dataset that are listed as "On track to 70%" rather than "Already above 70%". One example is Bangladesh. This may be an error in the OWID chart data, or may reflect a misunderstanding on my part of the people_vaccinated_per_hundred variable.
- The estimated number of people vaccinated by the target date is higher than the estimated population in some cases. Niue and Gibraltar in particular have a higher reported current number of people vaccinated than their estimated population





