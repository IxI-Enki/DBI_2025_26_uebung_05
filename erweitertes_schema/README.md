# Erweitertes Star-Schema - Implementation Guide

## 📖 Übersicht

Dieses Verzeichnis enthält die vollständige Implementierung eines **erweiterten Data Warehouse Schemas** basierend auf dem ursprünglichen Star-Schema aus Übung 02.

### Vom Star-Schema zum Fact Constellation Schema

#### ORIGINAL (Übung 02): Einfaches Star-Schema

```text
┌─────────────┐            ┌──────────────┐┌──────────────┐
│  DIM_TIME   │            │ DIM_PRODUCT  ││ DIM_CUSTOMER │
├─────────────┤            ├──────────────┤├──────────────┤
│ id (PK)     │            │ id (PK)      ││ id (PK)      │
│ year        │            │ product_name ││ customer_name│
│ month       │            │ category_name││ address      │
│ day         │            │ list_price   ││ credit_limit │
│ full_date   │            │              ││              │
└┬────────────┘            └─────────────┬┘└──────┬───────┘
 │    ┌────────────────────────────────┐ │        │
 │    │         FACT_SALES             │ │        │
 │    ├────────────────────────────────┤ │        │
 └────┤ t (FK) → DIM_TIME              │ │        │
      │ product (FK) → DIM_PRODUCT     ├─┘        │
      │ customer (FK) → DIM_CUSTOMER   ├──────────┘
  ┌───┤ employee (FK) → DIM_EMPLOYEE   │
  │   │ status (FK) → DIM_STATUS       ├─┐
  │   │ ───────────────                │ │
  │   │ order_id (Degenerate)          │ │
  │   │ item_id (Degenerate)           │ │
  │   │ quantity, unit_price, amount   │ │
  │   └────────────────────────────────┘ │
┌─┴─────────────┐           ┌────────────┴─┐
│ DIM_EMPLOYEE  │           │  DIM_STATUS  │
├───────────────┤           ├──────────────┤
│ id (PK)       │           │ id (PK)      │
│ first_name    │           │ status       │
│ last_name     │           └──────────────┘
│ job_title     │
└───────────────┘
```

**✅ Charakteristik:**

- **1 Fact-Tabelle** (FACT_SALES)
- **5 Dimensionen** (flach, denormalisiert)
- **Grain:** Eine Zeile pro Bestellposition
- **Measures:** quantity, unit_price, amount

---

#### ERWEITERT: Fact Constellation / Galaxy Schema

> **💡 Was ist "Degenerate Key"?**
> Keys die DIREKT in der Fact-Tabelle stehen, OHNE eigene Dimensions-Tabelle
> (z.B. `order_id`, `item_id` - sie haben keine weiteren Attribute)

---

##### 🌟 Star 1: FACT_SALES (Hauptfact - erweitert)

