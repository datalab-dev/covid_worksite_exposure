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
library(sf)
library(readtext)

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


base_url<-"https://campusready.ucdavis.edu/potential-exposure"

exposure_website <- GET(base_url) 
exposure_html<- read_html(exposure_website)  

# How many pages of data are there?
#extract the node with the last page number = the one that codes the "next" button
last_page_href<-xml_find_all(exposure_html, "//li[contains(@class, 'pager__item pager__item--next')]")[[1]]

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

#write the scraped exposure data to a csv without the row numbers
write.csv(x=all_exposures, file="./data/exposures.csv", row.names = FALSE)

## STEPS to scrape newest data- 1) replace the file name on the first line of this section with the correct
# file location on your computer 2) run scrape_exposure function. 3) Use the function as written above, replacing
# only the file destination with the correct one once again (the last variable). If anything does not run smoothly make sure that
# the page0, page1, and file_destination are all in quotes. 


# Name matching section ---------------------------------------------------

# load the building dictionary file (it's tab separated, not sure why/how, but we'll roll with it... thanks excel?)
building_dictionary<-read.csv("./data/building_dictionary.csv", sep=",")

# make a table of campus name variants
building_footprints <- st_read("./data/UC_Davis_Building_Footprints_2021-08-18.geojson")

campus_target_names<-building_footprints$arcgisDBObase_bldg_database_12_2017Building_Name

campus_name_variants<-c(
  building_footprints$arcgisDBObase_bldg_database_12_2017Official_Long,
  building_footprints$arcgisDBObase_bldg_database_12_2017Abbrev_Short,
  building_footprints$arcgisDBObase_bldg_database_12_2017FDX_Code
  )

#a dataframe with the name variations and what the targe (official) name should be
campus_names<-cbind.data.frame(
  campus_target_names, 
  campus_name_variants
  )

#removing the lines with blanks - because if there's an NA in either column, we don't really want it
campus_names<-na.omit(campus_names)
names(campus_names)<-names(building_dictionary)

#add the campus names to the dictionary names
building_dictionary<-rbind(building_dictionary, campus_names)

#join the exposure data and the building dictionary 
dictionary_join<-merge(
  x=all_exposures,
  y=building_dictionary,
  by.x="worksite",
  by.y="variation",
  all.x = TRUE
)

#update the NAs to match the worksite name
campus_building<-dictionary_join$target

for (i in 1:length(campus_building)){
  if (is.na(campus_building[i])){
    campus_building[i]<-dictionary_join$worksite[i]
  }
}

dictionary_join$campus_building<-campus_building

#add the campus_building column to the all_exposures dataset
all_exposures<-merge(
  x=all_exposures, 
  y=dictionary_join,
  by="worksite")

#remove the repeated columns
all_exposures<-all_exposures[,c(1:4, 9)]
names(all_exposures)<-c("worksite", "report_date", "location", "potential_exposure_dates", "campus_building")



# Date Parsing ------------------------------------------------------------

#use the potential_exposure_dates column to create a start and end column. If there is just one date (it's not a range of dates), the start and end should match. 

#the colums MUST be called "start" and "end" and have the format 2021-09-13 (use dashes, not slashes)

#subset first dates in table as start dates
start <- substr(all_exposures$potential_exposure_dates, 1, 5)

#add year
for(i in 1:length(start)){
  start[i] <- paste0("2021-", start[i])
}

#add start column to df
all_exposures$start <- start

#create empty list for end dates
end <- character()

#check if there is only one date -> start and end day the same, otherwise subset second date
for(i in 1:nrow(all_exposures)){
  if(nchar(all_exposures$potential_exposure_dates[i]) == 5){
    end[i] <- substr(all_exposures$potential_exposure_dates[i], 1, 5)
  }
  else{
    end[i] <- substr(all_exposures$potential_exposure_dates[i], 10, nchar(all_exposures$potential_exposure_dates))
  }
}

#add year
for(i in 1:length(end)){
  end[i] <- paste0("2021-", end[i])
}

#add end column to df
all_exposures$end <- end


# Join with Campus Buildings GEOJSON --------------------------------------

#join the campus exposures data to the campus buildings layer. 

#The "campus_building" column in the exposure dataframe should match the "arcgisDBObase_bldg_database_12_2017Building_Name" column in the campus building dataset. There are many building name variations in the campus layer, so make sure you match on the correct one.

#read geojson
footprints <- st_read("./data/UC_Davis_Building_Footprints_2021-08-18.geojson")

#isolate building names and geometries
geom <- footprints[,c("arcgisDBObase_bldg_database_12_2017Building_Name", "geometry")]

#merge geometries onto all_exposures, all.x=TRUE so we keep all the exposures but unmatched building names have empty geometry 
combined <- merge.data.frame(all_exposures, geom, by.x = "campus_building", by.y = "arcgisDBObase_bldg_database_12_2017Building_Name", all.x = TRUE)

#separate into matched and unmatched building names
matched <- combined[st_is_empty(combined$geometry) == FALSE, ]
unmatched <- combined[st_is_empty(combined$geometry) == TRUE, ]

#write the unmatched table to a .csv so we can fix them in the building dictionary
write.csv(unmatched, "./data/unmatched_buildings.csv")


#write to geojson to get formatting that leaflet can use
st_write(matched, "./mapinput.geojson", delete_dsn = TRUE)


#convert to txt file so we can edit the raw text
file.rename("./mapinput.geojson", "./mapinput.txt")

#read new text file into R
txt <- readtext("./mapinput.txt")

#adds javascript formatting
js <- paste0("var exposures = ", txt$text)

#write to js file
writeLines(js, "~/GitHub/covid_worksite_exposure/map/exposure_data.js")

#may want to add code to delete already existing mapinput files if we are running this repeatedly

paste0(
  "Number Of Buildings Unmatched: ", 
  dim(unmatched)[1]
  )
