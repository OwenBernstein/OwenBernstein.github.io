# Introduction R Script.

library(tidyverse)
library(ggplot2)
library(usmap)
library(ggthemes)
library(ggrepel)

# Reading in data.

popvote_df <- read.csv("data/popvote_1948-2016.csv")
pvstate_df <- read.csv("data/popvote_bystate_1948-2016.csv")

# Creating graph of historical trends in popular vote. Adding a ggtheme and
# other custom themes to make it readable.

popvote_df %>%
  ggplot(aes(x = year, y = pv2p, colour = party)) +
  geom_line(stat = "identity") +
  scale_color_manual(
    values = c("blue", "red"),
    name = "",
    labels = c("Democrat", "Republican")
  ) +
  xlab("") +
  ylab("Two Party Popular Vote (%)") +
  ggtitle("Presidential Vote Share (1948-2016)") +
  scale_x_continuous(breaks = seq(from = 1948, to = 2016, by = 4)) +
  ylim(32, 66) +
  theme_fivethirtyeight() +
  theme(axis.text.x  = element_text(angle = 45, hjust = 1),
        axis.text = element_text(size = 12))

# Saving image to the figures file.

ggsave(path = "images", filename = "PV_national_historical.png", height = 4, width = 8)

# Creating a data frame of swing states from 2000 - 2016. This is done by
# counting the number of times the GOP won and creating a new variable with this
# value. Then filtering for only unique rows.

swing_states <- pvstate_df %>% 
  filter(year >= 2000) %>% 
  mutate(rep_win = ifelse(R_pv2p > D_pv2p, 1, 0)) %>% 
  group_by(state) %>% 
  mutate(num_rep_w = sum(rep_win)) %>% 
  mutate(swing_state = ifelse(num_rep_w > 0 & num_rep_w < 5, 1, 0)) %>% 
  select(state, num_rep_w) %>% 
  unique() %>% 
  mutate(num_rep_w = as.factor(num_rep_w))

# Making the number of republican wins a factor.

swing_states$num_rep_w <- factor(swing_states$num_rep_w, levels = c("5", "4", "3", "2", "1", "0"))

# Plotting the swing state graph with some custom gradients. 

plot_usmap(data = swing_states, regions = "states", values = "num_rep_w", labels = T) +
  scale_fill_manual(values = c("white", "red", "pink", "skyblue", "blue", "white"), name = "GOP Election Wins") +
  theme_void() +
  labs(title = "Swing States from 2000 - 2016") 
  
# Saving the graph to the figures folder. 

ggsave(path = "images", filename = "swing_states_historical.png", height = 3, width = 8)

# Making a variable of win margins.Using code directly from the lab. 

pv_margins_map <- pvstate_df %>%
  filter(year >= 2000) %>%
  mutate(win_margin = (R_pv2p-D_pv2p))

# Making a map of win margin by state facet wrapped by year. The code is from
# the lab with changed limits and an added facet wrap.

plot_usmap(data = pv_margins_map, regions = "states", values = "win_margin") +
  facet_wrap(~ year) +
  scale_fill_gradient2(
    high = "red", 
    mid = "white",
    low = "blue", 
    breaks = c(-50,-25,0,25,50), 
    limits = c(-55,55),
    name = "win margin"
  ) +
  theme_void()

# Saving the graph to figures.

ggsave(path = "images", filename = "victory_margins_historical.png", height = 3, width = 8)

battleground <- pvstate_df %>%
  filter(
    state == "Nevada" | state == "Colorado" | state == "Iowa" |
      state == "Ohio" | state == "Florida" | state == "Virginia") %>% 
  filter(year >= 2012)


dem_battle <- battleground %>% 
  select(state, year, D_pv2p) %>% 
  pivot_wider(names_from = "year", values_from = "D_pv2p" ) %>% 
  mutate(d_vs_2020 = `2012` * 0.25 + `2016` * 0.75) %>% 
  mutate(vote_margin_2020 = d_vs_2020 - (100 - d_vs_2020),
         vote_margin_2016 = `2016` - (100 - `2016`),
         vote_margin_2012 = `2012` - (100 - `2012`)) %>% 
  select(state, vote_margin_2020: vote_margin_2012) %>% 
  pivot_longer(cols = c("vote_margin_2020" : "vote_margin_2012"), names_to = "year", values_to = "vote_margin")

dem_battle$year=gsub("vote_margin_","", dem_battle$year)
dem_battle$year = as.double(dem_battle$year)

dem_battle %>% 
  ggplot(aes(x=year, y=vote_margin, color=vote_margin)) + 
  facet_wrap(. ~ state) + 
  ## add plot elements
  geom_hline(yintercept=0,color="gray") +
  geom_line(size=2) + 
  geom_point(size=5) +
  ## specify scale colors
  scale_colour_gradient(low = "red", high = "blue") +
  scale_fill_gradient(low = "red", high = "blue") +
  ## specify titles, labels
  xlab("") +
  ylab("Democrat Vote-Share Margin") + 
  ggtitle("Predicting Swing States in 2020") +
  ## switch position of x-axis and y-axis
  coord_flip() +
  ## make x-axis (year) run from top to bottom
  scale_x_reverse(breaks=c(2012, 2016, 2020)) +
  theme_minimal() + 
  theme(panel.border    = element_blank(),
        plot.title      = element_text(size = 20, hjust = 0.5, face="bold"), 
        legend.position = "none",
        axis.title      = element_text(size=18),
        axis.text.x     = element_text(angle = 45, hjust = 1),
        axis.text       = element_text(size = 18),
        strip.text      = element_text(size = 18, face = "bold"))


ggsave(path = "images", filename = "swing_state_margins.png", height = 15, width = 8)
