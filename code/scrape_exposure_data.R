#GOAL: 
# 1. scrape the data from the UC Davis Potential Worksite Exposure Reporting (AB 685) report online
# 2. clean the data 
    # a. make the building names match the campus shapefile names
    # b. make separate columns for start and end dates for potential exposure
# 3. remove duplicates
# 4. write a csv with the exposure data
# 5. join the exposure data to the campus building data & export a json file

#Worksite Exposure URL: https://campusready.ucdavis.edu/potential-exposure

#Campus Building data URL: https://data-ucda.opendata.arcgis.com/datasets/ucdavis-campus-buildings/explore?location=38.534593%2C-121.792150%2C13.71 
