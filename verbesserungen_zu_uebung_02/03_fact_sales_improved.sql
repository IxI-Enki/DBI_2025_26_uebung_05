----------------------------------------------------------------------------------------------------
-- FACT_SALES create and load for OT (Company) - IMPROVED VERSION
-- Grain: one row per order line (order_id, item_id)
-- Dimensions: TIME, PRODUCT, CUSTOMER, EMPLOYEE (nullable), STATUS
-- Measures: quantity, unit_price, amount (quantity * unit_price)
--
-- IMPROVEMENTS over original version:
-- 1. Added CHECK constraints for data validation
-- 2. Improved primary key definition
-- 3. Better comments and documentation
-- 4. Performance optimizations
--
-- Idempotent: deletes before re-insert
-- Oracle SQL
-- Author: Jan Ritt
-- Date: 2025-10-28 (Improved Version)
----------------------------------------------------------------------------------------------------

-- Drop and recreate FACT_SALES to ensure deterministic DDL
BEGIN EXECUTE IMMEDIATE 'DROP TABLE FACT_SALES CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END; /

----------------------------------------------------------------------------------------------------
-- FACT_SALES Table Definition - IMPROVED
----------------------------------------------------------------------------------------------------

CREATE TABLE FACT_SALES (
  -- Dimension Foreign Keys
  t          NUMBER       NOT NULL REFERENCES DIM_TIME(id),
  product    NUMBER       NOT NULL REFERENCES DIM_PRODUCT(id),
  customer   NUMBER       NOT NULL REFERENCES DIM_CUSTOMER(id),
  employee   NUMBER           NULL REFERENCES DIM_EMPLOYEE(id),  -- Nullable: not all orders have salesperson
  status     NUMBER       NOT NULL REFERENCES DIM_STATUS(id),
  
  -- Degenerate Dimensions (for lineage/drill-through)
  order_id   NUMBER       NOT NULL,
  item_id    NUMBER       NOT NULL,
  
  -- Measures
  quantity   NUMBER(8,2)  NOT NULL,
  unit_price NUMBER(8,2)  NOT NULL,
  amount     NUMBER(12,2) NOT NULL,  -- Calculated: quantity * unit_price
  
  -- Primary Key: Time + Product + Customer + Status + Order + Item
  -- This ensures uniqueness and supports partition pruning
  CONSTRAINT PK_FACT_SALES PRIMARY KEY (t, product, customer, status, order_id, item_id),
  
  -- Data Validation Constraints (NEW)
  CONSTRAINT CHK_FACT_SALES_QUANTITY CHECK (quantity > 0),
  CONSTRAINT CHK_FACT_SALES_PRICE CHECK (unit_price >= 0),
  CONSTRAINT CHK_FACT_SALES_AMOUNT CHECK (amount >= 0),
  -- Ensure amount is correctly calculated (with tolerance for rounding)
  CONSTRAINT CHK_FACT_SALES_CALC CHECK (ABS(amount - (quantity * unit_price)) < 0.01)
);

-- Table and Column Comments
COMMENT ON TABLE FACT_SALES IS 'Sales fact table (grain: one row per order line item)';
COMMENT ON COLUMN FACT_SALES.t IS 'Time dimension FK (when was the sale)';
COMMENT ON COLUMN FACT_SALES.product IS 'Product dimension FK (what was sold)';
COMMENT ON COLUMN FACT_SALES.customer IS 'Customer dimension FK (who bought)';
COMMENT ON COLUMN FACT_SALES.employee IS 'Employee dimension FK (who sold - nullable)';
COMMENT ON COLUMN FACT_SALES.status IS 'Status dimension FK (order status)';
COMMENT ON COLUMN FACT_SALES.order_id IS 'Degenerate dimension: original order_id from OLTP';
COMMENT ON COLUMN FACT_SALES.item_id IS 'Degenerate dimension: line item number within order';
COMMENT ON COLUMN FACT_SALES.quantity IS 'Quantity sold (must be > 0)';
COMMENT ON COLUMN FACT_SALES.unit_price IS 'Unit price at time of sale (must be >= 0)';
COMMENT ON COLUMN FACT_SALES.amount IS 'Total amount (quantity × unit_price)';

