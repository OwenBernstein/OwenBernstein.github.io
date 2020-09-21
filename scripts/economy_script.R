# Load libraries

library(tidyverse)
library(ggplot2)
library(ggthemes)
library(broom)
library(gt)
library(webshot)

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

gdp_model <- dat %>%
  ggplot(aes(x= avg_gdp, y= pv2p,
             label= year)) + 
  geom_text() +
  geom_smooth(method="lm", formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=0.01, lty=2) + # median
  xlab("Average 2nd and 3rd Quarter GDP Growth") +
  ylab("Incumbent Party's Two-Party Vote Share") +
  theme_minimal()

ggsave(path = "images", filename = "gdp_model.png", height = 4, width = 8)

rdi_model <- dat %>%
  ggplot(aes(x= avg_rdi, y= pv2p,
             label= year)) + 
  geom_text() +
  geom_smooth(method="lm", formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=0.01, lty=2) + # median
  xlab("Average 2nd and 3rd Quarter RDI Growth") +
  ylab("Incumbent Party's Two-Party Vote Share") +
  theme_minimal()

ggsave(path = "images", filename = "rdi_model.png", height = 4, width = 8)

unemployment_model <- dat %>%
  ggplot(aes(x= avg_unemployment, y= pv2p,
             label= year)) + 
  geom_text() +
  geom_smooth(method="lm", formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=0.01, lty=2) + # median
  xlab("Average 2nd and 3rd Quarter Unemployment") +
  ylab("Incumbent Party's Two-Party Vote Share") +
  theme_minimal()

ggsave(path = "images", filename = "unemployment_model.png", height = 4, width = 8)

inflation_model <- dat %>%
  ggplot(aes(x= avg_inflation, y= pv2p,
             label= year)) + 
  geom_text() +
  geom_smooth(method="lm", formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=0.01, lty=2) + # median
  xlab("Average 2nd and 3rd Quarter Inflation") +
  ylab("Incumbent Party's Two-Party Vote Share") +
  theme_minimal()

ggsave(path = "images", filename = "inflation_model.png", height = 4, width = 8)

# Making models for each economic indicator


lm_gdp <- lm(pv2p ~ avg_gdp, data = dat)
lm_rdi <- lm(pv2p ~ avg_rdi, data = dat)
lm_unemployment <- lm(pv2p ~ avg_unemployment, data = dat)
lm_inflation <- lm(pv2p ~ avg_inflation, data = dat)

# Converting models to summaries

sm_gdp <- summary(lm_gdp)
sm_rdi <- summary(lm_rdi)
sm_unemployment <- summary(lm_unemployment)
sm_inflation <- summary(lm_inflation)

# Converting all summaries into a data frame

stats <- data.frame(
  row.names = c("gdp", "rdi", "unemploment", "inflation"),
  model = c("Average 2nd and 3rd Quarter GDP Growth",
            "Average 2nd and 3rd Quarter RDI Growth",
            "Average 2nd and 3rd Quarter Inflation",
            "Average 2nd and 3rd Quarter Unemployment"),
  r_squared = c(
    sm_gdp$r.squared,
    sm_rdi$r.squared,
    sm_unemployment$r.squared,
    sm_inflation$r.squared
  ),
  mse = c(
    sqrt(mean(sm_gdp$residuals ^ 2)),
    sqrt(mean(sm_rdi$residuals ^ 2)),
    sqrt(mean(sm_unemployment$residuals ^ 2)),
    sqrt(mean(sm_inflation$residuals ^ 2))
  )
)

# Making a gt table of the model statistics

models_gt <- gt(stats) %>% 
  tab_header(title = "Economic Models for Predicting Elections") %>% 
  cols_label(model = "Model",
             r_squared = "R Squared",
             mse = "MSE") %>% 
  fmt_number(columns = 2:3,
             decimals = 2)
  
gtsave(data = models_gt, path = "images", filename = "model_gt.png")

new_gdp <- econ %>% 
  filter(year == 2020 & quarter == 2) %>% 
  mutate(avg_rdi = RDI_growth,
         avg_gdp = GDP_growth_qt,
         avg_unemployment = unemployment,
         avg_inflation = inflation)

predict_rdi <- data.frame(predict(lm_rdi, new_gdp, interval = "prediction"))
predict_gdp <- data.frame(predict(lm_gdp, new_gdp, interval = "prediction"))
predict_unemployment <- data.frame(predict(lm_unemployment, new_gdp, interval = "prediction"))
predict_inflation <- data.frame(predict(lm_inflation, new_gdp, interval = "prediction"))

models_predict <- bind_rows(list(predict_rdi, predict_gdp, predict_unemployment, predict_inflation), .id = "model") %>%
  mutate(Model = c("RDI", "GDP", "Unemployment", "Inflation")) %>% 
  select(Model, fit, lwr, upr) %>% 
  gt() %>% 
  tab_header(title = "2020 Two-Party Vote Share Prediction by Models") %>% 
  cols_label(fit = "Prediction", lwr = "Lower Prediction Bound", upr = "Upper Prediction Bound") %>% 
  fmt_number(columns = 2:4,
           decimals = 2)

gtsave(data = models_predict, path = "images", filename = "econ_model_predict_gt.png")

