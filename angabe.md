# Übung zu "Analytische Funktionen"

> Geöffnet: Freitag, 17. Oktober 2025, 00:00
> Fällig: Montag, 3. November 2025, 06:00

## Führen Sie auf dem Star-Schema der Hausübung "Star-Schema Firmendatenbank" folgende Abfragen aus

### Als zusätzliche Spalte (= unter Verwendung von analytischen Funktionen)

1. Gesamtumsatz aller Sales-Verkäufe
2. Gesamtumsatz der Sales-Verkäufe je Jahr
3. Rang (bezogen auf sales) des Sales-Eintrags
4. Anstatt den Rang über alle Verkäufe zu ermitteln, soll der Rang relativ zum Verkaufstag (Jahr+Monat+Tag) berechnet werden
5. die laufende Summe der Verkäufe dieses Tages
6. den gleitenden Durchschnitt der Verkaufssummen der letzten 10 Verkäufe (sortiert nach Datum und Sales-Wert)
7. gleitender Durchschnitt der Verkaufssummen der letzten 10 Tage.
  
  > Hinweis: Intervallberechnung sind nur auf Spalten mit "echten" Zeit-Datentypen (z.B. DATE) möglich, nicht auf den aufgespalteten Auflösungsstufen der Zeit-Dimension.
  > Erweitern Sie zur Lösung dieser Aufgabenstellung entweder die Zeit-Dimension um eine Spalte, die das vollständige Datum enthält, oder konstruieren sie einen temporären Datumswert
  > z.B. mit TO_DATE, Beispiel:
  >
  > ```sql
  > TO_DATE(LPAD(year_num, 4, '0') ||
  > '-' || LPAD(month_num, 2, '0') ||
  > '-' || LPAD(day_num, 2, '0'), 'YYYY-MM-DD')
  > -- year_num, month_num, day_num aus Zeitdimension
  > ```

<!-- markdownlint-disable MD029 -->
8. Rang der Verkäufer nach deren Jahresumsatz
9. Geben Sie zu jedem Verkäufer an, um wie viel er mehr Umsatz generiert hat, als der nächst-schlechtere Verkäufer.
<!-- markdownlint-enable MD029 -->

<!--
### Zusätzliche Quellen

- [DBI Star-Schema Firmendatenbank](https://github.com/IxI-Enki/DBI_2025_26_uebung_02)
- [DBI Übung 02](../dbi_uebung_02)
-->