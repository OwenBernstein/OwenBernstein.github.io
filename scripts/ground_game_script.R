
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

# Joining data

popvote_state$state <- state.abb[match(popvote_state$state, state.name)]
poll_state$state <- state.abb[match(poll_state$state, state.name)]

dat <- popvote_state %>% 
  full_join(poll_state %>% 
              filter(weeks_left > 3 & weeks_left < 8) %>% 
              group_by(year,party,state) %>% 
              summarise(avg_poll=mean(avg_poll)),
            by = c("year" ,"state")) %>%
  left_join(demog %>%
              select(-c("total")),
            by = c("year" ,"state"))

# Creating lagged data

change_data <- dat %>%
  group_by(state) %>%
  mutate(Asian_change = Asian - lag(Asian, order_by = year),
         Black_change = Black - lag(Black, order_by = year),
         Hispanic_change = Hispanic - lag(Hispanic, order_by = year),
         Indigenous_change = Indigenous - lag(Indigenous, order_by = year),
         White_change = White - lag(White, order_by = year),
         Female_change = Female - lag(Female, order_by = year),
         Male_change = Male - lag(Male, order_by = year),
         age20_change = age20 - lag(age20, order_by = year),
         age3045_change = age3045 - lag(age3045, order_by = year),
         age4565_change = age4565 - lag(age4565, order_by = year),
         age65_change = age65 - lag(age65, order_by = year)
  )

# Creating demographics and poll model

clean_dat <- change_data %>% 
  drop_na() %>% 
  filter(party == "democrat")

poll_dem_mod <- lm(D_pv2p ~ avg_poll + Asian_change + Black_change + Hispanic_change + Female_change, clean_dat)


# Recreating ad spending and polls model

clean_campaign <- ad_campaigns %>% 
  mutate(date = mdy(air_date)) %>% 
  mutate(month = as.numeric(substr(date, 6, 7))) %>% 
  mutate(year = as.numeric(substr(date, 1, 4)))

month_spend_mod <- clean_campaign %>% 
  group_by(cycle, state, party) %>% 
  filter(month == 9 | month == 10) %>%
  mutate(month_cost = sum(total_cost)) %>% 
  ungroup() %>% 
  inner_join(poll_state, by = c("party", "year", "state")) %>% 
  inner_join(popvote_state, by = c("state", "year")) %>% 
  select(state, year, party, weeks_left, avg_poll, total_cost, R_pv2p, D_pv2p, month_cost) %>% 
  unique()

month_spend_dem <- month_spend_mod %>%
  filter(party == "democrat") %>% 
  select(- total_cost) %>% 
  filter(weeks_left > 3 & weeks_left < 8) %>% 
  group_by(state, year) %>%
  mutate(avg_poll = mean(avg_poll)) %>% 
  select(year, state, party, avg_poll, D_pv2p, month_cost) %>% 
  unique() %>% 
  arrange(state)

month_spend_dem_mod <- lm(D_pv2p ~ avg_poll + month_cost, month_spend_dem)

# Creating ad spending, demographics, and polls model

full_mod_dat <- month_spend_dem %>% 
  select(state, year, party, month_cost) %>% 
  full_join(change_data, by = c("year", "state", "party")) %>% 
  drop_na()

ad_poll_dem_mod <- lm(D_pv2p ~ avg_poll + month_cost + Asian_change + Black_change + Hispanic_change + Female_change, full_mod_dat)


stargazer(month_spend_dem_mod, poll_dem_mod, ad_poll_dem_mod,
          title = "Pooled Models with Polls, Ad Spending, and Demographics",
          out = "../OwenBernstein.github.io/images/star_test.html")

# Out of sample prediction full mod

all_years <- seq(from=2000, to=2012, by=4)
outsamp_dflist <- lapply(all_years, function(year){
  true_dem <- unique(full_mod_dat$D_pv2p[full_mod_dat$year == year])
  
  if (year >= 2000) {
    
    ad_poll_dem_mod_ <- lm(D_pv2p ~ avg_poll + month_cost + Asian_change + Black_change + Hispanic_change + Female_change,
                          data = full_mod_dat[full_mod_dat$year != year,])
    pred_dem_full <- predict(ad_poll_dem_mod_, full_mod_dat[full_mod_dat$year == year,])
  } else {
    
    pred_dem_full < NA
  }
  
  cbind.data.frame(year, 
                   full_mod_margin = (pred_dem_full - true_dem),
                   full_winner_correct = (pred_dem_full > 50) == (true_dem > 50))
  
})
outsamp_df <- do.call(rbind, outsamp_dflist)
full_mod_margin <- colMeans(abs(outsamp_df[2]), na.rm=T)
full_mod_correct <- colMeans(outsamp_df[3], na.rm=T)

# Out of sample prediction for poll and dem mod

all_years <- seq(from=1996, to=2016, by=4)
outsamp_dflist <- lapply(all_years, function(year){
  true_dem <- unique(clean_dat$D_pv2p[clean_dat$year == year])
  
  if (year >= 1996) {
    
    poll_dem_mod_ <- lm(D_pv2p ~ avg_poll + Asian_change + Black_change + Hispanic_change + Female_change,
                           data = clean_dat[clean_dat$year != year,])
    pred_poll_dem <- predict(poll_dem_mod_, clean_dat[clean_dat$year == year,])
  } else {
    
    pred_poll_dem < NA
  }
  
  cbind.data.frame(year, 
                   poll_dem_mod_margin = (pred_poll_dem - true_dem),
                   poll_dem_winner_correct = (pred_poll_dem > 50) == (true_dem > 50))
  
})
outsamp_df <- do.call(rbind, outsamp_dflist)
dem_poll_margin <- colMeans(abs(outsamp_df[2]), na.rm=T)
dem_poll_correct <- colMeans(outsamp_df[3], na.rm=T)

