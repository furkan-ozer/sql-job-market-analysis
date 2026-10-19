/* ====================================================================
   GLOBAL DATA JOB MARKET & SALARY ANALYSIS
   Database: PostgreSQL

   Sections:
   1. Business Analytics
   2. Advanced SQL Analytics

   Skills Demonstrated:
   - CTEs
   - Window Functions
   - Aggregate Functions
   - DENSE_RANK()
   - Multi-Column Partitioning
   - Benchmark Analysis
   - Business Intelligence Reporting
==================================================================== */


/* ====================================================================
   BUSINESS ANALYTICS
==================================================================== */


/* --------------------------------------------------------------------
	QUERY 1: Remote Work Salary Premium Analysis

   Business Question:
   Do remote positions offer higher salaries compared to the overall
   market benchmark?
-------------------------------------------------------------------- */

WITH overall_salary AS (
SELECT 
	AVG(salary_year_avg) AS overall_avg_salary
FROM data_jobs
WHERE salary_year_avg IS NOT NULL
)
SELECT 
	CASE 
		WHEN job_work_from_home = TRUE THEN 'Remote'
		ELSE 'Non-Remote'
	END AS work_mode,
	count(*) AS job_count,
	ROUND(AVG(salary_year_avg)::NUMERIC, 2) AS avg_salary,
	ROUND((AVG(salary_year_avg) - os.overall_avg_salary)::NUMERIC, 2) AS diff_from_overall_avg,
	ROUND(((AVG(salary_year_avg) - os.overall_avg_salary) / os.overall_avg_salary * 100)::NUMERIC, 2) AS premium_pct
	FROM data_jobs dj 
	CROSS JOIN overall_salary os
	WHERE dj.salary_year_avg IS NOT NULL
	GROUP BY 
		dj.job_work_from_home,
		os.overall_avg_salary 
	ORDER BY avg_salary DESC
	
	
/* --------------------------------------------------------------------
   QUERY 2: Highest Paying Countries Analysis

   Business Question:
   Which countries offer the highest average salaries for data
   professionals?
-------------------------------------------------------------------- */
	
SELECT
    job_country,
    COUNT(*) AS job_count,
    ROUND(AVG(salary_year_avg)::NUMERIC, 2) AS avg_salary
FROM data_jobs
WHERE salary_year_avg IS NOT NULL
GROUP BY job_country
HAVING COUNT(*) >= 100
ORDER BY avg_salary DESC
LIMIT 10;


/* --------------------------------------------------------------------
   QUERY 3: Most In-Demand Data Roles Analysis

   Business Question:
   Which data roles appear most frequently in the job market?
-------------------------------------------------------------------- */
	
SELECT
    job_title_short,
    COUNT(*) AS job_count
FROM data_jobs
GROUP BY job_title_short
ORDER BY job_count DESC;
	
	
/* --------------------------------------------------------------------
   QUERY 4: Highest Paying Companies Analysis

   Business Question:
   Which companies offer the highest average salaries while maintaining
   a meaningful number of job postings?
-------------------------------------------------------------------- */	
	
SELECT
    company_name,
    COUNT(*) AS job_count,
    ROUND(AVG(salary_year_avg)::NUMERIC, 2) AS avg_salary
FROM data_jobs
WHERE salary_year_avg IS NOT NULL
GROUP BY company_name
HAVING COUNT(*) >= 10
ORDER BY avg_salary DESC
LIMIT 10;	
	
	
/* --------------------------------------------------------------------
   QUERY 5: Role-Based Salary Comparison

   Business Question:
   How do average salaries compare across major data professions?
-------------------------------------------------------------------- */	
	
SELECT
    job_title_short,
    COUNT(*) AS job_count,
    ROUND(MIN(salary_year_avg)::NUMERIC, 2) AS min_salary,
    ROUND(AVG(salary_year_avg)::NUMERIC, 2) AS avg_salary,
    ROUND(MAX(salary_year_avg)::NUMERIC, 2) AS max_salary
FROM data_jobs
WHERE salary_year_avg IS NOT NULL
	AND job_title_short IN (
        'Data Analyst',
        'Data Engineer',
        'Data Scientist'
    )
GROUP BY job_title_short
ORDER BY avg_salary DESC;

	
/* ====================================================================
   ADVANCED SQL ANALYTICS
==================================================================== */


