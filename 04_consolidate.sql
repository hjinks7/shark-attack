
-- update case number
create or replace procedure update_case_number(
in tbl regclass
)
language plpgsql
as $$
begin

execute format( $sql$
drop view if exists base cascade;
create view base as (
  select
        ct_id,  
        "Year"::TEXT || '.' ||
        	LPAD("Month"::text, 2, '0') || '.' ||
        	LPAD("Day"::text, 2, '0') 
        	AS base_case_number
    FROM %1$s
);

drop view if exists numbered;
create view numbered as (select *,
ROW_NUMBER() over (partition by base_case_number) as rnk,
COUNT(*) OVER (
  partition by base_case_number
 ) AS dup_count
from base);

update %1$s g
set "Case Number" = 
n.base_case_number ||
case when n.dup_count >1 then
'.' || CHR(96 + n.rnk::INTEGER)
else ''
end
from numbered n
where 
n.ct_id = g.ct_id;

update %1$s
set "Case Number" = null
where "Case Number" ~ '^\d{4}\.\d{2}\.\d{2}'
and (
	substring("Case Number", 6, 2)::int not between 1 and 12
    or substring("Case Number", 9, 2)::int not between 1 and 31
        )
   

$sql$, tbl);
end;
$$;
-- fix date
create or replace procedure fix_date(

in tbl regclass

)

language plpgsql
as $$
begin
execute format($sql$

update %1$s
set "Date" = 
case when ("Month"::INTEGER between 1 and 12) and ("Day"::INTEGER between 1 and 31)
and "Year"::TEXT ~ '[0-9][0-9][0-9][0-9]'
then
TO_CHAR(
("Year" || '.' || LPAD("Month"::TEXT, 2, '0') || '.' || LPAD("Day"::TEXT, 2, '0'))::date, 'DD Mon YYYY')
else "Date"
end;

$sql$, tbl );

end;
$$;

-- fix country
create or replace procedure fix_country(
in tbl regclass
)
language plpgsql
as $$
begin
	execute format($sql$
	
drop extension if exists fuzzystrmatch;
CREATE EXTENSION fuzzystrmatch;

update %1$s
set "Country" = UPPER('United States of America')
where UPPER(TRIM("Country")) = 'USA';

with matches as (
    select distinct on (g.ct_id)
        g.ct_id,
        TRIM(cc."English short name (upper/lower case)") as matched_country,
        levenshtein(
            UPPER(TRIM(g."Country")),
            UPPER(TRIM(cc."English short name (upper/lower case)"))
        ) as dist
    from %1$s g
    join country_codes cc
        on levenshtein(
            UPPER(TRIM(g."Country")),
            UPPER(TRIM(cc."English short name (upper/lower case)"))
        ) <=1
    where NULLIF(TRIM(g."Country"), '') is not null
    order by g.ct_id, dist
)
update %1$s g
set "Country" =
 case
        when UPPER(g."Country") = 'IRAN'
        then 'IRAN'
        when UPPER(g."Country") = 'IRAQ'
        then 'IRAQ'
        when UPPER(g."Country") = 'ICELAND'
        then 'ICELAND'
        when UPPER(g."Country") = 'IRELAND'
        then 'IRELAND'
        else UPPER(m.matched_country)
    end
from matches m
where g.ct_id = m.ct_id;

$sql$, tbl);
end;
$$;

-- fix time

create or replace procedure fix_time(

in tbl regclass

)
language plpgsql

as $$
begin
	execute format($sql$
drop extension if exists fuzzystrmatch;
CREATE EXTENSION fuzzystrmatch;

update %1$s
set "Time" =
	case when TRIM("Time") ~ '^[0-9]h[0-9][0-9]$'
	then LPAD(TRIM("Time"), 5, '0')
	when TRIM("Time") ~'^[0-9]{3}hrs$'
	then LPAD(TRIM("Time"), 5, '0')
	else TRIM("Time")
	end;
	

update %1$s
set "Time" = 
case when "Time" ~ '^[0-9]{4}h$' or "Time" ~ '^[0-9]{4}hr' or "Time" ~ '^[0-9]{4} hr'
	then SUBSTRING("Time", 1, 2) || 'h' || SUBSTRING("Time", 3, 2)
when "Time" ~ '^[0-9]{2}h' or "Time" ~ '^[0-9]{2}hr' or "Time" ~ '^[0-9]{2} hr'
then SUBSTRING("Time", 1, 2) || 'h00'
else
"Time"
end;

update %1$s
set "Time" = 
replace("Time", 'h', ':');


update %1$s
set "Time" =
case when
"Time" ilike '%%a%%m%%' or "Time" ilike '%%morning%%' or "Time" ilike '%%dawn%%' or "Time" ilike '%%sunrise%%' or "Time" ilike '%%day%%break%%'
or "Time" ~ '[a-zA-Z ]*\s*[bB]efore\s*(?:[5-9]|1[01])' or "Time" ~ '[a-zA-Z ]*[bB]efore\s*[0-9]{1}' or "Time" ~ '[a-zA-Z ]*\s*[bB]efore\s*[nN]oon'
or "Time" ~* '^some\s*time\s+between\s+(?:[5-9]|1[01])\s*(?:and|&|-)\s*(?:[5-9]|1[01])$'
then 'Morning'
when "Time" ilike '%%after%%noon%%' or levenshtein(lower("Time"), 'afternoon') <=2 or "Time" ilike '%%mid%%day%%' or "Time" ilike '%%lunch%%'
or "Time" ~ '[a-zA-Z]*\s+[aA]fter\s+(?:12|[1-5])'
then 'Afternoon'
when "Time" ilike '%%evening%%' or levenshtein(lower("Time"), 'evening') <=2 or "Time" ilike '%%dusk%%' 
or "Time" ilike '%%sunset%%' or "Time" ilike '%%sundown%%'
then 'Evening'
when "Time" ilike '%%night%%' or levenshtein(lower("Time"), 'night') <=2 or "Time" ilike '%%dark%%'
then 'Night'
when "Time" ~ '^\?$' or "Time" ~* 'not stated' or "Time" ~* 'unknown' or "Time" ~* 'not advised' or nullif("Time", '') is null
then null
else "Time"
end;

$sql$, tbl);
end;
$$;


