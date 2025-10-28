----------------------------------------------------------------------------------------------------
-- Complete Star Schema Setup - IMPROVED VERSION
-- For OT (Company) Database
--
-- Author: Jan Ritt
-- Date: 2025-10-28
-- Course: DBI 2025/26
--
-- IMPROVEMENTS over original version:
-- ✅ DIM_TIME with FULL_DATE column
-- ✅ CHECK constraints for data validation
-- ✅ BITMAP and B-TREE indexes for performance
-- ✅ Materialized views for reporting
-- ✅ Comprehensive validation and statistics
-- ✅ Better documentation
--
-- Execution Order:
-- 1. DDL (dimensions and fact table)
-- 2. Load dimensions
-- 3. Load fact table
-- 4. Create indexes
-- 5. Create materialized views
-- 6. Gather statistics
-- 7. Validation
--
-- Prerequisites:
-- - OT schema (OLTP) must exist and be populated
-- - Sufficient privileges to create tables, indexes, and MVs
--
-- Usage:
--   @assignment_run_improved.sql
----------------------------------------------------------------------------------------------------

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET TIMING ON;
SET ECHO OFF;
SET VERIFY OFF;
SET FEEDBACK ON;

-- Clear screen (optional)
CLEAR SCREEN;

BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('╔══════════════════════════════════════════════════════════════════╗');
  DBMS_OUTPUT.PUT_LINE('║     DBI Star Schema - IMPROVED VERSION - Setup Script            ║');
  DBMS_OUTPUT.PUT_LINE('║     Author: Jan Ritt                                             ║');
  DBMS_OUTPUT.PUT_LINE('║     Date: 2025-10-28                                             ║');
  DBMS_OUTPUT.PUT_LINE('╚══════════════════════════════════════════════════════════════════╝');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Starting enhanced star schema setup...');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- STEP 1: Create Dimensions (DDL)
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('STEP 1/7: Creating dimension tables...');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

@@01_dim_company_ddl_improved.sql

BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('✓ STEP 1 COMPLETE: Dimension tables created');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- STEP 2: Load Dimensions
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('STEP 2/7: Loading dimension data...');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

@@02_dim_company_load_improved.sql

BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('✓ STEP 2 COMPLETE: Dimensions loaded');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- STEP 3: Create and Load Fact Table
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('STEP 3/7: Creating and loading fact table...');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

@@03_fact_sales_improved.sql

BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('✓ STEP 3 COMPLETE: Fact table created and loaded');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- STEP 4: Create Indexes
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('STEP 4/7: Creating indexes for performance...');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

@@04_indexes_and_optimization.sql

BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('✓ STEP 4 COMPLETE: Indexes created');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- STEP 5: Create Materialized Views
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('STEP 5/7: Creating materialized views...');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

@@05_materialized_views.sql

BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('✓ STEP 5 COMPLETE: Materialized views created');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- STEP 6: Final Statistics Gathering
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('STEP 6/7: Gathering comprehensive statistics...');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

BEGIN
  -- Gather schema-level statistics for optimal query plans
  DBMS_STATS.GATHER_SCHEMA_STATS(
    ownname => USER,
    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
    method_opt => 'FOR ALL COLUMNS SIZE AUTO',
    cascade => TRUE
  );
  
  DBMS_OUTPUT.PUT_LINE('✓ Schema statistics gathered');
END;
/

BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('✓ STEP 6 COMPLETE: Statistics gathered');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

----------------------------------------------------------------------------------------------------
-- STEP 7: Validation and Summary Report
----------------------------------------------------------------------------------------------------

BEGIN
  DBMS_OUTPUT.PUT_LINE('STEP 7/7: Validation and reporting...');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

