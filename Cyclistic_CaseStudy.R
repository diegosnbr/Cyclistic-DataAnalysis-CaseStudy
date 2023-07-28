## PREPARE

#### Let's install the packages

install.packages("tidyverse")
install.packages("skimr")
install.packages("janitor")
install.packages("lubridate")
install.packages("here")

#### Loading libraries.

library("tidyverse")
library("skimr")
library("janitor")
library("lubridate")
library("here")

#### Setting the work space directory.

setwd(here())
getwd()

#### Loading the CSV files.

cyclistic_22_06 <- read_csv(here("0_Datasets/2206-2306-cyclistic-tripdata/2206-cyclistic-tripdata.csv"))
cyclistic_22_07 <- read_csv(here("0_Datasets/2206-2306-cyclistic-tripdata/2207-cyclistic-tripdata.csv"))
cyclistic_22_08 <- read_csv(here("0_Datasets/2206-2306-cyclistic-tripdata/2208-cyclistic-tripdata.csv"))
cyclistic_22_09 <- read_csv(here("0_Datasets/2206-2306-cyclistic-tripdata/2209-cyclistic-tripdata.csv"))
cyclistic_22_10 <- read_csv(here("0_Datasets/2206-2306-cyclistic-tripdata/2210-cyclistic-tripdata.csv"))
cyclistic_22_11 <- read_csv(here("0_Datasets/2206-2306-cyclistic-tripdata/2211-cyclistic-tripdata.csv"))
cyclistic_22_12 <- read_csv(here("0_Datasets/2206-2306-cyclistic-tripdata/2212-cyclistic-tripdata.csv"))
cyclistic_23_01 <- read_csv(here("0_Datasets/2206-2306-cyclistic-tripdata/2301-cyclistic-tripdata.csv"))
cyclistic_23_02 <- read_csv(here("0_Datasets/2206-2306-cyclistic-tripdata/2302-cyclistic-tripdata.csv"))
cyclistic_23_03 <- read_csv(here("0_Datasets/2206-2306-cyclistic-tripdata/2303-cyclistic-tripdata.csv"))
cyclistic_23_04 <- read_csv(here("0_Datasets/2206-2306-cyclistic-tripdata/2304-cyclistic-tripdata.csv"))
cyclistic_23_05 <- read_csv(here("0_Datasets/2206-2306-cyclistic-tripdata/2305-cyclistic-tripdata.csv"))
cyclistic_23_06 <- read_csv(here("0_Datasets/2206-2306-cyclistic-tripdata/2306-cyclistic-tripdata.csv"))

#### Creating a new frame with all the data.

cyclistic_yearlytrips_2206_2306 <- bind_rows(
  cyclistic_22_06,
  cyclistic_22_07,
  cyclistic_22_08,
  cyclistic_22_09,
  cyclistic_22_10,
  cyclistic_22_11,
  cyclistic_22_12,
  cyclistic_23_01,
  cyclistic_23_02,
  cyclistic_23_03,
  cyclistic_23_04,
  cyclistic_23_05,
  cyclistic_23_06
)

## EXPLORE

#### Now we inspect the resulting data frame.

str(cyclistic_yearlytrips_2206_2306)

## PROCESS

#### Let's change the name of the variables inside 'member_casual'.

cyclistic_yearlytrips_2206_2306 <- cyclistic_yearlytrips_2206_2306 %>%
  mutate(member_casual=recode(member_casual,
                              "member"="Subscriber",
                              "casual"="Customer")
        )

#### Same with the column 'rideable_type'.

cyclistic_yearlytrips_2206_2306 <- cyclistic_yearlytrips_2206_2306 %>%
  mutate(rideable_type=recode(rideable_type,
                              "classic_bike"="Classic Bike",
                              "electric_bike"="Electric Bike",
                              "docked_bike"="Docked Bike")
        )

#### We can see that the 'started_at' column is datetime type. In order to aggregate by year, month and day, I want to add new columns for each. 

cyclistic_yearlytrips_2206_2306 <- cyclistic_yearlytrips_2206_2306 %>%
  mutate(
    year = year(started_at),
    month = month(started_at),
    day = weekdays(started_at)
    )

