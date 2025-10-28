# Star-Schema Erweiterungen - Konzepte und Verbesserungen

## 📚 Grundlagen: Star-Schema vs. Relationales Schema

### Unser aktuelles Star-Schema (aus Übung 02)

```
                    DIM_TIME
                       |
                       |
DIM_CUSTOMER ----  FACT_SALES  ---- DIM_PRODUCT
                       |
                       |
                  DIM_EMPLOYEE
                       |
                  DIM_STATUS
```

**✅ Dies ist ein KORREKTES Star-Schema!**

### Warum nur EINE Fact-Tabelle?

**Star-Schema Prinzip:**
- **Fact-Tabelle = Stern-Mittelpunkt** (enthält Measures: Umsatz, Menge, etc.)
- **Dimensionen = Stern-Zacken** (beschreiben den Kontext: Wer? Was? Wann? Wo?)
- **Flache, denormalisierte Dimensionen** (keine Hierarchien in separaten Tabellen)

**Das ist KEIN Fehler - das ist die Definition von Star-Schema!**

---

## 🌟 Schema-Typen im Vergleich

### 1. Star-Schema (unser aktuelles)

**Charakteristik:**
- 1 Fact-Tabelle
- Mehrere flache Dimension-Tabellen
- **Keine normalisierten Hierarchien**

**Vorteile:**
- ✅ Einfache Abfragen
- ✅ Schnelle Performance
- ✅ Leicht verständlich

**Nachteile:**
- ❌ Redundanz in Dimensionen
- ❌ Größerer Speicherbedarf

### 2. Snowflake-Schema (Normalisierte Dimensionen)

**Charakteristik:**
- 1 Fact-Tabelle
- **Hierarchisch normalisierte** Dimensionen

**Beispiel:**
```
DIM_TIME → DIM_MONTH → DIM_QUARTER → DIM_YEAR
```

**Vorteile:**
- ✅ Weniger Redundanz
- ✅ Kleinerer Speicherbedarf

**Nachteile:**
- ❌ Komplexere Abfragen (mehr JOINs)
- ❌ Langsamere Performance

### 3. Fact Constellation / Galaxy Schema

**Charakteristik:**
- **MEHRERE Fact-Tabellen**
- **Geteilte Dimensionen**

**Beispiel:**
```
              DIM_TIME
                 |  \
                 |   \
         FACT_SALES  FACT_INVENTORY
                 |   /
                 |  /
             DIM_PRODUCT
```

**Vorteile:**
- ✅ Mehrere Geschäftsprozesse modellierbar
- ✅ Dimensionen werden wiederverwendet

**Nachteile:**
- ❌ Komplexere Wartung
- ❌ Höhere Anforderungen an ETL

---

## 🚀 Verbesserungsvorschläge für unser Schema

### Option 1: Snowflake-Erweiterung (DIM_TIME hierarchisch)

**Problem:** `DIM_TIME` enthält redundante Jahr-/Monatsdaten

**Lösung:**
```sql
-- Aktuell (Star):
DIM_TIME (ID, YEAR, MONTH, DAY, FULL_DATE)

-- Snowflake:
DIM_DAY (ID, DAY_NUMBER, MONTH_ID, FULL_DATE)
   └── DIM_MONTH (ID, MONTH_NUMBER, QUARTER_ID, MONTH_NAME)
       └── DIM_QUARTER (ID, QUARTER_NUMBER, YEAR_ID)
           └── DIM_YEAR (ID, YEAR_NUMBER)
```

**Bewertung:** ❌ **NICHT empfohlen!** 
- Widerspricht Star-Schema-Prinzip
- Macht Abfragen komplexer
- Nur minimaler Speichervorteil

### Option 2: Fact Constellation (Mehrere Geschäftsprozesse)

**Idee:** Zusätzliche Fact-Tabellen für andere Geschäftsprozesse

**Neue Fact-Tabellen:**

#### 2.1 FACT_INVENTORY (Lagerbestand)

```sql
CREATE TABLE FACT_INVENTORY (
    INVENTORY_ID      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    PRODUCT           NUMBER NOT NULL,  -- FK zu DIM_PRODUCT
    T                 NUMBER NOT NULL,  -- FK zu DIM_TIME
    WAREHOUSE_ID      NUMBER NOT NULL,  -- FK zu DIM_WAREHOUSE (neu!)
    -- Measures
    QUANTITY_ON_HAND  NUMBER NOT NULL,
    REORDER_LEVEL     NUMBER NOT NULL,
    REORDER_QUANTITY  NUMBER,
    LAST_STOCK_DATE   DATE,
    
    CONSTRAINT FK_FINV_PRODUCT   FOREIGN KEY (PRODUCT)      REFERENCES DIM_PRODUCT(ID),
    CONSTRAINT FK_FINV_TIME      FOREIGN KEY (T)            REFERENCES DIM_TIME(ID),
    CONSTRAINT FK_FINV_WAREHOUSE FOREIGN KEY (WAREHOUSE_ID) REFERENCES DIM_WAREHOUSE(ID)
);
```

