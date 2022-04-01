
"""Executes dataset import, generating calculations of whether 
locations are on track to meet the WHO vaccination goal, 
and writing output and to disk for the OWID Covid-19 dataset.

Usage:
    python -m main
"""

from covid_calculations import download , calculations

def main():
    download.main()
    calculations.main()

if __name__ == "__main__":
    main()