```text
┌───────────┐┌─────────────┐                               ┌─────────────────────┐┌──────────────┐┌──────────────┐
│DIM_STATUS ││  DIM_TIME   │                               │  DIM_PRODUCT_SCD    ││ DIM_CUSTOMER ││ DIM_EMPLOYEE │
├───────────┤├─────────────┤                               ├─────────────────────┤├──────────────┤├──────────────┤
│id (PK)    ││ id (PK)     │                               │ id (PK)             ││ id (PK)      ││ id (PK)      │
│status     ││ year        │                               │ product_id (BK)     ││ customer_name││ first_name   │
└──────────┬┘│ month       │                               │ product_name        ││ address      ││ last_name    │
           │ │ day         │                               │ price, cost         ││ credit_limit ││ job_title    │
           │ │ full_date   │                               │ valid_from/to       │└─┬────────────┘└┬─────────────┘
           │ └┬────────────┘                               │ is_current, version │  │              │
           │  │                                            └───────────────────┬─┘  │              │
           │  │ ┌────────────────────────────────────────────────────────────┐ │    │              │
           │  │ │                     FACT_SALES                             │ │    │              │
           │  │ ├────────────────────────────────────────────────────────────┤ │    │              │
           │  └─┤ t (FK) → DIM_TIME                                          │ │    │              │
           │    │ product (FK) → DIM_PRODUCT_SCD                             ├─┘    │              │
           │    │ customer (FK) → DIM_CUSTOMER                               ├──────┘              │
           │    │ employee (FK) → DIM_EMPLOYEE                               ├─────────────────────┘
           └────┤ status (FK) → DIM_STATUS                                   │
              ┌─┤ warehouse_id (FK) → DIM_WAREHOUSE                          │
              │ │ shipping_id (FK) → DIM_SHIPPING_METHOD                     ├────┐
              │ │ payment_id (FK) → DIM_PAYMENT                              ├─┐  │
              │ │ ───────────────────────────────                            │ │  │
              │ │ order_id, item_id (Degenerate)                             │ │  │
              │ │ quantity, unit_price, amount, shipping_cost, discount, tax │ │  │
              │ └────────────────────────────────────────────────────────────┘ │  │
┌─────────────┴┐                                           ┌───────────────────┴┐┌┴────────────────────┐
│DIM_WAREHOUSE │                                           │ DIM_PAYMENT_METHOD ││ DIM_SHIPPING_METHOD │
├──────────────┤                                           ├────────────────────┤├─────────────────────┤
│id (PK)       │                                           │ id (PK)            ││id (PK)              │
│warehouse_code│                                           │ method_code(BK)    ││method_code (BK)     │
│warehouse_name│                                           │ method_name        ││method_name          │
│city, country │                                           │ provider           ││carrier              │
│capacity_sqm  │                                           │ transaction_fee    ││avg_delivery_days    │
│manager_name  │                                           │ processing_time    ││base_cost            │
└──────────────┘                                           └────────────────────┘└─────────────────────┘
```

---

##### 🌟 Star 2: FACT_INVENTORY

```text
┌─────────────┐                                  ┌───────────────┐┌─────────────┐
│  DIM_TIME   │                                  │DIM_PRODUCT_SCD││DIM_WAREHOUSE│
│  (shared)   │                                  │   (shared)    ││  (shared)   │
└┬────────────┘                                  └──────────────┬┘└┬────────────┘
 │ ┌──────────────────────────────────────────────────────────┐ │  │
 │ │                   FACT_INVENTORY                         │ │  │
 │ ├──────────────────────────────────────────────────────────┤ │  │
 └─┤ t (FK) → DIM_TIME                                        │ │  │
   │ product (FK) → DIM_PRODUCT_SCD                           ├─┘  │
   │ warehouse_id (FK) → DIM_WAREHOUSE                        ├────┘
   │ ────────────────────────────────────                     │
   │ inventory_id (PK)                                        │
   │ quantity_on_hand, reorder_level, quantity_reserved       │
   │ total_value, turnover_rate                               │
   └──────────────────────────────────────────────────────────┘
```

---

##### 🌟 Star 3: FACT_PRODUCT_RETURNS

```text
┌─────────────┐                            ┌───────────────┐┌────────────┐
│  DIM_TIME   │                            │DIM_PRODUCT_SCD││DIM_CUSTOMER│
│  (shared)   │                            │   (shared)    ││ (shared)   │
└┬────────────┘                            └──────────────┬┘└┬───────────┘
 │ ┌────────────────────────────────────────────────────┐ │  │
 │ │                  FACT_PRODUCT_RETURNS              │ │  │
 │ ├────────────────────────────────────────────────────┤ │  │
 └─┤ t (FK) → DIM_TIME                                  │ │  │
   │ product (FK) → DIM_PRODUCT_SCD                     ├─┘  │
   │ customer (FK) → DIM_CUSTOMER                       ├────┘
 ┌─┤ warehouse_id (FK) → DIM_WAREHOUSE                  │
 │ │ ───────────────────────────────────                │
 │ │ return_id (PK), quantity_returned, return_amount   │
 │ │ return_reason, condition, days_since_purchase      │
 │ │ resaleable                                         │
 │ └────────────────────────────────────────────────────┘
┌┴──────────────┐
│ DIM_WAREHOUSE │
│   (shared)    │
└───────────────┘
```

