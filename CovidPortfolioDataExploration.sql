/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
-- Cast the total_deaths and total_cases columns to float for mathematical operations

Select Location, date, total_cases,total_deaths, (cast(total_deaths as float)/cast(total_cases as float)*100) as DeathPercentage
From PortfolioProject..CovidDeaths
Where location = 'United States'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (cast(total_cases as float)/cast(population as float))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((cast(total_cases as float)/cast(population as float)))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(cast(new_cases as float)) as total_cases, SUM(cast(new_deaths as float)) as total_deaths, SUM(cast(new_deaths as float))/SUM(cast(new_Cases as float))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2


-- Looking at Total Population vs Vaccinations
-- Method 1: USE CTE to perform calculations on columns created within our SELECT query

WITH PopvsVac (Continent, Location, Date, Population, NewVaccinations, RollingPeopleVaccinated)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
AND vac.new_vaccinations is not null -- showing only dates with new_vaccination numbers
)

Select *, (RollingPeopleVaccinated/Population)*100 as RollingPercentVaccinated
From PopvsVac
Order by 2,3

-- Showing percentages over 100% of population , new_vaccinations sum may exceed population count due to booster and re-vaccination of individuals

-- Method 2: TEMP TABLE, does the same as CTE to allow for calculations on created columns from our SELECT query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(Continent nvarchar(255), 
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(new_vaccinations as float)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
AND vac.new_vaccinations is not null

Select *, (RollingPeopleVaccinated/Population)*100 as PercentPopulationVaccinated
From #PercentPopulationVaccinated
Order By 2,3


-- Create a view to be used in visualization later

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(new_vaccinations as float)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
AND vac.new_vaccinations is not null