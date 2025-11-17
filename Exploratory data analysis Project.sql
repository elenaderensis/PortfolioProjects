-- EXPLORATORY DATA ANALYSIS

SELECT *
FROM layoffs_staging2;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1  #companies with 100% layoffs
ORDER BY total_laid_off DESC;

SELECT company, SUM(total_laid_off)  #companies with the most layoffs
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

SELECT MIN(`date`), MAX(`date`)  #see when the layoffs started and ended in the dataset
FROM layoffs_staging2;

SELECT industry, SUM(total_laid_off)  #industries hit the most and the least
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

SELECT country, SUM(total_laid_off)  #countries hit the most and the least
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

SELECT YEAR(`date`), SUM(total_laid_off)  #total layoffs per year
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 2 DESC;

SELECT stage, SUM(total_laid_off)  #business stage at the time of layoffs
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;


SELECT SUBSTRING(`date`, 1,7) AS `Month`, SUM(total_laid_off)  #total layoffs per month each year
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC;

WITH rolling_total AS  #create a CTE to calculate total layoffs per month with running total over time
(
SELECT SUBSTRING(`date`, 1,7) AS `Month`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC
)
SELECT `Month`, total_off  #use the CTE monthly totals to calculate a running total
,SUM(total_off) OVER(ORDER BY `Month`) AS rolling_total
FROM rolling_total;

#now see the rolling total of layoffs per company
SELECT company, SUM(total_laid_off) 
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

SELECT company, YEAR(`date`), SUM(total_laid_off)  #total layoffs per company per year
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

WITH company_year (company, years, total_laid_off) AS  #create this temporary table with these columns
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
)
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS ranking  #ranking restarts for each year, highest layoffs have ranking 1
FROM company_year
WHERE years IS NOT NULL
ORDER BY ranking ASC;

WITH company_year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)  #first add up all layoffs for each company each year
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), 
company_year_rank AS
(
SELECT *,  #then see the rank each year based on first CTE totals
DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM company_year
WHERE years IS NOT NULL
)
SELECT *
FROM company_year_rank
WHERE ranking <= 5;  #finally pick the top 5 companies

