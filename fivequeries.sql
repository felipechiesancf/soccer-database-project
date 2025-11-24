
-- Top 20 Most Improved Players (2010 vs 2015)
WITH rating_2010 AS (
    
    SELECT player_api_id, MAX(overall_rating) as rating
    FROM player_attributes
    WHERE EXTRACT(YEAR FROM date) = 2010
    GROUP BY player_api_id
),
rating_2015 AS (
    
    SELECT player_api_id, MAX(overall_rating) as rating
    FROM player_attributes
    WHERE EXTRACT(YEAR FROM date) = 2015
    GROUP BY player_api_id
)
SELECT 
    p.player_name,
    r10.rating AS rating_2010,
    r15.rating AS rating_2015,
    (r15.rating - r10.rating) AS evolucao
FROM player p
JOIN rating_2010 r10 ON p.player_api_id = r10.player_api_id
JOIN rating_2015 r15 ON p.player_api_id = r15.player_api_id
WHERE r15.rating > r10.rating
ORDER BY evolucao DESC
LIMIT 20;



--Current Top Playmakers by Passing Ability

WITH RankedAttributes AS (
    SELECT
        pa.player_api_id,
        pa.passing,
        pa.date,
        ROW_NUMBER() OVER (PARTITION BY pa.player_api_id ORDER BY pa.date DESC) as rn
    FROM
        soccer.player_attributes pa
)
SELECT
    p.player_name,
    ra.passing,
    ra.date
FROM
    RankedAttributes ra
JOIN
    soccer.player p ON ra.player_api_id = p.player_api_id
WHERE
    ra.rn = 1
ORDER BY
    ra.passing DESC NULLS LAST
LIMIT 20;


--Elite Dual-Threat Attackers (Above Average Finishing & Long Shots)
SELECT 
    p.player_name,
    pa.finishing,
    pa.long_shots,
    pa.dribbling
FROM soccer.player p
JOIN soccer.player_attributes pa ON p.player_api_id = pa.player_api_id
WHERE pa.date = (SELECT MAX(date) FROM soccer.player_attributes WHERE player_api_id = pa.player_api_id) 
AND pa.finishing > (
    SELECT AVG(finishing) FROM soccer.player_attributes 
)
AND pa.long_shots > (
    SELECT AVG(long_shots) FROM soccer.player_attributes 
)
ORDER BY (pa.finishing + pa.long_shots) DESC
LIMIT 20;


--Physical & Technical Comparison by Preferred Foot (Left vs. Right)
SELECT 
    preferred_foot,
    COUNT(*) as player_count,
    ROUND(AVG(sprint_speed), 2) as avg_speed,
    ROUND(AVG(dribbling), 2) as avg_dribbling
FROM soccer.player_attributes
WHERE preferred_foot IS NOT NULL
GROUP BY preferred_foot
HAVING COUNT(*) > 100 
ORDER BY avg_dribbling DESC;


--Player Performance Lifecycle: Rating vs. Age Analysis
SELECT 
    CAST(EXTRACT(YEAR FROM age(pa.date, p.birthday)) AS INTEGER) AS player_age,
    COUNT(*) AS records_count,
    ROUND(AVG(pa.overall_rating), 2) AS avg_rating,
    ROUND(AVG(pa.potential), 2) AS avg_potential
FROM soccer.player p
JOIN soccer.player_attributes pa ON p.player_api_id = pa.player_api_id
WHERE p.birthday IS NOT NULL 
  AND pa.date IS NOT NULL
GROUP BY player_age
HAVING COUNT(*) >= 10 -- Filtro reduzido para garantir que apareçam dados
ORDER BY player_age;