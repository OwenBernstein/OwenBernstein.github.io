
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

# Reading in data 

econ <- read.csv("data/econ.csv")
local <- read.csv("data/local.csv")
avgpoll_time <- read.csv("data/pollavg_1968-2016 (1).csv")
avgpoll_time_state <- read.csv("data/pollavg_bystate_1968-2016 (1).csv")
polls_2020 <- read.csv("data/polls_2020.csv")
popvote <- read.csv("data/popvote_1948-2016.csv")
popvote_state <- read.csv("data/popvote_bystate_1948-2016.csv")
ad_creative <- read_csv("data/ad_creative_2000-2012.csv")
ad_campaigns <- read_csv("data/ad_campaigns_2000-2012.csv")
ads_2020 <- read_csv("data/ads_2020.csv")
field_office_2016 <- read_csv("data/fieldoffice_2012-2016_byaddress.csv")


field_office_2016 %>% 
  filter(year == 2016) %>% 
  count(candidate)

field_office_2016 %>% 
  filter(year == 2012) %>% 
  group_by(party) %>% 
  count(candidate)

dat <- field_office_2016 %>% 
  filter(year == 2016) %>% 
  group_by(state, party) %>% 
  count(candidate) %>% 
  arrange(desc(n)) 
  
