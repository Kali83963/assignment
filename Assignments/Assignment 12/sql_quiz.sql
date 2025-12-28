
---  List top 5 customers by total order amount.
SELECT TOP 5  c.CustomerID ,c.Name , SUM(sa.TotalAmount) as TotalSpend from Customer as c
JOIN SalesOrder as sa ON c.CustomerID = sa.CustomerID 
GROUP BY c.CustomerID , c.Name
ORDER BY SUM(sa.TotalAmount);


-- Find the number of products supplied by each supplier.
with cte as (
SELECT s.SupplierID , s.Name ,COUNT(inv.ProductId) as ProductCount 
FROM Supplier as s
LEFT JOIN PurchaseOrder as po ON po.SupplierID = s.SupplierID
LEFT JOIN Shipment as sh ON sh.OrderID = po.OrderID
LEFT JOIN Warehouse as wh ON sh.WarehouseID = wh.WarehouseID
LEFT JOIN Inventory as inv ON wh.WarehouseID = inv.WarehouseID
GROUP BY s.SupplierID , s.Name)

select * from 
cte
WHERE ProductCount > 10

--- Identify products that have been ordered but never returned.


SELECT *
FROM Product as pd
FULL OUTER JOIN SalesOrderDetail as sord ON pd.ProductID = sord.ProductID 
FULL OUTER JOIN Returns as re ON re.OrderID = sord.OrderID
FULL OUTER JOIN ReturnDetail as red ON red.ReturnID = re.ReturnID

SELECT * from ReturnDetail;



---  For each category, find the most expensive product.
WITH RankedProducts AS (
    SELECT
        P.Name,
        P.Price,
        C.Name as CategoryName,
		C.CategoryID as CategoryID,
        DENSE_RANK() OVER (
            PARTITION BY C.CategoryID
            ORDER BY P.Price DESC
        ) AS PriceRank
    FROM
        Product P
    INNER JOIN
        Category C ON P.CategoryID = C.CategoryID
)
SELECT
CategoryID
    CategoryName,
    Name,
    Price
FROM
    RankedProducts
WHERE
    PriceRank = 1
ORDER BY
    CategoryName;



---- List all sales orders with customer name, product name, category, and supplier.
---- For each sales order, display:
---- OrderID, CustomerName, ProductName, CategoryName, SupplierName, and Quantity.

SELECT S.OrderID, C.Name AS CustomerName , P.Name AS ProductName, CA.Name AS CategoryName, SOD.Quantity AS Quantity , SU.Name AS SupplierName
FROM SalesOrder as S
JOIN SalesOrderDetail as SOD On S.OrderID = SOD.OrderID
JOIN Product as P on SOD.ProductID = P.ProductID
JOIN PurchaseOrderDetail As POD on P.ProductID = POD.ProductID
JOIN PurchaseOrder AS PO On PO.OrderID = POD.OrderID
JOIN Supplier AS SU On SU.SupplierID = PO.SupplierID
JOIN Category as CA on P.CategoryID = CA.CategoryID
JOIN Customer as C on S.CustomerID = C.CustomerID


-- Q6. Find all shipments with details of warehouse, manager, and products shipped.
-- Display: ShipmentID, WarehouseName, ManagerName, ProductName, QuantityShipped, and TrackingNumber.

SELECT 
    s.ShipmentID,
    l.Name AS WarehouseName,
    e.Name AS ManagerName,
    p.Name AS ProductName,
    sd.Quantity AS QuantityShipped,
    s.TrackingNumber
FROM Shipment s
INNER JOIN Warehouse w ON s.WarehouseID = w.WarehouseID
INNER JOIN Location l ON w.LocationID = l.LocationID
LEFT JOIN Employee e ON w.ManagerID = e.EmployeeID
INNER JOIN ShipmentDetail sd ON s.ShipmentID = sd.ShipmentID
INNER JOIN Product p ON sd.ProductID = p.ProductID
ORDER BY s.ShipmentID;


-- Q7. Find the top 3 highest-value orders per customer using RANK().
-- Display CustomerID, CustomerName, OrderID, and TotalAmount.

WITH RankedOrders AS (
    SELECT 
        c.CustomerID,
        c.Name AS CustomerName,
        so.OrderID,
        so.TotalAmount,
        RANK() OVER (PARTITION BY c.CustomerID ORDER BY so.TotalAmount DESC) AS OrderRank
    FROM Customer c
    INNER JOIN SalesOrder so ON c.CustomerID = so.CustomerID
)
SELECT 
    CustomerID,
    CustomerName,
    OrderID,
    TotalAmount
FROM RankedOrders
WHERE OrderRank <= 3
ORDER BY CustomerID, OrderRank;


-- Q8. For each product, show its sales history with the previous and next sales quantities (based on order date).
-- Display ProductID, ProductName, OrderID, OrderDate, Quantity, PrevQuantity, and NextQuantity.

SELECT 
    p.ProductID,
    p.Name AS ProductName,
    so.OrderID,
    so.OrderDate,
    sod.Quantity,
    LAG(sod.Quantity) OVER (PARTITION BY p.ProductID ORDER BY so.OrderDate) AS PrevQuantity,
    LEAD(sod.Quantity) OVER (PARTITION BY p.ProductID ORDER BY so.OrderDate) AS NextQuantity
FROM Product p
INNER JOIN SalesOrderDetail sod ON p.ProductID = sod.ProductID
INNER JOIN SalesOrder so ON sod.OrderID = so.OrderID
ORDER BY p.ProductID, so.OrderDate;


-- Q9. Create a view named vw_CustomerOrderSummary that shows for each customer:
-- CustomerID, CustomerName, TotalOrders, TotalAmountSpent, and LastOrderDate.

CREATE VIEW vw_CustomerOrderSummary AS
SELECT 
    c.CustomerID,
    c.Name AS CustomerName,
    COUNT(so.OrderID) AS TotalOrders,
    ISNULL(SUM(so.TotalAmount), 0) AS TotalAmountSpent,
    MAX(so.OrderDate) AS LastOrderDate
FROM Customer c
LEFT JOIN SalesOrder so ON c.CustomerID = so.CustomerID
GROUP BY c.CustomerID, c.Name;


-- To view the results:
SELECT * FROM vw_CustomerOrderSummary ORDER BY CustomerID;


-- Q10. Write a stored procedure sp_GetSupplierSales that takes a SupplierID as input 
-- and returns the total sales amount for all products supplied by that supplier.
CREATE PROCEDURE sp_GetSupplierSales
    @SupplierID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        s.SupplierID,
        s.Name AS SupplierName,
        ISNULL(SUM(sod.TotalAmount), 0) AS TotalSalesAmount
    FROM Supplier s
    LEFT JOIN PurchaseOrder po ON s.SupplierID = po.SupplierID
    LEFT JOIN PurchaseOrderDetail pod ON po.OrderID = pod.OrderID
    LEFT JOIN Product p ON pod.ProductID = p.ProductID
    LEFT JOIN SalesOrderDetail sod ON p.ProductID = sod.ProductID
    WHERE s.SupplierID = @SupplierID
    GROUP BY s.SupplierID, s.Name;
END;


-- To execute the stored procedure:
-- EXEC sp_GetSupplierSales @SupplierID = 1;