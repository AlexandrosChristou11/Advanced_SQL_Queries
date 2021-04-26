/*
 Alexandros Christou - 10Mar21
 In this SQL Script execises R1-R10 are attemped!
*/


-- (R-1) Report with all academic staff by department. The report should include the
-- Department Name, and Surname and First name of the academic and should be
-- sorted by the same report attributes.

 
SELECT A.ACADEMIC_ID as Academic
		, P.FNAME as FirstName, P.LNAME as LastName
		, A.WORKING_DEPARTMENT as Department
		FROM ACADEMIC A JOIN PERSON P ON A.ACADEMIC_ID = P.PERSON_ID
		ORDER BY ACADEMIC_ID ASC

-- R-2. Report with all students in alphabetical order (surname, first name). The report
-- should include the student ID (generated by the system), the student library card
-- number, Surname, First name, Gender and Email. The report should allow the
-- student to select the first letter of the Surname (e.g., all students whose surname
-- starts with the letter �A�)

CREATE FUNCTION STUDENTS_DETAILS (@letter char(1))
RETURNS TABLE
AS RETURN (
	SELECT S.STUDENT_ID AS Student_Id, S.LIBRARY_CARD_NUMBER AS Library_Card, 
	P.FNAME AS First_Name, P.LNAME as Last_Name, P.GENDER AS Gender
	, P.EMAIL As Email
	FROM STUDENT S
	JOIN PERSON P ON  cast (S.STUDENT_ID as nvarchar)= P.PERSON_ID
	WHERE P.LNAME LIKE @letter+'%'	)


		
SELECT * FROM [dbo].[STUDENTS_DETAILS]('1') A 
ORDER BY A.First_Name, A.Last_Name


-- (R-3) Report with all departments (Department Name) and the total number of academics
-- they employ, sorted by that total number in descending order
SELECT D.DEPT_ID as DepartmentID ,D.DEPT_NAME as Department, 
		COUNT(A.ACADEMIC_ID) as Total_Academics
	FROM [dbo].[DEPARTMENT] D LEFT JOIN ACADEMIC A
		ON D.DEPT_ID = A.WORKING_DEPARTMENT
		GROUP BY D.DEPT_ID, D.DEPT_NAME
		ORDER BY COUNT(A.ACADEMIC_ID) DESC



-- (R-4) Report with modules (Module Code) that are not offered for a specific academic
-- period.
CREATE FUNCTION ModulesThatAreNotOffered (@academic_period char(7))
RETURNS TABLE
AS 
	RETURN ( SELECT R.MODULE FROM RUNNING_PERIOD R WHERE R.RUNNING_PERIOD <> @academic_period)

 
 DECLARE
@academic_period as char(7)
SET @academic_period = '2015/16'
SELECT * FROM [dbo].[ModulesThatAreNotOffered] (@academic_period)


-- (R-5) Report with the timetable for a specific student for a specific period. The report
-- should include the module name, the date, start time and end time and the
-- academic staff that teaches the module. It should also denote if the session is
-- lecture, practical or otherwise. The student id and period (start and end dates)
--should be provided as parameters.


CREATE FUNCTION StudentTimetableForASpecificPeriod 
				( @student nvarchar(30), @sDate char(10), @eDate char(10) )
RETURNS TABLE
AS

	RETURN (


	SELECT DISTINCT M.MODULE_NAME, cast  (T.START_DATE as date)AS Session_Date,
		T.START_TIME AS Start_Time, t.END_TIME as End_Time , T.TYPE as Teaching_Type , 
		T.TUDOR
		FROM SESSION_ T JOIN STUDENT_ATTEND_SESSION A
		ON T.SESSION_ID = A.SESSION_ATTENDED_STUDENT
		JOIN MODULE M ON T.MODULE_CODE = M.MCODE
		WHERE A.STUDENT_ATTENDING = @student AND
		( cast (T.START_DATE as date)>= @sDate ) AND 
		( cast (T.START_DATE as date) <= @eDate ) 
	)

DECLARE @student as nvarchar(30)
SET @student = 315 

DECLARE @sDate as date
SET @sDate = '2015-10-07'

