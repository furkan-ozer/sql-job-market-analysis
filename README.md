# Global Data Job Market & Salary Benchmark Analysis (PostgreSQL)

An analytical SQL project evaluating global compensation structures, remote work premiums, and multi-market talent benchmarks across core data roles using PostgreSQL.

## Project Overview
Analyzing labor market compensation often suffers from skewed salary distributions, flawed hourly/annual inputs, and uncleaned job postings. This project implements modular Common Table Expressions (CTEs), robust non-parametric metrics, and multi-level Window Functions to deliver granular business intelligence without row-collapsing aggregate limitations or unnecessary table joins.

## Tech Stack & Analytical Techniques
- **Database:** PostgreSQL (v13+)
- **Key Concepts:**
  - **Robust Central Tendency:** `PERCENTILE_CONT(0.5)` (Median) alongside `AVG()` to handle right-skewed salary distributions.
  - **Ranking Windows:** `DENSE_RANK() OVER (...)` to isolate compensation leaders while preserving salary ties.
  - **Aggregate Windows:** `AVG()`, `MAX()`, `MIN()`, `COUNT()` with `OVER (PARTITION BY ...)` to calculate segment benchmarks alongside discrete records.
  - **Weighted Baseline Modeling:** Combined aggregate window calculations `(SUM(SUM(...)) OVER () / SUM(COUNT(*)) OVER ())` to compute true market baselines across varying cohort sizes.
  - **Data Hygiene:** Salary floors (`salary_year_avg > 15000`) and sample size thresholds (`HAVING COUNT(*) >= 10/100`) to eliminate outliers and unrepresentative samples.

## Key Analytical Scenarios Solved

### 1. Remote Work Premium & True Market Baseline
Evaluated average and median compensation splits between remote and on-site positions. Applied a weighted global baseline to compute exact monetary deviations and premium percentages without Cartesian overhead.

### 2. High-Volume Geographic Compensation
Identified top-paying countries meeting statistical sample thresholds (`COUNT >= 100`), comparing median and average compensation to account for extreme positive skewness.

### 3. Specialization Demand & Market Share
Quantified job posting volumes across data disciplines and derived market share percentages using total window aggregates in a single pass.

### 4. Compensation Spread Across Core Disciplines
Evaluated minimum, median, average, and maximum compensation ranges across core data roles (Data Analyst, Data Engineer, Data Scientist) to identify wage dispersion.

### 5. Dual Regional & Global Benchmarking
Concurrently benchmarked individual tech postings in Turkey against both domestic market averages and global role-specific standards via modular CTE architectures.

### 6. Role Champions & Tier Segmentation (Europe)
Segmented top employers across Western European markets (Germany, Spain, France) using multi-column partitioning (`job_country`, `job_title_short`) and identified postings offering within 80% or more of the market peak rate.

## Repository Structure
```text
├── README.md        # Project documentation, analytical methodology & business scenarios
└── queries.sql      # Production-ready, modular PostgreSQL scripts
