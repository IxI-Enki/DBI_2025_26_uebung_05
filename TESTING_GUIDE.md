# Testing Guide - DBI Übung 05

> **Systematisches Testen der analytischen Funktionen**

---

## 🧪 Test-Strategie

### Phase 1: Voraussetzungen prüfen ✅

**Ziel:** Sicherstellen, dass das Star-Schema korrekt geladen ist

```sql
-- Test 1.1: Alle Tabellen vorhanden?
SELECT table_name 
FROM user_tables 
WHERE table_name IN ('FACT_SALES', 'DIM_TIME', 'DIM_PRODUCT', 'DIM_CUSTOMER', 'DIM_EMPLOYEE', 'DIM_STATUS')
ORDER BY table_name;
-- Erwartung: 6 Zeilen

-- Test 1.2: Sind Daten vorhanden?
SELECT 'FACT_SALES' AS tbl, COUNT(*) AS cnt FROM FACT_SALES
UNION ALL SELECT 'DIM_TIME', COUNT(*) FROM DIM_TIME
UNION ALL SELECT 'DIM_PRODUCT', COUNT(*) FROM DIM_PRODUCT;
-- Erwartung: Alle > 0

-- Test 1.3: Foreign Keys intakt?
SELECT COUNT(*) AS orphaned_rows
FROM FACT_SALES fs
WHERE NOT EXISTS (SELECT 1 FROM DIM_TIME WHERE id = fs.t);
-- Erwartung: 0
```

**Expected Results:**
- ✅ 6 Tabellen existieren
- ✅ Alle Tabellen haben Daten
- ✅ Keine verwaisten FK-Einträge

---

### Phase 2: Einfache analytische Funktionen 📊

**Ziel:** Grundlegende OVER()-Syntax testen

```sql
-- Test 2.1: SUM() OVER () - Gesamtsumme
SELECT 
  order_id,
  amount,
  SUM(amount) OVER () AS total
FROM FACT_SALES
WHERE ROWNUM <= 5;
-- Erwartung: total ist bei allen Zeilen gleich

-- Test 2.2: COUNT() OVER () - Gesamtanzahl
SELECT DISTINCT
  COUNT(*) OVER () AS total_rows
FROM FACT_SALES;
-- Erwartung: Eine Zahl = Anzahl Zeilen in FACT_SALES

-- Test 2.3: AVG() OVER () - Gesamtdurchschnitt
SELECT 
  amount,
  AVG(amount) OVER () AS avg_amount
FROM FACT_SALES
WHERE ROWNUM <= 10;
-- Erwartung: avg_amount ist bei allen Zeilen gleich
```

**Expected Behavior:**
- ✅ Aggregatfunktionen über alle Zeilen
- ✅ Keine Zeilenreduktion
- ✅ Ergebnis in jeder Zeile wiederholt

---

### Phase 3: PARTITION BY testen 🔀

**Ziel:** Gruppierung ohne Zeilenreduktion

```sql
-- Test 3.1: PARTITION BY Jahr
SELECT 
  dt.year,
  fs.amount,
  SUM(fs.amount) OVER (PARTITION BY dt.year) AS year_total,
  COUNT(*) OVER (PARTITION BY dt.year) AS year_count
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
WHERE ROWNUM <= 20
ORDER BY dt.year, fs.amount;
-- Erwartung: year_total ist für alle Zeilen eines Jahres gleich

-- Test 3.2: PARTITION BY mehrere Spalten
SELECT 
  dt.year,
  dt.month,
  fs.amount,
  AVG(fs.amount) OVER (PARTITION BY dt.year, dt.month) AS month_avg
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
WHERE dt.year = 2017 AND ROWNUM <= 20
ORDER BY dt.year, dt.month, fs.amount;
-- Erwartung: month_avg ist für alle Zeilen desselben Monats gleich
```

