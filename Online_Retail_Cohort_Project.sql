

---------------------Cleaning the Data-------------------------

--Total Records = 541909
-- We need to remove the records where, InvoiceNo, CustomerID are null

--CustomerID with null records = 135080
--CustomerID with not null records = 406829


With Online_Retail as 
(
	SELECT [InvoiceNo]
		  ,[StockCode]
		  ,[Description]
		  ,[Quantity]
		  ,[InvoiceDate]
		  ,[UnitPrice]
		  ,[CustomerID]
		  ,[Country]
	  FROM [Project_Online_Retail].[dbo].[Online_Retail]
	  Where CustomerID is not null
), Quantity_Unitprice as  
(
	--Records where Quantity > 0 and UnitPrice > 0 = 397884
	Select * 
	From Online_Retail
	Where Quantity > 0 and UnitPrice > 0
), Duplicate_check as
(
	-- Checking  the Duplicates in the Data
	Select *, Row_number() over (partition by InvoiceNo, StockCode, Quantity order by InvoiceDate) as Duplicate_flag
	From Quantity_Unitprice
)
-- Duplicate records are 5215
-- Now we have all 392669 Unique records

Select * 
into #Online_retail_cleaned
From Duplicate_check
Where Duplicate_flag = 1

-- Now we have got Cleaned Data for Cohort analysis
Select * 
From #Online_retail_cleaned

-- Unique Identifer (CustomerID)
-- Initital start date (First Invoice Date)

-- Find when did a customer amde his first purchase and then make a group

Select CustomerID, 
		min(InvoiceDate) as First_purchase_date,
		DATEFROMPARTS(year(min(InvoiceDate)), month(min(InvoiceDate)), 1) as Cohort_date   --given date as 1
into #Cohort_data
From #Online_retail_cleaned
Group by CustomerID
Order by Cohort_date


Select * 
From #Cohort_data
Order by Cohort_date

--We need to create Cohort Index (No. of months that has passed since the customer first engagement)
--Now we need invoicedate from Online_retail_cleaned and Cohort_date from Cohort_data


select
	index_query.*,
	Cohort_index = year_diff * 12 + month_diff + 1
into #Cohort_Retention
from
	(
		select
			Cohort_year_months_diff.*,
			year_diff = Invoice_year - Cohort_year,
			month_diff = Invoice_month - Cohort_month
		from
			(
				select
					m.*,
					c.Cohort_Date,
					year(m.InvoiceDate) as Invoice_year,
					month(m.InvoiceDate) Invoice_month,
					year(c.Cohort_Date) Cohort_year,
					month(c.Cohort_Date) Cohort_month
				from #Online_retail_cleaned m
				left join #Cohort_data c
					on m.CustomerID = c.CustomerID
					--Order by Invoice_year, Cohort_year
			)Cohort_year_months_diff
	)index_query
--where CustomerID = 14733

-- Cohort_index = 1 means cust made the purchase in the same month as first month, 2 means the next month

--Creating the Pivot Table

Select *
into #Cohort_pivot_table
From(
	Select distinct
			CustomerID,
			Cohort_date,
			Cohort_index
	From #Cohort_Retention
) as cohort_table
pivot(
	Count(CustomerID)
	for Cohort_index In ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13])
) as pivot_table


Select *
From #Cohort_pivot_table
Order by Cohort_date