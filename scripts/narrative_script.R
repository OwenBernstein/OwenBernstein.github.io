
# Loading libraries

library(quanteda)
library(tidyverse)
library(ggplot2)
library(gt)
library(broom)
library(skimr)
library(lubridate)
library(janitor)
library(tidytext)
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
  select(Speaker, Date, Title, Region, Source, Text) %>% 
  filter(Speaker == "Joe Biden" | Speaker == "Donald Trump")

speeches <- bind_rows(clinton_speeches, trump_speeches,
                      sanders_speeches, romney_speeches,
                      obama_speeches, mccain_speeches, biden_trump_speeches)

tidy_speeches <- speeches %>% 
  clean_names() %>% 
  filter(speaker == "Donald Trump" | speaker == "Hilary Clinton" |
           speaker == "Bernie Sanders" | speaker == "Mitt Romney" |
           speaker == "Barack Obama" | speaker == "John McCain" |
           speaker == "Joe Biden")

# Making corpus

speech_corpus <- corpus(tidy_speeches, text_field = "text")


speech_toks <- tokens(speech_corpus, 
                      remove_punct = TRUE,
                      remove_symbols = TRUE,
                      remove_numbers = TRUE,
                      remove_url = TRUE) %>% 
  tokens_wordstem() %>% 
  tokens_tolower() %>%
  tokens_remove(pattern= c("applause", "inaudible","cheers", "laughing",
                          "[applause]", "[inaudible]", "[cheers]",
                          "[laughing]", "(applause)", "(inaudible)","(cheers)",
                          "(laughing)", "joe","biden","donald","trump",
                          "president","kamala","harris", "john", "mccain", "romney",
                          "mitt", "governor", "senator", "bernie", "sanders", "barack", 
                          "obama", "hilary", "clinton")) %>%
  tokens_remove(pattern=stopwords("en")) %>%
  tokens_select(min_nchar=3)

speech_dfm <- dfm(speech_toks, groups = "speaker")

all_words_cloud <- textplot_wordcloud(speech_dfm, color = c("red", "orange",
                                                            "yellowgreen", "green",
                                                            "blue", "purple", "violet"),
                                      comparison = T)

# Making content categories by word

content_dict <- dictionary(list(populism = c("deceit", "treason",
                             "betray", "absurd",
                             "arrogant", "promise", 
                             "corrupt", "direct",
                             "elite", "establishment",
                             "ruling", "caste",
                             "class", "mafia",
                             "undemocratic", "politic",
                             "propaganda", "referend",
                             "regime", "shame",
                             "admit", "tradition",
                             "people"),
                environment = c("green","climate",
                                "environment","heating",
                                "durable"),
                immigration = c("asylum","halal",
                                "scarf","illegal",
                                "immigra","Islam", 
                                "Koran","Muslim",
                                "foreign"),
                progressive = c("progress","right",
                                "freedom","self-disposition",
                                "handicap","poverty",
                                "protection","honest",
                                "equal","education",
                                "pension","social",
                                "weak"),
                conservative = c("belief","famil",
                                 "church","norm",
                                 "porn","sex",
                                 "values","conservative",
                                 "conservatism","custom")))

content_words <- dfm_select(speech_dfm, pattern = content_dict, selection = "keep")

trump_keyness <- textstat_keyness(content_words, target = "Donald Trump")
trump_relative <- textplot_keyness(trump_keyness)

biden_keyness <- textstat_keyness(content_words, target = "Joe Biden")
biden_relative <- textplot_keyness(biden_keyness)

# Making content categories by grouping

content_categories <- dfm_lookup(speech_dfm, dictionary = content_dict)

content_df <- convert(content, to = "data.frame") %>% 
  group_by(doc_id) %>% 
  mutate(total = populism + environment + immigration + progressive + conservative) %>% 
  mutate(populism_percent = populism / total * 100,
       environment_percent = environment / total * 100,
       immigration_percent = immigration / total * 100,
       progressive_percent = progressive / total * 100,
       conservatism_percent = conservative / total * 100)

populism_box <- content_df %>% 
  ggplot(., aes(doc_id, populism_percent)) +
  geom_bar(stat = "identity") + 
  labs(title = "Populist Language in Speeches by Candidate",
       x = "Candidate", y = "Percent Populist Language") +
  theme_minimal() +
  theme(axis.line = element_line())
