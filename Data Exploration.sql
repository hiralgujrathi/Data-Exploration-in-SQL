select * from ['Covid_deaths']
--select location,date,total_cases,new_cases,total_deaths,population from ['Covid_deaths'] order by 1,2
exec sp_help ['Covid_deaths']
alter table ['Covid_deaths'] alter column total_cases FLOAT;
alter table ['Covid_deaths'] alter column total_deaths FLOAT;
--Looking at toal cases vs total deaths(% of people)
select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as Death_percentage,population from ['Covid_deaths']
where location='India' order by 4 desc

--Looking at total cases vs population
select location,date,total_cases,population,(total_cases/population)*100 percent_population from ['Covid_deaths'] order by 1,5 desc

--highest infection rate country (to find the highest infection rate, we will have to consider the maximum total cases for that country) its not about which country got maximum cases or has the highest population its about the highest infection rate means in which country majority people were affect FROM AMONG THE POPULATION so we take the day with maximum number of cases and divide by population which shows how much majority got affected
select location,population,max(total_cases) as highestcount,max((total_cases/population))*100 as highest_rate_of_infection from ['Covid_deaths'] group by location,population order by highest_rate_of_infection desc
select location,population,total_cases from ['Covid_deaths'] where location='Cyprus'
select location,population,max(total_cases) as highestcount from ['Covid_deaths'] where continent is not null group by location,population order by highestcount desc

--countries with highest death count per population
select location,population,max(total_deaths) as TotalDeaths from ['Covid_deaths'] group by location,population order by TotalDeaths desc 
--we see that in this query we have our locations as world,south america,north america which shouldnt be there but its happening as its gouping the whole continent because if we see the table there are some continents which are placed in the location column like World,north america so we select the fields where continents are not null becuase where they are null they are being placed in the location
select * from ['Covid_deaths'] where continent is not null
select location,population,max(total_deaths) as TotalDeaths from ['Covid_deaths'] where continent is not null group by location,population order by TotalDeaths desc
select location,population,max(total_deaths) as TotalDeaths,max((total_deaths/population))*100 as death_rate_by_population from ['Covid_deaths'] where continent is not null group by location,population order by death_rate_by_population desc

--by continent
select continent,max(total_deaths) as TotalDeaths from ['Covid_deaths'] where continent is not null group by continent order by TotalDeaths desc  --the problem with this query is that,if we check the data which we are getting back is not accurate , for eg north america is taking from only US and not Canada
--we have a different way 
select location,max(total_deaths) as TotalDeaths from ['Covid_deaths'] where continent is null group by location order by TotalDeaths desc


--GLOBAL NUMBERS
select date,total_deaths,total_cases ,(total_deaths/total_cases)*100 as Death_percentage from ['Covid_deaths'] where continent is not null 
select date,sum(new_cases) as new_cases from ['Covid_deaths'] group by date
select date,sum(new_cases) as new_cases,sum(new_deaths) as new_deaths from ['Covid_deaths'] group by date order by date
select date,sum(new_cases) as new_cases, sum(new_deaths) as new_deaths, sum(new_deaths)/sum(new_cases)*100 as death_percentage from ['Covid_deaths'] where continent is not null group by date order by new_cases,new_deaths
select date,sum(new_deaths) as new_deaths,sum(new_cases) as new_cases, sum(nullif(new_deaths,0))/sum(nullif(new_cases,0))*100 as death_percentage from ['Covid_deaths'] where continent is not null group by date order by new_cases,new_deaths
select sum(new_deaths) as new_deaths,sum(new_cases) as new_cases, sum(nullif(new_deaths,0))/sum(nullif(new_cases,0))*100 as death_percentage from ['Covid_deaths'] where continent is not null order by new_cases,new_deaths



select * from ['Covid_Vaccinations']
select top 50 * from ['Covid_Vaccinations']
select * from ['Covid_Vaccinations'] order by location offset 10 rows fetch next 5 rows only; --order by is compulsary
select * from ['Covid_deaths'] dea join ['Covid_Vaccinations'] vac on dea.location=vac.location and dea.date=vac.date

