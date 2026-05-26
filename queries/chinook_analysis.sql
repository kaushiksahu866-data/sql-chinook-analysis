-- ============================================================
--  CHINOOK MUSIC STORE — SQL ANALYTICS PROJECT
--  Database  : Chinook (MySQL)
--  Author    : Kaushik Sahu | B.Tech Biomedical Engineering, NIT Rourkela
--  Tool      : MySQL Workbench 8.0
--  Queries   : 20 across 5 complexity levels
-- ============================================================

-- ============================================================
--  QUERY INDEX
-- ============================================================
--  LEVEL 1 — Basic (Q01–Q04)
--    Q01 : Top 10 longest tracks by duration
--    Q02 : Track count per genre
--    Q03 : Customers from a specific country
--    Q04 : Total revenue by country
--
--  LEVEL 2 — JOINs (Q05–Q08)
--    Q05 : Full track details — 4-table JOIN
--    Q06 : Customer with support representative name
--    Q07 : Top 10 customers by lifetime revenue
--    Q08 : Customers who have never made a purchase (Anti-Join)
--
--  LEVEL 3 — Aggregations + Subqueries (Q09–Q12)
--    Q09 : Tracks priced above the catalogue average (Subquery)
--    Q10 : Top 5 artists by total tracks sold
--    Q11 : Revenue and sales volume by genre
--    Q12 : Employee sales performance (support rep revenue)
--
--  LEVEL 4 — CTEs (Q13–Q16)
--    Q13 : Monthly revenue trend with MoM comparison (CTE)
--    Q14 : Top-selling track per genre (CTE + ROW_NUMBER)
--    Q15 : Customer lifetime value segmentation (CTE + CASE WHEN)
--    Q16 : Customer revenue rank within each country (CTE + DENSE_RANK)
--
--  LEVEL 5 — Window Functions (Q17–Q20)
--    Q17 : Month-over-month revenue growth % (LAG)
--    Q18 : Running total revenue over time (SUM OVER)
--    Q19 : Track revenue quartile classification (NTILE)
--    Q20 : Country revenue Pareto analysis (Cumulative %)
-- ============================================================

CREATE DATABASE IF NOT EXISTS chinook;
USE chinook;

-- ============================================================
--  LEVEL 1 — BASIC
--  Concepts: SELECT, WHERE, ORDER BY, LIMIT, GROUP BY, HAVING
-- ============================================================

-- ------------------------------------------------------------
-- Q01: Top 10 Longest Tracks by Duration
-- Business question: Which tracks demand the most listening
-- time — useful for playlist curation and licensing decisions.
-- Concept: Computed column, ORDER BY, LIMIT
-- ------------------------------------------------------------
SELECT
    TrackId,
    Name                                    AS Track_Name,
    Milliseconds,
    ROUND(Milliseconds / 60000, 2)          AS Duration_Minutes
FROM Track
ORDER BY Milliseconds DESC
LIMIT 10;

-- ------------------------------------------------------------
-- Q02: Track Count Per Genre
-- Business question: Which music genres have the largest
-- catalogue? Helps identify inventory concentration.
-- Concept: INNER JOIN, GROUP BY, aggregate COUNT
-- ------------------------------------------------------------
SELECT
    g.Name                                  AS Genre_Name,
    COUNT(t.TrackId)                        AS Total_Tracks
FROM Track t
INNER JOIN Genre g
    ON t.GenreId = g.GenreId
GROUP BY g.GenreId, g.Name
ORDER BY Total_Tracks DESC;

-- ------------------------------------------------------------
-- Q03: Customers From a Specific Country
-- Business question: Who are our customers in France?
-- Useful for regional marketing and support assignment.
-- Concept: WHERE filter, CONCAT for full name, ORDER BY
-- ------------------------------------------------------------
SELECT
    CustomerId,
    CONCAT(FirstName, ' ', LastName)        AS Customer_Name,
    Country,
    Email,
    SupportRepId
FROM Customer
WHERE Country = 'France'
ORDER BY Customer_Name;

-- ------------------------------------------------------------
-- Q04: Total Revenue by Country
-- Business question: Which countries generate the most revenue?
-- Drives geographic expansion and pricing strategy decisions.
-- Concept: GROUP BY on billing country, SUM aggregation
-- ------------------------------------------------------------
SELECT
    BillingCountry                          AS Country,
    ROUND(SUM(Total), 2)                    AS Total_Revenue,
    COUNT(InvoiceId)                        AS Total_Invoices,
    ROUND(AVG(Total), 2)                    AS Avg_Invoice_Value
FROM Invoice
GROUP BY BillingCountry
ORDER BY Total_Revenue DESC;

