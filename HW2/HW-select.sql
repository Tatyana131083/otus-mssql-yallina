/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/
select StockItemID,StockItemName 
from Warehouse.StockItems
where StockItemName like '%urgent%' or StockItemName like 'Animal%'
/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select s.SupplierID, s.SupplierName
from Purchasing.Suppliers s
left join Purchasing.PurchaseOrders po
on s.SupplierID = po.SupplierID
where po.PurchaseOrderID is null


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

declare @pagesize int = 100,
        @pagenum int = 11

select o.OrderID
        ,convert(varchar, o.OrderDate, 104) as [Date]
		,datename(month, o.OrderDate) as [Month]
		,datename(quarter, o.OrderDate) as [Quarter]
		,case 
		 when datepart(month, o.OrderDate) >= 1 and datepart(month, o.OrderDate) <= 4 then 1
		 when datepart(month, o.OrderDate) >= 5 and datepart(month, o.OrderDate) <= 8 then 2
		 when datepart(month, o.OrderDate) >= 9 and datepart(month, o.OrderDate) <= 12 then 3
		 end [Third of year]
		,c.CustomerName
from Sales.Orders o
inner join Sales.OrderLines ol
on o.OrderID = ol.OrderID
inner join Sales.Customers c
on o.CustomerID = c.CustomerID
where (ol.UnitPrice > 100 or ol.Quantity > 20) and ol.PickingCompletedWhen is not null
order by [Quarter], [Third of year], o.OrderDate
offset(@pagenum - 1) * @pagesize rows
fetch next @pagesize rows only


/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select dm.DeliveryMethodName, o.ExpectedDeliveryDate, s.SupplierName, p.FullName
from Purchasing.PurchaseOrders o
inner join Purchasing.Suppliers s
	on o.SupplierID = s.SupplierID
inner join Application.DeliveryMethods dm
	on o.DeliveryMethodID = dm.DeliveryMethodID
inner join Application.People p
	on o.ContactPersonID = p.PersonID  
where o.ExpectedDeliveryDate >= '20130101' and o.ExpectedDeliveryDate < '20130201'
	and dm.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight') and IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select top 10  c.CustomerName, p.FullName, o.OrderID, o.OrderDate
from Sales.Orders o
inner join Sales.Customers c
on o.CustomerID = c.CustomerID
inner join Application.People p
on o.SalespersonPersonID = p.PersonID
order by OrderDate desc, o.OrderID desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select c.CustomerID, c.CustomerName, c.PhoneNumber
from Sales.Orders o
inner join Sales.OrderLines ol
	on o.OrderID = ol.OrderID
inner join Sales.Customers c
	on o.CustomerID = c.CustomerID
inner join Warehouse.StockItems si
	on si.StockItemID = ol.StockItemID
where si.StockItemName = 'Chocolate frogs 250g'