**Validation:**
```sql
-- Vergleich mit GROUP BY
-- Beide sollten gleiche Summen pro Jahr liefern
SELECT dt.year, SUM(fs.amount) 
FROM FACT_SALES fs JOIN DIM_TIME dt ON fs.t = dt.id 
GROUP BY dt.year
ORDER BY dt.year;

SELECT DISTINCT dt.year, SUM(fs.amount) OVER (PARTITION BY dt.year) 
FROM FACT_SALES fs JOIN DIM_TIME dt ON fs.t = dt.id 
ORDER BY dt.year;
```

---

### Phase 4: ORDER BY und Running Totals 📈

**Ziel:** Laufende Summen und implizite Fenster

```sql
-- Test 4.1: Running Total (einfach)
SELECT 
  order_id,
  item_id,
  amount,
  SUM(amount) OVER (ORDER BY order_id, item_id) AS running_total
FROM FACT_SALES
WHERE ROWNUM <= 10;
-- Erwartung: running_total steigt monoton an

-- Test 4.2: Running Total mit PARTITION
SELECT 
  dt.year,
  dt.month,
  dt.day,
  fs.amount,
  SUM(fs.amount) OVER (
    PARTITION BY dt.year, dt.month, dt.day 
    ORDER BY fs.amount
  ) AS daily_running_total
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
WHERE dt.year = 2017 AND dt.month = 1 AND ROWNUM <= 20
ORDER BY dt.day, fs.amount;
-- Erwartung: Pro Tag startet running_total bei der kleinsten amount
```

**Manual Verification:**
```sql
-- Prüfe einen spezifischen Tag manuell
SELECT 
  dt.year, dt.month, dt.day,
  fs.amount,
  SUM(fs.amount) OVER (
    PARTITION BY dt.year, dt.month, dt.day 
    ORDER BY fs.amount
  ) AS running_total
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
WHERE dt.year = 2017 AND dt.month = 1 AND dt.day = 5
ORDER BY fs.amount;
-- Erste Zeile: running_total = amount
-- Zweite Zeile: running_total = amount[1] + amount[2]
-- usw.
```

---

### Phase 5: ROWS und RANGE 🪟

**Ziel:** Fensterdefinitionen testen

```sql
-- Test 5.1: ROWS BETWEEN - feste Anzahl
SELECT 
  order_id,
  amount,
  AVG(amount) OVER (
    ORDER BY order_id 
    ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
  ) AS moving_avg_5
FROM FACT_SALES
WHERE ROWNUM <= 20
ORDER BY order_id;
-- Erwartung: Durchschnitt über 5 Zeilen (2 davor, aktuelle, 2 danach)

-- Test 5.2: RANGE mit DATE - funktioniert nur mit FULL_DATE!
-- Wenn DIM_TIME.FULL_DATE fehlt, wird Test fehlschlagen
SELECT 
  dt.full_date,
  fs.amount,
  AVG(fs.amount) OVER (
    ORDER BY dt.full_date
    RANGE BETWEEN INTERVAL '3' DAY PRECEDING AND CURRENT ROW
  ) AS avg_last_3_days
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
WHERE ROWNUM <= 20
ORDER BY dt.full_date;
-- Erwartung: Durchschnitt über die letzten 3 Tage + aktuellen Tag
```

**Common Errors:**

```sql
-- ❌ FEHLER: RANGE ohne echten DATE-Typ
-- Dies schlägt fehl, wenn DIM_TIME kein FULL_DATE hat:
AVG(amount) OVER (
  ORDER BY year, month, day  -- ❌ Keine DATE-Spalte
  RANGE BETWEEN INTERVAL '10' DAY PRECEDING AND CURRENT ROW
)

-- ✅ LÖSUNG: Temporäres DATE konstruieren
AVG(amount) OVER (
  ORDER BY TO_DATE(LPAD(year,4,'0')||'-'||LPAD(month,2,'0')||'-'||LPAD(day,2,'0'), 'YYYY-MM-DD')
  RANGE BETWEEN INTERVAL '10' DAY PRECEDING AND CURRENT ROW
)

-- ✅ ODER: Verbesserte Schema-Version verwenden
AVG(amount) OVER (
  ORDER BY dt.full_date  -- ✅ Echte DATE-Spalte
  RANGE BETWEEN INTERVAL '10' DAY PRECEDING AND CURRENT ROW
)
```

