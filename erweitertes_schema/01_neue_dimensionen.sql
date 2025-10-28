/*******************************************************************************
 * STAR-SCHEMA ERWEITERUNG - Phase 1: Neue Dimensionen
 *
 * Erstellt zusätzliche Dimensions-Tabellen für detailliertere Analysen
 * Bleibt im Star-Schema Prinzip (flache, denormalisierte Dimensionen)
 ******************************************************************************/

-- ==============================================================================
-- 1. DIM_WAREHOUSE (Lagerstandorte)
-- ==============================================================================

CREATE TABLE DIM_WAREHOUSE (
    ID                NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    WAREHOUSE_CODE    VARCHAR2(10)  NOT NULL UNIQUE,
    WAREHOUSE_NAME    VARCHAR2(100) NOT NULL,
    ADDRESS           VARCHAR2(200),
    CITY              VARCHAR2(50),
    POSTAL_CODE       VARCHAR2(20),
    COUNTRY           VARCHAR2(50),
    REGION            VARCHAR2(50),
    CAPACITY_SQM      NUMBER,
    MANAGER_NAME      VARCHAR2(100),
    MANAGER_EMAIL     VARCHAR2(100),
    PHONE             VARCHAR2(20),
    IS_ACTIVE         CHAR(1) DEFAULT 'Y',
    OPENED_DATE       DATE,
    
    CONSTRAINT CHK_WH_ACTIVE CHECK (IS_ACTIVE IN ('Y', 'N'))
);

COMMENT ON TABLE DIM_WAREHOUSE IS 'Dimension: Lagerstandorte/Warehouses';
COMMENT ON COLUMN DIM_WAREHOUSE.ID IS 'Surrogate Key';
COMMENT ON COLUMN DIM_WAREHOUSE.WAREHOUSE_CODE IS 'Business Key (z.B. "WH-WIEN", "WH-LINZ")';
COMMENT ON COLUMN DIM_WAREHOUSE.CAPACITY_SQM IS 'Lagerkapazität in Quadratmetern';

-- ==============================================================================
-- 2. DIM_SHIPPING_METHOD (Versandarten)
-- ==============================================================================

CREATE TABLE DIM_SHIPPING_METHOD (
    ID                NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    METHOD_CODE       VARCHAR2(10)  NOT NULL UNIQUE,
    METHOD_NAME       VARCHAR2(50)  NOT NULL,
    DESCRIPTION       VARCHAR2(200),
    CARRIER           VARCHAR2(50),      -- Versanddienstleister
    SERVICE_LEVEL     VARCHAR2(20),      -- z.B. "Standard", "Express", "Same Day"
    AVG_DELIVERY_DAYS NUMBER,
    MIN_DELIVERY_DAYS NUMBER,
    MAX_DELIVERY_DAYS NUMBER,
    BASE_COST         NUMBER(8,2),
    COST_PER_KG       NUMBER(6,2),
    TRACKING_AVAILABLE CHAR(1) DEFAULT 'Y',
    INSURANCE_INCLUDED CHAR(1) DEFAULT 'N',
    IS_ACTIVE         CHAR(1) DEFAULT 'Y',
    
    CONSTRAINT CHK_SHIP_TRACKING CHECK (TRACKING_AVAILABLE IN ('Y', 'N')),
    CONSTRAINT CHK_SHIP_INSURANCE CHECK (INSURANCE_INCLUDED IN ('Y', 'N')),
    CONSTRAINT CHK_SHIP_ACTIVE CHECK (IS_ACTIVE IN ('Y', 'N'))
);

COMMENT ON TABLE DIM_SHIPPING_METHOD IS 'Dimension: Versandmethoden';
COMMENT ON COLUMN DIM_SHIPPING_METHOD.METHOD_CODE IS 'Business Key (z.B. "STD", "EXP", "SAMEDAY")';
COMMENT ON COLUMN DIM_SHIPPING_METHOD.SERVICE_LEVEL IS 'Geschwindigkeit des Versands';

-- ==============================================================================
-- 3. DIM_PROMOTION (Marketing-Aktionen)
-- ==============================================================================

CREATE TABLE DIM_PROMOTION (
    ID                NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    PROMOTION_CODE    VARCHAR2(20)  NOT NULL UNIQUE,
    PROMOTION_NAME    VARCHAR2(100) NOT NULL,
    DESCRIPTION       VARCHAR2(500),
    PROMOTION_TYPE    VARCHAR2(30),      -- z.B. "Percentage Discount", "Fixed Amount", "BOGO"
    DISCOUNT_PERCENT  NUMBER(5,2),
    DISCOUNT_AMOUNT   NUMBER(10,2),
    START_DATE        DATE NOT NULL,
    END_DATE          DATE NOT NULL,
    MIN_ORDER_VALUE   NUMBER(10,2),
    MAX_DISCOUNT      NUMBER(10,2),
    IS_ACTIVE         CHAR(1) DEFAULT 'Y',
    
    CONSTRAINT CHK_PROMO_DATES CHECK (END_DATE >= START_DATE),
    CONSTRAINT CHK_PROMO_ACTIVE CHECK (IS_ACTIVE IN ('Y', 'N'))
);

COMMENT ON TABLE DIM_PROMOTION IS 'Dimension: Marketing-Promotions und Rabattaktionen';
COMMENT ON COLUMN DIM_PROMOTION.PROMOTION_TYPE IS 'Art der Promotion (Prozent, Festbetrag, Buy-One-Get-One)';