select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations from ['Covid_deaths'] dea join ['Covid_Vaccinations'] vac on dea.location=vac.location and dea.date=vac.date where dea.continent is not null order by 1,2,3
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,sum(cast(vac.new_vaccinations as bigint)) over(partition by dea.location order by dea.date)
from ['Covid_deaths'] dea join ['Covid_Vaccinations'] vac on dea.location=vac.location and dea.date=vac.date 
where dea.continent is not null order by 2,3
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,sum(cast(vac.new_vaccinations as bigint)) over(partition by dea.location order by dea.date) as PeopleVaccinated --we cannot use a column name just created (PeopleVaccinated)
from ['Covid_deaths'] dea join ['Covid_Vaccinations'] vac on dea.location=vac.location and dea.date=vac.date 
where dea.continent is not null order by 2,3 --it started from null for every location change
--know the difference (group by vs partition by)
select dea.location,dea.date,dea.population,vac.new_vaccinations,sum(cast(vac.new_vaccinations as bigint))
from ['Covid_deaths'] dea join ['Covid_Vaccinations'] vac on dea.location=vac.location and dea.date=vac.date 
where dea.continent is not null group by dea.location,dea.date,dea.population,vac.new_vaccinations order by 1
-- we want to know the total people vaccinated in that country and that number we get in the bottom of every country so if we just do peoplevaccinated/population but we get an error as its a window function
--since that is a window function so it cannot be used with other window or aggregate function and we need to perform division it cannot directly happen on a window function so we need to use CTE for that
--CTE
With PopVac(Continent,Date,Location,population,New_Vaccinations,TotalPeopleVaccinated) 
as 
(select dea.continent,dea.date,dea.location,dea.population,vac.new_vaccinations,sum(cast(vac.new_vaccinations as bigint)) 
over(partition by dea.location order by dea.date) as PeopleVaccinated
from ['Covid_deaths'] dea join ['Covid_Vaccinations'] vac on dea.location=vac.location and dea.date=vac.date 
where dea.continent is not null)
--order by 2,3
--select * from PopVac
--now we can use it for further calculation
--sum(total) of people vaccinated,country wise
select * ,(TotalPeopleVaccinated/population)*100 from PopVac



--Temp table
DROP TABLE IF EXISTS #PercentPeopleVaccinated
CREATE TABLE #PercentPeopleVaccinated
(Continent nvarchar(255),Location nvarchar(255),Date datetime,Population numeric,New_Vaccinations numeric,PeopleVaccinated numeric)
INSERT INTO #PercentPeopleVaccinated
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,sum(cast(vac.new_vaccinations as bigint)) over(partition by dea.location order by dea.date) as PeopleVaccinated --we cannot use a column name just created (PeopleVaccinated)
from ['Covid_deaths'] dea join ['Covid_Vaccinations'] vac on dea.location=vac.location and dea.date=vac.date 
where dea.continent is not null 
select *,(PeopleVaccinated/Population)*100 FROM #PercentPeopleVaccinated

--CREATING A VIEW
CREATE VIEW PeopleVaccinated as 
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,sum(cast(vac.new_vaccinations as bigint)) over(partition by dea.location order by dea.date) as PeopleVaccinated --we cannot use a column name just created (PeopleVaccinated)
from ['Covid_deaths'] dea join ['Covid_Vaccinations'] vac on dea.location=vac.location and dea.date=vac.date 
where dea.continent is not null 

SELECT * FROM PeopleVaccinated

SELECT SUM(total_cases) as total_cases,SUM(total_deaths) as total_deaths,SUM(total_cases)/SUM(total_deaths)*100 as DeathPercentage from ['Covid_deaths'] 
where continent is not null
order by 1,2
Select SUM(total_cases) as total_cases, SUM(total_deaths) as total_deaths, SUM(total_deaths)/SUM(total_Cases)*100 as DeathPercentage
From ['Covid_deaths']
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

SELECT location,SUM(total_deaths) as TotalDeaths from ['Covid_deaths'] where continent is null and location in ('Europe','North America','South America','Asia','Africa','Oceania') group by location
SELECT location,population,max(total_cases) as HighestIfectionCount,MAX((total_cases/population))*100 as PercentInfected from ['Covid_deaths'] group by location,population order by 1
SELECT location,population,date,total_cases as HighestIfectionCount,(total_cases/population)*100 as PercentInfected from ['Covid_deaths'] order by PercentInfected desc
SELECT location,population,date,max(total_cases) as HighestIfectionCount,max((total_cases/population))*100 as PercentInfected from ['Covid_deaths'] group by location,population,date order by PercentInfected desc
Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From ['Covid_deaths']
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc