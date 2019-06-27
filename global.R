# Loading all the required libraries
library(shiny)
library(shinyTime)
library(gginnards)
library(scales)
library(readr)
library(tidyverse)
library(lubridate)

print("Loading data")
setwd(dir = shiny_app_dir)
source("./data_preprocessing.R")

# Loading the data files into a list of tibbles
df_list <<- load_data(data_dir)

# Used by ui.R for initializing the date and time selector
date_time <<- df_list %>% 
  bind_rows() %>% 
  subset(select = c(Timestamp, Date)) %>% 
  arrange(Timestamp) %>% 
  subset(select = c(Date))

# Global variables used within server.R for internal communication
print("Setting up global variables")
current_sensors <<- list()
removed_sensors <<- list()
active_sensors_map <<- list()
current_from_date <<- NULL
current_to_date <<- NULL
current_from_time <<- NULL
current_to_time <<- NULL
current_custom_input <<- NULL
# This plot is manipulated on a global level
main_plot <<- ggplot()