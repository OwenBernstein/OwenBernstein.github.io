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
ad_creative <- read_csv("data/ad_creative_2000-2012.csv")
ad_campaigns <- read_csv("data/ad_campaigns_2000-2012.csv")
ads_2020 <- read_csv("data/ads_2020.csv")

# Graph of spending over time 
  
clean_campaign <- ad_campaigns %>% 
  mutate(date = mdy(air_date)) %>% 
  mutate(month = as.numeric(substr(date, 6, 7))) %>% 
  mutate(year = as.numeric(substr(date, 1, 4)))

ad_spending_time <- clean_campaign %>% 
  filter(year %in% c(2000, 2004, 2008, 2012), month > 7) %>%
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

# Changing state names

clean_campaign$state <- recode(clean_campaign$state,
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

# Modeling using polling and full cycle ad spending

total_spend_mod <- clean_campaign %>% 
  group_by(cycle, state, party) %>% 
  mutate(total_cost = sum(total_cost)) %>% 
  ungroup() %>% 
  inner_join(avgpoll_time_state, by = c("party", "year", "state")) %>% 
  inner_join(popvote_state, by = c("state", "year")) %>% 
  select(state, year, party, weeks_left, avg_poll, total_cost, R_pv2p, D_pv2p) %>% 
  unique()

poll_dem <- total_spend_mod %>% 
  filter(weeks_left > 5 & weeks_left < 11) %>% 
  filter(party == "democrat")

poll_rep <- total_spend_mod %>% 
  filter(weeks_left > 5 & weeks_left < 11) %>% 
  filter(party == "republican")

poll_dem_mod <- lm(D_pv2p ~ avg_poll, poll_dem)
poll_rep_mod <- lm(R_pv2p ~ avg_poll, poll_rep)
poll_spend_dem <- lm(D_pv2p ~ avg_poll + total_cost, poll_dem)
poll_spend_rep <- lm(R_pv2p ~ avg_poll + total_cost, poll_rep)

# Creating models for last months of ad spending

month_spend_mod <- clean_campaign %>% 
  group_by(cycle, state, party) %>% 
  filter(month == 9 | month == 10) %>%
  mutate(month_cost = sum(total_cost)) %>% 
  ungroup() %>% 
  inner_join(avgpoll_time_state, by = c("party", "year", "state")) %>% 
  inner_join(popvote_state, by = c("state", "year")) %>% 
  select(state, year, party, weeks_left, avg_poll, total_cost, R_pv2p, D_pv2p, month_cost) %>% 
  unique()

month_spend_dem <- month_spend_mod %>% 
  filter(weeks_left > 5 & weeks_left < 11) %>% 
  filter(party == "democrat")

month_spend_rep <- month_spend_mod %>% 
  filter(weeks_left > 5 & weeks_left < 11) %>% 
  filter(party == "republican")

month_spend_dem_mod <- lm(D_pv2p ~ avg_poll + month_cost, month_spend_dem)
month_spend_rep_mod <- lm(R_pv2p ~ avg_poll + month_cost, month_spend_rep)

# Creating summaries of the models

sm_poll_dem <- summary(poll_dem_mod)
sm_poll_rep <- summary(poll_rep_mod)
sm_total_spend_dem <- summary(poll_spend_dem)
sm_total_spend_rep <- summary(poll_spend_rep)
sm_month_spend_dem <- summary(month_spend_dem_mod)
sm_month_spend_rep <- summary(month_spend_rep_mod)

stats <- data.frame(
  row.names = c("poll_rep", "total_spend_rep",  "month_spend_rep", "poll_dem", "total_spend_dem", "month_spend_dem"),
  model = c("Polls Only Republican",
            "Polls and Total Ad Spending Republican",
            "Polls and Last 2 Months Ad Spending Republican",
            "Polls Only Democrat",
            "Polls and Total Ad Spending Democrat",
            "Polls and Last 2 Months Ad Spending Democrat"),
  r_squared = c(
    sm_poll_rep$r.squared,
    sm_total_spend_rep$r.squared,
    sm_month_spend_rep$r.squared,
    sm_poll_dem$r.squared,
    sm_total_spend_dem$r.squared,
    sm_month_spend_dem$r.squared
  ),
  mse = c(
    sqrt(mean(sm_poll_rep$residuals ^ 2)),
    sqrt(mean(sm_total_spend_rep$residuals ^ 2)),
    sqrt(mean(sm_month_spend_rep$residuals ^ 2)),
    sqrt(mean(sm_poll_dem$residuals ^ 2)),
    sqrt(mean(sm_total_spend_dem$residuals ^ 2)),
    sqrt(mean(sm_month_spend_dem$residuals ^ 2))
  )
)

# Making gt table of model

ad_models_gt <- gt(stats) %>% 
  tab_header(title = "State Election Models Using Polls and Ad Spending") %>% 
  cols_label(model = "Model",
             r_squared = "R Squared",
             mse = "MSE") %>% 
  fmt_number(columns = 2:3,
             decimals = 2)

gtsave(data = ad_models_gt, path = "images", filename = "ad_models_gt.png")
