# DBI Übung 05 – Analytische Funktionen (Window Functions)

> **Autor:** Jan Ritt  
> **Kurs:** Datenbanken und Informationssysteme (DBI) 2025/26  
> **Geöffnet:** Freitag, 17. Oktober 2025, 00:00  
> **Fällig:** Montag, 3. November 2025, 06:00

---

## 📋 Überblick

Diese Übung behandelt **Oracle Analytic Functions** (auch Window Functions genannt) auf Basis des Star-Schemas aus Übung 02 (Company/OT-Datenbank). Die Aufgaben demonstrieren verschiedene analytische Funktionen wie `SUM()`, `AVG()`, `RANK()`, `LAG()` und die Verwendung von Fensterdefinitionen (`PARTITION BY`, `ORDER BY`, `ROWS`, `RANGE`).

---

## 🎯 Lernziele

- Verständnis analytischer Funktionen vs. traditioneller Aggregate
- Verwendung von `PARTITION BY` zur Gruppierung
- Fensterdefinitionen mit `ROWS` und `RANGE`
- Ranking-Funktionen (`RANK`, `DENSE_RANK`, `ROW_NUMBER`)
- Navigation zwischen Zeilen (`LAG`, `LEAD`)
- Running Totals (laufende Summen)
- Moving Averages (gleitende Durchschnitte)

---

## 📂 Dateien in diesem Verzeichnis

| Datei | Beschreibung |
|-------|--------------|
| `angabe.md` | Offizielle Aufgabenstellung |
| `code_der_stunde.txt` | Beispielcode aus der Vorlesung |
| `window_functions.pdf` | Theoretische Grundlagen zu Window Functions |
| `window_functions_pdf.md` | Markdown-Version des PDFs |
| `RITT_uebung_05_analytische_funktionen.sql` | **Hauptabgabe: Lösungen aller 9 Aufgaben** |
| `dbi_2025_26_oracle.session.sql` | SQL-Session-File für Oracle DB (Docker) |
| `README.md` | Diese Datei |

---

## ✅ Aufgaben und Lösungen

Alle Lösungen befinden sich in der Datei **`RITT_uebung_05_analytische_funktionen.sql`**.

### Aufgabe 1: Gesamtumsatz aller Sales-Verkäufe
**Analytische Funktion:** `SUM(amount) OVER ()`  
**Konzept:** Aggregation über alle Zeilen ohne Gruppierung

### Aufgabe 2: Gesamtumsatz der Sales-Verkäufe je Jahr
**Analytische Funktion:** `SUM(amount) OVER (PARTITION BY year)`  
**Konzept:** Gruppierung nach Jahr mittels `PARTITION BY`

### Aufgabe 3: Rang (bezogen auf sales) des Sales-Eintrags
**Analytische Funktion:** `RANK() OVER (ORDER BY amount DESC)`  
**Konzept:** Ranking über alle Verkäufe

### Aufgabe 4: Rang relativ zum Verkaufstag
**Analytische Funktion:** `RANK() OVER (PARTITION BY year, month, day ORDER BY amount DESC)`  
**Konzept:** Ranking innerhalb jedes Tages

### Aufgabe 5: Laufende Summe der Verkäufe dieses Tages
**Analytische Funktion:** `SUM(amount) OVER (PARTITION BY year, month, day ORDER BY amount)`  
**Konzept:** Running Total mit implizitem Fenster

### Aufgabe 6: Gleitender Durchschnitt der letzten 10 Verkäufe
**Analytische Funktion:** `AVG(amount) OVER (ORDER BY ... ROWS BETWEEN 9 PRECEDING AND CURRENT ROW)`  
**Konzept:** Moving Average mit `ROWS` (zeilenbasiert)

### Aufgabe 7: Gleitender Durchschnitt der letzten 10 Tage
**Analytische Funktion:** `AVG(amount) OVER (ORDER BY datum RANGE BETWEEN INTERVAL '10' DAY PRECEDING AND CURRENT ROW)`  
**Konzept:** Moving Average mit `RANGE` (wertbasiert auf Datum)

### Aufgabe 8: Rang der Verkäufer nach deren Jahresumsatz
**Analytische Funktion:** `RANK() OVER (PARTITION BY year ORDER BY jahresumsatz DESC)`  
**Konzept:** Ranking auf aggregierten Daten (CTE)

### Aufgabe 9: Umsatzdifferenz zum nächst-schlechteren Verkäufer
**Analytische Funktion:** `LAG(jahresumsatz) OVER (PARTITION BY year ORDER BY jahresumsatz DESC)`  
**Konzept:** Zugriff auf vorherige Zeile mittels `LAG`

---

## 🚀 Ausführung

### Voraussetzungen

1. **Oracle Database** läuft (z.B. in Docker)
2. **Star-Schema aus Übung 02** ist erstellt und befüllt:
   - `FACT_SALES`
   - `DIM_TIME`
   - `DIM_PRODUCT`
   - `DIM_CUSTOMER`
   - `DIM_EMPLOYEE`
   - `DIM_STATUS`

### Ablauf

```sql
-- 1. Verbindung zur Oracle DB herstellen (siehe Screenshot im Projekt)
-- 2. Star-Schema prüfen
SELECT COUNT(*) FROM FACT_SALES;

-- 3. Übung 05 ausführen
@RITT_uebung_05_analytische_funktionen.sql
```

---

## 📊 Star-Schema Übersicht (aus Übung 02)

