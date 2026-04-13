<h1>
  <img src="www/logo_RT.png" alt="RootTracker logo" width="54" />
  RootTracker
</h1>

Track Growth. Analyze with Confidence.

## Overview

RootTracker is a web-based application designed to analyze root growth dose–response data. This tool lets you import CSV files, map inhibitor concentrations to numeric values, normalize growth to controls, visualize results (dose–effect curves, violin and bar plots), and run per-plot statistical tests (ANOVA/Tukey or Kruskal–Wallis/Dunn with CLD)—**without requiring any R programming knowledge**.

## Features

- **📊 Data Import**: Load multiple CSV files with automatic metadata extraction from filenames
- **🔄 Data Normalization**: Normalize growth measurements to control conditions
- **📈 Dose–Response Analysis**: Generate dose–effect curves using GAM (Generalized Additive Models)
- **🎨 Multiple Visualizations**: Dose–effect curves, violin plots, bar plots with confidence intervals
- **📉 Statistical Testing**: 
  - Parametric tests (ANOVA with Tukey post-hoc)
  - Non-parametric alternatives (Kruskal–Wallis with Dunn post-hoc)
  - Compact Letter Display (CLD) for easy interpretation
- **💾 Export Results**: Export processed data, plots, and statistical summaries
- **🖥️ No Coding Required**: Intuitive web interface for researchers

## Table of Contents

