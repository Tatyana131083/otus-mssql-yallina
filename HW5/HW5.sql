/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

with invByDate as
(select i.InvoiceDate, sum(il.[Quantity]*il.[UnitPrice]) sales, EOMONTH(i.InvoiceDate) endOfMonth
        
from [Sales].[Invoices] i
inner join [Sales].[InvoiceLines] il
	on il.InvoiceID = i.InvoiceID
where InvoiceDate >= '20150101'
group by  i.InvoiceDate)
select InvoiceDate, (select sum(sales)
                     from invByDate as invByDate2
					 where  invByDate2.InvoiceDate <=  invByDate.endOfMonth
					 )
from  invByDate order by InvoiceDate




/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

with invByDate as
(select i.InvoiceDate, sum(il.[Quantity]*il.[UnitPrice]) sales, EOMONTH(i.InvoiceDate) endOfMonth
from [Sales].[Invoices] i
inner join [Sales].[InvoiceLines] il
	on il.InvoiceID = i.InvoiceID
where InvoiceDate >= '20150101'
group by  i.InvoiceDate)
select *, sum(sales)over(order by endOfMonth)
from  invByDate order by InvoiceDate

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/
;with invByMnth as
(select datename(month, i.InvoiceDate) as [monthName]
        ,month(i.InvoiceDate) as [monthNum]
		,st.[StockItemName]
		,sum(il.[Quantity]) as qnt
from [Sales].[Invoices] i
inner join [Sales].[InvoiceLines] il
	on il.InvoiceID = i.InvoiceID
inner join [Warehouse].[StockItems] st
	on st.[StockItemID] = il.[StockItemID]
where InvoiceDate >= '20160101' and InvoiceDate < '20170101'
group by datename(month, i.InvoiceDate),month(i.InvoiceDate), st.[StockItemName])
select [monthName], [StockItemName], [qnt]
from (select [monthName],[monthNum], [StockItemName], [qnt],
             row_number()over(partition by [monthNum] order by qnt desc) as rowNum
      from invByMnth
      ) as res
where res.rowNum < 3
order by [monthNum]


/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select  [StockItemID]
       ,[StockItemName]
	   ,[Brand]
	   ,[UnitPrice]
	   ,row_number()over(partition by left([StockItemName], 1) order by [StockItemName]) as rowNmb
	   ,count(*)over() countAll
	   ,count(*)over(partition by left([StockItemName], 1)) countLetter
	   ,lead(StockItemID)over(order by [StockItemName]) as nextStockItemID
	   ,lag(StockItemID)over(order by [StockItemName]) as prevStockItemID
	   ,lag([StockItemName], 2, 'no item')over(order by [StockItemName]) as prevStockItemID_2 
	   ,ntile(30)over(order by [TypicalWeightPerUnit]) as nmbGroup
from [Warehouse].[StockItems] 
order by [StockItemName]
/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/
select [PersonID]
	   ,[FullName]
	   ,CustomerID
	   ,CustomerName
	   ,InvoiceDate
	   ,sum(summ) summ
from (
	select p.[PersonID]
		  ,p.[FullName]
		  ,cus.CustomerID
		  ,cus.CustomerName
		  ,dense_rank()over(partition by p.[PersonID]order by i.[InvoiceDate] desc, i.[InvoiceID] desc) dnsRank
		  ,i.[InvoiceID]
		  ,i.[InvoiceDate]
		  ,(il.Quantity * il.UnitPrice) summ
	from [Sales].[Invoices] i
	inner join [Sales].[InvoiceLines] il
		on il.InvoiceID = i.InvoiceID
	inner join [Sales].[Customers] cus
		on cus.[CustomerID] = i.[CustomerID]
	inner join [Application].[People] p
		on p.[PersonID] = i.[SalespersonPersonID]) tab
where dnsRank = 1
group by [PersonID]
	   ,[FullName]
	   ,CustomerID
	   ,CustomerName
	   ,InvoiceDate


/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select  CustomerID
	   ,CustomerName
	   ,StockItemID
	   ,max(InvoiceDate) invDate
	   ,price
from (
	select 
		   cus.CustomerID
		  ,cus.CustomerName
		  ,dense_rank()over(partition by cus.CustomerID order by il.UnitPrice desc,il.StockItemID) rnk
		  ,il.[StockItemID]
		  ,i.[InvoiceDate]
		  ,il.UnitPrice price
	from [Sales].[Invoices] i
	inner join [Sales].[InvoiceLines] il
		on il.InvoiceID = i.InvoiceID
	inner join [Sales].[Customers] cus
		on cus.[CustomerID] = i.[CustomerID]
) tab
where rnk < 3
group by CustomerID
	   ,CustomerName
	   ,StockItemID
	   ,price
order by CustomerID

/*Добрый день, в 5 задании правильнее будет использовать группировку и подсчет сумму внутри подзапроса и вместо dense_rank лучше row_number:
select [PersonID]
,[FullName]
,CustomerID
,CustomerName
,InvoiceDate
, summ
from (
select p.[PersonID]
,p.[FullName]
,cus.CustomerID
,cus.CustomerName
,row_number() over(partition by p.[PersonID]order by i.[InvoiceDate] desc) dnsRank
,i.[InvoiceDate]
,sum(il.Quantity * il.UnitPrice) summ
from [Sales].[Invoices] i
inner join [Sales].[InvoiceLines] il
on il.InvoiceID = i.InvoiceID
inner join [Sales].[Customers] cus
on cus.[CustomerID] = i.[CustomerID]
inner join [Application].[People] p
on p.[PersonID] = i.[SalespersonPersonID]
group by [PersonID]
,[FullName]
,cus.CustomerID
,CustomerName
,InvoiceDate) tab
where dnsRank = 1
ORDER BY [FullName], [InvoiceDate] DESC*/
