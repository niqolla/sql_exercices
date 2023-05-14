use Northwind
go

---- INTRODUCTORY

--1 
select * from Shippers
go

--2
select CategoryName, Description
from Categories
go

--3 
select FirstName, LastName, HireDate
from Employees
where Title='Sales Representative'
go

--4 
select FirstName, LastName, HireDate
from Employees
where Title='Sales Representative' AND Country='USA'
go

--5 
select OrderID, OrderDate
from Orders
where EmployeeID='5'
go

--6 
select SupplierID, ContactName, ContactTitle
from Suppliers
where ContactTitle != 'Marketing Manager'    -- != is the same as <>
go

--7
select * 
from Products
where ProductName LIKE '%queso%'
go

--8
select OrderID, CustomerID, ShipCountry
from Orders
where ShipCountry='France' OR ShipCountry='Belgium'
go

--9 ---------------	 WHERE [] IN ('', '', '', '', '', ...)
select OrderID, CustomerID, ShipCountry
from Orders
where ShipCountry in ('Brazil','Mexico','Argentina','Venezuela')
go

--10 
select FirstName, LastName, Title, BirthDate
from Employees
order by BirthDate asc
go


--11 --------------- CONVERT(TO_WHAT, COLUMN) 
select FirstName, LastName, Title, convert(date, BirthDate) BirthDate
from Employees
order by BirthDate asc
go

--12 
select FirstName, LastName, FullName=CONCAT(FirstName, ' ',LastName)
from Employees
go

--13 
select OrderID, ProductID, UnitPrice, Quantity, TotalPrice=(UnitPrice*Quantity)
from OrderDetails
go

--14 
select count(CustomerID)
from Customers
go

--15
select TOP 1 OrderDate 
from Orders
order by OrderDate asc
go

--15 b
select min(OrderDate)
from Orders
go

--16
select distinct Country
from Customers
go

--16b
select Country
from Customers
group by Country
go

--17
select ContactTitle, count(ContactTitle) as Counts
from Customers
group by ContactTitle
order by Counts desc
go

--18
select p.ProductID, p.ProductName, s.CompanyName
	from Products p
	left outer join Suppliers s ON p.SupplierID =s.SupplierID
go

--19 
select o.OrderID, CONVERT(date,o.OrderDate) as OrderDate, s.CompanyName
	from Orders o
	left join Shippers s on o.ShipVia = s.ShipperId
	where OrderID < 10300
go

---- INTERMEDIATE

-- 20
select comb.CategoryName, count(comb.CategoryName) as Counts
from 
(select p.CategoryID, c.CategoryName
from Products p
left join Categories c on p.CategoryID = c.CategoryID) comb
group by comb.CategoryName 
order by Counts desc
go

--21
select Country, City, count(City) as Counts
from Customers
group by Country, City
order by Counts desc
go

--22 
select ProductID, ProductName, UnitsInStock, ReorderLevel
from Products
where ReorderLevel > UnitsInStock
go

--23
select ProductID, ProductName, UnitsInStock, ReorderLevel
from Products
where ReorderLevel >= (UnitsInStock+UnitsOnOrder) AND Discontinued=0
go


--25
select top 3 ShipCountry, avg(Freight) as AverageFreight
from Orders
group by ShipCountry 
order by AverageFreight desc
go

--26
select top 3 ShipCountry, avg(Freight) as AverageFreight
from Orders
where datepart(YEAR, OrderDate) = 2015
group by ShipCountry 
order by AverageFreight desc
go

--27
Select Top 3
ShipCountry
,AverageFreight = avg(freight)
From Orders
Where
convert(date,OrderDate) between '1/1/2015' and '12/31/2015'
Group By ShipCountry
Order By AverageFreight desc
go

--28
Select Top 3
ShipCountry
,AverageFreight = avg(freight)
From Orders
Where
convert(date,OrderDate) between '2015-05-06' and '2016-05-06'
Group By ShipCountry
Order By AverageFreight desc
go

--28b 
declare @from_date date
set @from_date = (select dateadd(year,-1,convert(date,max(OrderDate))) from Orders)

declare @to_date date
set @to_date = (select convert(date,max(OrderDate)) from Orders)

