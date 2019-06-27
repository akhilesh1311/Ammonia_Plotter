# Ammonia Plotter

Aggregates ammonia sensor data from multiple .csv files, and plots them on a single interactive graph.

## Getting Started

### Prerequisites

R-cran version >= 3.4\
```
install.packages("shiny")
install.packages("shinyTime")
install.packages("gginnards")
install.packages("scales")
install.packages("readr")
install.packages("tidyverse")
install.packages("lubridate")
```

## Deployment

In the wrapper.R file, you have to change the following:

```
# Directory where all the code files are located
shiny_app_dir <<- "/home/akhil/Documents/winlab/code/"

# List of directory/files to load as given below for example. Files have end in .csv only.
data_dir <<- list(
  # "/home/akhil/Downloads/Plot_Ammonia_4-11-2019",
  # "/home/akhil/Documents/winlab/controlled_env/Analysis_11-11-2018",
  # "/home/akhil/Documents/winlab/controlled_env/short_exponential_analysis",
  "/home/akhil/Documents/winlab/controlled_env/Analysis_26_Nov/20181127_103609.csv"
  )

```
Then, run the wrapper.R file from R shell as:
```
source("<path to wrapper.R>")
```
or from command line as:
```
Rscript wrapper.R
```

## Sample Screenshots
![Alt text](sample_screenshot.png?raw=true "Sample Screenshot")\

## Built With

* [R] - Data Aggregation and preprocessing
* [R Shiney] - Web App deployment

## Acknowledgments

* Professor Richard Howard