DECLARE @eDate as date
SET @eDate = '2015-10-20'
SELECT * FROM [dbo].StudentTimetableForASpecificPeriod (@student, @sDate, @eDate)




-- (R-6) Report with the timetable for a specific academic for a specific period. The report
-- should include the module name, the date, start time and end time. It should also
-- denote if the session is lecture, practical or otherwise. The academic id and period
-- (start and end dates) should be provided as parameters.

CREATE FUNCTION AcademicTimetableForAPeriod ( @academic as nvarchar(30), @sDate char(10), @eDate char(10))
RETURNS TABLE
	AS
	RETURN (
		

	SELECT  M.MODULE_NAME,  
		cast (T.START_DATE as date )AS DateOfSession, CONVERT(nvarchar,T.START_TIME, 108) AS Start_Time,
		CONVERT(nvarchar,T.END_TIME, 108) AS End_Time ,
		T.TYPE as Session_Type
		from SESSION_ T
		JOIN MODULE M ON M.MCODE = T.MODULE_CODE
		WHERE (T.TUDOR = @academic) AND
		(  ( T.START_DATE >= @sDate  ) AND  ( T.START_DATE <= @eDate ) )
	)


DECLARE @academic as nvarchar(30)
SET @academic =  'T45'

DECLARE @sDate as date
SET @sDate = '2015-10-07'

DECLARE @eDate as date
SET @eDate = '2015-10-12'

SELECT * FROM [dbo].AcademicTimetableForAPeriod(@academic, @sDate, @eDate)



-- (R-7) Report with all students (Student ID, Student Surname and First name) of a
-- programme (i.e., programme should be a parameter in the report) and the number
-- of modules that they have been enrolled.

CREATE FUNCTION StudentsInAProgramAndTotalModulesEnrolled ( @program char(4) )
RETURNS TABLE
AS
		RETURN (
	 
		SELECT A.STUDENT_ATTENDING, B.STUDIES ,COUNT (DISTINCT S.MODULE_CODE) as Total_Modules 
		FROM SESSION_ S JOIN STUDENT_ATTEND_SESSION A
		ON S.SESSION_ID = A.SESSION_ATTENDED_STUDENT
		JOIN STUDENT B ON B.STUDENT_ID = A.STUDENT_ATTENDING
		WHERE B.STUDIES LIKE @program
		GROUP BY A.STUDENT_ATTENDING, B.STUDIES
		)


DECLARE @p char(4)
SET @p = 'P123'
SELECT * FROM  [dbo].[StudentsInAProgramAndTotalModulesEnrolled] (@p)

SELECT * FROM SESSION_

-- (R-8) Report presenting the top X academics that have the highest teaching workload
-- across the whole university. Teaching workload can be calculated by summing up
-- the duration of all sessions that an academic teaches. X should be a parameter.

CREATE FUNCTION AcademiWithHighestWorkload( @top as int )
RETURNS TABLE
AS	RETURN (

	SELECT TOP (@top) t.TUDOR,  sum (cast 
	(FORMAT(DATEADD(ss,DATEDIFF(ss,cast(T.START_TIME as time),  cast(T.END_TIME as time) ),0),'hh')as int)) as Total_Workload
	FROM SESSION_ T 
	GROUP BY t.TUDOR	
	ORDER BY Total_Workload desc
	)


DECLARE @num as int
SET @num = 10
SELECT * FROM [dbo].[AcademiWithHighestWorkload](@num)


-- (R-9) Report with all academics whose teaching workload is above the average in a specific
-- academic period. The report should consist of the Academic Name and Surname,
-- his/her Department, the total workload and the average workload. The academic
-- period must be a parameter.

-- Note: It will execute despite that it takes too much time :)
-- Thank you for your understanding and patient.

-- (1) TOTAL WORKLOAD OF ALL ACADEMICS IN A SPECIFIC ACADEMIC PERIOD ..
CREATE FUNCTION GetTotalAcademicWorkload (@academic_period char(7))
RETURNS int
AS 
BEGIN
DECLARE @total int ;
 
	SET @total = ( SELECT SUM (cast 
	(FORMAT(DATEADD(ss,DATEDIFF(ss,cast(T.START_TIME as time),  cast(T.END_TIME as time) ),0),'hh')as int)) 
	FROM SESSION_ T WHERE T.AC_PERIOD LIKE @academic_period)
	RETURN @total
