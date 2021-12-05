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
  "SELECT DISTINCT enrollment_type FROM studies"
df_q2 <- dbGetQuery(con, q2)

q3 <- 
  "SELECT DISTINCT mesh_type FROM browse_conditions"
df_q3 <- dbGetQuery(con, q3)

q4 <- 
  "SELECT * FROM baseline_measurements LIMIT 100"
df_q4 <- dbGetQuery(con, q4)

q5 <- 
  "SELECT DISTINCT title FROM baseline_measurements"
df_q5 <- dbGetQuery(con, q5)

q6 <- 
  "SELECT * FROM baseline_measurements WHERE title = 'Race / Ethnicity'"
df_q6 <- dbGetQuery(con, q6)

q7 <- 
  "SELECT DISTINCT gender FROM eligibilities"
df_q7 <- dbGetQuery(con, q7)
