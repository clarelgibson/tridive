# Title:       COVID Vaccines Wrangle
# Project:     TRIDIVE
# Date:        2021-12-07
# Author:      Clare Gibson

# SUMMARY ############################################################
# This script gathers and cleans the data needed for the COVID
# Vaccines analysis (covid-vaccines.Rmd)

# PACKAGES ###########################################################
library(RPostgreSQL)    # to connect to AACT database
library(rstudioapi)     # to mask AACT credentials
library(tidyverse)      # general data wrangling

# DATA SOURCES #######################################################
# COVID-19 Vaccine Trial Particpants (df_trial) ======================
# Source: https://clinicaltrials.gov/ (Accessed via that AACT
# database)

# COVID-19 Vaccine Doses Administered (df_real) ======================
# Source:
#   https://github.com/BloombergGraphics/covid-vaccine-tracker-data

# DATA CONNECTIONS ###################################################
# AACT Database ======================================================
drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv,
                 dbname="aact",
                 host="aact-db.ctti-clinicaltrials.org",
                 port=5432,
                 user=askForPassword("Database user"),
                 password=askForPassword("Database password"))

# COVID Vaccine Tracker ==============================================
cv_path <- "https://raw.githubusercontent.com/BloombergGraphics/covid-vaccine-tracker-data/master/data/current-global.csv"

# READ DATA ##########################################################
# df_trial ===========================================================
# Write query
cv_trial_query <- 
  "SELECT DISTINCT
     s.nct_id,
     c.name,
     m.*
    FROM studies s
   INNER JOIN designs d
      ON s.nct_id = d.nct_id
   INNER JOIN browse_conditions b
      ON s.nct_id = b.nct_id
   INNER JOIN countries c
      ON s.nct_id = c.nct_id
   INNER JOIN baseline_measurements m
      ON s.nct_id = m.nct_id
   WHERE s.overall_status = 'Completed'
     AND d.primary_purpose = 'Prevention'
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

# Run query
cv_trial_raw <- dbGetQuery(con, cv_trial_query)

# df_real ============================================================
cv_real_raw <- read_csv(cv_path)