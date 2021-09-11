#GOAL: 
# 1. scrape the data from the UC Davis Potential Worksite Exposure Reporting (AB 685) report online
# 2. clean the data 
    # a. make the building names match the campus shapefile names
    # b. make separate columns for start and end dates for potential exposure
# 3. remove duplicates
# 4. write a csv with the exposure data
# 5. join the exposure data to the campus building data & export a geojson file

#Worksite Exposure URL: https://campusready.ucdavis.edu/potential-exposure

#Campus Building data URL: https://data-ucda.opendata.arcgis.com/datasets/ucdavis-campus-buildings/explore?location=38.534593%2C-121.792150%2C13.71 

# Setup -------------------------------------------------------------------

library(httr)
library(jsonlite)
library(xml2)
library(rvest)
library(stringr)

setwd("C:\\Users\\mmtobias\\Documents\\GitHub\\covid_worksite_exposure")

# Fetching the website page 0----------------------------------------------------

# i_exposure_website0 <- GET("https://campusready.ucdavis.edu/potential-exposure?page=0&order=field_report_date&sort=desc") ## Fetch the website page 0

# i_data0<- read_html(i_exposure_website0)  ##Read the html of the website, from rvest

# i_tables0<- xml_find_all(i_data0, "//table") ## searches for tables on the website 

# i_cov0<- html_table(i_tables0, fill = TRUE) ## recreates a table from the website

# i_covid_df0<- i_cov0[[1]] ## takes the first page of the table

##This section is only used to create initial csv

# Fetching website page 1 -------------------------------------------------

# i_exposure_website1<- GET("https://campusready.ucdavis.edu/potential-exposure?page=1&order=field_report_date&sort=desc")
## Fetch the website page 1

# i_data1<- read_html(i_exposure_website1)  ##Read the html of the website

# i_tables1<- xml_find_all(i_data1, "//table") ## searches for tables on the website

# i_cov1<- html_table(i_tables1, fill = TRUE) ## recreates a table from the website

# i_covid_df1<- i_cov1[[1]] ## takes the first page of the table


# covid_worksite_ex<- rbind(i_covid_df0, i_covid_df1) ##Binding the two pages of content

# covid_worksite_ex<- covid_worksite_ex[!duplicated(covid_worksite_ex), ] ## Getting rid of duplicates

# colnames(covid_worksite_ex)<-c("report.date", "worksite", "location", "potential.exposure.dates") ##renaming columns


# write.csv(covid_worksite_ex, "~//data_lab//covid_worksite_exposure//covid_worksite_ex.csv", row.names = FALSE)

##This section is only used to create initial csv


# Scrapping Function ----------------------------------------------------------

# covid_worksite_ex<-read.csv("C://Users//ERIKA//data_lab_//covid_worksite_exposure//data//exposures.csv") ##Importing CSV file with the previous scrapping

# 
# scrape_exposure<- function(page0, page1, file_destination){
#   exposure_website0 <- GET(page0) 
#   data0<- read_html(exposure_website0)  
#   tables0<- xml_find_all(data0, "//table") 
#   cov0<- html_table(tables0, fill = TRUE)
#   covid_df0<- cov0[[1]]
#   colnames(covid_df0)<-c("report.date", "worksite", "location", "potential.exposure.dates")
#   exposure_website1 <- GET(page1) 
#   data1<- read_html(exposure_website1)  
#   tables1<- xml_find_all(data1, "//table") 
#   cov1<- html_table(tables1, fill = TRUE)
#   covid_df1<- cov1[[1]]
#   colnames(covid_df1)<-c("report.date", "worksite", "location", "potential.exposure.dates")
#   covid_worksite_ex<- rbind(covid_df0, covid_df1, covid_worksite_ex)
#   covid_worksite_ex<- covid_worksite_ex[!duplicated(covid_worksite_ex), ]
#   write.csv(covid_worksite_ex, file_destination, row.names = FALSE) 
#   return(covid_worksite_ex)
# }
# 
#  
# scrape_exposure("https://campusready.ucdavis.edu/potential-exposure?page=0&order=field_report_date&sort=desc"
#  , "https://campusready.ucdavis.edu/potential-exposure?page=1&order=field_report_date&sort=desc", 
#  "C://Users//ERIKA//data_lab_//covid_worksite_exposure//data//exposures.csv")



# How many pages of data are there?
#extract the node with the last page number = the one that codes the "next" button
last_page_href<-xml_find_all(data0, "//li[contains(@class, 'pager__item pager__item--next')]")[[1]]

#parse the number of pages from the text; note that it's 0 indexed (numbering starts with 0)
number_pages<-as.numeric(gsub("\"", "", substr(str_split(as.character(last_page_href), "page=")[[1]][2], 1, 2)))

covid_df<-read.csv("./data/exposures.csv")

for (i in 0:number_pages){
  
  #make the URL
  url<-paste0("https://campusready.ucdavis.edu/potential-exposure?page=", i)
  print(url)
  
  exposure_website <- GET(url) 
  data<- read_html(exposure_website)  
  tables<- xml_find_all(data, "//table") 
  cov<- html_table(tables, fill = TRUE)
  covid_df_page<- cov[[1]]
  colnames(covid_df_page)<-c("report.date", "worksite", "location", "potential.exposure.dates")
  
  #add the data from this page to the existing dataframe
  covid_df<-rbind.data.frame(covid_df, covid_df_page)

  #remove the duplicates
  all_exposures<-covid_df[!duplicated(covid_df), ]
  
}

## STEPS to scrape newest data- 1) replace the file name on the first line of this section with the correct
# file location on your computer 2) run scrape_exposure function. 3) Use the function as written above, replacing
# only the file destination with the correct one once again (the last variable). If anything does not run smoothly make sure that
# the page0, page1, and file_destination are all in quotes. 


# Name matching section ---------------------------------------------------

 
## Next steps: make a name matching dictionary

#Worksite Exposure URL: https://campusready.ucdavis.edu/potential-exposure

#Campus Building data URL: https://data-ucda.opendata.arcgis.com/datasets/ucdavis-campus-buildings/explore?location=38.534593%2C-121.792150%2C13.71 