---

##### 🌟 Star 4: FACT_EMPLOYEE_PERFORMANCE

```text
┌─────────────┐                               ┌──────────────┐
│  DIM_TIME   │                               │ DIM_EMPLOYEE │
│  (shared)   │                               │  (shared)    │
└┬────────────┘                               └─────────────┬┘
 │ ┌──────────────────────────────────────────────────────┐ │
 │ │           FACT_EMPLOYEE_PERFORMANCE                  │ │
 │ ├──────────────────────────────────────────────────────┤ │
 └─┤ t (FK) → DIM_TIME                                    │ │
   │ employee (FK) → DIM_EMPLOYEE                         ├─┘
   │ ──────────────────────────────────                   │
   │ performance_id (PK), sales_count, total_revenue      │
   │ avg_order_value, customer_satisfaction, hours_worked │
   │ revenue_per_hour, target_achievement_%               │
   └──────────────────────────────────────────────────────┘
```

---

##### 🌟 Star 5: FACT_CUSTOMER_INTERACTION

```text
┌─────────────┐                   ┌──────────────┐┌──────────────┐
│  DIM_TIME   │                   │ DIM_EMPLOYEE ││ DIM_CUSTOMER │
│  (shared)   │                   │  (shared)    ││  (shared)    │
└┬────────────┘                   └─────────────┬┘└┬─────────────┘
 │ ┌──────────────────────────────────────────┐ │  │
 │ │           FACT_CUSTOMER_INTERACTION      │ │  │
 │ ├──────────────────────────────────────────┤ │  │
 └─┤ t (FK) → DIM_TIME                        │ │  │
   │ employee (FK) → DIM_EMPLOYEE             ├─┘  │
   │ customer (FK) → DIM_CUSTOMER             ├────┘
   │ ───────────────────────────────────      │
   │ interaction_id (PK), interaction_type    │
   │ interaction_duration_min, issue_resolved │
   │ satisfaction_score, response_time_min    │
   └──────────────────────────────────────────┘
```

**✅ Charakteristik:**

- **5 Fact-Tabellen** (verschiedene Geschäftsprozesse)
- **9 Dimensionen** (teilweise geteilt!)
- **SCD Type 2** für DIM_PRODUCT_SCD
- **Grain:** Unterschiedlich je Fact-Tabelle

**🔗 Geteilte Dimensionen:**

- `DIM_TIME` → verwendet von ALLEN Facts
- `DIM_PRODUCT` → FACT_SALES, FACT_INVENTORY, FACT_RETURNS
- `DIM_EMPLOYEE` → FACT_SALES, FACT_EMPLOYEE_PERFORMANCE, FACT_CUSTOMER_INTERACTION
- `DIM_CUSTOMER` → FACT_SALES, FACT_RETURNS, FACT_CUSTOMER_INTERACTION
- `DIM_WAREHOUSE` → FACT_SALES, FACT_INVENTORY, FACT_RETURNS

---

## 🎯 Implementierungs-Phasen

### Phase 1: Neue Dimensionen ⭐ QUICK WIN

**Datei:** `01_neue_dimensionen.sql`

**Was wird gemacht:**

- **4 neue Dimension-Tabellen**:
  - `DIM_WAREHOUSE` (Lagerstandorte)
  - `DIM_SHIPPING_METHOD` (Versandarten)
  - `DIM_PROMOTION` (Marketing-Aktionen)
  - `DIM_PAYMENT_METHOD` (Zahlungsmethoden)
- **FACT_SALES erweitern** mit neuen Foreign Keys
- **Zusätzliche Measures**: Shipping Cost, Discount, Tax, Net Amount

**Aufwand:** 🟢 Niedrig | **Nutzen:** 🟢🟢🟢 Hoch

**Neue Analysemöglichkeiten:**

