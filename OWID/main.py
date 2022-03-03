
"""Executes dataset import, cleaning, and writing 
cleaned datapoints and metadata to disk for the 
World Bank Global Database of Inflation dataset.

Usage:
    python -m main
"""

from worldbank_inflation import download, init_variables_to_clean, clean

def main():
    download.main()
    init_variables_to_clean.main()
    clean.main()

if __name__ == "__main__":
    main()