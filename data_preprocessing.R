# Setting the col names of difference in sequence numbers 
# and difference in timestamps of consecutive rows, respectively.
sequence_diff <- "sequence_diff"
timestamp_diff <- "timestamp_diff"

# This function takes the path of a file, 
# finds the row from where our relevant data is present
# and returns that data.
preprocess <- function(file_path) {
  con <- file(file_path, "r")
  n <- 0
  while(TRUE){
    line <- readLines(con, n = 1) %>% strsplit(split = ",")
    n <- n+1
    if (length(line) == 0){
      break
    }
    line <- line %>% unlist()
    if ("Timestamp" %in% line){
      break
    }
  }
  close(con)
  data <- read_csv(file_path, skip = n-1, col_types = 
                     cols(.default = "d", Date = "c", 'Tag ID' = "i", 'Tag ID (Hex)' = "c", 'sequence number' = "i"))
  return(data)
}

# Data preprocessing helper function
preprocess2 <- function(data){
  data <- data %>%
    add_column(!!(timestamp_diff) := data$Timestamp - data$Timestamp[[1]]) %>% 
    add_column(!!(sequence_diff) := c(data$`sequence number` %>% diff(lag = 1), NA))
  data$Date <- mdy_hms(data$Date, tz=time_zone)
  data$`Tag ID` <- as.character(data$`Tag ID`)
  data$posix_Timestamp <- as.POSIXct(data$Timestamp/1000, origin = "1970-01-01", tz = time_zone)
  return (data)
}

load_data <- function(dir_paths){
  files <- list()
  for (dir_path in dir_paths){
    if (grepl(".csv", dir_path) == TRUE){
      files <- c(files, dir_path)
    }
    else{
      files <- c(files, list.files(path = dir_path, pattern = "*.csv", full.names = T))
    }
  }
  
  # Removing unnecessary columns
  ammonia_data <- sapply(files, preprocess, simplify = FALSE) %>%
    bind_rows() %>%
    subset(select = -c(`Tag ID (Hex)`, RSSI, Moisture, `Battery (mV)`, `Battery (J)`))
  
  # Pre-processing our data
  df_list <- ammonia_data %>% 
    split(ammonia_data$`Tag ID`) %>%
    lapply(preprocess2)
  
  return (df_list)
}