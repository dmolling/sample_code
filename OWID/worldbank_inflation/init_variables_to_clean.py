import os
import simplejson as json
import shutil
import pandas as pd
import logging
from typing import List

from worldbank_inflation import INPATH, OUTPATH, DATA_SERIES

logging.basicConfig()
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def main():
    variables_to_clean = get_variables_to_clean(DATA_SERIES)

    uniq_var_names = {var["name"] for var in variables_to_clean}
    for var in variables_to_clean:
        if var["name"] not in uniq_var_names:
            variables_to_clean.append(var)
            uniq_var_names.add(var["name"])

    uniq_var_names = [var["name"] for var in variables_to_clean]
    assert len(uniq_var_names) == len(set(uniq_var_names)), (
        "There are one or more duplicate variable names in the constructed "
        "array of variables to clean. Expected 0 duplicate variable names."
    )
    variables_to_clean = sorted(variables_to_clean, key=lambda x: x["name"])

    #removes data in output in preparation for writing new data
    delete_output()
    with open(os.path.join(OUTPATH, "variables_to_clean.json"), "w") as f:
        json.dump(
            {
                "meta": {
                    "notes": "This file contains an array of World Bank Inflation "
                    "variables to clean. Any variables NOT in this file will be "
                    "ignored."
                },
                "variables": variables_to_clean,
            },
            f,
            ignore_nan=True,
            indent=4,
        )

def get_variables_to_clean(series) -> List[dict]:
    """Retrieves an array of variables to clean from newly imported data.
    """
    df_variables = get_new_variables(series)
    df_variables = df_variables[["series_name"]].rename(
        columns={"series_name": "name"}
    )
    variables_to_clean = df_variables.to_dict(orient="records")
    return variables_to_clean


def get_new_variables(series):
    """Retrieves variable names from downloaded file
    """
    infpath = os.path.join(INPATH, "WorldBankInflation" + series + ".csv.zip")
    df_data = pd.read_csv(infpath, compression="gzip")
    df_data.columns = df_data.columns.str.lower().str.replace(
        r"[\s/-]+", "_", regex=True
    )
    df_variables = df_data[["series_name"]].drop_duplicates()
    assert len(df_variables == 1), (
        "There are multiple variables in the constructed array of variables names."
        "Expected only 1 variable.")
    return df_variables

def delete_output() -> None:
    """deletes all files in `{DATASET_DIR}/output`, and creates output folder if 
    it does not already exist
    """
    if os.path.exists(OUTPATH):
        shutil.rmtree(OUTPATH, ignore_errors=True)
        if not os.path.exists(OUTPATH):
            os.makedirs(OUTPATH)
    else:
        os.makedirs(OUTPATH)



if __name__ == "__main__":
    main()