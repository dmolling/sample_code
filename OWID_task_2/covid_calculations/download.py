"""downloads OWID Covid data and saves it to disk.
"""

from fileinput import filename
import os
import shutil
from io import BytesIO
import requests
import pandas as pd
from tqdm import tqdm

from covid_calculations import INPATH, FILE_URL, POPULATION_DATA_URL

import logging

logging.basicConfig()
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

MAX_RETRIES = 5
CHUNK_SIZE = 8192


def main():
    delete_input()
    download_data(FILE_URL, "vaccinations.csv")
    download_data(POPULATION_DATA_URL, "population_latest.csv")


def delete_input() -> None:
    """deletes all files and folders in `{INPATH}`.
    WARNING: this method deletes all input data and is only intended for use
    immediately prior to `download_data()`.
    """
    if os.path.exists(INPATH):
        shutil.rmtree(INPATH, ignore_errors=True) 
        if not os.path.exists(INPATH):
            os.makedirs(INPATH)
    logger.info(f"Deleted all existing input files in {INPATH}")


def download_data(url, filename) -> None:
    """Downloads csv data from a URL and saves in csv format to `{INPATH}`.
    """
    if not os.path.exists(INPATH):
        os.makedirs(INPATH)

    _download_data_csv(url, filename)
    logger.info(f"{filename} data succcessfully downloaded to {INPATH}")

def _download_data_csv(url, filename) -> None:
    content = _download_file(url, MAX_RETRIES)
    df = pd.read_csv(
        BytesIO(content) 
    )
    df.to_csv(os.path.join(INPATH, filename), index=False)

def _download_file(url, max_retries: int, bytes_read: int = None) -> bytes:
    logger.info(f'Downloading data from "{url}"...')
    if bytes_read:
        headers = {"Range": f"bytes={bytes_read}-"}
    else:
        headers = {}
        bytes_read = 0
    content = b""
    try:
        with requests.get(url, headers=headers, stream=True) as r:
            r.raise_for_status()
            for chunk in tqdm(r.iter_content(chunk_size=CHUNK_SIZE)):
                bytes_read += CHUNK_SIZE
                content += chunk
    except requests.exceptions.ChunkedEncodingError:
        if max_retries > 0:
            logger.info(
                "Encountered ChunkedEncodingError, attempting to resume " "download..."
            )
            content += _download_file(
                url, max_retries - 1, bytes_read
            )  # attempt to resume download
        else:
            logger.info(
                "Encountered ChunkedEncodingError, but max_retries has been "
                "exceeded. Download may not have been fully completed."
            )
    return content


if __name__ == "__main__":
    main()