#### 2.2 FACT_EMPLOYEE_PERFORMANCE (Mitarbeiter-Leistung)

```sql
CREATE TABLE FACT_EMPLOYEE_PERFORMANCE (
    PERFORMANCE_ID    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    EMPLOYEE          NUMBER NOT NULL,  -- FK zu DIM_EMPLOYEE
    T                 NUMBER NOT NULL,  -- FK zu DIM_TIME
    -- Measures
    SALES_COUNT       NUMBER NOT NULL,
    TOTAL_REVENUE     NUMBER(10,2) NOT NULL,
    AVG_ORDER_VALUE   NUMBER(10,2),
    CUSTOMER_RATING   NUMBER(3,2),
    
    CONSTRAINT FK_FPERF_EMPLOYEE FOREIGN KEY (EMPLOYEE) REFERENCES DIM_EMPLOYEE(ID),
    CONSTRAINT FK_FPERF_TIME     FOREIGN KEY (T)        REFERENCES DIM_TIME(ID)
);
```

**Bewertung:** ✅ **EMPFOHLEN!**
- Ermöglicht Analyse verschiedener Geschäftsprozesse
- Dimensionen werden wiederverwendet
- Entspricht Best Practices für DWH

### Option 3: Zusätzliche Dimensionen (erweitern)

**Neue Dimensionen für FACT_SALES:**

#### 3.1 DIM_WAREHOUSE (Lagerstandort)

```sql
CREATE TABLE DIM_WAREHOUSE (
    ID                NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    WAREHOUSE_CODE    VARCHAR2(10) NOT NULL UNIQUE,
    WAREHOUSE_NAME    VARCHAR2(100) NOT NULL,
    ADDRESS           VARCHAR2(200),
    CITY              VARCHAR2(50),
    COUNTRY           VARCHAR2(50),
    CAPACITY          NUMBER,
    MANAGER_NAME      VARCHAR2(100)
);
```

#### 3.2 DIM_SHIPPING_METHOD (Versandart)

```sql
CREATE TABLE DIM_SHIPPING_METHOD (
    ID                NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    METHOD_CODE       VARCHAR2(10) NOT NULL UNIQUE,
    METHOD_NAME       VARCHAR2(50) NOT NULL,
    CARRIER           VARCHAR2(50),
    AVG_DELIVERY_DAYS NUMBER,
    BASE_COST         NUMBER(8,2)
);
```

**FACT_SALES erweitern:**

```sql
ALTER TABLE FACT_SALES ADD (
    WAREHOUSE_ID       NUMBER,
    SHIPPING_METHOD_ID NUMBER,
    CONSTRAINT FK_SALES_WAREHOUSE      FOREIGN KEY (WAREHOUSE_ID)       REFERENCES DIM_WAREHOUSE(ID),
    CONSTRAINT FK_SALES_SHIPPING       FOREIGN KEY (SHIPPING_METHOD_ID) REFERENCES DIM_SHIPPING_METHOD(ID)
);
```

**Bewertung:** ✅ **EMPFOHLEN!**
- Ermöglicht detailliertere Analysen
- Bleibt im Star-Schema-Prinzip
- Einfach zu implementieren

### Option 4: Slowly Changing Dimensions (SCD Typ 2)

**Problem:** Preisänderungen bei Produkten nicht historisiert

**Lösung:** DIM_PRODUCT mit Versionierung

```sql
CREATE TABLE DIM_PRODUCT_SCD (
    ID                NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    PRODUCT_ID        NUMBER NOT NULL,        -- Business Key
    PRODUCT_NAME      VARCHAR2(100) NOT NULL,
    PRODUCT_CATEGORY  VARCHAR2(50),
    PRICE             NUMBER(10,2),
    -- SCD Typ 2 Felder
    VALID_FROM        DATE NOT NULL,
    VALID_TO          DATE,
    IS_CURRENT        CHAR(1) DEFAULT 'Y',
    VERSION           NUMBER DEFAULT 1,
    
    CONSTRAINT CHK_IS_CURRENT CHECK (IS_CURRENT IN ('Y', 'N'))
);
```

**Beispiel:**
```
PRODUCT_ID | PRODUCT_NAME | PRICE | VALID_FROM | VALID_TO   | IS_CURRENT
-----------|--------------|-------|------------|------------|------------
1          | Laptop A     | 999   | 2024-01-01 | 2024-06-30 | N
1          | Laptop A     | 899   | 2024-07-01 | NULL       | Y
```

**Bewertung:** ✅ **SEHR EMPFOHLEN!**
- Historische Preis-Analysen möglich
- Best Practice für DWH
- Keine Änderung an FACT_SALES nötig

### Option 5: Aggregate Facts (Pre-Aggregation)

**Idee:** Voraggregierte Fact-Tabellen für schnellere Abfragen

