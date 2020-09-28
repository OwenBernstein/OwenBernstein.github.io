# loading libraries

library(tidyverse)
library(ggplot2)
library(lubridate)
library(ggrepel)
library(ggthemes)
library(patchwork)
library(gt)
library(broom)
library(caret)
library(usmap)

# Loading data

econ <- read.csv("data/econ.csv")
local <- read.csv("data/local.csv")
avgpoll_time <- read.csv("data/pollavg_1968-2016 (1).csv")
avgpoll_time_state <- read.csv("data/pollavg_bystate_1968-2016 (1).csv")
polls_2020 <- read.csv("data/polls_2020.csv")
popvote <- read.csv("data/popvote_1948-2016.csv")
popvote_state <- read.csv("data/popvote_bystate_1948-2016.csv")

# Merging national data, using code from section

nat_time_dat <- popvote %>% 
  full_join(avgpoll_time %>% 
              filter(weeks_left > 5 & weeks_left < 11) %>% 
              group_by(year,party) %>% 
              summarise(avg_support=mean(avg_support))) %>% 
  left_join(econ %>% 
              filter(quarter == 2))

# Making scatterplot of incumbent and challenger polling vs vote share

incumbents <- nat_time_dat %>% 
  filter(incumbent_party == TRUE)

challenger <- nat_time_dat %>% 
  filter(incumbent_party == FALSE)

incumbent_plot <- incumbents %>% 
  ggplot(aes(x = avg_support, y = pv)) +
  geom_point() +
  geom_smooth(method = lm, color = "steelblue") +
  geom_label_repel(label = incumbents$year, box.padding = 0.5) +
  labs(title = "Incumbent Party") +
  xlab("Average Polling Support (6 - 10 Weeks Before Election)") +
  ylab("Popular Vote Share") +
  theme_clean()

challenger_plot <- challenger %>% 
  ggplot(aes(x = avg_support, y = pv)) +
  geom_point() +
  geom_smooth(method = lm, color = "steelblue") +
  geom_label_repel(label = challenger$year, box.padding = 0.5) +
  labs(title = "Challenger Party") +
  xlab("Average Polling Support (6 - 10 Weeks Before Election)") +
  ylab("Popular Vote Share") +
  theme_clean()

# Combining scatterplots with patchwork and saving

poll_vote_plot <<- incumbent_plot + challenger_plot

ggsave(path = "images", filename = "poll_vote_plot.png", height = 4, width = 8)

# Making polls only model of national election with code from section

dat_poll     <- nat_time_dat[!is.na(nat_time_dat$avg_support),]
dat_poll_inc <- dat_poll[dat_poll$incumbent_party,]
dat_poll_chl <- dat_poll[!dat_poll$incumbent_party,]
mod_poll_inc <- lm(pv ~ avg_support, data = dat_poll_inc)
mod_poll_chl <- lm(pv ~ avg_support, data = dat_poll_chl)

# Making polls and economics model of national election with code from section

dat_plus     <- nat_time_dat[!is.na(nat_time_dat$avg_support) & !is.na(nat_time_dat$GDP_growth_qt),]
dat_plus_inc <- dat_plus[dat_plus$incumbent_party,]
dat_plus_chl <- dat_plus[!dat_plus$incumbent_party,]
mod_plus_inc <- lm(pv ~ avg_support + GDP_growth_qt, data = dat_plus_inc)
mod_plus_chl <- lm(pv ~ avg_support + GDP_growth_qt, data = dat_plus_chl)

# Evaluation of models

poll_inc <- summary(mod_poll_inc)
poll_chl <- summary(mod_poll_chl)

plus_inc <- summary(mod_plus_inc)
plus_chl <- summary(mod_plus_chl)

stats <- data.frame(
  row.names = c("poll_inc", "poll_chl", "plus_inc", "plus_chl"),
  model = c("Polls Only Incumbent",
            "Polls Only Challenger",
            "Polls and GDP Growth Incumbent",
            "Polls and GDP Growth Challenger"),
  r_squared = c(
    poll_inc$r.squared,
    poll_chl$r.squared,
    plus_inc$r.squared,
    plus_chl$r.squared
  ),
  mse = c(
    sqrt(mean(poll_inc$residuals ^ 2)),
    sqrt(mean(poll_chl$residuals ^ 2)),
    sqrt(mean(plus_inc$residuals ^ 2)),
    sqrt(mean(plus_chl$residuals ^ 2))
  )
)

# Making a gt table of the model statistics

poll_models_gt <- gt(stats) %>% 
  tab_header(title = "Poll Only and Poll and GDP Growth Models for Predicting Elections") %>% 
  cols_label(model = "Model",
             r_squared = "R Squared",
             mse = "MSE") %>% 
  fmt_number(columns = 2:3,
             decimals = 2)

gtsave(data = poll_models_gt, path = "images", filename = "poll_models_gt.png")

# Using code from section to do out-of-sample evaluation


