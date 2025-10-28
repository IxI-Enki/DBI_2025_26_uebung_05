/*******************************************************************************
 * STAR-SCHEMA ERWEITERUNG - Phase 3: Fact Constellation / Galaxy Schema
 *
 * Erstellt zusätzliche Fact-Tabellen für verschiedene Geschäftsprozesse
 * Die Fact-Tabellen teilen sich gemeinsame Dimensionen
 ******************************************************************************/

-- ==============================================================================
-- FACT 2: FACT_INVENTORY (Lagerbestand)
-- ==============================================================================

CREATE TABLE FACT_INVENTORY (
    INVENTORY_ID      NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    
    -- Foreign Keys zu Dimensionen
    PRODUCT           NUMBER        NOT NULL,  -- FK zu DIM_PRODUCT / DIM_PRODUCT_SCD
    T                 NUMBER        NOT NULL,  -- FK zu DIM_TIME
    WAREHOUSE_ID      NUMBER        NOT NULL,  -- FK zu DIM_WAREHOUSE
    
    -- Measures (Kennzahlen)
    QUANTITY_ON_HAND  NUMBER        NOT NULL,  -- Aktueller Lagerbestand
    REORDER_LEVEL     NUMBER        NOT NULL,  -- Mindestbestand
    REORDER_QUANTITY  NUMBER,                  -- Nachbestellmenge
    QUANTITY_RESERVED NUMBER DEFAULT 0,        -- Reserviert für Bestellungen
    QUANTITY_AVAILABLE NUMBER,                 -- Verfügbar = On Hand - Reserved
    UNIT_COST         NUMBER(10,2),           -- Einstandspreis
    TOTAL_VALUE       NUMBER(12,2),           -- Lagerwert = Quantity * Cost
    LAST_STOCK_DATE   DATE,                   -- Letzter Wareneingang
    DAYS_SINCE_LAST_STOCK NUMBER,            -- Tage seit letztem Wareneingang
    STOCK_OUT_DAYS    NUMBER DEFAULT 0,       -- Tage mit Lagerbestand 0
    TURNOVER_RATE     NUMBER(8,2),           -- Umschlagshäufigkeit
    
    -- Constraints
    CONSTRAINT FK_FINV_PRODUCT   FOREIGN KEY (PRODUCT)      REFERENCES DIM_PRODUCT(ID),
    CONSTRAINT FK_FINV_TIME      FOREIGN KEY (T)            REFERENCES DIM_TIME(ID),
    CONSTRAINT FK_FINV_WAREHOUSE FOREIGN KEY (WAREHOUSE_ID) REFERENCES DIM_WAREHOUSE(ID),
    
    CONSTRAINT CHK_FINV_QUANTITY CHECK (QUANTITY_ON_HAND >= 0),
    CONSTRAINT CHK_FINV_RESERVED CHECK (QUANTITY_RESERVED >= 0)
);

COMMENT ON TABLE FACT_INVENTORY IS 'Fact-Tabelle: Lagerbestands-Snapshots (täglich)';
COMMENT ON COLUMN FACT_INVENTORY.QUANTITY_ON_HAND IS 'Physischer Bestand im Lager';
COMMENT ON COLUMN FACT_INVENTORY.QUANTITY_RESERVED IS 'Für Kundenaufträge reserviert';
COMMENT ON COLUMN FACT_INVENTORY.TURNOVER_RATE IS 'Lagerumschlag = Verkäufe / Durchschnittlicher Bestand';

-- Indexes
CREATE BITMAP INDEX idx_finv_product   ON FACT_INVENTORY(PRODUCT);
CREATE BITMAP INDEX idx_finv_time      ON FACT_INVENTORY(T);
CREATE BITMAP INDEX idx_finv_warehouse ON FACT_INVENTORY(WAREHOUSE_ID);

-- Composite Index für häufige Queries
CREATE INDEX idx_finv_prod_wh_date ON FACT_INVENTORY(PRODUCT, WAREHOUSE_ID, T);

-- ==============================================================================
-- FACT 3: FACT_EMPLOYEE_PERFORMANCE (Mitarbeiter-Leistung)
-- ==============================================================================

