create database bi_project
go
use bi_project;
go
------------------------------------------------------------------------------------
-- Creating the first table:
-- Sale table:

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
FROM 'C:\Users\Asus\Desktop\bi_exam\Table_1.csv'
WITH
(
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
)
------------------------------------------------------------------------------------
-- We do the process above for the second table:
--Sale Profit

create table sale_profit(
Product varchar(3) primary key,
ProfitRatio varchar(3)
)
go
BULK INSERT sale_profit
FROM 'C:\Users\Asus\Desktop\bi_exam\Table_2.csv'
WITH
(
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',   
    TABLOCK
)
go

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

-- Question_1: Total Sale

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

select sum(final_price) 
from sale_table
------------------------------------------------------------------------------------

-- Question_2: Number of distinct customers

select count(distinct(customer)) as count_customers 
from sale_table
------------------------------------------------------------------------------------

-- Question_3: Totald sale by Product

select Product, sum(final_price)
from sale_table
group by Product
------------------------------------------------------------------------------------

-- Question_4: customers who have at least an invoice of more than 1500

select Customer, sum(final_price) monetary, count(OrderID) num_orders, sum(Quantity) num_quantity 
from sale_table 
where Customer in (
	select distinct(Customer) 
	from sale_table 
	where final_price > 1500
	)
group by Customer
------------------------------------------------------------------------------------

-- Question_5: Profit

declare @total_sale_no_profit decimal(8,2) = (select sum(Quantity * UnitPrice) from sale_table)
declare @total_sale_with_profit decimal(8,2) = (select sum(final_price) from sale_table)
select @total_sale_with_profit - @total_sale_no_profit as Profit
select (@total_sale_no_profit/ @total_sale_with_profit) * 100 as Profit_percentage
------------------------------------------------------------------------------------

-- Question_6: Counting customers' each day purchase as one

with selected as(
select Date, Customer, count(*) as count_
from sale_table
group by Date, Customer
)
select count(*) distinct_customers from selected
------------------------------------------------------------------------------------

-- Question_7: personnel chart
-- Unsolved

create table personnel (
id tinyint primary key ,
name varchar(10),
manager varchar(10) null,
manager_id varchar(4) null
)

go

BULK INSERT personnel
FROM 'C:\Users\Asus\Desktop\bi_exam\Table_3.csv'
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
select p_1.id, p_1.name, p_1.manager_id as mg_1, p_2.manager_id as mg_2, p_3.manager_id as mg_3, p_4.manager_id as mg_4, p_5.manager_id as mg_5, p_6.manager_id as mg_6 
from personnel p_1
left join personnel p_2
on p_1.manager_id = p_2.id
left join personnel p_3
on p_2.manager_id = p_3.id
left join personnel p_4
on p_3.manager_id = p_4.id
left join personnel p_5
on p_4.manager_id = p_5.id
left join personnel p_6
on p_5.manager_id = p_6.id


