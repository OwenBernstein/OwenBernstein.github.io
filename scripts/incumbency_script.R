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

# Observational data about incumbents

data <- popvote %>% 
  filter(incumbent == T) %>% 
  filter(candidate != "Stevenson, Adlai")

sum(data$winner) / nrow(data)

mean(data$pv2p)


# Cleaning grant data

grant_state$year_type <- paste(grant_state$state_year_type, grant_state$state_year_type2)

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

# Joining state voting and state grants

grant_state$state_abb <- recode(grant_state$state_abb,
                                       "AK" = "Alaska",
                                       "AL" = "Alabama",
                                       "AR" = "Arkansas",
                                       "AZ" = "Arizona",
                                       "CA" = "California",
                                       "CO" = "Colorado",
                                       "CT" = "Connecticut",
                                       "DC" = "District of Columbia",
                                       "DE" = "Delaware",
                                       "FL" = "Florida",
                                       "GA" = "Georgia",
                                       "HI" = "Hawaii",
                                       "IA" = "Iowa",
                                       "ID" = "Idaho",
                                       "IL" = "Illinois",
                                       "IN" = "Indiana",
                                       "KS" = "Kansas",
                                       "KY" = "Kentucky",
                                       "LA" = "Louisiana",
                                       "MA" = "Massachusetts",
                                       "MD" = "Maryland",
                                       "ME" = "Maine",
                                       "MI" = "Michigan",
                                       "MN" = "Minnesota",
                                       "MO" = "Missouri",
                                       "MS" = "Mississippi",
                                       "MT" = "Montana",
                                       "NC" = "North Carolina",
                                       "ND" = "North Dakota",
                                       "NE" = "Nebraska",
                                       "NH" = "New Hampshire",
                                       "NJ" = "New Jersey",
                                       "NM" = "New Mexico",
                                       "NV" = "Nevada",
                                       "NY" = "New York",
                                       "OH" = "Ohio",
                                       "OK" = "Oklahoma",
                                       "OR" = "Oregon",
                                       "PA" = "Pennsylvania",
                                       "RI" = "Rhode Island",
                                       "SC" = "South Carolina",
                                       "SD" = "South Dakota",
                                       "TN" = "Tennessee",
                                       "TX" = "Texas",
                                       "UT" = "Utah",
                                       "VA" = "Virginia",
                                       "VT" = "Vermont",
                                       "WA" = "Washington", 
                                       "WI" = "Wisconsin", 
                                       "WY" = "Wyoming")

state_grant_dat <- popvote_state %>% 
  select(state, year, D_pv2p, R_pv2p) %>% 
  inner_join(grant_state, by = c("state" = "state_abb", "year"))

clean_popvote <- popvote %>% 
  filter(incumbent_party == T) %>% 
  full_join(state_grant_dat, by = "year") %>% 
  filter(year >= 1984) %>% 
  arrange(state) %>% 
  select(state, year, incumbent, D_pv2p, R_pv2p, grant_mil)

# Lagging voting and grants

state_grant_dat_lag <- clean_popvote %>% 
  group_by(state) %>%
  mutate(dem_vote_chng = D_pv2p - lag(D_pv2p, default = first(D_pv2p))) %>% 
  mutate(rep_vote_chng = R_pv2p - lag(R_pv2p, default = first(R_pv2p))) %>% 
  mutate(grant_chng = (grant_mil / lag(grant_mil, default = first(grant_mil)) - 1) * 100) %>% 
  filter(incumbent == T)

# Making vote share graphs for the incumbents

vs_graph_1992 <- state_grant_dat_lag %>% 
filter(year == 1992) %>% 
  ggplot(aes(x=grant_chng, y=rep_vote_chng, label = state)) +
  geom_vline(xintercept=0, lty=2) +
  geom_hline(yintercept=0, lty=2) +
  geom_smooth(method="lm", color = "steelblue2") +
  xlab("Change in Federal Grant Spending (%)") +
  ylab("Change in Incumbent Two Party Vote Share (%)") +
  geom_text() +
  theme_classic() + 
  theme(axis.title = element_text(size=20),
        axis.text = element_text(size=15)) +
  theme_clean() +
  labs(title = "1992")

vs_graph_1996 <- state_grant_dat_lag %>% 
  filter(year == 1996) %>% 
  ggplot(aes(x=grant_chng, y=dem_vote_chng, label = state)) +
  geom_vline(xintercept=0, lty=2) +
  geom_hline(yintercept=0, lty=2) +
  geom_smooth(method="lm", color = "steelblue2") +
  xlab("Change in Federal Grant Spending (%)") +
  ylab("") +
  geom_text() +
  theme_classic() + 
  theme(axis.title = element_text(size=20),
        axis.text = element_text(size=15)) +
  theme_clean() +
  labs(title = "1996")


vs_graph_2004 <- state_grant_dat_lag %>% 
  filter(year == 2004) %>% 
  ggplot(aes(x=grant_chng, y=rep_vote_chng, label = state)) +
  geom_vline(xintercept=0, lty=2) +
  geom_hline(yintercept=0, lty=2) +
  geom_smooth(method="lm", color = "steelblue2") +
  xlab("Change in Federal Grant Spending (%)") +
  ylab("") +
  geom_text() +
  theme_classic() + 
  theme(axis.title = element_text(size=20),
        axis.text = element_text(size=15)) +
  theme_clean() +
  labs(title = "2004")

vs_graphs_incumbent <- vs_graph_1992 / vs_graph_1996 / vs_graph_2004

ggsave(path = "images", filename = "vs_graphs_incumbent.png", height = 8, width = 8)
