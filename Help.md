

# RootTracker: User Guide

## About This App

RootTracker is a Shiny application designed to analyze root growth dose–response data. This tool lets you import CSV files, map inhibitor concentrations to numeric values, normalize growth to controls, visualize results (dose–effect curves, violin and bar plots), and run per-plot statistical tests (ANOVA/Tukey or Kruskal–Wallis/Dunn with CLD)—without requiring any R programming knowledge.

------

## 1. Data Preparation: The Key to Success

Correctly formatted data is essential for the app to function properly. Please follow these guidelines carefully.

### File Naming Convention

Your data files must be named according to a specific pattern that combines your main grouping variable (`VAR1`) and your concentration variable (`VAR2`).

- **Required Format:** `VAR1_VAR2.csv`
- **Example:** If your line is "WT" and the concentration is "10", the file must be named `WT_10.csv`.

The app uses this naming convention to automatically extract metadata.

### CSV Content Format

In this app, each uploaded `.csv` file is expected to contain one measurement value per row (root length), with no required header row.

- The grouping information is extracted from the filename (`VAR1_VAR2.csv`).
- `Day` is assigned automatically according to the **"Number of measures per roots"** setting (number of sequential measurements per root).

------

## 2. Step-by-Step Workflow

Follow these steps to go from raw data to final results.

### Step 2.1: Launch the App

1. Open the app from your R session (for example with `shiny::runApp("App.R")` in the project folder).

### Step 2.2: Upload & Load Data

1. In **"1. File Name Configuration"**, set what `VAR1` and `VAR2` mean in your filenames.
2. In **"2. Load Data"**, browse your computer to select your prepared CSV files into the upload area. The app validates the filenames.
3. In the same panel:
    - **File Pattern:** Use this to filter which of the uploaded files to load. For example, if you only want to analyze files containing "Col-0", you could enter `Col-0`. To load all, leave it as `.csv`.
    - **Number of measures per roots:** Enter how many sequential measurements belong to each root (used to reconstruct `Day1`, `Day2`, etc.).
4. Click **"Load Data"**. A preview of the combined dataset will appear.

### Step 2.3: Map Inhibitor Concentrations

If your concentration variable (`VAR2`) contains text or non-numeric labels, a yellow warning will appear. You must map these labels to numbers.

1. Go down to the **"Map Inhibitor Concentrations"** panel.
2. For each unique text label listed, enter its corresponding numeric value in the input box. For example, for the label "10uM", you would enter `10`.
3. Click **"Apply Concentration Mapping"**. The warning will disappear, and the data is now ready for analysis.

### Step 2.4: Configure Your Analysis

1. Go to the **"3. Analysis Parameters"** panel.
2. **Select Plot Type:**
    - `Dose-Effect Curve`: Shows mean growth vs. log-concentration. 
    - `Violin Plot`: Shows the distribution of all data points across all days and groups. Good for checking data spread.
    - `Bar Plot`: Compares groups at a single, specific day and concentration.
3. **Choose the Bar Plot Statistical Rule:**
    - `Strict`: use ANOVA only when the Shapiro-Wilk test supports normality; otherwise switch to Kruskal-Wallis.
    - `Permissive`: keep the parametric test when the data have sufficient sample sizes and homogeneous variances, even if Shapiro-Wilk is not fully satisfied.
4. **Adjust Text Size:** Use the *Text size* slider to make axis labels, titles, and legend text larger or smaller.
5. **Select Day/Concentration:** Based on your plot choice, select the specific day and/or concentration to analyze.
6. **(Optional) Reorder Groups:** Drag and drop the group names in the "Group Order" list to change their order in the plot legend and on the x-axis (for bar plots).

### Step 2.5: Run the Analysis

1. Click the **"Start Analysis"** button.
2. The application will automatically switch to the **"Analysis Results"** tab, where your plot and a summary of the retained statistical decision will be displayed.
3. For bar plots, the results panel shows the chosen mode, the selected test (ANOVA or Kruskal-Wallis), and the reason for that choice.

### Step 2.6: Interpret the Results

- **Dose-Effect Curve:** Asterisks (`*`) will appear above concentration points where a statistically significant difference was found between the groups.
- **Bar Plot:** Compact Letter Display (CLD) letters (a, b, ab) will appear above the bars. Groups that do not share a letter are significantly different from each other.

### Step 2.7: Export Your Findings

1. Go to the **"4. Export Results"** panel.
2. **Download Processed Data (CSV):**
	- Enter a filename.
	- Click the button to download the clean, combined dataset that was used for the analysis.
3. **Download Statistical Tables (ZIP):**
    - Enter a filename.
    - Click the button to download a `.zip` archive containing all statistical tables plus the analysis decision summary for bar plots. The archive includes normality tests, Levene's test when relevant, ANOVA/Kruskal-Wallis results, post-hoc tests, and a CSV summarizing the selected test and its rationale.
4. **Download Plot:**
    - Enter a filename and select the desired format (PNG, PDF, SVG), dimensions, and units.
    - Click **"Download Plot"** to save the currently displayed graphic.