-- update fatal
create or replace procedure update_fatal(

in tbl regclass


)
language plpgsql
as $$
begin
	
	execute format($sql$

update %1$s
set "Fatal Y/N" = 
case
            when nullif("Fatal Y/N", '') is null
              and ("Injury" ~* 'injur'
                 or "Injury" ~* 'laceration'
                 or "Injury" ~* 'abrasion'
				or "Injury" ~* 'recover'
                or "Injury" ilike '%%no attack%%'
                 or "Injury" ilike '%%no injury%%'
              )
            then 'N'

            when nullif("Fatal Y/N", '') is null
              and "Injury" ~* '^fatal'
            then 'Y'

            when "Fatal Y/N" = 'N'
              and "Injury" ~* '^fatal'
            then 'Y'

            when ("Fatal Y/N" = 'Y')
              and ("Injury" ~* 'non[- ]*fatal'
				or"Injury" ilike '%%no attack%%'
                 or "Injury" ilike '%%no injury%%')
            then 'N'

            when nullif("Fatal Y/N", '') is null
            then null

            else "Fatal Y/N"
        end

$sql$, tbl);
end;
$$;


-- update species
create or replace procedure update_species(
in tbl regclass
)
language plpgsql
as $$
begin
	execute format($sql$


delete from %1$s
where "Species" = 'Invalid'
or "Injury" ilike '%%no attack%%';

update %1$s
set "Species" = 
case when "Species" ilike '%%questionable%%' or "Species" ilike '%%unidentified%%' or "Species" ilike '%%doubtful%%'
or "Species" ilike '%%unknown%%' or "Species" ilike '%%undetermined%%' or "Species" ilike '%%not stated%%' or "Species" = ''
or "Species" ilike '%%shark%%involvement%%not%%confirmed'
then null
else "Species"
end;

update %1$s
set "Species"= 
case when
"Species" ilike '%%blacktip%%' then 'Blacktip Shark'
when "Species" ilike '%%dogfish%%'
or "Species" ilike '%%spurdog%%'
then 'Dogfish Shark'
when "Species" ilike '%%blue%%pointer%%'
then 'Blue Pointer Shark'
when "Species" ilike '%%hammer%%head%%'
then 'Hammerhead Shark'
when "Species" ilike '%%bull%%' or "Species" ilike '%%C%%leucas%%'
then 'Bull Shark'
when "Species" ilike '%%bronze%%whaler%%'
then 'Copper Shark'
when "Species" ilike '%%blue%%whaler%%'
then 'Blue Shark'
when "Species" ilike '%%whaler%%'
then REPLACE("Species", 'whaler', 'whaler shark')
when "Species" ilike '%%great%%white%%' or "Species" ilike '%%GWS%%' or "Species" ilike '%%white%%'
then 'Great White Shark'
when "Species" ilike '%%wobbegong%%'
then 'Wobbegong Shark'
when "Species" ilike '%%tiger%%shark%%'
then 'Tiger Shark'
when "Species" ilike '%%lemon%%shark%%'
then 'Lemon Shark'
when nullif("Species", '') is null or "Species" is null
then null
else "Species"
end;

$sql$, tbl);
end;
$$;

-- delete duplicates

create or replace procedure delete_duplicates(

in tbl regclass

)
language plpgsql
as $$
begin
	execute format ($sql$


with ranked as (
    select
        ct_id,
        ROW_NUMBER() over (
            partition by "Date", "Location",
  				case when name_quality_status in ('first_last', 'first_middle_last')
                     then "Name"
                     else null
                end,
                case when name_quality_status not in ('first_last', 'first_middle_last')
                     then "Age"
                     else null
                end,
                case when name_quality_status not in ('first_last', 'first_middle_last')
                     then "Sex"
                     else null
                end,
                case when name_quality_status not in ('first_last', 'first_middle_last')
                     then "Injury"
                     else null
                end
            order by ct_id
        ) as rnk
    from %1$s
)
delete from %1$s g
using ranked r
where g.ct_id = r.ct_id
  and r.rnk > 1;

$sql$, tbl);
end;
$$;

-- fix type

create or replace procedure update_types (
in tbl regclass)
language plpgsql
as $$
begin
execute format ($sql$ 

update %1$s
set "Type" =

case type_quality_status
when 'unprovoked' then 'Unprovoked'
when 'provoked' then 'Provoked'
when 'incident involving watercraft' then 'Incident involving watercraft'
when 'sea disaster' then 'Sea Disaster'
else "Type"
end;

update %1$s
set "Type" =
case when "Type" ilike '%%boat%%' then 'Incident involving watercraft'
else "Type"
end;

$sql$, tbl);
end;
$$;


