-- TASK 3: Validate row transfer

SELECT COUNT(*) AS total_rows
FROM reit_portfolio;
-- TASK 4: Isolate Short-Term Rental properties using a CTE

WITH str_properties AS (
    SELECT *
    FROM reit_portfolio
    WHERE Occupancy_Type = 'Short-Term Rental'
)
SELECT *
FROM str_properties;
-- TASK 5: Rolling 90-day average Gross Rental Yield
-- Partitioned by Zoning Code and Country Code

SELECT
    Property_ID,
    Sale_Date,
    Zoning_Code,
    Country_Code,
    Gross_Rental_Yield,

    AVG(Gross_Rental_Yield) OVER (
        PARTITION BY Zoning_Code, Country_Code
        ORDER BY julianday(Sale_Date)
        RANGE BETWEEN 89 PRECEDING AND CURRENT ROW
    ) AS Rolling_90_Day_Avg_Yield

FROM reit_portfolio
ORDER BY Zoning_Code, Country_Code, Sale_Date;
-- TASK 6: Categorize STR Saturation

SELECT
    Property_ID,
    Gross_Rental_Yield,
    CASE
        WHEN Gross_Rental_Yield > 0.12 THEN 'Extreme'
        WHEN Gross_Rental_Yield >= 0.08
             AND Gross_Rental_Yield <= 0.12 THEN 'Moderate'
        ELSE 'Normal'
    END AS STR_Saturation
FROM reit_portfolio;
-- TASK 7: Average Sale Price by STR Saturation

WITH saturation_data AS (
    SELECT
        Sale_Price_USD_Normalized,
        CASE
            WHEN Gross_Rental_Yield > 0.12 THEN 'Extreme'
            WHEN Gross_Rental_Yield >= 0.08
                 AND Gross_Rental_Yield <= 0.12 THEN 'Moderate'
            ELSE 'Normal'
        END AS STR_Saturation
    FROM reit_portfolio
)

SELECT
    STR_Saturation,
    COUNT(*) AS Property_Count,
    ROUND(AVG(Sale_Price_USD_Normalized), 2) AS Average_Sale_Price_USD
FROM saturation_data
GROUP BY STR_Saturation
ORDER BY Average_Sale_Price_USD DESC;
-- TASK 8: Divide properties into distance quintiles

SELECT
    Property_ID,
    Distance_To_City_Center_KM,
    NTILE(5) OVER (
        ORDER BY Distance_To_City_Center_KM
    ) AS Distance_Quintile
FROM reit_portfolio;
-- TASK 9: Identify Cannibalized Zones

SELECT
    Zoning_Code,

    SUM(
        CASE
            WHEN Occupancy_Type = 'Short-Term Rental' THEN 1
            ELSE 0
        END
    ) AS STR_Count,

    SUM(
        CASE
            WHEN Occupancy_Type = 'Primary Residence' THEN 1
            ELSE 0
        END
    ) AS Primary_Residence_Count

FROM reit_portfolio

GROUP BY Zoning_Code

HAVING
    SUM(
        CASE
            WHEN Occupancy_Type = 'Short-Term Rental' THEN 1
            ELSE 0
        END
    )
    >
    SUM(
        CASE
            WHEN Occupancy_Type = 'Primary Residence' THEN 1
            ELSE 0
        END
    )

ORDER BY STR_Count DESC;
-- TASK 10: Running Total of Tax Evasion by Country

SELECT
    Property_ID,
    Country_Code,
    Sale_Date,
    Tax_Evasion_Amount,

    SUM(Tax_Evasion_Amount) OVER (
        PARTITION BY Country_Code
        ORDER BY Sale_Date, Property_ID
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Running_Tax_Evasion

FROM reit_portfolio;
-- TASK 11: Create Zoning Tracker View

DROP VIEW IF EXISTS vw_zoning_tracker;

CREATE VIEW vw_zoning_tracker AS

SELECT
    Zoning_Code,

    SUM(
        CASE
            WHEN Occupancy_Type = 'Short-Term Rental' THEN 1
            ELSE 0
        END
    ) AS STR_Count,

    SUM(
        CASE
            WHEN Occupancy_Type = 'Primary Residence' THEN 1
            ELSE 0
        END
    ) AS Primary_Residence_Count,

    SUM(Tax_Evasion_Amount) AS Total_Tax_Evasion

FROM reit_portfolio

GROUP BY Zoning_Code;
-- TASK 12: Create Master Power BI Dataset View

DROP VIEW IF EXISTS vw_powerbi_dataset;

CREATE VIEW vw_powerbi_dataset AS

WITH enriched_data AS (
    SELECT
        r.*,

        CASE
            WHEN Gross_Rental_Yield > 0.12 THEN 'Extreme'
            WHEN Gross_Rental_Yield >= 0.08
                 AND Gross_Rental_Yield <= 0.12 THEN 'Moderate'
            ELSE 'Normal'
        END AS STR_Saturation,

        NTILE(5) OVER (
            ORDER BY Distance_To_City_Center_KM
        ) AS Distance_Quintile

    FROM reit_portfolio AS r
)

SELECT
    *
FROM enriched_data;
-- TASK 13: Index on Buyer_ID and Sale_Date
-- SQLite does not support SQL Server-style clustered indexes.
-- A composite index is used as the SQLite equivalent for query optimization.

CREATE INDEX IF NOT EXISTS idx_buyer_sale_date
ON reit_portfolio (Buyer_ID, Sale_Date);
-- TASK 14: Index on Zoning_Code
-- Standard SQLite index used for faster zoning-based filtering/grouping.

CREATE INDEX IF NOT EXISTS idx_zoning_code
ON reit_portfolio (Zoning_Code);
-- TASK 15: Verify index usage with EXPLAIN QUERY PLAN

-- Composite Buyer_ID + Sale_Date index
EXPLAIN QUERY PLAN
SELECT *
FROM reit_portfolio
WHERE Buyer_ID = 'BUY-3030'
  AND Sale_Date >= '2024-01-01';

-- Zoning_Code index
EXPLAIN QUERY PLAN
SELECT *
FROM reit_portfolio
WHERE Zoning_Code = 'RES-A';
