----------------------------------
--Ahan_online entrance exam (2023)|
----------------------------------
create database Ahan_online;
go
use Ahan_online;
go
------------------------------------------------------------------------------------
-- Creating the first table (sale_table):

create table sale_table(
SalesID int primary key identity(1,1),
OrderID int,
Customer varchar(3),
Product varchar(3),
Date tinyint,
Quantity tinyint,
UnitPrice smallint
)

-- Then we put our three tables into three different Excel files, to be able to bulk insert them into SQL.
-- Now we bulk insert the first table as below:

BULK INSERT sale_table
FROM 'D:\Work_Space\Exams\Ahan_online\Table_1.csv'
WITH
(
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
)

------------------------------------------------------------------------------------
-- We do the process above for the second table (sale_profit):

create table sale_profit(
Product varchar(3) primary key,
ProfitRatio varchar(3)
)
go
BULK INSERT sale_profit
FROM 'D:\Work_Space\Exams\Ahan_online\Table_2.csv'
WITH
(
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
)


-- Now we do some cleansing, and setting new datatype:

update sale_profit
set ProfitRatio = REPLACE(ProfitRatio, '%', '')
go
alter table sale_profit alter column ProfitRatio decimal(4,2)  --setting new datatype as integer instead of char-based datatype
go
update sale_profit
set ProfitRatio = (ProfitRatio / 100)
go
insert into sale_profit values('P6', 0.1)
go
alter table sale_table add foreign key(Product) references sale_profit(Product) --Building connection with 'sale_table'
------------------------------------------------------------------------------------

-- Question_1: Caculating the total sale

create function total_sale_function(@product varchar(3), @quantity tinyint, @unitprice smallint)
returns decimal(6,2) 
as
begin
   declare @ratio decimal(4,2);
   select  @ratio = ProfitRatio
   from sale_profit
   where Product = @product;
   return @quantity * (@unitprice + @unitprice * @ratio) --this function is the total sale value, with applying the profit values
end;

alter table sale_table add final_price as dbo.total_sale_function(Product, Quantity, UnitPrice) --adding computed column using function above

select sum(final_price) as total_sale
from sale_table
------------------------------------------------------------------------------------

-- Question_2: calculating the umber of distinct customers

select count(distinct(customer)) as distinct_customers 
from sale_table
------------------------------------------------------------------------------------

-- Question_3: calculating the total sale by Product

select Product, sum(final_price) as total_sale
from sale_table
group by Product
------------------------------------------------------------------------------------

-- Question_4: Finding customers who have at least an invoice of more than 1500

select distinct Customer from sale_table
group by Customer, OrderID
having sum(final_price) > 1500
------------------------------------------------------------------------------------

-- Question_5: Calculating the Profit

declare @total_sale_no_profit decimal(8,2) = (select sum(Quantity * UnitPrice) from sale_table)
declare @total_sale_with_profit decimal(8,2) = (select sum(final_price) from sale_table)
declare @profit decimal(8,2) = @total_sale_with_profit - @total_sale_no_profit
print 'The Profit: ' + cast(@profit as varchar(8))
print 'Profit Percentage: ' + cast(cast(((@profit/@total_sale_no_profit) * 100) as decimal(8, 2)) as varchar(8))

------------------------------------------------------------------------------------

-- Question_6: Counting customers' each day purchase as one

with selected as(
select [Date], Customer, count(distinct OrderID) as count_
from sale_table
group by Date, Customer
)
select date, count(*) distinct_customers from selected
group by [Date] with rollup

------------------------------------------------------------------------------------

-- Question_7: Creating a personnel chart

create table personnel (
id tinyint primary key ,
name varchar(10),
manager varchar(10) null,
manager_id varchar(4) null
)

go

BULK INSERT personnel
FROM 'D:\Work_Space\Exams\Ahan_online\Table_3.csv'
WITH
(
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
)

update personnel set manager_id = null where manager_id = 'NULL'
go
update personnel set manager = null where manager = 'NULL'
go
alter table personnel alter column manager_id tinyint null
go

with r_cte as(		--In this "Personnel chart", 'levels_' and 'head_manager_id' for each employee are displayed.	
	select *, 0 as [level], id as boss_id from personnel where [manager_id] is null  --***or 'where [id] = 1', to display only from specific node.
	UNION ALL
	select p.*, [level] + 1, t.boss_id as boss_id from personnel as p 
	inner join r_cte as t
		on p.manager_id = t.id)
select id, [name], manager_id, [level], case
	when boss_id = id then null
	else boss_id
	end as head_manager_id
from r_cte

------------------------------------------
