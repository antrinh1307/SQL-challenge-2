--Q1
SELECT count(DISTINCT User_name) as number_of_users
from Library_table

--Q2
select User_name, count(*) as number_of_borrows
from Library_table
group by User_name
HAVING Count(*) >= 2

--Q3
SELECT DISTINCT User_name
from Library_table
where Book_type = 'History'
and User_name NOT IN (
    SELECT DISTINCT User_name
    FROM Library_table
    WHERE Book_type = 'Psychology'
)
--Q4
WITH History_consecutive as (
	SELECT User_name, Book_type,
      	LAG(Book_type) over(partition by User_name order by Date) Previous_book
    FROM Library_table
)
SELECT DISTINCT User_name
FROM History_consecutive
WHERE Previous_book = 'History' AND Book_type = 'History'

--Q5
select User_name, datediff(day, min(Date), max(date)) as datediff
from Library_table
group by User_name

--Q6
with salary_rank as (
  select *,
  		dense_rank() over(partition by Department_Id order by Salary desc) as rank
  from Staff_table
)
select r.Staff_id, r.Staff_name, d.Department_name, r.Salary
from Salary_rank r
left join Department_table d
on r.Department_Id = d.Department_id
where r rank = 1

--Q7
select *
from (select *,
		dense_rank() over(order by Salary desc) as rank
      FROM Staff_table
) as t
where t.rank = 5

--Q8
select u.User_Id, o.Request_date 
	round(
      sum(case when o.Status like 'cancelled%' then 1 ELSE 0 end) / count(*) * 100,
      2
      ) as Cancelled_Ratio
FROM Order_table o
inner join User_table u
on o.Client_Id = u.User_Id and u.Banned = 'No'
inner join User_table s
ON s.Driver_Id = u.User_Id
GROUP BY u.User_Id, o.Request_date

--Q9
select ID, Phone,
	case
    	when Phone REGEXP '^[0-9]{9,11}$'
        	and Phone not REGEXP '^(1800|1900|1080)'
            and (length(Phone) = 9 and left(Phone, 2) in ('04', '08'))
            then 1
        else 0
    end as Valid_phone
from Contact_table
--- Cách 2
SELECT
  ID,
  Phone,
  CASE
    WHEN ISNUMERIC(Phone) = 1 AND
	(( LEN(Phone) = 9 AND LEFT(Phone, 2) IN (‘04’, ‘08’) ) OR ( LEN(Phone) IN (10, 11) )) AND
    LEFT(Phone, 4) NOT IN (‘1800’, ‘1900’, ‘1080’) THEN 1
    ELSE 0
  END AS Valid_phone
FROM Contact_table


--Q10
with Day_table AS (
  SELECT *,
		row_number() over(order by Visit_date) as day
  FROM Visitor_table
)
select *
from Day_table d1
where No_of_visitors >= 100
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
--- Cách 2
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