-- Table row counts
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== TABLE ROW COUNTS ===');
  DBMS_OUTPUT.PUT_LINE('DIM_TIME:     ' || RPAD(TO_CHAR((SELECT COUNT(*) FROM DIM_TIME)), 10) || ' rows');
  DBMS_OUTPUT.PUT_LINE('DIM_PRODUCT:  ' || RPAD(TO_CHAR((SELECT COUNT(*) FROM DIM_PRODUCT)), 10) || ' rows');
  DBMS_OUTPUT.PUT_LINE('DIM_CUSTOMER: ' || RPAD(TO_CHAR((SELECT COUNT(*) FROM DIM_CUSTOMER)), 10) || ' rows');
  DBMS_OUTPUT.PUT_LINE('DIM_EMPLOYEE: ' || RPAD(TO_CHAR((SELECT COUNT(*) FROM DIM_EMPLOYEE)), 10) || ' rows');
  DBMS_OUTPUT.PUT_LINE('DIM_STATUS:   ' || RPAD(TO_CHAR((SELECT COUNT(*) FROM DIM_STATUS)), 10) || ' rows');
  DBMS_OUTPUT.PUT_LINE('FACT_SALES:   ' || RPAD(TO_CHAR((SELECT COUNT(*) FROM FACT_SALES)), 10) || ' rows');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

-- Index counts
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== INDEX COUNTS ===');
  FOR rec IN (
    SELECT table_name, COUNT(*) AS idx_count
    FROM user_indexes
    WHERE table_name IN ('FACT_SALES', 'DIM_TIME', 'DIM_PRODUCT', 'DIM_CUSTOMER', 'DIM_EMPLOYEE', 'DIM_STATUS')
    GROUP BY table_name
    ORDER BY table_name
  ) LOOP
    DBMS_OUTPUT.PUT_LINE(RPAD(rec.table_name, 15) || ' ' || rec.idx_count || ' indexes');
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('');
END;
/

-- Materialized view counts
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== MATERIALIZED VIEW COUNTS ===');
  FOR rec IN (
    SELECT mview_name, (SELECT COUNT(*) FROM user_tables WHERE table_name = rec.mview_name) AS row_count
    FROM user_mviews
    ORDER BY mview_name
  ) LOOP
    -- Get row count dynamically
    DECLARE
      v_count NUMBER;
    BEGIN
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || rec.mview_name INTO v_count;
      DBMS_OUTPUT.PUT_LINE(RPAD(rec.mview_name, 35) || ' ' || v_count || ' rows');
    END;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('');
END;
/

-- Constraint validation
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== CONSTRAINT VALIDATION ===');
  
  DECLARE
    v_count NUMBER;
  BEGIN
    -- Check for any disabled constraints
    SELECT COUNT(*) INTO v_count 
    FROM user_constraints 
    WHERE table_name IN ('FACT_SALES', 'DIM_TIME', 'DIM_PRODUCT', 'DIM_CUSTOMER', 'DIM_EMPLOYEE', 'DIM_STATUS')
      AND status = 'DISABLED';
    
    IF v_count > 0 THEN
      DBMS_OUTPUT.PUT_LINE('⚠ WARNING: ' || v_count || ' constraints are disabled');
    ELSE
      DBMS_OUTPUT.PUT_LINE('✓ All constraints are enabled');
    END IF;
  END;
  
  -- Check for any invalid indexes
  SELECT COUNT(*) INTO v_count 
  FROM user_indexes 
  WHERE table_name IN ('FACT_SALES', 'DIM_TIME', 'DIM_PRODUCT', 'DIM_CUSTOMER', 'DIM_EMPLOYEE', 'DIM_STATUS')
    AND status = 'INVALID';
  
  IF v_count > 0 THEN
    DBMS_OUTPUT.PUT_LINE('⚠ WARNING: ' || v_count || ' indexes are invalid');
  ELSE
    DBMS_OUTPUT.PUT_LINE('✓ All indexes are valid');
  END IF;
  
  DBMS_OUTPUT.PUT_LINE('');
END;
/

