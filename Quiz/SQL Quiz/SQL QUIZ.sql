SELECT * from SalesOrder


-- QUESTION 1
WITH topTenCTE as (Select TOP(5) CustomerId, SUM(TotalAmount) as TotalSpent from SalesOrder
GROUP BY CustomerID
ORDER BY TotalSpent DESC) 
SELECT topTenCTE.CustomerID, Customer.Name, totalSpent from topTenCTE
INNER JOIN Customer ON topTenCTE.CustomerID = Customer.CustomerID

-- QUESTION 2
SELECT 
    s.SupplierID,
    s.Name AS SupplierName,
    COUNT(DISTINCT pod.ProductID) AS ProductCount
FROM supplier s
INNER JOIN purchaseorder po ON s.SupplierID = po.SupplierID
INNER JOIN purchaseorderdetail pod ON po.OrderID = pod.OrderID
GROUP BY s.SupplierID, s.Name
HAVING COUNT(DISTINCT pod.ProductID) > 10

-- Q3. Identify products that have been ordered but never returned
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    SUM(sod.Quantity) AS TotalOrderQuantity
FROM product p
INNER JOIN salesorderdetail sod ON p.ProductID = sod.ProductID
LEFT JOIN returndetail rd ON p.ProductID = rd.ProductID
WHERE rd.ProductID IS NULL
GROUP BY p.ProductID, p.Name
ORDER BY TotalOrderQuantity DESC;

-- Q4. For each category, find the most expensive product
SELECT 
    c.CategoryID,
    c.Name AS CategoryName,
    p.Name AS ProductName,
    p.Price
FROM category c
INNER JOIN product p ON c.CategoryID = p.CategoryID
WHERE p.Price = (
    SELECT MAX(p2.Price)
    FROM product p2
    WHERE p2.CategoryID = c.CategoryID
)
ORDER BY c.CategoryID;


-- Q5. List all sales orders with customer name, product name, category, and supplier
SELECT 
    so.OrderID,
    c.Name AS CustomerName,
    p.Name AS ProductName,
    cat.Name AS CategoryName,
    m.Name AS ManufacturerName,
    sod.Quantity
FROM salesorder so
INNER JOIN customer c ON so.CustomerID = c.CustomerID
INNER JOIN salesorderdetail sod ON so.OrderID = sod.OrderID
INNER JOIN product p ON sod.ProductID = p.ProductID
INNER JOIN category cat ON p.CategoryID = cat.CategoryID
INNER JOIN manufacturer m ON p.ManufacturerID = m.ManufacturerID
ORDER BY so.OrderID, sod.ProductID;

-- Q6. Find all shipments with details of warehouse, manager, and products shipped
SELECT 
    sh.ShipmentID,
    e.Name AS ManagerName,
    p.Name AS ProductName,
    sd.Quantity AS QuantityShipped,
    sh.TrackingNumber
FROM shipment sh
INNER JOIN warehouse w ON sh.WarehouseID = w.WarehouseID
INNER JOIN employee e ON w.ManagerID = e.EmployeeID
INNER JOIN shipmentdetail sd ON sh.ShipmentID = sd.ShipmentID
INNER JOIN product p ON sd.ProductID = p.ProductID
ORDER BY sh.ShipmentID;

-- Q7. Find the top 3 highest-value orders per customer using RANK()
WITH RankedOrders AS (
    SELECT 
        c.CustomerID,
        c.Name AS CustomerName,
        so.OrderID,
        so.TotalAmount,
        RANK() OVER (PARTITION BY c.CustomerID ORDER BY so.TotalAmount DESC) AS OrderRank
    FROM customer c
    INNER JOIN salesorder so ON c.CustomerID = so.CustomerID
)
SELECT 
    CustomerID,
    CustomerName,
    OrderID,
    TotalAmount
FROM RankedOrders
WHERE OrderRank <= 3
ORDER BY CustomerID, OrderRank;


-- Q8. For each product, show its sales history with previous and next sales quantities
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    so.OrderID,
    so.OrderDate,
    sod.Quantity,
    LAG(sod.Quantity) OVER (PARTITION BY p.ProductID ORDER BY so.OrderDate) AS PrevQuantity,
    LEAD(sod.Quantity) OVER (PARTITION BY p.ProductID ORDER BY so.OrderDate) AS NextQuantity
FROM product p
INNER JOIN salesorderdetail sod ON p.ProductID = sod.ProductID
INNER JOIN salesorder so ON sod.OrderID = so.OrderID
ORDER BY p.ProductID, so.OrderDate;

-- Q9. Create a view named vw_CustomerOrderSummary
CREATE VIEW vw_CustomerOrderSummary AS
SELECT 
    c.CustomerID,
    c.Name AS CustomerName,
    COUNT(DISTINCT so.OrderID) AS TotalOrders,
    SUM(so.TotalAmount) AS TotalAmountSpent,
    MAX(so.OrderDate) AS LastOrderDate
FROM customer c
LEFT JOIN salesorder so ON c.CustomerID = so.CustomerID
GROUP BY c.CustomerID, c.Name;

SELECT * FROM vw_CustomerOrderSummary ORDER BY TotalAmountSpent DESC;


-- Q10. Stored procedure sp_GetSupplierSales
ALTER PROCEDURE sp_GetSupplierSales 
    @p_SupplierID INT
AS
BEGIN
    SELECT 
        s.SupplierID,
        s.Name AS SupplierName,
        SUM(sod.TotalAmount) AS TotalSalesAmount
    FROM supplier s
    INNER JOIN purchaseorder po ON s.SupplierID = po.SupplierID
    INNER JOIN purchaseorderdetail pod ON po.OrderID = pod.OrderID
    INNER JOIN salesorderdetail sod ON pod.ProductID = sod.ProductID
    WHERE s.SupplierID = @p_SupplierID
    GROUP BY s.SupplierID, s.Name;
END;
GO
EXEC sp_GetSupplierSales 1