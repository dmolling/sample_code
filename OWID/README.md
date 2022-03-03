
# Dataset import for World Bank Global Database of Inflation

This folder contains all scripts required to execute a dataset import + update of chart for the World Bank - Global Database of Inflation: Annual headline consumer price index inflation dataset. 

Currently, this code is set up to download and store all the different series published in the World Bank Global Database of Inflation, however it only cleans and saves datapoints and metadata for their annual headline consumer price index. With a bit of work this code could be extended to also clean and save other data published in this database. 

Instructions:

1. Update worldbank_inflation/__init__.py with the appropriate DATASET_VERSION, DATASET_RETRIEVED_DATE, and other constants as needed.

2. Execute `python -m main` from this folder.

3. Run the included R script in this folder to generate the baseline visualization of this data series. 

Putting these scripts in the context of my application to Our World in Data:

I chose to use this task as an excuse to dust off my admittedly rusty python programming skills, and also to learn about how OWID currently structures your codebase and manages data imports. As a result I borrowed the general structure and many of the functions in this directory from the owid/importers/worldbank_wdi repository on github while making some modifications and simplifications. 

My hope is that this demonstrates my:

1. Interest in how OWID operates
2. Ability to learn and adapt to a new codebase. 
3. Make improvements to existing code, and create a "minimum viable product" that could be adapted to a more general use. 

I reverted back to my more comfortable R skills for the baseline visualization of this data series. If I had spent more time on the visualization part of this task, I would have created either an interactive R shiny or python application that allows for filtering of countries or changed the chart code to do a much better job of automatically adjusting the location of labels and axis ticks depending on which countries or years are selected. If you are interested in having me demonstrate the ability to do that, or have any other questions about any of the files in this folder please let me know. 