Select Top 3
ShipCountry
,AverageFreight = avg(freight)
From Orders
Where
convert(date,OrderDate) between @from_date and @to_date
Group By ShipCountry
Order By AverageFreight desc
go
-- way of getting from and to dates
select dateadd(year,-1,convert(date,max(OrderDate))), convert(date,max(OrderDate))
from Orders
go

--29 
select o.EmployeeID, e.LastName, o.OrderID, p.ProductName, od.Quantity
from Orders o
left join Employees e on o.EmployeeID = e.EmployeeID
left join OrderDetails od on o.OrderID = od.OrderID
left join Products p on od.ProductID = p.ProductID
go

--30 
select CustomerID
from Customers except
select distinct CustomerID
from Orders
go

--31
select distinct CustomerID
from Customers except 
select distinct CustomerID 
from Orders
where EmployeeID = 4
go

---- ADVANCED

--32 
select * from
(select *
from OrderDetails 
where (UnitPrice*Quantity) > 10000
) a left join 
(select *
from Orders
--where datepart(year,convert(date,OrderDate))=2016
) b on a.OrderID = b.OrderID
where datepart(year,convert(date,OrderDate))=2016 
go

--33 and 34
create view total_date_customer
as
select od.OrderID, UnitPrice*Quantity-Discount*UnitPrice*Quantity as total, o.OrderDate, o.CustomerID
from OrderDetails od
left join Orders o on od.OrderID=o.OrderID
left join Customers c on o.CustomerID = c.CustomerID
go

create view total_date_customer_2016
as
select CustomerID, sum(total) as sum_of_total from total_date_customer 
where datepart(year,convert(date,OrderDate))=2016
group by CustomerID
go

select * from total_date_customer_2016
where sum_of_total >= 15000
go

--35
select EmployeeID, OrderID, OrderDate
from Orders
where Convert(date,OrderDate)=EOMONTH(OrderDate)
order by EmployeeID, OrderID
go

--37
select top 2 percent  * 
from Orders
order by NEWID()
go

--38, 39, 40 
select OrderID, count(OrderID) as Counts
from (
select o.OrderID, Quantity--, COUNT(Quantity)
from Orders o
left join OrderDetails od on o.OrderID=od.OrderID
where EmployeeID=3 AND Quantity>=60
) m
group by m.OrderID
order by Counts desc
go

--41
select *
from Orders
where RequiredDate <= ShippedDate
go

--42 till 48
select oa.EmployeeID, e.FirstName, e.LastName, 
		oa.AllOrders, isnull(o.Counts, 0) as Late,
		'Rate [%]'=isnull(round((cast(o.Counts as float)/ cast(oa.AllOrders as float) *100),2),0)
		from (
select EmployeeID, COUNT(EmployeeID) as AllOrders from Orders 
			group by EmployeeID
) oa 
left join Employees e on oa.EmployeeID=e.EmployeeID
left join (
select EmployeeID, isnull(COUNT(EmployeeID), 0) as Counts
from Orders 
where RequiredDate <= ShippedDate
group by EmployeeID 
) o on o.EmployeeID = oa.EmployeeID
order by AllOrders desc
go

--48, 49
create view ordersOf2016
as
select *
from Orders
where DATEPART(YEAR,OrderDate)=2016
go
create view categoriesOfCustomersOf206
as
select CustomerID, SUM(UnitPrice*Quantity) as total_spent
	, category=case  
		when (SUM(UnitPrice*Quantity) <1000) then 'Low'
		when (SUM(UnitPrice*Quantity) >=1000 and SUM(UnitPrice*Quantity)< 5000) then 'Medium'
		when (SUM(UnitPrice*Quantity) >= 5000 and SUM(UnitPrice*Quantity)<10000) then 'High'
		when (SUM(UnitPrice*Quantity) >10000) then 'Very High'
		end 
from ordersOf2016 o
left join OrderDetails od on o.OrderID = od.OrderID
group by CustomerID
--order by CustomerID asc
go

--50
declare @noOfCust int
set @noOfCust = (select count(*) from categoriesOfCustomersOf206)
select category 
	, count(*) as counts
	, percetage=round(cast( ( cast(count(*) as float) / @noOfCust *100 ) as float), 2)

from categoriesOfCustomersOf206
group by category
order by counts desc
go 

--51 
select *
from CustomerGroupThresholds
go
