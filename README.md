# shark-attack
A completely end-to-end SQL project using the Global Shark Attack File (GSAF) - one of the messiest datasets you will ever come across spanning nearly two centuries - which takes a raw, unprocessed dataset and cleanses it into an analytics-ready result. Advanced SQL is used throughout the project (ctes, window functions, etc.) to provide a wealth of insight on the risks associated with shark attacks.

**The project has several files:**

SQL script `make_table.SQL` — setup for all three tables needed to create the final database: raw GSAF table; country reference table; World Bank population data (unpivoted from wide to long format).

SQL script `update_gsaf5.SQL` — initial cleaning pass; parses date field into month/day format. Classifies name field, type field & activity fields into quality-status bins which are used for scoring in the next script.

SQL script `consolidate.SQL` — all core cleaning procedures: standardizes case numbers. Corrects dates. Fuzzy-matches country names (via levenshtein). Converts free-text times into binned values. Reconciles fatality flag w/ injury descriptions. Consolidates species names. Eliminates duplicate records. Standardizes incident types.

SQL script `data_quality_scores.SQL` — stored procedure scores dataset across 24 dimensions (validity, completeness, consistency). Outputs failures table, so improvements can be measured w/ cleanliness prior to vs. After cleaning process.

SQL script `run_all.SQL` — orchestrates full pipeline: build tables → clean → score before/afters → compute overall data quality score.

SQL script `analysis.SQL` — analyzes cleansed data for various statistics: fatality rates by activity/species/country. Population-normalized attack rates. Geographic concentration over time. Countries with fatality rates that deviate most from global average.

Image `10_year_rolling_fatality_rate.png` - 
A time-series graph comparing raw high-frequency data for annual occurrence statistics with a trailing 10-year rolling average has been created to allow separating of historical patterns over time from year-to-year variation.

1. **Blue Line (`fatality_rate`):** Annual fatality percentage. Very responsive to small denominators
2. **Orange Line (`rolling_10yr_avg`):** Rolling ten year averages. Reduces variance of shorter term trends, and shows the direction and magnitude of longer term trends.
3. **Horizontal Axis:** Years
4. **Vertical Axis:** Fatality rate as a percentage

#### 💡 Key Findings

* **Global Macro Trends Over Time:** the rolling averages (orange line) show a century-long decline in shark encounter fatality rates - down from approximately **50%+ in the late 19th century to about 10%–13% in the current millennium.** These declines reflect improvements in human activity, including:
  +   rapid coastal communication systems
  +   emergency beach patrol services
  +   helicopter evacuation systems
  +   advances in traumatic injury treatment (rapid blood transfusion and antibiotics)

* **Necessity of Smoothing Data:** due to the relatively small numbers of people involved in shark attacks each year, there is substantial random variation in annual attack fatality rates (blue line). Without some smoothing process, this randomness could be misinterpreted as evidence of an increase/decrease in attack risk at times when no such change had occurred (e.g., the mid-1940s or the early 1900s). Use of a rolling average has smoothed these variations to provide confirmation that while attack risk may vary randomly by year, the overall attack risk remains lower than in the past.
* **Modern 2020s Upward Trend:** there appears to be a significant upward spike in both annual and rolled averages beginning in 2021 continuing into 2026. This presents an opportunity for additional explorative research to identify why there was a shift upwards in reported fatalities, e.g. whether there are correlations between post-COVID pandemic increases in the number of remote, unmonitored water-based activities (including ecotourism/surfing), or whether this represents a shift in how fatalities are being reported.

Image `per_capita_attack_exposure.png` -
This comparison shows how much people are exposed to sharks and how dangerous it has been for them over time by country.

1. **Bottom X-axis (logarithmic scale)** : attacks per million people 
(normalizes number of attacks by varying population density )
2. **Top X-axis (linear)** : fatality rate (%) (measures historical chance that an attack will be fatal)
3. **Bottom Y-axis**: segmented country and decade cohorts (breaks down geography and time)

#### 💡 Key Findings

* **The Large Exposure Due To The Small Denominator (left side):** small island nations such as Bermuda (1960), French Polynesia (2010), and New Caledonia (2000s & 2010s) completely dominate all categories of attack exposure per capita. Because each of these regions has extremely limited bases of population, when an incident occurs, even just a handful, it can scale exponentially and create a per million attack rate greater than 100 per million on the log scale.
* **The High-Exposure/ Low-Lethality Paradox:** If you look at French Polynesia (2010) and New Caledonia (2000), both show very large exposure rates per capita, yet show 0% mortality from attacks. This indicates that the methods used to collect data in this region inflate the number of reported incidents but do not increase the real danger associated with being attacked by a shark. 
* **The "Real Risk" Anomalies:** New Caledonia (2020) and Papua New Guinea (1960) represent an anomaly to the paradox described above. Both exhibit extremely high per capita attack rates which are also linked to high local mortality rates (between 40% to 50%). These conditions suggest unique environmental dangers or acute baseline delay times in providing medical attention during those respective years. 
* **Continental Micro-Risks (right side):** Heavyweight locations for shark-related incidents (Australia, New Zealand) are shown on the far right side of the graph. Since their large numbers of people absorb the metric, their attack rates appear to be lower on the bottom x-axis. However, their highly volatile, spiking orange fatality line proves that while your probability of encountering a shark there per-capita is low, the severity of any resulting injury remains erratic across many years.

