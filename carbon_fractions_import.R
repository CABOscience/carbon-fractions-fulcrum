# import carbon fractions data into fulcrum

library(googlesheets)
library(tidyverse)


##### importer donnees dans R
gs_auth()
carbon <- gs_url('https://docs.google.com/spreadsheets/d/1N-e2n-yX2aAz0bn9beYySSaG08T4oG5yo-UDfMmBUS4/edit?usp=sharing')

girard <- gs_read_csv(carbon, ws = 'Girard')
rioux <- gs_read_csv(carbon, ws = 'Beauchamp-Rioux')


# create new parent record
girard_analyses <- girard %>%
  select(batch_number, project, date_started) %>% 
  filter(!is.na(batch_number) ) %>% 
  distinct()

rioux_analyses <- rioux %>%
  select(batch_number, project, date_started) %>% 
  filter(!is.na(batch_number),
         !is.na(date_started),
         batch_number != 'batch_number') %>% 
  distinct()

# merge the two together
carbon_parent <- girard_analyses %>% 
  rbind(rioux_analyses) %>% 
  mutate(measured_by = 'Fabien Cichonski',
         analysis_remarks = paste('Batch number', batch_number))


# export csv, then import into Fulcrum
write.csv(carbon_parent, file = 'carbon_parent.csv', row.names = F,
          na = '')