- ✅ Versandkosten-Optimierung
- ✅ Warehouse-Performance
- ✅ Promotion-Effektivität
- ✅ Zahlungsmethoden-Analyse

**Beispiel-Query:**

```sql
-- Welcher Versandweg ist am profitabelsten?
SELECT 
    sm.METHOD_NAME,
    COUNT(*) AS ORDER_COUNT,
    SUM(fs.AMOUNT) AS TOTAL_REVENUE,
    SUM(fs.SHIPPING_COST) AS TOTAL_SHIPPING_COST,
    AVG(fs.AMOUNT) AS AVG_ORDER_VALUE
FROM 
    FACT_SALES fs
JOIN 
    DIM_SHIPPING_METHOD sm ON fs.SHIPPING_METHOD_ID = sm.ID
GROUP BY 
    sm.METHOD_NAME
ORDER BY 
    TOTAL_REVENUE DESC;
```

---

### Phase 2: Slowly Changing Dimensions (SCD) ⭐⭐ BEST PRACTICE

**Datei:** `02_scd_implementation.sql`

**Was wird gemacht:**

- **DIM_PRODUCT_SCD** mit Historisierung (SCD Type 2)
- **Stored Procedures**:
  - `sp_insert_product_scd()` - Neues Produkt
  - `sp_update_product_scd()` - Neue Version erstellen
- **Function**: `fn_get_product_at_date()` - Zeitreise-Queries
- **Views**: Aktuelle Produkte, Preis-Historie

**Aufwand:** 🟡 Mittel | **Nutzen:** 🟢🟢🟢 Sehr Hoch

**Neue Analysemöglichkeiten:**

- ✅ Historische Preis-Analysen
- ✅ Korrekte Umsatzberechnungen mit historischen Preisen
- ✅ Preis-Optimierung durch Historie
- ✅ Audit Trail für alle Änderungen

#### Beispiel: Preis-Historie

```sql
-- Wie hat sich der Preis von Produkt 1 entwickelt?
SELECT 
    PRODUCT_NAME,
    VERSION,
    PRICE,
    VALID_FROM,
    VALID_TO,
    PRICE_CHANGE,
    PRICE_CHANGE_PERCENT
FROM 
    V_PRODUCT_PRICE_HISTORY
WHERE 
    PRODUCT_ID = 1
ORDER BY 
    VERSION;

-- Ergebnis:
-- PRODUCT_NAME | VERSION | PRICE | VALID_FROM | VALID_TO   | CHANGE | CHANGE_%
-- Laptop A     | 1       | 999   | 2024-01-01 | 2024-06-30 | NULL   | NULL
-- Laptop A     | 2       | 899   | 2024-07-01 | 2024-09-30 | -100   | -10.01
-- Laptop A     | 3       | 849   | 2024-10-01 | NULL       | -50    | -5.56
```

**Zeitreise-Query:**

```sql
-- Welcher Preis galt am 15. Juni 2024?
SELECT 
    PRODUCT_NAME,
    PRICE
FROM 
    DIM_PRODUCT_SCD
WHERE 
    PRODUCT_ID = 1
    AND VALID_FROM <= DATE '2024-06-15'
    AND (VALID_TO IS NULL OR VALID_TO >= DATE '2024-06-15');
```

---

### Phase 3: Fact Constellation ⭐⭐⭐ ENTERPRISE-LEVEL

**Datei:** `03_fact_constellation.sql`

**Was wird gemacht:**

- **4 neue Fact-Tabellen**:
  1. `FACT_INVENTORY` - Lagerbestandsanalyse
  2. `FACT_EMPLOYEE_PERFORMANCE` - Mitarbeiter-KPIs
  3. `FACT_CUSTOMER_INTERACTION` - Kundenservice
  4. `FACT_PRODUCT_RETURNS` - Retourenanalyse
- **Cross-Fact Views** für kombinierte Analysen
- **ETL-Procedures** für Daten-Loading

**Aufwand:** 🔴 Hoch | **Nutzen:** 🟢🟢🟢 Sehr Hoch

