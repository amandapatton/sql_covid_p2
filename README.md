# sql_covid_p2
Demonstration of Intermediate &amp; Advanced SQL and Visualization Skills

View project visualizations in [Looker Studio](https://lookerstudio.google.com/reporting/79c09048-6a92-4eed-89ff-073b44d958ac).

# COVID-19 Data Analysis & Forecasting (Project #2)

This project demonstrates my SQL and data visualization skills using BigQuery and Looker Studio. The goal was to explore a large COVID-19 dataset, calculate key metrics like infection and death rates, and forecast trends using a machine learning model.

## Project Overview

**Objectives**  
- Explore and validate COVID-19 case and vaccination data.  
- Calculate infection rates, death rates, and rolling vaccination totals by location and continent.  
- Build views in BigQuery for streamlined visualization in Looker Studio.  
- Forecast infection rates using an ARIMA_PLUS ML model for short-term predictions.  

**Technologies Used**  
- SQL (BigQuery)  
- BigQuery ML for time series forecasting  
- Looker Studio for dashboards and visualizations  

## Data Exploration & Analysis

- Validated data structures and checked for anomalies in case and vaccination tables.  
- Calculated key metrics, including:  
  - Death rate per location (`total_deaths / total_cases`)  
  - Infection rate per location (`total_cases / population`)  
  - Rolling totals for vaccinations and deaths  
- Identified locations with the highest infection and death rates.  
- Aggregated totals by continent and globally for comparison.  

## Data Modeling & Views

Created reusable BigQuery views to simplify analysis and visualization:  
- **`vaccination_rate`**: Rolling vaccination totals by location.  
- **`vaccination_death_rates`**: Rolling vaccination and death counts.  
- **`global_sums_int`**: Total cases, deaths, and death rate globally (cast to INT for Looker Studio).  
- **`total_deaths_by_location`**: Maximum deaths per location, excluding duplicates.  
- **`infection_rate_by_country`**: Infection rates per country.  
- **`infection_rate_over_time`**: Infection rate trends over time.  
- **`historical_forecast_infection_rate`**: Combines historical infection rates with 30-day forecast for visualization.  

## Forecasting

- Built an ARIMA_PLUS model to forecast infection rates for the next 30 days.  
- Forecast results were combined with historical data to create a unified view for visualization.  
- This allows easy integration into Looker Studio dashboards to track trends and projections.  

## Key Learnings

- Learned to handle data type inconsistencies and casting issues for Looker Studio compatibility.  
- Practiced advanced SQL techniques: window functions, CTEs, joins, and BigQuery ML.  
- Gained experience creating modular views to support scalable analytics and dashboarding.  

## Next Steps

- Expand forecasts to include vaccination impact on infection trends.  
- Explore additional time series models for improved accuracy.  
- Continue building portfolio projects demonstrating SQL and visualization proficiency.

## Quick Links & Sample Queries

**Sample Queries**  
- **Infection Rate by Country**  
```
SELECT
  location,
  population,
  MAX(total_cases) AS highest_infection_count,
  MAX(ROUND((total_cases/population)*100,2)) AS infection_rate
FROM `covid_19_project.covid_deaths`
GROUP BY location, population
ORDER BY infection_rate DESC
```

- **Death Rate Over Time (US Example)**
```
SELECT
  location,
  date,
  total_cases,
  total_deaths,
  ROUND((total_deaths/total_cases)*100,2) AS death_rate
FROM `covid_19_project.covid_deaths`
WHERE location = 'United States'
ORDER BY date
```

- **30-Day Infection Rate Forecast**
```
SELECT *
FROM ML.FORECAST(MODEL `covid_19_project.infection_forecast_model`,
  STRUCT(30 AS horizon, 0.9 AS confidence_level))
```
