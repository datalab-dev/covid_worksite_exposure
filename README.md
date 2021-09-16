# covid_worksite_exposure
Scraping and visualizing the UC Davis Potential Worksite Exposure Reporting (AB 685) data

# Team

**Coding:**

Dr. [Michele Tobias](https://github.com/MicheleTobias), DataLab Geospatial Data Scientist

[Elijah Stockwell](https://github.com/elistockwell), DataLab Student Employee

[Erika Lopez](https://github.com/erklopez), DataLab Student Employee

[Jared Joseph](), DataLab Graduate Student Researcher


**Advising on Text Matching:**

Tyler Shoemaker

Nick Ulle

Carl Stahmer


# Project Description
The goal of this project is to scrape and visualize the [the UC Davis Potential Worksite Exposure Reporting (AB 685)](https://campusready.ucdavis.edu/potential-exposure) data to help people understand and interpret the spatial and temporal data posted on the website.

[California Assebly Bill 685 (AB685)](https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB685) requires employers to notify employees of potential worksite exposures to COVID-19 to the geographic scale of individual buildings.

The data tables on the Potential Worksite Exposure Reporting site list the building with a potential exposure and a date range. From this presentation, it can be difficult to understand both the temporal and spatial patterns present in the data. Looking at a list of a dozen buildings with potential exposures might seem like a lot of buildings because the density and spatial relationships aren't readily apparent. For example, if you were unfamiliar with the southwest corner of campus, you might not realize that Valley Hall and Vet Med 3A are nextdoor to each other or that the Center for Neuroscience is across I-80, east of the main campus. 

Our curiosity about the spatial and temporal patterns in the data led the DataLab team to build this visualization. It also provides a lovely example of many principles of data cleaning, analysis, visual representation, and interpretation that we regularly teach in our workshops.

To visualize this dataset, we chose to use an interactive web map with a timeline slider. The web map component allows users to customize the scale and exent (the view) of the data. The timeline allows users to see potential worksite exposures on a particular date, rather than looking at all of the data at once. 


# Workflow
The workflow to assemble this web map required several steps.

## Scrape the data
The [the UC Davis Potential Worksite Exposure Reporting (AB 685)](https://campusready.ucdavis.edu/potential-exposure) data is publically available on thieir website, presented as a table with ten rows per page with data for the last 14 days. Each day, data expires and is no longer available. To scrape this data, we needed to read the webpage to assess the number of pages on any given day, build the URL for each page of data, and then scrape the table from each URL.  The data scraped from each page is then added to a .csv file that contains data we scraped on previous days. Having more than 14 days's worth of data allows us to better understand spatial patterns in the data.

**Possible later upgrade:** We would like to scrape data from before our start date in mid August 2021 from the Internet Archive.

## Data Cleaning
Once we've assembed the data, we need to clean and format the data. For our visualization, we need to be able to join the exposures data to the building footprint spatial data layer produced by Campus Planning. We also need standardized start and end dates for each potential exposure record.

### Standardize Building Names
The building names in the current potential worksite exposures data are not always consistent with that campus' official building names. For example, "Activities and Recreation Center" is the official name of the campus fitness center, but the dataset includes names like "ARC" and "Activities and Recreation Center (ARC)". A standard table join that relies on an exact match will fail on these variations, so we had to implement code to try to match these with alternative names. The campus building footprint dataset has several name variations for each building, including the official name and a shorted names. Our code searches through the name variations and when it finds a match, we can lable the record with the offical building name. We also keep a list of known building name variants and the offical building name it corresponds to in a CSV file called the building dictionary and have included this data in the code as well. When the names don't match the offical building names, the join with the spatial data later will fail and we try to fix those by hand. 

When we need to fix a building name by hand, we enter the variant and the official name of the building into the building dictionary CSV file and re-run the code. This is a time-consuming and potentially error-prone process. It relies on our staff to interpret what the report intended, based on their personal experience of campus. Sometimes it's clear, like for "Tercero Dining Commons", but other times it's less clear, like "Physical Plant". Sometimes, the data refers to a group of buildings, such as "The Green". In that case, our process requires us to pick one building in the group, which artificially adds specificity to the record; however, if we applied the record to all the buildings in the group, we might be over-representing the record spatially.

**For your data:** To ensure consistency in data collection and data development, implement a controlled vocabulary for columns with a restricted list of possible entries. For example, you might want to use a contolled vocabulary with categorical data such as type of candy: "M&Ms" or "Good & Plenty"; not "M and Ms" or "Good and Plenty". However, you wouldn't want to use a contolled vocabulary for data that can take on any value such as the weight of each type of candy (1.3 or 100.783 pounds) or interview responses.

**Possible later upgrade:** We would like to implement a fuzzy matching process on the building names to automatically match building names that are slightly different than the standard. This will reduce the amount of hands-on time updating the building dictionary to handle building names that don't match the campus database.


### Standardize Start & End Dates
The dates of potential exposure take on two variations in the scraped dataset. The data is a string containing either a single date or two dates (a start and end) separated by an end of line character and a dash.  The tool that creates the timeline feature on our web map requires separate start and end columns, so we parsed the data to separate the two dates and format them into a standard date format that our javascript tool can read as a date.

**For your data:** To keep your data tidy and make it easier to work with, ensure that each column in your dataset contains only one piece of information. A better way to format the data described here would be to have separate start and end columns. If you ever needed to display these pieces of data in one string, you can use a concatenate function to do that. Parsing a string into separate pieces is a lot more difficult.

**For your data:** Excel is a handy tool for data creation and viewing tablular data, but beware when opening a dataset in Excel that contains dates. Excel automatically formats dates and can alter your data.

## Spatial Data
The spatial data in this dataset, the building names, is not immediately usable in a map. We, as humans, understand these names represent a location, but for a computer to place them on a map in relation to other locations, we need to represent these locations in a different way.  The tool we chose to use understands spatial data as a series of points, each of which has a latitude and logitude.  The campus buildings data already exists in this format, so we did a process called a table join to match the records in our exposures data to the campus buildings spatial data using the offical building name.  After the join, each of our exposure records has a building footprint associated with it.

The web map requires the data to be in geojson format, but wrapped in a javascript variable declaration, so the javascript functions can read it. Our script outputs this very specific format for the webmap, but we also save a plain geojson file in case we need it for troubleshooting in a desktop GIS program.

## Web Map
We built the web map interface using a javascript tool called Leaflet. Leaflet provides an interactive map window that can display background data from a tile service (we used Stamen's Toner tiles) and overlay it with spatial vector data, like our building footprints that contains information about potential exposures.  

We wanted to represent the temporal relationships in the data in addition to the spatial (map) relationships. To add the timeline feature, we used a plugin that extends Leaflet's functionality, called [Leaflet.Timeline](https://skeate.dev/Leaflet.timeline/).  Leaflet.Timeline reads the start and end columns from our dataset and displays each polygon when the timeline slider reaches the appropriate day. 

**For your data:** When deciding how to visualize your own data, consider what aspects of or relationships in the data you want to communicate to your audience and think about how best to represent them. For example, in our webmap, we wanted to clearly draw attention to the buildings turning on and off. Making them red could be a good choice, but red might impart a negative connotation (and might be hard to see for people with certain variations in color perception) so we decided to use a gold color. 

**Possible later upgrade:** Having annontations on the timeline for events like move-in or the start of classes could be helpful in understanding the patterns present in the data.




# Limitations & Cautions for Interpreting this Data
DataLab has made every effort to represent this data with fidelity to the original source, however, we do not intend for this visualization to be a replacement for the official [the UC Davis Potential Worksite Exposure Reporting (AB 685)](https://campusready.ucdavis.edu/potential-exposure) website.

This is presence data (not presence-absence data), meaning it only represents known cases and doesn't have information about where covid is NOT detected; just because a building isn't indicated, doesn't mean it doesn't have the virus present. 

Because the original data does not use a controlled vocabulary restricted to the official campus builing names, the spatial representation of the data may occasionally be incorrect. We will correct these as we find them.

# More Information & Bug Reporting
If you'd like more information, please contact DataLab at data@ucdavis.edu or visit our [website](https://datalab.ucdavis.edu/).

To report errors, either email us or [report an issue on our GitHub repository](https://github.com/datalab-dev/covid_worksite_exposure).





