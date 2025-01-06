--------------------------------------- USE OF CTE ------------------------------------------- 

-- Top 33 Country's death percentage with over 1 million cases
WITH GlobalAverage AS (
    SELECT 
        (SUM(total_deaths)::NUMERIC / SUM(total_cases)) * 100 AS world_death_percentage
    FROM public."CovidDeaths"
    WHERE date = '2021-04-30'
)
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (total_deaths::NUMERIC / total_cases) * 100 AS death_percentage
FROM public."CovidDeaths", GlobalAverage
WHERE date = '2021-04-30'
  AND (total_deaths::NUMERIC / total_cases) * 100 > world_death_percentage
  AND total_cases > 1000000
ORDER BY death_percentage DESC;


------------------------------------ USE OF JOINS ---------------------------------------------------

-- Total tests & cases, percentage cases by country - 03-31-2021
SELECT vac.location, vac.total_tests, dea.total_cases, (dea.total_cases::NUMERIC/vac.total_tests)*100 AS percentage_cases_to_tests
FROM public."CovidVaccinations" AS vac
JOIN public."CovidDeaths" AS dea ON (vac.location = dea.location AND vac.date = dea.date) 
WHERE (vac.location <> vac.continent AND vac.date = '2021-03-31')
	AND vac.total_tests IS NOT NULL
ORDER BY vac.total_tests DESC, dea.total_cases DESC, percentage_cases_to_tests;

-- Total deaths to cases percentage by country - 03-31-2021
SELECT vac.location, vac.total_tests, dea.total_deaths, ROUND((dea.total_deaths::NUMERIC/vac.total_tests)*100,2) AS percentage_deaths_to_tests
FROM public."CovidVaccinations" AS vac
JOIN public."CovidDeaths" AS dea ON (vac.location = dea.location AND vac.date = dea.date) 
WHERE (vac.location <> vac.continent AND vac.date = '2021-03-31')
	AND vac.total_tests IS NOT NULL
ORDER BY vac.total_tests DESC, dea.total_cases DESC, percentage_deaths_to_tests;



--------------------------------     USE OF AGGREGATE FUNCTIONS -----------------------------------

--  Death percentage per month, Cases, deaths,   GLOBALLY -- 
SELECT 
    TO_CHAR(date, 'YYYY-MM') AS month, -- Group by month (YYYY-MM format)
    MAX(total_cases) AS max_total_cases, -- Max of total cases for the month
    MAX(total_deaths) AS max_total_deaths, -- Max of total deaths for the month
    (MAX(total_deaths)::NUMERIC / NULLIF(MAX(total_cases), 0)) * 100 AS max_death_percentage -- Calculate max death percentage
FROM 
    public."CovidDeaths"
WHERE 
    total_deaths IS NOT NULL -- Only consider rows with deaths
GROUP BY 
    TO_CHAR(date, 'YYYY-MM') -- Group by year and month (not by full date)
ORDER BY 
    max_death_percentage DESC;

-- Countries with Highest Infection Rate compared to population latest date of 4-30-21
SELECT location,
		population,
		total_cases,
		MAX(total_cases) AS highest_infection_count,
		MAX((total_cases::NUMERIC/population))*100 AS percent_population_infected
FROM public."CovidDeaths"
WHERE (total_cases IS NOT NULL AND population IS NOT NULL) AND date = '2021-04-30'
GROUP BY location, population, total_cases
ORDER BY percent_population_infected DESC;


-- Highest Death Count per Country Population
SELECT location,
		MAX(total_deaths::NUMERIC) AS total_death_count
FROM public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC
OFFSET 28;


-- Highest Death Count by per Continent Population as of 04-30-21
SELECT DISTINCT continent,
		MAX(total_deaths::NUMERIC) AS total_death_count,
		date
FROM public."CovidDeaths"
WHERE continent IS NOT NULL AND date = '2021-04-30'
GROUP BY continent, date
ORDER BY total_death_count DESC;


------------------------- USE OF SUBQUERIES -----------------------------------

-- Total cases by country - Max Date --- 
SELECT location, total_cases
FROM public."CovidDeaths"
WHERE date = (SELECT MAX(date) 
			  FROM public."CovidDeaths")
  AND total_cases IS NOT NULL
  AND location <> continent
ORDER BY total_cases DESC;

