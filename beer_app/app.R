#
# This is the source code for a beer review explorer app which runs on R and Shiny. 
# Raw data was dowloaded from Kaggle (https://www.kaggle.com/rdoume/beerreviews) 
# Original data source is the beer review site beeradvocate.com
# Beers are scored on a 1-5 scale 
#
# Author: Daniel Molling <daniel.molling@gmail.com>#
#
# The raw data is saved in a csv file containing 1,586,614 reviews
# From this I generated mean scores for each scoring category for each beer 
# in the raw dataset.
#
# If I ever decide to update this app with more recent data I'll also include 
# a bayesian estimate of each beer's mean  score to adjust for differing 
# number of reviews and add more features to the app and handle missing
# data  better. For now, I arbitrarily dropped beers with less than 5 
# reviews and beers with missing abv from the dataset. 

# Bug: the shiny app currently crashes if a user enters certain special characters 
# (e.g. "[" or "(") in text fields due to functionality of str_detect. 
# If I update this app with new data I'll address this too.

# To run this app locally, you'll need to install the latest versions 
# of the packages ggvis, shiny, feather, Hmisc, stringr, and dplyr.

library(ggvis)
library(Hmisc)
library(dplyr)
library(stringr)
library(feather)
library(shiny)

all_beers = read_feather("df_beer.feather")

axis_vars <- c(
    "Number of Reviews" = "beer_num_reviews",
    "Overall Score" = "beer_overall",
    "Aroma Score" = "beer_aroma",
    "Appearance Score" = "beer_appearance",
    "Palate/Mouthfeel Score" = "beer_palate",
    "Taste Score" = "beer_taste",
    "Beer ABV" = "beer_abv"
)

ui = shinyUI(fluidPage(

    # Application title
    titlePanel("Beer Explorer"),
    fluidRow(
        column(3,
               wellPanel(
                   h4("Filter"),
                   sliderInput("reviews", "Minimum number of reviews on Beer Advocate",
                               0, 1000, 25, step = 25),
                   sliderInput("abv", "Beer ABV", 0, 41, value = c(5, 41),
                               sep = "", step = .5),
                   sliderInput("score", "Overall Score",
                               1, 5, value = c(1,5), step = .1),
                   selectInput("style", "Beer Style (104 options)",
                               c("All", 
                                 "Altbier",
                                 "American Stout",
                                 "American Adjunct Lager",
                                 "American Amber / Red Ale",
                                 "American Amber / Red Lager",
                                 "American Barleywine",
                                 "American Black Ale",
                                 "American Blonde Ale",
                                 "American Brown Ale",
                                 "American Dark Wheat Ale",
                                 "American Double / Imperial IPA",
                                 "American Double / Imperial Pilsner",
                                 "American Double / Imperial Stout",
                                 "American IPA",
                                 "American Malt Liquor",
                                 "American Pale Ale (APA)",
                                 "American Pale Lager",
                                 "American Pale Wheat Ale",
                                 "American Porter",
                                 "American Strong Ale",
                                 "American Wild Ale",
                                 "Baltic Porter",
                                 "Belgian Dark Ale",
                                 "Belgian IPA",
                                 "Belgian Pale Ale",
                                 "Belgian Strong Dark Ale",
                                 "Belgian Strong Pale Ale",
                                 "Berliner Weissbier",
                                 "Bière de Champagne / Bière Brut",
                                 "Bière de Garde",
                                 "Black & Tan",
                                 "Bock",
                                 "Braggot",
                                 "California Common / Steam Beer",
                                 "Chile Beer",
                                 "Cream Ale",
                                 "Czech Pilsener",
                                 "Doppelbock",
                                 "Dortmunder / Export Lager",
                                 "Dubbel",
                                 "Dunkelweizen",
                                 "Eisbock",
                                 "English Barleywine",
                                 "English Bitter",
                                 "English Brown Ale",
                                 "English Dark Mild Ale",
                                 "English India Pale Ale (IPA)",
                                 "English Pale Ale",
                                 "English Pale Mild Ale",
                                 "English Porter",
                                 "English Stout",
                                 "English Strong Ale",
                                 "Euro Dark Lager",
                                 "Euro Pale Lager",
                                 "Euro Strong Lager",
                                 "Extra Special / Strong Bitter (ESB)",
                                 "Faro",
                                 "Flanders Oud Bruin",
                                 "Flanders Red Ale",
                                 "Foreign / Export Stout",
                                 "Fruit / Vegetable Beer",
                                 "German Pilsener",
                                 "Gose",
                                 "Gueuze",
                                 "Happoshu",
                                 "Hefeweizen",
                                 "Herbed / Spiced Beer",
                                 "Irish Dry Stout",
                                 "Irish Red Ale",
                                 "Japanese Rice Lager",
                                 "Keller Bier / Zwickel Bier",
                                 "Kölsch",
                                 "Kristalweizen",
                                 "Kvass",
                                 "Lambic - Fruit",
                                 "Lambic - Unblended",
                                 "Light Lager",
                                 "Low Alcohol Beer",
                                 "Maibock / Helles Bock",
                                 "Märzen / Oktoberfest",
                                 "Milk / Sweet Stout",
                                 "Munich Dunkel Lager",
                                 "Munich Helles Lager",
                                 "Oatmeal Stout",
                                 "Old Ale",
                                 "Pumpkin Ale",
                                 "Quadrupel (Quad)",
                                 "Rauchbier",
                                 "Roggenbier",
                                 "Russian Imperial Stout",
                                 "Rye Beer",
                                 "Sahti",
                                 "Saison / Farmhouse Ale",
                                 "Schwarzbier",
                                 "Scotch Ale / Wee Heavy",
                                 "Scottish Ale",
                                 "Scottish Gruit / Ancient Herbed Ale",
                                 "Smoked Beer",
                                 "Tripel",
                                 "Vienna Lager",
                                 "Weizenbock",
                                 "Wheatwine",
                                 "Winter Warmer",
                                 "Witbier"
                               )
                   ),
                   textInput("style_text", "Beer style contains (e.g., stout)"),
                   textInput("brewery", "Brewery name contains (e.g., Founders)"),
                   textInput("name", "Beer name contains (e.g., CBS)"),
                   tags$small(paste0(
                       "Note: Beer Advocate reviews can be submitted by any user and rate",
                       " each beer from 1-5 on its aroma, appearance, palate/mouthfeel, ",
                       " taste, and overall quality. Beers with less than 5 reviews were excluded."
                   ))
               )
        ),
        column(9,
               ggvisOutput("plot1"),
               wellPanel(
                 selectInput("xvar", "X-axis variable", axis_vars, selected = "beer_num_reviews"),
                 selectInput("yvar", "Y-axis variable", axis_vars, selected = "beer_overall")),
               wellPanel(
                   span("Number of beers selected:",
                        textOutput("n_beers")
                   )
               )
        )
    )
))

