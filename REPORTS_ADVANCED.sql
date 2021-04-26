-- Alexandros Christou - 13Mar21
-- In this SQL Script execises RA1 - RA5 are attemped!

-- RA-1. This report examines the Gender distribution for all departments of the university.
-- The report should show the School Name, Department Name, the total number of
-- students, the total number of male students and the total number of female
-- students and the ratio (%) of female students in the department. If the latter ratio is
-- less than 20% then a new column labelled “Gender Analysis” should show
-- “Investigate” otherwise it should not show anything (i.e., “”)


-- (A) Calculation of total females by each department
WITH TotalFemaleStudents(DEPARTMENT_NAME, TotalFemales) as 

	(SELECT DISTINCT D.DEPT_NAME as Department_Name,

	COUNT (DISTINCT A.STUDENT) as Total_Female_Students

	FROM [dbo].[STUDENT_BELONG_DEPARTMENT] A

	JOIN DEPARTMENT D ON A.DEPARTMENT = D.DEPT_ID
	JOIN PERSON P ON P.PERSON_ID = A.STUDENT 
	WHERE P.GENDER = 'F'
	GROUP BY  D.DEPT_NAME
	),


-- (B) Calculation of total males by each department
	TotalMaleStudents(DEPARTMENT_NAME, TotalMales)as 
	(
	SELECT DISTINCT D.DEPT_NAME as Department_Name,

	COUNT (DISTINCT A.STUDENT) as Total_Female_Students

	FROM [dbo].[STUDENT_BELONG_DEPARTMENT] A

	JOIN DEPARTMENT D ON A.DEPARTMENT = D.DEPT_ID
	JOIN PERSON P ON P.PERSON_ID = A.STUDENT 
	WHERE P.GENDER = 'M'
	GROUP BY  D.DEPT_NAME
	),

-- (C) Calculation of total students by each department
	TotalStudents(DEPARTMENT_NAME, Total)as 
	(
	SELECT DISTINCT D.DEPT_NAME as Department_Name,

	COUNT (DISTINCT A.STUDENT) as Total_Female_Students

	FROM [dbo].[STUDENT_BELONG_DEPARTMENT] A

	JOIN DEPARTMENT D ON A.DEPARTMENT = D.DEPT_ID
	JOIN PERSON P ON P.PERSON_ID = A.STUDENT 
	GROUP BY  D.DEPT_NAME
	)

SELECT DISTINCT 
	D.SCHOOL_BELONG AS School_Name, D.DEPT_NAME as Department_Name,
	F.TotalFemales as Total_Females, M.TotalMales as Total_Males,
	S.Total as Total_Students, 
	cast (F.TotalFemales as float)/cast( S.Total as float)* 100 as FemaleStudents_Ratio,
	CASE 
		WHEN 
		((cast (F.TotalFemales as float)/cast( S.Total as float)* 100 ) <= 20.0)
		THEN 'Investigate' ELSE  '' END  as Gender_Analysis
		
	FROM [dbo].[STUDENT_BELONG_DEPARTMENT] A

	-- JOINS --
	JOIN DEPARTMENT D ON A.[DEPARTMENT] = D.DEPT_ID
	JOIN PERSON P ON P.PERSON_ID = A.STUDENT 
	JOIN TotalFemaleStudents F ON F.DEPARTMENT_NAME = D.DEPT_NAME
	JOIN TotalMaleStudents M ON M.DEPARTMENT_NAME = D.DEPT_NAME
	JOIN TotalStudents S ON S.DEPARTMENT_NAME = M.DEPARTMENT_NAME

	GROUP BY D.SCHOOL_BELONG,  D.DEPT_NAME, F.TotalFemales, M.TotalMales, S.Total
	ORDER BY FemaleStudents_Ratio




-- (RA-2) This report is similar to R8 but also creates a ranking for the academics. The rank
-- should present the same value for academics with the same teaching workload.


DECLARE @num as int
SET @num = 100
SELECT x.TUDOR, x.Total_Workload ,DENSE_RANK() OVER(ORDER BY Total_Workload DESC) as Ranking
	FROM [dbo].[AcademiWithHighestWorkload](@num) x
	




