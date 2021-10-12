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
library(lubridate)
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

# Start with trial scrape of January 8 scrape, page 0 to create the corresponding data frame
# t_get<-GET(historical_links$url[1])
# t_html<-read_html(t_get)
# t_tables<-xml_find_all(t_html, "//table")
# t_list<-html_table(t_tables, fill = TRUE)
# t_tab<- t_list[[1]]
# colnames(t_tab)<-c("report.date", "worksite", "location", "potential.exposure.dates")
# write.csv(t_tab, "~//data_lab//covid_worksite_exposure//historical_notcleaned.csv", row.names = FALSE)

historical_notcleaned<-read.csv("~//data_lab//covid_worksite_exposure//historical_notcleaned.csv")
#base data frame with data from page one Jan 8

historical_links$stamps<- strtrim(historical_links$timestamp, 8)
#get rid of the indicators within the time stamp, this will facilitate finding the correct urls for the different pages

url_wayback<- "https://web.archive.org/web/" 
#part one of the link for the wayback machine
url_davis<- "/https://campusready.ucdavis.edu/potential-exposure"
#original url of the website

for (i in historical_links$stamps){
  d<- paste0(url_wayback, i, url_davis)
  for(j in 0:12){ 
    url<-paste0(d, "?page=", j)
    print(url)
    a <-GET(url)
    b<-read_html(a)
    x_tables<- xml_find_all(b, "//table")
    exp_list<- html_table(x_tables, fill = TRUE) 
    if (length(exp_list)>=1){
      covid_df_page<- exp_list[[1]]
      colnames(covid_df_page)<-c("report.date", "worksite", "location", "potential.exposure.dates")
      #add the data from this page to the existing dataframe
      historical_notcleaned<-rbind.data.frame(historical_notcleaned, covid_df_page)
      }
    }
}



# Inspecting outcasts -----------------------------------------------------

outcasts<- historical_links[27:33,] #Links that did not give back any data.
#Notes: this links have only one page, therefore calling ?page=0 actually takes you to a different date
#so to work with this I wrote a loop for these dates only, but it could definitely be incorporated easily 
#into the original loop
historical_outcasts<- read.csv("~//data_lab//covid_worksite_exposure//historical_notcleaned.csv")
# usind this trial data again (above it was historical_notcleaned) to get a base with correct names for binding 
# next loop data frames

for (v in outcasts$stamps){
  d<- paste0(url_wayback, v, url_davis)
  print(d)
  a <-GET(d)
  b<-read_html(a)
  x_tables_o<- xml_find_all(b, "//table")
  exp_list_o<- html_table(x_tables_o, fill = TRUE) 
  covid_df_page<- exp_list_o[[1]]
  colnames(covid_df_page)<-c("report.date", "worksite", "location", "potential.exposure.dates")
  historical_outcasts<-rbind.data.frame(historical_outcasts, covid_df_page)
}

historical_cleaning<- read.csv("~//data_lab//covid_worksite_exposure//historical_data.csv")#read csv of the historical data


historical_cleaning<- rbind.data.frame(historical_cleaning, historical_outcasts) #binding outcast data to data
# collected from previous loop

# Cleaning duplicates --------------------------------------

row.names(historical_cleaning)<-seq(length=nrow(historical_cleaning))# numbers rows correctly

historical_cleaning<- historical_cleaning[!duplicated(historical_cleaning), ]#gets rid of duplicated rows

# write.csv(historical_cleaning,"~//data_lab//covid_worksite_exposure//historical_data.csv", row.names = FALSE) #Writes csv


# Re-formatting dates -----------------------------------------------------