server = function(input, output) {  
    
    
    # Filter the beers, returning a data frame
    beers = reactive({
        reviews = input$reviews
        abv = input$abv
        min_score = input$score[1]
        max_score = input$score[2]
        min_abv = input$abv[1]
        max_abv = input$abv[2]
        style = input$style
        style_text = input$style_text
        brewery = input$brewery
        name = input$name
        
        # Apply filters
        df = all_beers %>%
            filter(
                beer_num_reviews >= reviews,
                beer_overall >= min_score,
                beer_overall <= max_score,
                beer_abv >= min_abv,
                beer_abv <= max_abv
            ) 
        
        # Optional: filter by style
        if (style != "All") {
            df = df %>% filter(beer_style == style)
        }
        # Optional: filter by style_text
        if (!is.null(style_text) && style_text != "") {
            df = df %>% filter(str_detect(beer_style, fixed(style_text, ignore_case = T) ))
        }
        # Optional: filter by brewery
        if (!is.null(brewery) && brewery != "") {
            df = df %>% filter(str_detect(brewery_name, fixed(brewery, ignore_case = T) ))
        }
        # Optional: filter by beer name
        if (!is.null(name) && name != "") {
            df = df %>% filter(str_detect(beer_name, fixed(name, ignore_case = T) ))
        }
        
        
        df = as.data.frame(df)
        
    })
    
    # Function for generating tooltip text
    beer_tooltip = function(x) {
        if (is.null(x)) return(NULL)
        if (is.null(x$beer_beerid)) return(NULL)
        
        # Pick out the beer with this ID
        all_beers = isolate(beers())
        beer = all_beers[all_beers$beer_beerid == x$beer_beerid, ]
        
        paste0("<b>", beer$beer_name, "</b><br>",
               beer$brewery_name, "<br>",
               beer$beer_abv, "% abv"
        )
    }
    
    # 
    # A reactive expression with the ggvis plot
    # note: ggvis used to be my go-to interactive graphics package but apparently
    # the Rstudio/tidyverse team has stopped developing it. I started remaking this plot using
    # plotly but couldn't  get the tooltips the way I wanted them to be without doing
    # much more html wrangling than I want to at the moment so I stayed with ggvis.
    # I wish the Rstudio team would start working on ggvis again...
    vis = reactive({
        # Lables for axes
        xvar_name = names(axis_vars)[axis_vars == input$xvar]
        yvar_name = names(axis_vars)[axis_vars == input$yvar]

        xvar = prop("x", as.symbol(input$xvar))
        yvar = prop("y", as.symbol(input$yvar))

        beers %>%
            ggvis(x = xvar, y = yvar) %>%
            layer_points(size := 50, size.hover := 200,
                         fillOpacity := 0.2, fillOpacity.hover := 0.5,
                         key := ~beer_beerid) %>%
            add_tooltip(beer_tooltip, "hover") %>%
            add_axis("x", title = xvar_name) %>%
            add_axis("y", title = yvar_name) %>%
            set_options(width = 500, height = 500)
    })

    vis %>% bind_shiny("plot1")

    output$n_beers = renderText({ nrow(beers()) })
     }

# Run the application 
shinyApp(ui = ui, server = server)