#### We should add a column for the the total time elapsed in a trip, called 'trip_duration_secs'.

cyclistic_yearlytrips_2206_2306$trip_duration_secs <- as.double(
  difftime(
    cyclistic_yearlytrips_2206_2306$ended_at,
    cyclistic_yearlytrips_2206_2306$started_at,
    units = "secs")
)

#### Some trips have negative duration, because the bikes were taken out for maintenance. I'll remove negatives, and add all the data to a new frame.

clean_yearlytrips <- cyclistic_yearlytrips_2206_2306 %>%
  filter(trip_duration_secs > 0)

#### At last, we confirm nothing else needs cleanup by printing the new table.

skim_without_charts(clean_yearlytrips)

## ANALYZE

#### I'll start by taking the maximum, minimum, average and sum of total trip time in minutes, as well as percentage of total time and usage of each bike type, by each customer type.

summary_customer <- clean_yearlytrips %>%
  group_by(member_casual) %>%
    summarise(avgtime_mins=mean(trip_duration_secs)/60,
              maxtime_mins=max(trip_duration_secs)/60,
              mintime_mins=min(trip_duration_secs)/60,
              total_time_percent=sum(trip_duration_secs)/sum(clean_yearlytrips$trip_duration_secs)*100,
              total_population_percent=n()/nrow(clean_yearlytrips)*100
              )

#### Let's create another table focused on the type of bicycle, with total time spent on each and percentage of costumers using them.

summary_bicycle <- clean_yearlytrips %>%
  group_by(rideable_type, member_casual) %>%
  summarise(avgtime_mins=mean(trip_duration_secs)/60,
            maxtime_mins=max(trip_duration_secs)/60,
            mintime_mins=min(trip_duration_secs)/60,
            total_trips_percent=n()/nrow(clean_yearlytrips)*100,
            total_time_percent=sum(trip_duration_secs)/sum(clean_yearlytrips$trip_duration_secs)*100,) %>%
  arrange(rideable_type) %>%
  arrange(member_casual)

#### I also want an overview of the trips grouped by days of the week and hour, with average time and amount of each customer type.

summary_weekday <- clean_yearlytrips %>%
  group_by(day, member_casual) %>%
    summarise(number_of_rides = n(),
            avgtime_mins = mean(trip_duration_secs)
            ) %>%
  group_by(day) %>%
    mutate(number_of_rides_percent = round((prop.table(number_of_rides)*100), digits=2)
          ) %>%
  arrange(member_casual) %>%
  arrange(factor(day, levels = 
                   c('Monday',
                     'Tuesday',
                     'Wednesday',
                     'Thursday',
                     'Friday',
                     'Saturday',
                     'Sunday')))

#### I want to see an overview by hour, grouped by customer type.

summary_hour <- clean_yearlytrips %>%
  group_by(hour(started_at), member_casual) %>%
    summarise(number_of_rides = n(),
            avgtime_mins = mean(trip_duration_secs)
    ) %>%
  arrange(member_casual)

#### At last, let's see an overview by month, grouped by customer type.

summary_month <- clean_yearlytrips %>%
  group_by(month, year, member_casual) %>%
  summarise(number_of_rides = n(),
            avgtime_mins = mean(trip_duration_secs)
  ) %>%
  arrange(member_casual) %>%
  arrange(year) %>%
  arrange(month)

## EXPORTING

output_dir <- here("1_Summaries")

#### These are only the summaries.

write_csv(summary_bicycle, file.path(output_dir, "summary_bicycle.csv"))
write_csv(summary_customer, file.path(output_dir, "summary_customer.csv"))
write_csv(summary_hour, file.path(output_dir, "summary_hour.csv"))
write_csv(summary_month, file.path(output_dir, "summary_month.csv"))
write_csv(summary_weekday, file.path(output_dir, "summary_weekday.csv"))

#### This is the cleaned version of the merged data frames, which I'm using for Tableau.

write_csv(clean_yearlytrips, file.path(output_dir, "clean_tableau.csv"))