CREATE DATABASE ZomatoDB;
USE ZomatoDB;

CREATE TABLE zomato_dataset (
    RestaurantID INT PRIMARY KEY,
    RestaurantName VARCHAR(255),
    CountryCode VARCHAR(100),
    City VARCHAR(100),
    Address VARCHAR(100),
    Locality VARCHAR(255),
    LocalityVerbose VARCHAR(100),
    Cuisines TEXT,
    Currency VARCHAR(50),
    Has_Table_booking VARCHAR(10),
    Has_Online_delivery VARCHAR(10),
    Is_delivering_now VARCHAR(20),
    Switch_to_order_menu VARCHAR(20),
    Price_range INT,
    Votes INT,
    Average_Cost_for_two INT,
    Rating DECIMAL(3,1)
);

-- COUNTRY CODE COLUMN
SELECT DISTINCT CountryCode
FROM zomato_dataset;
-- CITY COLUMN
SELECT DISTINCT City
FROM zomato_dataset;
-- LOCALITY COLUMN
SELECT DISTINCT Locality
FROM zomato_dataset;
-- CUISINES COULMN
SELECT DISTINCT Cuisines
FROM zomato_dataset;
-- CURRENCY COULMN
SELECT DISTINCT Currency
FROM zomato_dataset;
-- YES/NO COLUMNS
SELECT 
    Has_Table_booking,
    Has_Online_delivery,
    Is_delivering_now,
    Switch_to_order_menu
FROM zomato_dataset;
-- PRICE RANGE COLUMN
SELECT DISTINCT Price_range
FROM zomato_dataset;
-- VOTES COLUMN (CHECKING MIN,MAX,AVG OF VOTE COLUMN)
SELECT 
    MIN(Votes) AS Min_Votes,
    MAX(Votes) AS Max_Votes,
    ROUND(AVG(Votes), 2) AS Avg_Votes
FROM zomato_dataset;
-- COST COLUMN
#2. Get MIN, MAX, and AVG Cost by Currency
SELECT 
    Currency,
    MIN(CAST(Average_Cost_for_two AS SIGNED)) AS Min_Cost,
    ROUND(AVG(CAST(Average_Cost_for_two AS SIGNED)), 2) AS Avg_Cost,
    MAX(CAST(Average_Cost_for_two AS SIGNED)) AS Max_Cost
FROM zomato_dataset
GROUP BY Currency
ORDER BY Currency;
-- RATING COLUMN
SELECT Rating
FROM zomato_dataset;
-- ADD COLOMN RATE_CATEGORY
ALTER TABLE zomato_dataset
ADD RATE_CATEGORY VARCHAR(20);
SET SQL_SAFE_UPDATES = 0;

-- UPDATING NEW ADDED COLUMN WITH REFFERENCE OF AN EXISTING COLUMN
UPDATE zomato_dataset
SET RATE_CATEGORY = 
    CASE
        WHEN Rating >= 1 AND Rating < 2.5 THEN 'POOR'
        WHEN Rating >= 2.5 AND Rating < 3.5 THEN 'GOOD'
        WHEN Rating >= 3.5 AND Rating < 4.5 THEN 'GREAT'
        WHEN Rating >= 4.5 THEN 'EXCELLENT'
        ELSE 'NO RATING'
    END;
SET SQL_SAFE_UPDATES = 1;


-- ROLLING/MOVING COUNT OF RESTAURANTS IN INDIAN CITIES
WITH LocalityCount AS (
    SELECT
        City,
        Locality,
        COUNT(RestaurantID) AS TOTAL_REST
    FROM zomato_dataset
    WHERE CountryCode = 1  -- India
    GROUP BY City, Locality
)
SELECT 
    City,
    Locality,
    TOTAL_REST,
    SUM(TOTAL_REST) OVER (PARTITION BY City ORDER BY TOTAL_REST DESC) AS Rolling_Sum
FROM LocalityCount
ORDER BY City, Rolling_Sum DESC;


-- SEARCHING FOR PERCENTAGE OF RESTAURANTS IN ALL THE COUNTRIES
WITH CountryWise AS (
    SELECT 
        CountryCode, 
        COUNT(RestaurantID) AS Country_Restaurants
    FROM zomato_dataset
    GROUP BY CountryCode
),
TotalCount AS (
    SELECT SUM(Country_Restaurants) AS Global_Total FROM CountryWise
)
SELECT 
    C.CountryCode, 
    C.Country_Restaurants, 
    ROUND((C.Country_Restaurants / T.Global_Total) * 100, 2) AS Percentage
FROM CountryWise C, TotalCount T
ORDER BY Percentage DESC;

-- WHICH COUNTRIES AND HOW MANY RESTAURANTS WITH PERCENTAGE PROVIDES ONLINE DELIVERY OPTION
WITH CountryTotal AS (
    SELECT 
        CountryCode, 
        COUNT(RestaurantID) AS Total_Restaurants
    FROM zomato_dataset
    GROUP BY CountryCode
),
OnlineDelivery AS (
    SELECT 
        CountryCode, 
        COUNT(RestaurantID) AS Online_Delivery_Restaurants
    FROM zomato_dataset
    WHERE Has_Online_delivery = 'Yes'
    GROUP BY CountryCode
)
SELECT 
    C.CountryCode, 
    C.Total_Restaurants, 
    COALESCE(O.Online_Delivery_Restaurants, 0) AS Online_Delivery_Restaurants, 
    ROUND((COALESCE(O.Online_Delivery_Restaurants, 0) / C.Total_Restaurants) * 100, 2) AS Percentage_Online_Delivery
