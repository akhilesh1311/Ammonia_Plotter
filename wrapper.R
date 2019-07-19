
# Please change this: -----------------------------------------------------

# Directory where all the code files are located
shiny_app_dir <<- "/home/akhil/Documents/winlab/code/ammonia_plotter/"

# List of directory/files to load as given below for example. Files have end in .csv only.
data_dir <<- list(
  # "/home/akhil/Downloads/Plot_Ammonia_4-11-2019", 
  # "/home/akhil/Documents/winlab/controlled_env/Analysis_11-11-2018",
  # "/home/akhil/Documents/winlab/controlled_env/short_exponential_analysis",
  # "/home/akhil/Documents/winlab/controlled_env/Analysis_26_Nov/20181127_103609.csv"
  "/home/akhil/Downloads/20190521_180247.csv"
  )

# Plot type, can be: linePoint, line, point
plot_type <<- "point"

# Sets the height of the plot area
plot_height <<- 700
# Sets the width of the plot area
plot_width <<- 1300

# That's it ---------------------------------------------------------------

# The following command is used to get the milliseconds information stored in posixct Timestamp
options(digits.secs = 3)

# Sets the time-zone for the data loaded
Sys.setenv(TZ = "America/New_York")
options(tz = "America/New_York")

# Remove all the global variables on stopping the shiny app
shiny::onStop(function(){
  print("Doing Application cleanup")
  remove(list = ls())
})
shiny::runApp(appDir = shiny_app_dir, launch.browser = TRUE)


# Install one more package
# install.package("gginnards")
# Update all packages:
# update.packages(ask = FALSE)
# OR
# package_df <- as.data.frame(installed.packages("/home/akhil/R/x86_64-pc-linux-gnu-library/3.4"))
# package_list <- as.character(package_df$Package)
# install.packages(package_list)


# install.packages("scales")
# library(scales)