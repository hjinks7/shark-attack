-- shark attack data

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

-- country codes

drop table if exists country_codes;
create table public.country_codes (
"SI. No" TEXT,
"English short name (upper/lower case)" TEXT,
"Link to ISO 3166-2 subdivision codes" TEXT,
"Alpha-2 code" TEXT,
"Alpha-3 code" TEXT,
"Numeric code" TEXT

);

update country_codes
set "English short name (upper/lower case)" = 
case when "English short name (upper/lower case)" ilike '%iran%' then 'Iran'
when "English short name (upper/lower case)" ilike '%iraq%' then 'Iraq'
else "English short name (upper/lower case)"
end;


-- world population data
drop table if exists world_population;

create table world_population (
    "Country Name"      TEXT,
    "Country Code"    TEXT,
    "Indicator Name"   TEXT,
   "Indicator Code"    TEXT,

    "1960" BIGINT,
    "1961" BIGINT,
    "1962" BIGINT,
    "1963" BIGINT,
    "1964" BIGINT,
    "1965" BIGINT,
    "1966" BIGINT,
    "1967" BIGINT,
    "1968" BIGINT,
    "1969" BIGINT,
    "1970" BIGINT,
    "1971" BIGINT,
    "1972" BIGINT,
    "1973" BIGINT,
    "1974" BIGINT,
    "1975" BIGINT,
    "1976" BIGINT,
    "1977" BIGINT,
    "1978" BIGINT,
    "1979" BIGINT,
    "1980" BIGINT,
    "1981" BIGINT,
    "1982" BIGINT,
    "1983" BIGINT,
    "1984" BIGINT,
    "1985" BIGINT,
    "1986" BIGINT,
    "1987" BIGINT,
    "1988" BIGINT,
    "1989" BIGINT,
    "1990" BIGINT,
    "1991" BIGINT,
    "1992" BIGINT,
    "1993" BIGINT,
    "1994" BIGINT,
    "1995" BIGINT,
    "1996" BIGINT,
    "1997" BIGINT,
    "1998" BIGINT,
    "1999" BIGINT,
    "2000" BIGINT,
    "2001" BIGINT,
    "2002" BIGINT,
    "2003" BIGINT,
    "2004" BIGINT,
    "2005" BIGINT,
    "2006" BIGINT,
    "2007" BIGINT,
    "2008" BIGINT,
    "2009" BIGINT,
    "2010" BIGINT,
    "2011" BIGINT,
    "2012" BIGINT,
    "2013" BIGINT,
    "2014" BIGINT,
    "2015" BIGINT,
    "2016" BIGINT,
    "2017" BIGINT,
    "2018" BIGINT,
    "2019" BIGINT,
    "2020" BIGINT,
    "2021" BIGINT,
    "2022" BIGINT,
    "2023" BIGINT,
    "2024" BIGINT,
    "2025" BIGINT
);

-- unpivoting dataset 
drop table if exists world_population_long;

create table world_population_long as
select
    "Country Name",
    "Country Code",
    "Indicator Name",
    "Indicator Code",
    v.year,
    v.population
from world_population
cross join lateral (
    values
        (1960, "1960"),
        (1961, "1961"),
        (1962, "1962"),
        (1963, "1963"),
        (1964, "1964"),
        (1965, "1965"),
        (1966, "1966"),
        (1967, "1967"),
        (1968, "1968"),
        (1969, "1969"),
        (1970, "1970"),
        (1971, "1971"),
        (1972, "1972"),
        (1973, "1973"),
        (1974, "1974"),
        (1975, "1975"),
        (1976, "1976"),
        (1977, "1977"),
        (1978, "1978"),
        (1979, "1979"),
        (1980, "1980"),
        (1981, "1981"),
        (1982, "1982"),
        (1983, "1983"),
        (1984, "1984"),
        (1985, "1985"),
        (1986, "1986"),
        (1987, "1987"),
        (1988, "1988"),
        (1989, "1989"),
        (1990, "1990"),
        (1991, "1991"),
        (1992, "1992"),
        (1993, "1993"),
        (1994, "1994"),
        (1995, "1995"),
        (1996, "1996"),
        (1997, "1997"),
        (1998, "1998"),
        (1999, "1999"),
        (2000, "2000"),
        (2001, "2001"),
        (2002, "2002"),
        (2003, "2003"),
        (2004, "2004"),
        (2005, "2005"),
        (2006, "2006"),
        (2007, "2007"),
        (2008, "2008"),
        (2009, "2009"),
        (2010, "2010"),
        (2011, "2011"),
        (2012, "2012"),
        (2013, "2013"),
        (2014, "2014"),
        (2015, "2015"),
        (2016, "2016"),
        (2017, "2017"),
        (2018, "2018"),
        (2019, "2019"),
        (2020, "2020"),
        (2021, "2021"),
        (2022, "2022"),
        (2023, "2023"),
        (2024, "2024"),
        (2025, "2025")
) as v(year, population)
where v.population is not null;