/* ====================================================================
   DATA JOB MARKET & SALARY BENCHMARK ANALYSIS
   Database: PostgreSQL

   Sections:
   1. Market Overview & Business Metrics
   2. Advanced Segmentations & Window Analytics

   Analytical Concepts & Techniques Demonstrated:
   - Window Functions (AVG, MAX, DENSE_RANK)
   - Common Table Expressions (CTEs)
   - Robust Central Tendency (Percentiles / Median)
   - Outlier Handling & Quality Filtering
   - Multi-Level Partitioning & Benchmarking
==================================================================== */


/* ====================================================================
   SECTION 1: MARKET OVERVIEW & BUSINESS METRICS
==================================================================== */


/* --------------------------------------------------------------------
   QUERY 1: Remote Work Salary Premium & Distribution
   Business Question:
   Do remote positions offer a premium compared to the overall 
   market median and average?
-------------------------------------------------------------------- */

SELECT 
    CASE 
        WHEN job_work_from_home = TRUE THEN 'Remote'
        ELSE 'Non-Remote'
    END AS work_mode,
    COUNT(*) AS job_count,
    ROUND(AVG(salary_year_avg)::NUMERIC, 2) AS avg_salary,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary_year_avg)::NUMERIC, 2) AS median_salary,
    ROUND((AVG(salary_year_avg) - (SUM(SUM(salary_year_avg)) OVER () / SUM(COUNT(*)) OVER ()))::NUMERIC, 2) AS diff_from_market_avg,
    ROUND(((AVG(salary_year_avg) - (SUM(SUM(salary_year_avg)) OVER () / SUM(COUNT(*)) OVER ())) 
        / (SUM(SUM(salary_year_avg)) OVER () / SUM(COUNT(*)) OVER ()) * 100)::NUMERIC, 2) AS premium_pct
FROM data_jobs
WHERE salary_year_avg IS NOT NULL
  AND salary_year_avg > 15000
GROUP BY 
    job_work_from_home
ORDER BY avg_salary DESC;


/* --------------------------------------------------------------------
   QUERY 2: Highest Paying Countries (with Reliable Sample Size)
   Business Question:
   Which countries offer the highest compensation for data roles?
-------------------------------------------------------------------- */

SELECT
    job_country,
    COUNT(*) AS job_count,
    ROUND(AVG(salary_year_avg)::NUMERIC, 2) AS avg_salary,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary_year_avg)::NUMERIC, 2) AS median_salary
FROM data_jobs
WHERE salary_year_avg IS NOT NULL
  AND salary_year_avg > 15000
GROUP BY job_country
HAVING COUNT(*) >= 100
ORDER BY median_salary DESC
LIMIT 10;


/* --------------------------------------------------------------------
   QUERY 3: Role Demand Distribution
   Business Question:
   Which data specializations have the highest posting volume?
-------------------------------------------------------------------- */

SELECT
    job_title_short,
    COUNT(*) AS job_count,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()), 2) AS market_share_pct
FROM data_jobs
GROUP BY job_title_short
ORDER BY job_count DESC;


/* --------------------------------------------------------------------
   QUERY 4: Highest Paying Companies (Minimum 10 Listings)
   Business Question:
   Which organizations lead in compensation while maintaining active hiring?
-------------------------------------------------------------------- */

SELECT
    company_name,
    COUNT(*) AS job_count,
    ROUND(AVG(salary_year_avg)::NUMERIC, 2) AS avg_salary,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary_year_avg)::NUMERIC, 2) AS median_salary
FROM data_jobs
WHERE salary_year_avg IS NOT NULL
  AND salary_year_avg > 15000
GROUP BY company_name
HAVING COUNT(*) >= 10
ORDER BY median_salary DESC
LIMIT 10;


/* --------------------------------------------------------------------
   QUERY 5: Core Data Roles Compensation Spread
   Business Question:
   How do salary ranges and medians compare across core professions?
-------------------------------------------------------------------- */

SELECT
    job_title_short,
    COUNT(*) AS job_count,
    ROUND(MIN(salary_year_avg)::NUMERIC, 2) AS min_salary,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary_year_avg)::NUMERIC, 2) AS median_salary,
    ROUND(AVG(salary_year_avg)::NUMERIC, 2) AS avg_salary,
    ROUND(MAX(salary_year_avg)::NUMERIC, 2) AS max_salary
FROM data_jobs
WHERE salary_year_avg IS NOT NULL
  AND salary_year_avg > 15000
  AND job_title_short IN ('Data Analyst', 'Data Engineer', 'Data Scientist')
GROUP BY job_title_short
ORDER BY median_salary DESC;


/* ====================================================================
   SECTION 2: BENCHMARK & WINDOW ANALYTICS
==================================================================== */


/* --------------------------------------------------------------------
   QUERY 6: Regional vs. Global Role Benchmark
   Business Question:
   How do individual Data Analyst salaries in Turkey compare to both
   the Turkish national average and the global Data Analyst benchmark?
-------------------------------------------------------------------- */

