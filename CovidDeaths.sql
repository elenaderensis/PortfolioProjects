select *
from PortfolioProject..['CovidDeaths']
where continent is not null
order by 3,4

--select *
--from PortfolioProject..['CovidVaccinations']
--order by 3,4

--select data that we are going to be using

--looking at Total Cases vs Total Deaths
--shows likelihood of dying if you contract covid in your country
select country, date, total_cases, total_deaths, (total_deaths/NULLIF(total_cases, 0)) * 100 as DeathPercentage
from PortfolioProject..['CovidDeaths']
where country like '%italy%'
and continent is not null
order by 1,2


--looking at Total Cases vs Population
--shows what % of population got covid

select country, date, population, total_cases, (total_cases/population) * 100 as PercentPopInfected
from PortfolioProject..['CovidDeaths']
--where country like '%italy%'
where continent is not null
order by 1,2

--looking at countries with highest infection rate compared to population

select country, population, max(total_cases) as HighestInfectionCount, 
max((total_cases/population)) * 100 as PercentPopInfected
from PortfolioProject..['CovidDeaths']
--where country like '%italy%'
where continent is not null
group by country, population
order by PercentPopInfected desc


--showing Countries with highest Death Count per Population

select country, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..['CovidDeaths']
--where country like '%italy%'
where continent is not null
group by country, population
order by TotalDeathCount desc

--LET'S BREAK THINGS DOWN BY CONTINET

--showing Continents with highest Death Count per Population

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..['CovidDeaths']
--where country like '%italy%'
where continent is not null
group by continent
order by TotalDeathCount desc


--GLOBAL NUMBERS

select sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, sum(new_deaths)/sum(nullif(new_cases,0)) *100 as DeathPercentage
from PortfolioProject..['CovidDeaths']
--where country like '%italy%'
WHERE continent is not null
--group by date
order by 1,2


--looking at Total Population vs Vaccinations

select dea.continent, dea.country, dea.date, dea.population, vax.new_vaccinations
, sum(convert(float, vax.new_vaccinations)) over(partition by dea.country order by dea.country, dea.date) as RollingVax
--, (RollingVax/population)*100
from PortfolioProject..['CovidDeaths'] dea
join PortfolioProject..['CovidVaccinations'] vax
on dea.country = vax.country
and dea.date = vax.date
where dea.continent is not null
order by 2,3


--USE CTE to be able to use the new column RollingVax

with PopvsVax (continent, country, date, population, new_vaccinations, rollingvax)
as
(
select dea.continent, dea.country, dea.date, dea.population, vax.new_vaccinations
, sum(convert(float, vax.new_vaccinations)) over(partition by dea.country order by dea.country, dea.date) as RollingVax
--, (RollingVax/population)*100
from PortfolioProject..['CovidDeaths'] dea
join PortfolioProject..['CovidVaccinations'] vax
on dea.country = vax.country
and dea.date = vax.date
where dea.continent is not null
--order by 2,3
)
select*, (rollingvax/population)*100
from PopvsVax


--TEMP TABLE

DROP TABLE if exists #percentpopvax --If the temporary table #PercentPopVax already exists, delete it before creating it again
create table #PercentPopVax
(
continent nvarchar(255),
country nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVax numeric
)

insert into #PercentPopVax
select dea.continent, dea.country, dea.date, dea.population, try_cast(vax.new_vaccinations as float) as new_vaccinations
, sum(try_cast(vax.new_vaccinations as float)) over(partition by dea.country order by dea.country, dea.date) as RollingVax
--, (RollingVax/population)*100
from PortfolioProject..['CovidDeaths'] dea
join PortfolioProject..['CovidVaccinations'] vax
on dea.country = vax.country
and dea.date = vax.date
--where dea.continent is not null
--order by 2,3

select*, (RollingVax/population)*100
from #PercentPopVax


--creating View to store data for later visualizations

create view PercentPopVax as
select dea.continent, dea.country, dea.date, dea.population, try_cast(vax.new_vaccinations as float) as new_vaccinations
, sum(try_cast(vax.new_vaccinations as float)) over(partition by dea.country order by dea.country, dea.date) as RollingVax
--, (RollingVax/population)*100
from PortfolioProject..['CovidDeaths'] dea
join PortfolioProject..['CovidVaccinations'] vax
on dea.country = vax.country
and dea.date = vax.date
where dea.continent is not null
--order by 2,3

select *
from PercentPopVax