-- ============================================================
--  LEVEL 2 — JOINS
--  Concepts: INNER JOIN, LEFT JOIN, multi-table joins, anti-join
-- ============================================================

-- ------------------------------------------------------------
-- Q05: Full Track Details — 4-Table JOIN
-- Business question: What is the complete catalogue with artist,
-- album, genre, and pricing information?
-- Concept: 4-table INNER JOIN chain (Track → Album → Artist,
--          Track → Genre)
-- ------------------------------------------------------------
SELECT
    t.TrackId,
    t.Name                                  AS Track_Name,
    ar.Name                                 AS Artist_Name,
    al.Title                                AS Album_Title,
    g.Name                                  AS Genre_Name,
    ROUND(t.Milliseconds / 60000, 2)        AS Duration_Minutes,
    t.UnitPrice
FROM Track t
INNER JOIN Album al
    ON t.AlbumId = al.AlbumId
INNER JOIN Artist ar
    ON al.ArtistId = ar.ArtistId
INNER JOIN Genre g
    ON t.GenreId = g.GenreId
ORDER BY Artist_Name, Album_Title, Track_Name;

-- ------------------------------------------------------------
-- Q06: Customer With Their Support Representative
-- Business question: Which employee is responsible for each
-- customer? Enables accountability and performance tracking.
-- Concept: Self-referencing JOIN between Customer and Employee
-- ------------------------------------------------------------
SELECT
    CONCAT(c.FirstName, ' ', c.LastName)    AS Customer_Name,
    c.Email,
    c.Country,
    CONCAT(e.FirstName, ' ', e.LastName)    AS Support_Representative,
    e.Title                                 AS Rep_Title
FROM Customer c
INNER JOIN Employee e
    ON c.SupportRepId = e.EmployeeId
ORDER BY Support_Representative, Customer_Name;

-- ------------------------------------------------------------
-- Q07: Top 10 Customers by Lifetime Revenue
-- Business question: Who are our highest-value customers?
-- Drives loyalty programme targeting and VIP identification.
-- Concept: JOIN + GROUP BY + multi-column aggregation + LIMIT
-- ------------------------------------------------------------
SELECT
    c.CustomerId,
    CONCAT(c.FirstName, ' ', c.LastName)    AS Customer_Name,
    c.Email,
    c.Country,
    COUNT(i.InvoiceId)                      AS Total_Invoices,
    ROUND(SUM(i.Total), 2)                  AS Lifetime_Revenue,
    ROUND(AVG(i.Total), 2)                  AS Avg_Invoice_Value
FROM Customer c
INNER JOIN Invoice i
    ON c.CustomerId = i.CustomerId
GROUP BY
    c.CustomerId,
    c.FirstName,
    c.LastName,
    c.Email,
    c.Country
ORDER BY Lifetime_Revenue DESC
LIMIT 10;

-- ------------------------------------------------------------
-- Q08: Customers Who Have Never Made a Purchase (Anti-Join)
-- Business question: Which registered customers have never
-- bought anything? Prime targets for re-engagement campaigns.
-- Concept: LEFT JOIN + IS NULL (anti-join pattern)
-- ------------------------------------------------------------
SELECT
    c.CustomerId,
    CONCAT(c.FirstName, ' ', c.LastName)    AS Customer_Name,
    c.Email,
    c.Country
FROM Customer c
LEFT JOIN Invoice i
    ON c.CustomerId = i.CustomerId
WHERE i.InvoiceId IS NULL
ORDER BY Customer_Name;

-- ============================================================
--  LEVEL 3 — AGGREGATIONS + SUBQUERIES
--  Concepts: Scalar subqueries, correlated logic, HAVING
-- ============================================================

-- ------------------------------------------------------------
-- Q09: Tracks Priced Above the Catalogue Average
-- Business question: Which tracks carry a premium price?
-- Useful for identifying high-margin inventory.
-- Concept: Scalar subquery in WHERE clause
-- ------------------------------------------------------------
SELECT
    TrackId,
    Name                                    AS Track_Name,
    UnitPrice,
    ROUND(UnitPrice - (SELECT AVG(UnitPrice) FROM Track), 2)
                                            AS Price_Above_Average
FROM Track
WHERE UnitPrice > (
    SELECT AVG(UnitPrice)
    FROM Track
)
ORDER BY UnitPrice DESC, Track_Name;

