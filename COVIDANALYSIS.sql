SELECT * FROM portfolioproject.dbo.DeathData

select * from portfolioproject..VaccinationData

-- slect data tht we are going to use
select location, date, total_cases, new_cases, total_deaths, population
from portfolioproject..DeathData
where continent is not null 

alter table dbo.deathdata alter column total_deaths decimal(18,2)

--total cases vs total deaths
--shows likelihood of dying if you contact covid in our country
select location, date, total_cases,total_deaths,
(total_deaths/total_cases)*100 as Deathpercentage
from portfolioproject..DeathData 
where location like '%India%'
and continent is not null
order by 1, 2

-- looking at total cases vs Population
select location, date, total_cases, population, (total_cases/population)*100
as comparison from portfolioproject..DeathData
--where location like '%India%'
where continent is not null
order by 1, 2

-- looking at countries with Highest Infection Rate compared to Population

select location, population, max(total_cases) as highestInfectionCount,
max(total_cases/population)*100 as percentpopulationInfected 
from portfolioproject..DeathData
where continent is not null
group by location, population
order by percentpopulationInfected desc

-- showing countries with highest death count per population
select location, max(total_deaths) as TotalDeathCount
from portfolioproject..DeathData
where continent is not null 
group by location
order by TotalDeathCount desc

-- LETS BREAK THINGS DOWN BY CONTINENT

select location, max(CAST (total_deaths AS INT)) as TotalDeathCount
from portfolioproject..DeathData
where continent is null 
group by location
order by TotalDeathCount desc

-- Showing continents with highest death count per population
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from portfolioproject..DeathData
where continent is not null
group by continent
order by TotalDeathCount Desc

-- Global Numbers

select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/nullif(sum(new_cases),0)*100 as DeathPercentage
from portfolioproject..DeathData
where continent is not null
--group by date
order by 1, 2

--looking at Total Population Vs Vaccinations

select d.continent, d.location, d.date, d.population, v.new_vaccinations
from portfolioproject..DeathData d
join portfolioproject..VaccinationData v
on d.location=v.location and
d.date=v.date
where d.continent is not null
order by 2,3

--rolling sum
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
sum(convert(bigint, v.new_vaccinations)) over (partition by d.location order by 
d.location, d.date)
as RollingVaccinations
from portfolioproject..DeathData d
join portfolioproject..VaccinationData v
on d.location=v.location and
d.date=v.date
where d.continent is not null
order by 2,3

--Using CTE
with popvsvac (continent, location, date, population, new_vaccinations, RollingVaccinations)
as 
( 
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(COALESCE(CONVERT(bigint, v.new_vaccinations), 0))  over (partition by d.location order by 
d.location, d.date) as RollingVaccinations from portfolioproject..DeathData d
join portfolioproject..VaccinationData v on d.location=v.location and d.date=v.date
where d.continent is not null
)
select * from popvsvac

select *, (RollingVaccinations/population)*100 as rollingPerc from popvsvac

-- Create Temp Table
drop table if exists #percentpopVaccinated
create table #percentpopVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccinations numeric 
)

insert into #percentpopVaccinated
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
sum(convert(int, v.new_vaccinations)) over (partition by d.location order by 
d.location, d.date) as RollingVaccinations from portfolioproject..DeathData d
join portfolioproject..VaccinationData v on d.location=v.location and d.date=v.date
where d.continent is not null 

select *, (RollingVaccinations/population)*100 as rollingPerc 
from #percentpopVaccinated

--creating view to store data for visualisation

create view percentpopvaccinated as
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
sum(convert(bigint, v.new_vaccinations)) over (partition by d.location order by 
d.location, d.date) as RollingVaccinations from portfolioproject..DeathData d
join portfolioproject..VaccinationData v on d.location=v.location and d.date=v.date
where d.continent is not null 