CREATE TABLE FACT_EMPLOYEE_PERFORMANCE (
    PERFORMANCE_ID    NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    
    -- Foreign Keys zu Dimensionen
    EMPLOYEE          NUMBER        NOT NULL,  -- FK zu DIM_EMPLOYEE
    T                 NUMBER        NOT NULL,  -- FK zu DIM_TIME
    
    -- Measures: Verkaufs-KPIs
    SALES_COUNT       NUMBER        DEFAULT 0,  -- Anzahl Verkäufe
    TOTAL_REVENUE     NUMBER(12,2)  DEFAULT 0,  -- Gesamtumsatz
    AVG_ORDER_VALUE   NUMBER(10,2),             -- Durchschnittlicher Auftragswert
    MAX_ORDER_VALUE   NUMBER(10,2),             -- Höchster Einzelauftrag
    MIN_ORDER_VALUE   NUMBER(10,2),             -- Niedrigster Einzelauftrag
    
    -- Measures: Kunden-KPIs
    NEW_CUSTOMERS     NUMBER        DEFAULT 0,  -- Neu gewonnene Kunden
    REPEAT_CUSTOMERS  NUMBER        DEFAULT 0,  -- Wiederkehrende Kunden
    CUSTOMER_SATISFACTION NUMBER(3,2),          -- Kundenzufriedenheit (1.00 - 5.00)
    
    -- Measures: Arbeitszeit
    HOURS_WORKED      NUMBER(6,2),              -- Gearbeitete Stunden
    HOURS_TRAINING    NUMBER(6,2),              -- Schulungsstunden
    SICK_DAYS         NUMBER,                   -- Krankheitstage
    VACATION_DAYS     NUMBER,                   -- Urlaubstage
    
    -- Measures: Produkt-KPIs
    PRODUCTS_SOLD     NUMBER        DEFAULT 0,  -- Anzahl verkaufter Produkte
    UNIQUE_PRODUCTS   NUMBER        DEFAULT 0,  -- Anzahl verschiedener Produkte
    
    -- Berechnete KPIs
    REVENUE_PER_HOUR  NUMBER(10,2),             -- Umsatz pro Arbeitsstunde
    SALES_TARGET      NUMBER(12,2),             -- Monatliches Verkaufsziel
    TARGET_ACHIEVEMENT_PERCENT NUMBER(5,2),     -- Zielerreichung in %
    
    -- Constraints
    CONSTRAINT FK_FPERF_EMPLOYEE FOREIGN KEY (EMPLOYEE) REFERENCES DIM_EMPLOYEE(ID),
    CONSTRAINT FK_FPERF_TIME     FOREIGN KEY (T)        REFERENCES DIM_TIME(ID),
    
    CONSTRAINT CHK_FPERF_SATISFACTION CHECK (CUSTOMER_SATISFACTION BETWEEN 1.00 AND 5.00),
    CONSTRAINT CHK_FPERF_SALES_COUNT  CHECK (SALES_COUNT >= 0)
);

COMMENT ON TABLE FACT_EMPLOYEE_PERFORMANCE IS 'Fact-Tabelle: Mitarbeiter-Performance-KPIs (monatlich)';
COMMENT ON COLUMN FACT_EMPLOYEE_PERFORMANCE.TARGET_ACHIEVEMENT_PERCENT IS 'Zielerreichung: (Tatsächlicher Umsatz / Ziel) * 100';

-- Indexes
CREATE BITMAP INDEX idx_fperf_employee ON FACT_EMPLOYEE_PERFORMANCE(EMPLOYEE);
CREATE BITMAP INDEX idx_fperf_time     ON FACT_EMPLOYEE_PERFORMANCE(T);

-- ==============================================================================
-- FACT 4: FACT_CUSTOMER_INTERACTION (Kundeninteraktionen)
-- ==============================================================================

