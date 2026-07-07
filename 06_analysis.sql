
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
order by attacks desc;

-- attacks and fatality rate by species

with avg_pop as (
    select "Country", round(avg(population),0) as avgpop
    from population_merged_with_gsaf
    group by "Country"
),
species_country_totals as (
    select 
        g."Species",
        g."Country",
        count(*) as attacks_in_country,
        a.avgpop
    from gsaf_copy g
    join avg_pop a
        on g."Country" = a."Country"
    where g."Species" is not null
    group by g."Species", g."Country", a.avgpop
),

species_frequency as (
    select
        "Species",
        sum(attacks_in_country) as total_attacks,
        round(
            sum(attacks_in_country) * 1000000.0 / nullif(sum(avgpop), 0), 
            3
        ) as attacks_per_million_pooled
    from species_country_totals
    group by "Species"
),

species_fatality as (
    select
        "Species",
        round(avg(case when "Fatal Y/N" = 'Y' then 1 else 0 end) * 100, 1) as fatality_rate
    from gsaf_copy
    where "Species" is not null
    group by "Species"
)

select
    f."Species",
    f.total_attacks,
    f.attacks_per_million_pooled,
    fa.fatality_rate
from species_frequency f
join species_fatality fa
    on f."Species" = fa."Species"
where f.total_attacks >= 10
order by f.total_attacks desc;


-- non-fatal sharks
with species_metrics as (select "Species",
COUNT(*) as attacks,
 ROUND(
        AVG(CASE WHEN "Fatal Y/N" = 'Y' THEN 1 ELSE 0 END) * 100,
        1
    ) AS fatality_rate
FROM gsaf_copy
WHERE "Species" IS NOT NULL
GROUP BY "Species"
HAVING COUNT(*) >= 10)

select * from species_metrics where fatality_rate = 0 and attacks > 0
and "Species" ~ '^[a-zA-Z]+ [sS]hark$';

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
order by attacks desc, fatality_rate desc;

-- attacks and fatality rate by country, adjusting for population size
with decades as (
    select 
        "Country",
        ("Year"::INTEGER / 10) * 10 as decade,
        ct_id,
        case when "Fatal Y/N" = 'Y' then 1.0 else 0.0 end as is_fatal
    from gsaf_copy
    where nullif("Country", '') is not null
      and nullif("Year"::TEXT, '') is not null
      and "Fatal Y/N" in ('Y', 'N')
),
population_decades as (
    select 
        "Country",
        (population_year::INTEGER / 10) * 10 as decade,
        avg(population) as avg_population_for_decade
    from population_merged_with_gsaf
    where population is not null
    group by 1, 2
),
normalized_for_population as (
    select 
        d."Country",
        d.decade,
        count(d.ct_id) as attacks,
        round(p.avg_population_for_decade, 0) as population_density,
        -- Safely calculate metrics per million using NULLIF jic population data is missing
        round(count(d.ct_id) * 1000000.0 / nullif(p.avg_population_for_decade, 0), 3) as attacks_per_million_people,
        round(avg(d.is_fatal) * 100, 1) as fatality_rate
    from decades d
    join population_decades p 
        on upper(trim(d."Country")) = upper(trim(p."Country")) 
        and d.decade = p.decade
    group by d."Country", d.decade, p.avg_population_for_decade
)
select 
    "Country",
    decade,
    attacks,
    population_density,
    attacks_per_million_people,
    fatality_rate
from normalized_for_population
where attacks > 5 
order by decade desc, attacks_per_million_people desc;


-- attacks by rough time of day; misleading because more people in the water in afternoon

select "Time", COUNT(*) as attacks
from gsaf_copy
where "Time" = 'Morning' or "Time" = 'Afternoon' or "Time" = 'Evening' or "Time" = 'Night'
group by "Time" 
having COUNT(*)>10
order by attacks;

-- attacks by hour of day

