parse_custom_input <- function(custom_input){
  temp <- custom_input %>% strsplit(",") %>% lapply(trimws) %>% unlist()
  sequences <- list()
  for (input in temp){
    # If user has left "," or "-" at the end, ignore it
    if (input == "," || input == "-"){
      next
    }
    input <- input %>% strsplit("-") %>% unlist()
    if (length(input) == 2){
      # Input has "-" with 2 numbers. Generate a sequence
      sequences <- c(sequences, seq(from = as.integer(input[1]), to = as.integer(input[2])))
    } else {
      # Input is a single number
      sequences <- c(sequences, as.integer(input))
    }
  }
  # Default behavior when the input box is empty. 
  # Generate a graph of sequence_number == 1
  if (length(sequences) == 0){
    sequences <- list(1)
  }
  return(sequences)
}

# Helper function for adding a plot with option "All"
add_plot_all <- function(plot_data){
    main_plot <<- main_plot + geom_line(mapping = aes(x = posix_Timestamp, y = adc, color = `Tag ID`), data = plot_data) +
      geom_point(mapping = aes(x = posix_Timestamp, y = adc, color = `Tag ID`), data = plot_data)
}

# Helper function for adding a plot with option "Last"
add_plot_last <- function(plot_data){
  main_plot <<- main_plot + geom_line(mapping = aes(x = posix_Timestamp, y = adc, color = `Tag ID`), data = plot_data %>% 
                                        subset(sequence_diff < 0)) +
    geom_point(mapping = aes(x = posix_Timestamp, y = adc, color = `Tag ID`), data = plot_data %>% 
                 subset(sequence_diff < 0))
}

# Helper function for adding a plot with option "Cutom"
add_plot_custom <- function(plot_data, custom_input){
  current_custom_input <<- custom_input
  sequences <- parse_custom_input(custom_input)
  # If the input sequence_number doesn't exist, then defalut behavior is to
  # generate a graph of sequence_number == 1
  if (nrow(plot_data %>% filter(`sequence number` %in% sequences)) == 0){
    sequences <- list(1)
  }
  main_plot <<- main_plot + geom_line(mapping = aes(x = posix_Timestamp, y = adc, color = `Tag ID`), data = plot_data %>% 
                                        filter(`sequence number` %in% sequences)) +
    geom_point(mapping = aes(x = posix_Timestamp, y = adc, color = `Tag ID`), data = plot_data %>% 
                 filter(`sequence number` %in% sequences))
}

