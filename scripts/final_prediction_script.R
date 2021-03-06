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

# Reading in data 

poll_state <- read_csv("data/pollavg_bystate_1968-2016 (1).csv")
polls_2020 <- read_csv("data/polls_2020.csv")
popvote_state <- read_csv("data/popvote_bystate_1948-2016.csv")
demog <- read_csv("data/demographic_1990-2018.csv")
approval <- read_csv("data/Gallup_approval.csv")
approval_2020 <- read_csv("data/approval_2020.csv")
vep <- read_csv("data/vep_1980-2016.csv")
ec <- read_csv("data/electoralcollegevotes_1948-2020.csv")

# Joining data 

popvote_state$state <- state.abb[match(popvote_state$state, state.name)]
poll_state$state <- state.abb[match(poll_state$state, state.name)]
vep$state <- state.abb[match(vep$state, state.name)]
ec$State <- state.abb[match(ec$State, state.name)]

dat <- popvote_state %>% 
  full_join(poll_state %>% 
              filter(weeks_left > 3 & weeks_left < 34) %>% 
              group_by(year,party,state) %>% 
              summarise(avg_poll = mean(avg_poll)),
            by = c("year" ,"state")) %>%
  left_join(demog %>%
              select(-c("total")),
            by = c("year" ,"state")) %>% 
  left_join(approval %>% 
              mutate(month = as.numeric(substr(poll_enddate, 6, 7))) %>%
              filter(year == 2020 | year == 2016 | year == 2012 | year == 2008 | year == 2004 |
                       year == 2000 | year == 1996 | year == 1992 | year == 1988 | year == 1984 | 
                       year == 1980 |  year == 1976) %>% 
              filter(month == 10) %>% 
              group_by(year) %>% 
              summarise(avg_approve = mean(approve)),
            by = "year") %>% 
  filter(party == "democrat")

# Creating demographic change variables and incumbent variable for dems