-- Sample data quality checks
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== DATA QUALITY CHECKS ===');
  
  DECLARE
    v_count NUMBER;
  BEGIN
    -- Check for NULL dates in DIM_TIME
    SELECT COUNT(*) INTO v_count FROM DIM_TIME WHERE full_date IS NULL;
    IF v_count > 0 THEN
      DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || v_count || ' rows in DIM_TIME have NULL full_date');
    ELSE
      DBMS_OUTPUT.PUT_LINE('✓ All DIM_TIME rows have valid full_date');
    END IF;
    
    -- Check for negative amounts in FACT_SALES
    SELECT COUNT(*) INTO v_count FROM FACT_SALES WHERE amount < 0;
    IF v_count > 0 THEN
      DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || v_count || ' rows in FACT_SALES have negative amount');
    ELSE
      DBMS_OUTPUT.PUT_LINE('✓ All FACT_SALES amounts are non-negative');
    END IF;
    
    -- Check for referential integrity (orphaned fact rows)
    SELECT COUNT(*) INTO v_count 
    FROM FACT_SALES fs
    WHERE NOT EXISTS (SELECT 1 FROM DIM_TIME WHERE id = fs.t);
    IF v_count > 0 THEN
      DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || v_count || ' orphaned rows in FACT_SALES (time FK)');
    ELSE
      DBMS_OUTPUT.PUT_LINE('✓ All FACT_SALES rows have valid time FK');
    END IF;
  END;
  
  DBMS_OUTPUT.PUT_LINE('');
END;
/

-- Performance recommendations
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== PERFORMANCE RECOMMENDATIONS ===');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('1. Materialized views are created but not scheduled for refresh');
  DBMS_OUTPUT.PUT_LINE('   Refresh manually: EXEC refresh_all_mvs;');
  DBMS_OUTPUT.PUT_LINE('   Or schedule automatic refresh (see 05_materialized_views.sql)');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('2. For large datasets, consider partitioning FACT_SALES by time');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('3. Monitor index usage with V$OBJECT_USAGE and drop unused indexes');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('4. Run DBMS_STATS.GATHER_SCHEMA_STATS regularly (e.g., weekly)');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

-- Final summary
BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('╔══════════════════════════════════════════════════════════════════╗');
  DBMS_OUTPUT.PUT_LINE('║                  SETUP COMPLETED SUCCESSFULLY                    ║');
  DBMS_OUTPUT.PUT_LINE('╚══════════════════════════════════════════════════════════════════╝');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('✓ STEP 7 COMPLETE: Validation and reporting finished');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('=== WHAT''S BEEN CREATED ===');
  DBMS_OUTPUT.PUT_LINE('• 5 Dimension Tables (with FULL_DATE in DIM_TIME)');
  DBMS_OUTPUT.PUT_LINE('• 1 Fact Table (with CHECK constraints)');
  DBMS_OUTPUT.PUT_LINE('• ' || (SELECT COUNT(*) FROM user_indexes 
                            WHERE table_name IN ('FACT_SALES', 'DIM_TIME', 'DIM_PRODUCT', 
                                                 'DIM_CUSTOMER', 'DIM_EMPLOYEE', 'DIM_STATUS')) 
           || ' Indexes (BITMAP and B-TREE)');
  DBMS_OUTPUT.PUT_LINE('• ' || (SELECT COUNT(*) FROM user_mviews) || ' Materialized Views');
  DBMS_OUTPUT.PUT_LINE('• 1 Stored Procedure (refresh_all_mvs)');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('=== NEXT STEPS ===');
  DBMS_OUTPUT.PUT_LINE('1. Test with Übung 05 queries (../RITT_uebung_05_analytische_funktionen.sql)');
  DBMS_OUTPUT.PUT_LINE('2. Compare performance with original schema');
  DBMS_OUTPUT.PUT_LINE('3. Review materialized views for your reporting needs');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Happy querying! 🚀');
  DBMS_OUTPUT.PUT_LINE('');
END;
/

-- Timing summary
SET TIMING OFF;
