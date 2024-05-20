-- create view to join 3 tables
CREATE VIEW forestation
AS SELECT   forest_area.country_code country_code,
            forest_area.country_name country_name,
            forest_area.year years,
            forest_area.forest_area_sqkm forest_area_sqkm,
            land_area.total_area_sq_mi * 2.59 AS land_area_sqkm,
            regions.region region, regions.income_group income_group,
            forest_area.forest_area_sqkm/(land_area.total_area_sq_mi * 2.59)*100 AS percent_forest
FROM forest_area
JOIN land_area
ON forest_area.country_code = land_area.country_code AND forest_area.year = land_area.year
JOIN regions
ON forest_area.country_code = regions.country_code

-- find the forest area all over the world in 1990
SELECT forest_area_sqkm FROM forestation 
WHERE years = 1990 AND country_name = 'World'

-- find the forest area all over the world in 2016
SELECT forest_area_sqkm FROM forestation 
WHERE years = 2016 AND country_name = 'World'

-- using self join
SELECT 
    f1990.years AS year_1990,
    f1990.country_name AS country_name_1990,
    f1990.forest_area_sqkm AS forest_area_1990,
    f2016.years AS year_2016,
    f2016.country_name AS country_name_2016,
    f2016.forest_area_sqkm AS forest_area_2016
FROM forestation f1990
JOIN forestation f2016 ON f1990.country_code = f2016.country_code
WHERE f1990.years = 1990 AND f2016.years = 2016 AND f1990.country_name = 'World'

-- find the loss of forest area all over the world in sqkm and percent from 1990 to 2016
SELECT 
    (SELECT forest_area_sqkm FROM forestation WHERE years = 1990 AND country_name = 'World') - 
    (SELECT forest_area_sqkm FROM forestation WHERE years = 2016 AND country_name = 'World') AS loss_sqkm,
    ((SELECT forest_area_sqkm FROM forestation WHERE years = 1990 AND country_name = 'World') - 
    (SELECT forest_area_sqkm FROM forestation WHERE years = 2016 AND country_name = 'World')) / 
    (SELECT forest_area_sqkm FROM forestation WHERE years = 1990 AND country_name = 'World') * 100 AS loss_percent;

-- find the country which has the forest area nearest to the loss of forest area all over the world from 1990 to 2016
SELECT country_name , 2.59 * total_area_sq_mi as land_area_sqkm FROM land_area
WHERE (2.59 * total_area_sq_mi) <     (SELECT forest_area_sqkm FROM forestation WHERE years = 1990 AND country_name = 'World') - 
    (SELECT forest_area_sqkm FROM forestation WHERE years = 2016 AND country_name = 'World') AND year = 2016
ORDER BY total_area_sq_mi DESC
LIMIT 1

-- Regional Outlook
--find the forest percent by region in 2016
WITH
    forest_area_sqkm_2016 AS (
        SELECT f.region, ROUND(CAST(SUM(f.forest_area_sqkm) AS numeric), 2) AS forest_area_2016 
        FROM forestation f 
        WHERE f.years = 2016 
        GROUP BY f.region
    ),
    land_area_sqkm_2016 AS (
        SELECT f.region, ROUND(CAST(SUM(f.land_area_sqkm) AS numeric), 2) AS land_area_2016 
        FROM forestation f 
        WHERE f.years = 2016 
        GROUP BY f.region 
    ),
    forest_area_percent_2016 AS (
        SELECT l.region, ROUND(CAST(f.forest_area_2016 / l.land_area_2016 * 100 AS numeric), 2) AS forest_area_percent
        FROM land_area_sqkm_2016 l, forest_area_sqkm_2016 f 
        WHERE l.region = f.region
    )
SELECT forest_area_percent_2016.region, forest_area_percent
FROM forest_area_percent_2016
ORDER BY forest_area_percent DESC;

