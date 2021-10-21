# GOAL :Scrape the data collected from Internet Archive and obtain + clean the work site exposure data collected.

#Internet Archive website: https://web.archive.org/web/*/https://campusready.ucdavis.edu/potential-exposure

# Set-up ------------------------------------------------------------------
library(dplyr)
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

# ucdavis_archive<- GET(link)##Fetch the website


# URL data frame building and cleaning ------------------------------------

# Used the wayback-scraper tool that utilizes the command line to access and scrpe the links of the
# calendar page that includes the URLs to the 'sreenshots'
# more info here: https://pypi.org/project/wayback-scraper/
# wayback-scraper -u http://campusready.ucdavis.edu/potential-exposure -o json (command line)

historical_links_json<- fromJSON(file = "~//data_lab//covid_worksite_exposure//wayback_scraper.json") 
# reads json that contains the links
# 
# historical_links<- lapply(historical_links_json, function(play)
#   {
#   data.frame(matrix(unlist(play), ncol=3, byrow = T))
# })
# creates the data frame with 3 columns corresponding to each variable from the json and 36 rows corresponding
# to the URLs

# 
# historical_links<- do.call(rbind, historical_links) #binds the data frames built with the previous line of code
# 
# colnames(historical_links)<-names(historical_links_json[[1]][[1]]) #renames the columns to correct name from firs json object names
# rownames(historical_links)<- NULL # gets rid of unnecessary row names


# Modifying and running code from scrape_exposure_data.R ------------------

# Start with trial scrape of January 8 scrape, page 0 to create the corresponding data frame
# t_get<-GET(historical_links$url[1])
# t_html<-read_html(t_get)
# t_tables<-xml_find_all(t_html, "//table")
# t_list<-html_table(t_tables, fill = TRUE)
# t_tab<- t_list[[1]]
# colnames(t_tab)<-c("report.date", "worksite", "location", "potential.exposure.dates")
# write.csv(t_tab, "~//data_lab//covid_worksite_exposure//historical_notcleaned.csv", row.names = FALSE)

# historical_notcleaned<-read.csv("~//data_lab//covid_worksite_exposure//historical_notcleaned.csv")
#base data frame with data from page one Jan 8

# historical_links$stamps<- strtrim(historical_links$timestamp, 8)
#get rid of the indicators within the time stamp, this will facilitate finding the correct urls for the different pages

# url_wayback<- "https://web.archive.org/web/" 
#part one of the link for the wayback machine
# url_davis<- "/https://campusready.ucdavis.edu/potential-exposure"
#original url of the website

# for (i in historical_links$stamps){
#   d<- paste0(url_wayback, i, url_davis)
#   for(j in 0:12){ 
#     url<-paste0(d, "?page=", j)
#     print(url)
#     a <-GET(url)
#     b<-read_html(a)
#     x_tables<- xml_find_all(b, "//table")
#     exp_list<- html_table(x_tables, fill = TRUE) 
#     if (length(exp_list)>=1){
#       covid_df_page<- exp_list[[1]]
#       colnames(covid_df_page)<-c("report.date", "worksite", "location", "potential.exposure.dates")
#       #add the data from this page to the existing dataframe
#       historical_notcleaned<-rbind.data.frame(historical_notcleaned, covid_df_page)
#       }
#     }
# }
# 


# Inspecting outcasts -----------------------------------------------------

# outcasts<- historical_links[27:33,] #Links that did not give back any data.

#Notes: this links have only one page, therefore calling ?page=0 actually takes you to a different date
#so to work with this I wrote a loop for these dates only, but it could definitely be incorporated easily 
#into the original loop
# historical_outcasts<- read.csv("~//data_lab//covid_worksite_exposure//historical_notcleaned.csv")
# usind this trial data again (above it was historical_notcleaned) to get a base with correct names for binding 
# next loop data frames

