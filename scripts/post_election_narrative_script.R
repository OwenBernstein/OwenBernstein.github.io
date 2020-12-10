# Loading libraries


library(tidyverse)
library(ggplot2)
library(ggrepel)
library(ggthemes)
library(patchwork)
library(broom)
library(usmap)
library(janitor)
library(statebins)
library(maptools)
library(rgdal)

# Loading data

demog_dat <- read_csv("data/cc-est2019-alldata.csv") %>% 
  clean_names() %>% 
  filter(year == 9 | year == 12) %>% 
  filter(agegrp == 0) %>% 
  mutate(white_pop = wa_male + wa_female) %>% 
  mutate(white_perc = white_pop / tot_pop,
         state = stname) %>% 
  transform(county = str_replace(ctyname, " County", "")) %>% 
  select(county, state, year, white_perc)

county_2016 <- read_csv("data/popvote_bycounty_2000-2016.csv") %>% 
  filter(year == 2016)

county_2020 <- read_csv("data/popvote_bycounty_2020.csv") %>% 
  clean_names() %>% 
  slice(-1) %>% 
  mutate(fips = as.double(fips),
         total_vote = as.double(total_vote),
         biden = as.double(joseph_r_biden_jr),
         trump = as.double(donald_j_trump)) %>% 
  select(fips, geographic_name, total_vote, biden, trump)

county_votes <- county_2016 %>% 
  full_join(county_2020, by = "fips") %>% 
  full_join(demog_dat, by = c("state", "county")) %>% 
  mutate(d_marg_2016 = D_win_margin) %>% 
  select(state, county, d_marg_2016, total_vote, biden, trump, year.y, white_perc) %>% 
  mutate(biden_perc = biden / total_vote,
         trump_perc = trump/ total_vote,
         d_marg_2020 = (biden_perc - trump_perc) * 100,
         dem_vs_chng = d_marg_2020 - d_marg_2016) %>% 
  select(state, county, d_marg_2016, d_marg_2020, white_perc, dem_vs_chng, year.y, total_vote)

marg_change <- county_votes %>% 
  filter(year.y == 12) %>% 
  ggplot(aes(white_perc, dem_vs_chng, size = total_vote)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = F) +
  ylim(-30, 30) +
  labs(title = "Democratic Win Margin Change (2016 - 2020) by White Population Percentage", y = "Democratic Win Margin Change", x = "White Population Percentage") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(path = "images", filename = "vote_marg_change.png", height = 6, width = 10)

vs_white_pop <- county_votes %>% 
  filter(year.y == 12) %>%
  ggplot(aes(white_perc, d_marg_2020, size = total_vote)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = F) +
  labs(title = "Democratic Win Margin by White Population Percentage", y = "Democratic Win Margin 2020", x = "White Population Percentage") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(path = "images", filename = "vs_white_pop.png", height = 6, width = 10)

midwest_states <- county_votes %>% 
  filter(state == "Pennsylvania" | state == "Wisconsin" | state == "Michigan") %>% 
  filter(year.y == 12) %>% 
  ggplot(aes(white_perc, dem_vs_chng, size = total_vote)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = F) +
  ylim(-30, 30) +
  labs(title = "Democratic Win Margin Change (2016 - 2020) in Flipped Midwest States by White Population Percentage", y = "Democratic Win Margin Change", x = "White Population Percentage") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(path = "images", filename = "midwest_vs_chng.png", height = 6, width = 10)
