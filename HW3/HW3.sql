/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

select p.PersonID, p.FullName
from Application.People p
where p.IsSalesperson = 1
	and not exists (select *
                  from [Sales].[Orders] o
				  where o.SalespersonPersonID = p.PersonID
					and o.OrderDate = '20150704')

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

select st.StockItemID, st.StockItemName, st.UnitPrice
from [Warehouse].[StockItems] st
where st.UnitPrice = (select min(st2.UnitPrice) from [Warehouse].[StockItems] st2)

select st.StockItemID, st.StockItemName, st.UnitPrice
from [Warehouse].[StockItems] st
where st.UnitPrice <= ALL (select st2.UnitPrice from [Warehouse].[StockItems] st2)


/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/
select c.CustomerID, c.CustomerName
from [Sales].[Customers] c
where c.CustomerID in ( select top 5 ct.CustomerID
						from Sales.CustomerTransactions ct
						order by  ct.TransactionAmount desc)

;with max_tran as
(select top 5 ct.CustomerID
from Sales.CustomerTransactions ct
order by  ct.TransactionAmount desc)
select c.CustomerID, c.CustomerName from [Sales].[Customers] c
where exists (select m.CustomerID from max_tran as m where m.CustomerID = c.CustomerID)



/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

select distinct ci.CityID, ci.CityName, p.FullName
from [Sales].[Invoices] i
join [Sales].[Customers] cu
	on cu.CustomerID = i.CustomerID
join [Application].[Cities] ci
	on cu.DeliveryCityID = ci.CityID
join [Sales].[InvoiceLines] il
	on il.[InvoiceID] = i.[InvoiceID]
join [Application].[People] p
	on p.PersonID = i.PackedByPersonID
where il.StockItemID in (select top 3 si.StockItemID
                        from [Warehouse].[StockItems]  si
                        order by  si.UnitPrice desc)
order by ci.CityID


