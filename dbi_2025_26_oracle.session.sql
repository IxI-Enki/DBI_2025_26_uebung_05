----------------------------------------------------------------------------------------------------
-- DBI 2025/26 - Oracle Session File
-- Übung 05: Analytische Funktionen (Window Functions)
-- 
-- Session: localhost:1521/FREEPDB1
-- Author: Jan Ritt
-- Date: 2025-10-28
--
-- Quick Start:
-- 1. Ensure Star Schema from Übung 02 is loaded
-- 2. Execute queries from RITT_uebung_05_analytische_funktionen.sql
-- 3. Optional: Apply improvements from verbesserungen_zu_uebung_02/
----------------------------------------------------------------------------------------------------

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;
SET PAGESIZE 100;
SET FEEDBACK ON;
SET TIMING ON;

-- Clear screen
CLEAR SCREEN;

----------------------------------------------------------------------------------------------------
-- VERIFICATION: Check if Star Schema exists
----------------------------------------------------------------------------------------------------

PROMPT ╔══════════════════════════════════════════════════════════════════╗
PROMPT ║     DBI Übung 05 - Analytische Funktionen                       ║
PROMPT ║     Session: Oracle @ localhost:1521/FREEPDB1                   ║
PROMPT ╚══════════════════════════════════════════════════════════════════╝

PROMPT;
PROMPT Checking Star Schema...
PROMPT;

-- Check if tables exist
SELECT 
  CASE 
    WHEN COUNT(*) = 6 THEN '✓ All required tables exist'
    ELSE '✗ ERROR: Missing tables! Please run Übung 02 setup first'
  END AS status
FROM user_tables
WHERE table_name IN ('FACT_SALES', 'DIM_TIME', 'DIM_PRODUCT', 'DIM_CUSTOMER', 'DIM_EMPLOYEE', 'DIM_STATUS');

-- Show row counts
PROMPT;
PROMPT Current Data:
PROMPT;

SELECT 'DIM_TIME' AS table_name, COUNT(*) AS row_count FROM DIM_TIME
UNION ALL
SELECT 'DIM_PRODUCT', COUNT(*) FROM DIM_PRODUCT
UNION ALL
SELECT 'DIM_CUSTOMER', COUNT(*) FROM DIM_CUSTOMER
UNION ALL
SELECT 'DIM_EMPLOYEE', COUNT(*) FROM DIM_EMPLOYEE
UNION ALL
SELECT 'DIM_STATUS', COUNT(*) FROM DIM_STATUS
UNION ALL
SELECT 'FACT_SALES', COUNT(*) FROM FACT_SALES
ORDER BY 1;

PROMPT;
PROMPT ═══════════════════════════════════════════════════════════════════
PROMPT  Ready to execute queries!
PROMPT  
PROMPT  Files available:
PROMPT  • RITT_uebung_05_analytische_funktionen.sql (all 9 exercises)
PROMPT  • verbesserungen_zu_uebung_02/ (optimized schema)
PROMPT  
PROMPT  Quick execution:
PROMPT  @RITT_uebung_05_analytische_funktionen.sql
PROMPT ═══════════════════════════════════════════════════════════════════
PROMPT;

----------------------------------------------------------------------------------------------------
-- Quick Test: Sample query with window function
----------------------------------------------------------------------------------------------------

PROMPT Testing window functions with sample query...
PROMPT;

-- Quick test: Total sales and rank
SELECT 
  order_id,
  item_id,
  amount,
  SUM(amount) OVER () AS total_sales,
  RANK() OVER (ORDER BY amount DESC) AS rank_by_amount
FROM FACT_SALES
WHERE ROWNUM <= 10
ORDER BY amount DESC;

PROMPT;
PROMPT ✓ Window functions working correctly!
PROMPT;
PROMPT Execute @RITT_uebung_05_analytische_funktionen.sql to run all exercises
PROMPT;
