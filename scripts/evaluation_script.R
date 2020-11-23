# Loading libraries

library(tidyverse)
library(ggplot2)
library(lubridate)
library(stargazer)
library(ggthemes)
library(patchwork)
library(broom)
library(janitor)
library(statebins)
library(ggrepel)
library(gt)
library(formattable)

# Loading data

load("data/states_point_prediction.Rdata")

real_dat <- read_csv("data/popvote_1948-2020.csv") %>% 
  filter(year == 2020)

real_dat_state <- read_csv("data/popvote_bystate_1948-2020.csv") %>% 
  filter(year == 2020)

real_dat_state$state <- state.abb[match(real_dat_state$state, state.name)]

# Model Evaluation Image

real_state_points <- states_point_prediction

real_state_points$winner[4] <- "Biden"
real_state_points$winner[33] <- "Biden"
real_state_points$winner[10] <- "Biden"


statebin_map_2_real <- real_state_points %>% 
  ggplot(aes(state = state, fill = fct_relevel(winner, "Biden", "Trump"))) +
  geom_statebins() +
  theme_statebins() +
  labs(title = " Actual 2020 Presidential Election Map",
       fill = "") +
  scale_fill_manual(values=c("steelblue2", "indianred"), breaks = c("Biden", "Trump"))

prediction_map_comp <- statebin_map_2 + statebin_map_2_real

ggsave(path = "images", filename = "prediction_map_comp.png", height = 6, width = 10)

# Making graph of real vs predicted vs by state

accuracy_graph <- states_point_prediction %>% 
  full_join(real_dat_state, by = "state") %>% 
  filter(state != "District of Columbia") %>% 
  ggplot(aes(rep_vs, R_pv2p)) +
  geom_point() +
  geom_text_repel(aes(label = state)) +
  labs(title = "Predicted vs. Actual Vote Share", x = "Predicted Trump 2 Party VS", y = "Actual Trump 2 Party VS") +
  theme_clean() +
  geom_abline(slope = 1) +
  geom_vline(xintercept = 0.5, col = "steelblue2", lty = 2, lwd = 0.6) +
  geom_hline(yintercept = 0.5, col = "steelblue2", lty = 2, lwd = 0.6) +
  xlim(0.3, 0.75) +
  ylim(0.3, 0.75)

ggsave(path = "images", filename = "accuracy_graph.png", height = 6, width = 10)

# Making table of accuracy measures

rmse <- states_point_prediction %>% 
  full_join(real_dat_state, by = "state") %>% 
  filter(state != "District of Columbia") %>% 
  group_by(state) %>% 
  summarize(error = rep_vs - R_pv2p) %>% 
  ungroup() %>% 
  summarize(rmse = mean(sqrt(error^2)) * 100)

mse <- states_point_prediction %>% 
  full_join(real_dat_state, by = "state") %>% 
  filter(state != "District of Columbia") %>% 
  group_by(state) %>% 
  summarize(error = rep_vs - R_pv2p) %>% 
  ungroup() %>% 
  summarize(rmse = mean(error) * 100)


measures <- c("National Electoral Vote Total", "RMSE (state, pv2p)", "MSE (state, pv2p", "Classification Accuracy", "States Missed")
my_model <- c("33", "1.68", "-0.43", "94", "AZ, GA, NV")
five_thirty_eight <- c("-42", "3.02", "-2.44", "96", "NC, FL")
economist <- c("-50", "2.80", "-2.33", "96", "NC, FL")

eval <- data.frame(Measure = measures, my_model = my_model, five_thirty_eight = five_thirty_eight, economist = economist)

eval_measures <- gt(eval) %>% 
  tab_header(title = "Trump Predicted - Trump Actual") %>% 
  cols_label(Measure = "", my_model = "My Model", five_thirty_eight = "FiveThirtyEight", economist = "The Economist")

gtsave(data = eval_measures, path = "images", filename = "eval_measures_gt.png")