with formatted_times as (
select "Time" from gsaf_copy 
where "Time" ~ '^[0-9][0-9]:[0-9][0-9]'

)

select EXTRACT(hour from "Time"::time) as hour, count(*) as attacks
from formatted_times
group by 1
order by 2 desc;

-- intermediate/advanced analysis questions

-- How has the fatality rate changed by decade since 1800?

with decade_attack as (select *,
("Year"::INTEGER / 10)*10 as decade
from gsaf_copy
where nullif("Year"::TEXT, '') is not null
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
ROUND((avg_fatality_rate_decade - prev_decade_fatality_rate)/prev_decade_fatality_rate, 4) * 100.0 as ten_year_pct_change_in_avg_fatality_rate
from lagged
where prev_decade_fatality_rate != 0
and decade >=1800
order by decade desc;

-- Have shark attacks become more geographically concentrated or more dispersed over time?
with decades as (
    select *, 
        ("Year"::integer / 10) * 10 as decade 
    from gsaf_copy 
    where "Year" is not null 
      and nullif(trim("Country"), '') is not null
      and "Year" >= 1800
),
population_decades as (
    select 
        "Country",
        (population_year::integer / 10) * 10 as decade,
        avg(population) as avg_population_for_decade
    from population_merged_with_gsaf
    where population is not null and population > 0
    group by 1, 2
),
country_decade_rates as (
    select 
        d.decade, 
        d."Country", 
        count(d.ct_id) as attacks,
        round(count(d.ct_id) * 1000000.0 / nullif(p.avg_population_for_decade, 0), 3) as attacks_per_million
    from decades d
    join population_decades p 
        on upper(trim(d."Country")) = upper(trim(p."Country")) 
        and d.decade = p.decade
    group by d.decade, d."Country", p.avg_population_for_decade
    having count(d.ct_id) >= 2
),
ranked as (
    select *, 
        sum(attacks_per_million) over (partition by decade) as total_attacks_rate_pool, 
        rank() over ( 
            partition by decade 
            order by attacks_per_million desc 
        ) as country_rank 
    from country_decade_rates
)
select 
    decade, 
    count(*) as countries_with_tracked_rates, 
    round(max(case when country_rank = 1 then attacks_per_million * 100.0 / total_attacks_rate_pool end), 2) as top_1_country_share, 
    round(sum(case when country_rank <= 3 then attacks_per_million else 0 end) * 100.0 / max(total_attacks_rate_pool), 2) as top_3_country_share 
from ranked 
group by decade 
order by decade desc;


--  Which countries have experienced the largest increase in recorded attacks over the past 50 years, adjusting for population?
with country_year as ( 
   select distinct "Country", decade FROM gsaf_copy
    cross join (select distinct ("Year"::INTEGER / 10) * 10 AS decade FROM gsaf_copy where "Year" is not null)
), 
bring_in_attacks as ( 
    select 
        cy."Country", 
        cy.decade, 
        g."Name"
    from country_year cy 
    left join gsaf_copy g 
        on cy."Country" = g."Country" 
        and cy.decade = (g."Year"::INTEGER / 10) * 10 
    where cy."Country" != ''
),
country_groups as ( 
    select 
        "Country", 
        decade, 
        COUNT("Name") as attacks 
    from bring_in_attacks 
    group by "Country", decade 
), 
lagged as (
    select *, 
        lag(attacks, 5) over (partition by "Country" order by decade) as prev_50_years_attacks 
    from country_groups
),
final_population_merge as (
    select 
        l.*,
        (
            select round(avg(population), 0) 
            from population_merged_with_gsaf p 
            where upper(trim(p."Country")) = upper(trim(l."Country")) 
              and (p."Year"::INTEGER / 10) * 10 = l.decade
        ) as avg_population_per_decade
    from lagged l
)
select 
    "Country", 
    attacks as attacks_2020s,
    coalesce(prev_50_years_attacks, 0) as attacks_1970s,
    (attacks - coalesce(prev_50_years_attacks, 0)) as fifty_year_change, 
    round(coalesce(
        (attacks - coalesce(prev_50_years_attacks, 0)) * 1000000 / nullif(avg_population_per_decade, 0), 
        0), 4)
    as fifty_year_change_normalized_per_million 
from final_population_merge 
where decade = 2020 
  and attacks > coalesce(prev_50_years_attacks, 0) 
order by fifty_year_change_normalized_per_million desc;

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

-- rolling 10-year average of fatality rate

WITH year_spine AS (
    SELECT DISTINCT "Year"::INT AS year 
    FROM gsaf_copy 
    WHERE "Year" IS NOT NULL AND "Year"::TEXT ~ '^[0-9]{4}$'
),
fatality_rate_per_year AS (
    SELECT 
        ys.year,
        -- Calculate the actual raw metrics per year, handling empty years as 0
        COALESCE(COUNT(CASE WHEN g."Fatal Y/N" = 'Y' THEN 1 END), 0) AS fatal_attacks,
        coalesce(COUNT(g.ct_id), 0) AS total_attacks
    FROM year_spine ys
    LEFT JOIN gsaf_copy g ON ys.year = g."Year"::INT
    GROUP BY ys.year
)
SELECT 
    year,
    -- Calculate the exact global fatality rate for THIS specific year
    ROUND(
        (fatal_attacks * 100.0) / NULLIF(total_attacks, 0), 
        1
    ) AS yearly_fatality_rate,
    
    -- Calculate the rolling 10-year average using RANGE to protect against missing years
    ROUND(
        (SUM(fatal_attacks) OVER w_10yr * 100.0) / 
        NULLIF(SUM(total_attacks) OVER w_10yr, 0), 
        1
    ) AS rolling_10yr_avg
FROM fatality_rate_per_year
WINDOW w_10yr AS (
    ORDER BY year 
    RANGE BETWEEN 9 PRECEDING AND CURRENT ROW
)
ORDER BY year DESC;

-- Which countries have unusually high fatality rates given their attack volume?
with overall_fatality as (

select
    avg(case when "Fatal Y/N" = 'Y' then 1 else 0 end) as overall_fatality_rate
from gsaf_copy
where "Fatal Y/N" in ('Y', 'N')

),

country_mets as (

select
    "Country",
    count(*) as attacks,
    sum(case when "Fatal Y/N" = 'Y' then 1 else 0 end) as fatal_attacks,
    -- 23% is overall fatality rate, 20 is a healthy credibility threshold
    ROUND(
    ((SUM(CASE WHEN "Fatal Y/N" = 'Y' THEN 1.0 ELSE 0.0 END) + (20 * 0.23)) / (COUNT(*) + 20)), 
    1
) AS weighted_fatality_rate
from gsaf_copy
where "Country" is not null
and "Fatal Y/N" in ('Y', 'N')
group by "Country"

),

population_country as (
select "Country",
avg(population) as avg_pop
from population_merged_with_gsaf
group by "Country"
),

population_normalized_per_million as(

select cm."Country",
attacks,
weighted_fatality_rate,
attacks * 1000000 / nullif(avg_pop , 0) as attacks_per_million,
fatal_attacks * 1000000 / nullif(avg_pop, 0) as fatal_attacks_per_million
from population_country p
join country_mets cm
on 
p."Country" = cm."Country"

)

select
    p."Country",
   	p.attacks,
   	round(p.attacks_per_million, 2) as attacks_per_million,
    round(p.fatal_attacks_per_million, 2) as fatal_attacks_per_million,
    round(p.weighted_fatality_rate * 100.0, 4) as fatality_rate_normalized,
    round((p.weighted_fatality_rate - o.overall_fatality_rate) * 100, 1) as percentage_points_above_overall
from population_normalized_per_million p
cross join overall_fatality o
where nullif("Country", '') is not null
order by percentage_points_above_overall desc, attacks desc;