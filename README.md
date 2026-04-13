# shiny_growth
The Root Growth Analysis Toolbox is a Shiny application designed to analyze root growth dose–response data. This tool lets you import CSV files, map inhibitor concentrations to numeric values, normalize growth to controls, visualize results (dose–effect curves, violin and bar plots), and run per-plot statistical tests (ANOVA/Tukey or Kruskal–Wallis/Dunn with CLD)—without requiring any R programming knowledge.

## Requirements

**R Version**: ≥ 4.0.0

**Key Dependencies**:

- shiny, shinydashboard (UI framework)
- ggplot2, ggpubr (visualizations)
- mgcv (GAM modeling)
- multcomp, PMCMRplus, emmeans, ARTool (statistical testing, post-hoc, and factorial non-parametric fallback)
- DT, readr (data handling)

All dependencies are automatically managed through the `global.R` configuration file in the application directory.

For a complete list of required packages, please refer to the `global.R` file.
If you encounter issues with automatic package installation, you can manually install the required packages using the following R command for each package:

```
install.packages("package_name", dependencies = TRUE)
library(package_name)
```

## Installation Methods

### Method 1: Local Installation

For individual use on your personal computer:

1. **Install R and RStudio** (if not already installed)

2. **Download the zip file from the latest release**:
    Extract the contents to a desired location on your computer. This will create a folder named `shiny_fluorcam`.

3. **Launch the application**:

    - Open RStudio
    - Go to `File` -> `Open File...`
    - Select the `App.R` in the `shiny_fluorcam` directory
    - Click the `Run App` button in the panel at the top left of the RStudio IDE.

    The application will open in your default web browser.

> Note: During the first launch, R will automatically install all required packages specified in the `global.R` file. Depending on your internet connection and system performance, this may take several minutes.
> Subsequent launches will be significantly faster.
> If you encounter any issues with package installation, please refer to the **Requirements** section below for manual installation instructions.
> For further assistance, consult the **Support** section.

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

1. **Upload application files** to `/srv/shiny-server/fluorcam_toolbox/` using SFTP with the `shiny` user account
2. **Access the application** via web browser at: `http://<server-address>:3838/fluorcam_toolbox/`

## files and directories

- Configuration file: `/etc/shiny-server/shiny-server.conf`
- Application directories: `/srv/shiny-server/`
- Log directory: `/var/log/shiny-server/`

#### Server Management Commands



```
# Check server status
sudo systemctl status shiny-server

# Start/stop/restart server
sudo systemctl start shiny-server
sudo systemctl stop shiny-server
sudo systemctl restart shiny-server

# View logs
sudo tail -f /var/log/shiny-server/*.log
```

## Usage

Detailed step-by-step usage instructions are available in the **Help.md** document, which can be accessed directly from the application interface through the help section. This comprehensive guide covers:

- File preparation and naming conventions
- Data loading procedures
- Statistical analysis options
- Visualization customization
- Export procedures
- Troubleshooting common issues
