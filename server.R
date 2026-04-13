source("helpers.R", local = TRUE) # Load the helper functions


server <- function(input, output, session) {

  # ===========================================
  # SECTION 1: INITIALIZATION & SETUP
  # ===========================================
  # STRATEGY: Set up core reactive infrastructure
  # PURPOSE: Foundation for all subsequent functionality
  
  # ===========================================
  # SECTION 1.5: SESSION-SPECIFIC FILE MANAGEMENT
  # ===========================================
  # STRATEGY: Create unique workspace for each user session
  # PURPOSE: Isolate user files and enable automatic cleanup
  
  # CREATE UNIQUE SESSION DIRECTORY
  # STRATEGY: Use session token for unique folder names
  # PURPOSE: Prevent file mixing between concurrent users
  session_id <- session$token
  session_dir <- file.path(tempdir(), paste0("rootgrowth_session_", session_id))
  
  # ENSURE SESSION DIRECTORY EXISTS
  # STRATEGY: Create session directory if it doesn't exist
  # PURPOSE: Ensure workspace is ready for file operations
  if (!dir.exists(session_dir)) {
    dir.create(session_dir, recursive = TRUE)
  }
  
  # SESSION CLEANUP ON DISCONNECT
  # STRATEGY: Automatic cleanup when user disconnects
  # PURPOSE: Remove files immediately when session ends
  session$onSessionEnded(function() {
    if (dir.exists(session_dir)) {
      unlink(session_dir, recursive = TRUE)
      cat("Cleaned up session directory:", session_id, "\n")
    }
  })
  
  # PERIODIC CLEANUP FUNCTION
  # STRATEGY: Background cleanup for orphaned directories
  # PURPOSE: Safety net for cleanup in case of unexpected disconnections
  cleanup_old_sessions <- function() {
    temp_base <- tempdir()
    all_dirs <- list.dirs(temp_base, full.names = TRUE, recursive = FALSE)
    session_dirs <- all_dirs[grepl("rootgrowth_session_", basename(all_dirs))]
    current_time <- Sys.time()
    
    for (dir in session_dirs) {
      dir_time <- file.info(dir)$mtime
      # CLEANUP AFTER 2 HOURS
      if (difftime(current_time, dir_time, units = "hours") > 2) {
        unlink(dir, recursive = TRUE)
        cat("Cleaned up old session directory:", basename(dir), "\n")
      }
    }
  }
  
  # SCHEDULE PERIODIC CLEANUP
  # STRATEGY: Run cleanup every 30 minutes using reactive timer
  # PURPOSE: Maintain server resources by removing old session files
  observeEvent(reactiveTimer(30 * 60 * 1000)(), {
    cleanup_old_sessions()
  })
  
  # ===========================================
  # SECTION 2: FILE UPLOAD FUNCTIONALITY
  # ===========================================
  # STRATEGY: Handle file uploads with validation and session isolation
  # PURPOSE: Replace directory browsing with file upload
  
  # FILE UPLOAD PROCESSING
  # STRATEGY: Process uploaded files with validation and session organization
  # PURPOSE: Handle file uploads, validate naming convention, and organize in session directory
  upload_refresh <- reactiveVal(0)

  observeEvent(input$uploaded_files, {
    req(input$uploaded_files)
    
    tryCatch({
      # COPY UPLOADED FILES TO SESSION DIRECTORY
      # STRATEGY: Move files from temp upload to session-specific folder
      # PURPOSE: Organize files and enable processing
      uploaded_paths <- input$uploaded_files$datapath
      original_names <- input$uploaded_files$name
      
      # VALIDATE FILE NAMES
      # STRATEGY: Check naming convention before processing
      # PURPOSE: Early validation to prevent processing errors
      invalid_files <- c()
      valid_files <- c()
      
      for (i in seq_along(original_names)) {
        # CHECK NAMING PATTERN: VAR1_VAR2.csv
        if (grepl("^[^_]+_[^_]+\\.(csv|CSV)$", original_names[i])) {
          # COPY TO SESSION DIRECTORY
          dest_path <- file.path(session_dir, original_names[i])
          file.copy(uploaded_paths[i], dest_path, overwrite = TRUE)
          valid_files <- c(valid_files, original_names[i])
        } else {
          invalid_files <- c(invalid_files, original_names[i])
        }
      }
      
      # VALIDATION FEEDBACK
      # STRATEGY: Provide user feedback on file validation results
      # PURPOSE: Inform user of successful uploads and naming issues
      if (length(invalid_files) > 0) {
        showNotification(
          paste("Invalid file names (must be VAR1_VAR2.csv):",
                paste(invalid_files, collapse = ", ")),
          type = "warning", duration = 10
        )
      }
      
      if (length(valid_files) > 0) {
        showNotification(
          paste("Successfully uploaded", length(valid_files), "files"),
          type = "message"
        )
        upload_refresh(upload_refresh() + 1)
      }
      
    }, error = function(e) {
      showNotification(paste("Error uploading files:", e$message), type = "error")
    })
  })
  
  # UPLOAD STATUS DISPLAY
  # STRATEGY: Show current upload status and file count
  # PURPOSE: Provide real-time feedback on upload status
  output$upload_status <- renderText({
    if (is.null(input$uploaded_files)) {
      return("No files uploaded yet.")
    }
    
    files_in_session <- list.files(session_dir, pattern = "\\.(csv|CSV)$")
    if (length(files_in_session) > 0) {
      paste("Files ready for analysis:", length(files_in_session), "files")
    } else {
      "No valid files found. Please check file naming convention."
    }
  })
  
  # FILES UPLOADED FLAG
  # STRATEGY: Reactive flag to indicate if files are available
  # PURPOSE: Enable conditional UI elements based on file availability
  output$files_uploaded <- reactive({
    !is.null(input$uploaded_files) && length(list.files(session_dir, pattern = "\\.(csv|CSV)$")) > 0
  })
  outputOptions(output, "files_uploaded", suspendWhenHidden = FALSE)
  
  # REACTIVE VARIABLE FOR CONTROLLING UPLOADED FILES DISPLAY
  # STRATEGY: Use reactiveVal for simple boolean state management
  # PURPOSE: Control visibility of uploaded files list
  show_uploaded_files <- reactiveVal(FALSE)
  
  # TOGGLE BUTTON FOR UPLOADED FILES
  # STRATEGY: Dynamic toggle button with file count display
  # PURPOSE: Allow users to show/hide uploaded files list with context
  output$toggle_files_button <- renderUI({
    req(input$uploaded_files)
    
    file_count <- nrow(input$uploaded_files)
    
    if (show_uploaded_files()) {
      actionButton("toggle_uploaded_files", "Hide file list", 
                   icon = icon("chevron-up"),
                   class = "btn-sm btn-outline-secondary",
                   style = "margin-bottom: 10px;")
    } else {
      actionButton("toggle_uploaded_files", paste("Show uploaded files (", file_count, ")"), 
                   icon = icon("chevron-down"),
                   class = "btn-sm btn-outline-secondary", 
                   style = "margin-bottom: 10px;")
    }
  })
  
  # OBSERVER FOR TOGGLE BUTTON
  # STRATEGY: Simple state toggle when button is clicked
  # PURPOSE: Toggle visibility state of uploaded files display
  observeEvent(input$toggle_uploaded_files, {
    show_uploaded_files(!show_uploaded_files())
  })
  
  # CONDITIONAL DISPLAY OF UPLOADED FILES TABLE
  # STRATEGY: Show table only when toggle is activated
  # PURPOSE: Clean UI with optional detailed file information
  output$uploaded_files_display <- renderUI({
    req(input$uploaded_files, show_uploaded_files())
    
    tableOutput("uploaded_files_table_main")
  })
  
  # UPLOADED FILES TABLE FOR MAIN PANEL
  # STRATEGY: Formatted table with file information and size formatting
  # PURPOSE: Display uploaded file details in user-friendly format
  output$uploaded_files_table_main <- renderTable({
    req(input$uploaded_files)
    
    files_df <- input$uploaded_files
    display_df <- files_df[, c("name", "size")]
    
    # FILE SIZE FORMATTING
    # STRATEGY: Convert bytes to human-readable format
    # PURPOSE: Display file sizes in appropriate units (B, KB, MB)
    display_df$size <- sapply(display_df$size, function(x) {
      if (x < 1024) paste(x, "B")
      else if (x < 1024^2) paste(round(x/1024, 1), "KB")
      else paste(round(x/1024^2, 1), "MB")
    })
    
    colnames(display_df) <- c("File Name", "Size")
    display_df
  }, striped = TRUE, hover = TRUE, bordered = TRUE)
  
  # ===========================================
  # SECURITY AND RESOURCE MANAGEMENT
  # ===========================================
  # STRATEGY: Implement comprehensive security and resource limits
  # PURPOSE: Protect server resources and ensure fair usage
  
  # FILE SIZE LIMITS
  # STRATEGY: Prevent abuse through large file uploads
  # PURPOSE: Set reasonable limits to protect server resources
  MAX_SESSION_SIZE <- 100 * 1024 * 1024  # 100 MB
  
  # VALIDATE SESSION SIZE
  # STRATEGY: Check total session size against limits
  # PURPOSE: Prevent resource exhaustion from large uploads
  validate_session_size <- function() {
    if (dir.exists(session_dir)) {
      total_size <- sum(file.size(list.files(session_dir, full.names = TRUE)), na.rm = TRUE)
      if (total_size > MAX_SESSION_SIZE) {
        showNotification("Session file size limit exceeded. Please reduce file sizes.",
                         type = "error")
        return(FALSE)
      }
    }
    return(TRUE)
  }

  # ===========================================
  # SECTION 2: FILE PREVIEW FUNCTIONALITY
  # ===========================================
  # STRATEGY: Allow users to preview files before loading
  # PURPOSE: Prevent loading wrong files, provide transparency

  # FILE LIST TOGGLE STATE
  # STRATEGY: ReactiveVal for simple boolean state management
  # PURPOSE: Control whether to show all files or just first 5
  show_all_files <- reactiveVal(FALSE)
  observeEvent(input$show_all, { show_all_files(!show_all_files()) })

  # DYNAMIC FILE LIST DISPLAY (MODIFIED)
  # STRATEGY: Show uploaded files automatically in main panel
  # PURPOSE: Direct preview of uploaded files without toggle button
  output$selected_files <- renderTable({
    # Reactive dependency to refresh table right after file selection/upload
    uploaded_files <- input$uploaded_files
    upload_refresh()

    if (is.null(uploaded_files)) {
      return(data.frame(Files = "No files uploaded yet", `Size (KB)` = NA, check.names = FALSE))
    }

    # Show files from session directory (uploaded files)
    files <- list.files(path = session_dir, pattern = "\\.(csv|CSV)$", full.names = TRUE)

    # Apply pattern filter if specified
    if (!is.null(input$pattern) && input$pattern != "") {
      files <- files[grepl(input$pattern, basename(files), ignore.case = TRUE)]
    }

    # CONDITIONAL DISPLAY: Show 5 or all based on toggle state
    if (!show_all_files()) files <- head(files, 5)

    if (length(files) > 0) {
      data.frame(
        Files = basename(files),
        `Size (KB)` = round(file.size(files) / 1024, 1),
        check.names = FALSE
      )
    } else {
      if (!is.null(input$pattern) && input$pattern != "") {
        data.frame(Files = "No uploaded files match the pattern", `Size (KB)` = NA, check.names = FALSE)
      } else {
        data.frame(Files = "No files uploaded yet", `Size (KB)` = NA, check.names = FALSE)
      }
    }
  })

  # UPDATE THE TOGGLE BUTTON TEXT
  # STRATEGY: Show appropriate text for file list toggle
  # PURPOSE: Clear indication of current state
  observeEvent(show_all_files(), {
    files <- list.files(path = session_dir, pattern = "\\.(csv|CSV)$")
    if (length(files) > 5) {
      button_text <- if(show_all_files()) "Show first 5 files" else "Show all files"
      updateActionButton(session, "show_all", label = button_text)
    }
  })

  # CONDITIONAL SHOW ALL BUTTON
  # STRATEGY: Only show toggle button when there are more than 5 files
  # PURPOSE: Clean UI when toggle is not needed
  output$show_all_button <- renderUI({
    files <- list.files(path = session_dir, pattern = "\\.(csv|CSV)$")
    if (length(files) > 5) {
      button_text <- if(show_all_files()) "Show first 5 files" else "Show all files"
      actionButton("show_all", button_text, class = "btn-info btn-sm")
    }
  })

  # ===========================================
  # SECTION 3: CORE DATA STRUCTURES
  # ===========================================
  # STRATEGY: Centralized reactive data storage
  # PURPOSE: Single source of truth for data and parameters across app

  # MAIN DATA STORAGE
  # STRATEGY: ReactiveValues for mutable data storage
  # PURPOSE: Store processed data that can be updated and accessed by multiple functions
  result_df <- reactiveValues(data = NULL)

  # TABLE DISPLAY CONTROL
  # STRATEGY: Global state for table view mode (preview vs full)
  # PURPOSE: Persists across data reloads
  show_full_table <- reactiveValues(full = FALSE)

  # TABLE TOGGLE OBSERVER
  # STRATEGY: Global observer for table view toggle
  # PURPOSE: Switch between 5-row preview and full table display
  observeEvent(input$toggle_table, {
    show_full_table$full <- !show_full_table$full
  })

  # ===========================================
  # SECTION 4: DATA LOADING FUNCTIONALITY
  # ===========================================
  # STRATEGY: Robust data loading with validation and error handling
  # PURPOSE: Load and validate data files, provide user feedback

  # DATA LOADING EVENT HANDLER
  # STRATEGY: Event-driven data processing with comprehensive validation
  # PURPOSE: Process uploaded files and prepare data for analysis
  observeEvent(input$load, {
    # INPUT VALIDATION
    req(input$pattern, input$var1, input$var2, input$num_days)

    # CHECK IF FILES EXIST IN SESSION
    available_files <- list.files(session_dir, pattern = input$pattern, full.names = TRUE)
    if (length(available_files) == 0) {
      showNotification("No files found. Please upload files first.", type = "error")
      return()
    }
    
    # VALIDATE SESSION SIZE
    if (!validate_session_size()) {
      return()
    }

    # EXTRACT INPUT VALUES
    # STRATEGY: Store inputs in local variables for processing
    # PURPOSE: Clean code and consistent variable access
    pattern <- input$pattern
    var1 <- input$var1
    var2 <- input$var2
    num_days <- input$num_days

    # MAIN DATA PROCESSING
    tryCatch({
      # CALL DATA PROCESSING FUNCTION WITH SESSION DIRECTORY
      # STRATEGY: Delegate complex processing to helper function
      # PURPOSE: Keep server code clean, enable testing of processing logic
      processed_data <- process_datafile(
        pattern = pattern,
        var1 = var1, 
        var2 = var2, 
        num_days = num_days, 
        dirpath = session_dir  # Use session directory
      )
      
      # DATA VALIDATION
      # STRATEGY: Check data quality before assignment
      # PURPOSE: Ensure only valid data is stored and used
      if(!is.null(processed_data) && nrow(processed_data) > 0) {
        result_df$data <- processed_data
        showNotification("Data loaded successfully!", type = "message")
      } else {
        showNotification("No valid data found in the files.", type = "warning")
        return()
      }
      
      # TABLE TOGGLE BUTTON CREATION
      # STRATEGY: Generate UI dynamically after successful data load
      # PURPOSE: Button only appears when data is available
      output$toggle_button <- renderUI({
        req(result_df$data)
        actionButton("toggle_table", "Show Full Table", class = "btn-info")
      })

    }, error = function(e) {
      # ERROR HANDLING
      # STRATEGY: User-friendly error messages + console logging for debugging
      showNotification(paste("Failed to load data files:", e$message), type = "error")
      print(e)  # Console logging for developers
    })
  })
  
  # ===========================================
  # SECTION 5: DATA TABLE RENDERING
  # ===========================================
  # STRATEGY: Interactive data table with responsive design
  # PURPOSE: Allow users to explore loaded data with horizontal scrolling and filtering

  # MAIN DATA TABLE RENDERER
  # STRATEGY: Responsive table with different modes (preview vs full)
  # PURPOSE: Provide appropriate data exploration interface based on user needs
  output$processed_data <- DT::renderDataTable({
    req(result_df$data)  # Only render when data is available

    if (show_full_table$full) {
      # FULL TABLE MODE
      # STRATEGY: Full featured interactive table for data exploration
      DT::datatable(
        result_df$data,
        options = list(
          scrollX = TRUE,              # SOLUTION: Horizontal scrolling for wide data
          scrollY = "400px",           # Vertical scroll with fixed height
          pageLength = 25,             # Default rows per page
          lengthMenu = c(10, 25, 50, 100),  # User selectable page sizes
          autoWidth = TRUE,            # Automatic column width adjustment
          columnDefs = list(
            list(width = "100px", targets = "_all")  # Minimum column width
          )
        ),
        class = "display nowrap",      # CSS classes for better display
        filter = "top"                 # Column filters for data exploration
      )
    } else {
      # PREVIEW MODE
      # STRATEGY: Limited view for quick data inspection
      DT::datatable(
        head(result_df$data, 5),       # Only first 5 rows
        options = list(
          scrollX = TRUE,
          scrollY = "200px",           # Smaller height for preview
          pageLength = 5,              # Fixed at 5 rows
          lengthMenu = c(5),           # No other options
          paging = FALSE,              # No pagination needed for 5 rows
          autoWidth = TRUE,
          columnDefs = list(
            list(width = "100px", targets = "_all")
          )
        ),
        class = "display nowrap",
        filter = "top"
      )
    }
  }, server = FALSE)  # Client-side processing for better performance

  # TABLE TOGGLE BUTTON TEXT UPDATE
  # STRATEGY: Dynamic button text based on current state
  # PURPOSE: Clear indication of what clicking the button will do
  observeEvent(show_full_table$full, {
    req(result_df$data)
    button_text <- if(show_full_table$full) "Show Preview (5 rows)" else "Show Full Table"
    output$toggle_button <- renderUI({
      actionButton("toggle_table", button_text, class = "btn-info")
    })
  })

  # ===========================================
  # SECTION 6: INHIBITOR CONCENTRATION MAPPING
  # ===========================================
  # STRATEGY: Allow user to map string values to numeric concentrations
  # PURPOSE: Convert qualitative inhibitor labels to quantitative values

  # REACTIVE VALUES FOR CONCENTRATION MAPPING
  concentration_values <- reactiveValues(
    unique_concentrations = NULL,
    mapping = NULL,
    mapping_complete = FALSE
  )

  # DETECT UNIQUE CONCENTRATION VALUES AFTER DATA LOADING
  # STRATEGY: Automatic detection of concentration labels needing mapping
  # PURPOSE: Identify non-numeric concentration values for user input
  observeEvent(result_df$data, {
    req(result_df$data)
    
    # Don't reset if mapping is already complete
    if (concentration_values$mapping_complete) {
      return()
    }
    
    # Get the name of the second variable (inhibitor concentration column)
    inhibitor_col <- input$var2
    
    if (!is.null(inhibitor_col) && inhibitor_col %in% names(result_df$data)) {
      # Check if values are already numeric
      column_values <- result_df$data[[inhibitor_col]]
      
      # If column is already numeric, no mapping needed
      if (is.numeric(column_values)) {
        concentration_values$mapping_complete <- TRUE
        return()
      }
      
      unique_vals <- unique(column_values)
      unique_vals <- unique_vals[!is.na(unique_vals)]
      concentration_values$unique_concentrations <- sort(unique_vals)
      concentration_values$mapping_complete <- FALSE
      
      # ENHANCED NOTIFICATION WITH SCROLL ACTION
      shiny::showNotification(
        HTML(paste(
          "<strong>⚠️ Action Required:</strong><br/>",
          "Found", length(unique_vals), "concentration labels that need numeric values.<br/>",
          "<small>See the yellow alert box below for details.</small>"
        )),
        type = "warning",
        duration = 10,
        id = "concentration_mapping_needed"
      )
    }
  })

  # REACTIVE FOR UI CONDITIONAL
  # STRATEGY: Flag for conditional UI display
  # PURPOSE: Show mapping UI only when needed
  output$mapping_complete <- reactive({
    !is.null(concentration_values$unique_concentrations) && !concentration_values$mapping_complete
  })
  outputOptions(output, "mapping_complete", suspendWhenHidden = FALSE)

  # MAPPING STATUS DISPLAY
  # STRATEGY: Visual feedback on mapping status
  # PURPOSE: Guide user through mapping process
  output$mapping_status <- renderUI({
    req(concentration_values$unique_concentrations)
    
    if (concentration_values$mapping_complete) {
      div(
        class = "alert alert-success",
        style = "margin-top: 15px;",
        h5("✓ Concentration Mapping Complete"),
        p("All inhibitor concentration labels have been converted to numeric values.")
      )
    } else {
      div(
        class = "alert alert-warning",
        style = "margin-top: 15px; border-left: 4px solid #f39c12; animation: pulse 2s infinite;",
        h5("⚠️ Concentration Mapping Required"),
        p("Your data contains concentration labels that need to be converted to numeric values."),
        HTML("<button onclick='document.getElementById(\"concentration_section\").scrollIntoView({behavior: \"smooth\"});' class='btn btn-warning btn-sm' style='margin-top: 10px;'>
              <i class='fa fa-arrow-down'></i> Complete Mapping Below
              </button>")
      )
    }
  })

  # DYNAMIC UI FOR CONCENTRATION MAPPING
  # STRATEGY: Dynamic form generation based on detected concentrations
  # PURPOSE: Allow users to input numeric values for each concentration label
  output$concentration_mapping_ui <- renderUI({
    req(concentration_values$unique_concentrations)
    
    concentrations <- concentration_values$unique_concentrations
    
    if (length(concentrations) == 0) return(NULL)
    
    tagList(
      h4("Map Inhibitor Concentrations to Numeric Values"),
      p("Enter the numeric concentration value for each label:"),
      
      # Create input fields for each unique concentration
      lapply(concentrations, function(conc) {
        div(
          style = "margin-bottom: 10px;",
          fluidRow(
            column(4, 
              strong(paste("Label:", conc))
            ),
            column(4,
              numericInput(
                inputId = paste0("conc_", make.names(conc)),
                label = NULL,
                value = 0,
                min = 0,
                step = 0.1,
                width = "100%"
              )
            ),
            column(4,
              span("(concentration units)", style = "color: #666; font-size: 0.9em;")
            )
          )
        )
      }),
      
      div(style = "margin-top: 20px;",
        actionButton("apply_concentration_mapping", 
                     "Apply Concentration Mapping", 
                     class = "btn-success"),
        actionButton("reset_concentration_mapping", 
                     "Reset Values", 
                     class = "btn-warning",
                     style = "margin-left: 10px;")
      )
    )
  })

  # APPLY CONCENTRATION MAPPING
  # STRATEGY: Convert concentration labels to numeric values
  # PURPOSE: Enable quantitative analysis of concentration effects
  observeEvent(input$apply_concentration_mapping, {
    req(result_df$data, concentration_values$unique_concentrations)
    
    concentrations <- concentration_values$unique_concentrations
    inhibitor_col <- input$var2
    
    # Collect mapping values from inputs
    mapping <- setNames(
      sapply(concentrations, function(conc) {
        input_id <- paste0("conc_", make.names(conc))
        as.numeric(input[[input_id]])  # IMPORTANT: Convert to numeric
      }),
      concentrations
    )
    
    # Validate that all values are numeric and not missing
    if (any(is.na(mapping)) || any(is.null(mapping))) {
      shiny::showNotification("Please fill in all concentration values.", type = "error")
      return()
    }
    
    # Apply mapping to data
    tryCatch({
      # Create a copy of the data
      updated_data <- result_df$data
      
      # Apply the mapping - convert text values to numeric
      updated_data[[inhibitor_col]] <- as.numeric(
        mapping[as.character(updated_data[[inhibitor_col]])]
      )
      
      # Check for any unmapped values (would result in NA)
      if (any(is.na(updated_data[[inhibitor_col]]))) {
        shiny::showNotification("Some concentration values could not be mapped. Please check your data.", 
                         type = "warning")
      } else {
        # Store the mapping for future reference
        concentration_values$mapping <- mapping
        
        # IMPORTANT: Mark mapping as complete BEFORE updating data
        concentration_values$mapping_complete <- TRUE
        
        # Update the reactive data
        result_df$data <- updated_data
        
        # Verification for debugging
        cat("Mapping applied successfully!\n")
        cat("Unique values after mapping:", unique(updated_data[[inhibitor_col]]), "\n")
        cat("Class of column:", class(updated_data[[inhibitor_col]]), "\n")
        
        shiny::showNotification("Concentration mapping applied successfully!", 
                     type = "message",
                     duration = 5)
      }
      
    }, error = function(e) {
      shiny::showNotification(paste("Error applying concentration mapping:", e$message), 
                       type = "error")
      print(e)
    })
  })

  # RESET CONCENTRATION MAPPING
  # STRATEGY: Allow users to reset mapping values
  # PURPOSE: Enable correction of mapping mistakes
  observeEvent(input$reset_concentration_mapping, {
    req(concentration_values$unique_concentrations)
    
    concentrations <- concentration_values$unique_concentrations
    
    # Reset all numeric inputs to 0
    for (conc in concentrations) {
      input_id <- paste0("conc_", make.names(conc))
      updateNumericInput(session, input_id, value = 0)
    }
    
    showNotification("Concentration values reset to 0.", type = "message")
  })
  
  # ===========================================
  # SECTION 7: DOSE EFFECT ANALYSIS
  # ===========================================
  # STRATEGY: Implement complete dose-effect analysis workflow
  # PURPOSE: Statistical analysis and visualization of dose-response data
  
  # REACTIVE VALUES FOR ANALYSIS RESULTS
  # STRATEGY: Centralized storage for analysis outputs
  # PURPOSE: Share results between analysis and visualization functions
  analysis_results <- reactiveValues(
    dose_data = NULL,
    stats = NULL,
    current_plot = NULL
  )
  
  # DYNAMIC UI FOR BAR PLOT CONCENTRATION SELECTION
  # STRATEGY: Populate concentration choices from actual data
  # PURPOSE: Only show concentrations that exist in the data (excluding control)
  output$barplot_concentration_ui <- renderUI({
    req(result_df$data, input$var2)
    req(concentration_values$mapping_complete)  # Ensure mapping is complete
    
    # Get unique concentrations (non-zero) directly from loaded data
    conc_values <- result_df$data[[input$var2]]
    conc_choices <- sort(unique(conc_values[conc_values != 0]))
    
    if (length(conc_choices) > 0) {
      selectInput("barplot_concentration", 
                 paste("Select", input$var2, ":"),
                 choices = conc_choices,
                 selected = conc_choices[1])
    }
  })
  
  # ANALYSIS EXECUTION WHEN START BUTTON IS CLICKED
  # STRATEGY: Event-driven analysis execution with complete workflow
  # PURPOSE: Perform statistical analysis and generate visualizations
  observeEvent(input$start_analysis, {
    req(result_df$data, input$var1, input$var2)
    req(concentration_values$mapping_complete)
    
    # SWITCH TO ANALYSIS RESULTS TAB IMMEDIATELY
    updateTabsetPanel(session, "main_tabs", selected = "Analysis Results")
    
    tryCatch({
      # STEP 1: Prepare dose-effect data
      # STRATEGY: Calculate AZ0 controls and percentage growth
      # PURPOSE: Normalize growth measurements to control values
      dose_data <- prepare_dose_effect_data(
        result_df$data,
        var1 = input$var1,
        var2 = input$var2
      )
      
      # Store results (pas de stats générales maintenant)
      analysis_results$dose_data <- dose_data
      analysis_results$stats <- NULL  # Reset previous stats
      
      # STEP 2: Create visualization based on selected plot type
      plot_type <- input$dose_plot_type %||% "curve"
      selected_day <- input$selected_day %||% "Day4"

      # Get colors with user-defined order if available
      var1_levels <- if (!is.null(group_order$var1_order) && length(group_order$var1_order) > 0) {
        group_order$var1_order
      } else {
        unique(result_df$data[[input$var1]])
      }

      colors <- RColorBrewer::brewer.pal(max(3, length(var1_levels)), "Set2")[1:length(var1_levels)]
      names(colors) <- var1_levels
      
      # Obtenir l'ordre personnalisé pour les plots
      current_order <- if (!is.null(group_order$var1_order) && length(group_order$var1_order) > 0) {
        group_order$var1_order
      } else {
        NULL
      }

      # Create appropriate plot AVEC analyse statistique intégrée
      plot_result <- NULL
      
      if (plot_type == "curve") {
        plot_result <- create_dose_effect_plot(
          dose_data$summary_AZ,
          dose_data$AZ_df,  # AJOUT des données brutes
          day_selected = selected_day,
          var1 = input$var1,
          var2 = input$var2,
          colors = colors,
          var1_order = current_order,
          base_size = input$plot_text_size %||% 16
        )
      } else if (plot_type == "violin") {
        plot_result <- create_violin_plot(
          dose_data$AZ_df,  # Utiliser les données du dose_data
          var1 = input$var1,
          var2 = input$var2,
          colors = colors,
          var1_order = current_order,
          base_size = input$plot_text_size %||% 16
        )
      } else if (plot_type == "barplot") {
        req(input$barplot_day, input$barplot_concentration)
        plot_result <- create_bar_plot(
          dose_data$AZ_df,  # Utiliser les données du dose_data
          day_selected = input$barplot_day,
          conc_selected = as.numeric(input$barplot_concentration),
          var1 = input$var1,
          var2 = input$var2,
          colors = colors,
          var1_order = current_order,
          base_size = input$plot_text_size %||% 16,
          analysis_mode = input$barplot_analysis_mode %||% "strict"
        )
      }
      
      # Stocker les résultats
      if (!is.null(plot_result)) {
        analysis_results$current_plot <- plot_result$plot
        analysis_results$stats <- plot_result$statistics  # Stocker les stats spécifiques au plot
      }
      
      # Display statistical summary basé sur le type de plot
      output$normality_text <- renderText({
        req(analysis_results$stats)
        stats <- analysis_results$stats
        current_plot_type <- input$dose_plot_type %||% "curve"
        
        if (current_plot_type == "curve") {
          # Pour curve plot, afficher résumé des tests par concentration
          curve_stats <- Filter(function(x) {
            is.list(x) && !is.null(x$significant)
          }, stats)

          if (length(curve_stats) == 0) {
            return("No concentration-wise statistics available for this curve.")
          }

          sig_concs <- names(curve_stats)[vapply(curve_stats, function(x) isTRUE(x$significant), logical(1))]
          if (length(sig_concs) > 0) {
            return(paste("Significant differences found at concentrations:",
                         paste(sig_concs, collapse = ", ")))
          } else {
            return("No significant differences found at any concentration")
          }
        } else if (current_plot_type == "barplot") {
          # Pour bar plot, afficher la décision statistique retenue et sa raison
          if (is.list(stats) && !is.null(stats$selected_test)) {
            shapiro_lines <- character(0)
            if (!is.null(stats$shapiro_results)) {
              group_cols <- setdiff(names(stats$shapiro_results), c("n", "p_shapiro"))
              if (length(group_cols) > 0) {
                group_col <- group_cols[1]
                shapiro_lines <- vapply(seq_len(nrow(stats$shapiro_results)), function(row_index) {
                  p_value <- stats$shapiro_results$p_shapiro[[row_index]]
                  paste0(
                    stats$shapiro_results[[group_col]][[row_index]],
                    ": p = ",
                    if (is.na(p_value)) "NA" else format.pval(p_value, digits = 3)
                  )
                }, character(1))
              }
            }

            result_text <- paste0(
              "Analysis mode: ", stats$analysis_mode %||% "unknown",
              "\nSelected test: ", stats$selected_test,
              "\nReason: ", stats$decision_reason %||% "none"
            )

            if (length(shapiro_lines) > 0) {
              result_text <- paste0(result_text, "\n\nShapiro-Wilk by group:\n", paste(shapiro_lines, collapse = "\n"))
            }

            if (!is.null(stats$levene_results)) {
              levene_p <- if ("p" %in% names(stats$levene_results)) stats$levene_results$p[1] else NA_real_
              result_text <- paste0(result_text, "\n\nLevene p-value: ", ifelse(is.na(levene_p), "NA", format.pval(levene_p, digits = 3)))
            }

            if (identical(stats$selected_test, "ANOVA") && !is.null(stats$main_test)) {
              result_text <- paste0(result_text, "\n\nANOVA p-value: ", format.pval(stats$main_test$p, digits = 3))
            } else if (identical(stats$selected_test, "Kruskal-Wallis") && !is.null(stats$main_test)) {
              result_text <- paste0(result_text, "\n\nKruskal-Wallis p-value: ", format.pval(stats$main_test$p, digits = 3))
            }

            return(result_text)
          }
          return("Bar plot statistics are not available yet.")
        } else {
          return("Violin plot - No statistical analysis performed")
        }
      })
      
      showNotification("Analysis completed successfully!", type = "message", duration = 3)
      
    }, error = function(e) {
      showNotification(paste("Analysis error:", e$message), type = "error", duration = 10)
      print(e)
    })
  })
  
  # REACTIVE OBSERVER FOR PLOT TYPE CHANGES
  # STRATEGY: Regenerate plot when user changes visualization type or parameters
  # PURPOSE: Allow users to explore different visualizations without rerunning full analysis
  observeEvent(c(input$dose_plot_type, input$selected_day, input$barplot_day, input$barplot_concentration, input$plot_text_size, color_mapping$colors), {
    req(analysis_results$dose_data)
    
    # Ignore if data is not ready
    if (is.null(analysis_results$dose_data)) {
      return()
    }
    
    tryCatch({
      plot_type <- input$dose_plot_type
      
      # Check that plot_type exists and is not NULL
      if (is.null(plot_type) || plot_type == "") {
        return()
      }
      
      selected_day <- input$selected_day %||% "Day4"
      
      # Use current user-selected colors
      colors_to_use <- unlist(color_mapping$colors)
      
      # S'assurer que les couleurs sont dans le bon ordre
      if (!is.null(group_order$var1_order)) {
        colors_to_use <- colors_to_use[group_order$var1_order]
      }
      
      current_order <- group_order$var1_order %||% NULL
      
      # Regénérer le plot avec analyse
      plot_result <- NULL
      
      if (plot_type == "curve") {
        plot_result <- create_dose_effect_plot(
          analysis_results$dose_data$summary_AZ,
          analysis_results$dose_data$AZ_df,
          day_selected = selected_day,
          var1 = input$var1,
          var2 = input$var2,
          colors = colors_to_use, # Utiliser les couleurs réactives
          var1_order = current_order,
          base_size = input$plot_text_size %||% 16
        )
      } else if (plot_type == "violin") {
        plot_result <- create_violin_plot(
          analysis_results$dose_data$AZ_df,
          var1 = input$var1,
          var2 = input$var2,
          colors = colors_to_use, # Utiliser les couleurs réactives
          var1_order = current_order,
          base_size = input$plot_text_size %||% 16
        )
      } else if (plot_type == "barplot") {
        if (is.null(input$barplot_day) || is.null(input$barplot_concentration)) {
          return()
        }
        plot_result <- create_bar_plot(
          analysis_results$dose_data$AZ_df,
          day_selected = input$barplot_day,
          conc_selected = as.numeric(input$barplot_concentration),
          var1 = input$var1,
          var2 = input$var2,
          colors = colors_to_use, # Utiliser les couleurs réactives
          var1_order = current_order,
          base_size = input$plot_text_size %||% 16,
          analysis_mode = input$barplot_analysis_mode %||% "strict"
        )
      }
      
      # Mettre à jour les résultats
      if (!is.null(plot_result)) {
        analysis_results$current_plot <- plot_result$plot
        analysis_results$stats <- plot_result$statistics
      }
      
    }, error = function(e) {
      if (!inherits(e, "shiny.silent.error")) {
        cat("ERROR in plot regeneration:\n")
        cat("Error message:", e$message, "\n")
        showNotification(paste("Plot regeneration error:", e$message), type = "error")
      }
    })
  }, ignoreNULL = TRUE, ignoreInit = TRUE)
  
  # PLOT RENDERER
  # STRATEGY: Generate plot fresh each time from stored parameters
  # PURPOSE: Ensure plots are always current with user selections
  output$plot_result <- renderPlot({
    req(analysis_results$current_plot)
    print(analysis_results$current_plot)
  }, height = 600, width = 800)
  
  # ===========================================
  # SECTION 8: GROUP ORDERING AND COLOR UI
  # ===========================================
  # STRATEGY: Drag-and-drop interface and color pickers for customization
  # PURPOSE: User control over plot appearance and legend order

  # REACTIVE VALUES FOR GROUP ORDER
  group_order <- reactiveValues(
    var1_order = NULL
  )
  
  # AJOUT: REACTIVE VALUES FOR COLOR MAPPING
  color_mapping <- reactiveValues(
    colors = NULL
  )

  # GROUPING VARIABLE ORDER UI
  output$var1_order_ui <- renderUI({
    req(result_df$data, input$var1)
    
    # Get unique values for the grouping variable
    unique_values <- unique(result_df$data[[input$var1]])
    
    # Initialize order if not set
    if (is.null(group_order$var1_order)) {
      group_order$var1_order <- unique_values
    }
    
    # Create sortable list using sortable package
    rank_list(
      text = paste("Order of", input$var1),
      labels = group_order$var1_order,
      input_id = "var1_order_list",
      css_id = "var1_order_sortable"
    )
  })
  
  # AJOUT: DYNAMIC UI FOR COLOR PICKERS
  output$color_picker_ui <- renderUI({
    req(group_order$var1_order)
    
    levels <- group_order$var1_order
    
    # Initialiser les couleurs si elles n'existent pas ou si les groupes ont changé
    if (is.null(color_mapping$colors) || !setequal(names(color_mapping$colors), levels)) {
      default_colors <- RColorBrewer::brewer.pal(max(3, length(levels)), "Set2")[1:length(levels)]
      color_mapping$colors <- setNames(as.list(default_colors), levels)
    }
    
    # Créer un sélecteur de couleur pour chaque niveau de la variable
    tagList(
      h4("Customize Group Colors"),
      lapply(levels, function(level) {
        colourInput(
          inputId = paste0("color_", make.names(level)),
          label = paste("Color for", level),
          value = color_mapping$colors[[level]]
        )
      })
    )
  })

  # KEEP COLOR MAPPING IN SYNC WITH UI PICKERS
  # STRATEGY: Single observer to avoid creating nested observers over time
  observe({
    req(group_order$var1_order)

    levels <- group_order$var1_order
    picked <- lapply(levels, function(level) {
      input[[paste0("color_", make.names(level))]]
    })
    names(picked) <- levels

    # Keep existing/default colors when a picker has not emitted a value yet
    for (level in levels) {
      if (is.null(picked[[level]]) || !nzchar(picked[[level]])) {
        picked[[level]] <- color_mapping$colors[[level]]
      }
    }

    color_mapping$colors <- picked
  })
  
  # OBSERVE CHANGES IN GROUP ORDER
  observeEvent(input$var1_order_list, {
    req(input$var1_order_list)
    group_order$var1_order <- input$var1_order_list
    
    # Update colors to match new order if analysis has been run
    if (!is.null(analysis_results$dose_data)) {
      # Regenerate plot with new order
      # This will be handled by the existing plot observer
    }
  }, ignoreNULL = TRUE)
  
  # UPDATE GROUP ORDER WHEN NEW DATA IS LOADED
  # STRATEGY: Reset group order when new data is loaded
  # PURPOSE: Ensure order matches current dataset
  observeEvent(result_df$data, {
    req(result_df$data, input$var1)
    
    # Reset to default order based on data
    unique_values <- unique(result_df$data[[input$var1]])
    group_order$var1_order <- unique_values
  })
  
  # ===========================================
  # SECTION 9: DATA EXPORT FUNCTIONALITY
  # ===========================================
  # STRATEGY: Allow users to export statistical results and processed data
  # PURPOSE: Enable further analysis and reporting outside the app
  
  # STATISTICAL RESULTS ZIP DOWNLOAD
  # STRATEGY: Create comprehensive zip with all statistical outputs
  # PURPOSE: Provide complete analysis results in organized format
  output$download_stats <- downloadHandler(
    filename = function() {
      filename_base <- if (!is.null(input$stats_filename) && input$stats_filename != "") {
        input$stats_filename
      } else {
        "statistical_results"
      }
      paste0(filename_base, ".zip")
    },
    content = function(file) {
      req(analysis_results$stats)
      
      tryCatch({
        # Générer le fichier zip avec les résultats statistiques
        zip_file <- create_statistical_export(
          analysis_results$stats,
          filename_base = input$stats_filename %||% "statistical_results"
        )
        
        # Copier le fichier zip vers la destination
        file.copy(zip_file, file, overwrite = TRUE)
        
        showNotification("Statistical results exported successfully!", 
                         type = "message", duration = 3)
        
      }, error = function(e) {
        showNotification(paste("Export error:", e$message), 
                         type = "error", duration = 5)
        print(e)
      })
    },
    contentType = "application/zip"
  )
  
  # PROCESSED DATA CSV DOWNLOAD
  # STRATEGY: Export clean dataset for external analysis
  # PURPOSE: Provide processed data in standard format
  output$download_data <- downloadHandler(
    filename = function() {
      filename_base <- if (!is.null(input$data_filename) && input$data_filename != "") {
        input$data_filename
      } else {
        "processed_data"
      }
      paste0(filename_base, ".csv")
    },
    content = function(file) {
      # Utiliser les données du dose_data au lieu de stats
      req(analysis_results$dose_data$AZ_df)
      
      tryCatch({
        write.csv(analysis_results$dose_data$AZ_df, file, row.names = FALSE)
        
        showNotification("Processed data exported successfully!", 
                         type = "message", duration = 3)
        
      }, error = function(e) {
        showNotification(paste("Export error:", e$message), 
                         type = "error", duration = 5)
        print(e)
      })
    },
    contentType = "text/csv"
  )
  
  output$download_plot <- downloadHandler(
    filename = function() {
      # Assurer que 'base' et 'fmt' sont des chaînes de caractères valides
      base <- input$plot_filename
      if (is.null(base) || !nzchar(trimws(base))) {
        base <- "plot"
      }
      
      fmt <- input$plot_format
      if (is.null(fmt) || !nzchar(trimws(fmt))) {
        fmt <- "png"
      }
      
      # Le 'switch' ici retourne une chaîne de caractères pour l'extension
      ext <- switch(tolower(fmt),
                    "png"  = "png",
                    "pdf"  = "pdf",
                    "svg"  = "svg",
                    "jpg"  = "jpg",
                    "jpeg" = "jpg",
                    "png" # Fallback sécurisé (chaîne de caractères)
      )
      
      paste0(base, ".", ext)
    },
    
    content = function(file) {
      # S'assurer que le plot existe
      req(analysis_results$current_plot)
      
      # Récupérer les paramètres de manière sécurisée
      fmt <- input$plot_format
      if (is.null(fmt) || !nzchar(trimws(fmt))) {
        fmt <- "png"
      }
      
      w <- suppressWarnings(as.numeric(input$plot_width))
      if (is.na(w) || w <= 0) w <- 30
      
      h <- suppressWarnings(as.numeric(input$plot_height))
      if (is.na(h) || h <= 0) h <- 20
      
      units <- input$plot_units
      if (is.null(units) || !nzchar(trimws(units))) {
        units <- "cm"
      }

      # Utiliser ggsave, qui est conçu pour gérer cela de manière robuste
      tryCatch({
        ggplot2::ggsave(
          filename = file,
          plot = analysis_results$current_plot,
          device = tolower(fmt), # ggsave comprend les chaînes "png", "pdf", etc.
          width = w,
          height = h,
          units = units,
          dpi = 300,
          bg = "white"
        )
        
        showNotification("Plot exported successfully!", type = "message")
        
      }, error = function(e) {
        # Gérer le cas où un package est manquant (ex: svglite pour svg)
        if (grepl("svglite", e$message)) {
          showNotification("SVG export requires the 'svglite' package. Please install it.", type = "error", duration = 10)
        } else {
          showNotification(paste("Plot export error:", e$message), type = "error", duration = 10)
        }
        # Écrire l'erreur dans le fichier pour le débogage, comme ce qui se passe actuellement
        writeLines(paste("ERROR:", e$message), file)
      })
    }
  )
}