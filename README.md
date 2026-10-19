# Global Data Job Market & Salary Benchmark Analysis (PostgreSQL)

An analytical SQL project evaluating global compensation structures, remote work salary premiums, and talent benchmarks across core data roles using PostgreSQL.

## Project Overview
Navigating tech compensation benchmarks often suffers from skewed salary distributions, uncleaned job postings, and flawed hourly/annual inputs. This project implements modular Common Table Expressions (CTEs), robust non-parametric metrics (medians), and multi-level Window Functions to deliver actionable market intelligence without row-collapsing aggregate limitations or unnecessary table joins.

## Tech Stack & Analytical Techniques
- **Database:** PostgreSQL (v13+)
- **Key Concepts:**
  - **Robust Central Tendency:** `PERCENTILE_CONT(0.5)` (Median) alongside `AVG()` to eliminate right-skewed salary bias.
  - **Ranking Windows:** `DENSE_RANK() OVER (...)` to isolate market leaders while preserving ties.
  - **Aggregate Windows:** `AVG()`, `MAX()`, `MIN()`, `COUNT()` with `OVER (PARTITION BY ...)` to evaluate cohort benchmarks alongside discrete records.
  - **Weighted Baseline Modeling:** Combined aggregate window calculations `(SUM(SUM(...)) OVER () / SUM(COUNT(*)) OVER ())` to calculate true market baselines across varying sample weights.
  - **Data Hygiene:** Hard salary floors (`salary_year_avg > 15000`) and sample size thresholds (`HAVING COUNT(*) >= 10/100`) to eliminate outliers and unrepresentative samples.

---

## Key Analytical Scenarios Solved (Queries 1–9)

### 1. Remote Work Salary Premium & Distribution (Query 1)
Evaluated average and median compensation splits between remote and non-remote roles. Implemented a weighted global baseline to compute monetary deviations and true premium percentages without Cartesian overhead.

### 2. Highest Paying Countries Analysis (Query 2)
Identified top-paying countries meeting statistical sample thresholds (`COUNT(*) >= 100`), comparing median and average compensation to account for extreme positive skewness.

### 3. Role Demand Distribution & Market Share (Query 3)
Quantified job posting volumes across all data roles and computed exact market share percentages using total window aggregates (`SUM(COUNT(*)) OVER ()`) in a single pass.

### 4. Highest Paying Companies Analysis (Query 4)
Ranked leading compensation employers maintaining reliable hiring volume (`COUNT(*) >= 10`), using median salaries to identify true high-paying organizations.

### 5. Core Data Roles Compensation Spread (Query 5)
Compared salary dispersion across primary professions (*Data Analyst, Data Engineer, Data Scientist*) evaluating minimum, median, average, and maximum annual compensation.

### 6. Regional vs. Global Role Benchmark (Query 6)
Concurrently benchmarked individual Data Analyst salaries in Turkey against both domestic market averages (`AVG() OVER ()`) and the global Data Analyst baseline via CTEs.

### 7. Top Employers by Role - Germany (Query 7)
Isolated the top 2 paying employers per discipline (*Data Analyst, Data Engineer*) in Germany using `DENSE_RANK()`, measuring individual variances from the role average.

### 8. Upper Tier Salary Distribution - Spain (Query 8)
Identified Spanish postings offering within 80% or more of the market ceiling (`MAX() OVER ()`) across core roles to uncover top-tier compensation packages.

### 9. Cross-Country Role Champions - Germany & France (Query 9)
Extracted the highest-paying market champions for Data Analysts and Data Scientists across Germany and France using multi-column partitioning (`job_country, job_title_short`).

---

## Repository Structure
```text
├── README.md        # Project documentation, analytical methodology & business scenarios
└── queries.sql      # Production-ready, modular PostgreSQL scripts
