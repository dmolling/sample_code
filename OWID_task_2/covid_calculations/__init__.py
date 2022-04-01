import os

# Dataset constants
FILE_URL = "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/vaccinations/vaccinations.csv"
POPULATION_DATA_URL = "https://raw.githubusercontent.com/owid/covid-19-data/master/scripts/input/un/population_latest.csv"
DATASET_RETRIEVED_DATE = "2022-04-01"
TARGET_DATE = "2022-07-01"
YEAR = "2022"
DATASET_DIR = os.path.dirname(__file__).split("/")[-1]
INPATH = os.path.join(DATASET_DIR, "input")
OUTPATH = os.path.join(DATASET_DIR, "output")



