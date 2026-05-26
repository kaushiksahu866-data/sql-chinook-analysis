# 🎵 Chinook Music Store — SQL Analytics Project
### 20 Queries Across 5 Complexity Levels | MySQL | Real Relational Database

![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Advanced-orange)
![Database](https://img.shields.io/badge/Database-Chinook-blue)
![Queries](https://img.shields.io/badge/Queries-20-brightgreen)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

---

## 🧭 Project Overview

This project conducts a full SQL analytics deep-dive on the **Chinook Music Store** — a real relational database modelled on Apple iTunes, containing customers, invoices, tracks, albums, artists, employees, and playlists across 11 normalized tables.

The goal is not just to write queries — it is to answer real business questions a music store analyst would face, and demonstrate SQL proficiency across every concept tested in Data Analyst interviews.

> **Core question:** *"What does the data tell us about revenue, customers, artists, and sales performance — and can we surface it using progressively advanced SQL?"*

---

## 📊 Database At A Glance

| Table | Rows | Description |
|-------|------|-------------|
| `Artist` | 275 | Music artists |
| `Album` | 347 | Albums linked to artists |
| `Track` | 3,503 | Individual tracks with price and duration |
| `Genre` | 25 | Music genre categories |
| `MediaType` | 5 | Audio format types |
| `Customer` | 59 | Store customers with support rep assignment |
| `Employee` | 8 | Staff including sales support representatives |
| `Invoice` | 412 | Customer purchase headers |
| `InvoiceLine` | 2,240 | Line items linking invoices to tracks |
| `Playlist` | 18 | Curated track playlists |
| `PlaylistTrack` | 8,715 | Many-to-many playlist–track mapping |

---

## 🗂️ Schema Relationships

```
Artist ──< Album ──< Track >── Genre
                      │
                      └──> InvoiceLine >── Invoice >── Customer >── Employee
                      │
                      └──> PlaylistTrack >── Playlist
```

---

## 📋 Query Index — 20 Queries Across 5 Levels

### Level 1 — Basic
| # | Business Question | SQL Concept |
|---|-------------------|-------------|
| Q01 | Which tracks are the longest? | `SELECT`, computed column, `ORDER BY`, `LIMIT` |
| Q02 | How many tracks exist per genre? | `INNER JOIN`, `GROUP BY`, `COUNT` |
| Q03 | Who are our customers in France? | `WHERE` filter, `CONCAT`, `ORDER BY` |
| Q04 | Which countries generate the most revenue? | `GROUP BY`, `SUM`, multi-metric aggregation |

### Level 2 — JOINs
| # | Business Question | SQL Concept |
|---|-------------------|-------------|
| Q05 | What does the full track catalogue look like? | 4-table `INNER JOIN` chain |
| Q06 | Which support rep manages each customer? | `JOIN` across Customer → Employee |
| Q07 | Who are our top 10 customers by lifetime spend? | Multi-table `JOIN` + `GROUP BY` + `LIMIT` |
| Q08 | Which customers have never made a purchase? | `LEFT JOIN` + `IS NULL` (anti-join) |

### Level 3 — Aggregations + Subqueries
| # | Business Question | SQL Concept |
|---|-------------------|-------------|
| Q09 | Which tracks are priced above the catalogue average? | Scalar subquery in `WHERE` |
| Q10 | Which 5 artists have sold the most tracks? | 4-table JOIN + `COUNT` + `LIMIT` |
| Q11 | Which genres drive the most revenue? | 3-table JOIN + dual aggregation |
| Q12 | Which support rep generates the most revenue? | 3-table JOIN + employee performance |

### Level 4 — CTEs
| # | Business Question | SQL Concept |
|---|-------------------|-------------|
| Q13 | How does monthly revenue trend by quarter? | CTE + `QUARTER()` + `CASE WHEN` |
| Q14 | What is the #1 bestselling track per genre? | Chained CTEs + `ROW_NUMBER()` `PARTITION BY` |
| Q15 | How do customers segment by lifetime spend? | CTE + `CASE WHEN` classification |
| Q16 | Who is the top customer in each country? | CTE + `DENSE_RANK()` `PARTITION BY` |

### Level 5 — Window Functions
| # | Business Question | SQL Concept |
|---|-------------------|-------------|
| Q17 | What is the month-over-month revenue growth %? | `LAG()` window function |
| Q18 | What is the cumulative revenue since launch? | `SUM() OVER` running total |
| Q19 | How do tracks distribute across revenue quartiles? | `NTILE(4)` classification |
| Q20 | Which countries account for 80% of revenue? | Pareto — cumulative `SUM() OVER` |

---

## 💡 SQL Highlights

### Anti-Join — Customers Who Never Purchased (Q08)
```sql
SELECT c.CustomerId,
       CONCAT(c.FirstName, ' ', c.LastName) AS Customer_Name,
       c.Email, c.Country
FROM Customer c
LEFT JOIN Invoice i
    ON c.CustomerId = i.CustomerId
WHERE i.InvoiceId IS NULL;
```
> Finds records in the left table with no match in the right table.

---

### Chained CTEs + ROW_NUMBER — Top Track Per Genre (Q14)
```sql
WITH Genre_Track_Sales AS (
    SELECT g.GenreId, g.Name AS Genre_Name,
           t.TrackId, t.Name AS Track_Name,
           SUM(il.Quantity) AS Total_Units_Sold
    FROM Genre g
    INNER JOIN Track t ON g.GenreId = t.GenreId
    INNER JOIN InvoiceLine il ON t.TrackId = il.TrackId
    GROUP BY g.GenreId, g.Name, t.TrackId, t.Name
),
Ranked_Tracks AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY GenreId
               ORDER BY Total_Units_Sold DESC
           ) AS Sales_Rank
    FROM Genre_Track_Sales
)
SELECT Genre_Name, Track_Name, Total_Units_Sold
FROM Ranked_Tracks
WHERE Sales_Rank = 1
ORDER BY Total_Units_Sold DESC;
```
> Two chained CTEs with `ROW_NUMBER() OVER (PARTITION BY)` — surfaces the #1 selling track within each genre independently.

---

### LAG Window Function — Month-over-Month Growth (Q17)
```sql
WITH Revenue_Per_Month AS (
    SELECT DATE_FORMAT(InvoiceDate, '%Y-%m') AS Revenue_Month,
           ROUND(SUM(Total), 2) AS Monthly_Revenue
    FROM Invoice
    GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
)
SELECT Revenue_Month, Monthly_Revenue,
       LAG(Monthly_Revenue) OVER (ORDER BY Revenue_Month) AS Prev_Month_Revenue,
       ROUND(
           (Monthly_Revenue - LAG(Monthly_Revenue) OVER (ORDER BY Revenue_Month))
           / LAG(Monthly_Revenue) OVER (ORDER BY Revenue_Month) * 100
       , 2) AS MoM_Growth_Pct
FROM Revenue_Per_Month
ORDER BY Revenue_Month;
```
> `LAG()` accesses the previous row's value without a self-join — enables period-over-period comparison in a single pass.

---

### DENSE_RANK — Customer Rank Within Country (Q16)
```sql
WITH Customer_Revenue AS (
    SELECT c.Country, c.CustomerId,
           CONCAT(c.FirstName, ' ', c.LastName) AS Customer_Name,
           ROUND(SUM(i.Total), 2) AS Total_Revenue
    FROM Customer c
    INNER JOIN Invoice i ON c.CustomerId = i.CustomerId
    GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
)
SELECT Country, Customer_Name, Total_Revenue,
       DENSE_RANK() OVER (
           PARTITION BY Country
           ORDER BY Total_Revenue DESC
       ) AS Revenue_Rank_In_Country
FROM Customer_Revenue
ORDER BY Country, Revenue_Rank_In_Country;
```
> `DENSE_RANK() OVER (PARTITION BY Country)` ranks customers independently within each country — no gaps in ranking for ties.

---

### Pareto Analysis — Cumulative Revenue by Country (Q20)
```sql
WITH Country_Revenue AS (
    SELECT BillingCountry AS Country,
           ROUND(SUM(Total), 2) AS Total_Revenue
    FROM Invoice
    GROUP BY BillingCountry
)
SELECT Country, Total_Revenue,
       ROUND(Total_Revenue / SUM(Total_Revenue) OVER () * 100, 2) AS Revenue_Share_Pct,
       ROUND(SUM(Total_Revenue) OVER (
           ORDER BY Total_Revenue DESC
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) / SUM(Total_Revenue) OVER () * 100, 2) AS Cumulative_Revenue_Pct
FROM Country_Revenue
ORDER BY Total_Revenue DESC;
```
> Combines two window functions in one query — individual share % and running cumulative %. Classic Pareto/80-20 analysis pattern.

---

## 📈 Key Business Insights

1. **USA dominates revenue** — $523.06 in total billing, nearly 1.7× the second-highest country (Canada at $303.96). Geographic concentration signals both opportunity and risk.

2. **Rock drives the catalogue** — Rock genre generated $826.65 in total revenue, the highest of any genre. Content acquisition investment should prioritise rock artists and licensing.

3. **Top customer is Helena Holý (Czech Republic)** — $49.62 in lifetime spend. Notable that the highest-value customer is not from the USA — the top-spending customers do not always come from the top-revenue countries.

4. **Jane Peacock is the top-performing support rep** — $833.04 in revenue generated through her customer portfolio. Performance varies meaningfully across the 3 support reps, suggesting rep assignment impacts revenue.

5. **59 customers, 412 invoices, $2,328.60 total revenue** — average of ~7 purchases per customer lifetime, indicating moderate but consistent repeat purchase behaviour across the base.

---

## 🗂️ Repository Structure

```
sql-chinook-analysis/
│
├── data/
│   └── Chinook_MySql.sql          # Original Chinook schema + data
│
├── queries/
│   └── chinook_analysis.sql       # All 20 queries
│
└── README.md
```

---

## ▶️ How to Run

```sql
-- 1. Clone the repository

-- 2. Open MySQL Workbench and connect to your local instance

-- 3. Import the Chinook database
-- File → Open SQL Script → select data/Chinook_MySql.sql → Execute

-- 4. Set chinook as default schema
-- Right-click chinook in Schemas panel → Set as Default Schema

-- 5. Open and run the queries
-- File → Open SQL Script → select queries/chinook_analysis.sql
-- Run individual queries by highlighting + Ctrl+Shift+Enter
-- Run all queries with Ctrl+Shift+Enter (no selection)
```

**Requirements:** MySQL 8.0+

---

## 👤 Author

**Kaushik Sahu**
B.Tech Biomedical Engineering, NIT Rourkela
Aspiring Data Analyst | Python · MySQL · Power BI · Excel

📧 kaushiksahu866@gmail.com
🔗 [LinkedIn](https://www.linkedin.com/in/kaushik-sahu-37316a1b8/)
🐙 [GitHub](https://github.com/kaushiksahu866-data)

---
