"""Cleans World Bank inflation metadata and data points in preparation for visualization.

Usage:
    python -m worldbank_inflation.clean
"""

import os
import simplejson as json
import shutil
from typing import List, Dict
import pandas as pd
from pandas.api.types import is_numeric_dtype
from tqdm import tqdm
from worldbank_inflation import (
    DATASET_NAME,
    DATASET_AUTHORS,
    DATASET_VERSION,
    CONFIGPATH,
    INPATH,
    OUTPATH,
    DATA_SERIES
)

import logging

logging.basicConfig()
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def main():
    #removing prior data in preparation for replacement
    delete_output(keep_paths=["variables_to_clean.json"])

    # loads variables to be cleaned and uploaded.
    variables_to_clean = load_variables_to_clean()

    #loads a list of standardized OWID entity names
    entity2owid_name = get_standard_entities() 

    # cleans datasets and 
    df_datasets = clean_datasets()

    #cleans datapoints and saves to disk
    clean_and_create_datapoints(variables_to_clean, entity2owid_name)
    assert (
        df_datasets.shape[0] == 1
    ), f"Only expected one dataset in {os.path.join(OUTPATH, 'datasets.csv')}."

    df_distinct_entities = pd.DataFrame(get_distinct_entities(), columns=["name"])

    #saving metadata to disk
    write_metadata(df_datasets, df_distinct_entities)

def load_variables_to_clean() -> List[dict]:
    """loads the array of variables to clean."""
    try:
        with open(os.path.join(CONFIGPATH, "variables_to_clean.json"), "r") as f:
            variables = json.load(f)["variables"]
    except:  # noqa
        with open(os.path.join(OUTPATH, "variables_to_clean.json"), "r") as f:
            variables = json.load(f)["variables"]
    return [item["name"] for item in variables]  

def get_standard_entities():
    """loads mapping of "{UNSTANDARDIZED_ENTITY_CODE}" -> "{STANDARDIZED_OWID_NAME}
    e.g. {"AFG": "Afghanistan", "SSF": "Sub-Saharan Africa", ...}
    """
    standard_entities = pd.read_csv(os.path.join(CONFIGPATH, "standardized_entity_names.csv"))
    return standard_entities.set_index("country_code").squeeze().to_dict()

def delete_output(keep_paths: List[str]) -> None:
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

def clean_datasets():
    """Constructs a dataframe where each row represents a dataset cleaned for visualization."""
    data = [
        {"id": 0, "name": f"{DATASET_NAME} - {DATASET_AUTHORS} ({DATASET_VERSION})"}
    ]
    df = pd.DataFrame(data)
    return df

def clean_and_create_datapoints(variable_names: List[str], entity2owid_name: dict):
    """Cleans all entity-variable-year data observations and saves all
    data points to csv in the `{OUTPATH}/datapoints` directory.
    The data for each variable is saved as a separate csv file.
    """
    # loads data
    df_data = pd.read_csv(os.path.join(INPATH, "WorldBankInflation" + DATA_SERIES + ".csv.zip"), compression="gzip")
    df_data.columns = df_data.columns.str.lower().str.replace(r"[\s/-]+", "_", regex=True)
    
    years = (
        df_data.columns[df_data.columns.str.contains(r"^\d{4}$")].sort_values().tolist()
    )
    df_data.dropna(subset=years, how="all", inplace=True)

    df_data = df_data[df_data["series_name"].isin(variable_names)]

    # standardizes entity names
    df_data["country"] = df_data["country_code"].apply(lambda x: entity2owid_name[x])

    df_data["series_name"] = df_data["series_name"].str.lower().str.replace(r"[\s/-]+", "_", regex=True)

    # cleans each variable and saves it to csv.
    out_path = os.path.join(OUTPATH, "datapoints")
    if not os.path.exists(out_path):
        os.makedirs(out_path)

    ignored_var_names = set({})
    kept_var_names = set({})
    #var_code2meta = {}
    grouped = df_data.groupby("series_name")
    logger.info("Saving data points for each variable to csv...")
    for series_name, gp in tqdm(grouped, total=len(grouped)):
        gp_long = (
            gp.set_index("country")[years]
            .stack()
            .sort_index()
            .reset_index()
            .rename(columns={"level_1": "year", 0: "value"})
        )
        gp_long["year"] = gp_long["year"].astype(int)
        assert not gp_long.duplicated(subset=["country", "year"]).any()
        assert is_numeric_dtype(gp_long["value"])
        assert is_numeric_dtype(gp_long["year"])
        assert gp_long.notnull().all().all()
        if gp_long.shape[0] == 0:
            ignored_var_names.add(series_name)
        else:
            kept_var_names.add(series_name)
            #timespan = f"{int(gp_long['year'].min())}-{int(gp_long['year'].max())}"
            #var_code2meta[series_name] = {"id": series_name, "timespan": timespan}
            fpath = os.path.join(out_path, f"datapoints_{series_name}.csv")
            assert not os.path.exists(fpath), (
                f"{fpath} already exists. This should not be possible, because "
                "each variable is supposed to be assigned its own unique "
                "file name."
            )
            gp_long.to_csv(fpath, index=False)

    logger.info(
        f"Saved data points to csv for {len(kept_var_names)} variables. Excluded {len(ignored_var_names)} variables."
    )
    #return var_code2meta


def get_distinct_entities() -> List[str]:
    """retrieves a list of all distinct entities that contain at least
    on non-null data point that was saved to disk from the
    `clean_and_create_datapoints()` method.
    Returns:
        entities: List[str]. List of distinct entity names.
    """
    fnames = [
        fname
        for fname in os.listdir(os.path.join(OUTPATH, "datapoints"))
        if fname.endswith(".csv")
    ]
    entities = set({})
    for fname in fnames:
        df_temp = pd.read_csv(os.path.join(OUTPATH, "datapoints", fname))
        entities.update(df_temp["country"].unique().tolist())

    entity_list = sorted(entities)
    assert pd.notnull(entity_list).all(), (
        "All entities should be non-null. Something went wrong in "
        "`clean_and_create_datapoints()`."
    )
    return entity_list

def write_metadata(df_datasets, df_distinct_entities):
    df_datasets.to_csv(os.path.join(OUTPATH, "datasets.csv"), index=False)
    df_distinct_entities.to_csv(os.path.join(OUTPATH, "distinct_countries_standardized.csv"), index=False)

if __name__ == "__main__":
    main()