--find the forest area percent decrease in 1990-2016
WITH
    forest_area_sqkm_1990 AS (
        SELECT f.region, ROUND(CAST(SUM(f.forest_area_sqkm) AS numeric), 2) AS forest_area_1990 
        FROM forestation f 
        WHERE f.years = 1990 
        GROUP BY f.region
    ),
    land_area_sqkm_1990 AS (
        SELECT f.region, ROUND(CAST(SUM(f.land_area_sqkm) AS numeric), 2) AS land_area_1990 
        FROM forestation f 
        WHERE f.years = 1990 
        GROUP BY f.region 
    ),
    forest_area_percent_1990 AS (
        SELECT l.region, ROUND(CAST(f.forest_area_1990 / l.land_area_1990 * 100 AS numeric), 2) AS forest_area_percent_1990
        FROM land_area_sqkm_1990 l, forest_area_sqkm_1990 f 
        WHERE l.region = f.region
    ),
    forest_area_sqkm_2016 AS (
        SELECT f.region, ROUND(CAST(SUM(f.forest_area_sqkm) AS numeric), 2) AS forest_area_2016 
        FROM forestation f 
        WHERE f.years = 2016 
        GROUP BY f.region
    ),
    land_area_sqkm_2016 AS (
        SELECT f.region, ROUND(CAST(SUM(f.land_area_sqkm) AS numeric), 2) AS land_area_2016 
        FROM forestation f 
        WHERE f.years = 2016 
        GROUP BY f.region 
    ),
    forest_area_percent_2016 AS (
        SELECT l.region, ROUND(CAST(f.forest_area_2016 / l.land_area_2016 * 100 AS numeric), 2) AS forest_area_percent_2016
        FROM land_area_sqkm_2016 l, forest_area_sqkm_2016 f 
        WHERE l.region = f.region
    )
SELECT forest_area_percent_1990.region, (forest_area_percent_1990.forest_area_percent_1990 - forest_area_percent_2016.forest_area_percent_2016), CASE WHEN (forest_area_percent_1990.forest_area_percent_1990 - forest_area_percent_2016.forest_area_percent_2016) > 0 THEN 'Decrease' ELSE 'Increase' END AS change_type
FROM forest_area_percent_1990, forest_area_percent_2016
WHERE forest_area_percent_1990.region = forest_area_percent_2016.region
ORDER BY forest_area_percent_1990.forest_area_percent_1990 DESC;

-- COUNTRY-LEVEL DETAIL
-- A.	SUCCESS STORIES
--  find the forest area Increase in percent of each country
WITH
    forest_area_sqkm_1990 AS (
        SELECT f.country_code, f.country_name, ROUND(CAST(SUM(f.forest_area_sqkm) AS numeric), 2) AS forest_area_1990 
        FROM forestation f 
        WHERE f.years = 1990 
        GROUP BY f.country_code, f.country_name
    ),
    forest_area_sqkm_2016 AS (
        SELECT f.country_code, f.country_name, ROUND(CAST(SUM(f.forest_area_sqkm) AS numeric), 2) AS forest_area_2016 
        FROM forestation f 
        WHERE f.years = 2016 
        GROUP BY f.country_code, f.country_name
    )
SELECT forest_area_sqkm_1990.country_code, forest_area_sqkm_1990.country_name, (forest_area_sqkm_1990.forest_area_1990 -  forest_area_sqkm_2016.forest_area_2016)/forest_area_sqkm_1990.forest_area_1990 AS increase_rate
FROM forest_area_sqkm_1990, forest_area_sqkm_2016
WHERE forest_area_sqkm_1990.country_code = forest_area_sqkm_2016.country_code AND (forest_area_sqkm_1990.forest_area_1990 -  forest_area_sqkm_2016.forest_area_2016) IS NOT NULL
ORDER BY increase_rate DESC;

-- B.	LARGEST CONCERNS

-- find the loss in forest area of each country 1990-2016 in sqkm
WITH
    forest_area_sqkm_1990 AS (
        SELECT f.region, f.country_name, ROUND(CAST(SUM(f.forest_area_sqkm) AS numeric), 2) AS forest_area_1990 
        FROM forestation f 
        WHERE f.years = 1990 
        GROUP BY f.country_name, f.region
    ),
    forest_area_sqkm_2016 AS (
        SELECT f.region, f.country_name, ROUND(CAST(SUM(f.forest_area_sqkm) AS numeric), 2) AS forest_area_2016 
        FROM forestation f 
        WHERE f.years = 2016 
        GROUP BY f.country_name, f.region
    )
SELECT forest_area_sqkm_1990.region, forest_area_sqkm_1990.country_name, (forest_area_sqkm_1990.forest_area_1990 -  forest_area_sqkm_2016.forest_area_2016)AS loss
FROM forest_area_sqkm_1990, forest_area_sqkm_2016
WHERE forest_area_sqkm_1990.country_name = forest_area_sqkm_2016.country_name AND (forest_area_sqkm_1990.forest_area_1990 -  forest_area_sqkm_2016.forest_area_2016) IS NOT NULL
ORDER BY (forest_area_sqkm_1990.forest_area_1990 -  forest_area_sqkm_2016.forest_area_2016) DESC;