-- Total deaths by country - 4/30/2021 -- 2 separate ways
SELECT location, total_deaths
FROM public."CovidDeaths"
WHERE (date = '2021-04-30' AND total_deaths IS NOT NULL) 
	 AND location <> continent
ORDER BY total_deaths DESC;

SELECT location, total_deaths
FROM public."CovidDeaths"
WHERE date = (SELECT MAX(date) FROM public."CovidDeaths")
  AND total_deaths IS NOT NULL
  AND location <> continent
ORDER BY total_deaths DESC;

-- Total cases, deaths, death percentage by country - 4/30/2021 --
SELECT location, total_cases, total_deaths, (total_deaths::NUMERIC/total_cases)*100 AS death_percentage
FROM public."CovidDeaths"
WHERE date = (SELECT MAX(date) FROM public."CovidDeaths")
  AND total_deaths IS NOT NULL
  AND location <> continent
GROUP BY location, total_deaths, total_cases
ORDER BY total_cases DESC;

-- People vaccinated by country - MAX date -- 
SELECT location, people_vaccinated
FROM public."CovidVaccinations"
WHERE date = (SELECT MAX(date) FROM public."CovidVaccinations")
	AND people_vaccinated IS NOT NULL
	AND location <> continent
ORDER BY people_vaccinated;

-- Total vaccinations by country -- 
SELECT location, total_vaccinations
FROM public."CovidVaccinations"
WHERE date = (SELECT MAX(date) 
              FROM public."CovidVaccinations"
              WHERE total_vaccinations IS NOT NULL)
AND total_vaccinations IS NOT NULL
AND location <> continent
ORDER BY total_vaccinations DESC;

-- People vaccinated by country - MAX date -- 
SELECT location, people_vaccinated
FROM public."CovidVaccinations"
WHERE date = (SELECT MAX(date) 
              FROM public."CovidVaccinations"
              WHERE people_vaccinated IS NOT NULL)
AND people_vaccinated IS NOT NULL
AND location <> continent
ORDER BY people_vaccinated DESC;

-- Verifying China Null Value -- 
SELECT location, people_vaccinated
FROM public."CovidVaccinations"
WHERE date = (SELECT MAX(date) 
              FROM public."CovidVaccinations")
AND location ='China'
ORDER BY people_vaccinated DESC;

-- Total tests by country - 03-31-2021 -- 
SELECT location, total_tests
FROM public."CovidVaccinations"
WHERE (location <> continent AND date = '2021-03-31')
	AND total_tests IS NOT NULL
ORDER BY total_tests DESC;



---------------------------------- BASIC QUERIES --------------------------------------------

-- United States cases & deaths by date
SELECT location, 
		date, 
		total_cases, 
		total_deaths, 
		(total_deaths::NUMERIC / total_cases)*100 as Death_Percentage
FROM public."CovidDeaths"
WHERE location LIKE '%United States%'
ORDER BY location;

-- United States percentage of cases per population
SELECT location, 
		date, 
		population,
		total_cases, 
		(total_cases::NUMERIC / population)*100 as population_cases_percentage
FROM public."CovidDeaths"
WHERE location LIKE '%United States%'
ORDER BY location;

-- World Cases, Deaths, and World Death Percentage
SELECT DISTINCT location, 
		date, 
		total_cases, 
		total_deaths, 
		(total_deaths::NUMERIC / total_cases)*100 AS death_percentage
FROM public."CovidDeaths"
WHERE location = 'World'
ORDER BY total_cases DESC, total_deaths DESC
LIMIT 1;

-- United States Cases, Deaths, and Death Percentage
SELECT location, 
		date, 
		total_cases, 
		total_deaths, (total_deaths::NUMERIC / total_cases)*100 AS death_percentage
FROM public."CovidDeaths"
WHERE location LIKE '%United States%'
ORDER BY date DESC
LIMIT 1;

-- Top 33 Country's death percentage with over 1 million cases
SELECT location, 
		date, total_cases, 
		total_deaths, 
		(total_deaths::NUMERIC / total_cases)*100 AS death_percentage
FROM public."CovidDeaths"
WHERE (total_deaths IS NOT NULL AND date = '2021-04-30')
GROUP BY location, date, total_cases, total_deaths
HAVING total_cases > 1000000
ORDER BY death_percentage DESC;




