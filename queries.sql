/* ====================================================================
   DATA JOBS SALARY & MARKET ANALYSIS
   Database: PostgreSQL
   Key Concepts: CTEs, Window Functions (DENSE_RANK, AVG, MAX, MIN, COUNT),
                 Multi-Column Partitioning
   ==================================================================== */


-- --------------------------------------------------------------------
-- QUERY 1: Baseline Comparison - National Role Average vs. Individual Roles
-- Business Question: How do individual Data Analyst salaries in Turkey compare 
--                    to the overall country benchmark for that role?
-- --------------------------------------------------------------------
SELECT 
    company_name,
    salary_year_avg,
    ROUND(AVG(salary_year_avg) OVER ()::NUMERIC, 2) AS country_role_avg,
    ROUND((salary_year_avg - AVG(salary_year_avg) OVER ())::NUMERIC, 2) AS salary_diff
FROM data_jobs
WHERE job_country = 'Turkey'
  AND job_title_short = 'Data Analyst'
  AND salary_year_avg IS NOT NULL
ORDER BY salary_year_avg DESC;


-- --------------------------------------------------------------------
-- QUERY 2: Multi-Role Partitioning & Ranking (Top 2 Companies per Role)
-- Business Question: Who are the top 2 highest paying employers in Germany 
--                    for Data Analysts vs Data Engineers, and how do they compare 
--                    to role-specific averages?
-- --------------------------------------------------------------------
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
      AND job_title_short IN ('Data Analyst', 'Data Engineer')
)
SELECT 
    job_title_short,
    rank_in_role,
    company_name,
    salary_year_avg,
    role_avg_salary,
    diff_from_role_avg
FROM role_salary_benchmarks
WHERE rank_in_role <= 2
ORDER BY 
    job_title_short ASC, 
    rank_in_role ASC;


-- --------------------------------------------------------------------
-- QUERY 3: Multi-Metric Market Profile (Aggregations within Groups)
-- Business Question: Provide a macro salary profile (post count, floor, ceiling, 
--                    average) for Data Analysts in Poland & Netherlands, filtering 
--                    jobs paying above national benchmark.
-- --------------------------------------------------------------------
WITH market_profile AS (
    SELECT 
        job_country,
        company_name,
        salary_year_avg,
        COUNT(*) OVER (PARTITION BY job_country) AS country_total_postings,
        ROUND(AVG(salary_year_avg) OVER (PARTITION BY job_country)::NUMERIC, 2) AS country_avg_salary,
        ROUND((salary_year_avg - AVG(salary_year_avg) OVER (PARTITION BY job_country))::NUMERIC, 2) AS salary_diff_from_avg,
        MAX(salary_year_avg) OVER (PARTITION BY job_country) AS country_max_salary
    FROM data_jobs
    WHERE job_country IN ('Poland', 'Netherlands')
      AND salary_year_avg IS NOT NULL
      AND job_title_short = 'Data Analyst'
)
SELECT *
FROM market_profile
WHERE salary_diff_from_avg > 0
ORDER BY 
    job_country ASC, 
    salary_diff_from_avg DESC;


-- --------------------------------------------------------------------
-- QUERY 4: Ceiling Ratio Analysis (Tier Evaluation)
-- Business Question: Identify companies in Spain offering competitive salaries 
--                    within 80% or more of each role's peak market rate.
-- --------------------------------------------------------------------
WITH spain_tier_analysis AS (
    SELECT 
        job_title_short,
        company_name,
        salary_year_avg,
        MAX(salary_year_avg) OVER (PARTITION BY job_title_short) AS role_max_salary,
        ROUND(
            (salary_year_avg / MAX(salary_year_avg) OVER (PARTITION BY job_title_short) * 100)::NUMERIC, 
            2
        ) AS pct_of_max_salary,
        DENSE_RANK() OVER (
            PARTITION BY job_title_short 
            ORDER BY salary_year_avg DESC
        ) AS role_rank
    FROM data_jobs
    WHERE job_country = 'Spain'
      AND salary_year_avg IS NOT NULL
      AND job_title_short IN ('Data Analyst', 'Data Scientist', 'Data Engineer')
)
SELECT *
FROM spain_tier_analysis
WHERE pct_of_max_salary >= 80
ORDER BY 
    job_title_short ASC, 
    pct_of_max_salary DESC;


-- --------------------------------------------------------------------
-- QUERY 5: Multi-Column Partitioning (Cross-Country Role Champions)
-- Business Question: What is the highest paying job for each role across 
--                    Germany and France, compared against country-role segments?
-- --------------------------------------------------------------------
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
      AND job_title_short IN ('Data Analyst', 'Data Scientist')
)
SELECT *
FROM country_role_matrix
WHERE segment_rank = 1
ORDER BY 
    job_country ASC, 
    job_title_short ASC;