FROM CountryTotal C
LEFT JOIN OnlineDelivery O ON C.CountryCode = O.CountryCode
ORDER BY Percentage_Online_Delivery DESC;

-- FINDING FROM WHICH CITY AND LOCALITY IN INDIA WHERE THE MAX RESTAURANTS ARE LISTED IN ZOMATO
SELECT City, Locality, COUNT(RestaurantID) AS Total_Restaurants
FROM zomato_dataset
WHERE CountryCode = 1  -- 1 is the CountryCode for India
GROUP BY City, Locality
ORDER BY Total_Restaurants DESC
LIMIT 1;

-- TYPES OF FOODS ARE AVAILABLE IN INDIA WHERE THE MAX RESTAURANTS ARE LISTED IN ZOMATO
SELECT Cuisines, COUNT(RestaurantID) AS Total_Restaurants
FROM zomato_dataset
WHERE CountryCode = 1  -- 1 is the CountryCode for India
GROUP BY Cuisines
ORDER BY Total_Restaurants DESC;

-- MOST POPULAR FOOD IN INDIA WHERE THE MAX RESTAURANTS ARE LISTED IN ZOMATO
SELECT 
    Cuisines, 
    COUNT(RestaurantID) AS Total_Restaurants
FROM zomato_dataset
WHERE CountryCode = 1  -- 1 corresponds to India
GROUP BY Cuisines
ORDER BY Total_Restaurants DESC
LIMIT 10;

-- WHICH LOCALITIES IN INDIA HAS THE LOWEST RESTAURANTS LISTED IN ZOMATO
SELECT 
    City, 
    Locality, 
    COUNT(RestaurantID) AS Total_Restaurants
FROM zomato_dataset
WHERE CountryCode = 1  -- 1 corresponds to India
GROUP BY City, Locality
ORDER BY Total_Restaurants ASC
LIMIT 10;

-- HOW MANY RESTAURANTS OFFER TABLE BOOKING OPTION IN INDIA WHERE THE MAX RESTAURANTS ARE LISTED IN ZOMATO
WITH CityMaxRestaurants AS (
    -- Find the city with the maximum number of restaurants listed in India
    SELECT 
        City, 
        COUNT(RestaurantID) AS Total_Restaurants
    FROM zomato_dataset
    WHERE CountryCode = 1  -- 216 corresponds to India
    GROUP BY City
    ORDER BY Total_Restaurants DESC
    LIMIT 1
)
SELECT 
    z.City, 
    COUNT(z.RestaurantID) AS Table_Booking_Restaurants
FROM zomato_dataset z
JOIN CityMaxRestaurants cmr ON z.City = cmr.City
WHERE z.Has_Table_booking = 'Yes'
GROUP BY z.City;

SELECT DISTINCT CountryCode FROM zomato_dataset;

-- HOW RATING AFFECTS IN MAX LISTED RESTAURANTS WITH AND WITHOUT TABLE BOOKING OPTION (Connaught Place)
SELECT 
    Rating,
    COUNT(CASE WHEN Has_Table_booking = 'Yes' THEN RestaurantID END) AS With_Table_Booking,
    COUNT(CASE WHEN Has_Table_booking = 'No' THEN RestaurantID END) AS Without_Table_Booking
FROM zomato_dataset
WHERE CountryCode = 1 AND Locality = 'Connaught Place'
GROUP BY Rating
ORDER BY Rating DESC;

-- AVG RATING OF RESTS LOCATION WISE
SELECT 
    City, 
    Locality, 
    ROUND(AVG(Rating), 2) AS Avg_Rating
FROM zomato_dataset
WHERE Rating IS NOT NULL
GROUP BY City, Locality
ORDER BY Avg_Rating DESC;

-- FINDING THE BEST RESTAURANTS WITH MODRATE COST FOR TWO IN INDIA HAVING INDIAN CUISINES
SELECT 
    RestaurantName, 
    City, 
    Locality, 
    Cuisines, 
    Average_Cost_for_two, 
    Rating
FROM zomato_dataset
WHERE 
    CountryCode = 1 -- India
    AND Cuisines LIKE '%Indian%' 
    AND Average_Cost_for_two BETWEEN 500 AND 1000 -- Moderate cost range
    AND Rating >= 4.0 -- Considering best restaurants with good ratings
ORDER BY Rating DESC, Average_Cost_for_two;

-- FIND ALL THE RESTAURANTS THOSE WHO ARE OFFERING TABLE BOOKING OPTIONS WITH PRICE RANGE AND HAS HIGH RATING
SELECT 
    RestaurantName, 
    City, 
    Locality, 
    Price_range, 
    Rating
FROM zomato_dataset
WHERE 
    Has_Table_booking = 'Yes' 
    AND Rating >= 4.0 -- Considering high-rated restaurants
ORDER BY Rating DESC, Price_range DESC;

drop table zomato_dataset;