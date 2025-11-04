----------------------------------------------------------------------------------------------------
-- DBI Übung 05 – Analytische Funktionen (Window Functions)
-- Autor: Jan Ritt
-- Datum: 2025-10-28
-- Kurs: Datenbanken und Informationssysteme (DBI) 2025/26
--
-- Beschreibung:
-- Diese Datei enthält Lösungen zu allen 9 Aufgaben der Übung "Analytische Funktionen"
-- auf Basis des Star-Schemas aus Übung 02 (Company/OT-Datenbank)
--
-- Voraussetzungen:
-- - Star-Schema (FACT_SALES, DIM_TIME, DIM_PRODUCT, DIM_CUSTOMER, DIM_EMPLOYEE, DIM_STATUS)
--   muss existieren und befüllt sein (siehe Übung 02)
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Aufgabe 1: Gesamtumsatz aller Sales-Verkäufe
----------------------------------------------------------------------------------------------------
-- Erläuterung:
-- SUM(amount) OVER () berechnet die Gesamtsumme über ALLE Verkäufe
-- und wiederholt diese bei jeder Zeile als zusätzliche Spalte
----------------------------------------------------------------------------------------------------

SELECT
    fs.order_id,
    fs.item_id,
    fs.quantity,
    fs.unit_price,
    fs.amount,
    SUM(fs.amount) OVER () AS gesamtumsatz_alle_sales
FROM FACT_SALES fs
ORDER BY fs.order_id, fs.item_id;


----------------------------------------------------------------------------------------------------
-- Aufgabe 2: Gesamtumsatz der Sales-Verkäufe je Jahr
----------------------------------------------------------------------------------------------------
-- Erläuterung:
-- PARTITION BY dt.year teilt die Daten nach Jahren auf
-- SUM(amount) berechnet dann die Summe pro Jahr
----------------------------------------------------------------------------------------------------

SELECT
    fs.order_id,
    fs.item_id,
    fs.amount,
    dt.year AS jahr,
    SUM(fs.amount) OVER () AS gesamtumsatz_alle,
    SUM(fs.amount) OVER (PARTITION BY dt.year) AS gesamtumsatz_jahr
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
ORDER BY dt.year, fs.order_id, fs.item_id;


----------------------------------------------------------------------------------------------------
-- Aufgabe 3: Rang (bezogen auf sales) des Sales-Eintrags
----------------------------------------------------------------------------------------------------
-- Erläuterung:
-- RANK() ordnet die Verkäufe nach Umsatz (amount)
-- Bei gleichen Werten erhalten die Zeilen den gleichen Rang
-- Höherer Umsatz = höherer Rang (DESC)
----------------------------------------------------------------------------------------------------

SELECT
    fs.order_id,
    fs.item_id,
    fs.amount,
    RANK() OVER (ORDER BY fs.amount DESC) AS rang_nach_umsatz,
    DENSE_RANK() OVER (ORDER BY fs.amount DESC) AS dense_rang_nach_umsatz,
    ROW_NUMBER() OVER (ORDER BY fs.amount DESC) AS zeilen_nummer
FROM FACT_SALES fs
ORDER BY fs.amount DESC;


----------------------------------------------------------------------------------------------------
-- Aufgabe 4: Rang relativ zum Verkaufstag (Jahr+Monat+Tag)
----------------------------------------------------------------------------------------------------
-- Erläuterung:
-- PARTITION BY dt.year, dt.month, dt.day gruppiert nach vollständigem Datum
-- RANK() wird innerhalb jedes Tages separat berechnet
----------------------------------------------------------------------------------------------------

SELECT
    fs.order_id,
    fs.item_id,
    dt.year,
    dt.month,
    dt.day,
    fs.amount,
    RANK() OVER (
        PARTITION BY dt.year, dt.month, dt.day
        ORDER BY fs.amount DESC
    ) AS rang_am_tag
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
ORDER BY dt.year, dt.month, dt.day, rang_am_tag;


----------------------------------------------------------------------------------------------------
-- Aufgabe 5: Laufende Summe der Verkäufe dieses Tages
----------------------------------------------------------------------------------------------------
-- Erläuterung:
-- Die laufende Summe (Running Total) wird für jeden Tag separat berechnet
-- ORDER BY amount: sortiert innerhalb des Tages nach Umsatz
-- Implizites Fenster: ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
----------------------------------------------------------------------------------------------------