server <- function(input, output, session) {
  ranges <- reactiveValues(x = NULL, y = NULL)
  output$main_plot <- renderPlot({
    # Setting the date/time global variables from the date/time selector in the ui.R
    if (is.null(current_from_date)){
      current_from_date <<- input$date[[1]]
      current_to_date <<- input$date[[2]]
      if (!(is.null(input$from_time))){
        current_from_time <<- strftime(input$from_time, format = "%H:%M:%S")
      }
      if (!(is.null(input$to_time))){
        current_to_time <<- strftime(input$to_time, format = "%H:%M:%S")
      }
    }
    
    # This if block is executed when we are adding a sensor.
    # The added sensors are added to a map of 
    # active_sensors_map, key = sensor, value = option (default is "Last")
    if (!is.null(input$sensor_no)){
      for (sensor in input$sensor_no){
        if (!(sensor %in% names(active_sensors_map))){
          # Reactive functions are called even before the following UI is added.
          # So, if the UI is not added, we skip
          if (is.null(input[[sensor]])){
            next
          }
          active_sensors_map[[sensor]] <<- input[[sensor]]
          from_time <- strftime(input$from_time, format = "%H:%M:%S")
          to_time <- strftime(input$to_time, format = "%H:%M:%S")
          
          # Getting the relevant data for a particular sensor 
          # by filtering the date/time and sensor ID
          plot_data <- lapply(seq_along(df_list), function(index) if (names(df_list)[index] == sensor)
            return (df_list[[names(df_list)[index]]] %>% 
                      subset(subset = posix_Timestamp >= as_datetime(paste(input$date[[1]], current_from_time, sep = " ")) & 
                               posix_Timestamp <= as_datetime(paste(input$date[[2]], current_to_time, sep = " "))))) %>% 
            bind_rows()
          
          # Adding the plot to main_plot
          if (input[[sensor]] == "All"){
            add_plot_all(plot_data)
          }
          else if(input[[sensor]] == "Last"){
            add_plot_last(plot_data)
          }
          else if(input[[sensor]] == "Custom"){
            add_plot_custom(plot_data, input[[paste0(sensor, "_custom")]])
          }
        }
      }
      
      # This for loop is for removing any sensors from the 
      # main_plot when user unticks a particular sensor ID 
      for (sensor in names(active_sensors_map)){
        # Reactive functions are called even before the following UI is added.
        # So, if the UI is not added, we skip
        if (is.null(input[[sensor]])){
          next
        }
        if (!(sensor %in% input$sensor_no)){
          active_sensors_map[[sensor]] <<- NULL
          # remove the plot from the main plot
          indices_to_null <- list()
          for (index in seq_along(main_plot$layers)){
            if (any(main_plot$layers[[index]]$data$`Tag ID` == sensor)){
              indices_to_null <- c(indices_to_null, index)
            }
          }
          # When the date/times are updated such that a particular sensor ID
          # has no data for that date/time, the plot is removed from main_plot.
          # In such cases, the length of indices_to_null is 0, and we can't 
          # remove a plot that doesn't exist. So, we skip.
          if (length(indices_to_null) == 0){
            next
          }
          main_plot <<- main_plot %>% delete_layers(idx = unlist(indices_to_null))
        }
      }

      # This for loop is executed when user changes the 
      # option for each sensor
      for (sensor in input$sensor_no){
        # Reactive functions are called even before the following UI is added.
        # So, if the UI is not added, we skip
        if (is.null(input[[sensor]])){
          next
        }
        # Same reason as above
        if (input[[sensor]] == "Custom" && is.null(input[[paste0(as.character(sensor), "_custom")]])){
          next
        }
        # Either the option is changed, or the custom input text box is changed.
        # So, we go in.
        if (active_sensors_map[[sensor]] != input[[sensor]] 
            || (input[[sensor]] == "Custom" && 
                current_custom_input != input[[paste0(sensor, "_custom")]])){
          
          # removing the plot with old option
          indices_to_null <- list()
          for (index in seq_along(main_plot$layers)){
            if (any(main_plot$layers[[index]]$data$`Tag ID` == sensor)){
              indices_to_null <- c(indices_to_null, index)
            }
          }
          if (length(indices_to_null) != 0){
            main_plot <<- main_plot %>% delete_layers(idx = unlist(indices_to_null))
          }
          
          # adding the plot with new options/custom input
          plot_data <- lapply(seq_along(df_list), function(index) if (names(df_list)[index] == sensor)
            return (df_list[[names(df_list)[index]]] %>% 
                      subset(subset = posix_Timestamp >= as_datetime(paste(input$date[[1]], current_from_time, sep = " ")) & 
                               posix_Timestamp <= as_datetime(paste(input$date[[2]], current_to_time, sep = " "))))) %>% 
            bind_rows()
          if (input[[sensor]] == "All"){
            add_plot_all(plot_data)
          }
          else if(input[[sensor]] == "Last"){
            add_plot_last(plot_data)
          }
          else if(input[[sensor]] == "Custom"){
            add_plot_custom(plot_data, input[[paste0(sensor, "_custom")]])
          }
          # Updating our active_sensors_map with new option
          active_sensors_map[[sensor]] <<- input[[sensor]]
        }
      }
      
      # This if block is executed if any of date/time is changed.
      # It essentially redraws the whole graph according to new date/time.
      if (input$date[[1]] != current_from_date || input$date[[2]] != current_to_date || 
          strftime(input$from_time, format = "%H:%M:%S") != current_from_time ||
          strftime(input$to_time, format = "%H:%M:%S") != current_to_time){
        # Updating the current date/time global variables
        current_from_date <<- input$date[[1]]
        current_to_date <<- input$date[[2]]
        current_from_time <<- strftime(input$from_time, format = "%H:%M:%S")
        current_to_time <<- strftime(input$to_time, format = "%H:%M:%S")
        
        # Removing all the layers
        main_plot <<- ggplot()
        
        # Adding the layers for all the sensors according to new time and date
        for (sensor in input$sensor_no){
          if (is.null(input[[sensor]])){
            next
          }
          plot_data <- lapply(seq_along(df_list), function(index) if (names(df_list)[index] == sensor)
            return (df_list[[names(df_list)[index]]] %>% 
                      subset(subset = posix_Timestamp >= as_datetime(paste(input$date[[1]], current_from_time, sep = " ")) & 
                               posix_Timestamp <= as_datetime(paste(input$date[[2]], current_to_time, sep = " "))))) %>% 
            bind_rows()
          if (input[[sensor]] == "All"){
            add_plot_all(plot_data)
          }
          else if(input[[sensor]] == "Last"){
            add_plot_last(plot_data)
          }
          else if(input[[sensor]] == "Custom"){
            add_plot_custom(plot_data, input[[paste0(sensor, "_custom")]])
          }
        }
      }
      
      # Adding the zoomable feature to our main_plot, along with many graphical parameters.
      main_plot <- main_plot + coord_cartesian(xlim = ranges$x, ylim = ranges$y, expand = FALSE) +
        scale_x_datetime(breaks = pretty_breaks(n=20)) + 
        scale_y_continuous(breaks = pretty_breaks(10)) +
        labs(x = "Date-Time", y = "ADC", color = "Tag ID") + 
        theme(axis.text.x = element_text(angle = 40, hjust = 1), 
              axis.text = element_text(size = 14), 
              axis.text.y = element_text(angle = 20), 
              axis.title = element_text(size = 14, face = "bold"), 
              axis.title.x = element_text(vjust = -1), 
              axis.title.y = element_text(angle = 0, vjust = 0.5, hjust = -1), 
              legend.title = element_text(size = 14, face = "bold"), 
              legend.text = element_text(size = 14), 
              legend.key.size = unit(1.0, "cm"), 
              legend.background = element_rect(fill = "peachpuff2"),
              legend.key = element_rect(fill = "grey91", color = NA))
      return (main_plot)
    } else {
      # No sensors are selected, so clear the active_sensors_map and main_plot and return it.
      active_sensors_map <<- list()
      main_plot <<- ggplot()
      return (main_plot)
    }
  })
  
  # Zoom if we double click on a brushed area, else zoom-out
  observeEvent(input$main_plot_dblclick, {
    brush <- input$main_plot_brush
    if (!is.null(brush)){
      cat(brush$xmin, " ", brush$xmax, "\n")
      ranges$x <- c(as.POSIXct(brush$xmin, origin = "1970-01-01"), as.POSIXct(brush$xmax, origin = "1970-01-01"))
      ranges$y <- c(brush$ymin, brush$ymax)
    } else {
      ranges$x <- NULL
      ranges$y <- NULL
    }
  })
  
  observeEvent(input$sensor_no, {
    # Adding the options radio buttons on selecting a sensor dynamically.
    # current_sensors and removed_sensors variables are used to track the sensors 
    # that are added/to be added or to be removed.
    for (sensor in input$sensor_no){
      if (!(sensor %in% current_sensors)) {
        insertUI(
          selector = '#sensor_no', 
          ui = radioButtons(as.character(sensor), sensor, c('All', 'Last', 'Custom'), selected = 'Last'), 
          immediate = FALSE
        )
        current_sensors <<- c(current_sensors, sensor)
      }
    }
    
    # Removing the options radio button on un-selecting a sensor
    # Also removes the custom textbox, if available
    for (sensor in current_sensors){
      if (!(sensor %in% input$sensor_no)){
        removeUI(
          selector = paste0("#", as.character(sensor)), 
          immediate = FALSE
        )
        removeUI(
          selector = paste0("#", as.character(sensor), "_custom"), 
          immediate = FALSE
        )
        removed_sensors <<- c(removed_sensors, sensor)
      }
    }
    current_sensors <<- current_sensors[!(current_sensors %in% removed_sensors)]
    removed_sensors <<- list()
  }, ignoreNULL = FALSE)
  
  # Adds text box UI dynamically if custom input option is selected.
  lapply(
    names(df_list), 
    FUN = function(sensor){
      observeEvent(input[[sensor]], {
        if (input[[sensor]] == 'Custom'){
          insertUI(
            selector = paste0("#", as.character(sensor)),
            ui = textInput(inputId = paste0(as.character(sensor), '_custom'), label = "", value = "1-3, 7, 9"),
            immediate = FALSE,
            where = 'afterEnd'
          )
        }
        else {
          removeUI(
            selector = paste0("#", as.character(sensor), "_custom")
          )
        }
      })
    }
  )
}