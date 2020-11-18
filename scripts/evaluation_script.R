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

# Loading data


real_dat <- read_csv("data/popvote_1948-2020.csv") %>% 
  filter(year == 2020)

real_dat_state <- read_csv("data/popvote_bystate_1948-2020.csv") %>% 
  filter(year == 2020)

real_dat_state$state <- state.abb[match(real_dat_state$state, state.name)]

accuracy_graph <- states_point_prediction %>% 
  full_join(real_dat_state, by = "state") %>% 
  filter(state != "District of Columbia") %>% 
  ggplot(aes(rep_vs, R_pv2p)) +
  geom_point() +
  geom_text_repel(aes(label = state)) +
  labs(x = "Predicted Trump 2 Party VS", y = "Actual Trump 2 Party VS") +
  theme_clean() +
  geom_abline(slope = 1) +
  geom_vline(xintercept = 0.5, col = "steelblue2", lty = 2, lwd = 0.6) +
  geom_hline(yintercept = 0.5, col = "steelblue2", lty = 2, lwd = 0.6)

states_point_prediction %>% 
  full_join(real_dat_state, by = "state") %>% 
  filter(state != "District of Columbia") %>% 
  group_by(state) %>% 
  summarize(error = rep_vs - R_pv2p) %>% 
  ungroup() %>% 
  summarize(rmse = mean(sqrt(error^2)) * 100)