all_years <- seq(from=1948, to=2016, by=4)
outsamp_dflist <- lapply(all_years, function(year){
  
  true_inc <- unique(nat_time_dat$pv[nat_time_dat$year == year & nat_time_dat$incumbent_party])
  true_chl <- unique(nat_time_dat$pv[nat_time_dat$year == year & !nat_time_dat$incumbent_party])
  
  if (year >= 1980) {
    ##poll model out-of-sample prediction
    mod_poll_inc_ <- lm(pv ~ avg_support, data = dat_poll_inc[dat_poll_inc$year != year,])
    mod_poll_chl_ <- lm(pv ~ avg_support, data = dat_poll_chl[dat_poll_chl$year != year,])
    pred_poll_inc <- predict(mod_poll_inc_, dat_poll_inc[dat_poll_inc$year == year,])
    pred_poll_chl <- predict(mod_poll_chl_, dat_poll_chl[dat_poll_chl$year == year,])
    
    ##plus model out-of-sample prediction
    mod_plus_inc_ <- lm(pv ~ GDP_growth_qt + avg_support, data = dat_plus_inc[dat_plus_inc$year != year,])
    mod_plus_chl_ <- lm(pv ~ GDP_growth_qt + avg_support, data = dat_plus_chl[dat_plus_chl$year != year,])
    pred_plus_inc <- predict(mod_plus_inc_, dat_plus_inc[dat_plus_inc$year == year,])
    pred_plus_chl <- predict(mod_plus_chl_, dat_plus_chl[dat_plus_chl$year == year,])
  } else {
    pred_poll_inc <- pred_poll_chl <- pred_plus_inc <- pred_plus_chl <- NA
  }
  
  cbind.data.frame(year,
                   poll_margin_error = (pred_poll_inc-pred_poll_chl) - (true_inc-true_chl),
                   plus_margin_error = (pred_plus_inc-pred_plus_chl) - (true_inc-true_chl),
                   poll_winner_correct = (pred_poll_inc > pred_poll_chl) == (true_inc > true_chl),
                   plus_winner_correct = (pred_plus_inc > pred_plus_chl) == (true_inc > true_chl)
  )
})
outsamp_df <- do.call(rbind, outsamp_dflist)
colMeans(abs(outsamp_df[2:3]), na.rm=T)
colMeans(outsamp_df[4:5], na.rm=T) ### classification accuracy

# Merging state data

state_time_dat <- popvote_state %>% 
  full_join(avgpoll_time_state %>% 
              filter(weeks_left > 5 & weeks_left < 11) %>% 
              group_by(year,party, state) %>% 
              summarise(avg_support=mean(avg_poll))) %>% 
  left_join(popvote, by = c("year", "party"))

# Making poll model for each state using map functions

state_poll     <- state_time_dat[!is.na(state_time_dat$avg_support),]
state_inc <- state_poll[state_poll$incumbent_party,]
state_chl <- state_poll[!state_poll$incumbent_party,]

state_inc_coefs <- state_inc %>%
  select(state, year, avg_support, pv) %>% 
  filter(!(state %in% c("District of Columbia", "ME-1","ME-2","NE-1","NE-2","NE-3"))) %>% 
  na.omit( ) %>%
  group_by(state) %>% 
  nest() %>%
  mutate(model = map(data, ~lm(pv ~ avg_support, data = .))) %>%
  mutate(model_sm = map(model, glance)) %>% 
  unnest(model_sm) %>% 
  select(state, r.squared)

state_chl_coefs <- state_chl %>%
  select(state, year, avg_support, pv) %>% 
  filter(!(state %in% c("District of Columbia", "ME-1","ME-2","NE-1","NE-2","NE-3"))) %>% 
  na.omit( ) %>%
  group_by(state) %>% 
  nest() %>%
  mutate(model = map(data, ~lm(pv ~ avg_support, data = .))) %>%
  mutate(model_sm = map(model, glance)) %>% 
  unnest(model_sm) %>% 
  select(state, r.squared)

# Plotting the r squared values of each of the state models in a histogram

state_models_chl <- state_chl_coefs %>% 
  ggplot(aes(r.squared)) +
  geom_histogram(fill = "steelblue") +
  geom_vline(data = state_chl_coefs, aes(xintercept = mean(r.squared), fill = "black")) +
  annotate("text", x = .4, y = 4.8, label = "Average R-Squared\n of State Models",
           color = "black", size = 4) +
  theme_clean() +
  labs(title = "State Models for Challengers")+
  xlab("R Squared Value") +
  ylab("")
  

state_models_inc <- state_inc_coefs %>% 
  ggplot(aes(r.squared)) +
  geom_histogram(fill = "steelblue") +
  geom_vline(data = state_inc_coefs, aes(xintercept = mean(r.squared), fill = "black")) +
  annotate("text", x = .58, y = 6, label = "Average R-Squared\n of State Models",
           color = "black", size = 4) +
  theme_clean() +
  labs(title = "State Models for Incumbent") +
  xlab("R Squared Value") +
  ylab("")

# Saving graph of state models evaluation

state_models_plot <- state_models_chl + state_models_inc

ggsave(path = "images", filename = "state_models_plot.png", height = 4, width = 8)

# Creating a data frame of polls in the month period that I used for creating state models

predict_polls <- polls_2020 %>% 
  select(poll_id, state, answer, end_date, pct) %>% 
  mutate(end_date = mdy(polls_2020$end_date)) %>% 
  filter(end_date > ymd("2020-08-27") & end_date < ymd("2020-09-27")) %>% 
  filter(answer == "Biden" | answer == "Trump") %>% 
  group_by(state, answer) %>% 
  summarise(avg_support = mean(pct)) %>% 
  filter(!(state %in% c("", "District of Columbia", "ME-1","ME-2","NE-1","NE-2","NE-3")))

# Predicting Biden vote share in each state

state_chl_prediction <- state_chl %>%
  select(state, year, avg_support, pv) %>% 
  filter(!(state %in% c("District of Columbia", "ME-1","ME-2","NE-1","NE-2","NE-3"))) %>% 
  na.omit( ) %>%
  group_by(state) %>% 
  nest() %>%
  mutate(model = map(data, ~lm(pv ~ avg_support, data = .))) %>% 
  select(state, model) %>% 
  right_join(predict_polls) %>% 
  filter(answer == "Biden") %>% 
  filter(!(state %in% c("Maine CD-1", "Maine CD-2", "Nebraska CD-2")))

# Making predicted Biden vote share into a data frame

Biden_predict <- c(predict(
  state_chl_prediction$model[3],
  newdata = data.frame(avg_support = state_chl_prediction$avg_support[3])
),
predict(
  state_chl_prediction$model[4],
  newdata = data.frame(avg_support = state_chl_prediction$avg_support[4])
),
predict(
  state_chl_prediction$model[8],
  newdata = data.frame(avg_support = state_chl_prediction$avg_support[8])
),
predict(
  state_chl_prediction$model[17],
  newdata = data.frame(avg_support = state_chl_prediction$avg_support[17])
),
predict(
  state_chl_prediction$model[22],
  newdata = data.frame(avg_support = state_chl_prediction$avg_support[22])
),
predict(
  state_chl_prediction$model[30],
  newdata = data.frame(avg_support = state_chl_prediction$avg_support[30])
))
   
y <- unlist(Biden_predict, recursive=TRUE, use.names=TRUE)  

biden_predict_df <- tibble(states, biden_prediction = y)
biden_predict_df$states[1] <- "Colorado"
biden_predict_df$states[2] <- "Florida"
biden_predict_df$states[3] <- "Iowa"
biden_predict_df$states[4] <- "Nevada"
biden_predict_df$states[5] <- "Ohio"
biden_predict_df$states[6] <- "Virginia"

# Doing the same for incumbent

state_inc_prediction <- state_inc %>%
  select(state, year, avg_support, pv) %>% 
  filter(!(state %in% c("District of Columbia", "ME-1","ME-2","NE-1","NE-2","NE-3"))) %>% 
  na.omit( ) %>%
  group_by(state) %>% 
  nest() %>%
  mutate(model = map(data, ~lm(pv ~ avg_support, data = .))) %>% 
  select(state, model) %>% 
  right_join(predict_polls) %>% 
  filter(answer == "Trump") %>% 
  filter(!(state %in% c("Maine CD-1", "Maine CD-2", "Nebraska CD-2")))

trump_predict <- c(predict(
  state_inc_prediction$model[3],
  newdata = data.frame(avg_support = state_inc_prediction$avg_support[3])
),
predict(
  state_inc_prediction$model[4],
  newdata = data.frame(avg_support = state_inc_prediction$avg_support[4])
),
predict(
  state_inc_prediction$model[8],
  newdata = data.frame(avg_support = state_inc_prediction$avg_support[8])
),
predict(
  state_inc_prediction$model[17],
  newdata = data.frame(avg_support = state_inc_prediction$avg_support[17])
),
predict(
  state_inc_prediction$model[22],
  newdata = data.frame(avg_support = state_inc_prediction$avg_support[22])
),
predict(
  state_inc_prediction$model[30],
  newdata = data.frame(avg_support = state_inc_prediction$avg_support[30])
))

y <- unlist(trump_predict, recursive=TRUE, use.names=TRUE)  

trump_predict_df <- tibble(states, trump_prediction = y)
trump_predict_df$states[1] <- "Colorado"
trump_predict_df$states[2] <- "Florida"
trump_predict_df$states[3] <- "Iowa"
trump_predict_df$states[4] <- "Nevada"
trump_predict_df$states[5] <- "Ohio"
trump_predict_df$states[6] <- "Virginia"

# Merging prediction data frames and calculating winner

win_margins <- trump_predict_df %>% 
  full_join(biden_predict_df) %>% 
  mutate(democrat_win_margin = biden_prediction - trump_prediction) %>% 
  select(states, democrat_win_margin) %>% 
  gt() %>% 
  tab_header(title = "Predicting Swing States in 2020") %>% 
  cols_label(states = "State", democrat_win_margin = "Democrat Win Margin")
  
gtsave(data = win_margins, path = "images", filename = "swing_states_win.png")
