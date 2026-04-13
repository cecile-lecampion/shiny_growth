# STEP 1: Global Setup
# STRATEGY: Load dependencies and global options once
source("global.R")

# STEP 2: User Interface and Server Definition
# STRATEGY: Source both app components explicitly for deterministic startup
source("UI.R")
source("server.R")

# APPLICATION LAUNCH
# STRATEGY: Simple application instantiation after all components loaded
# PURPOSE: Start the Shiny application with UI and server components
# CONFIGURATION: Uses default settings optimized for local development

# Launch the Shiny application
# PARAMETERS:
# - ui: User interface object from UI.R
# - server: Server function from server.R
# - options: Default Shiny options (auto-detect available port, open browser)
shinyApp(ui = ui, server = server)