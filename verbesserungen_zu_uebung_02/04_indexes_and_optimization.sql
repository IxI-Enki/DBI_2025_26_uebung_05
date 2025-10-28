----------------------------------------------------------------------------------------------------
-- Indexes and Performance Optimization for Star Schema
-- Author: Jan Ritt
-- Date: 2025-10-28
--
-- This script creates indexes optimized for:
-- 1. Star-join queries (typical OLAP queries)
-- 2. Analytic functions (window functions)
-- 3. Aggregation queries
--
-- Index Strategy:
-- - BITMAP indexes on FACT_SALES foreign keys (low cardinality, read-heavy workload)
-- - B-TREE index on DIM_TIME.FULL_DATE (high cardinality, range queries)
-- - B-TREE indexes on dimension natural keys for lookup performance
----------------------------------------------------------------------------------------------------

-- Enable output for progress messages
SET SERVEROUTPUT ON;

BEGIN
  DBMS_OUTPUT.PUT_LINE('=== Creating Indexes for Star Schema ===');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- BITMAP INDEXES on FACT_SALES
----------------------------------------------------------------------------------------------------
-- Why BITMAP?
-- - Low cardinality (few distinct values relative to total rows)
-- - Read-heavy workload (typical for data warehouses)
-- - Excellent for AND/OR/NOT operations in WHERE clauses
-- - Star-join optimization enabled by Oracle optimizer
-- - Space efficient for dimensions with low cardinality
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('Creating BITMAP indexes on FACT_SALES foreign keys...');
END;
/

-- Index on time dimension FK
CREATE BITMAP INDEX idx_fact_sales_t 
  ON FACT_SALES(t)
  TABLESPACE USERS;  -- Adjust tablespace as needed

-- Index on product dimension FK
CREATE BITMAP INDEX idx_fact_sales_product 
  ON FACT_SALES(product)
  TABLESPACE USERS;

-- Index on customer dimension FK
CREATE BITMAP INDEX idx_fact_sales_customer 
  ON FACT_SALES(customer)
  TABLESPACE USERS;

-- Index on employee dimension FK (nullable!)
-- BITMAP indexes handle NULLs efficiently
CREATE BITMAP INDEX idx_fact_sales_employee 
  ON FACT_SALES(employee)
  TABLESPACE USERS;

-- Index on status dimension FK
CREATE BITMAP INDEX idx_fact_sales_status 
  ON FACT_SALES(status)
  TABLESPACE USERS;

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ BITMAP indexes on FACT_SALES created');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- B-TREE INDEX on DIM_TIME.FULL_DATE
----------------------------------------------------------------------------------------------------
-- Why B-TREE?
-- - High cardinality (many distinct date values)
-- - Excellent for range queries (BETWEEN, <, >, >=, <=)
-- - Supports ORDER BY efficiently
-- - Critical for RANGE INTERVAL operations in analytic functions
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('Creating B-TREE index on DIM_TIME.FULL_DATE...');
END;
/

CREATE INDEX idx_dim_time_full_date 
  ON DIM_TIME(full_date)
  TABLESPACE USERS;

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ B-TREE index on DIM_TIME.FULL_DATE created');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- B-TREE INDEXES on Dimension Natural Keys
----------------------------------------------------------------------------------------------------
-- These indexes support lookups by natural/business keys
-- Useful for ETL processes and ad-hoc queries
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('Creating B-TREE indexes on dimension natural keys...');
END;
/

-- DIM_TIME: Composite index on year/month/day (already has UNIQUE constraint index)
-- No additional index needed - UNIQUE constraint creates index automatically

-- DIM_PRODUCT: Index on product name for text searches
CREATE INDEX idx_dim_product_name 
  ON DIM_PRODUCT(product_name)
  TABLESPACE USERS;

-- DIM_CUSTOMER: Index on customer name for text searches  
CREATE INDEX idx_dim_customer_name 
  ON DIM_CUSTOMER(customer_name)
  TABLESPACE USERS;

-- DIM_EMPLOYEE: Index on last name for text searches
CREATE INDEX idx_dim_employee_name 
  ON DIM_EMPLOYEE(last_name, first_name)
  TABLESPACE USERS;