/* --------------------------------------------------------------------
   QUERY 6: Baseline Comparison

   Business Question:
   How do individual Data Analyst salaries in Turkey compare to
   the overall benchmark?
-------------------------------------------------------------------- */	
	
SELECT
    dj.company_name,
    dj.salary_year_avg,
    ROUND(AVG(dj.salary_year_avg) OVER ()::NUMERIC, 2) AS country_role_avg,
    ROUND((dj.salary_year_avg - AVG(dj.salary_year_avg) OVER ())::NUMERIC,2) AS salary_diff
FROM data_jobs dj 
WHERE job_country = 'Turkey'
	AND dj.job_title_short = 'Data Analyst'
	AND dj.salary_year_avg IS NOT NULL
ORDER BY dj.salary_year_avg DESC
	
	
/* --------------------------------------------------------------------
   QUERY 7: Top Employers by Role Analysis

   Business Question:
   Who are the top-paying employers in Germany for Data Analysts
   and Data Engineers?
-------------------------------------------------------------------- */	
	
WITH role_salary_benchmarks AS (
SELECT
	company_name,
    job_title_short,
    salary_year_avg,
    ROUND(AVG(salary_year_avg)OVER (PARTITION BY job_title_short)::NUMERIC, 2) AS role_avg_salary,
    ROUND((salary_year_avg - AVG(salary_year_avg)OVER (PARTITION BY job_title_short))::NUMERIC, 2) AS diff_from_role_avg,
    DENSE_RANK() OVER (
            PARTITION BY job_title_short
            ORDER BY salary_year_avg DESC
    ) AS rank_in_role
FROM data_jobs
WHERE job_country = 'Germany'
	AND salary_year_avg IS NOT NULL
    AND job_title_short IN (
		'Data Analyst',
        'Data Engineer'
    	)
)
SELECT *
FROM role_salary_benchmarks
WHERE rank_in_role <= 2
ORDER BY
    job_title_short ASC,
    rank_in_role ASC;
	
	
/* --------------------------------------------------------------------
   QUERY 8: Salary Tier Analysis

   Business Question:
   Which Spanish companies are paying at least 80% of the maximum
   salary available in each role?
-------------------------------------------------------------------- */	

WITH spain_tier_analysis AS (
SELECT
	job_title_short,
    company_name,
    salary_year_avg,
    MAX(salary_year_avg)OVER (PARTITION BY job_title_short)AS role_max_salary,  
    ROUND((salary_year_avg / MAX(salary_year_avg)OVER (PARTITION BY job_title_short)* 100)::NUMERIC, 2) AS pct_of_max_salary,
        DENSE_RANK() OVER (
            PARTITION BY job_title_short
            ORDER BY salary_year_avg DESC
        ) AS role_rank
 FROM data_jobs
 WHERE job_country = 'Spain'
 	AND salary_year_avg IS NOT NULL
    AND job_title_short IN (
    	'Data Analyst',
        'Data Scientist',
        'Data Engineer'
        )
)
SELECT *
FROM spain_tier_analysis
WHERE pct_of_max_salary >= 80
ORDER BY
    job_title_short,
    pct_of_max_salary DESC;


/* --------------------------------------------------------------------
   QUERY 9: Country Role Champions Analysis

   Business Question:
   What is the highest-paying job for each role across Germany
   and France?
-------------------------------------------------------------------- */

WITH country_role_matrix AS (
SELECT
	job_country,
    job_title_short,
    company_name,
    salary_year_avg,
    ROUND(AVG(salary_year_avg)OVER (PARTITION BY job_country, job_title_short)::NUMERIC, 2) AS segment_avg,
    ROUND((salary_year_avg - AVG(salary_year_avg)OVER (PARTITION BY job_country,job_title_short))::NUMERIC, 2) AS segment_diff,
    DENSE_RANK() OVER (PARTITION BY job_country,job_title_short 
    	ORDER BY salary_year_avg DESC
        ) AS segment_rank
FROM data_jobs
WHERE job_country IN ('Germany', 'France')
	AND salary_year_avg IS NOT NULL
    AND job_title_short IN (
    	'Data Analyst',
        'Data Scientist'
        )
)
SELECT *
FROM country_role_matrix
WHERE segment_rank = 1
ORDER BY
    job_country ASC,
    job_title_short ASC;
