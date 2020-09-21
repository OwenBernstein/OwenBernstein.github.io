# Load libraries

library(tidyverse)
library(ggplot2)
library(ggthemes)
library(broom)

# Loading data

state_mob <- read.csv("data/Google Mobility - State - Daily.csv")
national_mob <- read.csv("data/Google Mobility - National - Daily.csv")
econ <- read.csv("data/econ.csv")
local <- read.csv("data/local.csv")
popvote <- read.csv("data/popvote_1948-2016.csv")
state_vote <- read.csv("data/popvote_bystate_1948-2016.csv")

# Joining data by year

dat <- popvote %>% 
  select(year, party, winner, pv2p, incumbent_party) %>%
  left_join(economy_df) %>% 
  filter(incumbent_party == T) %>% 
  filter(quarter == 2 | quarter == 3) %>% 
  group_by(year) %>% 
  mutate(avg_gdp = mean(GDP_growth_qt),
            avg_rdi = mean(RDI_growth),
            avg_inflation = mean(inflation),
            avg_unemployment = mean(unemployment))%>% 
  select(year, party, winner, pv2p, incumbent_party, avg_gdp, avg_rdi, avg_inflation, avg_unemployment) %>% 
  unique()

# Making scatterplots for gdp, rdi, unemployment, and inflation

dat %>%
  ggplot(aes(x= avg_gdp, y= pv2p,
             label= year)) + 
  geom_text() +
  geom_smooth(method="lm", formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=0.01, lty=2) + # median
  xlab("Average 2nd and 3rd Quarter GDP Growth") +
  ylab("Incumbent Party's Two-Party Vote Share") +
  theme_minimal()

dat %>%
  ggplot(aes(x= avg_rdi, y= pv2p,
             label= year)) + 
  geom_text() +
  geom_smooth(method="lm", formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=0.01, lty=2) + # median
  xlab("Average 2nd and 3rd Quarter RDI Growth") +
  ylab("Incumbent Party's Two-Party Vote Share") +
  theme_minimal()

dat %>%
  ggplot(aes(x= avg_unemployment, y= pv2p,
             label= year)) + 
  geom_text() +
  geom_smooth(method="lm", formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=0.01, lty=2) + # median
  xlab("Average 2nd and 3rd Quarter Unemployment") +
  ylab("Incumbent Party's Two-Party Vote Share") +
  theme_minimal()

dat %>%
  ggplot(aes(x= avg_inflation, y= pv2p,
             label= year)) + 
  geom_text() +
  geom_smooth(method="lm", formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=0.01, lty=2) + # median
  xlab("Average 2nd and 3rd Quarter Inflation") +
  ylab("Incumbent Party's Two-Party Vote Share") +
  theme_minimal()

# Making models for each economic indicator


lm_gdp <- lm(pv2p ~ avg_gdp, data = dat)
lm_rdi <- lm(pv2p ~ avg_rdi, data = dat)
lm_unemployment <- lm(pv2p ~ avg_unemployment, data = dat)
lm_inflation <- lm(pv2p ~ avg_inflation, data = dat)

summary(lm_gdp)

tidy(lm_gdp)