-- ==============================================================================
-- 4. DIM_PAYMENT_METHOD (Zahlungsmethoden)
-- ==============================================================================

CREATE TABLE DIM_PAYMENT_METHOD (
    ID                NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    METHOD_CODE       VARCHAR2(10)  NOT NULL UNIQUE,
    METHOD_NAME       VARCHAR2(50)  NOT NULL,
    DESCRIPTION       VARCHAR2(200),
    PROVIDER          VARCHAR2(50),      -- z.B. "Visa", "PayPal", "Klarna"
    TRANSACTION_FEE_PERCENT NUMBER(5,2),
    TRANSACTION_FEE_FIXED   NUMBER(6,2),
    PROCESSING_TIME_DAYS    NUMBER,
    REFUND_POLICY     VARCHAR2(200),
    REQUIRES_VERIFICATION CHAR(1) DEFAULT 'N',
    IS_ACTIVE         CHAR(1) DEFAULT 'Y',
    
    CONSTRAINT CHK_PAY_VERIFY CHECK (REQUIRES_VERIFICATION IN ('Y', 'N')),
    CONSTRAINT CHK_PAY_ACTIVE CHECK (IS_ACTIVE IN ('Y', 'N'))
);

COMMENT ON TABLE DIM_PAYMENT_METHOD IS 'Dimension: Zahlungsmethoden';
COMMENT ON COLUMN DIM_PAYMENT_METHOD.TRANSACTION_FEE_PERCENT IS 'Prozentuale Transaktionsgebühr';
COMMENT ON COLUMN DIM_PAYMENT_METHOD.TRANSACTION_FEE_FIXED IS 'Fixe Transaktionsgebühr pro Zahlung';

-- ==============================================================================
-- 5. FACT_SALES erweitern mit neuen Foreign Keys
-- ==============================================================================

ALTER TABLE FACT_SALES ADD (
    WAREHOUSE_ID       NUMBER,
    SHIPPING_METHOD_ID NUMBER,
    PROMOTION_ID       NUMBER,
    PAYMENT_METHOD_ID  NUMBER,
    
    -- Zusätzliche Measures
    SHIPPING_COST      NUMBER(10,2),
    DISCOUNT_AMOUNT    NUMBER(10,2),
    TAX_AMOUNT         NUMBER(10,2),
    NET_AMOUNT         NUMBER(10,2),
    
    CONSTRAINT FK_SALES_WAREHOUSE      FOREIGN KEY (WAREHOUSE_ID)       REFERENCES DIM_WAREHOUSE(ID),
    CONSTRAINT FK_SALES_SHIPPING       FOREIGN KEY (SHIPPING_METHOD_ID) REFERENCES DIM_SHIPPING_METHOD(ID),
    CONSTRAINT FK_SALES_PROMOTION      FOREIGN KEY (PROMOTION_ID)       REFERENCES DIM_PROMOTION(ID),
    CONSTRAINT FK_SALES_PAYMENT        FOREIGN KEY (PAYMENT_METHOD_ID)  REFERENCES DIM_PAYMENT_METHOD(ID)
);

COMMENT ON COLUMN FACT_SALES.WAREHOUSE_ID IS 'Lager, von dem versandt wurde';
COMMENT ON COLUMN FACT_SALES.SHIPPING_COST IS 'Versandkosten für diesen Auftrag';
COMMENT ON COLUMN FACT_SALES.DISCOUNT_AMOUNT IS 'Rabattbetrag durch Promotion';
COMMENT ON COLUMN FACT_SALES.TAX_AMOUNT IS 'Steuerbetrag (MwSt)';
COMMENT ON COLUMN FACT_SALES.NET_AMOUNT IS 'Nettobetrag (Brutto minus Rabatt)';

-- ==============================================================================
-- Indexes für Performance
-- ==============================================================================

-- Bitmap Indexes für neue Foreign Keys in FACT_SALES
CREATE BITMAP INDEX idx_fact_sales_warehouse      ON FACT_SALES(WAREHOUSE_ID);
CREATE BITMAP INDEX idx_fact_sales_shipping       ON FACT_SALES(SHIPPING_METHOD_ID);
CREATE BITMAP INDEX idx_fact_sales_promotion      ON FACT_SALES(PROMOTION_ID);
CREATE BITMAP INDEX idx_fact_sales_payment        ON FACT_SALES(PAYMENT_METHOD_ID);

-- B-Tree Indexes für Business Keys
CREATE INDEX idx_warehouse_code      ON DIM_WAREHOUSE(WAREHOUSE_CODE);
CREATE INDEX idx_shipping_code       ON DIM_SHIPPING_METHOD(METHOD_CODE);
CREATE INDEX idx_promotion_code      ON DIM_PROMOTION(PROMOTION_CODE);
CREATE INDEX idx_payment_code        ON DIM_PAYMENT_METHOD(METHOD_CODE);

-- Indexes für Datumsbereich-Queries
CREATE INDEX idx_promotion_dates ON DIM_PROMOTION(START_DATE, END_DATE);

COMMIT;

/*******************************************************************************
 * ENDE - Neue Dimensionen erstellt
 * 
 * Nächste Schritte:
 * 1. Test-Daten laden (siehe 01_neue_dimensionen_data.sql)
 * 2. Phase 2: Slowly Changing Dimensions (siehe 02_scd_implementation.sql)
 * 3. Phase 3: Fact Constellation (siehe 03_fact_constellation.sql)
 ******************************************************************************/
