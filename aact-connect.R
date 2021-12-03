# Title:       AACT Connect
# Project:     TRIDIVE
# Date:        2021-12-03
# Author:      Clare Gibson

# SUMMARY ############################################################
# This script establishes a connection to the Access to Aggregate
# Content of ClinicalTrials.gov (AACT) database.
# Source: https://aact.ctti-clinicaltrials.org/

# PACKAGES ###########################################################
library(RPostgreSQL)
library(rstudioapi)

# CONNECT TO THE DATABASE ############################################
drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv,
                 dbname="aact",
                 host="aact-db.ctti-clinicaltrials.org",
                 port=5432,
                 user=askForPassword("Database user"),
                 password=askForPassword("Database password"))

# TEST QUERIES #######################################################
q1 <- 
  "SELECT DISTINCT name FROM countries"
df_q1 <- dbGetQuery(con, q1)

q2 <- 
  "SELECT DISTINCT study_type FROM studies"
df_q2 <- dbGetQuery(con, q2)