END;	

-- (2) AVERAGE WORKLOAD IN A SPECIFIC ACADEMIC PERIOD ...
CREATE FUNCTION GetAverageAcademicWorkload (@academic_period char(7) )
RETURNS int
AS BEGIN
	DECLARE @average int;
	SET @average = (SELECT [dbo].[GetTotalAcademicWorkload](@academic_period))
	/ (SELECT COUNT (DISTINCT A.TUDOR) FROM SESSION_ A WHERE A.AC_PERIOD LIKE (@academic_period))
	RETURN @average
END;

-- (3) EXECUTES ACADEMIC WHO HAVE MORE HIGHER WORKLOAD
--		FROM THE AVERAGE WORKLOAD IN THAT ACADEMIC YEAR ..

CREATE FUNCTION AcademicsWithHigherWorkloadFromAverage (@academic_period char(7))
RETURNS TABLE
	AS RETURN (
		
				
			SELECT T.AC_PERIOD ,T.TUDOR, P.FNAME, P.LNAME, A.WORKING_DEPARTMENT,
	
			sum (cast 
			(FORMAT(DATEADD(ss,DATEDIFF(ss,cast(T.START_TIME as time),
			cast(T.END_TIME as time) ),0),'hh')as int)) as Academic_Total_Workload,

			(SELECT [dbo].[GetTotalAcademicWorkload] (@academic_period)) as Total_Workload,

			(SELECT [dbo].[GetAverageAcademicWorkload] (@academic_period))as Average_Workload

			FROM SESSION_ T JOIN PERSON P ON T.TUDOR = P.PERSON_ID
			JOIN ACADEMIC A ON A.ACADEMIC_ID = P.PERSON_ID
			WHERE T.AC_PERIOD = @academic_period
			GROUP BY t.TUDOR, p.FNAME, p.LNAME, A.WORKING_DEPARTMENT , T.AC_PERIOD
			HAVING 
				sum (cast 
			(FORMAT(DATEADD(ss,DATEDIFF(ss,cast(T.START_TIME as time),
			cast(T.END_TIME as time) ),0),'hh')as int))  
			>= 
			(SELECT [dbo].[GetAverageAcademicWorkload] (@academic_period))


	)

SELECT * FROM [dbo].[AcademicsWithHigherWorkloadFromAverage] ('2015/16')



-- (R-10) Report with all students that are at Risk (see Student Support office) for a specific
-- academic period. The academic period must be a parameter.


	CREATE FUNCTION STUDENTS_AT_RISK (@academic_period char(7))
	RETURNS TABLE
	AS RETURN (
	SELECT A.STUDENT_CODE , 
	sum(CASE WHEN A.ATTENDANCE = 'Y' THEN 1 ELSE 0 end) as Y,
		sum(CASE WHEN A.ATTENDANCE  = 'N' THEN 1 ELSE 0 end) as N,
		sum(CASE WHEN A.ATTENDANCE  = 'J' THEN 0 ELSE 1 end) as Total,
		(cast (sum(CASE WHEN A.ATTENDANCE  = 'Y' THEN 1 ELSE 0 end) as float) / 
	 cast (sum(CASE WHEN A.ATTENDANCE  = 'J' THEN 0 ELSE 1 end) as float)) *100 as Ratio
		
	FROM attendance A
	WHERE A.ACADEMIC_PERIOD = @academic_period
	GROUP BY A.STUDENT_CODE
	HAVING ((cast (sum(CASE WHEN A.ATTENDANCE  = 'Y' THEN 1 ELSE 0 end) as float) / 
	 cast (sum(CASE WHEN A.ATTENDANCE  = 'J' THEN 0 ELSE 1 end) as float)) *100 ) <= 70.00
	)
	SELECT * FROM STUDENTS_AT_RISK ('2015/16')