```sql
-- Tägliche Aggregation
CREATE TABLE FACT_SALES_DAILY (
    DAILY_ID          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    T                 NUMBER NOT NULL,  -- FK zu DIM_TIME (nur Tag-Ebene)
    PRODUCT           NUMBER NOT NULL,
    EMPLOYEE          NUMBER NOT NULL,
    -- Aggregierte Measures
    TOTAL_AMOUNT      NUMBER(12,2),
    TOTAL_QUANTITY    NUMBER,
    ORDER_COUNT       NUMBER,
    AVG_ORDER_VALUE   NUMBER(10,2)
);

-- Monatliche Aggregation
CREATE TABLE FACT_SALES_MONTHLY (
    MONTHLY_ID        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    YEAR              NUMBER NOT NULL,
    MONTH             NUMBER NOT NULL,
    PRODUCT           NUMBER NOT NULL,
    -- Aggregierte Measures
    TOTAL_AMOUNT      NUMBER(12,2),
    TOTAL_QUANTITY    NUMBER,
    ORDER_COUNT       NUMBER
);
```

**Bewertung:** ⚠️ **Optional**
- Beschleunigt Reporting
- Erhöht Wartungsaufwand
- Nur bei großen Datenmengen sinnvoll

---

## 🎯 Empfohlene Implementierung

### Phase 1: Zusätzliche Dimensionen (Quick Win)

1. **DIM_WAREHOUSE** erstellen
2. **DIM_SHIPPING_METHOD** erstellen
3. **FACT_SALES** erweitern

**Aufwand:** Niedrig | **Nutzen:** Hoch

### Phase 2: Slowly Changing Dimensions

1. **DIM_PRODUCT_SCD** implementieren
2. ETL-Prozess für Versionierung

**Aufwand:** Mittel | **Nutzen:** Sehr Hoch

### Phase 3: Fact Constellation

1. **FACT_INVENTORY** erstellen
2. **FACT_EMPLOYEE_PERFORMANCE** erstellen
3. Dimensionen teilen

**Aufwand:** Hoch | **Nutzen:** Sehr Hoch

### Phase 4: Aggregate Facts (Optional)

1. **FACT_SALES_DAILY** erstellen
2. **FACT_SALES_MONTHLY** erstellen
3. ETL-Jobs für Aggregation

**Aufwand:** Hoch | **Nutzen:** Mittel (nur bei großen Datenmengen)

---

## 📊 Vergleich: Vorher vs. Nachher

### Vorher (Aktuelles Schema)

```
                    DIM_TIME
                       |
                       |
DIM_CUSTOMER ----  FACT_SALES  ---- DIM_PRODUCT
                       |
                       |
                  DIM_EMPLOYEE
                       |
                  DIM_STATUS
```

**Capabilities:**
- Verkaufsanalyse
- Kunden-Analysen
- Produkt-Performance
- Mitarbeiter-Verkäufe

### Nachher (Erweitertes Fact Constellation)

```
                              DIM_TIME
                                 |
                        +--------+--------+
                        |                 |
         DIM_WAREHOUSE  |                 |  DIM_SHIPPING
                   \    |                 |    /
DIM_CUSTOMER ---  FACT_SALES        FACT_INVENTORY --- DIM_PRODUCT_SCD
                   /    |                 |
        DIM_EMPLOYEE    |                 |
                   \    |                 |
               DIM_STATUS         FACT_EMPLOYEE_PERFORMANCE
```

**Neue Capabilities:**
- ✅ Lagerbestandsanalyse
- ✅ Versandkosten-Optimierung
- ✅ Warehouse-Performance
- ✅ Historische Preisanalysen
- ✅ Mitarbeiter-KPIs (unabhängig von Verkäufen)
- ✅ Cross-Process Analysen

---

## 💡 Fazit

**Deine Intuition war richtig!** 

Ein Star-Schema kann und sollte für komplexe Geschäftsprozesse erweitert werden:

1. **Nicht durch Hierarchien** (das wäre Snowflake)
2. **Sondern durch:**
   - Zusätzliche **Dimensionen** (mehr Analysemöglichkeiten)
   - Zusätzliche **Fact-Tabellen** (verschiedene Geschäftsprozesse)
   - **SCD** für Historisierung

**Unser aktuelles Schema war NICHT falsch** - es ist ein perfekt valides Star-Schema für Verkaufsanalysen!

**Aber:** Für ein umfassendes Enterprise Data Warehouse sollten wir zu einem **Fact Constellation Schema** erweitern.

---

## 📋 Nächste Schritte

1. ✅ Branch erstellt: `feature/erweitertes-star-schema`
2. 📝 SQL-Skripte für Phase 1-3 erstellen
3. 🧪 Test-Daten generieren
4. 📊 Beispiel-Analysen durchführen
5. 📚 Dokumentation vervollständigen

Bereit für die Implementierung? 🚀
