#GOAL: 
# 1. scrape the data from the UC Davis Potential Worksite Exposure Reporting (AB 685) report online
# 2. clean the data 
    # a. make the building names match the campus shapefile names
    # b. make separate columns for start and end dates for potential exposure
# 3. remove duplicates
# 4. write a csv

#URL: https://campusready.ucdavis.edu/potential-exposure


# Setup -------------------------------------------------------------------

library(httr)
library(jsonlite)
library(xml2)
library(rvest)

# Fetching the website page 0----------------------------------------------------

exposure_website0 <- GET("https://campusready.ucdavis.edu/potential-exposure") ## Fetch the website page 0

data0<- read_html(exposure_website0)  ##Read the html of the website, from rvest

tables0<- xml_find_all(data0, "//table") ## searches for tables on the website 

cov0<- html_table(tables0, fill = TRUE) ## recreates a table from the website

covid_df0<- cov0[[1]] ## takes the first page of the table

# Fetching website page 1 -------------------------------------------------

exposure_website1<- GET("https://campusready.ucdavis.edu/potential-exposure?order=field_building_name&sort=asc&page=1")
## Fetch the website page 1

data1<- read_html(exposure_website1)  ##Read the html of the website

tables1<- xml_find_all(data1, "//table") ## searches for tables on the website

cov1<- html_table(tables1, fill = TRUE) ## recreates a table from the website

covid_df1<- cov1[[1]] ## takes the first page of the table

## Next steps: make a function to do this ^^ and then a loop to work with it everyday, I also need to
## make sure that it  deletes duplicates.