# for (v in outcasts$stamps){
#   d<- paste0(url_wayback, v, url_davis)
#   print(d)
#   a <-GET(d)
#   b<-read_html(a)
#   x_tables_o<- xml_find_all(b, "//table")
#   exp_list_o<- html_table(x_tables_o, fill = TRUE) 
#   covid_df_page<- exp_list_o[[1]]
#   colnames(covid_df_page)<-c("report.date", "worksite", "location", "potential.exposure.dates")
#   historical_outcasts<-rbind.data.frame(historical_outcasts, covid_df_page)
# }

historical_cleaning<- read.csv("~//data_lab//covid_worksite_exposure//historical_data.csv")#read csv of the historical data


# historical_cleaning<- rbind.data.frame(historical_cleaning, historical_outcasts) #binding outcast data to data
# collected from previous loop

# Cleaning duplicates --------------------------------------

# row.names(historical_cleaning)<-seq(length=nrow(historical_cleaning))# numbers rows correctly

# historical_cleaning<- historical_cleaning[!duplicated(historical_cleaning), ]#gets rid of duplicated rows

# write.csv(historical_cleaning,"~//data_lab//covid_worksite_exposure//historical_data.csv", row.names = FALSE) #Writes csv


# Re-formatting dates -----------------------------------------------------

#Standardize the dates in the report.date and potential.exposure.dates columns
#EXAMPLE OF DATE PARSING:
#parse_date_time(c('30-Sep', '09-24', '10/01/2021'), orders=c('%d-%b', '%m-%d', '%d/%m/%Y'))
#EXAMPLE OF ADDING A YEAR TO A DATE WITH 0000 FOR THE YEAR:
#my_date %m+% years(2021)


possible.formats<-c('%d-%b', '%m-%d', '%m/%d/%Y')

parsed.report.date<-parse_date_time(historical_cleaning$report.date, possible.formats)

for (i in 1:length(parsed.report.date)){
  if (format(parsed.report.date[i], '%Y') == '0000'){
    parsed.report.date[i]<-parsed.report.date[i] %m+% years(2021)
  }
}

#Exposure Date Parsing

for (i in 1:length(historical_cleaning$potential.exposure.dates)){
  split.dates<-unlist(strsplit(historical_cleaning$potential.exposure.dates[i], ' - '))
  if (length(split.dates)==2){
    historical_cleaning$start[i]<-split.dates[1]
    historical_cleaning$end[i]<-split.dates[2]
  }else{
    historical_cleaning$start[i]<-split.dates[1]
    historical_cleaning$end[i]<-split.dates[1]
  }
}

parsed.start.date<-parse_date_time(historical_cleaning$start, possible.formats)

for (i in 1:length(parsed.start.date)){
  if (format(parsed.start.date[i], '%m') == '12'){
    parsed.start.date[i]<-parsed.start.date[i] %m+% years(2020)
  }
  if (format(parsed.start.date[i], '%Y') == '0000'){
    parsed.start.date[i]<-parsed.start.date[i] %m+% years(2021)
  }
}

parsed.end.date<-parse_date_time(historical_cleaning$end, possible.formats)

for (i in 1:length(parsed.end.date)){
  if (format(parsed.end.date[i], '%m') == '12'){
    parsed.end.date[i]<-parsed.end.date[i] %m+% years(2020)
  }
  if (format(parsed.end.date[i], '%Y') == '0000'){
    parsed.end.date[i]<-parsed.end.date[i] %m+% years(2021)
  }
}

historical_cleaning$standard.report.date<-parsed.report.date
historical_cleaning$start<-parsed.start.date
historical_cleaning$end<-parsed.end.date


#code should output all_hist_exposures variable with the data de-duplicated
all_hist_exposures<-historical_cleaning[!duplicated(historical_cleaning), ] #there were none

# Amending Historical and Current Data ------------------------------------

# Grab code from scrape_exposure_data.R and to gram matched and merge it with historical data

all_exposures<-read.csv('./data/exposures.csv')