-- find the loss in forest area of each country 1990-2016 in percent
WITH
    forest_area_sqkm_1990 AS (
        SELECT f.region, f.country_name, ROUND(CAST(SUM(f.forest_area_sqkm) AS numeric), 2) AS forest_area_1990 
        FROM forestation f 
        WHERE f.years = 1990 
        GROUP BY f.region, f.country_name
    ),
    forest_area_sqkm_2016 AS (
        SELECT f.region, f.country_name, ROUND(CAST(SUM(f.forest_area_sqkm) AS numeric), 2) AS forest_area_2016 
        FROM forestation f 
        WHERE f.years = 2016 
        GROUP BY f.region, f.country_name
    )
SELECT forest_area_sqkm_1990.region, forest_area_sqkm_1990.country_name, (forest_area_sqkm_1990.forest_area_1990 -  forest_area_sqkm_2016.forest_area_2016) / forest_area_sqkm_1990.forest_area_1990 AS loss_percent
FROM forest_area_sqkm_1990, forest_area_sqkm_2016
WHERE forest_area_sqkm_1990.country_name = forest_area_sqkm_2016.country_name AND (forest_area_sqkm_1990.forest_area_1990 -  forest_area_sqkm_2016.forest_area_2016) IS NOT NULL
ORDER BY loss_percent DESC;

-- divide country in quartile based on percent forest area 
WITH
    forest_area_sqkm_2016 AS (
        SELECT f.country_code, f.country_name, f.region, ROUND(CAST(SUM(f.forest_area_sqkm) AS numeric), 2) AS forest_area_2016 
        FROM forestation f 
        WHERE f.years = 2016 
        GROUP BY f.country_code, f.country_name, f.region
    ),
    land_area_sqkm_2016 AS (
        SELECT f.country_code, f.country_name, f.region, ROUND(CAST(SUM(f.land_area_sqkm) AS numeric), 2) AS land_area_2016 
        FROM forestation f 
        WHERE f.years = 2016 
        GROUP BY f.country_code, f.country_name, f.region
    ),
    forest_area_percent_2016 AS (
        SELECT l.country_code, f.country_name, f.region, ROUND(CAST(f.forest_area_2016 / l.land_area_2016 * 100 AS numeric), 2) AS forest_area_percent_2016
        FROM land_area_sqkm_2016 l, forest_area_sqkm_2016 f 
        WHERE l.country_code = f.country_code
    )
SELECT 
    CASE 
        WHEN forest_area_percent_2016 < 25 THEN 4
        WHEN forest_area_percent_2016 >= 25 AND forest_area_percent_2016 < 50 THEN 3
        WHEN forest_area_percent_2016 >= 50 AND forest_area_percent_2016 < 75 THEN 2
        WHEN forest_area_percent_2016 >= 75 THEN 1
    END AS quartile,
    COUNT(*) AS country_count
FROM forest_area_percent_2016
GROUP BY quartile;

-- find the top forest area percent country
WITH
    forest_area_sqkm_2016 AS (
        SELECT f.country_code, f.country_name, f.region, ROUND(CAST(SUM(f.forest_area_sqkm) AS numeric), 2) AS forest_area_2016 
        FROM forestation f 
        WHERE f.years = 2016 
        GROUP BY f.country_code, f.country_name, f.region
    ),
    land_area_sqkm_2016 AS (
        SELECT f.country_code, f.country_name, f.region, ROUND(CAST(SUM(f.land_area_sqkm) AS numeric), 2) AS land_area_2016 
        FROM forestation f 
        WHERE f.years = 2016 
        GROUP BY f.country_code, f.country_name, f.region
    ),
    forest_area_percent_2016 AS (
        SELECT l.country_code, f.country_name, f.region, ROUND(CAST(f.forest_area_2016 / l.land_area_2016 * 100 AS numeric), 2) AS forest_area_percent_2016
        FROM land_area_sqkm_2016 l, forest_area_sqkm_2016 f 
        WHERE l.country_code = f.country_code
    ),
    first_quartile AS (
        SELECT 
            forest_area_percent_2016.country_name, 
            forest_area_percent_2016.region, 
            forest_area_percent_2016.forest_area_percent_2016
        FROM forest_area_percent_2016
        WHERE forest_area_percent_2016.forest_area_percent_2016 >= 75
    )
SELECT 
    1 AS quartile,
    first_quartile.country_name, 
    first_quartile.region, 
    first_quartile.forest_area_percent_2016
FROM first_quartile
ORDER BY first_quartile.forest_area_percent_2016 DESC;