**Neue Geschäftsprozesse:**

- ✅ Lageroptimierung
- ✅ Mitarbeiter-Performance-Management
- ✅ Customer-Service-Qualität
- ✅ Retourenmanagement

#### Beispiel: Cross-Fact Analyse

```sql
-- Produkte mit hoher Retourenrate
SELECT 
    PRODUCT_NAME,
    TOTAL_SALES,
    SALES_QUANTITY,
    RETURN_QUANTITY,
    RETURN_RATE_PERCENT
FROM 
    V_PRODUCT_SALES_RETURNS
WHERE 
    RETURN_RATE_PERCENT > 10
ORDER BY 
    RETURN_RATE_PERCENT DESC;
```

---

## 🚀 Installation & Setup

### 1. Voraussetzungen

- Oracle DB (bereits laufend in Docker)
- Übung 02 Star-Schema bereits erstellt
- Ausreichende Berechtigungen (CREATE TABLE, CREATE INDEX, etc.)

### 2. Installations-Reihenfolge

```sql
-- Schritt 1: Phase 1 ausführen
@01_neue_dimensionen.sql

-- Schritt 2: Phase 2 ausführen
@02_scd_implementation.sql

-- Schritt 3: Phase 3 ausführen
@03_fact_constellation.sql

-- Schritt 4: Test-Daten laden (wenn verfügbar)
-- @04_test_data.sql
```

### 3. Verifizierung

```sql
-- Prüfe, ob alle Tabellen erstellt wurden
SELECT 
    TABLE_NAME,
    NUM_ROWS
FROM 
    USER_TABLES
WHERE 
    TABLE_NAME LIKE 'DIM_%' OR TABLE_NAME LIKE 'FACT_%'
ORDER BY 
    TABLE_NAME;

-- Prüfe alle Foreign Keys
SELECT 
    CONSTRAINT_NAME,
    TABLE_NAME,
    R_CONSTRAINT_NAME
FROM 
    USER_CONSTRAINTS
WHERE 
    CONSTRAINT_TYPE = 'R'
ORDER BY 
    TABLE_NAME;
```

---

## 📊 Analysemöglichkeiten

### 1. Verkaufsanalysen (erweitert)

```sql
-- Umsatz nach Versandmethode und Promotion
SELECT 
    sm.METHOD_NAME,
    p.PROMOTION_NAME,
    COUNT(*) AS ORDER_COUNT,
    SUM(fs.AMOUNT) AS TOTAL_REVENUE,
    SUM(fs.SHIPPING_COST) AS TOTAL_SHIPPING,
    SUM(fs.DISCOUNT_AMOUNT) AS TOTAL_DISCOUNT,
    AVG(fs.NET_AMOUNT) AS AVG_NET_AMOUNT
FROM 
    FACT_SALES fs
LEFT JOIN DIM_SHIPPING_METHOD sm ON fs.SHIPPING_METHOD_ID = sm.ID
LEFT JOIN DIM_PROMOTION p ON fs.PROMOTION_ID = p.ID
GROUP BY 
    sm.METHOD_NAME, p.PROMOTION_NAME
ORDER BY 
    TOTAL_REVENUE DESC;
```

### 2. Lageroptimierung

```sql
-- Produkte mit niedrigem Lagerbestand
SELECT 
    p.PRODUCT_NAME,
    w.WAREHOUSE_NAME,
    fi.QUANTITY_ON_HAND,
    fi.REORDER_LEVEL,
    fi.QUANTITY_AVAILABLE,
    CASE 
        WHEN fi.QUANTITY_ON_HAND < fi.REORDER_LEVEL THEN 'NACHBESTELLEN!'
        WHEN fi.QUANTITY_ON_HAND < fi.REORDER_LEVEL * 1.5 THEN 'Niedrig'
        ELSE 'OK'
    END AS STATUS
FROM 
    FACT_INVENTORY fi
JOIN DIM_PRODUCT p ON fi.PRODUCT = p.ID
JOIN DIM_WAREHOUSE w ON fi.WAREHOUSE_ID = w.ID
JOIN DIM_TIME t ON fi.T = t.ID
WHERE 
    t.FULL_DATE = TRUNC(SYSDATE)  -- Heutiger Bestand
    AND fi.QUANTITY_ON_HAND < fi.REORDER_LEVEL * 1.5
ORDER BY 
    fi.QUANTITY_ON_HAND;
```

