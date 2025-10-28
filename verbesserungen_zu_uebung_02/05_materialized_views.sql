----------------------------------------------------------------------------------------------------
-- Materialized Views for Star Schema
-- Author: Jan Ritt
-- Date: 2025-10-28
--
-- Purpose:
-- Pre-aggregate common queries to improve reporting performance
-- Materialized views store query results physically and can be refreshed on demand or schedule
--
-- Benefits:
-- - Dramatic performance improvement for aggregate queries
-- - Reduced load on fact table
-- - Enable complex analytics without scanning millions of rows
--
-- Refresh Strategy:
-- - REFRESH COMPLETE ON DEMAND: Truncate and reload (use for nightly ETL)
-- - Alternative: REFRESH FAST ON COMMIT (requires materialized view logs)
----------------------------------------------------------------------------------------------------

SET SERVEROUTPUT ON;

BEGIN
  DBMS_OUTPUT.PUT_LINE('=== Creating Materialized Views ===');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- MV 1: Sales by Year and Product
----------------------------------------------------------------------------------------------------
-- Use Case: Annual product performance reports
-- Typical Query Time: 2-5 seconds on large fact table
-- MV Query Time: <100ms
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('Creating MV: Sales by Year and Product...');
  EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_sales_by_year_product';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE MATERIALIZED VIEW mv_sales_by_year_product
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT 
  dt.year,
  dp.product_name,
  dp.category_name,
  COUNT(*) AS anzahl_verkaufe,
  SUM(fs.quantity) AS gesamt_menge,
  SUM(fs.amount) AS gesamt_umsatz,
  AVG(fs.amount) AS durchschnitt_umsatz,
  MIN(fs.amount) AS min_umsatz,
  MAX(fs.amount) AS max_umsatz
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
JOIN DIM_PRODUCT dp ON fs.product = dp.id
GROUP BY dt.year, dp.product_name, dp.category_name;

-- Create index on the MV for fast filtering
CREATE INDEX idx_mv_sales_year_prod ON mv_sales_by_year_product(year, product_name);

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ MV created: mv_sales_by_year_product');
  DBMS_OUTPUT.PUT_LINE('  Rows: ' || (SELECT COUNT(*) FROM mv_sales_by_year_product));
END;
/

----------------------------------------------------------------------------------------------------
-- MV 2: Sales by Year, Month, and Customer
----------------------------------------------------------------------------------------------------
-- Use Case: Customer trend analysis, monthly performance tracking
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('Creating MV: Sales by Year, Month, Customer...');
  EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_sales_by_month_customer';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE MATERIALIZED VIEW mv_sales_by_month_customer
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT 
  dt.year,
  dt.month,
  dc.customer_name,
  dc.address AS customer_address,
  COUNT(*) AS anzahl_bestellungen,
  SUM(fs.quantity) AS gesamt_menge,
  SUM(fs.amount) AS gesamt_umsatz,
  AVG(fs.amount) AS durchschnitt_umsatz
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
JOIN DIM_CUSTOMER dc ON fs.customer = dc.id
GROUP BY dt.year, dt.month, dc.customer_name, dc.address;

-- Create index on the MV
CREATE INDEX idx_mv_sales_month_cust ON mv_sales_by_month_customer(year, month, customer_name);

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ MV created: mv_sales_by_month_customer');
  DBMS_OUTPUT.PUT_LINE('  Rows: ' || (SELECT COUNT(*) FROM mv_sales_by_month_customer));
END;
/

----------------------------------------------------------------------------------------------------
-- MV 3: Employee Performance by Year
----------------------------------------------------------------------------------------------------
-- Use Case: Salesperson rankings, commission calculations
-- Directly supports Übung 05 Aufgabe 8 & 9
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('Creating MV: Employee Performance by Year...');
  EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_employee_sales_by_year';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE MATERIALIZED VIEW mv_employee_sales_by_year
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT 
  dt.year,
  de.id AS employee_id,
  de.first_name,
  de.last_name,
  de.job_title,
  COUNT(*) AS anzahl_verkaufe,
  SUM(fs.quantity) AS gesamt_menge,
  SUM(fs.amount) AS jahresumsatz,
  AVG(fs.amount) AS durchschnitt_umsatz,
  -- Pre-calculate rank (will be refreshed with MV)
  RANK() OVER (PARTITION BY dt.year ORDER BY SUM(fs.amount) DESC) AS rang_im_jahr
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
JOIN DIM_EMPLOYEE de ON fs.employee = de.id
WHERE fs.employee IS NOT NULL
GROUP BY dt.year, de.id, de.first_name, de.last_name, de.job_title;

