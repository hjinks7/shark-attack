-- making the table and calling stored procedures
drop table if exists gsaf5 cascade;
CREATE TABLE public.gsaf5 (
  "Date" text,
  "Year" real,
  "Type" text,
  "Country" text,
  "State" text,
  "Location" text,
  "Activity" text,
  "Name" text,
  "Sex" text,
  "Age" text,
  "Injury" text,
  "Fatal Y/N" text,
  "Time" text,
  "Species " text,
  "Source" text,
  pdf text,
  "href formula" text,
  href text,
  "Case Number" text,
  "Case Number.1" text,
  "original order" text,
  "Unnamed: 21" text,
  "Unnamed: 22" text
);

drop table if exists country_codes;
create table public.country_codes (
"SI. No" TEXT,
"English short name (upper/lower case)" TEXT,
"Link to ISO 3166-2 subdivision codes" TEXT,
"Alpha-2 code" TEXT,
"Alpha-3 code" TEXT,
"Numeric code" TEXT

)

update country_codes
set "English short name (upper/lower case)" = 
case when "English short name (upper/lower case)" ilike '%iran%' then 'Iran'
when "English short name (upper/lower case)" ilike '%iraq%' then 'Iraq'
else "English short name (upper/lower case)"
end

call update_gsaf('gsaf5'::regclass);

drop table if exists gsaf_copy cascade;
select * into gsaf_copy from gsaf5;

call update_case_number ('gsaf_copy'::regclass);
call fix_country('gsaf_copy'::regclass);
call fix_date ('gsaf_copy'::regclass);
call fix_time ('gsaf_copy'::regclass);
call update_fatal ('gsaf_copy'::regclass);
call update_species ('gsaf_copy'::regclass);
call delete_duplicates ('gsaf_copy'::regclass);
call update_types('gsaf_copy'::regclass);

call create_data_quality_scores('gsaf_copy'::regclass);
call create_data_quality_scores('gsaf5'::regclass);

select * from failures;

-- overall score

SELECT AVG(score) AS overall_score
FROM failures,
LATERAL (
    VALUES
        (case_number_valid),
        (case_number_unique),
        (case_number_complete),
        (name_valid),
        (activity_valid),
        (type_valid),
        (type_complete),
        (fatal_valid),
        (fatal_complete),
        (age_complete),
        (species_complete),
        (species_valid),
        (country_upper),
        (country_valid),
        (time_valid),
        (time_complete),
        (year_valid),
        (year_complete),
        (date_valid),
        (date_consistent),
        (date_complete),
        (injury_fatal_match)
) AS v(score);


-- excluding scores for missing data like age or time
SELECT AVG(score) AS fixable_quality_score
FROM failures,
LATERAL (
    VALUES
        (case_number_valid),
        (case_number_unique),
        (activity_valid),
        (type_valid),
        (fatal_valid),
        (species_valid),
        (country_upper),
        (country_valid),
        (time_valid),
        (year_valid),
        (date_valid),
        (date_consistent),
        (injury_fatal_match)
) AS v(score);