-- DATA CLEANING

SELECT *
FROM layoffs;

-- 1. Remove duplicates
-- 2. Standardise the data
-- 3. look for Null or Blank values
-- 4. Remove unnecessary columns or rows

CREATE TABLE layoffs_staging
LIKE layoffs;  #create temporary table same as layoffs without importing data to make changes without touching the raw data

SELECT *
FROM layoffs_staging;  #now will show the full table

INSERT layoffs_staging  #to populate the data from layoffs table
SELECT *
FROM layoffs;


-- 1. we don't have unique id to identify duplicates

SELECT *,  #create a row num column
ROW_NUMBER() OVER (  #function that assigns 1 on the first row and 2 on the second
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num #use backticks for date because it's a keyword in sql
FROM layoffs_staging;

WITH duplicate_cte AS  #create a CTE
(
SELECT *,
ROW_NUMBER() OVER (  #always used together, use partition by because i'm finding duplicates
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;  #because it would mean it has a duplicate

SELECT *
FROM layoffs_staging
WHERE company = 'Casper';  #to check if the company actually has a duplicate

#we can't delete from the CTE directly, so do it another way
-- copy to clipboard, create statement from layoffs_staging

CREATE TABLE `layoffs_staging2` (  #create new table
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT  #add this line
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2;  #now we have this empty table

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

DELETE  #now we can remove the duplicates
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2;  #now this is the table without duplicates


-- STANDARDISING DATA

SELECT company, TRIM(company)  #to remove unwanted spaces
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;  #order by the first column

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';  #we noticed there are crypto industries under slightly different names, but should all have the same name

UPDATE layoffs_staging2  #update to have all the same name Crypto
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry
FROM layoffs_staging2;

SELECT DISTINCT country  #to check if other columns have issues
FROM layoffs_staging2   #we noticed there are two USA column, one with period at the end, need to update
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)  #to remove any period at the end of the string
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2  #to update the table with correct syntax
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- How to change format of the date (from string to date)
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')  #first put the string and then the format, it's american format
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');  #to update with new date format

SELECT `date`
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;  #to change the data type of date into date format in the structure of the table

-- 4.
SELECT *
FROM layoffs_staging2  #to see where we dont have the industry, try to populate them
WHERE industry IS NULL
OR industry = '';

UPDATE layoffs_staging2  #to have it null instead of black, can be easier to update
SET industry = NULL
WHERE industry = '';

SELECT *  #populate where we have same company but one of them does not have industry specified, put the same industry
FROM layoffs_staging2 t1  
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry ='')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1  #will only work if there is another row with same company
JOIN layoffs_staging2 t2
	 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;  #if both of these are null probably quite useless in this case

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2  #finalised clean data without the extra row we created before
DROP COLUMN row_num;
