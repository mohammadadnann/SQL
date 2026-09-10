-- WORLD LIFE EXPECTANCY -- 

Select *
from worldlifexpectancy

SELECT *
FROM
(SELECT Row_ID, 
CONCAT(Country, Year), 
ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS Row_num
FROM worldlifexpectancy) AS Row_table
WHERE Row_num > 1

-- REMOVING DUPLICATE -- 

DELETE FROM worldlifexpectancy
WHERE 
 Row_ID IN ( SELECT Row_ID
FROM
(SELECT Row_ID, 
CONCAT(Country, Year), 
ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS Row_num
FROM worldlifexpectancy) AS Row_table
WHERE Row_num > 1
)

-- Empty Spaces -- 

Select *
from worldlifexpectancy
Where STATUS = ''

Select *
from worldlifexpectancy
WHERE Lifeexpectancy = '79.1'

Select DISTINCT(STATUS)
from worldlifexpectancy
Where STATUS <> ''

Select DISTINCT(COUNTRY)
from worldlifexpectancy
Where STATUS = 'Developing'

-- populating empty data -- 

UPDATE worldlifexpectancy t1
JOIN worldlifexpectancy t2
ON t1.country = t2.country
SET t1.status = 'Developing'
WHERE t1.status = ''
AND t2.status <> ''
AND t2.status = 'Developing'
;

-- populating empty data -- 

Select *
from worldlifexpectancy
WHERE Lifeexpectancy = ''

Select t1.country, t1.YEAR, t1.`Lifeexpectancy`,
t2.country, t2.YEAR, t2.Lifeexpectancy,
t3.country, t3.YEAR, t3.Lifeexpectancy,
ROUND((t2.Lifeexpectancy + t3.Lifeexpectancy)/2,1)
from worldlifexpectancy t1
Join worldlifexpectancy t2
ON t1.country = t2.country
AND t1.YEAR = t2.YEAR - 1
Join worldlifexpectancy t3
ON t1.country = t3.country
AND t1.YEAR = t3.YEAR + 1
WHERE t1.Lifeexpectancy = ''


UPDATE worldlifexpectancy t1
Join worldlifexpectancy t2
ON t1.country = t2.country
AND t1.YEAR = t2.YEAR - 1
Join worldlifexpectancy t3
ON t1.country = t3.country
AND t1.YEAR = t3.YEAR + 1
SET t1.`Lifeexpectancy` = ROUND((t2.Lifeexpectancy + t3.Lifeexpectancy)/2,1)
WHERE t1.`Lifeexpectancy` = ''
;



SELECT *
FROM worldlifexpectancy
WHERE Year >= 2010


-- US PROJECT DATA CLEANING --

select *
from USHouseholdincome

select COUNT(id)
from ushouseholdincome_statistics

SELECT id, COUNT(id)
FROM USHouseholdincome
GROUP BY id
HAVING COUNT(id) > 1

DELETE FROM USHouseholdincome

DELETE FROM USHouseholdincome
WHERE row_id IN (
  SELECT row_id
  FROM (
  SELECT row_id,
  id,
  ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) row_num
  FROM USHouseholdincome) As DUPLICATES
  where row_num > 1)
  
SELECT state_name, COUNT(state_name)
FROM USHouseholdincome
GROUP BY state_name

  
SELECT  DISTINCT(State_Name)
from USHouseholdincome
Order by 1

update USHouseholdincome
SET state_name = 'Georgia'
WHERE state_name = 'georia'


SELECT *
FROM USHouseholdincome
WHERE type = 'borough'
AND types = 'boroughs'


UPDATE USHouseholdincome
SET PLACE = 'Autaugaville'
WHERE City = 'Vinemont'
AND County = 'Autauga County'


UPDATE USHouseholdincome
SET Type = 'Borough'
WHERE Type = 'Boroughs'


-- US PROJECT EXPLORATORY DATA ANALYSIS --
