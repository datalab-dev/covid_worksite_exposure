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
library(lubridate)


base_url<-"https://campusready.ucdavis.edu/potential-exposure"

exposure_website <- GET(base_url) 
exposure_html<- read_html(exposure_website)  

# How many pages of data are there?
#extract the nodes called "pager_item" - there is one more of these than the number of pages (because the next button is one too)

last_page_href<-length(xml_find_all(exposure_html, "//li[contains(@class, 'pager__item')]"))

number_pages<-last_page_href-1 #-1 because there are x pages + the next button

covid_df<-read.csv("./data/exposures.csv")
#covid_df<-read.csv("./data/exposures_thursday.csv")

#covid_df<-covid_df[,1:4]

for (i in 0:(number_pages-1)){ #pages on the site are 0 indexed
  
  #make the URL
  url<-paste0("https://campusready.ucdavis.edu/potential-exposure?page=", i)
  print(url)
  
  exposure_website <- GET(url) 
  data<- read_html(exposure_website)  
  tables<- xml_find_all(data, "//table") 
  cov<- html_table(tables, fill = TRUE)
  covid_df_page<- cbind.data.frame(cov[[1]], NA, NA, NA)
  #colnames(covid_df_page)<-c("report.date", "worksite", "location", "potential.exposure.dates")
  colnames(covid_df_page)<-names(covid_df)
  
  #add the data from this page to the existing dataframe
  covid_df<-rbind.data.frame(covid_df, covid_df_page)

  #remove the duplicates - we'll need to do this AFTER we convert the dates to a standard format
  #all_exposures<-covid_df[!duplicated(covid_df), ] 
  
}


# Date formating ----------------------------------------------------------

#Standardize the dates in the report.date and potential.exposure.dates columns
  #EXAMPLE OF DATE PARSING:
    #parse_date_time(c('30-Sep', '09-24', '10/01/2021'), orders=c('%d-%b', '%m-%d', '%d/%m/%Y'))
  #EXAMPLE OF ADDING A YEAR TO A DATE WITH 0000 FOR THE YEAR:
    #my_date %m+% years(2021)

possible.formats<-c( '%d-%b','%m-%d', '%m/%d/%Y', '%m-%d-%Y', '%Y/%m/%d', '%Y-%m-%d')

#Report Date
parsed.report.date<-parse_date_time(covid_df$report.date, possible.formats)

for (j in 1:dim(covid_df)[1]){ #for each row in the covid_df dataframe
  if (is.na(covid_df[j, 7])) { #if the value in column 7 is NA
    parsed.date<-parse_date_time(covid_df$report.date[j], possible.formats) #parse the reported date
    if (
      format(parsed.date, '%Y') == '0000' && #the year is 0000
      format(Sys.Date(), '%m') == "01" &&    #today's month is January
      format(parsed.date, '%m') == "12"      #the parsed month is December
      ){
      covid_df[j,7]<-as.character(parsed.date %m+% (years(as.numeric(format(Sys.Date(), '%Y')))-years(1))) #the year for the report date is today's year minus 1
    }
    else if (format(parsed.date, '%Y') == '0000') { #the year is 0000
      covid_df[j,7]<-as.character(parsed.date %m+% years(format(Sys.Date(), '%Y')))
    }
  }
}

unmatched_dates<- setNames(data.frame(matrix(ncol = 4, nrow = 0)), c("report.date", "worksite","location", "potential.exposure.dates"))
# MAKES data frame with no rows but corresponding columns to the covid_df, used to create parsed_fail

fail_parsed_rows<-which(is.na(covid_df$standard.report.date)) ##creates list of the rows that do not parse
for (i in fail_parsed_rows){
  f<-as.data.frame(covid_df[i,])
  unmatched_dates<- rbind.data.frame(f, unmatched_dates)
  covid_df<- covid_df[-i,]
} # extracts the dates that failed to parse report date 
parsed.report.date<-na.omit(parsed.report.date)
# removes na's from parsed.report.date

# for (i in 1:length(parsed.report.date)){
#   # if (format(parsed.report.date[i], '%m') == '12'){
#   #   parsed.report.date[i]<-parsed.report.date[i] %m+% years(2020)
#   #   }
#   if (format(
#     parsed.report.date[i], '%Y') == '0000' || 
#     format(parsed.report.date[i], '%m') == '1'){
#     parsed.report.date[i]<-parsed.report.date[i] %m+% years(2022)
#   }
#   if (format(
#     parsed.report.date[i], '%Y') == '0000' || 
#     format(parsed.report.date[i], '%m') == '1'){
#     parsed.report.date[i]<-parsed.report.date[i] %m+% years(2022)
#   }
# } # Adds year to parsed report date




#Exposure Date Parsing

for (i in 1:length(covid_df$potential.exposure.dates)){
  if (is.na(covid_df$start[i])){
    split.dates<-unlist(strsplit(covid_df$potential.exposure.dates[i], ' - '))
    if (length(split.dates)==2){
      covid_df$start[i]<-format.Date(parse_date_time(split.dates[1], possible.formats), "%Y-%m-%d")
      covid_df$end[i]<-format.Date(parse_date_time(split.dates[2], possible.formats), "%Y-%m-%d")
    }else{
      covid_df$start[i]<-format.Date(parse_date_time(split.dates[1], possible.formats), "%Y-%m-%d")
      covid_df$end[i]<-format.Date(parse_date_time(split.dates[1], possible.formats), "%Y-%m-%d")
    }
  }
  
} # Splits dates



parsed.start.date<-parse_date_time(covid_df$start, possible.formats) #Parsing start date
# checking for failure to parse in start date
fail_parsed_start<-which(is.na(parsed.start.date)) ##creates list of the rows that do not parse
for (i in fail_parsed_start){
  f<-as.data.frame(covid_df[i,])
  f<-f[,1:4]
  unmatched_dates<- rbind.data.frame(f, unmatched_dates)
  covid_df<- covid_df[-i,]
  parsed.report.date<-parsed.report.date[-i] # removes the corresponding non-parsed numbers from parsed.report.date
} # extracts the dates that failed to parse start date
parsed.start.date<-na.omit(parsed.start.date)
# removes na's from parsed.start.date

# for (i in 1:length(parsed.start.date)){
#   if (format(parsed.start.date[i], '%m') == '12'){
#     parsed.start.date[i]<-parsed.start.date[i] %m+% years(2020)
#     }
#   if (format(parsed.start.date[i], '%Y') == '0000'){
#     parsed.start.date[i]<-parsed.start.date[i] %m+% years(2021)
#   }
# } # Adds year to parsed start date



parsed.end.date<-parse_date_time(covid_df$end, possible.formats) #Parsing end date
# checking for failure to parse in start date
fail_parse_end<-which(is.na(parsed.end.date)) ##creates list of the rows that do not parse
for (i in fail_parse_end){
  f<-as.data.frame(covid_df[i,])
  f<-f[,1:4]
  unmatched_dates<- rbind.data.frame(f, unmatched_dates)
  covid_df<- covid_df[-i,]
  parsed.start.date<-parsed.start.date[-i]
  parsed.report.date<-parsed.report.date[-i]
} # extracts the dates that failed to parse end date
parsed.end.date<-na.omit(parsed.end.date)
# removes na's from parsed.end.date

# for (i in 1:length(parsed.end.date)){
#   if (format(parsed.end.date[i], '%m') == '12'){
#     parsed.end.date[i]<-parsed.end.date[i] %m+% years(2020)
#     }
#   if (format(parsed.end.date[i], '%Y') == '0000'){
#     parsed.end.date[i]<-parsed.end.date[i] %m+% years(2021)
#   }
# } # Adds year to parsed end dates


# covid_df$standard.report.date<-parsed.report.date
# covid_df$start<-parsed.start.date
# covid_df$end<-parsed.end.date

unmatched_dates<-na.omit(unmatched_dates) #remove NA's at unmatched_dates that are created

write.csv(unmatched_dates,'./data/unmatched_dates.csv', row.names = FALSE) # writes csv with the rows that failed to parse

#code should output all_exposures variable with the data de-duplicated
all_exposures<-covid_df[!duplicated(covid_df[,c(2, 5:7)]), ]

# Testing date mismatch  --------------------------------------------------
# 
# covid_df<-covid_df[390:414,] # Subsets covid_df to work with smaller section
# 
# covid_2$report.date[1]<- "Sep-13"
# covid_2$potential.exposure.dates[2]<- "Sep-08 - Sep-10"
# covid_2$potential.exposure.dates[3]<- "2020-Sep-14"
# covid_2$potential.exposure.dates[24]<- "2021-09-20"
# covid_2$potential.exposure.dates[25]<- "2021-09-17 - 2021-09-19"
# covid_2$report.date[4]<- "2021-09-15"


#organizes exposures by date reported
all_exposures<-all_exposures[(order(as.Date(all_exposures$standard.report.date, format="%m/%d/%Y"))),]



# All exposures -----------------------------------------------------------
 
#code should output all_exposures variable with the data de-duplicated
all_exposures<-covid_df[!duplicated(covid_df[,c(2, 5:7)]), ]
#organizes exposures by date reported
all_exposures<-all_exposures[(order(as.Date(all_exposures$standard.report.date, format="%m/%d/%Y"))),]

#organizes exposures by date reported
all_exposures<-all_exposures[(order(as.Date(all_exposures$standard.report.date, format="%m/%d/%Y"))),]

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
all_exposures<-all_exposures[,c(1:7, 15)]
names(all_exposures)<-c("worksite", "report_date", "location", "potential_exposure_dates", "start", "end", "standardized_exposure_dates", "campus_building")



# # Date Parsing ------------------------------------------------------------
# 
# #use the potential_exposure_dates column to create a start and end column. If there is just one date (it's not a range of dates), the start and end should match. 
# 
# #the colums MUST be called "start" and "end" and have the format 2021-09-13 (use dashes, not slashes)
# 
# #subset first dates in table as start dates
# start <- substr(all_exposures$potential_exposure_dates, 1, 5)
# 
# #add year
# for(i in 1:length(start)){
#   start[i] <- paste0("2021-", start[i])
# }
# 
# #add start column to df
# all_exposures$start <- start
# 
# #create empty list for end dates
# end <- character()
# 
# #check if there is only one date -> start and end day the same, otherwise subset second date
# for(i in 1:nrow(all_exposures)){
#   if(nchar(all_exposures$potential_exposure_dates[i]) == 5){
#     end[i] <- substr(all_exposures$potential_exposure_dates[i], 1, 5)
#   }
#   else{
#     end[i] <- substr(all_exposures$potential_exposure_dates[i], 10, nchar(all_exposures$potential_exposure_dates))
#   }
# }
# 
# #add year
# for(i in 1:length(end)){
#   end[i] <- paste0("2021-", end[i])
# }
# 
# #add end column to df
# all_exposures$end <- end


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
#writeLines(js, "~/GitHub/covid_worksite_exposure/docs/exposure_data.js")
writeLines(js, "./docs/exposure_data.js")

#may want to add code to delete already existing mapinput files if we are running this repeatedly

paste0(
  "Number Of Buildings Unmatched: ", 
  dim(unmatched)[1]
  )
unmatched[, c(2,4)]