-- ------------------------------------------------------------
-- Q10: Top 5 Artists by Total Tracks Sold
-- Business question: Which artists drive the most sales volume?
-- Informs licensing renewals and promotional partnerships.
-- Concept: 4-table JOIN chain, GROUP BY, aggregate COUNT
-- ------------------------------------------------------------
SELECT
    ar.ArtistId,
    ar.Name                                 AS Artist_Name,
    COUNT(DISTINCT t.TrackId)               AS Unique_Tracks_In_Catalogue,
    COUNT(il.InvoiceLineId)                 AS Total_Tracks_Sold,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS Total_Revenue
FROM Artist ar
INNER JOIN Album al
    ON ar.ArtistId = al.ArtistId
INNER JOIN Track t
    ON al.AlbumId = t.AlbumId
INNER JOIN InvoiceLine il
    ON t.TrackId = il.TrackId
GROUP BY ar.ArtistId, ar.Name
ORDER BY Total_Tracks_Sold DESC
LIMIT 5;

-- ------------------------------------------------------------
-- Q11: Revenue and Sales Volume by Genre
-- Business question: Which genres generate the most revenue?
-- Guides content acquisition and catalogue investment decisions.
-- Concept: 3-table JOIN, GROUP BY, dual aggregation metrics
-- ------------------------------------------------------------
SELECT
    g.Name                                  AS Genre_Name,
    COUNT(il.InvoiceLineId)                 AS Total_Tracks_Sold,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS Total_Revenue,
    ROUND(AVG(il.UnitPrice * il.Quantity), 2) AS Avg_Revenue_Per_Sale
FROM Genre g
INNER JOIN Track t
    ON g.GenreId = t.GenreId
INNER JOIN InvoiceLine il
    ON t.TrackId = il.TrackId
GROUP BY g.GenreId, g.Name
ORDER BY Total_Revenue DESC;

-- ------------------------------------------------------------
-- Q12: Employee Sales Performance (Support Rep Revenue)
-- Business question: Which support representative drives the
-- most customer revenue? Enables performance-based incentives.
-- Concept: 3-table JOIN, GROUP BY across employee dimension
-- ------------------------------------------------------------
SELECT
    e.EmployeeId,
    CONCAT(e.FirstName, ' ', e.LastName)    AS Employee_Name,
    e.Title,
    COUNT(DISTINCT c.CustomerId)            AS Customers_Managed,
    COUNT(DISTINCT i.InvoiceId)             AS Total_Invoices,
    ROUND(SUM(i.Total), 2)                  AS Total_Revenue_Generated,
    ROUND(AVG(i.Total), 2)                  AS Avg_Invoice_Value
FROM Employee e
INNER JOIN Customer c
    ON e.EmployeeId = c.SupportRepId
INNER JOIN Invoice i
    ON c.CustomerId = i.CustomerId
GROUP BY
    e.EmployeeId,
    e.FirstName,
    e.LastName,
    e.Title
ORDER BY Total_Revenue_Generated DESC;

-- ============================================================
--  LEVEL 4 — CTEs (Common Table Expressions)
--  Concepts: WITH clause, chained CTEs, ROW_NUMBER, CASE WHEN
-- ============================================================

-- ------------------------------------------------------------
-- Q13: Monthly Revenue Trend with Quarter Context (CTE)
-- Business question: How does revenue trend month by month?
-- Which quarters are strongest? Drives seasonal planning.
-- Concept: CTE for modular query structure, date functions,
--          CASE WHEN for quarter labelling
-- ------------------------------------------------------------
WITH Monthly_Revenue AS (
    SELECT
        YEAR(InvoiceDate)                   AS Revenue_Year,
        MONTH(InvoiceDate)                  AS Revenue_Month,
        MONTHNAME(InvoiceDate)              AS Month_Name,
        QUARTER(InvoiceDate)                AS Revenue_Quarter,
        ROUND(SUM(Total), 2)                AS Monthly_Revenue,
        COUNT(InvoiceId)                    AS Total_Invoices
    FROM Invoice
    GROUP BY
        YEAR(InvoiceDate),
        MONTH(InvoiceDate),
        MONTHNAME(InvoiceDate),
        QUARTER(InvoiceDate)
)
SELECT
    Revenue_Year,
    Revenue_Quarter,
    Revenue_Month,
    Month_Name,
    Monthly_Revenue,
    Total_Invoices,
    CASE Revenue_Quarter
        WHEN 1 THEN 'Q1 (Jan–Mar)'
        WHEN 2 THEN 'Q2 (Apr–Jun)'
        WHEN 3 THEN 'Q3 (Jul–Sep)'
        WHEN 4 THEN 'Q4 (Oct–Dec)'
    END                                     AS Quarter_Label
FROM Monthly_Revenue
ORDER BY Revenue_Year, Revenue_Month;

