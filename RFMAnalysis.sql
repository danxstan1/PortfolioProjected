-- Inspecting Data

select *
from [dbo].[sales_data_sample]

-- Checking unique values
select distinct status from sales_data_sample -- potential plotting 
select distinct YEAR_ID from sales_data_sample
select distinct PRODUCTLINE from sales_data_sample -- potential plotting 
select distinct COUNTRY from sales_data_sample -- potential plotting 
select distinct DEALSIZE from sales_data_sample --  potential plotting 
select distinct TERRITORY from sales_data_sample -- potential plotting 
select distinct MONTH_ID from sales_data_sample
WHERE YEAR_ID = 2005

-- ANALYSIS
-- Let's start by grouping sales by productline

SELECT PRODUCTLINE, sum(sales) as Revenue
FROM sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

SELECT YEAR_ID, sum(sales) as Revenue
FROM sales_data_sample
GROUP BY YEAR_ID
ORDER BY 2 DESC -- we notice that 2005 has unusally low revenue for the year, maybe they didnt operate for the full year?

select distinct MONTH_ID from sales_data_sample
WHERE YEAR_ID = 2005 -- confirms our suspicions, as they only operated from jan to may

SELECT DEALSIZE, sum(sales) as Revenue
FROM sales_data_sample
GROUP BY DEALSIZE
ORDER BY 2 DESC

-- what was the best month for sales in a specific year? How much was earned that month?
SELECT MONTH_ID, sum(sales) as Revenue, count(ORDERNUMBER) AS frequency
FROM sales_data_sample
WHERE year_ID = 2004 -- change year to see the rest
GROUP BY MONTH_ID
ORDER BY 2 DESC

-- November seems to be the best month, what product do they sell in November? Classic cars?
SELECT MONTH_ID, PRODUCTLINE, sum(sales) as Revenue, count(ORDERNUMBER) AS frequency
FROM sales_data_sample
WHERE year_ID = 2004 and MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC


/* RFM - Recency-Frequency-Monetary

An indexing technique that uses past purchase behaviour to segment customers
An RFM report is a way of segmenting customers using 3 key metrics
Recency - how long ago was their last purchase - (last order date)
Frequency - how often they purchase - (count of total orders)
Monetary value - how much they spent - (total spend)

*/

-- Who is our best customer (this could be best answered with RFM)
DROP TABLE IF EXISTS #rfm;
with rfm as
(
SELECT CUSTOMERNAME,
	   sum(sales) MonetaryValue,
	   avg(sales) AvgMonetaryValue,
	   count(ORDERDATE) Frequency,
	   max(ORDERDATE) last_order_date,
	   (select max(ORDERDATE) from sales_data_sample) max_order_date,
	   DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from sales_data_sample)) Recency
FROM sales_data_sample
GROUP BY CUSTOMERNAME
),
rfm_calc as
(
SELECT *,
NTILE(4) over (ORDER BY Recency desc) rfm_recency, --the closer the order date to the max order date, the higher the "bucket" value from NTILE
NTILE(4) over (ORDER BY Frequency) rfm_frequency,
NTILE(4) over (ORDER BY AvgMonetaryValue) rfm_monetary
from rfm r
)
SELECT *, rfm_frequency+rfm_recency+rfm_monetary as rfm_cell,
cast(rfm_recency as varchar) + cast(rfm_frequency as varchar)+ cast(rfm_monetary as varchar) as rfm_cell_string
into #rfm
from rfm_calc c

Select CUSTOMERNAME, rfm_recency,rfm_frequency,rfm_monetary,
CASE
        when rfm_cell BETWEEN 0 AND 4 THEN 'low value'
		when rfm_cell BETWEEN 5 AND 8 THEN 'medium value'
		when rfm_cell BETWEEN 9 AND 11 THEN 'high value'
		when rfm_cell = 12 THEN 'loyal'
end
from #rfm