---

### Phase 6: Ranking-Funktionen 🏆

**Ziel:** RANK, DENSE_RANK, ROW_NUMBER unterscheiden

```sql
-- Test 6.1: Alle drei Ranking-Funktionen vergleichen
WITH test_data AS (
  SELECT amount
  FROM FACT_SALES
  WHERE ROWNUM <= 20
)
SELECT 
  amount,
  RANK() OVER (ORDER BY amount DESC) AS rank,
  DENSE_RANK() OVER (ORDER BY amount DESC) AS dense_rank,
  ROW_NUMBER() OVER (ORDER BY amount DESC) AS row_number
FROM test_data
ORDER BY amount DESC;
-- Erwartung bei Gleichstand (z.B. amount = 100, 100, 90):
-- rank:       1, 1, 3  (überspringt 2)
-- dense_rank: 1, 1, 2  (überspringt nicht)
-- row_number: 1, 2, 3  (immer eindeutig)

-- Test 6.2: RANK mit PARTITION
SELECT 
  dt.year,
  de.last_name,
  SUM(fs.amount) AS jahresumsatz,
  RANK() OVER (PARTITION BY dt.year ORDER BY SUM(fs.amount) DESC) AS rang_im_jahr
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
JOIN DIM_EMPLOYEE de ON fs.employee = de.id
GROUP BY dt.year, de.id, de.last_name
ORDER BY dt.year, rang_im_jahr;
-- Erwartung: Pro Jahr startet Rang bei 1
```

**Edge Cases:**
```sql
-- NULL-Handling in RANK
SELECT 
  employee,
  SUM(amount) AS total,
  RANK() OVER (ORDER BY SUM(amount) DESC NULLS LAST) AS rank_nulls_last
FROM FACT_SALES
GROUP BY employee;
-- NULLs sollten am Ende erscheinen
```

---

### Phase 7: LAG und LEAD 🔄

**Ziel:** Zugriff auf vorherige/nächste Zeilen

```sql
-- Test 7.1: LAG - vorherige Zeile
SELECT 
  dt.full_date,
  SUM(fs.amount) AS daily_total,
  LAG(SUM(fs.amount)) OVER (ORDER BY dt.full_date) AS previous_day,
  SUM(fs.amount) - LAG(SUM(fs.amount)) OVER (ORDER BY dt.full_date) AS change
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
GROUP BY dt.full_date
ORDER BY dt.full_date;
-- Erwartung: previous_day ist NULL für ersten Tag

-- Test 7.2: LEAD - nächste Zeile
SELECT 
  dt.year,
  de.last_name,
  SUM(fs.amount) AS jahresumsatz,
  LAG(SUM(fs.amount)) OVER (PARTITION BY dt.year ORDER BY SUM(fs.amount) DESC) AS naechst_schlechter,
  SUM(fs.amount) - LAG(SUM(fs.amount)) OVER (PARTITION BY dt.year ORDER BY SUM(fs.amount) DESC) AS vorsprung
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
JOIN DIM_EMPLOYEE de ON fs.employee = de.id
WHERE fs.employee IS NOT NULL
GROUP BY dt.year, de.id, de.last_name
ORDER BY dt.year, jahresumsatz DESC;
-- Erwartung: naechst_schlechter ist NULL für schlechtesten Verkäufer
```

---

### Phase 8: Integration Test - Alle 9 Aufgaben 🎯

**Ziel:** Komplettes Durchlaufen aller Übungsaufgaben

