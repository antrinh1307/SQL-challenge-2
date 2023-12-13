--Q1
SELECT count(DISTINCT User_name) AS number_of_users
FROM Library_table

--Q2
SELECT User_name, count(*) AS number_of_borrows
FROM Library_table
GROUP BY User_name
HAVING Count(*) >= 2

--Q3
SELECT DISTINCT User_name
FROM Library_table
WHERE Book_type = 'History'
AND User_name NOT IN (
    SELECT DISTINCT User_name
    FROM Library_table
    WHERE Book_type = 'Psychology'
)
--Q4
WITH History_consecutive AS (
	SELECT User_name, Book_type,
      	LAG(Book_type) OVER(PARTITION BY User_name ORDER BY Date) Previous_book
    FROM Library_table
)
SELECT DISTINCT User_name
FROM History_consecutive
WHERE Previous_book = 'History' AND Book_type = 'History'

--Q5
SELECT User_name, datediff(DAY, min(Date), max(date)) AS datediff
FROM Library_table
GROUP BY User_name

--Q6
WITH salary_rank AS (
  SELECT *,
  		dense_rank() OVER(PARTITION BY Department_Id ORDER BY Salary DESC) AS rank
  FROM Staff_table
)
SELECT r.Staff_id, r.Staff_name, d.Department_name, r.Salary
FROM Salary_rank r
LEFT JOIN Department_table d
ON r.Department_Id = d.Department_id
WHERE r rank = 1

--Q7
SELECT *
FROM (select *,
		dense_rank() OVER(ORDER BY Salary DESC) AS rank
      FROM Staff_table
) AS t
WHERE t.rank = 5

--Q8
SELECT u.User_Id, o.Request_date 
	round(
      sum(CASE WHEN o.Status LIKE 'cancelled%' THEN 1 ELSE 0 END) / count(*) * 100,
      2
      ) AS Cancelled_Ratio
FROM Order_table o
INNER JOIN User_table u
ON o.Client_Id = u.User_Id AND u.Banned = 'No'
INNER JOIN User_table s
ON s.Driver_Id = u.User_Id
GROUP BY u.User_Id, o.Request_date

--Q9
SELECT ID, Phone,
	CASE
    	WHEN Phone REGEXP '^[0-9]{9,11}$'
        	AND Phone NOT REGEXP '^(1800|1900|1080)'
            AND (LENGTH(Phone) = 9 AND LEFT(Phone, 2) IN ('04', '08'))
            THEN 1
        ELSE 0
    END AS Valid_phone
FROM Contact_table
--- Method 2
SELECT
  ID,
  Phone,
  CASE
    WHEN ISNUMERIC(Phone) = 1 AND
	(( LENGTH(Phone) = 9 AND LEFT(Phone, 2) IN (‘04’, ‘08’) ) OR ( LENGTH(Phone) IN (10, 11) )) AND
    LEFT(Phone, 4) NOT IN (‘1800’, ‘1900’, ‘1080’) THEN 1
    ELSE 0
  END AS Valid_phone
FROM Contact_table


--Q10
WITH Day_table AS (
  SELECT *,
		row_number() OVER(ORDER BY Visit_date) AS day
  FROM Visitor_table
)
SELECT *
FROM Day_table d1
WHERE No_of_visitors >= 100
AND EXISTS (
        SELECT *
        FROM Day_table d2
        WHERE
            d2.day >= d1.day - 2 AND
            d2.day <= d1.day + 2 AND
            d2.No_of_visitors >= 100
        HAVING COUNT(*) >= 3
    )
ORDER BY Visit_date ASC
--- Method 2
WITH TMP AS (
	SELECT Visit_date AS CUR_DATE,
		LAG(Visit_date, 1) OVER (ORDER BY Visit_date) AS LAG1_DATE,
		LAG(Visit_date, 2) OVER (ORDER BY Visit_date) AS LAG2_DATE,
		No_of_visitors AS CUR_VISITORS,
		LAG(No_of_visitors, 1) OVER (ORDER BY Visit_date) AS LAG1_VISITORS,
		LAG(No_of_visitors, 2) OVER (ORDER BY Visit_date) AS LAG2_VISITORS
	FROM Visitor_table
),
SASTIFIED_RECORDS AS (
	SELECT CUR_DATE, LAG1_DATE, LAG2_DATE
	FROM TMP
	WHERE CUR_VISITORS >= 100 AND LAG1_VISITORS >= 100 AND LAG2_VISITORS >= 100
),
SELECT CUR_DATE
FROM SASTIFIED_RECORDS
UNION
SELECT LAG1_DATE
FROM SASTIFIED_RECORDS
UNION
SELECT LAG2_DATE
FROM SASTIFIED_RECORDS

