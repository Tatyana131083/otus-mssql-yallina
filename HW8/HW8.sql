/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID
, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, 
IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

DECLARE @xmlDocument XML;

SELECT @xmlDocument = BulkColumn
FROM OPENROWSET (BULK 'C:\Users\yalli\Repository\otus-sqlserver\otus-mssql-yallina\HW8\StockItems.xml'
                 , SINGLE_CLOB) as t

SELECT @xmlDocument as [@xmlDocument];


--OPENXML
DECLARE @docHandle INT;
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument;

SELECT @docHandle AS docHandle;



SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item') --путь к строкам
WITH ( 
	[StockItemName] NVARCHAR(100)  '@Name', -- атрибут
	[SupplierID] INT 'SupplierID', -- элемент
	[UnitPackageID] INT 'Package/UnitPackageID',
	[OuterPackageID] INT 'Package/OuterPackageID',
	[QuantityPerOuter] INT 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] DECIMAL(18,3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] INT 'LeadTimeDays',
	[IsChillerStock] BIT 'IsChillerStock',
	[TaxRate] DECIMAL(18,3) 'TaxRate',
	[UnitPrice] DECIMAL(18,2) 'UnitPrice')


EXEC sp_xml_removedocument @docHandle;


--XQuery

SELECT 
    [StockItemName] = t.Item.value('(@Name)[1]', 'NVARCHAR(100)')
    ,[SupplierID] = t.Item.value('(SupplierID)[1]', 'INT')
	,[UnitPackageID] = t.Item.value('(Package/UnitPackageID)[1]', 'INT')
	,[OuterPackageID] = t.Item.value('(Package/OuterPackageID)[1]', 'INT')
	,[QuantityPerOuter] = t.Item.value('(Package/QuantityPerOuter)[1]', 'INT')
	,[TypicalWeightPerUnit] = t.Item.value('(Package/TypicalWeightPerUnit)[1]', 'DECIMAL(18,3)')
	,[LeadTimeDays] = t.Item.value('(LeadTimeDays)[1]', 'INT')
	,[IsChillerStock] = t.Item.value('(IsChillerStock)[1]', 'BIT')
	,[TaxRate]  = t.Item.value('(TaxRate)[1]', 'DECIMAL(18,3)')
	,[UnitPrice] = t.Item.value('(UnitPrice)[1]', 'DECIMAL(18,2)')
into #StockItems_For_Update
FROM @xmlDocument.nodes('/StockItems/Item') AS t(Item);



MERGE [Warehouse].[StockItems] AS Target
USING #StockItems_For_Update AS Source
    ON (Target.[StockItemName] = Source.[StockItemName])
WHEN MATCHED 
    THEN UPDATE 
        SET Target.[SupplierID] = Source.[SupplierID],
		Target.[UnitPackageID] = Source.[UnitPackageID],
		Target.[OuterPackageID] = Source.[OuterPackageID],
		Target.[QuantityPerOuter] = Source.[QuantityPerOuter],
		Target.[TypicalWeightPerUnit] = Source.[TypicalWeightPerUnit],
		Target.[LeadTimeDays] = Source.[LeadTimeDays],
		Target.[IsChillerStock] = Source.[IsChillerStock],
		Target.[TaxRate] = Source.[TaxRate],
		Target.[UnitPrice] = Source.[UnitPrice]
WHEN NOT MATCHED 
    THEN INSERT (StockItemName, [SupplierID], [UnitPackageID],[OuterPackageID], [LeadTimeDays], 
		[QuantityPerOuter], [IsChillerStock], [TaxRate], [UnitPrice], [TypicalWeightPerUnit], [LastEditedBy])
        VALUES (Source.StockItemName, Source.[SupplierID], Source.[UnitPackageID],Source.[OuterPackageID], Source.[LeadTimeDays], 
		Source.[QuantityPerOuter], Source.[IsChillerStock], Source.[TaxRate], Source.[UnitPrice],  Source.[TypicalWeightPerUnit], 1)
OUTPUT deleted.*, $action, inserted.*;



--227
/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

SELECT [StockItemName] as [@name] 
    ,[SupplierID]  
	,[UnitPackageID] as [Package/UnitPackageID] 
	,[OuterPackageID] as [Package/OuterPackageID]
	,[QuantityPerOuter] as [Package/QuantityPerOuter]
	,[TypicalWeightPerUnit] as [Package/TypicalWeightPerUnit]
	,[LeadTimeDays]  
	,[IsChillerStock]  
	,[TaxRate]   
	,[UnitPrice]  
FROM [Warehouse].[StockItems]
FOR XML PATH('Item'), ROOT('StockItems')


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select StockItemID
      ,StockItemName
       ,JSON_VALUE(CustomFields, '$.CountryOfManufacture') as CountryOfManufacture
	   ,JSON_VALUE(CustomFields, '$.Tags[0]') as FirstTag
from Warehouse.StockItems

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


select StockItemID
      ,StockItemName
	  ,CustomFields
from Warehouse.StockItems as i
outer apply openjson(CustomFields, '$.Tags') t
where t.value = N'Vintage'



