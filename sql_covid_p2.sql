-- DATA & STRUCTURE VALIDATION --

SELECT *
FROM `covid_19_project.covid_deaths`
ORDER BY 3,4
LIMIT 50

SELECT *
FROM `covid_19_project.covid_vaccinations`
ORDER BY 3,4
LIMIT 50

-- DATA EXPLORATION --

SELECT
  location,
  date,
  total_cases,
  new_cases,
  total_deaths,
  population
FROM `covid_19_project.covid_deaths`
ORDER BY 3,4


SELECT
  location,
  date,
  total_cases,
  new_cases,
  total_deaths,
  population
FROM `covid_19_project.covid_deaths`
ORDER BY 1,2

-- Calculate death rate as % with two decimal places
SELECT
  location,
  date,
  total_cases,
  total_deaths,
  ROUND((total_deaths/total_cases)*100,2) AS death_rate
FROM `covid_19_project.covid_deaths`
ORDER BY 1,2


-- Show death rate in the United States only
SELECT
  location,
  date,
  total_cases,
  total_deaths,
  ROUND((total_deaths/total_cases)*100,2) AS death_rate
FROM `covid_19_project.covid_deaths`
WHERE location = 'United States'
ORDER BY 1,2

-- Show Infection Rate as %
SELECT
  location,
  total_cases,
  population,
  ROUND((total_cases/population)*100,5) AS infection_rate
FROM `covid_19_project.covid_deaths`
GROUP BY location, total_cases, population
ORDER BY 1,2

-- Show top 10 locations with highest infection rate
SELECT
  location,
  MAX(ROUND((total_cases/population)*100,5)) AS infection_rate
FROM `covid_19_project.covid_deaths`
GROUP BY location, population
ORDER BY 2 DESC
LIMIT 10

-- Show the infection rates of the locations with the highest infection counts
SELECT
  location,
  population,
  MAX(total_cases) AS highest_infection_count,
  MAX(ROUND((total_cases/population)*100,2)) AS infection_rate
FROM `covid_19_project.covid_deaths`
GROUP BY location, population
ORDER BY infection_rate DESC

-- Show total death count, descending, by location
SELECT
  location,
  MAX(total_deaths) AS total_death_count
FROM `covid_19_project.covid_deaths`
GROUP BY location
ORDER BY total_death_count DESC

SELECT
  location,
  MAX(total_deaths) AS total_death_count
FROM `covid_19_project.covid_deaths`
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Show total death count, by continent, in desceding order
SELECT
  continent,
  MAX(total_deaths) AS total_death_count
FROM `covid_19_project.covid_deaths`
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC


-- Show total death count, by location, in descending order. Ensure duplicates are not included.
SELECT
  location,
  MAX(total_deaths) AS total_death_count
FROM `covid_19_project.covid_deaths`
WHERE continent IS NULL
  AND location NOT IN ("World", "International")
GROUP BY location
ORDER BY total_death_count DESC

--Results of query above showed "European Union" in location field. Updated query (below) to exclude, as EU is Europe.
SELECT
  location,
  MAX(total_deaths) AS total_death_count
FROM `covid_19_project.covid_deaths`
WHERE continent IS NULL
  AND location NOT IN ("World", "International", "European Union")
GROUP BY location
ORDER BY total_death_count DESC


-- Show all cases, deaths, and death rate in the world
SELECT
 -- date,
  SUM(new_cases) AS total_cases,
  SUM(new_deaths) AS total_deaths,
  ROUND(((SUM(new_deaths)/SUM(new_cases))*100),2) AS death_rate
FROM `covid_19_project.covid_deaths`
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2


-- JOIN TABLES --

-- Show rolling daily sum of new vaccinations per location
-- Note:  Accuracy validated by adding daily new_vaccinations and matching to rolling_total_vaccinations
SELECT 
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY vac.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinations
FROM `covid_19_project.covid_deaths` dea
  JOIN `covid_19_project.covid_vaccinations` vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Show vaccination rate over time by continent
-- USING CTE --
WITH pop_vs_vac
AS
(SELECT 
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY vac.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinations,
  SUM(dea.new_deaths) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_deaths
FROM `covid_19_project.covid_deaths` dea
  JOIN `covid_19_project.covid_vaccinations` vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL)
SELECT continent,
  date,
  ROUND((rolling_total_vaccinations/population)*100,2) AS vaccination_rate,
  ROUND((rolling_total_deaths/population)*100,5) AS death_rate