### 3. Mitarbeiter-Performance

```sql
-- Top-Performer des Monats
SELECT 
    e.NAME,
    e.JOB_TITLE,
    fp.SALES_COUNT,
    fp.TOTAL_REVENUE,
    fp.AVG_ORDER_VALUE,
    fp.CUSTOMER_SATISFACTION,
    fp.TARGET_ACHIEVEMENT_PERCENT
FROM 
    FACT_EMPLOYEE_PERFORMANCE fp
JOIN DIM_EMPLOYEE e ON fp.EMPLOYEE = e.ID
JOIN DIM_TIME t ON fp.T = t.ID
WHERE 
    t.YEAR = 2024
    AND t.MONTH = 10
ORDER BY 
    fp.TOTAL_REVENUE DESC
FETCH FIRST 10 ROWS ONLY;
```

### 4. Retourenanalyse

```sql
-- Hauptgründe für Retouren
SELECT 
    fr.RETURN_REASON,
    COUNT(*) AS RETURN_COUNT,
    SUM(fr.RETURN_AMOUNT) AS TOTAL_REFUNDED,
    AVG(fr.DAYS_SINCE_PURCHASE) AS AVG_DAYS_TO_RETURN,
    SUM(CASE WHEN fr.RESALEABLE = 'Y' THEN 1 ELSE 0 END) AS RESALEABLE_COUNT,
    ROUND(
        SUM(CASE WHEN fr.RESALEABLE = 'Y' THEN 1 ELSE 0 END) / COUNT(*) * 100,
        2
    ) AS RESALEABLE_PERCENT
FROM 
    FACT_PRODUCT_RETURNS fr
GROUP BY 
    fr.RETURN_REASON
ORDER BY 
    RETURN_COUNT DESC;
```

---

## 🎓 Lernziele & Konzepte

### Star-Schema vs. Fact Constellation

| Aspekt | Star-Schema | Fact Constellation |
|--------|-------------|-------------------|
| **Fact-Tabellen** | 1 | Mehrere (2+) |
| **Dimensionen** | Nicht geteilt | Geteilt zwischen Facts |
| **Komplexität** | Niedrig | Mittel-Hoch |
| **Flexibilität** | Begrenzt auf einen Prozess | Mehrere Geschäftsprozesse |
| **Performance** | Sehr gut | Gut |
| **Wartung** | Einfach | Aufwändiger |
| **Use Case** | Einzelner Geschäftsprozess | Enterprise Data Warehouse |

### Slowly Changing Dimensions (SCD)

| Typ | Beschreibung | Use Case |
|-----|-------------|----------|
| **Type 0** | Keine Änderungen erlaubt | Unveränderliche Daten |
| **Type 1** | Überschreiben | Keine Historie nötig |
| **Type 2** | Neue Version erstellen ⭐ | Volle Historie (implementiert!) |
| **Type 3** | Zusätzliche Spalte für alte Werte | Begrenzte Historie |
| **Type 4** | Historien-Tabelle | Sehr große Dimensionen |

### Best Practices

✅ **DO:**

- Flache, denormalisierte Dimensionen
- Surrogate Keys verwenden
- Bitmap Indexes für Foreign Keys in Facts
- B-Tree Indexes für Dimensions-Business-Keys
- Aussagekräftige Measures in Fact-Tabellen
- Constraints für Datenqualität

❌ **DON'T:**

- Dimensionen nicht normalisieren (kein Snowflake ohne Grund)
- Keine NULL-Foreign-Keys in Facts (verwende Unknown-Dimension)
- Keine berechneten Felder in SELECT (pre-calculate in Facts)
- Keine Transaktionsdaten in Dimensionen