all_exposures_2<-rbind(all_hist_exposures, all_exposures)


#################################################################################################################################
# TO BE DONE WITH BOUND DATA
# Name matching section ---------------------------------------------------
# load the building dictionary file (it's tab separated, not sure why/how, but we'll roll with it... thanks excel?)
building_dictionary<-read.csv("./data/building_dictionary.csv", sep=",")

# make a table of campus name variants
building_footprints <- st_read("./data/UC_Davis_Building_Footprints_2021-08-18.geojson")

campus_target_names<-building_footprints$arcgisDBObase_bldg_database_12_2017Building_Name

campus_name_variants<-c(
  building_footprints$arcgisDBObase_bldg_database_12_2017Official_Long,
  building_footprints$arcgisDBObase_bldg_database_12_2017Abbrev_Short,
  building_footprints$arcgisDBObase_bldg_database_12_2017FDX_Code,
  building_footprints$arcgisDBObase_building_footprintsNAME_LC
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
  x=all_exposures_2,
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

#add the campus_building column to the all_hist_exposures data set
all_exposures_3<-merge(
  x=all_exposures_2, 
  y=dictionary_join,
  by="worksite") 

#remove the repeated columns
all_exposures_3<-all_exposures_3[,c(1:7, 15)]
names(all_exposures_3)<-c("worksite", "report_date", "location", "potential_exposure_dates", "start", "end", "standardized_exposure_dates", "campus_building")

all_exposures_3<-all_exposures_3[!duplicated(all_exposures_3), ]

# Join with Campus Buildings GEOJSON --------------------------------------

#join the campus exposures data to the campus buildings layer. 

#The "campus_building" column in the exposure dataframe should match the "arcgisDBObase_bldg_database_12_2017Building_Name" column in the campus building dataset. There are many building name variations in the campus layer, so make sure you match on the correct one.

#read geojson
footprints <- st_read("./data/UC_Davis_Building_Footprints_2021-08-18.geojson")

#isolate building names and geometries
geom <- footprints[,c("arcgisDBObase_bldg_database_12_2017Building_Name", "geometry")]

#merge geometries onto all_exposures, all.x=TRUE so we keep all the exposures but unmatched building names have empty geometry 
combined <- merge.data.frame(all_exposures_3, geom, by.x = "campus_building", by.y = "arcgisDBObase_bldg_database_12_2017Building_Name", all.x = TRUE)

#separate into matched and unmatched building names
matched <- combined[st_is_empty(combined$geometry) == FALSE, ]
unmatched <- combined[st_is_empty(combined$geometry) == TRUE, ]
# unmatched<-distinct(unmatched, campus_building, worksite, report_date, location, potential_exposure_dates, .keep_all= TRUE)
#write the unmatched table to a .csv so we can fix them in the building dictionary
write.csv(unmatched, "./data/unmatched_buildings.csv", row.names = FALSE)


#write to geojson to get formatting that leaflet can use
st_write(matched, "./mapinput.geojson", delete_dsn = TRUE)


#convert to txt file so we can edit the raw text
file.rename("./mapinput.geojson", "./mapinput.txt")

#read new text file into R
txt <- readtext("./mapinput.txt")

#adds javascript formatting
js <- paste0("var exposures = ", txt$text)

#write to js file
#writeLines(js, "~/GitHub/covid_worksite_exposure/docs/exposure_data.js")
writeLines(js, "./docs/exposure_data.js")

#may want to add code to delete already existing mapinput files if we are running this repeatedly

paste0(
  "Number Of Buildings Unmatched: ", 
  dim(unmatched)[1]
)
unmatched[, c(2,4)]

# Write exposures csv -----------------------------------------------------

all_exposures_2<-all_exposures_2[(order(as.Date(all_exposures_2$standard.report.date, format="%m/%d/%Y"))),]
write.csv(x=all_exposures_2, file="./data/exposures.csv", row.names = FALSE)
