
# Loading libraries

library(quanteda)
library(tidyverse)
library(ggplot2)
library(gt)
library(broom)
library(skimr)
library(lubridate)
library(janitor)
library(dotwhisker)
library(ggthemes)
library(webshot)

# Loading data

clinton_speeches <- read_csv("data/hilary_clinton_speeches.csv")
trump_speeches <- read_csv("data/donald_trump_speeches.csv")
sanders_speeches <- read_csv("data/bernie_sanders_speeches.csv")
romney_speeches <- read_csv("data/mitt_romney_speeches.csv")
obama_speeches <- read_csv("data/barack_obama_speeches.csv")
mccain_speeches <- read_csv("data/john_mccain_speeches.csv")
biden_trump_speeches <- read_csv("data/campaignspeech_2019-2020.csv") %>% 
  mutate(Speaker = candidate, Date = approx_date, Title = title, Source = url, Text = text, Region = NA) %>% 
  select(Speaker, Date, Title, Region, Source, Text)

speeches <- bind_rows(clinton_speeches, trump_speeches,
                      sanders_speeches, romney_speeches,
                      obama_speeches, mccain_speeches, biden_trump_speeches)

tidy_speeches <- speeches %>% 
  clean_names() %>% 
  filter(speaker == "Donald Trump" | speaker == "Hilary Clinton" |
           speaker == "Bernie Sanders" | speaker == "Mitt Romney" |
           speaker == "Barack Obama" | speaker == "John McCain" |
           speaker == "Joe Biden")
