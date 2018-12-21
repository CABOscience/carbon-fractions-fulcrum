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

# then export leaf chemistry samples and carbon fractions from both projects (done)
# read the data
carbon_fractions <- read_csv('Fulcrum_Export_feb0fb9b-43ca-4d7b-a6ab-6910e5497f17/carbon_fractions/carbon_fractions.csv')
chemistry <- read_csv('Fulcrum_Export_feb0fb9b-43ca-4d7b-a6ab-6910e5497f17/leaf_chemistry_samples/leaf_chemistry_samples.csv')

# get all bags 
bags <- girard %>%
  rbind(rioux) %>% 
  filter(!is.na(date_started),
         batch_number != 'batch_number') %>% 
  select(batch_number, bag_number, sample_id, project, date_started, empty.bag.wt, sample.wt, ndf.wt, adf.wt, adl.wt, crucib.wt, crucib.ash.wt) %>% 
  rename(empty_bag_weight_g = empty.bag.wt,
         sample_weight_g = sample.wt,
         ndf_weight_g = ndf.wt,
         adf_weight_g = adf.wt,
         adl_weight_g = adl.wt,
         empty_crucible_weight_g = crucib.wt,
         crucible_ash_weight_g = crucib.ash.wt) %>% 
  mutate(sample_type = 'sample',
         quality_flag_bag = 'good',
         date_started = as.Date(date_started)) 

# fill sample_type
bags[bags$sample_id == 'blank', 'sample_type'] <- 'blank'

# remove blank from sample_id
bags[bags$sample_id == 'blank', 'sample_id'] <- NA
bags[is.na(bags$sample_id), 'sample_weight_g'] <- NA

# merge the correct parent id
carbon_fractions_sub <- carbon_fractions %>%
  select(fulcrum_id,
         project,
         date_started)
chemistry_sub <- chemistry %>%
  filter(status != 'deleted') %>% 
  select(fulcrum_id, sample_id) %>% 
  rename(leaf_chemistry_sample = fulcrum_id) %>% 
  mutate(sample_id = as.character(sample_id))
  
bags2 <- bags %>%
  left_join(carbon_fractions_sub) %>% 
  rename(fulcrum_parent_id = fulcrum_id) %>% 
  left_join(chemistry_sub) %>% 
  rename(bottle_id = sample_id) %>% 
  select(-batch_number,
         -project,
         -date_started)
  
# add the bags2
write.csv(bags2, file = 'Fulcrum_Export_feb0fb9b-43ca-4d7b-a6ab-6910e5497f17/carbon_fractions/carbon_fractions_bags_UPDATED.csv', row.names = F,
          na = '')
# now zip, and proceed to Fulcrum export