```
┌─────────────┐       ┌──────────────┐       ┌──────────────┐
│  DIM_TIME   │       │ DIM_PRODUCT  │       │ DIM_CUSTOMER │
├─────────────┤       ├──────────────┤       ├──────────────┤
│ id (PK)     │       │ id (PK)      │       │ id (PK)      │
│ year        │       │ product_name │       │ customer_name│
│ month       │       │ category_name│       │ address      │
│ day         │       │ list_price   │       │ credit_limit │
└──────┬──────┘       └──────┬───────┘       └──────┬───────┘
       │                     │                      │
       │              ┌──────┴──────────────────────┴──────┐
       │              │                                     │
       └──────────────┤         FACT_SALES                  │
                      ├─────────────────────────────────────┤
       ┌──────────────┤ t (FK) → DIM_TIME                   │
       │              │ product (FK) → DIM_PRODUCT          │
       │              │ customer (FK) → DIM_CUSTOMER        │
┌──────┴────────┐     │ employee (FK) → DIM_EMPLOYEE        │
│ DIM_EMPLOYEE  │     │ status (FK) → DIM_STATUS            │
├───────────────┤     │ order_id, item_id                   │
│ id (PK)       │     │ quantity, unit_price, amount        │
│ first_name    │     └─────────────────────────────────────┘
│ last_name     │              │
│ job_title     │              │
└───────────────┘       ┌──────┴───────┐
                        │  DIM_STATUS  │
                        ├──────────────┤
                        │ id (PK)      │
                        │ status       │
                        └──────────────┘
```

**Grain:** Eine Zeile pro Bestellposition (order_id, item_id)  
**Measures:** quantity, unit_price, amount

---

## 🔑 Wichtige Konzepte

### OVER Clause - Macht Funktion analytisch

```sql
-- Traditionelles Aggregat (eine Zeile pro Gruppe)
SELECT deptno, SUM(sal) FROM emp GROUP BY deptno;

-- Analytische Funktion (alle Zeilen bleiben erhalten)
SELECT deptno, empno, SUM(sal) OVER (PARTITION BY deptno) FROM emp;
```

### PARTITION BY - Gruppierung ohne Zeilenreduktion

```sql
-- Gesamtumsatz je Jahr, aber alle Detailzeilen bleiben sichtbar
SUM(amount) OVER (PARTITION BY year)
```

### ORDER BY in OVER - Aktiviert implizites Fenster

```sql
-- Implizites Fenster: UNBOUNDED PRECEDING AND CURRENT ROW
SUM(amount) OVER (ORDER BY datum)
```

### ROWS vs RANGE

| Typ | Bedeutung | Beispiel |
|-----|-----------|----------|
| `ROWS` | Anzahl von Zeilen | `ROWS BETWEEN 9 PRECEDING AND CURRENT ROW` |
| `RANGE` | Wertebereich | `RANGE BETWEEN INTERVAL '10' DAY PRECEDING AND CURRENT ROW` |

### Ranking-Funktionen

| Funktion | Bei Gleichheit | Beispiel (1, 2, 2, 4) |
|----------|----------------|------------------------|
| `RANK()` | Gleicher Rang, Lücken | 1, 2, 2, 4 |
| `DENSE_RANK()` | Gleicher Rang, keine Lücken | 1, 2, 2, 3 |
| `ROW_NUMBER()` | Fortlaufend eindeutig | 1, 2, 3, 4 |

---

## 📚 Quellen

- [DBI Star-Schema Firmendatenbank (Übung 02)](https://github.com/IxI-Enki/DBI_2025_26_uebung_02)
- `window_functions.pdf` - Oracle Analytic Functions Guide
- `code_der_stunde.txt` - Vorlesungsbeispiele

---

## 💡 Tipps

1. **Analytische Funktionen vs WHERE**: Analytische Funktionen werden *nach* WHERE ausgewertet → für Filterung auf analytische Werte Subquery verwenden
2. **NULL-Werte**: `LAG`/`LEAD` liefern `NULL`, wenn keine vorherige/nächste Zeile existiert
3. **Performance**: Analytische Funktionen sind oft schneller als Self-Joins oder korrelierte Subqueries
4. **Datum konstruieren**: Bei Aufgabe 7 muss ein DATE-Objekt für RANGE INTERVAL erstellt werden

---

## 📝 Notizen zur Implementierung

### Aufgabe 7 - Besonderheit

Die Zeit-Dimension (`DIM_TIME`) hat nur separate Felder für `year`, `month`, `day` (keine vollständige `DATE`-Spalte). Für `RANGE BETWEEN INTERVAL` muss ein temporäres Datum konstruiert werden:

```sql
TO_DATE(
    LPAD(year, 4, '0') || '-' || 
    LPAD(month, 2, '0') || '-' || 
    LPAD(day, 2, '0'), 
    'YYYY-MM-DD'
)
```

**Alternative Verbesserung für Übung 02:** `DIM_TIME` um Spalte `full_date DATE` erweitern (siehe `verbesserungen_zu_uebung_02/`).

---

## ✨ Best Practices

1. **Kommentierung**: Jede analytische Funktion sollte erklären, was sie tut
2. **Lesbarkeit**: OVER-Clauses mehrzeilig formatieren bei komplexen Definitionen
3. **Testing**: Mit kleinen Datenmengen testen und Ergebnisse manuell nachrechnen
4. **Performance**: Bei großen Daten `ROWS` bevorzugen (schneller als `RANGE`)

---

Viel Erfolg! 🚀
