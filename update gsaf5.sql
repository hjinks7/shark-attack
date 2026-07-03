
create or replace procedure update_gsaf (

in tbl regclass

)
language plpgsql

as $$

begin

execute format( $sql$

alter table %1$s
add column "ct_id" serial primary key,
add column "Month" smallint,
add column "Day" smallint,
add column name_quality_status TEXT,
add column type_quality_status TEXT,
add column activity_quality_status TEXT;

alter table %1$s
rename "Species " to "Species";

update %1$s
set "Year" = 
"Year"::INTEGER


update %1$s 
set "Month"= 
	case
	WHEN "Date" ~ '^\d{4}-\d{2}-\d{2}'
    THEN EXTRACT(MONTH FROM "Date"::date)
    WHEN "Date" ILIKE '%%Jan%%' THEN 1
    WHEN "Date" ILIKE '%%Feb%%' THEN 2
    WHEN "Date" ILIKE '%%Mar%%' THEN 3
    WHEN "Date" ILIKE '%%Apr%%' THEN 4
    WHEN "Date" ILIKE '%%May%%' THEN 5
    WHEN "Date" ILIKE '%%Jun%%' THEN 6
    WHEN "Date" ILIKE '%%Jul%%' THEN 7
    WHEN "Date" ILIKE '%%Aug%%' THEN 8
    WHEN "Date" ILIKE '%%Sep%%' THEN 9
    WHEN "Date" ILIKE '%%Oct%%' THEN 10
    WHEN "Date" ILIKE '%%Nov%%' THEN 11
    WHEN "Date" ILIKE '%%Dec%%' THEN 12
    ELSE 0
	end;

update %1$s
set "Day" = 
case
	when "Date" ~ '^\d{4}-\d{2}-\d{2}'
	then EXTRACT(day from "Date"::date)
	
	when TRIM("Date") ~ '^\d{1,2}[-/ ]+[A-Za-z]+[-/ ]+\d{4}'
	THEN REGEXP_REPLACE(TRIM("Date"), '^(\d{1,2}).*$', '\1')::INTEGER
	
	when TRIM("Date") ~ '^\d{1,2}(st|nd|rd|th)?[ ]+[A-Za-z]+'
	THEN REGEXP_REPLACE(TRIM("Date"), '^(\d{1,2}).*$', '\1')::INTEGER
	
	when TRIM("Date") ~ '^[a-zA-Z]+[-/ ]+\d{1,2}' 
	then REGEXP_REPLACE(TRIM("Date"), '^([a-zA-Z]+)([-/ ]+)(\d{1,2}).*$', '\3')::INTEGER
	-- fix this because 4000 B.C. is being truncated as day = 40
	else 0
end;


update %1$s
set name_quality_status =
 CASE
      WHEN "Name" IS NULL OR TRIM("Name") = '' THEN 'missing'
      WHEN TRIM("Name") ~* '^(unknown|anonymous|not identified)$' THEN 'unknown'
      WHEN TRIM("Name") ~* '(man|woman|male|female|boy|girl)' THEN 'generic_description'
      when TRIM("Name") ~* '[2-9 ]*(males|men|women|females|boys|girls|crew|sailors)' then 'group'
      WHEN TRIM("Name") ~* '^[A-Z][A-Za-z''-]+ [A-Z][A-Za-z''-]+$' THEN 'first_last'
      WHEN TRIM("Name") ~* '^[A-Z][A-Za-z''-]+ [A-Z][A-Za-z''-]+ [A-Z][A-Za-z''-]+$' 
      THEN 'first_middle_last'
      ELSE 'other_text'
    END;

update %1$s
set type_quality_status = 
case
	when TRIM("Type") ~* 'watercraft' then 'incident involving watercraft'
	when TRIM("Type") ~* 'sea disaster' then 'sea disaster'
	when TRIM("Type") ~* 'unprovoked' then 'unprovoked'
	when TRIM("Type") ~* 'provoked' then 'provoked'
	when TRIM("Type") ~* 'questionable' then 'unknown'
	when NULLIF("Type", '') is null or "Type" is null then 'unknown'
	else
	'invalid'
end;


update %1$s
set activity_quality_status =
case
	when 
	"Activity" ilike '%%Swim%%' then 'Swimming'
	when "Activity" ilike '%%Bath%%' then 'Bathing'
	when "Type" ~ 'Watercraft' then 'Watercraft Activity'
	when "Type" ~ 'Sea Disaster' then 'Watercraft Activity'
	when "Activity" ilike '%%Fishing%%' then 'Fishing'
	when "Activity" ilike '%%Diving%%' then 'Diving'
	when "Activity" ilike '%%Surf%%' then 'Surfing'
	when "Activity" ilike '%%Snorkel%%' then 'Snorkeling'
	when "Activity" ilike '%%Board%%' then 'Board Activity'
	when "Activity" ilike '%%Kayak%%' then 'Watercraft Activity'
	when "Activity" ilike '%%Canoe%%' then 'Watercraft Activity'
	when "Activity" ilike '%%Boat%%' then 'Watercraft Activity'
	when "Activity" ilike '%%Ship%%' then 'Watercraft Activity'
	when "Activity" ilike '%%Watercraft%%' then 'Watercraft Activity'
	when "Activity" ilike '%%Air%%' then 'Air Activity'
	when "Activity" ilike '%%Wading%%' then 'Wading'
	when "Activity" ilike '%%Float%%' then 'Wading'
	when "Activity" ilike '%%Tread%%' then 'Wading'
	when "Activity" ilike '%%Sunk%%' then 'Watercraft Activity'
	when "Activity" ilike '%%Sink%%' then 'Watercraft Activity'
	when "Activity" ilike '%%Yacht%%' then 'Watercraft Activity'
	when "Activity" ilike '%%Stand%%' then 'Standing'
	when "Activity" ilike '%%Hunt%%' then 'Hunting'
	else 'Miscellaneous'
	end;

$sql$, tbl);
end;
$$

call update_gsaf('gsaf_copy'::regclass);