```sql
-- Führe alle Queries aus RITT_uebung_05_analytische_funktionen.sql aus
@RITT_uebung_05_analytische_funktionen.sql
```

**Manuelle Validierung:**

```sql
-- Aufgabe 1: Gesamtumsatz sollte für alle Zeilen identisch sein
SELECT DISTINCT SUM(amount) OVER () AS gesamtumsatz FROM FACT_SALES;
-- Sollte genau EINE Zeile liefern

-- Aufgabe 2: Summe aller Jahresumsätze = Gesamtumsatz
WITH jahresumsaetze AS (
  SELECT DISTINCT dt.year, SUM(fs.amount) OVER (PARTITION BY dt.year) AS umsatz
  FROM FACT_SALES fs JOIN DIM_TIME dt ON fs.t = dt.id
)
SELECT SUM(umsatz) FROM jahresumsaetze;
-- Sollte = Gesamtumsatz aus Aufgabe 1 sein
```

---

## 🐛 Häufige Fehler und Lösungen

### Fehler 1: ORA-30483 (Window functions not allowed here)

```sql
-- ❌ FALSCH: Window function in WHERE
SELECT * 
FROM FACT_SALES 
WHERE RANK() OVER (ORDER BY amount) = 1;

-- ✅ RICHTIG: Subquery verwenden
SELECT * FROM (
  SELECT *, RANK() OVER (ORDER BY amount) AS rnk
  FROM FACT_SALES
) WHERE rnk = 1;
```

### Fehler 2: ORA-30487 (ORDER BY not allowed here)

```sql
-- ❌ FALSCH: ORDER BY ohne PARTITION bei LAG
SELECT LAG(amount) OVER () FROM FACT_SALES;

-- ✅ RICHTIG: ORDER BY angeben
SELECT LAG(amount) OVER (ORDER BY order_id) FROM FACT_SALES;
```

### Fehler 3: ORA-30554 (Function not allowed with windowing)

```sql
-- ❌ FALSCH: FIRST_VALUE mit RANGE auf nicht-DATE
SELECT FIRST_VALUE(amount) OVER (
  ORDER BY year
  RANGE BETWEEN 10 PRECEDING AND CURRENT ROW
) FROM FACT_SALES;

-- ✅ RICHTIG: ROWS statt RANGE verwenden
SELECT FIRST_VALUE(amount) OVER (
  ORDER BY year
  ROWS BETWEEN 10 PRECEDING AND CURRENT ROW
) FROM FACT_SALES;
```

---

## ✅ Erfolgs-Checkliste

- [ ] Alle Tabellen vorhanden und gefüllt
- [ ] Einfache OVER() funktioniert
- [ ] PARTITION BY gruppiert korrekt
- [ ] ORDER BY erzeugt Running Totals
- [ ] ROWS BETWEEN funktioniert
- [ ] RANGE INTERVAL funktioniert (mit FULL_DATE)
- [ ] RANK, DENSE_RANK, ROW_NUMBER unterscheiden sich korrekt
- [ ] LAG/LEAD liefern vorherige/nächste Werte
- [ ] Alle 9 Übungsaufgaben ausführbar
- [ ] Ergebnisse plausibel (keine negativen Werte, NULLs erwartet, etc.)

---

## 🚀 Performance Testing (Optional)

```sql
-- Test Performance mit/ohne Index
SET TIMING ON;

-- Ohne Index auf DIM_TIME.FULL_DATE
SELECT COUNT(*)
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
WHERE dt.full_date BETWEEN DATE '2017-01-01' AND DATE '2017-12-31';

-- Index erstellen (aus verbesserungen_zu_uebung_02)
CREATE INDEX idx_dim_time_full_date ON DIM_TIME(full_date);

-- Selbe Query nochmal - sollte schneller sein
SELECT COUNT(*)
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
WHERE dt.full_date BETWEEN DATE '2017-01-01' AND DATE '2017-12-31';
```

---

Viel Erfolg beim Testen! 🎉
