# GOAL :Scrape the data collected from Internet Archive and obtain + clean the work site exposure data collected.

#Internet Archive website: https://web.archive.org/web/*/https://campusready.ucdavis.edu/potential-exposure

# Set-up ------------------------------------------------------------------

library(httr)
library(jsonlite)
library(xml2)
library(rvest)
library(stringr)
library(sf)
library(readtext)
library(V8)
library(plyr)
library(dplyr)
library(ggvis)
library(knitr)
library(rjson)



# Initial fetch (URLs). ----------------------------------------

##I'll have it do a scrapping of each link of the calendar that initially shows up for the internet archive website and 
##then I'll modify the function used for the scrapping of scrape_exposure_data.R

link<- "https://web.archive.org/web/*/https://campusready.ucdavis.edu/potential-exposure" #Initial link with the calendar and the 
# urls to the actual "screenshots" of the website

ucdavis_archive<- GET(link)##Fetch the website


# URL data frame building and cleaning ------------------------------------

# Used the wayback-scraper tool that utilizes the command line to access and scrpe the links of the
# calendar page that includes the URLs to the 'sreenshots'
# more info here: https://pypi.org/project/wayback-scraper/
# wayback-scraper -u http://campusready.ucdavis.edu/potential-exposure -o json (command line)

historical_links_json<- fromJSON(file = "~//data_lab//covid_worksite_exposure//wayback_scraper.json") 
# reads json that contains the links

historical_links<- lapply(historical_links_json, function(play)
  {
  data.frame(matrix(unlist(play), ncol=3, byrow = T))
})
# creates the data frame with 3 columns corresponding to each variable from the json and 36 rows corresponding
# to the URLs


historical_links<- do.call(rbind, historical_links) #binds the data frames built with the previous line of code

colnames(historical_links)<-names(historical_links_json[[1]][[1]]) #renames the columns to correct name from firs json object names
rownames(historical_links)<- NULL # gets rid of unnecessary row names


# Modifying and running code from scrape_exposure_data.R ------------------




