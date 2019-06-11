SELECT NS."Year", NS."Month", NS."Day", NS."Extent" as "ExtentNorth", SS."Extent" as "ExtentSouth", GT."LandAverageTemperature", GT."LandMaxTemperature"
FROM CLIMATE.NORTHSEAICE NS
JOIN CLIMATE.SOUTHSEAICE SS ON NS."Year"=SS."Year"
    AND NS."Month"=SS."Month"
    AND NS."Day"=SS."Day"
LEFT JOIN (SELECT SUBSTRING(GT."dt", 1, 4) AS "Year", SUBSTRING(GT."dt", 6, 2) AS "Month", SUBSTRING(GT."dt", 9, 2) AS "Day", "LandAverageTemperature", "LandMaxTemperature" FROM CLIMATE.GLOBALTEMPERATURES GT) GT ON NS."Year"=GT."Year"
    AND NS."Month"=GT."Month"
    AND NS."Day"=GT."Day"
WHERE SS."Year"<>'YYYY' AND NS."Year"<>'YYYY';
