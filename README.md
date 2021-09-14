# covid_worksite_exposure
Scraping and visualizing the UC Davis Potential Worksite Exposure Reporting (AB 685) data

# Team
Dr. [Michele Tobias](https://github.com/MicheleTobias), DataLab Geospatial Data Scientist

[Elijah Stockwell](https://github.com/elistockwell), DataLab Geospatial Student Employee

[Erika Lopez](https://github.com/erklopez), DataLab Student Employee


# Project Description
The goal of this project is to scrape and visualize the [the UC Davis Potential Worksite Exposure Reporting (AB 685)](https://campusready.ucdavis.edu/potential-exposure) data to help people understand and interpret the spatial and temporal data posted on the website.

The data tables on the Potential Worksite Exposure Reporting site list the building with a potential exposure and a date range. From this presentation, it can be difficult to understand both the temporal and spatial patterns present in the data. Looking at a list of a dozen buildings with potential exposures might seem like a lot of buildings because the density and spatial relationships aren't readily apparent. For example, if you were unfamiliar with the southwest corner of campus, you might not realize that Valley Hall and Vet Med 3A are nextdoor to each other or that the Center for Neuroscience is across I-80, east of the main campus. 

Our curiosity about the spatial and temporal patterns in the data led the DataLab team to build this visualization. It also provides a lovely example of many principles of data cleaning, analysis, visual representation, and interpretation that we regularly teach in our workshops.

To visualize this dataset, we chose to use an interactive web map with a timeline slider. The web map component allows users to customize the scale and exent (the view) of the data. The timeline allows users to see potential worksite exposures on a particular date, rather than looking at all of the data at once. 


# Workflow
The workflow to assemble this web map required several steps.

## Scrape the data
The [the UC Davis Potential Worksite Exposure Reporting (AB 685)](https://campusready.ucdavis.edu/potential-exposure) data is publically available on thieir website, presented as a table with ten rows per page for the last 14 days. Each day, data expires and is no longer available. To scrape this data, we needed to read the webpage to assess the number of pages on any given day, build the URL for each page of data, and then scrape the table from each URL.  The new data is then added to a .csv file that contains data we scraped on previous days. Having more than 14 days's worth of data allows us to better understand spatial patterns in the data.

## Data Cleaning

## Spatial Data
The spatial data in this dataset, the building names, is not immediately usable in a map. We, as humans, understand these names represent a location, but for a computer to place them on a map in relation to other locations, we need to represent these locations in a different way.
Join exposure data to the campus buildings spatial data

## Web Map
Add the spatial exposures data to the webmap



limitations of the covid workplace data viz:
* matching multi-building complexes like "The Green", we had to pick one building footprint (maybe we can merge by name later)
* not all names in the workplace exposure data can be matched to a building - can't tell what they meant, or the building doesn't exist in the campus map yet (because it's still under construction, etc.) 
* this is presence data (not presence-absence), meaning it only represents known cases and doesn't have information about where covid is NOT detected; just because a building isn't indicated, doesn't mean it doesn't have the virus present

lessons: 
* use a controlled vocabulary so you don't end up with lots of variations of the same words
* don't use Excel, especially when dates are involved - autoformatting can make the dates unreadable or just not what you expect