FROM pop_vs_vac
GROUP BY 1,2,3,4


-- CREATE VIEWS TO STORE DATA FOR FUTURE VISUALIZATION --
CREATE VIEW `covid_19_project.vaccination_rate` AS (
SELECT 
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY vac.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinations
FROM `covid_19_project.covid_deaths` dea
  JOIN `covid_19_project.covid_vaccinations` vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL)

---
CREATE VIEW `covid_19_project.vaccination_death_rates` AS (
SELECT 
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY vac.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinations,
  SUM(dea.new_deaths) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_deaths
FROM `covid_19_project.covid_deaths` dea
  JOIN `covid_19_project.covid_vaccinations` vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL)

-- Global numbers for table view
-- Data Type troubleshooting steps:
  -- total_deaths imported into Looker Studio as DATE, although showed as INT in BigQuery Schema
  -- Forced INT data type using CAST in query below
CREATE VIEW `covid_19_project.global_sums_int` AS (
SELECT
  CAST(SUM(CAST(new_cases AS INT64)) AS INT64) AS total_cases,
  CAST(SUM(CAST(new_deaths AS INT64)) AS INT64) AS total_deaths,
  ROUND(SUM(CAST(new_deaths AS FLOAT64)) / SUM(CAST(new_cases AS FLOAT64)) * 100, 5) 
    AS deaths_per_case_rate
FROM `covid_19_project.covid_deaths`
WHERE continent IS NOT NULL)

--
CREATE VIEW `covid_19_project.total_deaths_by_location` AS (
SELECT
  location,
  MAX(total_deaths) AS total_death_count
FROM `covid_19_project.covid_deaths`
WHERE continent IS NULL
  AND location NOT IN ("World", "International", "European Union")
GROUP BY location
ORDER BY total_death_count DESC)

--
CREATE VIEW `covid_19_project.infection_rate_by_country` AS (
SELECT
  location,
  population,
  MAX(total_cases) AS highest_infection_count,
  MAX(ROUND((total_cases/population)*100,2)) AS infection_rate
FROM `covid_19_project.covid_deaths`
GROUP BY location, population
ORDER BY infection_rate DESC)

--
CREATE VIEW `covid_19_project.infection_rate_over_time` AS (
SELECT
  date,
  location,
  population,
  MAX(total_cases) AS highest_infection_count,
  MAX(ROUND((total_cases/population)*100,2)) AS infection_rate
FROM `covid_19_project.covid_deaths`
GROUP BY location, population, date
ORDER BY infection_rate DESC)

-- FORECASTING INFECTION RATE WTIH ML MODEL --
-- 1. Create model using ARIMA_PLUS
Forecast with ARIMA_PLUS ML model
CREATE OR REPLACE MODEL `covid_19_project.infection_forecast_model`
  OPTIONS(MODEL_TYPE='ARIMA_PLUS',
  time_series_timestamp_col='date',
  time_series_data_col='infection_rate',
  time_series_id_col='location',  -- since you have multiple locations
  horizon=30,                     -- forecast 30 days into the future
  auto_arima=True
) AS
SELECT
  date,
  location,
  infection_rate
FROM `covid_19_project.infection_rate_over_time`
WHERE infection_rate IS NOT NULL
ORDER BY date

-- 2. Generate the forecast
SELECT
  *
FROM
  ML.FORECAST(MODEL `covid_19_project.infection_forecast_model`,
  STRUCT(30 AS horizon, 0.9 AS confidence_level));


-- 3. Join historical & forecast data using UNION
-- 4. Create VIEW for visualization in Looker Studio
CREATE VIEW `covid_19_project.historical_forecast_infection_rate` AS (
WITH historical AS (
  SELECT
    CAST(date AS DATE) AS forecast_timestamp,
    location,
    infection_rate AS actual_value,
    NULL AS forecast_value
  FROM `covid_19_project.infection_rate_over_time`
),
forecast AS (
  SELECT
    CAST(forecast_timestamp AS DATE) AS forecast_timestamp,
    location,
    NULL AS actual_value,
    forecast_value
  FROM
    ML.FORECAST(MODEL `covid_19_project.infection_forecast_model`,
    STRUCT(30 AS horizon, 0.9 AS confidence_level))
)
SELECT * FROM historical
UNION ALL
SELECT * FROM forecast
ORDER BY location, forecast_timestamp)

