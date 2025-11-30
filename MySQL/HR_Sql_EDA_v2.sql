CREATE SCHEMA HR;

SELECT *
FROM employee_productivity;


-- Altering Department to Department_ID
ALTER TABLE employee_productivity
RENAME COLUMN Department TO Department_ID;

UPDATE employee_productivity
SET Department = CASE
WHEN Department = "Finance" THEN "FI-01"
WHEN Department = "HR" THEN "HR-01"
WHEN Department = "IT" THEN "IT-01"
WHEN Department = "Operations" THEN "OP-01"
WHEN Department = "Sales" THEN "SA-01"
WHEN Department = "Marketing" THEN "MA-01"
ELSE ""
END;

-- Creating Dept table for showcase of JOIN
-- Insert values to the table
CREATE TABLE Dept (
Department_ID VARCHAR(10) PRIMARY KEY,
Department_Name VARCHAR(50) NOT NULL
);

INSERT INTO Dept (Department_ID, Department_Name)
VALUES
('FI-01','Finance'),
('HR-01','HR'),
('IT-01','IT'),
('OP-01','Operations'),
('SA-01','Sales'),
('MA-01','Marketing');

-- END

SELECT *
FROM dept;

-- For checking distinct values for multiple text columns
SELECT Employee_ID, length(Employee_ID)
FROM employee_productivity
WHERE length(Employee_ID) > 6;

SELECT DISTINCT Department_Name
FROM dept;

SELECT LENGTH(Department_ID)
FROM dept
WHERE Department_ID > 5;

SELECT DISTINCT Gender
FROM employee_productivity;

SELECT LENGTH(Hire_Date)
FROM employee_productivity
WHERE LENGTH(Hire_Date) > 10;

SELECT MIN(Hire_Date), MAX(Hire_Date)
FROM employee_productivity;

SELECT MIN(Salary_USD), MAX(Salary_USD)
FROM employee_productivity;

SELECT MIN(Tenure_Years), MAX(Tenure_Years)
FROM employee_productivity;

-- Validating the Data - END

-- Checking for Duplicates
WITH dupli as (SELECT *, 
ROW_NUMBER() OVER(PARTITION BY Employee_ID, 
	Department_ID, Gender, Age, Hire_Date, Performance_Score, 
	Absences_per_Month, Salary_USD, Tenure_Years) as dupli_row
FROM employee_productivity)
SELECT *
FROM dupli
WHERE dupli_row > 1
;
-- END no duplicates


-- Start EDA
SELECT *
FROM employee_productivity;

-- Total Employee by Department with Rolling Totals and Employee Distribution Percentage
WITH total_emp AS (SELECT d2.Department_Name, COUNT(e1.Employee_ID) as total_emp
FROM employee_productivity as e1
JOIN Dept as d2
ON e1.Department_ID = d2.Department_ID
GROUP BY d2.Department_Name),
total_rt AS(
SELECT *, SUM(total_emp) OVER(ORDER BY total_emp ASC) as total_emp_RT
FROM total_emp
)
SELECT Department_Name, total_emp, total_emp_RT, 
CONCAT(ROUND((total_emp * 100 / SUM(total_emp) OVER ()), 2),"%") as distribution_perc
FROM total_rt
;

-- Average Performance Score by Age Bracket
With bracket AS (SELECT Employee_ID, Age, Performance_Score,
CASE
	WHEN Age < 32 THEN "Young (20-31)"
    WHEN Age BETWEEN 32 AND 50 THEN "Middle Age (32-50)"
    WHEN Age >= 51 Then "Old (51-65)"
END as Age_Bracket
FROM employee_productivity)
SELECT Age_Bracket, ROUND(AVG(Performance_Score), 2) as Avg_Performance_Score
FROM bracket
GROUP BY Age_Bracket
ORDER BY 2 DESC;

