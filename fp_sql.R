## Following packages are required 
## Install them in console if you haven't already installed them before

library(tidyverse)
library(lubridate)
library(RSQLite)

sqlite.driver <- dbDriver("SQLite")

## read the fpdb files
## Change path to the appropriate file in the line below

db <- dbConnect(sqlite.driver, "data/fprime.fpdb")

db_list_tables(db)

t_i_dat <- dbReadTable(db, "traitInstance")

t_i_dat <- t_i_dat %>% 
  rename(traitInstance_id = X_id) %>% 
  select(traitInstance_id, trait_id)

trt_dat <- dbReadTable(db, "trait")

trt_dat <- trt_dat %>% 
  select(trait_id = id, trait_name = caption)

t_i_dat <- t_i_dat %>% 
  left_join(trt_dat)

raw_dat <- dbReadTable(db, "datum")

raw_dat <- raw_dat %>% 
  left_join(t_i_dat) %>% 
  select(node_id, value, trait_name, timestamp, userid)

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

## Change output filename to whatever suits you
## When you run it again make sure you change the name so that you are not overwriting

write_csv(raw_dat, "output/fp_output.csv", na = "")

## Clearing rstudio - optional!!

rm(list = ls())
cat("\014")
