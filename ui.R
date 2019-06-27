
ui <- fluidPage(
  titlePanel("Ammonia Sensor"),
  sidebarLayout(
    sidebarPanel(
      dateRangeInput("date", "From/To Dates",
                     start = as.character(date_time$Date[1]) %>% strsplit(" ") %>% unlist() %>% nth(n=1), 
                     end = as.character(tail(date_time, n=1)$Date[1]) %>% strsplit(" ") %>% unlist() %>% nth(n=1),
                     min = as.character(date_time$Date[1]) %>% strsplit(" ") %>% unlist() %>% nth(n=1), 
                     max = as.character(tail(date_time, n=1)$Date[1]) %>% strsplit(" ") %>% unlist() %>% nth(n=1)), 
      timeInput(inputId = "from_time", label = paste0("From Time (Min:", as.character(date_time$Date[1]) %>% strsplit(" ") %>% unlist() %>% nth(n=2), ")"), 
                value = as.character(date_time$Date[1]) %>% strsplit(" ") %>% unlist() %>% nth(n=2) %>% strptime("%T")), 
      timeInput(inputId = "to_time", label = paste0("To Time (Max:", as.character(tail(date_time, n=1)$Date[1]) %>% strsplit(" ") %>% unlist() %>% nth(n=2), ")"), 
                value = as.character(tail(date_time, n=1)$Date[1]) %>% strsplit(" ") %>% unlist() %>% nth(n=2) %>% strptime("%T")), 
      checkboxGroupInput('sensor_no', 'Sensor ID', names(df_list)), width = 2),
    mainPanel(
      plotOutput("main_plot", 
                 dblclick = "main_plot_dblclick", 
                 brush = brushOpts(
                   id = "main_plot_brush", 
                   resetOnNew = TRUE
                 ), height = 800, width = 1500)
    )
  )
)
