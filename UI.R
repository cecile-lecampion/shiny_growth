########################################################################################################################################
# Define the UI
########################################################################################################################################
# STRATEGY: Create a comprehensive Shiny dashboard for root growth analysis
# PURPOSE: Provide an intuitive, step-by-step interface for users to load data, configure analysis, and export results
# KEY FEATURES:
# - Uses dashboardPage layout for professional appearance
# - Implements collapsible accordion panels for organized workflow
# - Provides step-by-step guided analysis process
# - Supports both bar plot and curve analysis workflows

ui <- dashboardPage(
  # ===========================================
  # HEADER SECTION
  # ===========================================
  # STRATEGY: Professional branding with logo and title
  # PURPOSE: Clear application identity and professional appearance
  dashboardHeader(
    title = div(
      class = "brand",
      tags$img(src = "logo_RT.png", alt = "RootTracker", class = "brand-logo"),
      span("RootTracker", class = "brand-title")
    ),
    titleWidth = 360
  ),

  # ===========================================
  # SIDEBAR CONFIGURATION
  # ===========================================
  # STRATEGY: Disabled sidebar to use custom layout
  # PURPOSE: More flexibility while keeping dashboard styling
  dashboardSidebar(disable = TRUE),

  # ===========================================
  # MAIN DASHBOARD BODY
  # ===========================================
  # STRATEGY: Custom CSS + fluidPage for responsive design
  # PURPOSE: Professional styling with responsive layouts
  dashboardBody(
    # ===========================================
    # CSS STYLING SECTION
    # ===========================================
    # STRATEGY: Comprehensive custom CSS for professional appearance
    # PURPOSE: Improve visual design, user experience, and fix layout issues
    tags$head(
      tags$link(rel = "icon", type = "image/png", href = "logo_RT.png"),
      tags$link(rel = "alternate icon", href = "logo_RT.png"),
      tags$meta(name = "theme-color", content = "#1E5B49"),
      tags$style(HTML("
        :root {
          --rt-primary: #1E5B49;
          --rt-secondary: #2D6A4F;
          --rt-accent: #40916C;
          --rt-bg-soft: #F7FAF8;
          --rt-white: #FFFFFF;
          --rt-primary-rgb: 30, 91, 73;
          --rt-accent-rgb: 64, 145, 108;
        }

        /* ===========================================
           HEADER AND BRANDING STYLES
           =========================================== */
        /* STRATEGY: Responsive logo and title layout */
        /* PURPOSE: Professional branding that works on all screen sizes */
        .main-header .logo {
          display: flex !important;
          align-items: center;
          padding: 0 15px;
          background-color: var(--rt-primary) !important;
        }
        .main-header .navbar {
          background-color: var(--rt-secondary) !important;
        }
        .brand {
          display: flex;
          align-items: center;
          gap: 10px;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        .brand-logo {
          width: 26px;
          height: 26px;
          flex: 0 0 26px;
        }
        .brand-title {
          font-weight: 600;
          font-size: 18px;
          line-height: 1;
          letter-spacing: 0.2px;
          color: var(--rt-bg-soft);
        }
        
        /* MOBILE RESPONSIVE ADJUSTMENTS */
        /* STRATEGY: Smaller elements on mobile devices */
        /* PURPOSE: Maintain readability on small screens */
        @media (max-width: 480px) {
          .brand-title { font-size: 16px; }
        }
        
        /* ===========================================
           GENERAL LAYOUT IMPROVEMENTS
           =========================================== */
        /* STRATEGY: Clean white background for better readability */
        /* PURPOSE: Reduce eye strain and improve content visibility */
        .content-wrapper, .right-side {
          background-color: var(--rt-bg-soft);
        }
        
        /* STRATEGY: Card-like design with soft green accent */
        /* PURPOSE: Clear visual separation of content blocks */
        .info-box {
          background: var(--rt-white);
          padding: 20px;
          margin: 15px 0;
          border-radius: 8px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          border-left: 4px solid var(--rt-accent);
        }
        
        /* ===========================================
           INTERACTIVE ELEMENT STYLING
           =========================================== */
        /* STRATEGY: Softer green-themed button styling */
        /* PURPOSE: Professional appearance with gentle green color scheme */
        .btn-primary {
          background-color: var(--rt-accent) !important;
          border-color: var(--rt-accent) !important;
          color: #fff !important;
        }
        .btn-primary:hover {
          background-color: var(--rt-secondary) !important;
          border-color: var(--rt-secondary) !important;
          color: #fff !important;
        }
        
        .btn-success {
          background-color: var(--rt-secondary) !important;
          border-color: var(--rt-secondary) !important;
          color: #fff !important;
        }
        .btn-success:hover {
          background-color: var(--rt-primary) !important;
          border-color: var(--rt-primary) !important;
          color: #fff !important;
        }
        
        .btn-warning {
          background-color: var(--rt-accent) !important;
          border-color: var(--rt-accent) !important;
          color: #fff !important;
        }
        .btn-warning:hover {
          background-color: var(--rt-secondary) !important;
          border-color: var(--rt-secondary) !important;
          color: #fff !important;
        }
        
        .btn-block {
          margin-bottom: 15px;
          border-radius: 5px;
        }
        
        /* STRATEGY: Interactive hover effects with soft green accent */
        /* PURPOSE: Visual feedback that panels are clickable */
        .panel-heading {
          cursor: pointer !important;
          transition: background-color 0.3s ease !important;
          padding: 0 !important;
        }
        .panel-heading:hover {
          background-color: rgba(var(--rt-accent-rgb), 0.08) !important;
        }
        
        .panel-heading a {
          display: block !important;
          width: 100% !important;
          padding: 15px 20px !important;
          text-decoration: none !important;
          color: inherit !important;
        }
        
        .panel-heading a:hover {
          text-decoration: none !important;
          color: inherit !important;
        }
        
        .panel-title {
          margin: 0 !important;
          width: 100% !important;
        }
        
        /* STRATEGY: Soft green-themed alert design */
        /* PURPOSE: Softer, more professional notification appearance */
        .alert {
          border-radius: 6px;
          border: none;
          box-shadow: 0 1px 4px rgba(0,0,0,0.1);
        }
        .alert-info {
          background-color: rgba(var(--rt-accent-rgb), 0.08) !important;
          color: var(--rt-primary) !important;
        }
        
        /* STRATEGY: Animation for attention-grabbing alerts */
        /* PURPOSE: Draw user attention to required actions */
        @keyframes pulse {
          0% { opacity: 1; }
          50% { opacity: 0.7; }
          100% { opacity: 1; }
        }

        .alert-warning {
          animation: pulse 3s infinite;
        }

        .alert-warning:hover {
          animation: none;
        }
        
        /* STRATEGY: Soft green tab design matching color scheme */
        /* PURPOSE: Consistent visual identity throughout application */
        .nav-tabs {
          border-bottom: 2px solid var(--rt-accent);
        }
        .nav-tabs > li.active > a {
          background-color: var(--rt-accent) !important;
          color: white !important;
          border-color: var(--rt-accent) !important;
        }
        .nav-tabs > li > a:hover {
          background-color: rgba(var(--rt-accent-rgb), 0.08) !important;
          border-color: rgba(var(--rt-accent-rgb), 0.25) !important;
        }
        
        /* STRATEGY: Clean table design with subtle shadows */
        /* PURPOSE: Professional data presentation */
        .table {
          background: white;
          border-radius: 5px;
          overflow: hidden;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        
        /* ===========================================
           PLOT CONTAINER FIXES
           =========================================== */
        /* STRATEGY: Solve plot overflow issues and ensure responsive design */
        /* PURPOSE: Prevent plots from extending beyond container boundaries */
        #plot_result {
          background: white;
          padding: 20px;
          border-radius: 8px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          margin: 15px 0;
          overflow: hidden;
          width: 100%;
          box-sizing: border-box;
        }
        
        /* STRATEGY: Force plot to fit within container */
        /* PURPOSE: Responsive plot sizing on all devices */
        #plot_result .shiny-plot-output {
          width: 100% !important;
          height: auto !important;
          max-width: 100%;
        }
        
        /* STRATEGY: Responsive image sizing */
        /* PURPOSE: Ensure plot images scale properly */
        #plot_result img {
          max-width: 100%;
          height: auto;
          display: block;
          margin: 0 auto;
        }
        
        /* ===========================================
           FORM ELEMENT IMPROVEMENTS
           =========================================== */
        /* STRATEGY: Soft green-themed input styling with focus effects */
        /* PURPOSE: Better user interaction feedback */
        .form-control {
          border-radius: 4px;
          border: 1px solid #ddd;
          transition: border-color 0.3s ease;
        }
        .form-control:focus {
          border-color: var(--rt-accent);
          box-shadow: 0 0 0 0.2rem rgba(var(--rt-accent-rgb), 0.25);
        }
        
        /* ===========================================
           HELP TAB SCROLLABLE CONTAINER
           =========================================== */
        /* STRATEGY: Fixed height container with custom scrollbar */
        /* PURPOSE: Better navigation of long documentation content */
        .help-container {
          height: 80vh;
          overflow-y: auto;
          overflow-x: hidden;
          padding: 20px;
          background: white;
          border-radius: 8px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          margin: 10px 0;
        }
        
        /* STRATEGY: Soft green-themed scrollbar styling */
        /* PURPOSE: Professional appearance even for scroll elements */
        .help-container::-webkit-scrollbar {
          width: 8px;
        }
        
        .help-container::-webkit-scrollbar-track {
          background: var(--rt-bg-soft);
          border-radius: 4px;
        }
        
        .help-container::-webkit-scrollbar-thumb {
          background: rgba(var(--rt-accent-rgb), 0.5);
          border-radius: 4px;
        }
        
        .help-container::-webkit-scrollbar-thumb:hover {
          background: var(--rt-accent);
        }
        
        /* ===========================================
           HELP CONTENT MARKDOWN STYLING
           =========================================== */
        /* STRATEGY: Soft green-themed documentation styling */
        /* PURPOSE: Improved readability and visual hierarchy */
        .help-container h1, .help-container h2, .help-container h3 {
          color: var(--rt-primary);
          border-bottom: 2px solid rgba(var(--rt-accent-rgb), 0.15);
          padding-bottom: 8px;
          margin-top: 30px;
          margin-bottom: 15px;
        }
        
        .help-container h1 { font-size: 28px; }
        .help-container h2 { font-size: 24px; }
        .help-container h3 { font-size: 20px; }
        
        .help-container p {
          line-height: 1.6;
          margin-bottom: 15px;
          text-align: justify;
        }
        
        /* STRATEGY: Soft green-themed code styling */
        /* PURPOSE: Clear differentiation between code and text */
        .help-container code {
          background-color: var(--rt-bg-soft);
          border: 1px solid rgba(var(--rt-accent-rgb), 0.2);
          border-radius: 4px;
          padding: 2px 6px;
          font-family: 'Courier New', monospace;
          color: var(--rt-primary);
        }
        
        .help-container pre {
          background-color: var(--rt-bg-soft);
          border: 1px solid rgba(var(--rt-accent-rgb), 0.2);
          border-radius: 4px;
          padding: 15px;
          overflow-x: auto;
        }
        
        /* STRATEGY: Improved list styling */
        /* PURPOSE: Better visual hierarchy and spacing */
        .help-container ul, .help-container ol {
          margin-left: 20px;
          margin-bottom: 15px;
        }
        
        .help-container li {
          margin-bottom: 8px;
          line-height: 1.5;
        }
        
        /* ===========================================
           ADDITIONAL SOFT GREEN THEME ELEMENTS
           =========================================== */
        /* Panel primary styling */
        .panel-primary > .panel-heading {
          background-color: var(--rt-accent) !important;
          border-color: var(--rt-accent) !important;
        }

        .panel-primary > .panel-heading,
        .panel-primary > .panel-heading .panel-title,
        .panel-primary > .panel-heading .panel-title a,
        .panel-primary > .panel-heading .panel-title i {
          color: #fff !important;
        }

        .panel-primary > .panel-heading a:hover,
        .panel-primary > .panel-heading a:focus {
          color: #fff !important;
        }
        
        /* Well styling for soft green theme */
        .well {
          background-color: var(--rt-bg-soft) !important;
          border: 1px solid rgba(var(--rt-accent-rgb), 0.2) !important;
        }
        
        /* Input group styling */
        .input-group-addon {
          background-color: var(--rt-bg-soft) !important;
          border-color: #ddd !important; /* Neutral border */
        }

      "))
    ),
    
    # ===========================================
    # MAIN LAYOUT STRUCTURE
    # ===========================================
    # STRATEGY: Responsive design using fluidPage with sidebarLayout
    # PURPOSE: Optimal layout for desktop and mobile devices
    fluidPage(
      sidebarLayout(

        # ===========================================
        # SIDEBAR PANEL
        # ===========================================
        # STRATEGY: Step-by-step guided workflow using accordion panels
        # PURPOSE: Organized, progressive user interface that guides analysis
        sidebarPanel(

          # ===========================================
          # ACCORDION CONTAINER
          # ===========================================
          # STRATEGY: Bootstrap accordion for collapsible sections
          # PURPOSE: Reduce visual clutter and guide users through workflow
          div(class = "panel-group", id = "accordion",
            
            # ===========================================
            # SECTION 1: FILE NAMING CONFIGURATION
            # ===========================================
            # TITLE: File Name Configuration
            # STRATEGY: Define variable mapping before any data operations
            # PURPOSE: Establish file naming convention understanding
            div(class = "panel panel-primary",
                # ACCORDION HEADER
                # STRATEGY: Clickable header with clear section numbering
                # PURPOSE: Visual hierarchy and intuitive navigation
                div(class = "panel-heading",
                    h4(class = "panel-title",
                       tags$a(`data-toggle` = "collapse",
                              `data-parent` = "#accordion",
                              href = "#collapse1",
                              icon("tag"), " 1. File Name Configuration"))
                ),
                # PANEL CONTENT - STARTS EXPANDED
                # STRATEGY: First step should be immediately visible
                # PURPOSE: Guide users to complete setup before proceeding
                div(id = "collapse1", class = "panel-collapse collapse in",
                    div(class = "panel-body",

                        # NAMING CONVENTION EXPLANATION
                        # STRATEGY: Prominent alert box with clear examples
                        # PURPOSE: Prevent user confusion about required file format
                        div(class = "alert alert-info", style = "margin-bottom: 15px;",
                            icon("info-circle"),
                            strong(" Required File Naming Pattern:"),
                            br(), br(),
                            tags$code("VAR1_VAR2.csv", style = "font-size: 14px; background-color: var(--rt-bg-soft); padding: 15px;"),
                            br(), br(),
                            em("Example: Line1_AZ0.csv")
                        ),

                        # VARIABLE DEFINITION INPUTS
                        # STRATEGY: Three-column layout for logical organization
                        # PURPOSE: Map generic placeholders to actual experiment variables
                        helpText("Define what each variable represents in your file names:"),
                        fluidRow(
                          column(4, 
                                 div(style = "text-align: center;",
                                     strong("VAR1"),
                                     textInput("var1", NULL, value = "Line", placeholder = "e.g., Line")
                                 )
                          ),
                          column(4, 
                                 div(style = "text-align: center;",
                                     strong("VAR2"),
                                     textInput("var2", NULL, value = "Inhibitor_concentration", placeholder = "e.g., Inhibitor_concentration")
                                 )
                          ),

                        ),

                        # LIVE FILENAME PREVIEW
                        # STRATEGY: Real-time feedback using reactive inputs
                        # PURPOSE: Immediate validation of user setup
                        div(class = "well well-sm", style = "margin-top: 15px; background-color: var(--rt-bg-soft);",
                            strong("Expected filename example: "),
                          tags$span(id = "filename_preview", style = "font-family: monospace; color: var(--rt-primary);",
                                     "Line1_AZ0.csv")
                        )
                    )
                )
            ),

            # ===========================================
            # SECTION 2: DATA LOADING
            # ===========================================
            # TITLE: Data Loading Interface
            # STRATEGY: File upload → pattern matching → preview → load
            # PURPOSE: Secure, server-friendly data loading workflow
            div(class = "panel panel-primary",
                # ACCORDION HEADER
                div(class = "panel-heading",
                    h4(class = "panel-title",
                       tags$a(`data-toggle` = "collapse", 
                              `data-parent` = "#accordion",
                              href = "#collapse2",
                              icon("database"), " 2. Load Data"))
                ),
                # PANEL CONTENT - COLLAPSED BY DEFAULT
                # STRATEGY: Users complete Section 1 before proceeding
                # PURPOSE: Logical workflow progression
                div(id = "collapse2", class = "panel-collapse collapse",
                    div(class = "panel-body",

                        # FILE UPLOAD INTERFACE
                        # STRATEGY: Direct file upload for server deployment compatibility
                        # PURPOSE: Works in both local and deployed environments
                        div(
                          style = "background-color: var(--rt-bg-soft); padding: 20px; border-radius: 8px; margin-bottom: 20px;",
                          h4(icon("upload"), "Upload FluorCam Files",
                             style = "color: #495057; margin-bottom: 15px;"),

                          # MULTIPLE FILE INPUT
                          # STRATEGY: Accept multiple files with extension filtering
                          # PURPOSE: Bulk upload of related data files
                          fileInput(
                            "uploaded_files",
                            label = div(
                              strong("Select RootGrowth .csv files:"),
                              br(),
                              span("Choose multiple files that follow the naming pattern VAR1_VAR2.csv",
                                   style = "font-size: 12px; color: #6c757d;")
                            ),
                            multiple = TRUE,
                            accept = c(".csv", ".CSV"),
                            width = "100%"
                          ),

                          # UPLOAD FEEDBACK
                          # STRATEGY: Real-time status updates
                          # PURPOSE: User feedback during file processing
                          verbatimTextOutput("upload_status")
                        ),

                        # FILE PATTERN FILTER
                        # STRATEGY: Flexible pattern matching for different file types
                        # PURPOSE: Support various file extensions and naming patterns
                        textInput("pattern", "File Pattern", 
                                  value = ".csv",
                                  placeholder = "e.g., .csv"),

                        # NUMBER OF DAYS INPUT
                        # STRATEGY: Numeric input with sensible defaults
                        numericInput("num_days", "Number of measures per roots", value = 1, min = 1),

                        # FILE PREVIEW CONTROLS
                        # STRATEGY: Optional file list with conditional toggle
                        # PURPOSE: Verify correct files before loading
                        uiOutput("show_all_button"),
                        br(), br(),

                        # MAIN LOAD ACTION BUTTON
                        # STRATEGY: Prominent action button with success styling
                        # PURPOSE: Clear call-to-action for data loading
                        actionButton("load", "Load Data",
                                     icon = icon("play"),
                                     class = "btn-success btn-block")
                    )
                )
            ),
            
            # ===========================================
            # SECTION 3: ANALYSIS CONFIGURATION
            # ===========================================
            # TITLE: Analysis Parameters Setup
            # STRATEGY: Comprehensive parameter configuration interface
            # PURPOSE: All analysis settings in logical, organized layout
            div(class = "panel panel-primary",
                # ACCORDION HEADER
                div(class = "panel-heading",
                    h4(class = "panel-title",
                       tags$a(`data-toggle` = "collapse", 
                              `data-parent` = "#accordion",
                              href = "#collapse3",
                              icon("chart-line"), " 3. Analysis Parameters"))
                ),
                # PANEL CONTENT - REQUIRES DATA TO BE LOADED
                div(id = "collapse3", class = "panel-collapse collapse",
                    div(class = "panel-body",
                        
                        # ===========================================
                        # DOSE-EFFECT ANALYSIS SETTINGS (ALWAYS VISIBLE)
                        # ===========================================
                        div(
                            style = "background-color: rgba(var(--rt-accent-rgb), 0.10); padding: 15px; border-radius: 5px; border-left: 4px solid var(--rt-accent); margin: 15px 0;",
                            h4(style = "margin-top: 0; color: var(--rt-primary);", 
                             icon("chart-line"), " Dose-Effect Analysis Settings"),
                          
                          hr(),
                          
                          # DAY SELECTION FOR DOSE EFFECT PLOT
                          h5("Select Day for Analysis"),
                          selectInput("selected_day", NULL,
                                      choices = c("Day1", "Day2", "Day3", "Day4"),
                                      selected = "Day4"),
                          
                          hr(),

                          # GROUP ORDERING AND COLOR CUSTOMIZATION
                          # STRATEGY: Side-by-side layout for related controls
                          # PURPOSE: Intuitive control over plot aesthetics
                          fluidRow(
                            column(6,
                              # GROUP ORDERING UI
                              # STRATEGY: Drag-and-drop for intuitive ordering
                              # PURPOSE: Control legend and axis order
                              uiOutput("var1_order_ui")
                            ),
                            column(6,
                              # DYNAMIC COLOR PICKER UI
                              # STRATEGY: Generate color pickers for each group
                              # PURPOSE: Allow users to customize plot colors interactively
                              uiOutput("color_picker_ui")  # AJOUT: Emplacement pour les sélecteurs de couleur
                            )
                          ),

                          hr(),
                          
                          # PLOT TYPE SELECTION FOR DOSE EFFECT
                          h5("Visualization Type"),
                          radioButtons("dose_plot_type", NULL,
                                       choices = list(
                                         "Dose-Effect Curve (Log scale)" = "curve",
                                         "Violin Plot (All Days)" = "violin",
                                         "Bar Plot (Specific Day & Concentration)" = "barplot"
                                       ),
                                       selected = "curve"),

                          conditionalPanel(
                            condition = "input.dose_plot_type == 'barplot'",
                            radioButtons(
                              "barplot_analysis_mode",
                              "Bar plot statistical rule",
                              choices = list(
                                "Strict: follow Shapiro-Wilk only" = "strict",
                                "Permissive: keep parametric test when variance is acceptable" = "prefer_parametric"
                              ),
                              selected = "strict"
                            )
                          ),

                          sliderInput(
                            "plot_text_size",
                            "Text size",
                            min = 10,
                            max = 24,
                            value = 16,
                            step = 1
                          ),
                          
                          # BAR PLOT SPECIFIC CONTROLS (CONDITIONAL)
                          conditionalPanel(
                            condition = "input.dose_plot_type == 'barplot'",
                            div(
                              style = "background-color: rgba(var(--rt-accent-rgb), 0.10); padding: 15px; border-radius: 5px; margin-top: 15px; border-left: 3px solid var(--rt-secondary);",
                              h5(style = "margin-top: 0;", icon("bar-chart"), " Bar Plot Settings"),
                              
                              selectInput("barplot_day", "Select Day",
                                          choices = c("Day1", "Day2", "Day3", "Day4"),
                                          selected = "Day4"),
                              
                              uiOutput("barplot_concentration_ui")
                            )
                          )
                        ),

                        hr(),

                        # ANALYSIS EXECUTION BUTTON
                        # STRATEGY: Warning-colored button indicates significant action
                        # PURPOSE: Execute configured analysis with all parameters
                        actionButton("start_analysis", "Start Analysis",
                                     icon = icon("play"),
                                     class = "btn-warning btn-block")
                    )
                )
            ),
            
            # ===========================================
            # SECTION 4: RESULTS EXPORT
            # ===========================================
            # TITLE: Export Analysis Results
            # STRATEGY: Separate exports for statistical data and plots
            # PURPOSE: Professional output options with full customization
            div(class = "panel panel-primary",
                # ACCORDION HEADER
                div(class = "panel-heading",
                    h4(class = "panel-title",
                       tags$a(`data-toggle` = "collapse",
                              `data-parent` = "#accordion",
                              href = "#collapse4",
                              icon("download"), " 4. Export Results"))
                ),
                # PANEL CONTENT - ONLY AVAILABLE AFTER ANALYSIS
                div(id = "collapse4", class = "panel-collapse collapse",
                    div(class = "panel-body",

                        # RAW DATA EXPORT SECTION
                        # STRATEGY: CSV export of processed data
                        # PURPOSE: Provide clean dataset for external analysis
                        strong("Raw Data Export:"),
                        br(), br(),
                        textInput("data_filename", "Data filename (without extension)",
                                  value = "processed_data",
                                  placeholder = "Enter filename"),
                        br(),
                        downloadButton("download_data", "Download Processed Data (CSV)",
                                       class = "btn-info", icon = icon("table")),

                        hr(),
                        # STATISTICAL DATA EXPORT SECTION
                        # STRATEGY: ZIP archive with multiple text files
                        # PURPOSE: Organized, readable statistical output
                        strong("Statistical Results:"),
                        br(), br(),
                        textInput("stats_filename", "Filename (without extension)",
                                  value = "statistical_results",
                                  placeholder = "Enter filename"),
                        br(),
                        downloadButton("download_stats", "Download Statistical Tables (ZIP)",
                                       class = "btn-primary", icon = icon("download")),
                        
                        hr(),
                        
                        # PLOT EXPORT SECTION
                        # STRATEGY: Comprehensive customization for publication quality
                        # PURPOSE: Professional plot output with format options
                        strong("Export Plot:"),
                        br(), br(),

                        # FILENAME AND FORMAT SELECTION
                        # STRATEGY: Side-by-side layout for related options
                        # PURPOSE: Efficient use of space for related settings
                        fluidRow(
                          column(6,
                            textInput("plot_filename", "Filename",
                                      value = "plot",
                                      placeholder = "Enter filename")
                          ),
                          column(6,
                            # FORMAT OPTIONS FOR DIFFERENT USE CASES
                            # STRATEGY: Multiple formats for different applications
                            # PURPOSE: Professional control over plot output format
                            selectInput("plot_format", "Format",
                                        choices = list(
                                          "PNG (High-res)" = "png",    # General use, high quality
                                          "PDF (Print)" = "pdf",       # Publication ready
                                          "SVG (Vector)" = "svg",      # Scalable graphics
                                          "JPEG" = "jpg"               # Compressed format
                                        ),
                                        selected = "png")
                          )
                        ),

                        # PLOT DIMENSIONS CONFIGURATION
                        # STRATEGY: Scientific units (cm) with alternatives
                        # PURPOSE: Professional control over plot sizing
                        fluidRow(
                          column(4,
                            numericInput("plot_width", "Width",
                                         value = 30, min = 10, max = 50, step = 1)
                          ),
                          column(4,
                            numericInput("plot_height", "Height",
                                         value = 20, min = 5, max = 40, step = 1)
                          ),
                          column(4,
                            # UNIT SELECTION FOR DIFFERENT STANDARDS
                            # STRATEGY: Scientific (cm) default with alternatives
                            # PURPOSE: Professional control over plot sizing
                            selectInput("plot_units", "Units",
                                        choices = list(
                                          "Centimeters" = "cm",    # Scientific standard
                                          "Inches" = "in",         # US publishing standard
                                          "Millimeters" = "mm"     # High precision
                                        ),
                                        selected = "cm")
                          )
                        ),
                        br(),

                        # PLOT EXPORT ACTION BUTTON
                        # STRATEGY: Success-colored button for positive action
                        # PURPOSE: Download configured plot with custom settings
                        downloadButton("download_plot", "Download Plot",
                                       class = "btn-success", icon = icon("image"))
                    )
                )
            )
          )
        ),
          
        # ===========================================
        # MAIN PANEL: RESULTS DISPLAY AREA
        # ===========================================
        # STRATEGY: Tabbed interface for organized information presentation
        # PURPOSE: Logical separation of data, results, and documentation
        mainPanel(

          # ===========================================
          # TABBED INTERFACE CONTAINER
          # ===========================================
          # STRATEGY: Three-tab structure for complete workflow coverage
          # PURPOSE: Separate concerns while maintaining easy navigation
          tabsetPanel(
            id = "main_tabs",

            # ===========================================
            # TAB 1: DATA OVERVIEW
            # ===========================================
            # TITLE: Data Overview and File Management
            # STRATEGY: Interactive data preview with file information
            # PURPOSE: Allow users to verify loaded data before analysis
            tabPanel("Data Overview", 
                     icon = icon("table"),
                     br(),

                    # UPLOADED FILES INFORMATION SECTION
                    # STRATEGY: Conditional display with toggle functionality
                    # PURPOSE: Show file upload status without cluttering interface
                    conditionalPanel(
                       condition = "output.files_uploaded",
                       div(
                         h4("Uploaded Files:", style = "margin-bottom: 15px; color: var(--rt-primary);"),
                         # TOGGLE BUTTON FOR FILE LIST
                         # STRATEGY: Collapsible file list to save space
                         # PURPOSE: Optional detailed file information
                         uiOutput("toggle_files_button"),
                         br(),
                         # CONDITIONAL FILE TABLE DISPLAY
                         # STRATEGY: Show table only when requested
                         # PURPOSE: Clean interface with optional detail
                         uiOutput("uploaded_files_display"),
                         hr()
                       )
                     ),

                    # PROCESSED FILES PREVIEW
                    # STRATEGY: ALWAYS VISIBLE FILE INFORMATION
                    # PURPOSE: SHOW WHICH FILES ARE READY FOR ANALYSIS
                    tableOutput("selected_files"),

                    # CONDITIONAL SEPARATOR
                    # STRATEGY: ONLY SHOW SEPARATOR WHEN FILES ARE PRESENT
                    # PURPOSE: CLEAN LAYOUT WITHOUT UNNECESSARY ELEMENTS
                    conditionalPanel(
                      condition = "output.selected_files",
                      hr()
                    ),

                    # DATA TABLE TOGGLE CONTROLS
                    # STRATEGY: User control over table detail level
                    # PURPOSE: Balance between quick preview and full exploration
                    uiOutput("toggle_button"),
                    br(),

                    # MAIN INTERACTIVE DATA TABLE
                    # STRATEGY: DT datatable for full interactive features
                    # PURPOSE: Comprehensive data exploration with filtering and pagination
                    DT::dataTableOutput("processed_data")
            ),

            # ===========================================
            # TAB 2: ANALYSIS RESULTS
            # ===========================================
            # TITLE: Analysis Results and Visualizations
            # STRATEGY: Information summary + main visualization display
            # PURPOSE: Present analysis outputs in organized, readable format
            tabPanel("Analysis Results",
                     icon = icon("chart-line"),
                     br(),

                     # ANALYSIS INFORMATION SUMMARY
                     # STRATEGY: Key information in prominent info boxes
                     # PURPOSE: Quick reference for analysis parameters and results
                     fluidRow(
                       
                       # NORMALITY TEST RESULTS (BAR PLOTS ONLY)
                       # STRATEGY: Conditional display based on analysis type
                       # PURPOSE: Statistical information relevant to bar plot analysis only
                       conditionalPanel(
                         condition = "input.dose_plot_type == 'barplot'",
                         column(6,
                           div(class = "info-box",
                             h4("Statistical Decision"),
                             verbatimTextOutput("normality_text")
                           )
                         )
                       )
                     ),
                     hr(),

                     # MAIN VISUALIZATION DISPLAY
                     # STRATEGY: Responsive container for plot display
                     # PURPOSE: Professional plot presentation
                     div(
                       style = "min-height: 600px;",
                       plotOutput("plot_result", height = "auto", width = "100%")
                     )
            ),
            
            # ===========================================
            # TAB 3: HELP DOCUMENTATION
            # ===========================================
            # TITLE: User Help and Documentation
            # STRATEGY: Comprehensive documentation in scrollable container
            # PURPOSE: Complete user guidance and reference material
            tabPanel("Help",
                     icon = icon("question-circle"),
                     br(),
                     
                     # SCROLLABLE HELP CONTAINER
                     # STRATEGY: Fixed height container with custom scrolling
                     # PURPOSE: Better navigation of extensive documentation
                     div(class = "help-container",
                       includeMarkdown("Help.md")  # External markdown file for easy editing
                     )
            )
          ),
          
          # ===========================================
          # CONCENTRATION MAPPING SECTION
          # ===========================================
          # STRATEGY: Conditional display of concentration mapping UI only after data is loaded
          # PURPOSE: Guide users to map inhibitor concentrations after data table is displayed
          conditionalPanel(
            condition = "output.processed_data",
            
            # Concentration mapping section
            div(id = "concentration_section",
              br(),
              hr(),
              h3("Map Inhibitor Concentrations"),
              p("Set the numeric values for each inhibitor concentration label found in your data."),
              
              # Mapping status
              uiOutput("mapping_status"),
              
              # Concentration mapping UI
              uiOutput("concentration_mapping_ui")
            )
          )
        )
      )
    )
  )
)