/*******************************************************************************
 * STAR-SCHEMA ERWEITERUNG - Phase 2: Slowly Changing Dimensions (SCD Type 2)
 *
 * Implementiert Historisierung für Produktpreise und andere veränderliche Attribute
 * SCD Type 2: Neue Version bei Änderung, alte Version bleibt erhalten
 ******************************************************************************/

-- ==============================================================================
-- 1. DIM_PRODUCT_SCD (Produkte mit Historisierung)
-- ==============================================================================

CREATE TABLE DIM_PRODUCT_SCD (
    ID                NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Business Key
    PRODUCT_ID        NUMBER        NOT NULL,  -- Originale Produkt-ID (unveränderlich)
    
    -- Attribute (können sich ändern)
    PRODUCT_NAME      VARCHAR2(100) NOT NULL,
    PRODUCT_CATEGORY  VARCHAR2(50),
    DESCRIPTION       VARCHAR2(500),
    PRICE             NUMBER(10,2)  NOT NULL,
    COST              NUMBER(10,2),
    SUPPLIER          VARCHAR2(100),
    SUPPLIER_CODE     VARCHAR2(50),
    WEIGHT_KG         NUMBER(8,3),
    IS_DISCONTINUED   CHAR(1) DEFAULT 'N',
    
    -- SCD Type 2 Metadata
    VALID_FROM        DATE          NOT NULL,
    VALID_TO          DATE,                    -- NULL = aktuelle Version
    IS_CURRENT        CHAR(1)       DEFAULT 'Y',
    VERSION           NUMBER        DEFAULT 1,
    
    CONSTRAINT CHK_PROD_SCD_CURRENT CHECK (IS_CURRENT IN ('Y', 'N')),
    CONSTRAINT CHK_PROD_SCD_DATES   CHECK (VALID_TO IS NULL OR VALID_TO >= VALID_FROM),
    CONSTRAINT CHK_PROD_DISCONTINUED CHECK (IS_DISCONTINUED IN ('Y', 'N'))
);

COMMENT ON TABLE DIM_PRODUCT_SCD IS 'Produkt-Dimension mit Historisierung (SCD Type 2)';
COMMENT ON COLUMN DIM_PRODUCT_SCD.PRODUCT_ID IS 'Business Key - bleibt gleich bei Versionsänderungen';
COMMENT ON COLUMN DIM_PRODUCT_SCD.VALID_FROM IS 'Gültig ab diesem Datum';
COMMENT ON COLUMN DIM_PRODUCT_SCD.VALID_TO IS 'Gültig bis zu diesem Datum (NULL = aktuell)';
COMMENT ON COLUMN DIM_PRODUCT_SCD.IS_CURRENT IS 'Y = aktuelle Version, N = historische Version';
COMMENT ON COLUMN DIM_PRODUCT_SCD.VERSION IS 'Versionsnummer (1, 2, 3, ...)';

-- ==============================================================================
-- 2. Indexes für SCD-Tabelle
-- ==============================================================================

-- Performance-kritisch: Lookup der aktuellen Version
CREATE INDEX idx_prod_scd_current    ON DIM_PRODUCT_SCD(PRODUCT_ID, IS_CURRENT);

-- Zeitreise-Queries: Welche Version war zu einem bestimmten Datum gültig?
CREATE INDEX idx_prod_scd_timetravel ON DIM_PRODUCT_SCD(PRODUCT_ID, VALID_FROM, VALID_TO);

-- Historische Analysen
CREATE INDEX idx_prod_scd_dates      ON DIM_PRODUCT_SCD(VALID_FROM, VALID_TO);

-- ==============================================================================
-- 3. View: Nur aktuelle Produkte
-- ==============================================================================

CREATE OR REPLACE VIEW V_DIM_PRODUCT_CURRENT AS
SELECT 
    ID,
    PRODUCT_ID,
    PRODUCT_NAME,
    PRODUCT_CATEGORY,
    DESCRIPTION,
    PRICE,
    COST,
    SUPPLIER,
    SUPPLIER_CODE,
    WEIGHT_KG,
    IS_DISCONTINUED,
    VALID_FROM,
    VERSION
FROM 
    DIM_PRODUCT_SCD
WHERE 
    IS_CURRENT = 'Y';

COMMENT ON TABLE V_DIM_PRODUCT_CURRENT IS 'View: Zeigt nur aktuelle Produktversionen';

-- ==============================================================================
-- 4. Stored Procedure: Neues Produkt einfügen
-- ==============================================================================

