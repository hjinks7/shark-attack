# Setup & How to Run

## Requirements

An exhaustive list of tools used during this project:

* Python 3.8.2
* PostgreSQL 18.4 
* Jupyter Notebook 
* pandas 
* DBeaver
* Excel
* fuzzystrmatch

## Recommended Run Sequence

Run the project files in the following order:

```text
GSAF_to_CSV.ipynb
01_make_table.sql
02_update_gsaf.sql
03_data_quality_scores.sql
04_consolidate.sql
05_run_all.sql
06_analysis.sql
```

## Step 1: Convert Source Files to CSV

Open and run:

```text
GSAF_to_CSV.ipynb
```

The above mentioned Jupyter notebook takes the original raw Excel file and country codes file, converting them to CSV format to allow you to load the files into PostgreSQL.

## Step 2: Create the PostgreSQL Database

Create a new PostgreSQL database for the project. For example:

```sql
CREATE DATABASE shark_attack;
```

Then connect to the database in DBeaver.

## Step 3: Create and Load Tables

Run:

```text
01_make_table.sql
```

After running this script to create the tables, import the generated CSV files into those tables using DBeaver's CSV Import Wizard.

## Step 4: Initial Cleaning

Run:

```text
02_update_gsaf.sql
```

This performs the first round of cleaning and creates supporting fields that are used later for data quality assessment and downstream analysis across broad categorical 
.
## Step 5: Create Data Quality Score Stored Procedure

Run:

```text
03_data_quality_scores.sql
```

This creates the procedure used to score the dataset across data-quality dimensions like completeness, validity, consistency, and whether there are duplicates.

## Step 6: Create Main Cleaning Procedures

Run:

```text
04_consolidate.sql
```

This is where the primary data cleaning functions are created. The functions include all of the necessary rules to clean the various types of columns, such as:

* Case number standardization
* Country name cleaning
* Time field standardization
* Date field cleaning
* Fatality flag resolution
* Shark species values consolidation
* Duplicate record removal
* Incident type values standardization

## Step 7: Run Full Pipeline

Run:

```text
05_run_all.sql
```

This executes the full cleaning and scoring process. It creates a cleaned copy of the raw GSAF table, applies the cleaning procedures to the copy, 
and calculates data quality scores for the untouched raw table and its transformed copy.

## Step 8: Run Analysis Queries

Run:

```text
06_analysis.sql
```

This script contains the final analysis queries, including:

* Fatality rates by activity
* Fatality rates by species
* Fatality rates by country
* Population-normalized attack rates
* Geographic concentration over time
* Rolling 10-year fatality-rate trends
* Countries with unusually high fatality rates given attack volume

## Expected Output

After completing the full pipeline and running all of the cleaning and scoring processes, you should observe a noticeable increase in overall quality of the data.

Approximate results:

| Metric                     | Before Cleaning | After Cleaning |
| -------------------------- | --------------: | -------------: |
| Overall Data Quality Score |             76% |            89% |
| Fixable Data Quality Score |             80% |            96% |

The final analysis outputs are used to produce the charts shown in the main README and explained in `CHARTS.md`.