SELECT
    fs.order_id,
    fs.item_id,
    dt.year,
    dt.month,
    dt.day,
    fs.amount,
    SUM(fs.amount) OVER (
        PARTITION BY dt.year, dt.month, dt.day
        ORDER BY fs.amount
    ) AS laufende_summe_tag,
    -- Alternative: explizite Fensterdeklaration (identisches Ergebnis)
    SUM(fs.amount) OVER (
        PARTITION BY dt.year, dt.month, dt.day
        ORDER BY fs.amount
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS laufende_summe_tag_explizit
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
ORDER BY dt.year, dt.month, dt.day, fs.amount;


----------------------------------------------------------------------------------------------------
-- Aufgabe 6: Gleitender Durchschnitt der letzten 10 Verkäufe
----------------------------------------------------------------------------------------------------
-- Erläuterung:
-- ROWS BETWEEN 9 PRECEDING AND CURRENT ROW = die letzten 10 Zeilen (9 davor + aktuelle)
-- Sortierung: erst nach vollständigem Datum, dann nach amount
-- AVG() berechnet den Durchschnitt über dieses gleitende Fenster von 10 Verkäufen
----------------------------------------------------------------------------------------------------

SELECT
    fs.order_id,
    fs.item_id,
    dt.year,
    dt.month,
    dt.day,
    fs.amount,
    AVG(fs.amount) OVER (
        ORDER BY dt.year, dt.month, dt.day, fs.amount
        ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
    ) AS gleitender_durchschnitt_10_verkaufe
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
ORDER BY dt.year, dt.month, dt.day, fs.amount;


----------------------------------------------------------------------------------------------------
-- Aufgabe 7: Gleitender Durchschnitt der Verkaufssummen der letzten 10 Tage
----------------------------------------------------------------------------------------------------
-- Erläuterung:
-- RANGE BETWEEN INTERVAL '10' DAY PRECEDING AND CURRENT ROW
-- benötigt ein "echtes" Datums-Feld (DATE-Typ)
-- Da DIM_TIME nur year, month, day hat, konstruieren wir ein temporäres Datum mit TO_DATE
--
-- WICHTIG: RANGE arbeitet mit Wertebereichen (hier: Tage), nicht mit Zeilenanzahl
----------------------------------------------------------------------------------------------------

SELECT
    fs.order_id,
    fs.item_id,
    dt.year,
    dt.month,
    dt.day,
    TO_DATE(
        LPAD(dt.year, 4, '0') || '-' ||
        LPAD(dt.month, 2, '0') || '-' ||
        LPAD(dt.day, 2, '0'),
        'YYYY-MM-DD'
    ) AS verkaufsdatum,
    fs.amount,
    AVG(fs.amount) OVER (
        ORDER BY TO_DATE(
            LPAD(dt.year, 4, '0') || '-' ||
            LPAD(dt.month, 2, '0') || '-' ||
            LPAD(dt.day, 2, '0'),
            'YYYY-MM-DD'
        )
        RANGE BETWEEN INTERVAL '10' DAY PRECEDING AND CURRENT ROW
    ) AS gleitender_durchschnitt_10_tage
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
ORDER BY dt.year, dt.month, dt.day;


----------------------------------------------------------------------------------------------------
-- Aufgabe 8: Rang der Verkäufer nach deren Jahresumsatz
----------------------------------------------------------------------------------------------------
-- Erläuterung:
-- Zuerst wird der Jahresumsatz pro Verkäufer aggregiert (Subquery/WITH)
-- Dann wird RANK() auf diese Aggregation angewendet
-- Verkäufer ohne Zuordnung (employee IS NULL) werden separat behandelt
----------------------------------------------------------------------------------------------------

WITH verkaufer_jahresumsatz AS (
    SELECT
        dt.year,
        fs.employee,
        de.first_name,
        de.last_name,
        SUM(fs.amount) AS jahresumsatz
    FROM FACT_SALES fs
    JOIN DIM_TIME dt ON fs.t = dt.id
    LEFT JOIN DIM_EMPLOYEE de ON fs.employee = de.id
    WHERE fs.employee IS NOT NULL  -- nur Verkäufe mit zugeordnetem Verkäufer
    GROUP BY dt.year, fs.employee, de.first_name, de.last_name
)
SELECT
    year,
    employee,
    first_name,
    last_name,
    jahresumsatz,
    RANK() OVER (PARTITION BY year ORDER BY jahresumsatz DESC) AS rang_im_jahr
FROM verkaufer_jahresumsatz
ORDER BY year, rang_im_jahr;


----------------------------------------------------------------------------------------------------
-- Aufgabe 9: Umsatzdifferenz zum nächst-schlechteren Verkäufer
----------------------------------------------------------------------------------------------------
-- Erläuterung:
-- LAG(jahresumsatz) liefert den Umsatz des nächst-schlechteren Verkäufers
-- (da absteigend sortiert nach jahresumsatz)
-- Die Differenz zeigt, um wie viel mehr der aktuelle Verkäufer erwirtschaftet hat
----------------------------------------------------------------------------------------------------

WITH verkaufer_jahresumsatz AS (
    SELECT
        dt.year,
        fs.employee,
        de.first_name,
        de.last_name,
        SUM(fs.amount) AS jahresumsatz
    FROM FACT_SALES fs
    JOIN DIM_TIME dt ON fs.t = dt.id
    LEFT JOIN DIM_EMPLOYEE de ON fs.employee = de.id
    WHERE fs.employee IS NOT NULL
    GROUP BY dt.year, fs.employee, de.first_name, de.last_name
)
SELECT
    year,
    employee,
    first_name,
    last_name,
    jahresumsatz,
    RANK() OVER (PARTITION BY year ORDER BY jahresumsatz DESC) AS rang_im_jahr,
    LAG(jahresumsatz) OVER (PARTITION BY year ORDER BY jahresumsatz DESC) AS umsatz_naechst_schlechter,
    jahresumsatz - LAG(jahresumsatz) OVER (PARTITION BY year ORDER BY jahresumsatz DESC) AS mehrwert_gegenueber_naechstem
FROM verkaufer_jahresumsatz
ORDER BY year, rang_im_jahr;


----------------------------------------------------------------------------------------------------
-- BONUS: Kombinierte Übersicht mit mehreren analytischen Funktionen
----------------------------------------------------------------------------------------------------
-- Diese Query kombiniert mehrere Aufgaben in einer Abfrage zur besseren Übersicht
----------------------------------------------------------------------------------------------------

SELECT
    fs.order_id,
    fs.item_id,
    dt.year,
    dt.month,
    dt.day,
    TO_DATE(
        LPAD(dt.year, 4, '0') || '-' ||
        LPAD(dt.month, 2, '0') || '-' ||
        LPAD(dt.day, 2, '0'),
        'YYYY-MM-DD'
    ) AS verkaufsdatum,
    de.first_name || ' ' || de.last_name AS verkaufer,
    dp.product_name,
    dc.customer_name,
    fs.quantity,
    fs.unit_price,
    fs.amount,
    -- Aufgabe 1: Gesamtumsatz aller Sales
    SUM(fs.amount) OVER () AS gesamtumsatz_alle,
    -- Aufgabe 2: Gesamtumsatz je Jahr
    SUM(fs.amount) OVER (PARTITION BY dt.year) AS gesamtumsatz_jahr,
    -- Aufgabe 3: Rang nach Umsatz (global)
    RANK() OVER (ORDER BY fs.amount DESC) AS rang_global,
    -- Aufgabe 4: Rang am Tag
    RANK() OVER (PARTITION BY dt.year, dt.month, dt.day ORDER BY fs.amount DESC) AS rang_am_tag,
    -- Aufgabe 5: Laufende Summe des Tages
    SUM(fs.amount) OVER (
        PARTITION BY dt.year, dt.month, dt.day
        ORDER BY fs.amount
    ) AS laufende_summe_tag,
    -- Aufgabe 6: Gleitender Durchschnitt der letzten 10 Verkäufe
    AVG(fs.amount) OVER (
        ORDER BY dt.year, dt.month, dt.day, fs.amount
        ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
    ) AS gleit_avg_10_verkaufe
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.t = dt.id
JOIN DIM_PRODUCT dp ON fs.product = dp.id
JOIN DIM_CUSTOMER dc ON fs.customer = dc.id
LEFT JOIN DIM_EMPLOYEE de ON fs.employee = de.id
ORDER BY dt.year, dt.month, dt.day, fs.order_id, fs.item_id;

----------------------------------------------------------------------------------------------------
COMMIT;
----------------------------------------------------------------------------------------------------