-- RA-3. This report is similar to R10 but produces both the “Risk” and “High Risk” students
-- for a specific academic period. The report should include a new column names “Risk
-- Classification” that shows Risk or High Risk according to the classification.

CREATE FUNCTION STUDENT_RISK_CLASSIFICATION (@academic_period char(7))
	RETURNS TABLE
	AS RETURN (


	SELECT A.STUDENT_ATTENDING , 
	-- CASES ..
	sum(CASE WHEN A.STUDENT_SESSION_STATUS = 'Y' THEN 1 ELSE 0 end) as Y,
		sum(CASE WHEN A.STUDENT_SESSION_STATUS  = 'N' THEN 1 ELSE 0 end) as N,
		sum(CASE WHEN A.STUDENT_SESSION_STATUS  = 'J' THEN 0 ELSE 1 end) as Total,
		(cast (sum(CASE WHEN A.STUDENT_SESSION_STATUS  = 'Y' THEN 1 ELSE 0 end) as float) / 
	 cast (sum(CASE WHEN A.STUDENT_SESSION_STATUS  = 'J' THEN 0 ELSE 1 end) as float)) *100 as Ratio,
	
	-- check if attendance's ratio and put appropriate message ..
	CASE WHEN (((cast (sum(CASE WHEN A.STUDENT_SESSION_STATUS  = 'Y' THEN 1 ELSE 0 end) as float) / 
	 cast (sum(CASE WHEN A.STUDENT_SESSION_STATUS  = 'J' THEN 0 ELSE 1 end) as float)) *100 ) > 50.00
	)
	THEN 'Risk' ELSE 'High Risk' END  as Risk_Classification

	FROM STUDENT_ATTEND_SESSION A
	WHERE A.AC_PERIOD = @academic_period
	GROUP BY A.STUDENT_ATTENDING
	HAVING ((cast (sum(CASE WHEN A.STUDENT_SESSION_STATUS  = 'Y' THEN 1 ELSE 0 end) as float) / 
	 cast (sum(CASE WHEN A.STUDENT_SESSION_STATUS  = 'J' THEN 0 ELSE 1 end) as float)) *100 ) <= 70.00
	 ORDER BY A.STUDENT_ATTENDING
	)

	SELECT DISTINCT* FROM STUDENT_RISK_CLASSIFICATION ('2015/16') S




-- (RA-4) School Enrolment Progress Report: Starting from the first academic period, the
-- report should show the enrolments of a school for each academic period and
-- calculate the difference of enrolments with the previous academic period. The
-- School must be a parameter of this report.



CREATE FUNCTION SCHOOL_ENROLLEMENT_PROGRESS (@sID tinyint)
RETURNS TABLE
AS RETURN (
	SELECT  S.ACADEMIC_PERIOD,  C.SCHOOL_ID ,
			C.NAME , COUNT (DISTINCT S.STUDENT) as Total_Number_Of_New_Enrolled_Students
		, LAG(COUNT (DISTINCT S.STUDENT)) OVER (ORDER BY S.ACADEMIC_PERIOD)  AS PREVIOUS_YEAR_ENROLLEMENTS
		, cast( cast(cast ((( COUNT (DISTINCT S.STUDENT) 
		- LAG(COUNT (DISTINCT S.STUDENT)) OVER (ORDER BY S.ACADEMIC_PERIOD)) ) / 
		cast(cast(LAG(COUNT (DISTINCT S.STUDENT)) OVER (ORDER BY S.ACADEMIC_PERIOD) as nvarchar)+'.0' as float)
		as float)*100 as int) as nvarchar)+'%'
		 AS Difference_
		 
	FROM STUDENT_ENROLLS_IN_SCHOOL S
	JOIN SCHOOL C ON C.SCHOOL_ID = S.SCHOOL

	WHERE C.SCHOOL_ID = @sID
	GROUP BY C.NAME, S.ACADEMIC_PERIOD, C.SCHOOL_ID 
	)

SELECT * FROM SCHOOL_ENROLLEMENT_PROGRESS(20)	



-- RA-5. (Bonus Question) Most Important Departments according to the pareto principle
-- (http://en.wikipedia.org/wiki/Pareto_principle). In particular, for a specific
-- academic period, the report should show all student enrolment that contribute to
-- the 80% of the total enrolment for that period. The rest of the department should
-- be displayed as “Others”.