-- Department with highest Average Performance Score
SELECT d2.Department_Name, ROUND(AVG(e1.Performance_Score), 2) as Avg_Performance_Score
FROM employee_productivity as e1
JOIN Dept as d2
ON e1.Department_ID = d2.Department_ID
GROUP BY d2.Department_Name
ORDER BY 2 DESC;

-- Department with highest Average Absences
SELECT d2.Department_Name, SUM(e1.Absences_per_Month) as Total_Absences, 
	ROUND(AVG(e1.Absences_per_Month),2) as Avg_Absences
FROM employee_productivity as e1
JOIN Dept as d2
ON e1.Department_ID = d2.Department_ID
GROUP BY d2.Department_Name
ORDER BY 3 DESC;

-- Top 10 Highest Performing Employees
-- EMP_ID - DEPT_ID - HIRE_DATE - PERF SCORE
WITH perf_rank AS (SELECT e1.Employee_ID, d2.Department_Name, e1.Hire_Date, e1.Performance_Score,
DENSE_RANK() OVER(ORDER BY e1.Performance_Score DESC) as performance_rank
FROM employee_productivity as e1
JOIN Dept as d2
ON e1.Department_ID = d2.Department_ID)
SELECT Employee_ID, Department_Name, Hire_Date, 
Performance_Score, performance_rank
FROM perf_rank
;

-- Average Performance v Average Absences
WITH avg_perf AS (SELECT d2.Department_Name, ROUND(AVG(e1.Performance_Score ) , 2) as Avg_Performance_Score,
AVG(e1.Absences_per_Month) as Avg_Absences
FROM employee_productivity as e1
JOIN Dept as d2
ON e1.Department_ID = d2.Department_ID
GROUP BY d2.Department_Name
ORDER BY 2 DESC)
SELECT Department_Name, Avg_Performance_Score, Avg_Absences
FROM avg_perf;


-- Average Tenure Years by Department
SELECT d2.Department_Name, ROUND(SUM(e1.Tenure_Years),2) as Total_TenureYR, ROUND(AVG(e1.Tenure_Years),2) as AVG_TenureYR
FROM employee_productivity as e1
JOIN Dept as d2
ON e1.Department_ID = d2.Department_ID
GROUP BY d2.Department_Name
ORDER BY 3 DESC;

-- Top 10 Employees by Department with highest Tenure Years
WITH ranking AS (SELECT d2.Department_Name, e1.Employee_ID, e1.Tenure_Years,
DENSE_RANK() OVER(PARTITION BY d2.Department_Name ORDER BY e1.Tenure_Years DESC) as Tenure_Rank
FROM employee_productivity as e1
JOIN Dept as d2
ON e1.Department_ID = d2.Department_ID
)
SELECT Department_Name, Employee_ID, Tenure_Years, Tenure_Rank
FROM ranking
WHERE Tenure_Rank <= 10
ORDER BY 1 ASC
;

-- Top 10 Employees by Department with Highest Salary
WITH ranking AS (SELECT d2.Department_Name, e1.Employee_ID, e1.Salary_USD,
DENSE_RANK() OVER(PARTITION BY d2.Department_Name ORDER BY e1.Salary_USD DESC) as Salary_Rank
FROM employee_productivity as e1
JOIN Dept as d2
ON e1.Department_ID = d2.Department_ID
)
SELECT Department_Name, Employee_ID, Salary_USD, Salary_Rank
FROM ranking
WHERE Salary_Rank <= 10
ORDER BY 1 ASC
;

-- Average Salary by Department
SELECT d2.Department_Name, ROUND(AVG(e1.Salary_USD),2) as Avg_Salary_USD
FROM employee_productivity as e1
JOIN Dept as d2
ON e1.Department_ID = d2.Department_ID
GROUP BY d2.Department_Name
ORDER BY 2 DESC;