# Creating gt table

stats <- data.frame(
  row.names = c("full_poll_mod", "dem_poll_mod"),
  model = c("Polls, Ad Spending and Demographics",
            "Polls and Demographics"),
  margins = c(
    full_mod_margin,
    dem_poll_margin
  ),
  correct_pred = c(
    full_mod_correct,
    dem_poll_correct
  )
)

poll_dem_spend_gt <- gt(stats) %>% 
  tab_header(title = "Out of Sample Prediction",
             subtitle = "Models Using Polls, Ad Spending, and Demographics") %>% 
  cols_label(model = "Model",
             margins = "Average Prediction Error",
             correct_pred = "Correct Prediction Percentage") %>% 
  fmt_number(columns = 2:3,
             decimals = 2)

gtsave(data = poll_dem_spend_gt, path = "images", filename = "poll_dem_spend_gt.png")

# Predicting 2020

demog_2020 <- subset(demog, year == 2018)
demog_2020 <- as.data.frame(demog_2020)
rownames(demog_2020) <- demog_2020$state
demog_2020 <- demog_2020[state.abb, ]


demog_2020_change <- demog %>%
  filter(year %in% c(2016, 2018)) %>%
  group_by(state) %>%
  mutate(
    Asian_change = Asian - lag(Asian, order_by = year),
    Black_change = Black - lag(Black, order_by = year),
    Hispanic_change = Hispanic - lag(Hispanic, order_by = year),
    Indigenous_change = Indigenous - lag(Indigenous, order_by = year),
    White_change = White - lag(White, order_by = year),
    Female_change = Female - lag(Female, order_by = year),
    Male_change = Male - lag(Male, order_by = year),
    age20_change = age20 - lag(age20, order_by = year),
    age3045_change = age3045 - lag(age3045, order_by = year),
    age4565_change = age4565 - lag(age4565, order_by = year),
    age65_change = age65 - lag(age65, order_by = year)
  ) %>%
  filter(year == 2018)

predict_polls <- polls_2020 %>% 
  select(poll_id, state, answer, end_date, pct) %>% 
  mutate(end_date = mdy(polls_2020$end_date)) %>% 
  filter(end_date > ymd("2020-09-01") & end_date < ymd("2020-10-07")) %>% 
  filter(answer == "Biden" | answer == "Trump") %>% 
  group_by(state, answer) %>% 
  summarise(avg_poll = mean(pct)) %>% 
  filter(!(state %in% c(""))) %>% 
  filter(answer == "Biden")

predict_polls$state <- state.abb[match(predict_polls$state, state.name)]

newdata <- predict_polls %>% 
  full_join(demog_2020_change, by = "state")

predictions <- data.frame(predict(poll_dem_mod, newdata))

state_dem_vs <- predictions %>% 
  mutate(state = newdata$state) %>% 
  mutate(dem_vs = predict.poll_dem_mod..newdata.) %>% 
  mutate(winner = ifelse(dem_vs > 50, "Biden", "Trump")) %>% 
  drop_na() %>% 
  select(state, dem_vs, winner)

state_dem_vs$state <- state.name[match(state_dem_vs$state, state.abb)]

statebin_map <- state_dem_vs %>% 
  ggplot(aes(state = state, fill = fct_relevel(winner, "Biden", "Trump"))) +
  geom_statebins() +
  theme_statebins() +
  labs(title = "2020 Presidential Election Prediction Map",
       subtitle = "Using Polls and Demographics",
       fill = "") +
  scale_fill_manual(values=c("steelblue2", "indianred"), breaks = c("Biden", "Trump"))

ggsave(path = "images", filename = "poll_dem_predict.png", height = 6, width = 10)

# Predicting 2020 with surge 


predict(mod_demog_change, newdata = demog_2020_change) +
  (1.28-0.64)*demog_2020$Hispanic

predictions_2 <-
  data.frame(
    predict(poll_dem_mod, newdata) - (2.19 * 0.05) * demog_2020$Asian - (0.01 *
                                                                           0.05) * demog_2020$Black - (0.06 *
                                                                                                         0.05) * demog_2020$Hispanic - (1.09 * 0.05)*demog_2020$Female
  )

state_dem_vs_2 <- predictions_2 %>% 
  mutate(state = newdata$state) %>% 
  mutate(dem_vs = predictions_2$predict.poll_dem_mod..newdata.....2.19...0.05....demog_2020.Asian...) %>% 
  mutate(winner = ifelse(dem_vs > 50, "Biden", "Trump")) %>% 
  drop_na() %>% 
  select(state, dem_vs, winner)

state_dem_vs_2$state <- state.name[match(state_dem_vs_2$state, state.abb)]

statebin_map_2 <- state_dem_vs_2 %>% 
  ggplot(aes(state = state, fill = fct_relevel(winner, "Biden", "Trump"))) +
  geom_statebins() +
  theme_statebins() +
  labs(title = "2020 Presidential Election Prediction Map",
       subtitle = "Using Polls and Decreased Demographic Effects",
       fill = "") +
  scale_fill_manual(values=c("steelblue2", "indianred"), breaks = c("Biden", "Trump"))

ggsave(path = "images", filename = "surge_predict.png", height = 6, width = 10)


