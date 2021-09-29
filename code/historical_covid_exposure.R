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



# Initial fetch (website per day). ----------------------------------------

##I'll have it do a scrapping of each link of the calendar that initially shows up for the internet archive website and 
##then I'll modify the function that Michele used for the scrapping of scrape_exposure_data.R
link<- "https://web.archive.org/web/*/https://campusready.ucdavis.edu/potential-exposure"
ucdavis_archive<- GET("https://web.archive.org/web/*/https://campusready.ucdavis.edu/potential-exposure")##Fetch the website

archive_html<- read_xml(ucdavis_archive) ##Reads the html content of the website


# https://stackoverflow.com/questions/26631511/scraping-javascript --------

setwd("C:/Program Files/phantomjs-2.1.1-windows/bin")

# render HTML from the site with phantomjs
# 
# writeLines(sprintf("var page = require('webpage').create();
# page.open('%s', function () {
#     console.log(page.content); //page source
#     phantom.exit();
# });", link))
#  # ,con="scrape.js"
# system("phantomjs scrape.js > scrape.html", intern = TRUE)
# # extract the content you need
# pg <- read_xml("scrape.html")
# pg %>% html_nodes("#utime") %>% html_text()


# library(RSelenium)
# 
# url
# 
# system('docker run -d -p 4445:4444 selenium/standalone-chrome') 
# remDr <- remoteDriver(remoteServerAddr = "localhost", port = 4445L, browserName = "chrome")
# remDr$open()
# remDr$navigate(link)
# 
# writeLines(sprintf("var page = require('webpage').create();
# page.open('%s', function () {
#     console.log(page.content); //page source
#     phantom.exit();
# });", link), con="scrape.js")
# 
# system("phantomjs scrape.js > scrape.html", intern = T)
# 
# # extract the content you need
# pg <- read_html("scrape.html")
# pg %>% html_nodes("#utime") %>% html_text() 
# requires ^^ docker and i don't want to install it until I try the one avobe this

# https://blog.brooke.science/posts/scraping-javascript-websites-in-r/#javascript-webscraping-in-r