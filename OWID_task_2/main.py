
"""Executes dataset import, cleaning, and writing 
cleaned datapoints and metadata to disk for the 
World Bank Global Database of Inflation dataset.

Usage:
    python -m main
"""

from covid_calculations import download , calculations

def main():
    download.main()
    calculations.main()

if __name__ == "__main__":
    main()