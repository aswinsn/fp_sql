## Following packages are required 
## Install them in console if you haven't already installed them before

library(tidyverse)
library(lubridate)
library(RSQLite)

sqlite.driver <- dbDriver("SQLite")

## read the fpdb files
## Change path to the appropriate file in the line below

db <- dbConnect(sqlite.driver, "c:/Users/sin17m/Documents/Corrine/Backup tab 4 18082020")

db_list_tables(db)

## Trait instance

t_i_dat <- dbReadTable(db, "traitInstance")

t_i_dat <- t_i_dat %>% 
  rename(traitInstance_id = X_id) %>% 
  select(traitInstance_id, trait_id)

## Trait names

trt_dat <- dbReadTable(db, "trait")

trt_dat <- trt_dat %>% 
  select(trait_id = id, trait_name = caption)

t_i_dat <- t_i_dat %>% 
  left_join(trt_dat)

## Datum value field

raw_dat <- dbReadTable(db, "datum")

unit_id <- raw_dat %>% 
  distinct(node_id) %>% 
  filter(node_id >= 10460)

raw_dat <- raw_dat %>% 
  left_join(t_i_dat) %>% 
  select(node_id, value, trait_name, timestamp, userid)

## fp Notes

note_dat <- dbReadTable(db, "nodeNote")

note_dat <- note_dat %>% 
  select(node_id, note)

raw_dat <- raw_dat %>% 
  left_join(note_dat)

## Change tz below to appropriate timezone. Note Perth is different to other states 

raw_dat$date_time <- as_datetime(as.numeric((raw_dat$timestamp)/1000), tz = "Australia/Perth")

nd_att <- dbReadTable(db, "nodeAttribute")
att_dat <- dbReadTable(db, "attributeValue")

att_dat <- att_dat %>% 
  left_join(nd_att, by =c("nodeAttribute_id"="id")) %>% 
  select(node_id, value, name) %>% 
  pivot_wider(names_from = name, values_from = value)

raw_dat <- raw_dat %>% 
  left_join(att_dat)

node <- dbReadTable(db, "node") %>% 
  select(node_id = id, row, col)

raw_dat <- raw_dat %>% 
  left_join(node) %>% 
  arrange(row, col, date_time) 

dis_rr <- raw_dat %>% 
  select(node_id, row, col, id, variety) %>% 
  distinct() %>% 
  arrange(row, col, node_id) %>% 
  group_by(row, col) %>% 
  mutate(t_num = 1:n())

f_layout <- dis_rr %>% 
  filter(t_num == 2) %>% 
  ggplot(aes(row, col))+
  geom_tile(fill = "gray",colour = "black")+
  geom_text(aes(label = variety), size = 2.25)+
  scale_x_continuous(breaks = 1:12, expand = c(0,0))+
  scale_y_continuous(breaks = seq(0,80,5), expand = c(0,0))+
  theme_bw()+
  labs(caption = "2020 WA FP DATA - Tab 4")

f_layout

dir.create("plots")

ggsave("plots/2020_tab_10_data.png", f_layout, units = "in", height = 9, width = 16)

## Change output filename to whatever suits you
## When you run it again make sure you change the name so that you are not overwriting

write_csv(raw_dat, "output/fp_output_tab-04.csv", na = "")

## Clearing rstudio - optional!!

rm(list = ls())
cat("\014")
