/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

DECLARE @dml AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)
 
SELECT @ColumnName= ISNULL(@ColumnName + ',','') 
       + QUOTENAME(CustomerName)
	   FROM 
	   (select distinct cus.CustomerName
	    from [Sales].[Invoices] i
		inner join [Sales].[InvoiceLines] il
			on il.InvoiceID = i.InvoiceID
		inner join [Sales].[Customers] cus
			on cus.[CustomerID] = i.[CustomerID]) AS Cust
		order by CustomerName


SET @dml =
N'select convert(varchar, InvoiceMonth, 104) , ' + @ColumnName + ' from
(select datefromparts(Datepart(year, i.[InvoiceDate]), Datepart(month, i.[InvoiceDate]),1) as InvoiceMonth
        ,cus.[CustomerName] as CustomerName
		,count(distinct i.InvoiceID) as cnt
from [Sales].[Invoices] i
inner join [Sales].[InvoiceLines] il
	on il.InvoiceID = i.InvoiceID
inner join [Sales].[Customers] cus
	on cus.[CustomerID] = i.[CustomerID]
group by datefromparts(Datepart(year, i.[InvoiceDate]), Datepart(month, i.[InvoiceDate]),1), cus.[CustomerName]) as InvByMonth
pivot (sum(cnt)
for CustomerName in(' + @ColumnName + ')) AS pvt
order by InvoiceMonth;'


EXEC sp_executesql @dml