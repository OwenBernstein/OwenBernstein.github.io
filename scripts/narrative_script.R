
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
library(patchwork)

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
  filter(speaker == "Donald Trump" | speaker == "Hillary Clinton" |
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
                          "obama", "hillary", "clinton")) %>%
  tokens_remove(pattern=stopwords("en")) %>%
  tokens_select(min_nchar=3)

speech_dfm <- dfm(speech_toks, groups = "speaker")

all_words_cloud <- textplot_wordcloud(speech_dfm, color = c("red", "orange",
                                                            "yellowgreen", "green",
                                                            "blue", "purple", "violet"),
                                      comparison = T)

ggsave(path = "images", filename = "all_words_cloud.png", height = 6, width = 10)

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

ggsave(path = "images", filename = "trump_relative.png", height = 6, width = 10)

biden_keyness <- textstat_keyness(content_words, target = "Joe Biden")
biden_relative <- textplot_keyness(biden_keyness)

ggsave(path = "images", filename = "biden_relative.png", height = 6, width = 10)



# Making content categories by grouping

content_categories <- dfm_lookup(speech_dfm, dictionary = content_dict)

content_df <- convert(content_categories, to = "data.frame") %>% 
  group_by(doc_id) %>% 
  mutate(total = populism + environment + immigration + progressive + conservative) %>% 
  mutate(populism_percent = populism / total * 100,
       environment_percent = environment / total * 100,
       immigration_percent = immigration / total * 100,
       progressive_percent = progressive / total * 100,
       conservatism_percent = conservative / total * 100)

populism_bar <- content_df %>% 
  ggplot(aes(x = reorder(doc_id, -populism_percent), populism_percent)) +
  geom_bar(stat = "identity", fill = "steelblue2") + 
  labs(title = "Populist Language",
       x = "", y = "Percent") +
  theme_clean() +
  theme(axis.line = element_line()) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  geom_hline(yintercept = mean(content_df$populism_percent), color = "indianred", lty = 2, lwd = 1.3)

environment_bar <- content_df %>% 
  ggplot(aes(x = reorder(doc_id, -environment_percent), environment_percent)) +
  geom_bar(stat = "identity", fill = "steelblue2") + 
  labs(title = "Language Relating to the Environment",
       x = "", y = "Percent") +
  theme_clean() +
  theme(axis.line = element_line()) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  geom_hline(yintercept = mean(content_df$environment_percent), color = "indianred", lty = 2, lwd = 1.3)

immigration_bar <- content_df %>% 
  ggplot(aes(x = reorder(doc_id, -immigration_percent), immigration_percent)) +
  geom_bar(stat = "identity", fill = "steelblue2") + 
  labs(title = "Language Relating to Immigration",
       x = "", y = "Percent") +
  theme_clean() +
  theme(axis.line = element_line()) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  geom_hline(yintercept = mean(content_df$immigration_percent), color = "indianred", lty = 2, lwd = 1.3)

progressive_bar <- content_df %>% 
  ggplot(aes(x = reorder(doc_id, -progressive_percent), progressive_percent)) +
  geom_bar(stat = "identity", fill = "steelblue2") + 
  labs(title = "Progressive Language",
       x = "", y = "Percent") +
  theme_clean() +
  theme(axis.line = element_line()) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  geom_hline(yintercept = mean(content_df$progressive_percent), color = "indianred", lty = 2, lwd = 1.3)

conservative_bar <- content_df %>% 
  ggplot(aes(x = reorder(doc_id, -conservatism_percent), conservatism_percent)) +
  geom_bar(stat = "identity", fill = "steelblue2") + 
  labs(title = "Conservative Language",
       x = "", y = "Percent") +
  theme_clean() +
  theme(axis.line = element_line()) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  geom_hline(yintercept = mean(content_df$conservatism_percent), color = "indianred", lty = 2, lwd = 1.3)

content_cat_bars <- (populism_bar + progressive_bar + conservative_bar) / (immigration_bar + environment_bar)

ggsave(path = "images", filename = "content_cat_bars.png", height = 6, width = 10)

# Changes in Trump language over campaigns

tidy_speeches$date <- mdy(tidy_speeches$date)

speeches_time <- tidy_speeches %>% 
  filter(speaker == "Donald Trump") %>% 
  mutate(date = floor_date(date, "year"))

time_corpus <- corpus(speeches_time, text_field = "text")


time_toks <- tokens(time_corpus, 
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
                           "obama", "hillary", "clinton")) %>%
  tokens_remove(pattern=stopwords("en")) %>%
  tokens_select(min_nchar=3)

time_dfm <- dfm(time_toks, groups = c("date"))

recent_keyness <- textstat_keyness(time_dfm, target = "2020-01-01")
recent_relative <- textplot_keyness(recent_keyness, n = 15L)

ggsave(path = "images", filename = "trump_recent_relative.png", height = 6, width = 10)

# Most used phrases for Trump by month

speeches_time <- tidy_speeches %>% 
  filter(speaker == "Donald Trump") %>% 
  filter(date > as.Date("2018-01-01")) %>% 
  mutate(date = floor_date(date, "bimonth"))

time_corpus <- corpus(speeches_time, text_field = "text")

time_toks <- tokens(time_corpus, 
                    remove_punct = TRUE,
                    remove_symbols = TRUE,
                    remove_numbers = TRUE,
                    remove_url = TRUE) %>% 
  tokens_tolower() %>%
  tokens_remove(pattern= c("applause", "inaudible","cheers", "laughing",
                           "[applause]", "[inaudible]", "[cheers]",
                           "[laughing]", "(applause)", "(inaudible)","(cheers)",
                           "(laughing)", "joe","biden","donald","trump",
                           "president","kamala","harris", "john", "mccain", "romney",
                           "mitt", "governor", "senator", "bernie", "sanders", "barack", 
                           "obama", "hillary", "clinton")) %>%
  tokens_remove(pattern=stopwords("en")) %>%
  tokens_select(min_nchar=3) %>% 
  tokens_ngrams(n = 2)

time_dfm <- dfm(time_toks, groups = c("date"))

trump_months_wordcloud <- textplot_wordcloud(time_dfm, comparison = T, min_count = 15)

# Most used phrases by month Biden

speeches_time <- tidy_speeches %>% 
  filter(speaker == "Joe Biden") %>% 
  filter(date > as.Date("2018-01-01")) %>% 
  mutate(date = floor_date(date, "bimonth"))

time_corpus <- corpus(speeches_time, text_field = "text")

time_toks <- tokens(time_corpus, 
                    remove_punct = TRUE,
                    remove_symbols = TRUE,
                    remove_numbers = TRUE,
                    remove_url = TRUE) %>% 
  tokens_tolower() %>%
  tokens_remove(pattern= c("applause", "inaudible","cheers", "laughing",
                           "[applause]", "[inaudible]", "[cheers]",
                           "[laughing]", "(applause)", "(inaudible)","(cheers)",
                           "(laughing)", "joe","biden","donald","trump",
                           "president","kamala","harris", "john", "mccain", "romney",
                           "mitt", "governor", "senator", "bernie", "sanders", "barack", 
                           "obama", "hillary", "clinton")) %>%
  tokens_remove(pattern=stopwords("en")) %>%
  tokens_select(min_nchar=3) %>% 
  tokens_ngrams(n = 2)

time_dfm <- dfm(time_toks, groups = c("date"))

biden_months_wordcloud <- textplot_wordcloud(time_dfm, comparison = T, min_count = 15)




