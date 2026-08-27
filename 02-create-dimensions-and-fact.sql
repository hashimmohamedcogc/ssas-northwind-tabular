/* IMPORTANT BEFORE Executing this query - Remember to CHANGE the Data Type for the PK of dateDimension Table to DateTime. */

Use <Insert_Your_Database_Name>;


--To Create DIMENSION Tables
--Creates dimEmployee Table
SELECT DISTINCT e.EmployeeID, e.FirstName, e.LastName, e.Title, e.BirthDate, e.HireDate, e.Address, e.City, e.Region, e.PostalCode, e.Country, r.RegionDescription
INTO dimEmployee 
      FROM Northwind.dbo.Employees e, Northwind.dbo.EmployeeTerritories et, Northwind.dbo.Territories t, Northwind.dbo.Region r
      WHERE e.employeeID = et.employeeID AND et.territoryID = t.territoryID AND t.regionID = r.regionID;	
	 
-- Creates dimCustomer Table
SELECT DISTINCT c.CustomerID, c.CompanyName, c.ContactName, c.ContactTitle, c.Address, c.City, c.Region, c.PostalCode, c.Country
INTO dimCustomer
	FROM Northwind.dbo.Customers c;
	
-- Creates dimProduct Table
SELECT p.ProductID, p.ProductName, p.QuantityPerUnit, p.UnitPrice, p.discontinued, p.CategoryID, c.CategoryName, c.Description
INTO dimProduct
	FROM Northwind.dbo.Products p, Northwind.dbo.Categories c
      WHERE p.CategoryID = c.CategoryID;

--Creates dimSupplier Table
 SELECT DISTINCT s.SupplierID, s.CompanyName, s.ContactName, s.ContactTitle, s.Address, s.City, s.Region, s.PostalCode, s.Country
  INTO dimSupplier
      FROM Northwind.dbo.Suppliers s;

--Updating dimension tables to identify PKs
ALTER TABLE dimEmployee ADD PRIMARY KEY (EmployeeID);
ALTER TABLE dimCustomer ADD PRIMARY KEY (CustomerID);
ALTER TABLE dimProduct ADD PRIMARY KEY (ProductID);
ALTER TABLE dimSupplier ADD PRIMARY KEY (SupplierID);

--To Create FACT Table
--To add Shipper CompanyName column to Orders table by creating a version called factOrder (Intermediate Table 1).
-- Creates factOrder Table (Intermediate Table 1)
 
SELECT o.*, sh.CompanyName
  INTO factOrder --–- Intermediate Table 1
	FROM Northwind.dbo.Orders o, Northwind.dbo.Shippers sh
      WHERE o.Shipvia = sh.ShipperID;
	
--To add supplierID column to OrderDetails table by creating a verison called factDetail (Intermediate Table 2).
-- Creates factDetail Table (Intermediate Table 2)
  
SELECT od.*, su.SupplierID
  INTO factDetail ---- Intermediate Table 2
	FROM Northwind.dbo.[Order Details] od, Northwind.dbo.Products p, Northwind.dbo.Suppliers su
      WHERE od.ProductID = p.ProductID AND p.SupplierID = su.SupplierID;

-- Creates factOrderDetail Table (using join between Intermediate Table 1 and Intermediate Table 2)
 
 SELECT fo.*, fd.ProductID, fd.UnitPrice, fd.Quantity,fd.Discount,fd.SupplierID
  INTO factOrderDetail
	FROM factOrder fo, factDetail fd
      WHERE fo.OrderID = fd.OrderID;

--Drops the 2 Intermediate Tables used to Create the factOrderDetail table
 DROP TABLE dbo.factDetail;
 DROP TABLE dbo.factOrder;

--Adding new column and then updated to act as PK for fact Table
ALTER TABLE factOrderDetail ADD factOrderDetailID INT IDENTITY;
ALTER TABLE factOrderDetail ADD PRIMARY KEY (factOrderDetailID);

--Adding 2 computed columns to factOrderDetails table
ALTER TABLE dbo.factOrderDetail ADD Total_OD_Price AS (UnitPrice * Quantity * (1 - Discount)) Persisted;  
ALTER TABLE dbo.factOrderDetail ADD Order_To_ShipDate AS DATEDIFF(day, OrderDate, ShippedDate) Persisted;

--Creating PK-FK Relationships
--Updating Fact Table columns to act as FKs
ALTER TABLE factOrderDetail 
ADD CONSTRAINT [FK_factOrderDetail_dimCustomer]
FOREIGN KEY (CustomerID) REFERENCES dimCustomer(CustomerID)
ON DELETE NO ACTION ON UPDATE CASCADE;

ALTER TABLE factOrderDetail 
ADD CONSTRAINT [FK_factOrderDetail_dimEmployee]
FOREIGN KEY (EmployeeID) REFERENCES dimEmployee(EmployeeID)
ON DELETE NO ACTION ON UPDATE CASCADE;

ALTER TABLE factOrderDetail 
ADD CONSTRAINT [FK_factOrderDetail_dimProduct]
FOREIGN KEY (ProductID) REFERENCES dimProduct(ProductID)
ON DELETE NO ACTION ON UPDATE CASCADE;

ALTER TABLE factOrderDetail 
ADD CONSTRAINT [FK_factOrderDetail_dimSupplier]
FOREIGN KEY (SupplierID) REFERENCES dimSupplier(SupplierID)
ON DELETE NO ACTION ON UPDATE CASCADE;

ALTER TABLE factOrderDetail 
ADD CONSTRAINT [FK_factOrderDetail_OD_dimDate]
FOREIGN KEY (OrderDate) REFERENCES DateDimension(Date)
ON DELETE NO ACTION ON UPDATE No ACTION;

ALTER TABLE factOrderDetail 
ADD CONSTRAINT [FK_factOrderDetail_RD_dimDate]
FOREIGN KEY (RequiredDate) REFERENCES DateDimension(Date)
ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE factOrderDetail 
ADD CONSTRAINT [FK_factOrderDetail_SD_dimDate]
FOREIGN KEY (ShippedDate) REFERENCES DateDimension(Date)
ON DELETE NO ACTION ON UPDATE NO ACTION;

--Check all date fields to be updated are datetime data type.
--Increase all date values by adding 20 years

UPDATE dimEmployee 
 SET BirthDate = DATEADD(Year , 20 , BirthDate);
 
UPDATE dimEmployee 
 SET HireDate = DATEADD(Year , 20 , HireDate);

UPDATE factOrderDetail 
 SET OrderDate = DATEADD(Year , 20 , OrderDate);

UPDATE factOrderDetail 
 SET RequiredDate = DATEADD(Year , 20 , RequiredDate);

UPDATE factOrderDetail 
 SET ShippedDate = DATEADD(Year , 20 , ShippedDate);
 
