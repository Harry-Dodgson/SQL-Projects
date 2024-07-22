-- Data Cleaning

SELECT *
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardise the Data (spellings etc.)
-- 3. Null values or Blank Values (populate if we can)
-- 4. Remove Any Columns if Necessary

# Create staging table so as not to work on the raw data

CREATE Table layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- 1. Remove Duplicates

# Partition to label duplicates (2 or more for row_num)
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

# Create CTE. Show duplicates
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

# Check company name for duplicates
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

# Just delete the duplicate row (not both). Can't delete using a CTE. Have to create another staging table with row_num then delete the duplicates.
# Create new staging table
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

# Check table
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

# populate new table
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

# Delete duplicates
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

# Check table
SELECT *
FROM layoffs_staging2;

-- 2. Standardising data. Finding issues in the data and fixing.

# Trim company column check
SELECT company, TRIM(company)
FROM layoffs_staging2;

# Update table
UPDATE layoffs_staging2
SET company = TRIM(company);

# Check industry column (blanks, nulls, different spellings, etc.)
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

# Checking crypto/crypto currency
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

# Update crypto industry
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

# Check country column
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

# Checking United States currency
SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%';

# Trim '.'
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

# Update 'United States.'
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

# Check date format
SELECT `date`
FROM layoffs_staging2;

# Update date format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

# Change date column data type
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 3. Null values or Blank Values

# Check industry for nulls and blanks
SELECT DISTINCT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

# Set blanks to Nulls
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

# Check for other rows for certain company to decide what industry it should be
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

# Select blank or null industry
SELECT t1.industry, t2.industry
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

# Update blank or null industry
UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

# Not able to update total_laid_off, percentage_laid_off, and funds_raised_millions columns as we don't have the data

-- 4. Remove Any Columns if Necessary

# No useful info in these rows for this project
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

# Delete rows
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

# Delete row_num column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;










