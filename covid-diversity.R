# Title:       COVID Diversity
# Project:     TRIDIVE
# Date:        2021-12-13
# Author:      Clare Gibson

# SUMMARY ############################################################
# This script gathers and cleans the data needed for my analysis of
# diversity in US COVID trials which have published results.

# PACKAGES ###########################################################
library(RPostgreSQL)    # to connect to AACT database
library(rstudioapi)     # to mask AACT credentials
library(tidyverse)      # general data wrangling

# DATA SOURCES #######################################################
# COVID-19 US Trial Particpants
# Source: https://clinicaltrials.gov/ (Accessed via the AACT
# database)

# DATA CONNECTIONS ###################################################
drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv,
                 dbname="aact",
                 host="aact-db.ctti-clinicaltrials.org",
                 port=5432,
                 user=askForPassword("Database user"),
                 password=askForPassword("Database password"))

# READ DATA ##########################################################
# Write query to return trial IDs of interest
query_nct_id <- 
  "SELECT
     s.nct_id
   FROM studies s
   INNER JOIN browse_conditions b
   ON s.nct_id = b.nct_id
   WHERE s.results_first_submitted_date IS NOT NULL
   AND b.mesh_term IN ('COVID-19',
					  'COVID',
					  'SARS-CoV-2',
					  'Coronavirus disease 2019',
					  'Severe Acute Respiratory Syndrome Coronavirus 2',
					  'Novel Coronavirus',
					  'Coronavirus Disease 19',
					  '2019-nCoV',
					  'SARS Coronavirus 2',
					  'Wuhan Coronavirus')"

# Run trial ID query
df_nct_id <- dbGetQuery(con, query_nct_id)

# Write query to return countries associated with trial IDs
query_country <- 
  "SELECT
     nct_id,
     name
   FROM countries
   WHERE nct_id IN (
     SELECT
       s.nct_id
     FROM studies s
     INNER JOIN browse_conditions b
     ON s.nct_id = b.nct_id
     WHERE s.results_first_submitted_date IS NOT NULL
     AND b.mesh_term IN ('COVID-19',
					  'COVID',
					  'SARS-CoV-2',
					  'Coronavirus disease 2019',
					  'Severe Acute Respiratory Syndrome Coronavirus 2',
					  'Novel Coronavirus',
					  'Coronavirus Disease 19',
					  '2019-nCoV',
					  'SARS Coronavirus 2',
					  'Wuhan Coronavirus'))"

# Run countries query
df_countries <- dbGetQuery(con, query_country) %>% 
  group_by(nct_id) %>% 
  mutate(country_cnt = n()) %>% 
  ungroup() %>% 
  filter(country_cnt == 1,
         name == "United States") %>% 
  select(-country_cnt)

# Write query to return baseline measurements
query_demog <- 
  "SELECT
     nct_id,
     ctgov_group_code,
     classification AS demog_classification,
     category,
     title AS demog_title,
     description AS demog_description,
     units,
     param_type,
     param_value_num
   FROM baseline_measurements
   WHERE nct_id IN (
     SELECT
       s.nct_id
     FROM studies s
     INNER JOIN browse_conditions b
     ON s.nct_id = b.nct_id
     WHERE s.results_first_submitted_date IS NOT NULL
     AND b.mesh_term IN ('COVID-19',
					  'COVID',
					  'SARS-CoV-2',
					  'Coronavirus disease 2019',
					  'Severe Acute Respiratory Syndrome Coronavirus 2',
					  'Novel Coronavirus',
					  'Coronavirus Disease 19',
					  '2019-nCoV',
					  'SARS Coronavirus 2',
					  'Wuhan Coronavirus'))"

# Run demographics query
df_demog <- dbGetQuery(con, query_demog)

# Write query to return result titles
query_results <- 
  "SELECT
     nct_id,
     ctgov_group_code,
     result_type,
     title AS results_title,
     description AS results_description
   FROM result_groups
   WHERE nct_id IN (
     SELECT
       s.nct_id
     FROM studies s
     INNER JOIN browse_conditions b
     ON s.nct_id = b.nct_id
     WHERE s.results_first_submitted_date IS NOT NULL
     AND b.mesh_term IN ('COVID-19',
					  'COVID',
					  'SARS-CoV-2',
					  'Coronavirus disease 2019',
					  'Severe Acute Respiratory Syndrome Coronavirus 2',
					  'Novel Coronavirus',
					  'Coronavirus Disease 19',
					  '2019-nCoV',
					  'SARS Coronavirus 2',
					  'Wuhan Coronavirus'))"

# Run results query
df_results <- dbGetQuery(con, query_results)

# CLEAN DATA #####################################################
# Join data
df <- df_countries %>% 
  left_join(df_demog) %>% 
  left_join(df_results) %>% 
  filter(results_title == "Total")

df_race <- df %>% 
  filter(demog_title == "Race (NIH/OMB)") %>% 
  mutate(ethnicity = coalesce(category,
                              demog_classification)) %>% 
  select(nct_id,
         ethnicity,
         part_cnt = param_value_num) %>% 
  group_by(nct_id) %>% 
  mutate(part_pct = part_cnt/sum(part_cnt)) %>% 
  ungroup() %>%
  mutate(ethnicity = str_to_lower(ethnicity)) %>% 
  mutate(ethnic_group = case_when(
    is.na(ethnicity) ~ "Not Reported",
    grepl("(missing|reported|unknown|prefer)",
          ethnicity) ~ "Not Reported",
    grepl("(african|black)",
          ethnicity) ~ "Black or African-American",
    grepl("(alaska|native american)",
          ethnicity) ~ "American Indian or Alaska Native",
    grepl("(caucasian|white)",
          ethnicity) ~ "White",
    grepl("asian",
          ethnicity) ~ "Asian",
    grepl("hawaiian",
          ethnicity)~"Native Hawaiian or Other Pacific Islander",
    grepl("(middle|other)",
          ethnicity) ~ "Some Other Race",
    grepl("not hispanic",
          ethnicity) ~ "Not Hispanic or Latino",
    grepl("(hispanic|latin)",
          ethnicity) ~ "Hispanic or Latino",
    grepl("(mixed|more|multi)",
          ethnicity) ~ "Two or More Races",
    TRUE ~ ethnicity
  ))

df_gender <- df %>% 
  filter(str_detect(demog_title, "(Sex|Gender)")) %>% 
  mutate(gender = coalesce(category,
                           demog_classification),
         gender = case_when(grepl("Female",
                                  gender) ~ "Female",
                            grepl("Male",
                                  gender) ~ "Male",
                            TRUE ~ gender)) %>% 
  filter(gender %in% c("Male", "Female")) %>% 
  select(nct_id,
         gender,
         part_cnt = param_value_num) %>% 
  group_by(nct_id) %>% 
  mutate(part_pct = part_cnt/sum(part_cnt)) %>% 
  ungroup()

df_ethnic_groups <- df_race %>% 
  group_by(ethnic_group, ethnicity) %>% 
  summarise(count = n())

# EXPORT DATA ###################################################
write_csv(df_race,"data-out/df_race.csv", na="")
write_csv(df_gender, "data-out/df_gender.csv", na="")