CREATE TABLE FACT_CUSTOMER_INTERACTION (
    INTERACTION_ID    NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    
    -- Foreign Keys
    CUSTOMER          NUMBER        NOT NULL,  -- FK zu DIM_CUSTOMER
    T                 NUMBER        NOT NULL,  -- FK zu DIM_TIME
    EMPLOYEE          NUMBER,                  -- FK zu DIM_EMPLOYEE (optional)
    
    -- Measures
    INTERACTION_TYPE  VARCHAR2(30)  NOT NULL,  -- 'Email', 'Phone', 'Chat', 'Store Visit'
    INTERACTION_DURATION_MIN NUMBER,           -- Dauer in Minuten
    ISSUE_RESOLVED    CHAR(1)       DEFAULT 'N',  -- Problem gelöst?
    ESCALATED         CHAR(1)       DEFAULT 'N',  -- Eskaliert?
    FOLLOW_UP_REQUIRED CHAR(1)      DEFAULT 'N',  -- Follow-up nötig?
    SATISFACTION_SCORE NUMBER(3,2),             -- Zufriedenheit (1-5)
    RESPONSE_TIME_MIN NUMBER,                   -- Reaktionszeit in Minuten
    
    -- Constraints
    CONSTRAINT FK_FINT_CUSTOMER FOREIGN KEY (CUSTOMER) REFERENCES DIM_CUSTOMER(ID),
    CONSTRAINT FK_FINT_TIME     FOREIGN KEY (T)        REFERENCES DIM_TIME(ID),
    CONSTRAINT FK_FINT_EMPLOYEE FOREIGN KEY (EMPLOYEE) REFERENCES DIM_EMPLOYEE(ID),
    
    CONSTRAINT CHK_FINT_RESOLVED     CHECK (ISSUE_RESOLVED IN ('Y', 'N')),
    CONSTRAINT CHK_FINT_ESCALATED    CHECK (ESCALATED IN ('Y', 'N')),
    CONSTRAINT CHK_FINT_FOLLOWUP     CHECK (FOLLOW_UP_REQUIRED IN ('Y', 'N')),
    CONSTRAINT CHK_FINT_SATISFACTION CHECK (SATISFACTION_SCORE BETWEEN 1.00 AND 5.00)
);

COMMENT ON TABLE FACT_CUSTOMER_INTERACTION IS 'Fact-Tabelle: Kundenservice-Interaktionen';
COMMENT ON COLUMN FACT_CUSTOMER_INTERACTION.RESPONSE_TIME_MIN IS 'Zeit bis zur ersten Reaktion';

-- Indexes
CREATE BITMAP INDEX idx_fint_customer ON FACT_CUSTOMER_INTERACTION(CUSTOMER);
CREATE BITMAP INDEX idx_fint_time     ON FACT_CUSTOMER_INTERACTION(T);
CREATE BITMAP INDEX idx_fint_employee ON FACT_CUSTOMER_INTERACTION(EMPLOYEE);
CREATE INDEX idx_fint_type ON FACT_CUSTOMER_INTERACTION(INTERACTION_TYPE);

-- ==============================================================================
-- FACT 5: FACT_PRODUCT_RETURNS (Retouren)
-- ==============================================================================

CREATE TABLE FACT_PRODUCT_RETURNS (
    RETURN_ID         NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    
    -- Foreign Keys
    ORIGINAL_ORDER_ID NUMBER,                  -- FK zu FACT_SALES (optional)
    PRODUCT           NUMBER        NOT NULL,  -- FK zu DIM_PRODUCT
    CUSTOMER          NUMBER        NOT NULL,  -- FK zu DIM_CUSTOMER
    T                 NUMBER        NOT NULL,  -- FK zu DIM_TIME (Retourenzeitpunkt)
    WAREHOUSE_ID      NUMBER,                  -- FK zu DIM_WAREHOUSE
    
    -- Measures
    QUANTITY_RETURNED NUMBER        NOT NULL,
    RETURN_AMOUNT     NUMBER(10,2)  NOT NULL,  -- Erstattungsbetrag
    RESTOCKING_FEE    NUMBER(10,2)  DEFAULT 0,
    SHIPPING_COST     NUMBER(10,2),            -- Rücksendekosten
    RETURN_REASON     VARCHAR2(100),           -- 'Defect', 'Wrong Item', 'Changed Mind', etc.
    CONDITION         VARCHAR2(20),            -- 'New', 'Opened', 'Damaged'
    REFUND_METHOD     VARCHAR2(30),            -- 'Original Payment', 'Store Credit', 'Exchange'
    DAYS_SINCE_PURCHASE NUMBER,                -- Tage seit Originalkauf
    RESALEABLE        CHAR(1)       DEFAULT 'Y',
    
    -- Constraints
    CONSTRAINT FK_FRET_PRODUCT   FOREIGN KEY (PRODUCT)      REFERENCES DIM_PRODUCT(ID),
    CONSTRAINT FK_FRET_CUSTOMER  FOREIGN KEY (CUSTOMER)     REFERENCES DIM_CUSTOMER(ID),
    CONSTRAINT FK_FRET_TIME      FOREIGN KEY (T)            REFERENCES DIM_TIME(ID),
    CONSTRAINT FK_FRET_WAREHOUSE FOREIGN KEY (WAREHOUSE_ID) REFERENCES DIM_WAREHOUSE(ID),
    
    CONSTRAINT CHK_FRET_QUANTITY   CHECK (QUANTITY_RETURNED > 0),
    CONSTRAINT CHK_FRET_RESALEABLE CHECK (RESALEABLE IN ('Y', 'N'))
);