CREATE OR REPLACE PROCEDURE sp_insert_product_scd(
    p_product_id        IN NUMBER,
    p_product_name      IN VARCHAR2,
    p_product_category  IN VARCHAR2,
    p_description       IN VARCHAR2,
    p_price             IN NUMBER,
    p_cost              IN NUMBER,
    p_supplier          IN VARCHAR2,
    p_supplier_code     IN VARCHAR2,
    p_weight_kg         IN NUMBER,
    p_valid_from        IN DATE DEFAULT SYSDATE
)
IS
BEGIN
    INSERT INTO DIM_PRODUCT_SCD (
        PRODUCT_ID,
        PRODUCT_NAME,
        PRODUCT_CATEGORY,
        DESCRIPTION,
        PRICE,
        COST,
        SUPPLIER,
        SUPPLIER_CODE,
        WEIGHT_KG,
        IS_DISCONTINUED,
        VALID_FROM,
        VALID_TO,
        IS_CURRENT,
        VERSION
    ) VALUES (
        p_product_id,
        p_product_name,
        p_product_category,
        p_description,
        p_price,
        p_cost,
        p_supplier,
        p_supplier_code,
        p_weight_kg,
        'N',
        p_valid_from,
        NULL,
        'Y',
        1
    );
    
    COMMIT;
END;
/

-- ==============================================================================
-- 5. Stored Procedure: Produkt aktualisieren (neue Version erstellen)
-- ==============================================================================

CREATE OR REPLACE PROCEDURE sp_update_product_scd(
    p_product_id        IN NUMBER,
    p_product_name      IN VARCHAR2 DEFAULT NULL,
    p_product_category  IN VARCHAR2 DEFAULT NULL,
    p_description       IN VARCHAR2 DEFAULT NULL,
    p_price             IN NUMBER DEFAULT NULL,
    p_cost              IN NUMBER DEFAULT NULL,
    p_supplier          IN VARCHAR2 DEFAULT NULL,
    p_supplier_code     IN VARCHAR2 DEFAULT NULL,
    p_weight_kg         IN NUMBER DEFAULT NULL,
    p_is_discontinued   IN CHAR DEFAULT NULL,
    p_effective_date    IN DATE DEFAULT SYSDATE
)
IS
    v_current_id        NUMBER;
    v_version           NUMBER;
    v_name              VARCHAR2(100);
    v_category          VARCHAR2(50);
    v_desc              VARCHAR2(500);
    v_price             NUMBER(10,2);
    v_cost              NUMBER(10,2);
    v_supplier          VARCHAR2(100);
    v_supplier_code     VARCHAR2(50);
    v_weight            NUMBER(8,3);
    v_discontinued      CHAR(1);
BEGIN
    -- Hole aktuelle Version
    SELECT 
        ID, VERSION, PRODUCT_NAME, PRODUCT_CATEGORY, DESCRIPTION, 
        PRICE, COST, SUPPLIER, SUPPLIER_CODE, WEIGHT_KG, IS_DISCONTINUED
    INTO 
        v_current_id, v_version, v_name, v_category, v_desc,
        v_price, v_cost, v_supplier, v_supplier_code, v_weight, v_discontinued
    FROM 
        DIM_PRODUCT_SCD
    WHERE 
        PRODUCT_ID = p_product_id
        AND IS_CURRENT = 'Y';
    
    -- Setze aktuelle Version auf inaktiv
    UPDATE DIM_PRODUCT_SCD
    SET 
        IS_CURRENT = 'N',
        VALID_TO = p_effective_date - 1
    WHERE 
        ID = v_current_id;
    
    -- Erstelle neue Version mit aktualisierten Werten
    INSERT INTO DIM_PRODUCT_SCD (
        PRODUCT_ID,
        PRODUCT_NAME,
        PRODUCT_CATEGORY,
        DESCRIPTION,
        PRICE,
        COST,
        SUPPLIER,
        SUPPLIER_CODE,
        WEIGHT_KG,
        IS_DISCONTINUED,
        VALID_FROM,
        VALID_TO,
        IS_CURRENT,
        VERSION
    ) VALUES (
        p_product_id,
        NVL(p_product_name, v_name),
        NVL(p_product_category, v_category),
        NVL(p_description, v_desc),
        NVL(p_price, v_price),
        NVL(p_cost, v_cost),
        NVL(p_supplier, v_supplier),
        NVL(p_supplier_code, v_supplier_code),
        NVL(p_weight_kg, v_weight),
        NVL(p_is_discontinued, v_discontinued),
        p_effective_date,
        NULL,
        'Y',
        v_version + 1
    );
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Produkt mit ID ' || p_product_id || ' nicht gefunden');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- ==============================================================================
-- 6. Function: Ermittle Produkt-Version zu einem bestimmten Zeitpunkt
-- ==============================================================================

