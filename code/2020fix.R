
#Fix incorrect December 2020 dates

setwd("~/GitHub/covid_worksite_exposure-1")

df2020 <- data.frame()

covid_df<-read.csv("./data/exposures.csv")

for (i in 1:nrow(covid_df)){
  
  date <- covid_df$standard.report.date[i]
  year <- substr(date,1,4)
  
  if(year == "2020"){
    
    df2020 <- rbind(df2020, covid_df[i,]) #Create df of 2020 dates to look through
    
    #This showed that they were all supposed to be 2021 based on start and end fields
  
    covid_df$standard.report.date[i] <- paste0("2021", substr(date, 5, 11))
    
  }
  
}

write.csv(covid_df,"./data/exposures.csv")
