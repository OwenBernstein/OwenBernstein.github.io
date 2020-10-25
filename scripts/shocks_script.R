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

# Making Covid data

covid_clean <- covid %>% 
  mutate(submission_date = mdy(submission_date)) %>% 
  mutate(month = as.numeric(substr(submission_date, 6, 7))) %>% 
  filter(month > 7) %>% 
  group_by(state) %>% 
  mutate(avg_new_case = sum(new_case)) %>% 
  mutate(avg_new_death = sum(new_death)) %>% 
  select(state, avg_new_death, avg_new_case) %>% 
  unique()

covid_clean$state <- state.name[match(covid_clean$state, state.abb)]

covid_data <- covid_clean %>% 
  inner_join(pop, by = c("state" = "NAME")) %>% 
  group_by(state) %>% 
  mutate(avg_per_cap_cases = avg_new_case/CENSUS2010POP * 100000) %>% 
  mutate(avg_per_cap_deaths = avg_new_death/CENSUS2010POP * 100000) %>% 
  ungroup() %>% 
  mutate(average_cases = mean(avg_new_case)/mean(CENSUS2010POP) * 100000) %>% 
  mutate(average_deaths = mean(avg_new_death)/mean(CENSUS2010POP) * 100000) %>% 
  arrange(desc(avg_per_cap_deaths))

# Making country covid data

covid_19_deaths <- covid_data %>% 
  ggplot(aes(state = state, fill = avg_per_cap_deaths)) +
  geom_statebins() +
  theme_statebins() +
  labs(title = "COVID-19 Deaths Per Capita Since August",
       fill = "Deaths") +
  scale_fill_gradient(high = "indianred", low = "steelblue2")

ggsave(path = "images", filename = "country_covid.png", height = 6, width = 10)

# Making battleground states covid graph

dat <- covid_data %>% 
  filter(state %in% c("Florida", "Wisconsin", "Pennsylvania", "Georgia", "North Carolina", "Arizona", "Michigan"))

battleground_covid <- dat %>% 
  ggplot(aes(x = reorder(state, -avg_per_cap_deaths), y = avg_per_cap_deaths)) +
  geom_bar(stat = "identity", fill = "steelblue2") + 
  labs(title = "Recent COVID-19 Deaths in Battleground States",
       x = "",
       y = "Deaths per 100,000 Since August") +
  theme_clean() +
  geom_hline(yintercept = dat$average_deaths, lwd = 2, lty = 2, col = "indianred")

ggsave(path = "images", filename = "battelground_covid.png", height = 6, width = 10)



