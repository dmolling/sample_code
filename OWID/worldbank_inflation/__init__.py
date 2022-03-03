import os

# Dataset constants.
DATASET_NAME = "World Bank Cross-Country Database of Inflation"
DATASET_AUTHORS = "World Bank"
DATASET_VERSION = "June 2021"
DATASET_LINK = "https://www.worldbank.org/en/research/brief/inflation-database"
FILE_URL = "https://thedocs.worldbank.org/en/doc/1ad246272dbbc437c74323719506aa0c-0350012021/original/Inflation-data.xlsx"
DATA_SERIES = "hcpi_a"
DATASET_RETRIEVED_DATE = "02-March-2022"
DATASET_DIR = os.path.dirname(__file__).split("/")[-1]
DATASET_NAMESPACE = f"{DATASET_DIR}@{DATASET_VERSION}"
CONFIGPATH = os.path.join(DATASET_DIR, "config")
INPATH = os.path.join(DATASET_DIR, "input")
OUTPATH = os.path.join(DATASET_DIR, "output")



