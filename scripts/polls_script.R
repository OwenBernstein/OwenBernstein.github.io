# loading libraries

library(tidyverse)
library(ggplot2)
library(lubridate)
library(ggrepel)
library(ggthemes)
library(patchwork)

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
  geom_smooth(method = lm) +
  geom_label_repel(label = incumbents$year, box.padding = 0.5) +
  labs(title = "Incumbent Party Popular Vote Share by Polling Average") +
  xlab("Average Polling Support (6 - 10 Weeks Before Election)") +
  ylab("Popular Vote Share") +
  theme_clean()

challenger_plot <- challenger %>% 
  ggplot(aes(x = avg_support, y = pv)) +
  geom_point() +
  geom_smooth(method = lm) +
  geom_label_repel(label = challenger$year, box.padding = 0.5) +
  labs(title = "Challenger Party Popular Vote Share by Polling Average") +
  xlab("Average Polling Support (6 - 10 Weeks Before Election)") +
  ylab("Popular Vote Share") +
  theme_clean()

# Combining scatterplots with patchwork and saving

poll_vote_plot <<- incumbent_plot + challenger_plot

ggsave(path = "images", filename = "poll_vote_plot.png", height = 4, width = 8)

# Making polls only model of national election

dat_poll     <- nat_time_dat[!is.na(nat_time_dat$avg_support),]
dat_poll_inc <- dat_poll[dat_poll$incumbent_party,]
dat_poll_chl <- dat_poll[!dat_poll$incumbent_party,]
mod_poll_inc <- lm(pv ~ avg_support, data = dat_poll_inc)
mod_poll_chl <- lm(pv ~ avg_support, data = dat_poll_chl)

# Making polls and economics model of national election

dat_plus     <- dat[!is.na(dat$avg_support) & !is.na(dat$GDP_growth_qt),]
dat_plus_inc <- dat_plus[dat_plus$incumbent_party,]
dat_plus_chl <- dat_plus[!dat_plus$incumbent_party,]
mod_plus_inc <- lm(pv ~ avg_support + GDP_growth_qt, data = dat_plus_inc)
mod_plus_chl <- lm(pv ~ avg_support + GDP_growth_qt, data = dat_plus_chl)