-- ------------------------------------------------------------
-- Q14: Top-Selling Track Per Genre (Chained CTEs + ROW_NUMBER)
-- Business question: What is the #1 bestselling track in each
-- genre? Guides featured playlist and homepage curation.
-- Concept: Two chained CTEs, ROW_NUMBER() with PARTITION BY
-- ------------------------------------------------------------
WITH Genre_Track_Sales AS (
    SELECT
        g.GenreId,
        g.Name                              AS Genre_Name,
        t.TrackId,
        t.Name                              AS Track_Name,
        SUM(il.Quantity)                    AS Total_Units_Sold,
        ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS Total_Revenue
    FROM Genre g
    INNER JOIN Track t
        ON g.GenreId = t.GenreId
    INNER JOIN InvoiceLine il
        ON t.TrackId = il.TrackId
    GROUP BY g.GenreId, g.Name, t.TrackId, t.Name
),
Ranked_Tracks AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY GenreId
            ORDER BY Total_Units_Sold DESC
        )                                   AS Sales_Rank
    FROM Genre_Track_Sales
)
SELECT
    Genre_Name,
    Track_Name,
    Total_Units_Sold,
    Total_Revenue
FROM Ranked_Tracks
WHERE Sales_Rank = 1
ORDER BY Total_Revenue DESC;

-- ------------------------------------------------------------
-- Q15: Customer Lifetime Value Segmentation (CTE + CASE WHEN)
-- Business question: How do customers segment by total spend?
-- Champions (>$40), Loyal ($20–$40), Occasional (<$20).
-- Concept: CTE for aggregation, CASE WHEN for classification
-- ------------------------------------------------------------
WITH Customer_Lifetime_Value AS (
    SELECT
        c.CustomerId,
        CONCAT(c.FirstName, ' ', c.LastName) AS Customer_Name,
        c.Country,
        c.Email,
        COUNT(i.InvoiceId)                  AS Total_Purchases,
        ROUND(SUM(i.Total), 2)              AS Total_Spent,
        ROUND(AVG(i.Total), 2)              AS Avg_Purchase_Value
    FROM Customer c
    INNER JOIN Invoice i
        ON c.CustomerId = i.CustomerId
    GROUP BY
        c.CustomerId,
        c.FirstName,
        c.LastName,
        c.Country,
        c.Email
)
SELECT
    CustomerId,
    Customer_Name,
    Country,
    Email,
    Total_Purchases,
    Total_Spent,
    Avg_Purchase_Value,
    CASE
        WHEN Total_Spent > 40  THEN 'Champion'
        WHEN Total_Spent >= 20 THEN 'Loyal'
        ELSE                        'Occasional'
    END                                     AS Customer_Segment
FROM Customer_Lifetime_Value
ORDER BY Total_Spent DESC;

-- ------------------------------------------------------------
-- Q16: Customer Revenue Rank Within Each Country
-- Business question: Who is the top-spending customer in each
-- country? Enables localised loyalty programme targeting.
-- Concept: CTE + DENSE_RANK() with PARTITION BY Country
-- ------------------------------------------------------------
WITH Customer_Revenue AS (
    SELECT
        c.Country,
        c.CustomerId,
        CONCAT(c.FirstName, ' ', c.LastName) AS Customer_Name,
        ROUND(SUM(i.Total), 2)              AS Total_Revenue
    FROM Customer c
    INNER JOIN Invoice i
        ON c.CustomerId = i.CustomerId
    GROUP BY
        c.CustomerId,
        c.FirstName,
        c.LastName,
        c.Country
)
SELECT
    Country,
    CustomerId,
    Customer_Name,
    Total_Revenue,
    DENSE_RANK() OVER (
        PARTITION BY Country
        ORDER BY Total_Revenue DESC
    )                                       AS Revenue_Rank_In_Country
FROM Customer_Revenue
ORDER BY Country, Revenue_Rank_In_Country;

-- ============================================================
--  LEVEL 5 — WINDOW FUNCTIONS
--  Concepts: LAG, SUM OVER, NTILE, cumulative aggregation
-- ============================================================

-- ------------------------------------------------------------
-- Q17: Month-over-Month Revenue Growth (LAG Window Function)
-- Business question: Is revenue growing or declining each month?
-- What is the exact % change vs the previous month?
-- Concept: LAG() to access prior row value, computed % change
-- ------------------------------------------------------------
WITH Revenue_Per_Month AS (
    SELECT
        DATE_FORMAT(InvoiceDate, '%Y-%m')   AS Revenue_Month,
        ROUND(SUM(Total), 2)               AS Monthly_Revenue
    FROM Invoice
    GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
)
SELECT
    Revenue_Month,
    Monthly_Revenue,
    LAG(Monthly_Revenue) OVER (
        ORDER BY Revenue_Month
    )                                       AS Prev_Month_Revenue,
    ROUND(
        (Monthly_Revenue - LAG(Monthly_Revenue) OVER (ORDER BY Revenue_Month))
        / LAG(Monthly_Revenue) OVER (ORDER BY Revenue_Month) * 100
    , 2)                                    AS MoM_Growth_Pct
