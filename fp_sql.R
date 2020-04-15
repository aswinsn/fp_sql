library(tidyverse)
library(lubridate)
library(RSQLite)

sqlite.driver <- dbDriver("SQLite")
db <- dbConnect(sqlite.driver, "fprime.fpdb")

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

write_csv(raw_dat, "dion_data_set_3.csv", na = "")