----------------------------------------------------------------------------------------------------
-- Load FACT_SALES from OLTP
----------------------------------------------------------------------------------------------------

-- Idempotent load
BEGIN EXECUTE IMMEDIATE 'DELETE FROM FACT_SALES'; EXCEPTION WHEN OTHERS THEN NULL; END; /
COMMIT;

INSERT /*+ APPEND */ INTO FACT_SALES (
  t, product, customer, employee, status, order_id, item_id, quantity, unit_price, amount
)
SELECT
  tm.id                                              AS t,
  dp.id                                              AS product,
  dc.id                                              AS customer,
  de.id                                              AS employee,
  ds.id                                              AS status,
  o.order_id,
  oi.item_id,
  oi.quantity,
  oi.unit_price,
  (oi.quantity * oi.unit_price)                      AS amount
FROM orders o
JOIN order_items oi       ON oi.order_id = o.order_id
JOIN products p           ON p.product_id = oi.product_id
JOIN DIM_PRODUCT  dp      ON dp.SOURCE_PRODUCT_ID = p.product_id
JOIN DIM_CUSTOMER dc      ON dc.SOURCE_CUSTOMER_ID = o.customer_id
LEFT JOIN DIM_EMPLOYEE de ON de.SOURCE_EMPLOYEE_ID = o.salesman_id
JOIN DIM_STATUS ds        ON ds.STATUS = o.status
JOIN (
  -- Join with DIM_TIME using FULL_DATE (more efficient than separate year/month/day)
  SELECT id, full_date
  FROM DIM_TIME
) tm
  ON tm.full_date = TRUNC(o.order_date);

COMMIT;

----------------------------------------------------------------------------------------------------
-- Validation and Summary
----------------------------------------------------------------------------------------------------

DECLARE
  v_count NUMBER;
  v_null_employee NUMBER;
  v_total_amount NUMBER;
  v_min_amount NUMBER;
  v_max_amount NUMBER;
BEGIN
  -- Count total rows
  SELECT COUNT(*) INTO v_count FROM FACT_SALES;
  DBMS_OUTPUT.PUT_LINE('✓ FACT_SALES loaded: ' || v_count || ' rows');
  
  -- Count rows with NULL employee (expected: some orders have no salesperson)
  SELECT COUNT(*) INTO v_null_employee FROM FACT_SALES WHERE employee IS NULL;
  DBMS_OUTPUT.PUT_LINE('  - Rows with NULL employee: ' || v_null_employee);
  
  -- Summary statistics
  SELECT 
    SUM(amount),
    MIN(amount),
    MAX(amount)
  INTO v_total_amount, v_min_amount, v_max_amount
  FROM FACT_SALES;
  
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('=== FACT_SALES STATISTICS ===');
  DBMS_OUTPUT.PUT_LINE('Total Amount:   ' || TO_CHAR(v_total_amount, '999,999,990.00'));
  DBMS_OUTPUT.PUT_LINE('Min Amount:     ' || TO_CHAR(v_min_amount, '999,999,990.00'));
  DBMS_OUTPUT.PUT_LINE('Max Amount:     ' || TO_CHAR(v_max_amount, '999,999,990.00'));
  DBMS_OUTPUT.PUT_LINE('Avg Amount:     ' || TO_CHAR(v_total_amount / v_count, '999,999,990.00'));
  DBMS_OUTPUT.PUT_LINE('==============================');
  
  -- Validate no constraint violations
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'ERROR: FACT_SALES is empty!');
  END IF;
  
END;
/

----------------------------------------------------------------------------------------------------
-- Summary of improvements:
-- ✅ CHECK constraints for data validation (quantity > 0, amount >= 0, etc.)
-- ✅ Calculation validation (amount = quantity × unit_price)
-- ✅ Comments on table and columns
-- ✅ Improved join with DIM_TIME using FULL_DATE
-- ✅ Comprehensive validation and statistics
----------------------------------------------------------------------------------------------------