- [Quick Start](#quick-start)
- [Requirements](#requirements)
- [Installation Methods](#installation-methods)
  - [Method 1: Local Installation](#method-1-local-installation)
  - [Method 2: Server Installation (Ubuntu 24)](#method-2-server-installation-ubuntu-24)
- [File Structure](#file-structure)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Support & Contributing](#support--contributing)

## Quick Start

1. **Install R** (≥ 4.0.0) and RStudio if not already installed
2. **Download and extract** the application files
3. **Open `App.R`** in RStudio and click "Run App"
4. **Test with sample data** in the `test_data/` folder (see examples below)
5. **Access the Help** tab in the application for detailed instructions

Detailed step-by-step usage instructions are in [Help.md](Help.md).

## Requirements

**Operating System**: macOS, Windows, or Linux

**R Version**: ≥ 4.0.0 (tested on R 4.x)

**System Requirements**:
- RAM: Minimum 4 GB (8 GB recommended for large datasets)
- Disk Space: ~200 MB for application and dependencies
- Internet connection: Required for initial package installation only

**Key Dependencies**:

- `shiny`, `shinydashboard` (UI framework)
- `ggplot2`, `ggpubr` (visualizations)
- `mgcv` (GAM modeling)
- `multcomp`, `PMCMRplus`, `emmeans`, `ARTool` (statistical testing, post-hoc, and factorial non-parametric fallback)
- `DT`, `readr` (data handling)

All dependencies are automatically managed through the `global.R` configuration file in the application directory.

For a complete list of required packages, please refer to the [global.R](global.R) file.

**Note**: If you encounter issues with automatic package installation, you can manually install required packages using:

```r
install.packages("package_name", dependencies = TRUE)
library(package_name)
```

## Installation Methods

### Method 1: Local Installation

For individual use on your personal computer:

1. **Install R and RStudio** (if not already installed)
   - Download from [r-project.org](https://www.r-project.org/) and [posit.co](https://posit.co/download/rstudio-desktop/)

2. **Download the application**:
   - Clone the repository or download the latest release as a ZIP file
   - Extract the contents to a desired location on your computer

3. **Launch the application**:
   - Open RStudio
   - Go to `File` → `Open File...`
   - Select the `App.R` file in the application directory
   - Click the `Run App` button in the top-right of the editor panel

   The application will open in your default web browser at `http://localhost:XXXX`.

> **First Launch**: During the first launch, R will automatically install all required packages specified in `global.R`. Depending on your internet connection and system performance, this may take 5–10 minutes. Subsequent launches will be significantly faster.

> **Package Installation Issues?** If you encounter errors, see the [Troubleshooting](#troubleshooting) section below.

### Method 2: Server Installation (Ubuntu 24)

For multi-user deployment on a dedicated server:

#### Prerequisites Installation

```
sudo apt install -y gfortran cmake libfontconfig1-dev libcurl4-openssl-dev
sudo apt install -y libxml2-dev libharfbuzz-dev libfribidi-dev
sudo apt install -y libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev
sudo apt install -y liblapack-dev libblas-dev libnlopt-dev
sudo apt install -y --no-install-recommends software-properties-common dirmngr
```

#### R Installation (Latest Version)

```
# Add CRAN repository key
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc

# Add CRAN repository
add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

# Install R and Shiny
sudo apt update
sudo apt install -y --no-install-recommends r-base
sudo R -e "install.packages('shiny', repos='https://cran.rstudio.com/')"
```

#### Shiny Server Installation

```
sudo apt install -y gdebi-core
cd /tmp
SHINY_VERSION=x.x.x.x   # for instance: 1.5.23.1030
curl -O "https://download3.rstudio.org/ubuntu-20.04/x86_64/shiny-server-${SHINY_VERSION}-amd64.deb"
sudo gdebi shiny-server-${SHINY_VERSION}-amd64.deb
rm shiny-server-${SHINY_VERSION}-amd64.deb
```

#### Deploy the Application

1. **Upload application files** to `/srv/shiny-server/shiny_growth/` using SFTP with the `shiny` user account
2. **Access the application** via web browser at: `http://<server-address>:3838/shiny_growth/`

#### Server Directory Structure

- Configuration file: `/etc/shiny-server/shiny-server.conf`
- Application directories: `/srv/shiny-server/`
- Log directory: `/var/log/shiny-server/`

#### Server Management Commands

```bash
# Check server status
sudo systemctl status shiny-server

# Start/stop/restart server
sudo systemctl start shiny-server
sudo systemctl stop shiny-server
sudo systemctl restart shiny-server

# View logs
sudo tail -f /var/log/shiny-server/*.log
```

## File Structure

```
shiny_growth/
├── App.R                 # Main application launcher
├── global.R              # Package dependencies and global configuration
├── server.R              # Server-side logic
├── UI.R                  # User interface definition
├── helpers.R             # Helper functions for data processing and analysis
├── Help.md               # Detailed user guide (accessible in the app)
├── README.md             # This file
├── LICENSE               # License information
├── www/                  # Static assets served by Shiny (logos, favicon)
│   ├── root-tracker-logo.svg
│   ├── root-tracker-monogram.svg
│   └── logo_RT.png
└── test_data/            # Sample datasets for testing
    ├── WT_AZ0.csv
    ├── WT_AZ001.csv
    ├── WT_AZ01.csv
    ├── WT_AZ03.csv
    ├── WT_AZ08.csv
    ├── mrp5ems_AZ0.csv
    ├── mrp5ems_AZ001.csv
    ├── mrp5ems_AZ01.csv
    ├── mrp5ems_AZ03.csv
    ├── mrp5ems_AZ08.csv
    ├── mrp5KO_AZ0.csv
    ├── mrp5KO_AZ001.csv
    ├── mrp5KO_AZ01.csv
    ├── mrp5KO_AZ03.csv
    └── mrp5KO_AZ08.csv
```

## Sample Data

The `test_data/` folder contains pre-formatted sample datasets based on root growth experiments:

- **WT** (Wild-type control): Baseline root growth
- **mrp5ems** (MRP5 mutant with enhanced multi-drug sensitivity): Treatment variant
- **mrp5KO** (MRP5 knockout): Treatment variant

Each variant includes measurements at multiple inhibitor concentrations: AZ0, AZ001, AZ01, AZ03, and AZ08.

**To test the application**:
1. Launch the app
2. In "2. Load Data", upload all files from `test_data/`
3. Click "Load Data" to see the combined dataset
4. Explore the visualization and statistical analysis tabs

## Usage

### Quick Workflow Overview

1. **Data Preparation**: Format your CSV files as `GROUPNAME_CONCENTRATION.csv`
2. **Upload Files**: Use the upload interface in the app
3. **Configure Settings**: Specify what the filenames represent (e.g., genotype and inhibitor concentration)
4. **Load & Normalize**: Load data and normalize to control conditions
5. **Visualize**: Explore dose–response curves and distributions
6. **Analyze**: Run statistical tests (ANOVA or Kruskal–Wallis)
7. **Export**: Download plots and summary tables

### Full Documentation

For detailed step-by-step instructions on data preparation, file formats, statistical methods, and troubleshooting, consult the **[Help.md](Help.md)** document. This comprehensive guide is also accessible directly from the application interface through the Help tab.

Topics covered in Help.md:
- File naming conventions and CSV format requirements
- Data loading procedures
- Inhibitor concentration mapping
- Statistical analysis options (parametric vs. non-parametric)
- Visualization customization
- Export procedures
- Common issues and solutions

## Troubleshooting

### Application Won't Start

**Problem**: "Package X is not installed" error
- **Solution**: Manually install the package:
  ```r
  install.packages("package_name", dependencies = TRUE)
  ```
  Then restart the app.

**Problem**: Application is very slow on first launch
- **Solution**: The app is installing packages in the background. This is normal and may take 5–10 minutes on first run. Subsequent launches will be much faster.

### Data Loading Issues

**Problem**: Files are rejected or show "Invalid filename"
- **Solution**: Ensure your filenames follow the pattern `VAR1_VAR2.csv` (e.g., `WT_10.csv`). See [Help.md](Help.md) for details.

**Problem**: Data values appear as zeros or missing values
- **Solution**: Verify your CSV files contain numerical data (one value per row, no header). See the Data Preparation section in [Help.md](Help.md).

### Statistical Testing Issues

**Problem**: "Singular fit" or convergence warnings in GAM model
- **Solution**: This may indicate insufficient data variation. Try grouping observations differently or consulting the Help section.

**Problem**: Test cannot be performed due to insufficient replicates
- **Solution**: Ensure you have at least 2 replicates per group for statistical testing.

### Browser & Display Issues

**Problem**: Application not displaying correctly or buttons are unresponsive
- **Solution**: 
  - Refresh the page (Cmd+R on macOS, Ctrl+R on Windows/Linux)
  - Clear browser cache
  - Try a different browser (Chrome, Firefox, Safari)

### Contact Support

If you encounter a bug or have questions not covered in [Help.md](Help.md), please:
- Check this README and Help.md first
- Review any error messages carefully (they often suggest solutions)
- Open an issue on GitHub if the problem persists

## Data Format Example

Here's what a sample CSV file should look like:

**File name**: `WT_10.csv`

**Content** (root length measurements, one per line):
```
45.3
48.2
44.8
46.9
47.1
```

The app will extract:
- VAR1 (from filename): "WT" (e.g., genotype)
- VAR2 (from filename): "10" (e.g., inhibitor concentration)
- Measurements: 5 values (45.3, 48.2, 44.8, 46.9, 47.1)

For multi-root datasets with sequential measurements, see the "Number of measures per roots" setting in the app.

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

## Citation

If you use this application in your research, please cite:

```
RootTracker (shiny_growth)
Version: [check App.R or releases for version number]
[Add citation details as appropriate for your repository]
```

## Support & Contributing

### Questions or Feedback?

- 📖 **Read the Help**: Start with [Help.md](Help.md) for comprehensive documentation
- 🐛 **Report Bugs**: Open an issue on GitHub with a detailed description
- 💡 **Suggest Features**: Use GitHub discussions or issues with the "enhancement" label

### Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code follows R style guidelines and includes appropriate comments.

---

**Last Updated**: April 2026