WITH global_role_benchmark AS (
    SELECT 
        ROUND(AVG(salary_year_avg)::NUMERIC, 2) AS global_analyst_avg
    FROM data_jobs
    WHERE job_title_short = 'Data Analyst'
      AND salary_year_avg IS NOT NULL
      AND salary_year_avg > 15000
)
SELECT
    dj.company_name,
    dj.salary_year_avg,
    ROUND(AVG(dj.salary_year_avg) OVER ()::NUMERIC, 2) AS turkey_analyst_avg,
    ROUND((dj.salary_year_avg - AVG(dj.salary_year_avg) OVER ())::NUMERIC, 2) AS diff_from_turkey_avg,
    grb.global_analyst_avg,
    ROUND((dj.salary_year_avg - grb.global_analyst_avg)::NUMERIC, 2) AS diff_from_global_avg
FROM data_jobs dj
CROSS JOIN global_role_benchmark grb
WHERE dj.job_country = 'Turkey'
  AND dj.job_title_short = 'Data Analyst'
  AND dj.salary_year_avg IS NOT NULL
  AND dj.salary_year_avg > 15000
ORDER BY dj.salary_year_avg DESC;


/* --------------------------------------------------------------------
   QUERY 7: Top Employers by Role (Germany)
   Business Question:
   Who are the top 2 compensation leaders in Germany per discipline?
-------------------------------------------------------------------- */

WITH role_salary_benchmarks AS (
    SELECT
        company_name,
        job_title_short,
        salary_year_avg,
        ROUND(AVG(salary_year_avg) OVER (PARTITION BY job_title_short)::NUMERIC, 2) AS role_avg_salary,
        ROUND((salary_year_avg - AVG(salary_year_avg) OVER (PARTITION BY job_title_short))::NUMERIC, 2) AS diff_from_role_avg,
        DENSE_RANK() OVER (
            PARTITION BY job_title_short
            ORDER BY salary_year_avg DESC
        ) AS rank_in_role
    FROM data_jobs
    WHERE job_country = 'Germany'
      AND salary_year_avg IS NOT NULL
      AND salary_year_avg > 15000
      AND job_title_short IN ('Data Analyst', 'Data Engineer')
)
SELECT *
FROM role_salary_benchmarks
WHERE rank_in_role <= 2
ORDER BY
    job_title_short ASC,
    rank_in_role ASC;


/* --------------------------------------------------------------------
   QUERY 8: Upper Tier Salary Distribution (Spain)
   Business Question:
   Which Spanish postings fall within 80% or more of the top tier salary?
-------------------------------------------------------------------- */

WITH spain_calculated AS (
    SELECT
        job_title_short,
        company_name,
        salary_year_avg,
        MAX(salary_year_avg) OVER (PARTITION BY job_title_short) AS role_max_salary,
        DENSE_RANK() OVER (
            PARTITION BY job_title_short
            ORDER BY salary_year_avg DESC
        ) AS role_rank
    FROM data_jobs
    WHERE job_country = 'Spain'
      AND salary_year_avg IS NOT NULL
      AND salary_year_avg > 15000
      AND job_title_short IN ('Data Analyst', 'Data Scientist', 'Data Engineer')
),
spain_tier_analysis AS (
    SELECT
        job_title_short,
        company_name,
        salary_year_avg,
        role_max_salary,
        ROUND((salary_year_avg / role_max_salary * 100)::NUMERIC, 2) AS pct_of_max_salary,
        role_rank
    FROM spain_calculated
)
SELECT *
FROM spain_tier_analysis
WHERE pct_of_max_salary >= 80
ORDER BY
    job_title_short,
    pct_of_max_salary DESC;


/* --------------------------------------------------------------------
   QUERY 9: Cross-Country Champions (France & Germany)
   Business Question:
   What are the absolute top-paying opportunities in each category?
-------------------------------------------------------------------- */

WITH country_role_matrix AS (
    SELECT
        job_country,
        job_title_short,
        company_name,
        salary_year_avg,
        ROUND(AVG(salary_year_avg) OVER (PARTITION BY job_country, job_title_short)::NUMERIC, 2) AS segment_avg,
        ROUND((salary_year_avg - AVG(salary_year_avg) OVER (PARTITION BY job_country, job_title_short))::NUMERIC, 2) AS segment_diff,
        DENSE_RANK() OVER (
            PARTITION BY job_country, job_title_short 
            ORDER BY salary_year_avg DESC
        ) AS segment_rank
    FROM data_jobs
    WHERE job_country IN ('Germany', 'France')
      AND salary_year_avg IS NOT NULL
      AND salary_year_avg > 15000
      AND job_title_short IN ('Data Analyst', 'Data Scientist')
)
SELECT *
FROM country_role_matrix
WHERE segment_rank = 1
ORDER BY
    job_country ASC,
    job_title_short ASC;
