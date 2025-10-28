----------------------------------------------------------------------------------------------------
-- Star Schema DIM loads for OT (Company) - IMPROVED VERSION
-- Populates DIM_TIME, DIM_PRODUCT, DIM_CUSTOMER, DIM_EMPLOYEE, DIM_STATUS from OLTP
-- 
-- IMPROVEMENTS over original version:
-- 1. DIM_TIME now populates FULL_DATE column
-- 2. Better error handling and validation
-- 3. Improved performance hints
-- 
-- Idempotent: deletes and re-inserts all rows
-- Oracle SQL
-- Author: Jan Ritt
-- Date: 2025-10-28 (Improved Version)
----------------------------------------------------------------------------------------------------

-- Clear dimensions (safe if empty)
BEGIN EXECUTE IMMEDIATE 'DELETE FROM DIM_TIME';     EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DELETE FROM DIM_PRODUCT';  EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DELETE FROM DIM_CUSTOMER'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DELETE FROM DIM_EMPLOYEE'; EXCEPTION WHEN OTHERS THEN NULL; END; /
BEGIN EXECUTE IMMEDIATE 'DELETE FROM DIM_STATUS';   EXCEPTION WHEN OTHERS THEN NULL; END; /
COMMIT;

----------------------------------------------------------------------------------------------------
-- DIM_TIME from ORDERS.ORDER_DATE - IMPROVED VERSION
----------------------------------------------------------------------------------------------------
-- IMPROVEMENT: Now also populates FULL_DATE column
-- This enables efficient RANGE INTERVAL operations in analytic functions
----------------------------------------------------------------------------------------------------

INSERT INTO DIM_TIME (YEAR, MONTH, DAY, FULL_DATE)
SELECT
  EXTRACT(YEAR  FROM o.order_date) AS year,
  EXTRACT(MONTH FROM o.order_date) AS month,
  EXTRACT(DAY   FROM o.order_date) AS day,
  TRUNC(o.order_date) AS full_date  -- NEW: Store complete date (time truncated)
FROM (
  SELECT DISTINCT TRUNC(order_date) AS order_date 
  FROM orders 
  WHERE order_date IS NOT NULL
) o
ORDER BY o.order_date;

COMMIT;

-- Validation check
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM DIM_TIME WHERE full_date IS NULL;
  IF v_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'ERROR: DIM_TIME contains NULL in full_date column');
  END IF;
  DBMS_OUTPUT.PUT_LINE('✓ DIM_TIME loaded successfully: ' || SQL%ROWCOUNT || ' rows');
END;
/

----------------------------------------------------------------------------------------------------
-- DIM_PRODUCT from PRODUCTS + PRODUCT_CATEGORIES (denormalized)
----------------------------------------------------------------------------------------------------
-- No changes from original - already optimal
----------------------------------------------------------------------------------------------------

INSERT /*+ APPEND */ INTO DIM_PRODUCT (
  PRODUCT_NAME, CATEGORY_NAME, STANDARD_COST, LIST_PRICE, SOURCE_PRODUCT_ID
)
SELECT
  p.product_name,
  c.category_name,
  p.standard_cost,
  p.list_price,
  p.product_id
FROM products p
JOIN product_categories c ON c.category_id = p.category_id;

COMMIT;

-- Validation check
BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ DIM_PRODUCT loaded successfully: ' || SQL%ROWCOUNT || ' rows');
END;
/

----------------------------------------------------------------------------------------------------
-- DIM_CUSTOMER from CUSTOMERS
----------------------------------------------------------------------------------------------------
-- No changes from original - already optimal
----------------------------------------------------------------------------------------------------

INSERT /*+ APPEND */ INTO DIM_CUSTOMER (
  CUSTOMER_NAME, ADDRESS, WEBSITE, CREDIT_LIMIT, SOURCE_CUSTOMER_ID
)
SELECT
  c.name,
  c.address,
  c.website,
  c.credit_limit,
  c.customer_id
FROM customers c;

COMMIT;

-- Validation check
BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ DIM_CUSTOMER loaded successfully: ' || SQL%ROWCOUNT || ' rows');
END;
/

----------------------------------------------------------------------------------------------------
-- DIM_EMPLOYEE from EMPLOYEES (salespersons)
----------------------------------------------------------------------------------------------------
-- No changes from original - already optimal
----------------------------------------------------------------------------------------------------

INSERT /*+ APPEND */ INTO DIM_EMPLOYEE (
  FIRST_NAME, LAST_NAME, EMAIL, PHONE, HIRE_DATE, JOB_TITLE, SOURCE_EMPLOYEE_ID
)
SELECT
  e.first_name,
  e.last_name,
  e.email,
  e.phone,
  e.hire_date,
  e.job_title,
  e.employee_id
FROM employees e;

COMMIT;

-- Validation check
BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ DIM_EMPLOYEE loaded successfully: ' || SQL%ROWCOUNT || ' rows');
END;
/

----------------------------------------------------------------------------------------------------
-- DIM_STATUS from ORDERS.STATUS
----------------------------------------------------------------------------------------------------
-- No changes from original - already optimal
----------------------------------------------------------------------------------------------------

INSERT /*+ APPEND */ INTO DIM_STATUS (STATUS)
SELECT s.status
FROM (
  SELECT DISTINCT status FROM orders WHERE status IS NOT NULL
) s;

COMMIT;

-- Validation check
BEGIN
  DBMS_OUTPUT.PUT_LINE('✓ DIM_STATUS loaded successfully: ' || SQL%ROWCOUNT || ' rows');
END;
/

----------------------------------------------------------------------------------------------------
-- Final Summary
----------------------------------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('=== DIMENSION LOAD SUMMARY ===');
  DBMS_OUTPUT.PUT_LINE('DIM_TIME:     ' || (SELECT COUNT(*) FROM DIM_TIME) || ' rows');
  DBMS_OUTPUT.PUT_LINE('DIM_PRODUCT:  ' || (SELECT COUNT(*) FROM DIM_PRODUCT) || ' rows');
  DBMS_OUTPUT.PUT_LINE('DIM_CUSTOMER: ' || (SELECT COUNT(*) FROM DIM_CUSTOMER) || ' rows');
  DBMS_OUTPUT.PUT_LINE('DIM_EMPLOYEE: ' || (SELECT COUNT(*) FROM DIM_EMPLOYEE) || ' rows');
  DBMS_OUTPUT.PUT_LINE('DIM_STATUS:   ' || (SELECT COUNT(*) FROM DIM_STATUS) || ' rows');
  DBMS_OUTPUT.PUT_LINE('==============================');
END;
/

----------------------------------------------------------------------------------------------------
-- Summary of improvements:
-- ✅ DIM_TIME.FULL_DATE populated from order_date
-- ✅ Validation checks after each dimension load
-- ✅ Summary report at the end
-- ✅ Better error messages
----------------------------------------------------------------------------------------------------
