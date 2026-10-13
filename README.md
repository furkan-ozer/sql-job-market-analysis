# Global Data Job Market & Salary Analysis (PostgreSQL)

An analytical SQL project exploring global salary trends, competitive benchmarks, and employer tiering across European markets using PostgreSQL.

## Project Overview
Analyzing labor market datasets often requires comparing individual records against segment benchmarks without losing row-level granularity. This project implements modular SQL architecture (CTEs) and advanced Window Functions to solve real-world talent acquisition and business intelligence questions without heavy JOIN overheads or row-collapsing GROUP BY clauses.

## Tech Stack & Analytical Techniques
- **Database:** PostgreSQL
- **Key Concepts:**
  - **Common Table Expressions (CTEs):** Modularized, readable subquery workflows.
  - **Ranking Windows:** `DENSE_RANK() OVER (...)` to isolate market leaders and handle salary ties.
  - **Aggregate Windows:** `AVG()`, `MAX()`, `MIN()`, `COUNT()` combined with `OVER()` to compute segment baselines alongside individual observations.
  - **Multi-Column Partitioning:** Isolating discrete market cohorts via `PARTITION BY job_country, job_title_short`.
  - **Data Type Casting:** Precise financial rounding using `::NUMERIC`.

---

## Key Analytical Scenarios Solved

### 1. Market Baseline vs. Individual Postings
Calculated the role average salary across Turkish tech postings and isolated exact deviations (`salary - avg`) in a single pass without extra subquery joins.

### 2. Top-N Employer Identification per Segment
Leveraged `DENSE_RANK()` partitioned by role to identify the top 2 highest-paying employers across Germany, evaluating how far each leader outpaces the group median.

### 3. Macro Market Profiling (Benelux & CEE)
Built aggregated profiles (total volume, floor, ceiling, and average rates) across Poland and the Netherlands to flag offers exceeding national thresholds.

### 4. Salary Tiering (Peak Rate Proximity)
Calculated dynamic ceiling metrics to uncover companies offering salaries within 80% or more of peak market compensation per role.

### 5. Multi-Dimensional Market Champions
Partitioned data simultaneously across geography and specialization (`job_country` and `job_title_short`) to extract compensation leaders for cross-border talent acquisition.

---

## Repository Structure
```text
├── README.md        # Project documentation & analytical methodology
└── queries.sql      # Well-commented, runnable PostgreSQL queries
