"""Generates calculations based on OWID Covid-19 data.

Usage:
    python -m covid_calculations.calculations
"""

import os
import shutil
from typing import List
import pandas as pd
import numpy as np
from covid_calculations import (
    INPATH,
    OUTPATH,
    DATASET_RETRIEVED_DATE,
    TARGET_DATE,
    YEAR
)

def main():
    #removing prior data in preparation for replacement
    delete_output()

    vaccinations = get_csv_input("vaccinations.csv")
    population_latest = get_csv_input("population_latest.csv")

    estimates = calculate_estimates(vaccinations, population_latest)
    
    write_estimates(estimates, "estimates.csv")
 
def delete_output(keep_paths: List[str] = []) -> None:
    """deletes all files in `{DATASET_DIR}/output` EXCEPT for any file
    names in `keep_paths`, and creates output folder if 
    it does not already exist
    
    Arguments:
        keep_paths: List[str]. List of subpaths in `{DATASET_DIR}/output` that
            you do NOT want deleted. They will be temporarily move to `{DATASET_DIR}`
            and then back into `{DATASET_DIR}/output` after everything else in
            `{DATASET_DIR}/output` has been deleted.
    Returns:
        None.
    """
     # temporarily moves some files out of the output directory so that they
    # are not deleted.
    for path in keep_paths:
        if os.path.exists(os.path.join(OUTPATH, path)):
            os.rename(os.path.join(OUTPATH, path), os.path.join(OUTPATH, "..", path))
    # deletes all remaining output files 
    if os.path.exists(OUTPATH):
        shutil.rmtree(OUTPATH, ignore_errors=True) 
        if not os.path.exists(OUTPATH):
            os.makedirs(OUTPATH)
    else:
        os.makedirs(OUTPATH)

    # moves the exception files back into the output directory.
    for path in keep_paths:
        if os.path.exists(os.path.join(OUTPATH, "..", path)):
            os.rename(os.path.join(OUTPATH, "..", path), os.path.join(OUTPATH, path))

def calculate_estimates(vaccinations, population_latest):
    """returns a dataframe of all distinct locations,
     along with their entity code and estimated status 
     towards the WHO initial vaccination protocol goal
    """
    vaccinations['date'] = pd.to_datetime(vaccinations['date'])
    vaccinations = vaccinations.sort_values(['location', 'date'], ascending=[True, True])

    #Filtering for dates earlier than DATASET_RETRIEVED_DATE
    #This only filters if running for a date in the past rather than today's date
    vaccinations = vaccinations[vaccinations['date'] <= DATASET_RETRIEVED_DATE] 

    #dropping rows without a value for daily initial vaccine protocol completions
    vaccinations = vaccinations[vaccinations['daily_people_vaccinated'].notna()]

    vaccinations['most_recent_date'] = vaccinations.groupby('iso_code')['date'].transform('max')

    #filtering for most recent 14 days of data for each location 
    vaccinations = vaccinations[vaccinations['date'] > vaccinations['most_recent_date'] - pd.DateOffset(days = 14)]

    #Group by location and calculate the rate of initial vaccination protocol completions over this period
    location_level_vaccinations = vaccinations.groupby(
        ['location','iso_code', 'most_recent_date']
        ).agg(
            daily_people_vaccinated_rate=pd.NamedAgg(column='daily_people_vaccinated', aggfunc='mean'),
            people_vaccinated = pd.NamedAgg(column='people_vaccinated', aggfunc='last'),
            people_vaccinated_per_hundred = pd.NamedAgg(column='people_vaccinated_per_hundred', aggfunc='last'),
        ).reset_index()
    location_level_vaccinations['target_date'] = pd.to_datetime(TARGET_DATE)

    #filtering for locations that either reported data in the past 30 days or
    #already reached the vaccination target
    location_level_vaccinations = location_level_vaccinations[ 
        (location_level_vaccinations['most_recent_date'] + pd.DateOffset(days = 30) >= DATASET_RETRIEVED_DATE)
        | (location_level_vaccinations['people_vaccinated_per_hundred'] >= 70)]

    #calculating the estimated number of initial vaccination protocol completions before TARGET_DATE
    #using the 14 day average rate from the most recent point of data
    location_level_vaccinations['people_vaccinated_by_target_date'] = (
        location_level_vaccinations['people_vaccinated'] +
        location_level_vaccinations['daily_people_vaccinated_rate'] * 
        (location_level_vaccinations['target_date'] - location_level_vaccinations['most_recent_date']).dt.days
        )

    #merge in population data
    combined_data = pd.merge(location_level_vaccinations, population_latest[['iso_code', 'population']],on='iso_code',how='left')

    #estimating population for locations without a listed population in the population_lastest.csv file
    #a more complete version of this code would use exact numbers from primary sources to avoid rounding errors
    combined_data['population'] = combined_data['population'].fillna(combined_data['people_vaccinated'] / (combined_data['people_vaccinated_per_hundred']/100)) 

    #calculate the estimated share of population vaccinated
    combined_data['estimated_share_vaccinated'] = combined_data['people_vaccinated_by_target_date'] / combined_data['population']
    assert (combined_data['estimated_share_vaccinated'].between(0,5)).all(), (
        "At least one estimated_share_vaccinated for a location is between 0 and 5."
    ) #note: some countries have a higher estimated number of vaccinations by target date than the population

    combined_data['Year'] = YEAR

    combined_data['status'] = np.select(
        [
            combined_data['people_vaccinated_per_hundred'] >= 70,
            combined_data['estimated_share_vaccinated'] < 0.7, 
            combined_data['estimated_share_vaccinated'] >= 0.7
        ], 
        [
            "Already above 70% fully vaccinated",  
            "Not on track to 70% fully vaccinated",
            "On track to 70% fully vaccinated"
        ], 
        default=pd.NA
    )
    return combined_data[['location', 'iso_code', 'Year', 'status']].rename(columns={"location": "Entity", "iso_code": "Code"}) 

def get_csv_input(filename):
    """loads input data in csv format from {INPATH}
    """
    input = pd.read_csv(os.path.join(INPATH, filename))
    return input


def write_estimates(estimates, filename):
    estimates.to_csv(os.path.join(OUTPATH, filename), index=False)

if __name__ == "__main__":
    main()
