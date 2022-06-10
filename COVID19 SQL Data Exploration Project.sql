Skills used: Joins, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

SELECT *
FROM PortfolioProject.dbo.CovidVaccinations$
WHERE continent is not null
ORDER BY 3,4 -- order by ordinal position of column in list i.e first column, second then third etc

-- Select the data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths

-- Shows likelihood of dying if you contract COVID in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths$
WHERE location LIKE '%kingdom%' and continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Population
SELECT Location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths$
WHERE location LIKE '%kingdom%' and continent is not null
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
--WHERE location LIKE '%kingdom%'
GROUP BY Location, population
ORDER BY PercentPopulationInfected DESC -- If you specify the GROUP BY clause, columns referenced must be all the columns in the SELECT clause that do not contain an aggregate function.

-- Looking at countries with highest death count per population
SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount -- potential issues with datatype, so we convert nvarchar to int
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
-- WHERE location LIKE '%kingdom%'
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Showing continents with the highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount -- potential issues with datatype, so we convert nvarchar to int
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
-- WHERE location LIKE '%kingdom%'
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths AS int)) as total_deaths,SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE location LIKE '%kingdom%' and 
WHERE continent is not null
group BY date
ORDER BY 1,2


SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths AS int)) as total_deaths,SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths$
--WHERE location LIKE '%kingdom%' and 
WHERE continent is not null
ORDER BY 1,2


-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations, 
SUM(cast (vac.new_vaccinations as bigint)) OVER (Partition by dea.Location ORDER BY dea.location,
dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ AS dea
JOIN PortfolioProject.dbo.CovidVaccinations$ AS vac
     ON dea.location = vac.location 
	 and dea.date = vac.date
WHERE dea.continent is not NULL
order by 2,3


--USE CTE

--With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
--as
--(
--SELECT dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations, 
--SUM(cast (vac.new_vaccinations as bigint)) OVER (Partition by dea.Location ORDER BY dea.location,
--dea.Date) as RollingPeopleVaccinated
--FROM PortfolioProject.dbo.CovidDeaths$ AS dea
--JOIN PortfolioProject.dbo.CovidVaccinations$ AS vac
--     ON dea.location = vac.location 
--	 and dea.date = vac.date
--WHERE dea.continent is not NULL
--order by 2,3
--)

--SELECT *, (RollingPeopleVaccinated/Population)*100
--FROM PopvsVac

-- TEMP TABLE

IF OBJECT_ID(PortfolioProject..PercentPopulationVaccinated) is not null
DROP TABLE IF EXISTS #PercentPopulationVaccinated -- useful if planning to make any alterations to the table below
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations, 
SUM(cast (vac.new_vaccinations as bigint)) OVER (Partition by dea.Location ORDER BY dea.location,
dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ AS dea
JOIN PortfolioProject.dbo.CovidVaccinations$ AS vac
     ON dea.location = vac.location 
	 and dea.date = vac.date
WHERE dea.continent is not NULL
--order by 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations


CREATE VIEW PercentPopulationVaccinated
as
SELECT dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations, 
SUM(cast (vac.new_vaccinations as bigint)) OVER (Partition by dea.Location ORDER BY dea.location,
dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ AS dea
JOIN PortfolioProject.dbo.CovidVaccinations$ AS vac
     ON dea.location = vac.location 
	 and dea.date = vac.date
WHERE dea.continent is not NULL

--order by 2,3

SELECT *
FROM PercentPopulationVaccinated