COMMENT ON TABLE FACT_PRODUCT_RETURNS IS 'Fact-Tabelle: Produkt-Retouren';
COMMENT ON COLUMN FACT_PRODUCT_RETURNS.RESALEABLE IS 'Kann das Produkt wieder verkauft werden?';

-- Indexes
CREATE BITMAP INDEX idx_fret_product   ON FACT_PRODUCT_RETURNS(PRODUCT);
CREATE BITMAP INDEX idx_fret_customer  ON FACT_PRODUCT_RETURNS(CUSTOMER);
CREATE BITMAP INDEX idx_fret_time      ON FACT_PRODUCT_RETURNS(T);
CREATE INDEX idx_fret_reason ON FACT_PRODUCT_RETURNS(RETURN_REASON);

-- ==============================================================================
-- VIEWS: Cross-Fact Analysen
-- ==============================================================================

-- View 1: Verkaufs- und Retourenrate pro Produkt
CREATE OR REPLACE VIEW V_PRODUCT_SALES_RETURNS AS
SELECT 
    p.ID AS PRODUCT_ID,
    p.PRODUCT_NAME,
    p.PRODUCT_CATEGORY,
    COALESCE(s.TOTAL_SALES, 0) AS TOTAL_SALES,
    COALESCE(s.SALES_QUANTITY, 0) AS SALES_QUANTITY,
    COALESCE(r.RETURN_COUNT, 0) AS RETURN_COUNT,
    COALESCE(r.RETURN_QUANTITY, 0) AS RETURN_QUANTITY,
    COALESCE(r.RETURN_AMOUNT, 0) AS RETURN_AMOUNT,
    CASE 
        WHEN COALESCE(s.SALES_QUANTITY, 0) = 0 THEN 0
        ELSE ROUND(COALESCE(r.RETURN_QUANTITY, 0) / s.SALES_QUANTITY * 100, 2)
    END AS RETURN_RATE_PERCENT
FROM 
    DIM_PRODUCT p
LEFT JOIN (
    SELECT 
        PRODUCT,
        SUM(AMOUNT) AS TOTAL_SALES,
        COUNT(*) AS SALES_QUANTITY
    FROM FACT_SALES
    GROUP BY PRODUCT
) s ON p.ID = s.PRODUCT
LEFT JOIN (
    SELECT 
        PRODUCT,
        COUNT(*) AS RETURN_COUNT,
        SUM(QUANTITY_RETURNED) AS RETURN_QUANTITY,
        SUM(RETURN_AMOUNT) AS RETURN_AMOUNT
    FROM FACT_PRODUCT_RETURNS
    GROUP BY PRODUCT
) r ON p.ID = r.PRODUCT;

COMMENT ON TABLE V_PRODUCT_SALES_RETURNS IS 'View: Verkäufe vs. Retouren pro Produkt';

-- View 2: Mitarbeiter-Performance mit Kundenzufriedenheit
CREATE OR REPLACE VIEW V_EMPLOYEE_FULL_PERFORMANCE AS
SELECT 
    e.ID AS EMPLOYEE_ID,
    e.NAME AS EMPLOYEE_NAME,
    e.JOB_TITLE,
    -- Sales Performance
    COALESCE(s.TOTAL_SALES, 0) AS TOTAL_SALES,
    COALESCE(s.SALES_COUNT, 0) AS SALES_COUNT,
    -- KPI Performance
    p.CUSTOMER_SATISFACTION,
    p.REVENUE_PER_HOUR,
    p.TARGET_ACHIEVEMENT_PERCENT,
    -- Customer Interactions
    COALESCE(i.INTERACTION_COUNT, 0) AS INTERACTION_COUNT,
    COALESCE(i.AVG_RESOLUTION_TIME, 0) AS AVG_RESOLUTION_TIME_MIN
