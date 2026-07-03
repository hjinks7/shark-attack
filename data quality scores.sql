

create or replace procedure create_data_quality_scores(
in tbl regclass
)
language plpgsql
as $$
DECLARE total_rows NUMERIC;
begin

EXECUTE format ('SELECT COUNT(*) FROM %s', tbl)
INTO total_rows;

drop table if exists failures;
create table failures (
case_number_valid Float,
case_number_unique Float,
case_number_complete Float,
name_valid Float,
activity_valid float,
type_valid Float,
type_complete float,
fatal_valid float,
fatal_complete float,
age_complete float,
species_complete float,
species_valid float,
species_shark float,
country_upper float,
country_valid float,
time_valid float,
time_complete float,
year_valid float,
year_complete float,
date_valid float,
date_consistent float,
date_complete float,
injury_fatal_match float,
no_duplicates float);

EXECUTE format($sql$
insert into failures (case_number_valid, case_number_unique, case_number_complete,
name_valid, activity_valid, type_valid, type_complete, fatal_valid, fatal_complete,
age_complete, species_complete, species_valid, species_shark, country_upper, country_valid, time_valid,
time_complete, year_valid, year_complete, date_valid, date_consistent, date_complete, 
injury_fatal_match, no_duplicates)
values(
-- case number valid
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where "Case Number" !~ '^[0-9]{4}.[0-9]{2}.[0-9]{2}'
and LEFT("Case Number", 4) != "Year"::TEXT
or SUBSTRING("Case Number", 6, 2) != LPAD ("Month"::TEXT, 2, '0')
or SUBSTRING("Case Number", 9, 2) != LPAD("Day"::TEXT, 2, '0')
or SUBSTRING("Case Number", 6, 2)::INTEGER not between 1 and 12
or SUBSTRING("Case Number", 9, 2)::INTEGER not between 1 and 31),

-- case number unique
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where "Case Number" in (select "Case Number" from %2$s
group by "Case Number"
having count(*) > 1)),

-- case number complete
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where NULLIF("Case Number", '') is null),

-- name valid
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where name_quality_status ilike 'unknown'
or name_quality_status ilike 'generic_description'
or name_quality_status ilike 'other_text'),

-- activity valid

(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where
activity_quality_status ilike 'miscellaneous')
,

-- type valid

(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where 
type_quality_status ilike 'invalid'
),

-- type complete

(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where
NULLIF("Type", '') is null or "Type" is null 
),

-- fatal valid

(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where
"Fatal Y/N" != 'Y' 
and "Fatal Y/N" != 'N'),

-- fatal complete

(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where 
nullif("Fatal Y/N", '') is null or "Fatal Y/N" is null),

-- age complete
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where 
nullif("Age", '') is null or "Age" is null

),

-- species complete
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where 
nullif("Species", '') is null or "Species" is null

),

-- species valid
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where 
TRIM("Species") ~* 'Invalid'
or "Injury" ilike '%%no injury%%'
or "Injury" ilike '%%no attack%%'
),

-- species shark
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where 
"Species" ~* 'shark'
),

-- country upper
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where 
"Country" != UPPER("Country")

),

-- country valid
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s g
left join country_codes cc
on UPPER(g."Country") = UPPER(cc."English short name (upper/lower case)")
where cc."English short name (upper/lower case)" is null


),

-- time valid
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where "Time" !~ '[0-9][0-9]:[0-9][0-9]'
and "Time" not ilike '%%morning%%'
and "Time" not ilike '%%afternoon%%'
and "Time" not ilike '%%evening%%'
and "Time" not ilike '%%night%%'),

-- time complete
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where NULLIF("Time", '') is null or "Time" is null ),

-- year valid
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where "Year"::TEXT !~ '^[0-9][0-9][0-9][0-9]$'

),

-- year complete
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where NULLIF("Year"::TEXT, '') is null or "Year" is null ),

-- date valid
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where 
TRIM("Date") !~ '^\d{4}-\d{2}-\d{2}( \d{2}:\d{2}:\d{2}(\.\d+)?)?$'
and TRIM("Date") !~ '^\d{1,2}-[A-Za-z]{3}-\d{4}$'
and TRIM("Date") !~ '^\d{1,2}-[A-Za-z]{3,9}-\d{4}$'
and TRIM("Date") !~ '^\d{1,2}(st|nd|rd|th)? [A-Za-z]+ \d{4}$'

),

-- date consistent
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where "Date" !=
case when "Case Number" ~* '^[0-9][0-9][0-9][0-9].[0-1][0-9].[0-3][0-9]' and
SUBSTRING("Case Number", 6, 2)::INTEGER between 1 and 12 
and SUBSTRING("Case Number", 9, 2)::INTEGER between 1 and 31
then
	TO_CHAR(
 	 TO_DATE(LEFT("Case Number", 10), 'YYYY.MM.DD'),
  	 'DD Mon YYYY')
else null
end
),
-- date complete
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where NULLIF("Date", '') is null or "Date" is null

),
-- injury and fatal match
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from %2$s
where ("Fatal Y/N" = 'Y' and ("Injury" ~* 'non[- ]*fatal' or "Injury" ilike '%%no attack%%'
or "Injury" ilike '%%no injury%%'))
or ("Fatal Y/N" = 'N' and ("Injury" ~* '^Fatal' or "Injury" ilike '%%killed%%'))
),

-- check duplicates
(select 1 - ROUND(COUNT(*) * 1.0 / %1$s, 4)
from (
    select
        COUNT(*) over (
            partition by
                "Date",
				"Location",
				"Name")
        as dup_count
    from %2$s)

WHERE dup_count > 1
)

);

$sql$, total_rows, tbl);
end;
$$