---

## 📈 Performance-Tipps

### 1. Partitionierung (für große Datenmengen)

```sql
-- Partitionierung nach Datum für FACT_SALES
CREATE TABLE FACT_SALES_PARTITIONED (
    -- ... Spalten ...
)
PARTITION BY RANGE (T) (
    PARTITION p_2024_q1 VALUES LESS THAN (TO_DATE('2024-04-01', 'YYYY-MM-DD')),
    PARTITION p_2024_q2 VALUES LESS THAN (TO_DATE('2024-07-01', 'YYYY-MM-DD')),
    PARTITION p_2024_q3 VALUES LESS THAN (TO_DATE('2024-10-01', 'YYYY-MM-DD')),
    PARTITION p_2024_q4 VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD'))
);
```

### 2. Materialized Views

```sql
-- Voraggregierte Monthly Sales
CREATE MATERIALIZED VIEW MV_SALES_MONTHLY
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT 
    t.YEAR,
    t.MONTH,
    p.PRODUCT_CATEGORY,
    COUNT(*) AS ORDER_COUNT,
    SUM(fs.AMOUNT) AS TOTAL_REVENUE,
    AVG(fs.AMOUNT) AS AVG_ORDER_VALUE
FROM 
    FACT_SALES fs
JOIN DIM_TIME t ON fs.T = t.ID
JOIN DIM_PRODUCT p ON fs.PRODUCT = p.ID
GROUP BY 
    t.YEAR, t.MONTH, p.PRODUCT_CATEGORY;
```

### 3. Statistiken aktualisieren

```sql
-- Nach großen Datenladungen
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS('YOUR_SCHEMA', 'FACT_SALES');
    DBMS_STATS.GATHER_TABLE_STATS('YOUR_SCHEMA', 'FACT_INVENTORY');
    DBMS_STATS.GATHER_TABLE_STATS('YOUR_SCHEMA', 'DIM_PRODUCT_SCD');
END;
/
```

---

## 🔍 Troubleshooting

### Problem: "Foreign Key Constraint verletzt"

**Lösung:** Stelle sicher, dass die referenzierten Dimensionen existieren, bevor du Fact-Daten einfügst.

```sql
-- Prüfe, ob Dimension-Einträge existieren
SELECT COUNT(*) FROM DIM_WAREHOUSE;
SELECT COUNT(*) FROM DIM_SHIPPING_METHOD;
```

### Problem: "SCD Update funktioniert nicht"

**Lösung:** Stelle sicher, dass das `PRODUCT_ID` (nicht `ID`) verwendet wird.

```sql
-- Richtig:
EXEC sp_update_product_scd(p_product_id => 1, p_price => 899);

-- Falsch:
EXEC sp_update_product_scd(p_product_id => 1234, p_price => 899);  -- 1234 ist ID, nicht PRODUCT_ID
```

---

## 📚 Weitere Ressourcen

- **Star-Schema Design**: The Data Warehouse Toolkit (Ralph Kimball)
- **SCD Patterns**: Slowly Changing Dimensions Explained
- **Fact Constellation**: Multi-Star Schemas in DWH
- **Oracle Docs**: Bitmap Indexes, Partitioning, Materialized Views

---

## ✅ Checkliste

- [ ] Phase 1: Neue Dimensionen erstellt
- [ ] Phase 1: FACT_SALES erweitert
- [ ] Phase 1: Test-Queries ausgeführt
- [ ] Phase 2: DIM_PRODUCT_SCD erstellt
- [ ] Phase 2: SCD Procedures getestet
- [ ] Phase 2: Preis-Historie-Queries funktionieren
- [ ] Phase 3: Alle neuen Fact-Tabellen erstellt
- [ ] Phase 3: Cross-Fact Views funktionieren
- [ ] Performance-Tuning durchgeführt
- [ ] Dokumentation vervollständigt

---

**Branch:** `feature/erweitertes-star-schema`  
**Status:** ✅ In Entwicklung  
**Letztes Update:** 2024-10-28