FROM Revenue_Per_Month
ORDER BY Revenue_Month;

-- ------------------------------------------------------------
-- Q18: Running Total Revenue Over Time (SUM OVER)
-- Business question: What is the cumulative revenue the store
-- has generated since its first invoice?
-- Concept: SUM() OVER with ROWS UNBOUNDED PRECEDING (running total)
-- ------------------------------------------------------------
WITH Revenue_Per_Month AS (
    SELECT
        DATE_FORMAT(InvoiceDate, '%Y-%m')   AS Revenue_Month,
        ROUND(SUM(Total), 2)               AS Monthly_Revenue
    FROM Invoice
    GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
)
SELECT
    Revenue_Month,
    Monthly_Revenue,
    ROUND(
        SUM(Monthly_Revenue) OVER (
            ORDER BY Revenue_Month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
    , 2)                                    AS Running_Total_Revenue
FROM Revenue_Per_Month
ORDER BY Revenue_Month;

-- ------------------------------------------------------------
-- Q19: Track Revenue Quartile Classification (NTILE)
-- Business question: How do tracks distribute across revenue
-- quartiles?
-- Concept: NTILE(4) for equal-bucket distribution analysis
-- ------------------------------------------------------------
WITH Track_Revenue AS (
    SELECT
        t.TrackId,
        t.Name                              AS Track_Name,
        ar.Name                             AS Artist_Name,
        g.Name                              AS Genre_Name,
        COUNT(il.InvoiceLineId)             AS Times_Sold,
        ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS Total_Revenue
    FROM Track t
    INNER JOIN InvoiceLine il
        ON t.TrackId = il.TrackId
    INNER JOIN Album al
        ON t.AlbumId = al.AlbumId
    INNER JOIN Artist ar
        ON al.ArtistId = ar.ArtistId
    INNER JOIN Genre g
        ON t.GenreId = g.GenreId
    GROUP BY t.TrackId, t.Name, ar.Name, g.Name
)
SELECT
    TrackId,
    Track_Name,
    Artist_Name,
    Genre_Name,
    Times_Sold,
    Total_Revenue,
    NTILE(4) OVER (
        ORDER BY Total_Revenue DESC
    )                                       AS Revenue_Quartile,
    CASE NTILE(4) OVER (ORDER BY Total_Revenue DESC)
        WHEN 1 THEN 'Top 25% — Bestseller'
        WHEN 2 THEN 'Upper Mid'
        WHEN 3 THEN 'Lower Mid'
        WHEN 4 THEN 'Bottom 25% — Low Seller'
    END                                     AS Quartile_Label
FROM Track_Revenue
ORDER BY Total_Revenue DESC;

-- ------------------------------------------------------------
-- Q20: Country Revenue Pareto Analysis (Cumulative %)
-- Business question: Which countries account for 80% of total
-- revenue? Demonstrates the 80/20 rule in the customer base.
-- Concept: Running SUM() OVER for cumulative %, revenue share %
-- ------------------------------------------------------------
WITH Country_Revenue AS (
    SELECT
        BillingCountry                      AS Country,
        ROUND(SUM(Total), 2)                AS Total_Revenue,
        COUNT(InvoiceId)                    AS Total_Invoices
    FROM Invoice
    GROUP BY BillingCountry
)
SELECT
    Country,
    Total_Invoices,
    Total_Revenue,
    ROUND(
        SUM(Total_Revenue) OVER (
            ORDER BY Total_Revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
    , 2)                                    AS Cumulative_Revenue,
    ROUND(
        Total_Revenue / SUM(Total_Revenue) OVER () * 100
    , 2)                                    AS Revenue_Share_Pct,
    ROUND(
        SUM(Total_Revenue) OVER (
            ORDER BY Total_Revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / SUM(Total_Revenue) OVER () * 100
    , 2)                                    AS Cumulative_Revenue_Pct
FROM Country_Revenue
ORDER BY Total_Revenue DESC;

-- ==============================================================
--  END OF CHINOOK SQL ANALYTICS PROJECT
--  20 queries | 5 levels | MySQL 8.0
--  Author: Kaushik Sahu | https://github.com/kaushiksahu866-data
-- ==============================================================