-- Average Salary by Age Bracket
With bracket AS (SELECT Employee_ID, Age, Salary_USD,
CASE
	WHEN Age < 32 THEN "Young (20-31)"
    WHEN Age BETWEEN 32 AND 50 THEN "Middle Age (32-50)"
    WHEN Age >= 51 Then "Old (51-65)"
END as Age_Bracket
FROM employee_productivity)
SELECT Age_Bracket, ROUND(AVG(Salary_USD), 2) as Avg_Salary_USD
FROM bracket
GROUP BY Age_Bracket
ORDER BY 2 DESC;


SELECT *
FROM employee_productivity;


-- Yearly Total Hired 2010-2025
-- Change `Year` for filter
WITH hired AS(SELECT YEAR(e1.Hire_Date) as `Year`, d2.Department_Name as Dept_Name, 
	ROUND(COUNT(e1.Hire_Date),2) as Total_Hired
FROM employee_productivity as e1
JOIN Dept as d2
ON e1.Department_ID = d2.Department_ID
GROUP BY YEAR(e1.Hire_Date), d2.Department_Name
ORDER BY 1, 2 ASC)
SELECT `Year`, Dept_Name, Total_Hired
FROM hired
WHERE `Year` = 2025
ORDER BY `Year` ASC, 3 DESC
;

-- Monthyl Total Hired 2010-2025
-- Change `Year` and `Dept_Name` for filter (Full Year and Full Dept_Name)
WITH hired AS(SELECT YEAR(e1.Hire_Date) as `Year`, MONTH(e1.Hire_Date) as MonthNUM,
	MONTHNAME(e1.Hire_Date) AS `Month`, d2.Department_Name as Dept_Name, 
	ROUND(Count(e1.Hire_Date),2) as Total_Hired
FROM employee_productivity as e1
JOIN Dept as d2
ON e1.Department_ID = d2.Department_ID
GROUP BY YEAR(e1.Hire_Date), MONTH(e1.Hire_Date), 
	MONTHNAME(e1.Hire_Date), d2.Department_Name
)
SELECT `Year`, `Month`, Dept_Name, Total_Hired
FROM hired
WHERE `Year` = 2025
AND Dept_Name = 'Operations'
ORDER BY `Year`, MonthNUM ASC, Total_Hired DESC
;

-- Yearly Total Absences 2010-2025
-- Change `Year` for filter
WITH avg_abs AS(SELECT YEAR(e1.Hire_Date) as `Year`, d2.Department_Name as Dept_Name, 
	ROUND(AVG(e1.Absences_per_Month),2) as Avg_Absences
FROM employee_productivity as e1
JOIN Dept as d2
ON e1.Department_ID = d2.Department_ID
GROUP BY YEAR(e1.Hire_Date), d2.Department_Name
ORDER BY 1, 2 ASC)
SELECT `Year`, Dept_Name, Avg_Absences
FROM avg_abs
WHERE `Year` = 2010
ORDER BY 3 DESC
;


-- MOnthly Total Absences 2010-2025
-- Change `Year` and `Dept_Name` for filter (Full Year and Full Dept_Name)
WITH avg_abs AS(SELECT YEAR(e1.Hire_Date) as `Year`, MONTH(e1.Hire_Date) as MonthNUM,
	MONTHNAME(e1.Hire_Date) AS `Month`, d2.Department_Name as Dept_Name, 
	ROUND(AVG(e1.Absences_per_Month),2) as Avg_Absences
FROM employee_productivity as e1
JOIN Dept as d2
ON e1.Department_ID = d2.Department_ID
GROUP BY YEAR(e1.Hire_Date), MONTH(e1.Hire_Date), 
	MONTHNAME(e1.Hire_Date), d2.Department_Name
ORDER BY 1,4 ASC)
SELECT `Year`, `Month`, Dept_Name, Avg_Absences
FROM avg_abs
WHERE `Year` = 2025
AND Dept_Name = 'IT'
ORDER BY `Year`, MonthNUM ASC, Avg_Absences DESC
;




-- END --






