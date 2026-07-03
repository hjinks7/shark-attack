
-- attacks and fatality rate by type of incident
select type_quality_status,
COUNT(*) as attacks,
ROUND(AVG(case when "Fatal Y/N" = 'Y' then 1 else 0 end)*100.0, 1) as fatality_rate
from gsaf_copy
group by type_quality_status;

-- attacks and fatality rate by activity
SELECT
    "Activity",
    COUNT(*) AS attacks,
    ROUND(
        AVG(CASE WHEN "Fatal Y/N" = 'Y' THEN 1 ELSE 0 END) * 100,
        1
    ) AS fatality_rate
FROM gsaf_copy
WHERE "Activity" IS NOT NULL
GROUP BY "Activity"
HAVING COUNT(*) >= 10
ORDER BY attacks DESC;

-- attacks and fatality rate by species
select "Species",
COUNT(*) as attacks,
 ROUND(
        AVG(CASE WHEN "Fatal Y/N" = 'Y' THEN 1 ELSE 0 END) * 100,
        1
    ) AS fatality_rate
FROM gsaf_copy
WHERE "Species" IS NOT NULL
GROUP BY "Species"
HAVING COUNT(*) >= 10
ORDER BY attacks DESC;

-- attacks and fatality rate by country

select "Country", COUNT(*) as attacks,
ROUND(
        AVG(CASE WHEN "Fatal Y/N" = 'Y' THEN 1 ELSE 0 END) * 100,
        1
    ) AS fatality_rate
from gsaf_copy
where "Country" is not null
group by "Country" 
having count(*) > 10
order by attacks, fatality_rate desc;

-- attacks by rough time of day; misleading because more people in the water in afternoon

select "Time", COUNT(*) as attacks
from gsaf_copy
where "Time" = 'Morning' or "Time" = 'Afternoon' or "Time" = 'Evening' or "Time" = 'Night'
group by "Time" 
having COUNT(*)>10
order by attacks

-- attacks by hour of day

with formatted_times as (
select "Time" from gsaf_copy 
where "Time" ~ '^[0-9][0-9]:[0-9][0-9]'

)

select EXTRACT(hour from "Time"::time) as hour, count(*) as attacks
from formatted_times
group by 1
order by 2 desc

-- intermediate/advanced analysis questions

-- How has the 10-year rolling fatality rate changed (since 1800)?

with decade_attack as (select *,
("Year"::INTEGER / 10)*10 as decade
from gsaf_copy
where "Year" is not null
and "Fatal Y/N" in ('Y', 'N')),

rolling_fatality_rate as(

select decade, AVG(case when "Fatal Y/N" = 'Y' then 1 else 0 end) as avg_fatality_rate_decade
from decade_attack
group by decade

),

lagged as(

select *, lag(avg_fatality_rate_decade) over (order by decade) as prev_decade_fatality_rate
from rolling_fatality_rate

)

select decade, ROUND(avg_fatality_rate_decade * 100.0, 4) as avg_fatality_rate_decade,
ROUND((avg_fatality_rate_decade - prev_decade_fatality_rate)/prev_decade_fatality_rate, 4) * 100.0 as ten_year_change_in_avg_fatality_rate
from lagged
where prev_decade_fatality_rate != 0
and decade >=1800
order by decade desc

-- Have shark attacks become more geographically concentrated or more dispersed over time (since 1800)?
with decades as (
    select
        *,
        ("Year"::integer / 10) * 10 as decade
    from gsaf_copy
    where "Year" is not null
      and nullif(trim("Country"), '') is not null
),

country_decade_counts as (
    select
        decade,
        "Country",
        count(*) as attacks
    from decades
    where decade > 1800
    group by decade, "Country"
),

ranked as (
    select
        *,
        sum(attacks) over (partition by decade) as total_attacks,
        rank() over (
            partition by decade
            order by attacks desc
        ) as country_rank
    from country_decade_counts
)

select
    decade,
    count(*) as countries_with_attacks,
    round(max(case when country_rank = 1 then attacks * 100.0 / total_attacks end), 2) as top_1_country_share,
    round(sum(case when country_rank <= 3 then attacks else 0 end) * 100.0 / max(total_attacks), 2) as top_3_country_share
from ranked
group by decade
order by countries_with_attacks desc;


--  Which countries have experienced the largest increase in recorded attacks over the past 50 years?

with decades as (
select *, ("Year"::INTEGER / 10) * 10 as decade
from gsaf_copy
),

country_groups as (
select "Country", decade, COUNT(*) as attacks
from decades
group by "Country", decade
),

lagged as (select *, lag(attacks, 5) over (partition by "Country" order by decade) as prev_50_years_attacks from country_groups)

select "Country", coalesce(attacks - prev_50_years_attacks, 0) as fifty_year_change
from lagged 
where decade = 2020
and attacks > prev_50_years_attacks
order by fifty_year_change desc

-- Which activities have experienced the greatest decline in fatality rate over the past century?

with centuries as (
select *, ("Year"::INTEGER / 100) + 1 as century
from gsaf_copy
where "Fatal Y/N" in ('Y', 'N')
),

activities_grouped as (select 
    activity_quality_status, century,
    COUNT(*) as attacks,
    ROUND(
        AVG(case when "Fatal Y/N" = 'Y' then 1 else 0 end) * 100,
        1
    ) AS fatality_rate
from centuries
where nullif(activity_quality_status, '') is not null
group by activity_quality_status, century
having COUNT(*) >= 10),

previous_century as (select *, lag(fatality_rate) over (partition by activity_quality_status order by century) as prev_century_fatality_rate
from activities_grouped)

select *, fatality_rate - prev_century_fatality_rate as change_in_fatality_rate
from previous_century
where fatality_rate < prev_century_fatality_rate
and century = 21
order by change_in_fatality_rate asc;