change_data <- dat %>%
  group_by(state) %>%
  mutate(
    asian_change = Asian - lag(Asian, order_by = year),
    black_change = Black - lag(Black, order_by = year),
    hispanic_change = Hispanic - lag(Hispanic, order_by = year),
    indigenous_change = Indigenous - lag(Indigenous, order_by = year),
    white_change = White - lag(White, order_by = year),
    female_change = Female - lag(Female, order_by = year),
    male_change = Male - lag(Male, order_by = year),
    age20_change = age20 - lag(age20, order_by = year),
    age3045_change = age3045 - lag(age3045, order_by = year),
    age4565_change = age4565 - lag(age4565, order_by = year),
    age65_change = age65 - lag(age65, order_by = year)
  ) %>%
  select(
    state,
    year,
    D,
    R,
    total,
    R_pv2p,
    D_pv2p,
    party,
    avg_poll,
    avg_approve,
    asian_change,
    black_change,
    hispanic_change,
    indigenous_change,
    white_change,
    female_change,
    male_change,
    age20_change,
    age3045_change,
    age4565_change,
    age65_change
  ) %>%
  mutate(incumbent = ifelse(
    year == 1976 & party == "republican",
    1,
    ifelse(
      year == 1980 & party == "democrat",
      1,
      ifelse(
        year == 1984 & party == "republican",
        1,
        ifelse(
          year == 1988 & party == "republican",
          1,
          ifelse(
            year == 1992 & party == "republican",
            1,
            ifelse(
              year == 1996 & party == "democrat",
              1,
              ifelse(
                year == 2000 & party == "democrat",
                1,
                ifelse(
                  year == 2004 & party == "republican",
                  1,
                  ifelse(
                    year == 2008 & party == "republican",
                    1,
                    ifelse(
                      year == 2012 & party == "democrat",
                      1,
                      ifelse(
                        year == 2016 & party == "democrat",
                        1,
                        ifelse(year == 2020 &
                                 party == "republican", 1, 0)
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )) %>% 
  filter(incumbent == 1) %>% 
  mutate(inc_vote = D)

#  Creating demographic change variables and incumbent variable for reps

dat_2 <- popvote_state %>% 
  full_join(poll_state %>% 
              filter(weeks_left > 3 & weeks_left < 34) %>% 
              group_by(year,party,state) %>% 
              summarise(avg_poll = mean(avg_poll)),
            by = c("year" ,"state")) %>%
  left_join(demog %>%
              select(-c("total")),
            by = c("year" ,"state")) %>% 
  left_join(approval %>% 
              mutate(month = as.numeric(substr(poll_enddate, 6, 7))) %>%
              filter(year == 2020 | year == 2016 | year == 2012 | year == 2008 | year == 2004 |
                       year == 2000 | year == 1996 | year == 1992 | year == 1988 | year == 1984 | 
                       year == 1980 |  year == 1976) %>% 
              filter(month == 10) %>% 
              group_by(year) %>% 
              summarise(avg_approve = mean(approve)),
            by = "year") %>% 
  filter(party == "republican")

# Creating demographic change variables and incumbent variable for dems

change_data_2 <- dat_2 %>%
  group_by(state) %>%
  mutate(
    asian_change = Asian - lag(Asian, order_by = year),
    black_change = Black - lag(Black, order_by = year),
    hispanic_change = Hispanic - lag(Hispanic, order_by = year),
    indigenous_change = Indigenous - lag(Indigenous, order_by = year),
    white_change = White - lag(White, order_by = year),
    female_change = Female - lag(Female, order_by = year),
    male_change = Male - lag(Male, order_by = year),
    age20_change = age20 - lag(age20, order_by = year),
    age3045_change = age3045 - lag(age3045, order_by = year),
    age4565_change = age4565 - lag(age4565, order_by = year),
    age65_change = age65 - lag(age65, order_by = year)
  ) %>%
  select(
    state,
    year,
    D,
    R,
    total,
    R_pv2p,
    D_pv2p,
    party,
    avg_poll,
    avg_approve,
    asian_change,
    black_change,
    hispanic_change,
    indigenous_change,
    white_change,
    female_change,
    male_change,
    age20_change,
    age3045_change,
    age4565_change,
    age65_change
  ) %>%
  mutate(incumbent = ifelse(
    year == 1976 & party == "republican",
    1,
    ifelse(
      year == 1980 & party == "democrat",
      1,
      ifelse(
        year == 1984 & party == "republican",
        1,
        ifelse(
          year == 1988 & party == "republican",
          1,
          ifelse(
            year == 1992 & party == "republican",
            1,
            ifelse(
              year == 1996 & party == "democrat",
              1,
              ifelse(
                year == 2000 & party == "democrat",
                1,
                ifelse(
                  year == 2004 & party == "republican",
                  1,
                  ifelse(
                    year == 2008 & party == "republican",
                    1,
                    ifelse(
                      year == 2012 & party == "democrat",
                      1,
                      ifelse(
                        year == 2016 & party == "democrat",
                        1,
                        ifelse(year == 2020 &
                                 party == "republican", 1, 0)
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )) %>% 
  filter(incumbent == 1) %>% 
  mutate(inc_vote = R)

# Joining rows

mod_dat <- bind_rows(change_data, change_data_2) %>% 
  arrange(state) %>% 
  mutate(voters = D + R)


# making glm

glm_mod <- glm(cbind(inc_vote, voters-inc_vote) ~ avg_poll + avg_approve + asian_change + black_change + hispanic_change + female_change + party +
                 age3045_change + age4565_change + age65_change, mod_dat,
               
               family = binomial)

stargazer(glm_mod,
          title = "Election Model",
          out = "../OwenBernstein.github.io/images/final_model_glm.html")

# Predicting 2020

demog_2020 <- subset(demog, year == 2018)
demog_2020 <- as.data.frame(demog_2020)
rownames(demog_2020) <- demog_2020$state
demog_2020 <- demog_2020[state.abb, ]


demog_2020_change <- demog %>%
  filter(year %in% c(2016, 2018)) %>%
  group_by(state) %>%
  mutate(
    asian_change = Asian - lag(Asian, order_by = year),
    black_change = Black - lag(Black, order_by = year),
    hispanic_change = Hispanic - lag(Hispanic, order_by = year),
    indigenous_change = Indigenous - lag(Indigenous, order_by = year),
    white_change = White - lag(White, order_by = year),
    female_change = Female - lag(Female, order_by = year),
    male_change = Male - lag(Male, order_by = year),
    age20_change = age20 - lag(age20, order_by = year),
    age3045_change = age3045 - lag(age3045, order_by = year),
    age4565_change = age4565 - lag(age4565, order_by = year),
    age65_change = age65 - lag(age65, order_by = year)
  ) %>%
  filter(year == 2018) %>% 
  mutate(year = 2020)

predict_polls <- polls_2020 %>% 
  select(poll_id, state, answer, end_date, pct) %>% 
  mutate(end_date = mdy(polls_2020$end_date)) %>% 
  filter(end_date > ymd("2020-10-01") & end_date < ymd("2020-11-1")) %>% 
  filter(answer == "Biden" | answer == "Trump") %>% 
  group_by(state, answer) %>% 
  summarise(avg_poll = mean(pct)) %>% 
  filter(!(state %in% c(""))) %>% 
  filter(answer == "Trump")

predict_polls$state <- state.abb[match(predict_polls$state, state.name)]

approve_predict <- approval_2020 %>% 
  mutate(month = as.numeric(substr(mdy(end_date), 6, 7))) %>%
  filter(politician_id == 11) %>% 
  filter(month == 10) %>%
  mutate(year = 2020) %>% 
  mutate(avg_approve = mean(yes)) %>% 
  select(year, avg_approve) %>% 
  unique()

newdata <- predict_polls %>% 
  full_join(demog_2020_change, by = "state") %>% 
  left_join(approve_predict,
            by = "year") %>% 
  mutate(party = "republican") %>% 
  drop_na(state) %>% 
  filter(state != "DC")

polls_sd <- polls_2020 %>% 
  select(poll_id, state, answer, end_date, pct) %>% 
  mutate(end_date = mdy(polls_2020$end_date)) %>% 
  filter(end_date > ymd("2020-10-01") & end_date < ymd("2020-11-1")) %>% 
  filter(answer == "Trump") %>% 
  group_by(state) %>% 
  summarise(sd = sd(pct))

polls_sd$state <- state.abb[match(polls_sd$state, state.name)]

# Predicting states

output <- tibble()
tib <- tibble()
n <- 10000

for(s in unique(newdata$state)) {
  
  state_dat <- newdata %>% 
    filter(state == s)
  
  state_dat_2 <- mod_dat %>% 
    filter(state == s) %>% 
    filter(year == 2016)
  
  state_dat_3 <- polls_sd %>% 
    filter(state == s) %>% 
    pull(sd)
  
  prob_vote <- predict(glm_mod, newdata = state_dat, type="response")[[1]]
  
  sim_inc_votes <- rbinom(n = n, size = state_dat_2$voters, prob = rnorm(n = n, mean = prob_vote, sd = (state_dat_3/100)))
  
  inc_vs <- sim_inc_votes/state_dat_2$voters
  
  for(i in 1:n){
    vec <- tibble(state = s, prob = inc_vs[i])
    tib <- tib %>%
      bind_rows(vec)
  }
  vector <- tibble(state = s, sims = list(inc_vs))
  
  output <- output %>%
    bind_rows(vector)
  
}


tibstate_wins <- tib %>% 
  mutate(mod = rep(1:n, times = 50)) %>% 
  group_by(state) %>% 
  mutate(winner = ifelse(prob > 0.5, "republican", "democrat"))

predict_ec <- tibstate_wins %>%
  left_join(ec, by = c("state" = "State")) %>% 
  select(state, prob, mod, winner, `2016`) %>% 
  group_by(mod, winner) %>%
  summarise(votes = sum(`2016`)) %>% 
  mutate(votes = ifelse(winner == "democrat", votes + 3, votes))

college_votes <- predict_ec %>% 
  ggplot(aes(x = votes, fill = winner)) +
  geom_histogram(position = "identity", alpha = c(0.6), bins = 38) +
  scale_fill_manual(values=c("steelblue2", "indianred"), name = "", labels = c("Democrat", "Republican")) +
  labs(title = "10,000 Electoral College Simulations", x = "Electoral Votes", y = "Simulations") +
  theme_clean() +
  geom_vline(xintercept = 270, lty = 2, lwd = 1.3)

ggsave(path = "images", filename = "final_predict.png", height = 6, width = 10)

biden_win_perc <- predict_ec %>% 
  group_by(winner) %>%
  filter(winner == "democrat") %>% 
  mutate(dem_win = ifelse(votes > 270, 1, 0)) %>% 
  summarise(mean(dem_win))

point_prediction <- tibstate_wins %>% 
  left_join(ec, by = c("state" = "State")) %>% 
  group_by(state, `2016`) %>% 
  summarize(rep_vs = mean(prob)) %>% 
  mutate(winner = ifelse(rep_vs > 0.5, "republican", "democrat")) %>% 
  group_by(winner) %>% 
  summarize(votes = sum(`2016`)) %>% 
  mutate(votes = ifelse(winner == "democrat", votes + 3, votes))

states_point_prediction <- tibstate_wins %>% 
  group_by(state) %>% 
  summarize(rep_vs = mean(prob)) %>% 
  mutate(winner = ifelse(rep_vs > 0.5, "Trump", "Biden")) %>% 
  add_row(state = "District of Columbia", rep_vs = 7, winner = "Biden")

# Measuring fit of test for 1996

output_2 <- tibble()

for(y in unique(mod_dat$year)) {
  
  year_inc <- subset(mod_dat, subset = year == y)
  
  for(s in unique(mod_dat$state)) {
    
    year_state_inc <- subset(year_inc, subset = state == s)
    
    true_inc <- year_state_inc %>% 
      pull(inc_vote)
    
    glm_mod_dat <- mod_dat %>% 
      filter(year != y & state != s)
    
    out_samp_mod <- glm(cbind(inc_vote, voters-inc_vote) ~ avg_poll + avg_approve + asian_change + black_change + hispanic_change + female_change + party +
                          age3045_change + age4565_change + age65_change, glm_mod_dat,
                        
                        family = binomial)
    
    pred_inc_vote <- predict(out_samp_mod, newdata = year_state_inc, type = "response")[[1]]
    
    sim_inc_votes <- rbinom(n = 1, size = year_state_inc$voters, prob = pred_inc_vote)
    
    inc_vs <- sim_inc_votes/year_state_inc$voters
    
    tib <- tibble(state = s, year = y, winner = ifelse(inc_vs > 0.5 & (true_inc / year_state_inc$voters) > 0.5, 1, 
                                                       ifelse(inc_vs < 0.5 & (true_inc / year_state_inc$voters) < 0.5, 1, 0)))
    
    output_2 <- output_2 %>% bind_rows(tib)
  }
  
}

cor_96 <- mean(output_2$winner, na.rm = T)

# Measuring fit for 2000

mod_dat_2 <- na.omit(mod_dat) %>% 
  filter(year == 2000)

output_2 <- tibble()

for(s in unique(mod_dat_2$state)) {
    
    year_state_inc <- subset(mod_dat_2, subset = state == s)
    
    true_inc <- year_state_inc %>% 
      pull(inc_vote)
    
    glm_mod_dat <- mod_dat %>% 
      filter(year != 2000, state != s)
    
    out_samp_mod <- glm(cbind(inc_vote, voters-inc_vote) ~ avg_poll + avg_approve + asian_change + black_change + hispanic_change + female_change + party +
                          age3045_change + age4565_change + age65_change, glm_mod_dat,
                        
                        family = binomial)
    
    pred_inc_vote <- predict(out_samp_mod, newdata = year_state_inc, type = "response")[[1]]
    
    sim_inc_votes <- rbinom(n = 1, size = year_state_inc$voters, prob = pred_inc_vote)
    
    inc_vs <- sim_inc_votes/year_state_inc$voters
    
    tib <- tibble(state = s, year = 2000, winner = ifelse(inc_vs > 0.5 & (true_inc / year_state_inc$voters) > 0.5, 1, 
                                                       ifelse(inc_vs < 0.5 & (true_inc / year_state_inc$voters) < 0.5, 1, 0)))
    
    output_2 <- output_2 %>% bind_rows(tib)
  }

cor_00 <- mean(output_2$winner, na.rm = T)

# Measuring fit for 2004

mod_dat_3 <- na.omit(mod_dat) %>% 
  filter(year == 2004)

output_2 <- tibble()

for(s in unique(mod_dat_3$state)) {
  
  year_state_inc <- subset(mod_dat_3, subset = state == s)
  
  true_inc <- year_state_inc %>% 
    pull(inc_vote)
  
  glm_mod_dat <- mod_dat %>% 
    filter(year != 2004, state != s)
  
  out_samp_mod <- glm(cbind(inc_vote, voters-inc_vote) ~ avg_poll + avg_approve + asian_change + black_change + hispanic_change + female_change + party +
                        age3045_change + age4565_change + age65_change, glm_mod_dat,
                      
                      family = binomial)
  
  pred_inc_vote <- predict(out_samp_mod, newdata = year_state_inc, type = "response")[[1]]
  
  sim_inc_votes <- rbinom(n = 1, size = year_state_inc$voters, prob = pred_inc_vote)
  
  inc_vs <- sim_inc_votes/year_state_inc$voters
  
  tib <- tibble(state = s, year = 2004, winner = ifelse(inc_vs > 0.5 & (true_inc / year_state_inc$voters) > 0.5, 1, 
                                                        ifelse(inc_vs < 0.5 & (true_inc / year_state_inc$voters) < 0.5, 1, 0)))
  
  output_2 <- output_2 %>% bind_rows(tib)
}

cor_04 <- mean(output_2$winner, na.rm = T)

# Measuring fit for 2008

mod_dat_4 <- na.omit(mod_dat) %>% 
  filter(year == 2008)

output_2 <- tibble()

for(s in unique(mod_dat_4$state)) {
  
  year_state_inc <- subset(mod_dat_4, subset = state == s)
  
  true_inc <- year_state_inc %>% 
    pull(inc_vote)
  
  glm_mod_dat <- mod_dat %>% 
    filter(year != 2008, state != s)
  
  out_samp_mod <- glm(cbind(inc_vote, voters-inc_vote) ~ avg_poll + avg_approve + asian_change + black_change + hispanic_change + female_change + party +
                        age3045_change + age4565_change + age65_change, glm_mod_dat,
                      
                      family = binomial)
  
  pred_inc_vote <- predict(out_samp_mod, newdata = year_state_inc, type = "response")[[1]]
  
  sim_inc_votes <- rbinom(n = 1, size = year_state_inc$voters, prob = pred_inc_vote)
  
  inc_vs <- sim_inc_votes/year_state_inc$voters
  
  tib <- tibble(state = s, year = 2008, winner = ifelse(inc_vs > 0.5 & (true_inc / year_state_inc$voters) > 0.5, 1, 
                                                        ifelse(inc_vs < 0.5 & (true_inc / year_state_inc$voters) < 0.5, 1, 0)))
  
  output_2 <- output_2 %>% bind_rows(tib)
}

cor_08 <- mean(output_2$winner, na.rm = T)

# Measuring fit for 2012

mod_dat_5 <- na.omit(mod_dat) %>% 
  filter(year == 2012)

output_2 <- tibble()

for(s in unique(mod_dat_5$state)) {
  
  year_state_inc <- subset(mod_dat_5, subset = state == s)
  
  true_inc <- year_state_inc %>% 
    pull(inc_vote)
  
  glm_mod_dat <- mod_dat %>% 
    filter(year != 2012, state != s)
  
  out_samp_mod <- glm(cbind(inc_vote, voters-inc_vote) ~ avg_poll + avg_approve + asian_change + black_change + hispanic_change + female_change + party +
                        age3045_change + age4565_change + age65_change, glm_mod_dat,
                      
                      family = binomial)
  
  pred_inc_vote <- predict(out_samp_mod, newdata = year_state_inc, type = "response")[[1]]
  
  sim_inc_votes <- rbinom(n = 1, size = year_state_inc$voters, prob = pred_inc_vote)
  
  inc_vs <- sim_inc_votes/year_state_inc$voters
  
  tib <- tibble(state = s, year = 2012, winner = ifelse(inc_vs > 0.5 & (true_inc / year_state_inc$voters) > 0.5, 1, 
                                                        ifelse(inc_vs < 0.5 & (true_inc / year_state_inc$voters) < 0.5, 1, 0)))
  
  output_2 <- output_2 %>% bind_rows(tib)
}

cor_12 <- mean(output_2$winner, na.rm = T)

# Measuring fit for 2016

mod_dat_6 <- na.omit(mod_dat) %>% 
  filter(year == 2016)

output_2 <- tibble()

for(s in unique(mod_dat_6$state)) {
  
  year_state_inc <- subset(mod_dat_6, subset = state == s)
  
  true_inc <- year_state_inc %>% 
    pull(inc_vote)
  
  glm_mod_dat <- mod_dat %>% 
    filter(year != 2016, state != s)
  
  out_samp_mod <- glm(cbind(inc_vote, voters-inc_vote) ~ avg_poll + avg_approve + asian_change + black_change + hispanic_change + female_change + party +
                        age3045_change + age4565_change + age65_change, glm_mod_dat,
                      
                      family = binomial)
  
  pred_inc_vote <- predict(out_samp_mod, newdata = year_state_inc, type = "response")[[1]]
  
  sim_inc_votes <- rbinom(n = 1, size = year_state_inc$voters, prob = pred_inc_vote)
  
  inc_vs <- sim_inc_votes/year_state_inc$voters
  
  tib <- tibble(state = s, year = 2016, winner = ifelse(inc_vs > 0.5 & (true_inc / year_state_inc$voters) > 0.5, 1, 
                                                        ifelse(inc_vs < 0.5 & (true_inc / year_state_inc$voters) < 0.5, 1, 0)))
  
  output_2 <- output_2 %>% bind_rows(tib)
}

cor_16 <- mean(output_2$winner, na.rm = T)

# Total correct state prediction rate

pred_df <- data.frame(type = "Out of Sample", year = c(1996, 2000, 2004, 2008, 2012, 2016), correct_perc = c(cor_96, cor_00, cor_04, cor_08, cor_12, cor_16))

####
# Testing in sample fitness
###


# Measuring fit of test for 1996

output_2 <- tibble()

for(y in unique(mod_dat$year)) {
  
  year_inc <- subset(mod_dat, subset = year == y)
  
  for(s in unique(mod_dat$state)) {
    
    year_state_inc <- subset(year_inc, subset = state == s)
    
    true_inc <- year_state_inc %>% 
      pull(inc_vote)
    
    glm_mod_dat <- mod_dat
    
    out_samp_mod <- glm(cbind(inc_vote, voters-inc_vote) ~ avg_poll + avg_approve + asian_change + black_change + hispanic_change + female_change + party +
                          age3045_change + age4565_change + age65_change, glm_mod_dat,
                        
                        family = binomial)
    
    pred_inc_vote <- predict(out_samp_mod, newdata = year_state_inc, type = "response")[[1]]
    
    sim_inc_votes <- rbinom(n = 1, size = year_state_inc$voters, prob = pred_inc_vote)
    
    inc_vs <- sim_inc_votes/year_state_inc$voters
    
    tib <- tibble(state = s, year = y, winner = ifelse(inc_vs > 0.5 & (true_inc / year_state_inc$voters) > 0.5, 1, 
                                                       ifelse(inc_vs < 0.5 & (true_inc / year_state_inc$voters) < 0.5, 1, 0)))
    
    output_2 <- output_2 %>% bind_rows(tib)
  }
  
}

cor_96_in_samp <- mean(output_2$winner, na.rm = T)

# Measuring fit for 2000

mod_dat_2 <- na.omit(mod_dat) %>% 
  filter(year == 2000)

output_2 <- tibble()

for(s in unique(mod_dat_2$state)) {
  
  year_state_inc <- subset(mod_dat_2, subset = state == s)
  
  true_inc <- year_state_inc %>% 
    pull(inc_vote)
  
  glm_mod_dat <- mod_dat
  
  out_samp_mod <- glm(cbind(inc_vote, voters-inc_vote) ~ avg_poll + avg_approve + asian_change + black_change + hispanic_change + female_change + party +
                        age3045_change + age4565_change + age65_change, glm_mod_dat,
                      
                      family = binomial)
  
  pred_inc_vote <- predict(out_samp_mod, newdata = year_state_inc, type = "response")[[1]]
  
  sim_inc_votes <- rbinom(n = 1, size = year_state_inc$voters, prob = pred_inc_vote)
  
  inc_vs <- sim_inc_votes/year_state_inc$voters
  
  tib <- tibble(state = s, year = 2000, winner = ifelse(inc_vs > 0.5 & (true_inc / year_state_inc$voters) > 0.5, 1, 
                                                        ifelse(inc_vs < 0.5 & (true_inc / year_state_inc$voters) < 0.5, 1, 0)))
  
  output_2 <- output_2 %>% bind_rows(tib)
}

cor_00_in_samp <- mean(output_2$winner, na.rm = T)

# Measuring fit for 2004

mod_dat_3 <- na.omit(mod_dat) %>% 
  filter(year == 2004)

output_2 <- tibble()

for(s in unique(mod_dat_3$state)) {
  
  year_state_inc <- subset(mod_dat_3, subset = state == s)
  
  true_inc <- year_state_inc %>% 
    pull(inc_vote)
  
  glm_mod_dat <- mod_dat
  
  out_samp_mod <- glm(cbind(inc_vote, voters-inc_vote) ~ avg_poll + avg_approve + asian_change + black_change + hispanic_change + female_change + party +
                        age3045_change + age4565_change + age65_change, glm_mod_dat,
                      
                      family = binomial)
  
  pred_inc_vote <- predict(out_samp_mod, newdata = year_state_inc, type = "response")[[1]]
  
  sim_inc_votes <- rbinom(n = 1, size = year_state_inc$voters, prob = pred_inc_vote)
  
  inc_vs <- sim_inc_votes/year_state_inc$voters
  
  tib <- tibble(state = s, year = 2004, winner = ifelse(inc_vs > 0.5 & (true_inc / year_state_inc$voters) > 0.5, 1, 
                                                        ifelse(inc_vs < 0.5 & (true_inc / year_state_inc$voters) < 0.5, 1, 0)))
  
  output_2 <- output_2 %>% bind_rows(tib)
}

cor_04_in_samp <- mean(output_2$winner, na.rm = T)

# Measuring fit for 2008

mod_dat_4 <- na.omit(mod_dat) %>% 
  filter(year == 2008)

output_2 <- tibble()

for(s in unique(mod_dat_4$state)) {
  
  year_state_inc <- subset(mod_dat_4, subset = state == s)
  
  true_inc <- year_state_inc %>% 
    pull(inc_vote)
  
  glm_mod_dat <- mod_dat
  
  out_samp_mod <- glm(cbind(inc_vote, voters-inc_vote) ~ avg_poll + avg_approve + asian_change + black_change + hispanic_change + female_change + party +
                        age3045_change + age4565_change + age65_change, glm_mod_dat,
                      
                      family = binomial)
  
  pred_inc_vote <- predict(out_samp_mod, newdata = year_state_inc, type = "response")[[1]]
  
  sim_inc_votes <- rbinom(n = 1, size = year_state_inc$voters, prob = pred_inc_vote)
  
  inc_vs <- sim_inc_votes/year_state_inc$voters
  
  tib <- tibble(state = s, year = 2008, winner = ifelse(inc_vs > 0.5 & (true_inc / year_state_inc$voters) > 0.5, 1, 
                                                        ifelse(inc_vs < 0.5 & (true_inc / year_state_inc$voters) < 0.5, 1, 0)))
  
  output_2 <- output_2 %>% bind_rows(tib)
}

cor_08_in_samp <- mean(output_2$winner, na.rm = T)

# Measuring fit for 2012

mod_dat_5 <- na.omit(mod_dat) %>% 
  filter(year == 2012)

output_2 <- tibble()

for(s in unique(mod_dat_5$state)) {
  
  year_state_inc <- subset(mod_dat_5, subset = state == s)
  
  true_inc <- year_state_inc %>% 
    pull(inc_vote)
  
  glm_mod_dat <- mod_dat
  
  out_samp_mod <- glm(cbind(inc_vote, voters-inc_vote) ~ avg_poll + avg_approve + asian_change + black_change + hispanic_change + female_change + party +
                        age3045_change + age4565_change + age65_change, glm_mod_dat,
                      
                      family = binomial)
  
  pred_inc_vote <- predict(out_samp_mod, newdata = year_state_inc, type = "response")[[1]]
  
  sim_inc_votes <- rbinom(n = 1, size = year_state_inc$voters, prob = pred_inc_vote)
  
  inc_vs <- sim_inc_votes/year_state_inc$voters
  
  tib <- tibble(state = s, year = 2012, winner = ifelse(inc_vs > 0.5 & (true_inc / year_state_inc$voters) > 0.5, 1, 
                                                        ifelse(inc_vs < 0.5 & (true_inc / year_state_inc$voters) < 0.5, 1, 0)))
  
  output_2 <- output_2 %>% bind_rows(tib)
}

cor_12_in_samp <- mean(output_2$winner, na.rm = T)

# Measuring fit for 2016

mod_dat_6 <- na.omit(mod_dat) %>% 
  filter(year == 2016)

output_2 <- tibble()

for(s in unique(mod_dat_6$state)) {
  
  year_state_inc <- subset(mod_dat_6, subset = state == s)
  
  true_inc <- year_state_inc %>% 
    pull(inc_vote)
  
  glm_mod_dat <- mod_dat
  
  out_samp_mod <- glm(cbind(inc_vote, voters-inc_vote) ~ avg_poll + avg_approve + asian_change + black_change + hispanic_change + female_change + party +
                        age3045_change + age4565_change + age65_change, glm_mod_dat,
                      
                      family = binomial)
  
  pred_inc_vote <- predict(out_samp_mod, newdata = year_state_inc, type = "response")[[1]]
  
  sim_inc_votes <- rbinom(n = 1, size = year_state_inc$voters, prob = pred_inc_vote)
  
  inc_vs <- sim_inc_votes/year_state_inc$voters
  
  tib <- tibble(state = s, year = 2016, winner = ifelse(inc_vs > 0.5 & (true_inc / year_state_inc$voters) > 0.5, 1, 
                                                        ifelse(inc_vs < 0.5 & (true_inc / year_state_inc$voters) < 0.5, 1, 0)))
  
  output_2 <- output_2 %>% bind_rows(tib)
}

cor_16_in_samp <- mean(output_2$winner, na.rm = T)

# Total correct state prediction rate

pred_df_in_samp <- data.frame(type = "In Sample", year = c(1996, 2000, 2004, 2008, 2012, 2016), correct_perc = c(cor_96_in_samp, cor_00_in_samp, cor_04_in_samp,
                                                                                     cor_08_in_samp, cor_12_in_samp, cor_16_in_samp))

pred_df_both <- pred_df %>% 
  bind_rows(pred_df_in_samp)

outsamp_graph <- pred_df_both %>% 
  ggplot(aes(x = as.factor(year), y = correct_perc, fill = type)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(y = "States Predicted Correctly (%)", x = "", title = "Out of Sample Classification Accuracy") +
  scale_fill_manual(values = c("steelblue2", "indianred"), name = "Forecast Type") +
  coord_flip() +
  geom_hline(yintercept = mean(pred_df$correct_perc), lty = 2, lwd = 1.3, color = "red") +
  geom_hline(yintercept = mean(pred_df_in_samp$correct_perc), lty = 2, lwd = 1.3, color = "blue") +
  annotate("text", label = "Avg\n (0.8)", x = 6, y = 0.85, size = 4) +
  annotate("text", label = "Avg\n (0.9)", x = 6, y = 0.95, size = 4) +
  theme_clean()
  
ggsave(path = "images", filename = "final_samp_graph.png", height = 6, width = 10)

# Making 95% conf interval for Trump electoral votes

trump_interval <- predict_ec %>% 
  filter(winner == "republican") %>% 
  pull(votes) %>% 
  quantile(probs = c(0.025, 0.975))

# Point prediction states

states_point_prediction$state <- state.name[match(states_point_prediction$state, state.abb)]
states_point_prediction$state[51] <- "District of Columbia"

statebin_map_2 <- states_point_prediction %>% 
  ggplot(aes(state = state, fill = fct_relevel(winner, "Biden", "Trump"))) +
  geom_statebins() +
  theme_statebins() +
  labs(title = "2020 Presidential Election Prediction Map",
       fill = "") +
  scale_fill_manual(values=c("steelblue2", "indianred"), breaks = c("Biden", "Trump"))

ggsave(path = "images", filename = "final_prediction_map.png", height = 6, width = 10)