-- DIM_STATUS: Small dimension, no additional index needed

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ B-TREE indexes on dimension natural keys created');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- COMPOSITE INDEXES for Common Query Patterns
----------------------------------------------------------------------------------------------------
-- These support specific analytical queries
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('Creating composite indexes for common queries...');
END;
/

-- Support queries filtered by time + product
CREATE BITMAP INDEX idx_fact_sales_t_product 
  ON FACT_SALES(t, product)
  TABLESPACE USERS;

-- Support queries filtered by time + customer  
CREATE BITMAP INDEX idx_fact_sales_t_customer 
  ON FACT_SALES(t, customer)
  TABLESPACE USERS;

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ Composite indexes created');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- Index Statistics and Validation
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('=== Gathering Statistics ===');
END;
/

-- Gather statistics for cost-based optimizer
-- This is CRITICAL for query optimization
BEGIN
  -- Analyze FACT_SALES
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname => USER,
    tabname => 'FACT_SALES',
    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
    method_opt => 'FOR ALL COLUMNS SIZE AUTO',
    cascade => TRUE  -- Include indexes
  );
  DBMS_OUTPUT.PUT_LINE('✓ Statistics gathered for FACT_SALES');
  
  -- Analyze dimensions
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'DIM_TIME', cascade => TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'DIM_PRODUCT', cascade => TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'DIM_CUSTOMER', cascade => TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'DIM_EMPLOYEE', cascade => TRUE);
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'DIM_STATUS', cascade => TRUE);
  DBMS_OUTPUT.PUT_LINE('✓ Statistics gathered for all dimensions');
  
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- Index Summary Report
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('=== INDEX SUMMARY ===');
END;
/

SELECT 
  table_name,
  index_name,
  index_type,
  uniqueness,
  status
FROM user_indexes
WHERE table_name IN ('FACT_SALES', 'DIM_TIME', 'DIM_PRODUCT', 'DIM_CUSTOMER', 'DIM_EMPLOYEE', 'DIM_STATUS')
ORDER BY table_name, index_name;

BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('=== INDEX CREATION COMPLETE ===');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Performance Tips:');
  DBMS_OUTPUT.PUT_LINE('1. BITMAP indexes are ideal for star-join queries');
  DBMS_OUTPUT.PUT_LINE('2. Use FULL_DATE in DIM_TIME for date range queries');
  DBMS_OUTPUT.PUT_LINE('3. Let Oracle optimizer choose between indexes');
  DBMS_OUTPUT.PUT_LINE('4. Monitor index usage with V$OBJECT_USAGE');
  DBMS_OUTPUT.PUT_LINE('5. Rebuild indexes if fragmentation occurs');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- Optional: Enable Query Result Cache (if available)
----------------------------------------------------------------------------------------------------
-- This can significantly improve performance for repeated queries
-- Uncomment if your Oracle version supports it and you have sufficient memory

/*
ALTER TABLE FACT_SALES RESULT_CACHE (MODE FORCE);
ALTER TABLE DIM_TIME RESULT_CACHE (MODE FORCE);
ALTER TABLE DIM_PRODUCT RESULT_CACHE (MODE FORCE);
ALTER TABLE DIM_CUSTOMER RESULT_CACHE (MODE FORCE);
ALTER TABLE DIM_EMPLOYEE RESULT_CACHE (MODE FORCE);
ALTER TABLE DIM_STATUS RESULT_CACHE (MODE FORCE);

BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ Query Result Cache enabled for all tables');
END;
/
*/

----------------------------------------------------------------------------------------------------
-- Index Maintenance Recommendations
----------------------------------------------------------------------------------------------------
-- Run these periodically (e.g., monthly) to maintain index health:
--
-- 1. Check for unused indexes:
--    SELECT * FROM v$object_usage WHERE used = 'NO';
--
-- 2. Check for index fragmentation:
--    SELECT index_name, blevel, leaf_blocks, num_rows 
--    FROM user_indexes 
--    WHERE table_name = 'FACT_SALES';
--
-- 3. Rebuild indexes if needed:
--    ALTER INDEX idx_fact_sales_t REBUILD ONLINE;
--
-- 4. Update statistics regularly:
--    EXEC DBMS_STATS.GATHER_SCHEMA_STATS(USER);
----------------------------------------------------------------------------------------------------

COMMIT;
