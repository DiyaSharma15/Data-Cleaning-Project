-- Data Cleaning Project

-- Steps -- 
-- 1. Remove Duplicates 
-- 2. Standardize the Data 
-- 3. Null Values or blank values 
-- 4. Remove any Unnecessary Data and Columns 

----------------------------------------------------------------------------------------------------------------------------

-- First of all, create a staging table to make changes in so, that the raw file remains untouched in case any error occurs. 
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;

----------------------------------------------------------------------------------------------------------------------------

-- 1. Remove Duplicates 

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off,
 percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- create a CTE to store the result
WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, 
total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- double check by selecting one of the records from the previous result to make sure it's a duplicate 
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- create a new table 
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off,
 percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Run a select statement to indentify the duplicate rows
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Delete the duplicate rows 
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

----------------------------------------------------------------------------------------------------------------------------

-- 2. Standardizing Data

SELECT *
FROM layoffs_staging2;

-- Remove extra spaces from the company names 
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- the industry column has 'crypto' and 'crypto currency' as seprate industries lets name 'crypto currency' as 'cryto' since it's the same thing.
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Looking at the country column
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

-- everything looks good except apparently we have some "United States" and some "United States." with a period at the end. Let's standardize this.
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

-- Fixing the date column by changing it from TEXT datatype to DATE 
SELECT *
FROM world_layoffs.layoffs_staging2;

-- use the str to date function to update this field
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

----------------------------------------------------------------------------------------------------------------------------

-- 3. Handling null values

-- Fill in nulls and blanks if possible 
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

SELECT *
FROM layoffs_staging2
WHERE company = 'airbnb';

-- change all blanks to null so that they are easier to handle
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- write a query that if there is another row with the same company name, it will update it to the non-null industry values
-- makes it easy so if there were thousands we wouldn't have to manually check them all
SELECT * 
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

----------------------------------------------------------------------------------------------------------------------------

-- 4. Remove any unnecessary columns and rows 

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete useless data 
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