CREATE OR REPLACE FUNCTION fn_get_product_at_date(
    p_product_id IN NUMBER,
    p_as_of_date IN DATE
) RETURN NUMBER
IS
    v_dimension_id NUMBER;
BEGIN
    SELECT ID
    INTO v_dimension_id
    FROM DIM_PRODUCT_SCD
    WHERE PRODUCT_ID = p_product_id
      AND VALID_FROM <= p_as_of_date
      AND (VALID_TO IS NULL OR VALID_TO >= p_as_of_date);
    
    RETURN v_dimension_id;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN TOO_MANY_ROWS THEN
        -- Fehler: Überlappende Zeiträume (sollte nicht vorkommen)
        RAISE_APPLICATION_ERROR(-20002, 'Dateninkonsistenz: Mehrere aktive Versionen gefunden');
END;
/

-- ==============================================================================
-- 7. View: Preis-Historie pro Produkt
-- ==============================================================================

CREATE OR REPLACE VIEW V_PRODUCT_PRICE_HISTORY AS
SELECT 
    PRODUCT_ID,
    PRODUCT_NAME,
    PRICE,
    VALID_FROM,
    VALID_TO,
    VERSION,
    CASE 
        WHEN LAG(PRICE) OVER (PARTITION BY PRODUCT_ID ORDER BY VERSION) IS NULL THEN NULL
        ELSE PRICE - LAG(PRICE) OVER (PARTITION BY PRODUCT_ID ORDER BY VERSION)
    END AS PRICE_CHANGE,
    CASE 
        WHEN LAG(PRICE) OVER (PARTITION BY PRODUCT_ID ORDER BY VERSION) IS NULL THEN NULL
        ELSE ROUND(
            (PRICE - LAG(PRICE) OVER (PARTITION BY PRODUCT_ID ORDER BY VERSION)) / 
            LAG(PRICE) OVER (PARTITION BY PRODUCT_ID ORDER BY VERSION) * 100, 
            2
        )
    END AS PRICE_CHANGE_PERCENT
FROM 
    DIM_PRODUCT_SCD
ORDER BY 
    PRODUCT_ID, VERSION;

COMMENT ON TABLE V_PRODUCT_PRICE_HISTORY IS 'View: Zeigt Preis-Historie mit Änderungen';

-- ==============================================================================
-- 8. FACT_SALES anpassen für SCD
-- ==============================================================================

-- Optional: Wenn wir Point-in-Time Reporting wollen, speichern wir den SCD-Snapshot
ALTER TABLE FACT_SALES ADD (
    PRODUCT_SCD_ID NUMBER  -- Referenz auf spezifische Produkt-Version
);

-- FK zu beiden Tabellen möglich
ALTER TABLE FACT_SALES ADD (
    CONSTRAINT FK_SALES_PRODUCT_SCD FOREIGN KEY (PRODUCT_SCD_ID) REFERENCES DIM_PRODUCT_SCD(ID)
);

COMMENT ON COLUMN FACT_SALES.PRODUCT_SCD_ID IS 'Referenz auf die zum Verkaufszeitpunkt gültige Produktversion';

-- ==============================================================================
-- 9. Beispiel-Queries
-- ==============================================================================

-- Query 1: Alle aktuellen Produkte
-- SELECT * FROM V_DIM_PRODUCT_CURRENT;

-- Query 2: Alle Versionen eines bestimmten Produkts
-- SELECT * FROM DIM_PRODUCT_SCD WHERE PRODUCT_ID = 1 ORDER BY VERSION;

-- Query 3: Welcher Preis galt am 15. Juni 2024?
-- SELECT PRICE FROM DIM_PRODUCT_SCD 
-- WHERE PRODUCT_ID = 1 
--   AND VALID_FROM <= DATE '2024-06-15' 
--   AND (VALID_TO IS NULL OR VALID_TO >= DATE '2024-06-15');

-- Query 4: Preis-Historie
-- SELECT * FROM V_PRODUCT_PRICE_HISTORY WHERE PRODUCT_ID = 1;

COMMIT;

/*******************************************************************************
 * ENDE - Slowly Changing Dimensions implementiert
 * 
 * Vorteile:
 * - Historische Preis-Analysen möglich
 * - Korrekte Umsatzberechnungen mit historischen Preisen
 * - Audit Trail für alle Änderungen
 * 
 * Nächste Schritte:
 * - Test-Daten laden
 * - Phase 3: Fact Constellation (mehrere Fact-Tabellen)
 ******************************************************************************/