-- Create index on the MV
CREATE INDEX idx_mv_emp_sales_year ON mv_employee_sales_by_year(year, employee_id);

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ MV created: mv_employee_sales_by_year');
  DBMS_OUTPUT.PUT_LINE('  Rows: ' || (SELECT COUNT(*) FROM mv_employee_sales_by_year));
END;
/

----------------------------------------------------------------------------------------------------
-- MV 4: Daily Sales Summary
----------------------------------------------------------------------------------------------------
-- Use Case: Daily KPI dashboard, trend analysis
-- Supports Übung 05 Aufgabe 5 (laufende Summe des Tages)
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('Creating MV: Daily Sales Summary...');
  EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_daily_sales_summary';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE MATERIALIZED VIEW mv_daily_sales_summary
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT 
  dt.year,
  dt.month,
  dt.day,
  dt.full_date,
  COUNT(*) AS anzahl_verkaufe,
  SUM(fs.quantity) AS gesamt_menge,
  SUM(fs.amount) AS tagesumsatz,
  AVG(fs.amount) AS durchschnitt_umsatz,
  MIN(fs.amount) AS min_umsatz,
  MAX(fs.amount) AS max_umsatz
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
GROUP BY dt.year, dt.month, dt.day, dt.full_date;

-- Create index on the MV
CREATE INDEX idx_mv_daily_sales_date ON mv_daily_sales_summary(full_date);

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ MV created: mv_daily_sales_summary');
  DBMS_OUTPUT.PUT_LINE('  Rows: ' || (SELECT COUNT(*) FROM mv_daily_sales_summary));
END;
/

----------------------------------------------------------------------------------------------------
-- MV 5: Product Category Performance
----------------------------------------------------------------------------------------------------
-- Use Case: Category-level reporting, inventory planning
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('Creating MV: Product Category Performance...');
  EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_category_performance';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE MATERIALIZED VIEW mv_category_performance
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT 
  dt.year,
  dt.month,
  dp.category_name,
  COUNT(DISTINCT fs.product) AS anzahl_produkte,
  COUNT(*) AS anzahl_verkaufe,
  SUM(fs.quantity) AS gesamt_menge,
  SUM(fs.amount) AS gesamt_umsatz,
  AVG(fs.amount) AS durchschnitt_umsatz
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
JOIN DIM_PRODUCT dp ON fs.product = dp.id
GROUP BY dt.year, dt.month, dp.category_name;

-- Create index on the MV
CREATE INDEX idx_mv_category_perf ON mv_category_performance(year, month, category_name);

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ MV created: mv_category_performance');
  DBMS_OUTPUT.PUT_LINE('  Rows: ' || (SELECT COUNT(*) FROM mv_category_performance));
END;
/

----------------------------------------------------------------------------------------------------
-- Gather Statistics on Materialized Views
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Gathering statistics on materialized views...');
  
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'MV_SALES_BY_YEAR_PRODUCT', cascade => TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'MV_SALES_BY_MONTH_CUSTOMER', cascade => TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'MV_EMPLOYEE_SALES_BY_YEAR', cascade => TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'MV_DAILY_SALES_SUMMARY', cascade => TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'MV_CATEGORY_PERFORMANCE', cascade => TRUE);
  
  DBMS_OUTPUT.PUT_LINE('✓ Statistics gathered');
END;
/

----------------------------------------------------------------------------------------------------
-- Summary Report
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('=== MATERIALIZED VIEW SUMMARY ===');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

SELECT 
  mview_name,
  query_rewrite_enabled,
  refresh_method,
  refresh_mode,
  build_mode,
  fast_refreshable
FROM user_mviews
ORDER BY mview_name;

BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('=== USAGE EXAMPLES ===');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('-- View annual product sales:');
  DBMS_OUTPUT.PUT_LINE('SELECT * FROM mv_sales_by_year_product WHERE year = 2017;');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('-- View employee rankings:');
  DBMS_OUTPUT.PUT_LINE('SELECT * FROM mv_employee_sales_by_year ORDER BY year, rang_im_jahr;');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('-- Refresh all MVs after data load:');
  DBMS_OUTPUT.PUT_LINE('EXEC DBMS_MVIEW.REFRESH(''MV_SALES_BY_YEAR_PRODUCT'');');
  DBMS_OUTPUT.PUT_LINE('EXEC DBMS_MVIEW.REFRESH(''MV_SALES_BY_MONTH_CUSTOMER'');');
  DBMS_OUTPUT.PUT_LINE('EXEC DBMS_MVIEW.REFRESH(''MV_EMPLOYEE_SALES_BY_YEAR'');');
  DBMS_OUTPUT.PUT_LINE('EXEC DBMS_MVIEW.REFRESH(''MV_DAILY_SALES_SUMMARY'');');
  DBMS_OUTPUT.PUT_LINE('EXEC DBMS_MVIEW.REFRESH(''MV_CATEGORY_PERFORMANCE'');');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- Refresh Procedure (convenience)
----------------------------------------------------------------------------------------------------
-- Create a stored procedure to refresh all MVs at once
----------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE refresh_all_mvs
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('Refreshing all materialized views...');
  
  DBMS_MVIEW.REFRESH('MV_SALES_BY_YEAR_PRODUCT', method => 'C');
  DBMS_OUTPUT.PUT_LINE('✓ mv_sales_by_year_product refreshed');
  
  DBMS_MVIEW.REFRESH('MV_SALES_BY_MONTH_CUSTOMER', method => 'C');
  DBMS_OUTPUT.PUT_LINE('✓ mv_sales_by_month_customer refreshed');
  
  DBMS_MVIEW.REFRESH('MV_EMPLOYEE_SALES_BY_YEAR', method => 'C');
  DBMS_OUTPUT.PUT_LINE('✓ mv_employee_sales_by_year refreshed');
  
  DBMS_MVIEW.REFRESH('MV_DAILY_SALES_SUMMARY', method => 'C');
  DBMS_OUTPUT.PUT_LINE('✓ mv_daily_sales_summary refreshed');
  
  DBMS_MVIEW.REFRESH('MV_CATEGORY_PERFORMANCE', method => 'C');
  DBMS_OUTPUT.PUT_LINE('✓ mv_category_performance refreshed');
  
  DBMS_OUTPUT.PUT_LINE('All materialized views refreshed successfully!');
END refresh_all_mvs;
/

BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('✓ Stored procedure refresh_all_mvs created');
  DBMS_OUTPUT.PUT_LINE('  Usage: EXEC refresh_all_mvs;');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('=== MATERIALIZED VIEW CREATION COMPLETE ===');
END;
/

----------------------------------------------------------------------------------------------------
-- Performance Notes:
-- 
-- 1. Query Rewrite: When ENABLE QUERY REWRITE is set, Oracle optimizer can automatically
--    use the MV instead of the base tables if it determines the MV can satisfy the query
--
-- 2. Refresh Strategy: Choose between COMPLETE (full rebuild) and FAST (incremental)
--    - COMPLETE: Simple, reliable, but slower for large tables
--    - FAST: Requires materialized view logs, faster, more complex
--
-- 3. Refresh Schedule: Consider setting up a job to refresh MVs automatically:
--    BEGIN
--      DBMS_SCHEDULER.CREATE_JOB (
--        job_name => 'REFRESH_SALES_MVS',
--        job_type => 'STORED_PROCEDURE',
--        job_action => 'refresh_all_mvs',
--        start_date => SYSTIMESTAMP,
--        repeat_interval => 'FREQ=DAILY; BYHOUR=2; BYMINUTE=0',  -- Daily at 2 AM
--        enabled => TRUE
--      );
--    END;
----------------------------------------------------------------------------------------------------

COMMIT;