Image `shark_attack_frequency_vs_fatality_rate.png` - 
1. **Horizontal Axis:** Attacks Per Million Pooled (Normalizes regional populations at-risk) 
2. **Vertical Axis:** Historic Fatality Rates (%)(Fatality rate per-attack) 
3. **Size of Bubble:** Total Number of Recorded Attacks (Weighting sample-size)

#### 💡 Key Findings

* **The Top Three "Apex" Groups:** Great White, Tiger, and Bull sharks cluster aggressively in the upper-left corner. All three have large recorded samples (bubble size), and all three have demonstrated fatality rates between 20%-25%. The results validate that these three are the most significant absolute statistical threats to humans. 
* **Volume v. Lethality Diversion:** Although Great White Sharks were responsible for the greatest number of documented attacks historically (largest bubble diameter), each individual Tiger Shark has a statistically greater chance of killing a person during an interaction than each Great White Shark (slightly higher Y-value).
* **Revealing the "Denominator" Distortion:** A clear example of a distortion from small denominators can be seen when comparing the Copper shark and Wobbegong shark. The two are located very far to the right along the x-axis indicating an extremely high population adjusted attack rate. However, both have extremely small bubble diameters indicating that the high rate is simply statistical noise. Since there are so few documented encounters, when normalized by local population density, they exhibit artificially inflated relative risks. 
* **Benchmark for Baseline Safety**: Wobbegongs serve well as an anchor for safety metrics. Wobbegongs have an extremely high localized per-capita exposure rate (very high x value), however, there is no historic evidence of fatalities resulting from Wobbegong interactions; therefore, demonstrate that having many incidents in a particular area is not indicative of inherent danger.

Image `shift_in_global_risk.png` - 
The horizontal bar graph compares the countries with the greatest growth in population normalized shark incidents from 1970 to 2020 by averaging each decade's baseline decade averages for the 1970s compared to the modern decade averages of the 2020s.

1. **Horizontal Axis:** Groth in population normalized shark incidents from the decade of 1970 to 2020
2. **Vertical Axis**: Countries

#### 💡 Key Findings

* **The South Pacific Acceleration Baseline**:
French Polynesia and New Caledonia are at the top of all global locations having experienced an increase of "28 to 36 attacks per million" during the 50 year time period. 
This significant increase is indicative of localized trends — such as a huge spike in coastal eco-tourism; changes in local environmental regulations; or improvements in reporting incident tracking systems that have drastically improved the ability to track incidents within the region.

* **The Island Nation Grouping (The Small Denominator Effect)**:
Small island nations and territories including the Maldives, Belize, Samoa and Seychelles completely dominated the middle tier of the growth rankings having shown increases of 8 to 11 attacks per million.
While it may seem alarming, when viewed through a lens of per capita growth rates based upon small baseline populations, this creates a skewed view due to a "small denominator effect"; i.e., even a single digit increase in raw encounters over a decade can be artificially inflated into a high per capita growth rate because small island nations' total population base is relatively small.

* **Continental Micro-Shifts vs. Macro Mass**:
Heavily populated baselines such as Australia and New Zealand rank lower in this specific growth ranking having demonstrated population-normalized growth rates of less than 3 per million. 
Because both Australia and New Zealand have enormous, rapidly increasing populations, they dilute their population-normalized growth rate. 
Although absolute numbers of shark incidents would likely show notable increases in either country over the course of the past 50 years, the population-normalized metric remains both very low and stable.

**Headline findings**

Most reported shark attacks were made by bull sharks, tiger sharks, and great white sharks. However, when you look at fatality rates they need to be viewed along with the fact that all three of those species also represent a huge number of attacks on record. Rates of fatalities are volatile and unreliable when a single species or country reports just a few attacks; e.g., Wobbegongs or Copperheads.
The ten year rolling average of fatality rates have dramatically decreased from the early 1900s, and that can be attributed to advances in medical treatment and reporting; however, the annual fatality numbers are very erratic and that is precisely why we use a rolling average. 
Rates of attacks per capita tell a vastly different story than just the total number of attacks. For example, small island nation states (Bermuda, French Polynesia, New Caledonia) report the most attacks per one million population members. This difference may be due to the "small denominator" effect as opposed to an indication that these places are significantly more hazardous than other locales. 
There are some countries whose fatality rates exceed the world-wide average of fatality rates even if there are more than 20 documented attacks. That is likely a better indicator of how dangerous a particular locale is compared to the island effect of having a low population density.


**Tools**

Pandas to transform GSAF .xlsx file into a .csv. PostgreSQL (stored procedures, window functions, regex, fuzzystrmatch extension for fuzzy country matching). Charts built in Excel from query outputs.

**Known limitations / what I'd improve next**

* Year validation is too permissive - it currently only checks that "Year" is 4 digits, not that it's a plausible/real year, which lets a few clearly invalid years slip through into the trend charts.

* No automated tests; the quality scoring framework doubles as a sanity check but isn't a substitute for unit tests on the cleaning procedures.

* Currently, the data-quality scripts overwrite the same logging tables; therefore, if you run both the clean-data and raw-log processes, they both write their results to the same logging-table, resulting in the raw-log results being overwritten by the clean-data results. Therefore, I would like to add a "run-id" field to allow for each process to be logged separately.
