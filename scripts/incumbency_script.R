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

# Reading in data 

econ <- read.csv("data/econ.csv")
local <- read.csv("data/local.csv")
avgpoll_time <- read.csv("data/pollavg_1968-2016 (1).csv")
avgpoll_time_state <- read.csv("data/pollavg_bystate_1968-2016 (1).csv")
polls_2020 <- read.csv("data/polls_2020.csv")
popvote <- read.csv("data/popvote_1948-2016.csv")
popvote_state <- read.csv("data/popvote_bystate_1948-2016.csv")
grant_state <- read.csv("data/fedgrants_bystate_1988-2008.csv") 


grant_state$year_type <- paste(grant_state$state_year_type, grant_state$state_year_type2)
grant_state$year_type_3 <- gsub("swing + nonelection NA", "Swing State, Nonelection Year", grant_state$year_type)
grant_state$year_type_3 <- gsub("swing + election year swing state\n (successor election year)", "Swing State, Election Year \n (Successor)", grant_state$year_type)
grant_state$year_type_3 <- gsub("core + nonelection NA", "Core State Nonelection Year", grant_state$year_type)
grant_state$year_type <- gsub("swing + nonelection NA", "Swing State, Nonelection Year", grant_state$year_type)
grant_state$year_type <- gsub("swing + nonelection NA", "Swing State, Nonelection Year", grant_state$year_type)


grant_state$year_type <- recode(grant_state$year_type, "swing + nonelection NA" = "Swing State, Nonelection Year",
       "swing + election year swing state\n(successor election year)" = "Swing State, Election Year \n (Successor)",
       "swing + election year swing state\n(incumbent re-election year)" = "Swing State, Election Year \n (Incumbent)",
       "core + nonelection NA" = "Core State, Nonelection Year",
       "core + election NA" = "Core State, Election Year")

# Making graph of grant data

grant_bars <- grant_state %>%
  filter(year_type != "NA NA") %>%
  group_by(year_type) %>%
  summarise(mean=mean(grant_mil, na.rm=T), se=sd(grant_mil, na.rm=T)/sqrt(n())) %>%
  ggplot(aes(x=year_type, y=mean, ymin=mean-1.96*se, ymax=mean+1.96*se)) +
  coord_flip() +
  geom_bar(stat="identity", fill = "steelblue2") +
  geom_errorbar(width=.2) +
  xlab("") +
  ylab("Federal Grant Spending (Millions of Dollars)") +
  theme_clean() + 
  theme(axis.title = element_text(size=20),
        axis.text = element_text(size=15))

ggsave(path = "images", filename = "federal_grants_bar.png", height = 4, width = 8)
