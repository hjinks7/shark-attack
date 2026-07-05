# shark-attack
A completely end-to-end SQL project using the Global Shark Attack File (GSAF) - one of the messiest datasets you will ever come across spanning nearly two centuries - which takes a raw, unprocessed dataset and cleanses it into an analytics-ready result. Advanced SQL is used throughout the project (ctes, window functions, etc.) to provide a wealth of insight on the risks associated with shark attacks.

The project has several files:

SQL script make_table.SQL — setup for all three tables needed to create the final database: raw GSAF table; country reference table; World Bank population data (unpivoted from wide to long format).

SQL script update_gsaf5.SQL — initial cleaning pass; parses date field into month/day format. Classifies name field, type field & activity fields into quality-status bins which are used for scoring in the next script.

SQL script consolidate.SQL — all core cleaning procedures: standardizes case numbers. Corrects dates. Fuzzy-matches country names (via levenshtein). Converts free-text times into binned values. Reconciles fatality flag w/ injury descriptions. Consolidates species names. Eliminates duplicate records. Standardizes incident types.

SQL script data_quality_scores.SQL — stored procedure scores dataset across 24 dimensions (validity, completeness, consistency). Outputs failures table, so improvements can be measured w/ cleanliness prior to vs. After cleaning process.

SQL script run_all.SQL — orchestrates full pipeline: build tables → clean → score before/afters → compute overall data quality score.

SQL script analysis.SQL — analyzes cleansed data for various statistics: fatality rates by activity/species/country. Population-normalized attack rates. Geographic concentration over time. Countries with fatality rates that deviate most from global average.

Image 10_year_fatality_rate.png ...

Image per_capita_attack_exposure.png ...

Image shark_attack_frequency_vs_fatality_rate.png ...

Image shift_in_global_risk.png ...

Headline findings

Most reported shark attacks were made by bull sharks, tiger sharks, and great white sharks. However, when you look at fatality rates they need to be viewed along with the fact that all three of those species also represent a huge number of attacks on record. Rates of fatalities are volatile and unreliable when a single species or country reports just a few attacks; e.g., Wobbegongs or Copperheads. The pooled attacks per million metric shows that... 
The ten year rolling average of fatality rates have dramatically decreased from the early 1900s, and that can be attributed to advances in medical treatment and reporting; however, the annual fatality numbers are very erratic and that is precisely why we use a rolling average. 
Rates of attacks per capita tell a vastly different story than just the total number of attacks. For example, small island nation states (Bermuda, French Polynesia, New Caledonia) report the most attacks per one million population members. This difference may be due to the "small denominator" effect as opposed to an indication that these places are significantly more hazardous than other locales. 
There are some countries whose fatality rates exceed the world-wide average of fatality rates even if there are more than 20 documented attacks. That is likely a better indicator of how dangerous a particular locale is compared to the island effect of having a low population density.


Tools

PostgreSQL (stored procedures, window functions, regex, fuzzystrmatch extension for fuzzy country matching). Charts built externally from query outputs.

Known limitations / what I'd improve next

Year validation is too permissive — it currently only checks that "Year" is 4 digits, not that it's a plausible/real year, which lets a few clearly invalid years slip through into the trend charts.
No automated tests; the quality scoring framework doubles as a sanity check but isn't a substitute for unit tests on the cleaning procedures.
...
