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

# Reading in data 

econ <- read.csv("data/econ.csv")
local <- read.csv("data/local.csv")
avgpoll_time <- read.csv("data/pollavg_1968-2016 (1).csv")
avgpoll_time_state <- read.csv("data/pollavg_bystate_1968-2016 (1).csv")
polls_2020 <- read.csv("data/polls_2020.csv")
popvote <- read.csv("data/popvote_1948-2016.csv")
popvote_state <- read.csv("data/popvote_bystate_1948-2016.csv")
grant_state <- read.csv("data/fedgrants_bystate_1988-2008.csv") 
covid_grants <- read.csv("data/covid_grants.csv") %>% 
  clean_names()
ad_creative <- read_csv("data/ad_creative_2000-2012.csv")
ad_campaigns <- read_csv("data/ad_campaigns_2000-2012.csv")

# Graph of spending over time 
  
ad_spending_time <- ad_campaigns %>% 
  mutate(date = mdy(air_date)) %>% 
  mutate(month = as.numeric(substr(date, 6, 7))) %>% 
  mutate(year = as.numeric(substr(date, 1, 4))) %>% 
  filter(year %in% c(2000, 2004, 2008, 2012), month > 7 & month < 10) %>%
  group_by(cycle, date, party) %>%
  summarise(total_cost = sum(total_cost)) %>%
  ggplot(aes(x=date, y=total_cost, color=party)) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b, %Y") +
  scale_y_continuous(labels = dollar_format()) +
  scale_color_manual(values = c("steelblue2","indianred"), name = "Party", labels = c("Democrat", "Republican")) +
  geom_line() + geom_point(size=0.5) +
  facet_wrap(cycle ~ ., scales="free") +
  xlab("") + ylab("Ad Spending") +
  theme_clean() +
  theme(axis.title = element_text(size=20),
        axis.text = element_text(size=11),
        strip.text.x = element_text(size = 20))

ggsave(path = "images", filename = "advertising spending_time.png", height = 6, width = 10)
