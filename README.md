# SSAS Tabular Semantic Model — Northwind Data Mart

Coursework project for COMP10002 Data Warehouse Environment, University of the West of Scotland. Graded 90% (Distinction).

The brief was to take a transactional database and turn it into something a business user could actually query and trust. I built a star schema data mart from Northwind in SQL Server, deployed an SSAS Tabular model on top of it in Visual Studio, wrote the DAX measures, and then proved the whole thing worked by running all five classical OLAP operations against it in Excel.

## The data mart

Northwind's OLTP tables get transformed into a star schema (NorthwindDM):

- `factOrderDetail` — 2,155 rows, sits at the centre
- `DateDimension` — 25,568 rows, spans 70 years (1960–2030) with day-of-week, quarter, public holiday flags, the works
- `dimCustomer` (91), `dimEmployee` (9), `dimProduct` (77), `dimSupplier` (29)

A couple of things that aren't obvious until you hit them: the DateDimension primary key has to be changed from DATE to DATETIME before it'll work as a foreign key target in the Tabular model, and all the original dates get shifted forward 20 years so the data actually falls in a usable, current-looking timeframe. Both scripts below handle this.

## SSAS Tabular model

Built in Visual Studio 2022 against the data mart. Two hierarchies:

- Date Hierarchy (DateDimension): Year → Quarter → Month
- Product Hierarchy (dimProduct): CategoryName → ProductName

Four DAX measures on `factOrderDetail`:

```dax
Units Sold := SUM(factOrderDetail[Quantity])

Net Sales := SUMX(
    factOrderDetail,
    factOrderDetail[Quantity] * factOrderDetail[UnitPrice] * (1 - factOrderDetail[Discount])
)

Order Count := DISTINCTCOUNT(factOrderDetail[OrderID])

Average Order Value := DIVIDE([Net Sales], [Order Count], 0)
```

Across the full (unfiltered) dataset these come out to:

| Measure | Result |
|---|---|
| Units Sold | 51,317 |
| Net Sales | £1,265,793.04 |
| Order Count | 830 |
| Average Order Value | £1,525.05 |

## OLAP operations in Excel

Connected the deployed model to Excel via Analyze in Excel and demonstrated all five classic operations:

| Operation | What it does | Example used |
|---|---|---|
| Roll-Up | detail → summary | monthly sales rolled up to yearly |
| Drill-Down | summary → detail | 2016 expanded to quarters |
| Slice | filter on one dimension | Country = Germany |
| Dice | filter on multiple dimensions | Germany + Beverages |
| Pivot | rotate the analysis axis | years moved from rows to columns |

The PivotTable workbook (`olap-pivot-analysis.xlsx`) has the actual working examples.

## Why this matters (the semantic layer bit)

SSAS Tabular's VertiPaq engine is an in-memory columnar store — it compresses aggressively and answers queries fast even across tens of thousands of rows. But the thing that makes it valuable for a business isn't the speed, it's the semantic layer: `factOrderDetail` and its cryptic column names disappear behind business-friendly measures like "Net Sales" and "Order Count." Every tool that connects to it — Excel, Power BI, whatever comes next — sees the same definitions. That's what a single version of the truth looks like in practice, rather than as a buzzword.

## Repo layout

```
sql-scripts/
  01-create-date-dimension.sql       builds the 70-year DateDimension table
  02-create-dimensions-and-fact.sql  builds the star schema from Northwind
  instnwnd.sql                       standard Northwind sample DB install script (Microsoft)
olap-pivot-analysis.xlsx             Excel workbook with the five OLAP operations
full-report.docx                    complete written report covering all five tasks in detail
```

Run `instnwnd.sql` first to stand up the base Northwind database, then the two numbered scripts in order.

## Stack

SQL Server 2025, SSMS, Visual Studio 2022, SSAS Tabular, DAX, Excel, Power BI for the reporting layer on top.

## Grading notes

Submitted for COMP10002 Data Warehouse Environment, University of the West of Scotland — 90%, Distinction.

---

More of my projects: [github.com/hashimmohamedcogc](https://github.com/hashimmohamedcogc) · [LinkedIn](https://linkedin.com/in/hashimmohamedcogc)
