# Loading libraries

library(tidyverse)
library(ggplot2)
library(lubridate)
library(ggrepel)
library(ggthemes)
library(patchwork)
library(gt)
library(broom)
library(usmap)
library(janitor)
library(statebins)
library(maptools)
library(rgdal)
library(stargazer)

# Reading in data 

polls <- read.csv("data/pollavg_1968-2016 (1).csv")
poll_state <- read.csv("data/pollavg_bystate_1968-2016 (1).csv")
polls_2020 <- read.csv("data/polls_2020.csv")
popvote <- read.csv("data/popvote_1948-2016.csv")
popvote_state <- read.csv("data/popvote_bystate_1948-2016.csv")
ad_campaigns <- read_csv("data/ad_campaigns_2000-2012.csv")
ads_2020 <- read_csv("data/ads_2020.csv")
demog <- read_csv("data/demographic_1990-2018.csv")
covid <- read_csv("data/COVID-19_Cases_and_Deaths.csv")
pop <- read_csv("data/populations.csv") %>% 
  select(NAME, CENSUS2010POP)

covid_data <- covid %>% 
  mutate(submission_date = mdy(submission_date)) %>% 
  mutate(month = as.numeric(substr(submission_date, 6, 7))) %>% 
  filter(month > 8) %>% 
  group_by(state) %>% 
  mutate(avg_new_case = mean(new_case)) %>% 
  mutate(avg_new_death = mean(new_death)) %>% 
  select(state, avg_new_death, avg_new_case) %>% 
  unique()

covid_data$state <- state.name[match(covid_data$state, state.abb)]


dat <- covid_data %>% 
  inner_join(pop, by = c("state" = "NAME")) %>% 
  mutate(avg_per_cap_cases = avg_new_case/CENSUS2010POP * 100000) %>% 
  mutate(avg_per_cap_deaths = avg_new_death/CENSUS2010POP * 100000) %>% 
  ungroup() %>% 
  mutate(average_cases = mean(avg_new_case)/mean(CENSUS2010POP) * 100000) %>% 
  mutate(average_deaths = mean(avg_new_death)/mean(CENSUS2010POP) * 100000) %>% 
  arrange(desc(avg_per_cap_deaths)) %>% 
  filter(state %in% c("Florida", "Wisconsin", "Pennsylvania", "Ohio", "North Carolina", "Arizona", "Iowa")) %>% 
  mutate(avg_btg = mean(avg_new_death)/mean(CENSUS2010POP) * 100000)

barplot(height = dat$avg_per_cap_deaths, names = dat$state, las = 1, col = "steelblue2")
abline(h = mean(dat$average_deaths), col = "indianred", lty = 2, lwd = 3)

