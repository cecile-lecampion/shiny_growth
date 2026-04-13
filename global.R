# Global configuration and package management for the Shiny app.

# ===========================================
# SECTION 1: REQUIRED PACKAGES
# ===========================================
# Purpose: Keep a single source of truth for all app dependencies.

required_packages <- c(
  # Core Shiny framework
  "shiny",
  "shinydashboard",
  "shinyFiles",
  "shinyWidgets",

  # Data manipulation
  "dplyr",
  "tidyr",
  "data.table",
  "forcats",
  "stringr",

  # File system helpers
  "fs",
  "zip",

  # Statistical analysis
  "rstatix",
  "rcompanion",
  "multcompView",
  "Rmisc",

  # Modeling
  "qgam",

  # Visualization
  "ggplot2",
  "ggbeeswarm",
  "RColorBrewer",

  # User interface helpers
  "colourpicker",
  "sortable",
  "DT",
  "htmltools"
)

# ===========================================
# SECTION 2: QUIET PACKAGE INSTALLATION
# ===========================================
# Purpose: Install only the packages that are missing, without verbose output.

missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]

if (length(missing_packages) > 0) {
  tryCatch(
    install.packages(missing_packages, dependencies = TRUE, quiet = TRUE),
    error = function(e) {
      stop(
        paste(
          "Unable to install missing packages:",
          paste(missing_packages, collapse = ", "),
          "\n",
          e$message
        ),
        call. = FALSE
      )
    }
  )
}

# ===========================================
# SECTION 3: PACKAGE LOADING
# ===========================================
# Purpose: Load all dependencies silently and fail fast if one is unavailable.

suppressPackageStartupMessages({
  for (pkg in required_packages) {
    library(pkg, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)
  }
})

# ===========================================
# SECTION 4: GLOBAL APP SETTINGS
# ===========================================
# Purpose: Configure shared Shiny options before UI and server are loaded.

options(shiny.maxRequestSize = 100 * 1024^2)
options(shiny.sanitize.errors = TRUE)
options(shiny.autoreload = FALSE)
options(shiny.usecairo = FALSE)

tryCatch(
  Sys.setlocale("LC_NUMERIC", "C"),
  error = function(e) {
    warning("Could not set LC_NUMERIC locale")
  }
)

# Light cleanup after startup.
gc()