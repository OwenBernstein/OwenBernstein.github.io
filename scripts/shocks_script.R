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

covid_19_cases <- covid_data %>% 
  ggplot(aes(state = state, fill = avg_per_cap_cases)) +
  geom_statebins() +
  theme_statebins() +
  labs(title = "COVID-19 Cases Per Capita Since August",
       fill = "Cases") +
  scale_fill_gradient(high = "indianred", low = "steelblue2")


covid_country <- covid_19_cases + covid_19_deaths

ggsave(path = "images", filename = "country_covid.png", height = 6, width = 10)

# Making battleground states covid graph

dat <- covid_data %>% 
  filter(state %in% c("Florida", "Wisconsin", "Pennsylvania", "Georgia", "North Carolina",
                      "Arizona", "Michigan", "Ohio", "New Hampshire"))

battleground_covid <- dat %>% 
  ggplot(aes(x = reorder(state, -avg_per_cap_deaths), y = avg_per_cap_deaths)) +
  geom_bar(stat = "identity", fill = "steelblue2") + 
  labs(title = "Battleground COVID-19 Deaths",
       x = "",
       y = "Deaths per 100,000 Since August") +
  theme_clean() +
  geom_hline(yintercept = dat$average_deaths, lwd = 2, lty = 2, col = "indianred") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

battleground_covid_cases <- dat %>% 
  ggplot(aes(x = reorder(state, -avg_per_cap_cases), y = avg_per_cap_cases)) +
  geom_bar(stat = "identity", fill = "steelblue2") + 
  labs(title = "Battleground COVID-19 Cases",
       x = "",
       y = "Cases per 100,000 Since August") +
  theme_clean() +
  geom_hline(yintercept = dat$average_cases, lwd = 2, lty = 2, col = "indianred") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

battleground_covid_graph <- battleground_covid_cases + battleground_covid

ggsave(path = "images", filename = "battleground_covid.png", height = 6, width = 10)

# Measuring Effect on Polls

polls <- polls_2020 %>% 
  select(poll_id, state, answer, end_date, pct) %>% 
  mutate(end_date = mdy(polls_2020$end_date)) %>% 
  filter(end_date > ymd("2020-08-01") & end_date < ymd("2020-10-17")) %>% 
  filter(answer == "Biden" | answer == "Trump") %>% 
  mutate(date = floor_date(end_date, "1 week")) %>% 
  group_by(answer, date) %>% 
  mutate(nat_poll = mean(pct)) %>%
  ungroup() %>% 
  group_by(state, answer, date) %>% 
  mutate(avg_poll = mean(pct)) %>% 
  filter(answer == "Trump") %>% 
  filter(state %in% c("Florida", "Wisconsin", "Pennsylvania", "Georgia", "North Carolina",
                      "Arizona", "Michigan", "Ohio", "New Hampshire")) %>% 
  select(state, answer, date, nat_poll, avg_poll) %>% 
  unique()
 
covid_week <- covid %>% 
   select(submission_date, state, new_death, new_case) %>% 
   mutate(submission_date = mdy(submission_date)) %>% 
   filter(submission_date > ymd("2020-08-01") & submission_date < ymd("2020-10-17")) %>% 
   mutate(date = floor_date(submission_date, "1 week")) %>% 
   group_by(state, date) %>% 
   summarize(new_death = sum(new_death),
             new_case = sum(new_case))

covid_week$state <- state.name[match(covid_week$state, state.abb)]

dat_2 <- covid_week %>% 
  filter(state %in% c("Florida", "Wisconsin", "Pennsylvania", "Georgia", "North Carolina",
                      "Arizona", "Michigan", "Ohio", "New Hampshire")) %>% 
  full_join(polls, by = c("state", "date")) %>% 
  select(-answer) %>% 
  mutate(state_poll_chng = avg_poll - lag(avg_poll, order_by = date)) %>% 
  mutate(nat_poll_chng = nat_poll - lag(nat_poll, order_by = date)) %>% 
  mutate(poll_chng = state_poll_chng - nat_poll_chng)

death_trends <- dat_2 %>% 
  ggplot(aes(log(new_death), poll_chng)) +
  geom_point() +
  facet_wrap(~ state) +
  geom_smooth(method = "lm", se = F) +
  theme_minimal() +
  labs(y = "Weekly Change in Polls",
       x = "Weekly New Covid Deaths")

case_trends <- dat_2 %>% 
  ggplot(aes(log(new_case), poll_chng)) +
  geom_point() +
  facet_wrap(~ state) +
  geom_smooth(method = "lm", se = F) +
  theme_minimal() +
  labs(y = "Weekly Change in Polls",
       x = "Weekly New Covid Cases")

covid_trends <- case_trends / death_trends

ggsave(path = "images", filename = "covid_polls.png", height = 10, width = 10)