FROM 
    DIM_EMPLOYEE e
LEFT JOIN (
    SELECT 
        EMPLOYEE,
        SUM(AMOUNT) AS TOTAL_SALES,
        COUNT(*) AS SALES_COUNT
    FROM FACT_SALES
    WHERE EMPLOYEE IS NOT NULL
    GROUP BY EMPLOYEE
) s ON e.ID = s.EMPLOYEE
LEFT JOIN FACT_EMPLOYEE_PERFORMANCE p ON e.ID = p.EMPLOYEE
LEFT JOIN (
    SELECT 
        EMPLOYEE,
        COUNT(*) AS INTERACTION_COUNT,
        AVG(INTERACTION_DURATION_MIN) AS AVG_RESOLUTION_TIME
    FROM FACT_CUSTOMER_INTERACTION
    WHERE EMPLOYEE IS NOT NULL
    GROUP BY EMPLOYEE
) i ON e.ID = i.EMPLOYEE;

COMMENT ON TABLE V_EMPLOYEE_FULL_PERFORMANCE IS 'View: Umfassende Mitarbeiter-Performance-Analyse';

-- ==============================================================================
-- Stored Procedure: ETL für FACT_INVENTORY (täglicher Snapshot)
-- ==============================================================================

CREATE OR REPLACE PROCEDURE sp_etl_inventory_snapshot(
    p_date IN DATE DEFAULT TRUNC(SYSDATE)
)
IS
    v_time_id NUMBER;
BEGIN
    -- Hole TIME_ID für das Datum
    SELECT ID INTO v_time_id FROM DIM_TIME WHERE FULL_DATE = p_date;
    
    -- Füge Inventory-Snapshot für alle Produkte/Warehouses ein
    INSERT INTO FACT_INVENTORY (
        PRODUCT,
        T,
        WAREHOUSE_ID,
        QUANTITY_ON_HAND,
        REORDER_LEVEL,
        REORDER_QUANTITY,
        QUANTITY_RESERVED,
        QUANTITY_AVAILABLE,
        UNIT_COST,
        TOTAL_VALUE,
        LAST_STOCK_DATE,
        DAYS_SINCE_LAST_STOCK
    )
    SELECT 
        p.ID AS PRODUCT,
        v_time_id AS T,
        w.ID AS WAREHOUSE_ID,
        -- Hier würden normalerweise Daten aus einem operativen System kommen
        0 AS QUANTITY_ON_HAND,
        100 AS REORDER_LEVEL,
        500 AS REORDER_QUANTITY,
        0 AS QUANTITY_RESERVED,
        0 AS QUANTITY_AVAILABLE,
        0 AS UNIT_COST,
        0 AS TOTAL_VALUE,
        NULL AS LAST_STOCK_DATE,
        NULL AS DAYS_SINCE_LAST_STOCK
    FROM 
        DIM_PRODUCT p
    CROSS JOIN 
        DIM_WAREHOUSE w
    WHERE NOT EXISTS (
        SELECT 1 
        FROM FACT_INVENTORY fi 
        WHERE fi.PRODUCT = p.ID 
          AND fi.T = v_time_id 
          AND fi.WAREHOUSE_ID = w.ID
    );
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Kein TIME-Eintrag für Datum ' || p_date);
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

COMMIT;

/*******************************************************************************
 * ENDE - Fact Constellation Schema erstellt
 * 
 * Struktur:
 * 
 *        DIM_TIME ----+----+----+----+
 *                     |    |    |    |
 *                     v    v    v    v
 * DIM_PRODUCT --> FACT_SALES | FACT_INVENTORY | FACT_RETURNS | FACT_PERFORMANCE
 *                     |    |    |    |
 * DIM_CUSTOMER -------+    |    +----+
 * DIM_EMPLOYEE ------------+----+
 * DIM_WAREHOUSE ------------+----+
 * 
 * Vorteile:
 * - Mehrere Geschäftsprozesse modelliert
 * - Dimensionen werden wiederverwendet
 * - Cross-Fact Analysen möglich
 * - Trennung der Concerns
 * 
 * Nächste Schritte:
 * - Test-Daten für alle Fact-Tabellen generieren
 * - Beispiel-Analysen durchführen
 * - Performance-Tuning
 ******************************************************************************/
