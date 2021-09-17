# covid_worksite_exposure
Scraping and visualizing the UC Davis Potential Worksite Exposure Reporting (AB 685) data

# Team

**Coding:**

[Michele Tobias](https://github.com/MicheleTobias), DataLab Geospatial Data Scientist

[Elijah Stockwell](https://github.com/elistockwell), DataLab Student Employee

[Erika Lopez](https://github.com/erklopez), DataLab Student Employee

[Jared Joseph](https://github.com/Epsian), DataLab Graduate Student Researcher


**Documentation Editing:**

[Pamela Reynolds](https://github.com/PLNReynolds), DataLab Associate Director


**Advising on Text Matching:**

Tyler Shoemaker, DataLab PostDoc

Nick Ulle, DataLab Data Scientist

Carl Stahmer, DataLab Executive Director


# Background
Data made available for the public, whether for policy reporting or other purposes, is often presented in periodically updated tables on a website. Here we demonstrate how a toolchain of webscraping, text processing, and interactive visualization can be applied to aid data interpretation and generate new insights.

For this case study, we are using the temporal and spatial data presented in the [the UC Davis Potential Worksite Exposure Reporting (AB 685)](https://campusready.ucdavis.edu/potential-exposure). [California Assebly Bill 685 (AB685)](https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB685) requires employers to notify employees of potential worksite exposures to COVID-19 to the geographic scale of individual buildings. This dataset exploration allows us to demonstrate many principles of data cleaning, analysis, visual representation, and interpretation that we regularly teach in DataLab workshops.

The data tables on the Potential Worksite Exposure Reporting website list the name of the building with a potential exposure and the range of dates the building had the potential exposure. However, this tabular presentation can be challenging for a potentially affected individual or community member to understand both the immediate and broader temporal and spatial patterns present in the data. For example, the list of dozens of building names might give the impression that there is a larger affected area than actual because the density and spatial relationships aren't readily apparent in the data table. If you were unfamiliar with the southwest corner of campus, you might not realize that Valley Hall and Vet Med 3A are next door to each other, or that the Center for Neuroscience is across I-80 (east of the main campus) and not at all near Valley Hall or Vet Med 3A.

To better demonstrate the spatial and temporal patterns in this dataset, we developed an interactive web map with a timeline slider. The web map component allows users to customize the scale and extent (the view) of the data. The timeline allows users to see potential worksite exposures on a particular date, rather than looking at all of the data at once. 


# Workflow
The workflow to assemble this web map required several steps: webscraping, cleaning, standardization, and mapping.

## Scrape the data
The [the UC Davis Potential Worksite Exposure Reporting (AB 685)](https://campusready.ucdavis.edu/potential-exposure) data is publicly available webpage with exposure data from the last 14 days presented as a table with ten rows per page. This is what we call a "living dataset" with new exposures continually being collected and added to the dataset. Each day, data older than 14 days expires and is no longer available on the web portal. To gather this data from the web we need to first programmatically read the webpage to assess the number of pages of data on any given day, then build the URL for each page of data, and finally scrape the table from each of those URLs. The data scraped from each page is then added to a .csv file that contains all the data scraped from previous days. Having more than 14 days worth of data allows us to better understand spatial and temporal patterns in potential worksite exposures on campus.

**Possible later upgrade:** For a more comprehensive visualization, data could be scraped prior to the current project start date (mid August 2021) from the Internet Archive.

## Data Cleaning
Once we assemble the data, we need to clean and format it. For our visualization, we need to join the exposures data to a building footprint spatial data layer produced by the department of Campus Planning. We also need standardize start and end dates for each potential exposure record.

### Standardizing Building Names
The building names in the webportal dataset are not always consistent with the official campus building names. For example, "Activities and Recreation Center" is the official name of the campus fitness center, but the UC Davis AB-685 dataset includes names like "ARC" and "Activities and Recreation Center (ARC)". A standard table join that relies on an exact match will fail on these variations, so we had to write code to match these variations with the official campus building names. First, we added building name variations (official and shortened names) as separate columns to create a "building dictionary" dataset. Our code then searches through all of the name columns and when it finds a match, the record is programmatically labeled with the corresponding official building name. When there is no match to an official building name, the join with the spatial data later fails and we can identify and fix those mismatches by hand.

When we need to fix a building name by hand, we enter the variant and the official name of the building into the building dictionary CSV file and re-run the code. This workflow is time consuming and not ideal. It relies on our staff to interpret what the report intended, based on their personal experience of campus. Sometimes it's clear, like for "Tercero Dining Commons", but other times it's less clear, like "Physical Plant." Sometimes, the data refers to a group of buildings, such as "The Green." In that case, our process requires us to pick one building in the group, which artificially adds specificity to the record; however, if we applied the record to all the buildings in the group, we might be over-representing the record spatially leading viewers to inaccurately assume a greater exposure risk than actual.

**For your data:** To ensure consistency in data collection and data development, implement a controlled vocabulary for columns with a restricted list of possible entries. We recommend you select one representation for each unique level of a categorical dataset. For example, if you are recording the type of candy you could set the vocabulary as "M&Ms" and "Good & Plenty", and not a combination of "M and Ms", "M&Ms", "Good and Plenty", and "Good&Plenty." Controlled vocabularly would not, however, be appropriate for continuous data or responses that can take on any value, such as the weight of each type of candy (1.3 or 100.783 pounds) or interview transcripts.

**Possible later upgrade:** Ideally a fuzzy matching would be used on the building names to automatically match building names to a standard. This would reduce the amount of hands-on time updating the building dictionary to handle building names that don't match the campus database.


### Standardizing Start & End Dates
Working with temporal data, specifically dates, can pose additional challegnes for data cleaning and alignment. The dates of potential exposure in scraped dataset appear as a string containing either a single date or two dates (a start and end) separated by an end of line character and a dash. The tool that creates the timeline feature on our web map requires separate start and end columns, so we had to write code to parse the data into two separate dates, and then format them into a standard date format for our javascript tool.

**For your data:** To keep your data tidy and make it easier to work with, ensure that each column in your dataset contains only one piece of information. Instead of a date range, it is better to have separate columns (start, end) in the dataset. If you ever needed to display these pieces of data in one string, you can use a concatenate function to do that. Parsing a string into separate pieces is a lot more difficult than combining strings.

**For your data:** Excel is a handy tool for data creation and viewing tablular data, but beware when opening a dataset with dates in Excel. Excel automatically formats dates and can reformat and alter your data in ways you aren't expecting.

## Spatial Data
The spatial data in the scraped dataset (building names), is not immediately usable in a map. We, as humans, understand that these names represent a location, but for a computer to place them on a map in relation to other locations we need to represent these locations in a different way. The tool we chose to use understands spatial data as a series of points, each of which has a latitude and longitude. Polygons, such as our building footprints, are represented as a list of points corresponding to building corners. The campus buildings data already exists in this format, so we used table joins to match the records in our scraped data to the campus buildings spatial data using the official building names present in both datasets. After the join, each of our scraped exposure records has a building footprint associated with it.

The web map requires the data to be in geojson format, but wrapped in a javascript variable declaration so the javascript functions can read it. Our R script outputs this  specific format for the webmap, but we also save a plain geojson file in case we need it for troubleshooting in a separate desktop GIS program.

## Web Map
We built the web map interface using a javascript library called Leaflet. Leaflet provides an interactive map window with panning and zooming that can display background data from a tile service (we used Stamen's Toner tiles) and overlay it with spatial vector data, such as our building footprints that contains information about potential exposures.  

For this exercise we wanted to represent the temporal relationships in the data in addition to the spatial (map) relationships. We used a timeline to show the affected buildings one day at a time. To add the timeline feature, we used a plugin that extends Leaflet's functionality, called [Leaflet.Timeline](https://skeate.dev/Leaflet.timeline/).  Leaflet.Timeline reads the start and end columns from our dataset and displays each polygon when the timeline slider reaches the appropriate day. 

**For your data:** When deciding how to visualize your own data, consider what aspects or relationships in the data you want to communicate to your audience and how those can best be represented. For example, in our webmap we wanted to clearly draw attention to the buildings turning on and off. Making them red could be a good choice, but red might impart a negative connotation and could be hard to see on monitors and by individuals with color display and perception deficiencies, so we decided to use the Aggie gold color. 

**Possible later upgrade:** Having annotations on the timeline for events that could correlate with exposures, such as move-in or the start of classes, could be helpful in understanding the factors contributing to the patterns present in the data.


# Limitations & Cautions for Interpreting these Data
DataLab has made every effort to represent this data with fidelity to the original source, however, we do not intend for this visualization to be a replacement for the official [the UC Davis Potential Worksite Exposure Reporting (AB 685)](https://campusready.ucdavis.edu/potential-exposure) website. We do not have access to the source data informing the webportal and are limited to using the publicaly presented data on the portal.

Furthermore, it is important to note that the interactive map contains presence data (not presence-absence data), meaning it only represents known cases and doesn't have information about where an exposure did NOT occur. Just because a building isn't indicated, doesn't mean it hasn't had a potential exposure. Additionally, this visualization does not tell us the degree of exposure risk for any given location, simply that there was an exposure.

Because the original data does not use a controlled vocabulary restricted to the official campus building names, it is possible that there may be inaccuracies in the spatial representation. We will correct these as we become aware of them, and we encourage you to alert us if you notice any discrepancies.

# More Information & Bug Reporting
If you'd like more information, please contact DataLab at datalab@ucdavis.edu or visit our [website](https://datalab.ucdavis.edu/).

To report errors or suggest improvements, [report an issue on our GitHub repository](https://github.com/datalab-dev/covid_worksite_exposure) or email us.