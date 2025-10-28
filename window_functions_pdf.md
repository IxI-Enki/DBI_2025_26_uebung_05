# Oracle Analytic Functions (Fensterfunktionen)

> Inhalt der PDF-Datei zur **Oracle Analytic Functions** im Markdown-Format, einschließlich der Tabellen.

---

<!-- markdownlint-disable MD033 -->
<div style="display: flex; align-items: center; justify-content: space-between; padding: 20px 0;">
  
  <!-- Logo links -->
  <div style="flex: 0 0 auto;">
    <img src="collab12logo.png" alt="COLLABORATE 12" height="80"/>
  </div>
  
  <!-- Text Mitte -->
  <div style="flex: 1; padding: 0 30px;">
    <h2 style="margin: 0; color: #666;">
      COLLABORATE<span style="color: #00a3c4;">12</span>
    </h2>
    <p style="margin: 5px 0 0 0; font-size: 0.7em; color: #666; text-transform: uppercase;">
      Technology and Applications Forum<br/>for the Oracle Community
    </p>
  </div>
  
  <!-- IOUG Logo rechts -->
  <div style="flex: 0 0 auto;">

$$\Huge\color{#007}{\boldsymbol{⟨}}\!\! \begin{array}{c} \textbf{\color{#00a3c4}{{IOUG}}} \\[-22pt] \tiny\textbf{independent oracle users group} \end{array}\!\!\color{#007}{\boldsymbol{⟩}}$$

  </div>
  
</div>
<!-- markdownlint-enable MD033 -->

---

## Agenda

* **Aggregate vs Analytic**
* **PARTITION BY**
* **ORDER BY**
* **Window Clause**
  * **ROWS**
  * **RANGE**

---

## WHY USE ANALYTIC FUNCTIONS?

* Ability to see one row from another row in the results
* Avoid self-join queries
* Summary data in detail rows
* Slice and dice within the results

---

## AGGREGATE OR ANALYTIC?

| Funktion | Aggregate | Analytic |
|:---|:---|:---|
| COUNT | ✅ | ✅ |
| SUM | ✅ | ✅ |
| MAX | ✅ | ✅ |
| MIN | ✅ | ✅ |

---

### What's the difference?

| | SYNTAX | OUTPUT |
|:---|:---|:---|
| **Aggregate (traditional)** | Query often includes the keywords **GROUP BY** | Output is a single row (or one row per group with GROUP BY) |
| **Analytic** | **OVER** (some other stuff) | Does not change number of rows |

---

<!-- markdownlint-disable MD033 -->

<h2 align="center" style="color: #003d5c; font-size: 2em; margin: 40px 0; border-bottom: 2px solid #ccc; padding-bottom: 10px;">AGGREGATE EXAMPLES</h2>

<div style="display: grid; grid-template-columns: 1fr 1fr 320px; gap: 15px; margin: 30px 0;">

<!-- ========== LINKE SPALTE - Seite 1 ========== -->
<div style="grid-column: 1;">

<div style="border: 2px solid #000; padding: 0; margin-bottom: 20px; background: white; font-family: monospace;">
<div style="background: #f0f0f0; padding: 8px; border-bottom: 1px solid #bbb;">
<span style="color: #0066cc; font-weight: bold;">SELECT COUNT</span> ( * )<br/>
<span style="color: #0066cc; font-weight: bold;">FROM</span> scott.emp;
</div>
<div style="padding: 12px;">
<strong>COUNT(*)</strong><br/>
---------<br/>
14<br/>
<br/>
<em>1 row selected.</em>
</div>
</div>

<div style="border: 2px solid #000; padding: 0; margin-bottom: 20px; background: white; font-family: monospace;">
<div style="background: #f0f0f0; padding: 8px; border-bottom: 1px solid #bbb;">
<span style="color: #0066cc; font-weight: bold;">SELECT SUM</span> ( sal )<br/>
<span style="color: #0066cc; font-weight: bold;">FROM</span> scott.emp;
</div>
<div style="padding: 12px;">
<strong>SUM(SAL)</strong><br/>
---------<br/>
29025<br/>
<br/>
<em>1 row selected.</em>
</div>
</div>

</div>

<!-- ========== MITTLERE SPALTE - Seite 1 ========== -->
<div style="grid-column: 2;">

<div style="border: 2px solid #000; padding: 0; background: white; font-family: monospace;">
<div style="background: #f0f0f0; padding: 8px; border-bottom: 1px solid #bbb;">
<span style="color: #0066cc; font-weight: bold;">SELECT COUNT</span> ( * )<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;, <span style="color: #0066cc; font-weight: bold;">SUM</span> ( sal )<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;, <span style="color: #0066cc; font-weight: bold;">MAX</span> ( sal )<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;, <span style="color: #0066cc; font-weight: bold;">MIN</span> ( ename )<br/>
<span style="color: #0066cc; font-weight: bold;">FROM</span> scott.emp;
</div>
<div style="padding: 12px;">
<strong>COUNT(*) &nbsp; SUM(SAL) &nbsp; MAX(SAL) &nbsp; MIN(ENAME)</strong><br/>
-------- &nbsp; -------- &nbsp; -------- &nbsp; ----------<br/>
14 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 29025 &nbsp;&nbsp;&nbsp;&nbsp; 5000 &nbsp;&nbsp;&nbsp;&nbsp; ADAMS<br/>
<br/>
<em>1 row selected.</em>
</div>
</div>

</div>

<!-- ========== RECHTE SPALTE - DATENTABELLE ========== -->
<div style="grid-column: 3; grid-row: 1 / 3;">

<div style="border: 2px solid #003d5c; background: white; overflow: hidden;">

<table style="width: 100%; border-collapse: collapse; font-family: monospace; font-size: 0.9em;">
<thead>
<tr style="background: #003d5c; color: white;">
<th style="padding: 8px; text-align: center; border: 1px solid #003d5c;">Deptno</th>
<th style="padding: 8px; text-align: center; border: 1px solid #003d5c;">Ename</th>
<th style="padding: 8px; text-align: center; border: 1px solid #003d5c;">Sal</th>
</tr>
</thead>
<tbody>
<tr style="background: #e8e8e8;"><td style="padding: 6px; text-align: center; border: 1px solid #ddd;">10</td><td style="padding: 6px; border: 1px solid #ddd;">Clark</td><td style="padding: 6px; text-align: right; border: 1px solid #ddd;">2450</td></tr>
<tr style="background: #e8e8e8;"><td style="padding: 6px; text-align: center; border: 1px solid #ddd;">10</td><td style="padding: 6px; border: 1px solid #ddd;">King</td><td style="padding: 6px; text-align: right; border: 1px solid #ddd;">5000</td></tr>
<tr style="background: #e8e8e8;"><td style="padding: 6px; text-align: center; border: 1px solid #ddd;">10</td><td style="padding: 6px; border: 1px solid #ddd;">Miller</td><td style="padding: 6px; text-align: right; border: 1px solid #ddd;">1300</td></tr>
<tr style="background: #d8d8d8;"><td style="padding: 6px; text-align: center; border: 1px solid #ddd;">20</td><td style="padding: 6px; border: 1px solid #ddd;">Adams</td><td style="padding: 6px; text-align: right; border: 1px solid #ddd;">1100</td></tr>
<tr style="background: #d8d8d8;"><td style="padding: 6px; text-align: center; border: 1px solid #ddd;">20</td><td style="padding: 6px; border: 1px solid #ddd;">Ford</td><td style="padding: 6px; text-align: right; border: 1px solid #ddd;">3000</td></tr>
<tr style="background: #d8d8d8;"><td style="padding: 6px; text-align: center; border: 1px solid #ddd;">20</td><td style="padding: 6px; border: 1px solid #ddd;">Jones</td><td style="padding: 6px; text-align: right; border: 1px solid #ddd;">2975</td></tr>
<tr style="background: #d8d8d8;"><td style="padding: 6px; text-align: center; border: 1px solid #ddd;">20</td><td style="padding: 6px; border: 1px solid #ddd;">Scott</td><td style="padding: 6px; text-align: right; border: 1px solid #ddd;">3000</td></tr>
<tr style="background: #d8d8d8;"><td style="padding: 6px; text-align: center; border: 1px solid #ddd;">20</td><td style="padding: 6px; border: 1px solid #ddd;">Smith</td><td style="padding: 6px; text-align: right; border: 1px solid #ddd;">800</td></tr>
<tr style="background: #c8c8c8;"><td style="padding: 6px; text-align: center; border: 1px solid #ddd;">30</td><td style="padding: 6px; border: 1px solid #ddd;">Allen</td><td style="padding: 6px; text-align: right; border: 1px solid #ddd;">1600</td></tr>
<tr style="background: #c8c8c8;"><td style="padding: 6px; text-align: center; border: 1px solid #ddd;">30</td><td style="padding: 6px; border: 1px solid #ddd;">Blake</td><td style="padding: 6px; text-align: right; border: 1px solid #ddd;">2850</td></tr>
<tr style="background: #c8c8c8;"><td style="padding: 6px; text-align: center; border: 1px solid #ddd;">30</td><td style="padding: 6px; border: 1px solid #ddd;">James</td><td style="padding: 6px; text-align: right; border: 1px solid #ddd;">950</td></tr>
<tr style="background: #c8c8c8;"><td style="padding: 6px; text-align: center; border: 1px solid #ddd;">30</td><td style="padding: 6px; border: 1px solid #ddd;">Martin</td><td style="padding: 6px; text-align: right; border: 1px solid #ddd;">1250</td></tr>
<tr style="background: #c8c8c8;"><td style="padding: 6px; text-align: center; border: 1px solid #ddd;">30</td><td style="padding: 6px; border: 1px solid #ddd;">Turner</td><td style="padding: 6px; text-align: right; border: 1px solid #ddd;">1500</td></tr>
<tr style="background: #c8c8c8;"><td style="padding: 6px; text-align: center; border: 1px solid #ddd;">30</td><td style="padding: 6px; border: 1px solid #ddd;">Ward</td><td style="padding: 6px; text-align: right; border: 1px solid #ddd;">1250</td></tr>
</tbody>
</table>

</div>

</div>

</div>

<div style="height: 40px; border-bottom: 3px solid #003d5c; margin: 40px 0;"></div>

<!-- ========== SEITE 2 ========== -->

<div style="display: grid; grid-template-columns: 1fr 1fr 320px; gap: 15px; margin: 30px 0;">

<!-- ========== LINKE SPALTE - Seite 2 ========== -->
<div style="grid-column: 1;">

<div style="border: 2px solid #000; padding: 0; background: white; font-family: monospace;">
<div style="background: #f0f0f0; padding: 8px; border-bottom: 1px solid #bbb;">
<span style="color: #0066cc; font-weight: bold;">SELECT COUNT</span> ( * )<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;, <span style="color: #0066cc; font-weight: bold;">SUM</span> ( sal )<br/>
<span style="color: #0066cc; font-weight: bold;">FROM</span> scott.emp<br/>
<span style="color: #0066cc; font-weight: bold;">WHERE</span> deptno = <span style="color: #009900;">30</span>;
</div>
<div style="padding: 12px;">
<strong>COUNT(*) &nbsp; SUM(SAL)</strong><br/>
-------- &nbsp; --------<br/>
6 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 9400<br/>
<br/>
<em>1 row selected.</em>
</div>
</div>

</div>

<!-- ========== MITTLERE SPALTE - Seite 2 ========== -->
<div style="grid-column: 2;">

<div style="border: 2px solid #000; padding: 0; margin-bottom: 20px; background: white; font-family: monospace;">
<div style="background: #f0f0f0; padding: 8px; border-bottom: 1px solid #bbb;">
<span style="color: #0066cc; font-weight: bold;">SELECT</span> deptno<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;, <span style="color: #0066cc; font-weight: bold;">COUNT</span>(*)<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;, <span style="color: #0066cc; font-weight: bold;">SUM</span>(sal)<br/>
<span style="color: #0066cc; font-weight: bold;">FROM</span> scott.emp<br/>
<span style="color: #0066cc; font-weight: bold;">GROUP BY</span> deptno;
</div>
<div style="padding: 12px;">
<strong>DEPTNO &nbsp;&nbsp; COUNT(*) &nbsp;&nbsp; SUM(SAL)</strong><br/>
------ &nbsp;&nbsp; -------- &nbsp;&nbsp; --------<br/>
10 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 3 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 8750<br/>
20 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 5 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 10875<br/>
30 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 6 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 9400<br/>
<br/>
<em>3 rows selected.</em>
<div style="background: #003d5c; color: white; padding: 8px; margin-top: 10px; text-align: center; font-weight: bold;">
One record for each group
</div>
</div>
</div>

<div style="border: 2px solid #000; padding: 0; background: white; font-family: monospace;">
<div style="background: #f0f0f0; padding: 8px; border-bottom: 1px solid #bbb;">
<span style="color: #0066cc; font-weight: bold;">SELECT</span> deptno<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;, <span style="color: #0066cc; font-weight: bold;">COUNT</span>(*)<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;, <span style="color: #0066cc; font-weight: bold;">SUM</span>(sal)<br/>
<span style="color: #0066cc; font-weight: bold;">FROM</span> scott.emp;
</div>
<div style="padding: 12px; background: #fff;">
<br/>
<strong style="color: #cc0000;">ERROR at line 1:</strong><br/>
<strong style="color: #cc0000;">ORA-00937: not a single-group group function</strong>
</div>
</div>

</div>

<!-- ========== RECHTE SPALTE - Fortsetzung Datentabelle (optional) ========== -->
<div style="grid-column: 3;">

<p style="font-style: italic; color: #666; text-align: center;">
↑ Data from scott.emp table shown above ↑
</p>

</div>

</div>

<!-- markdownlint-enable MD033 -->

---

<h2 align="center" style="color: #003d5c; font-size: 2em; margin: 40px 0; border-bottom: 2px solid #ccc; padding-bottom: 10px;">ANALYTIC FUNCTIONS</h2>

<!-- ========== SEITE 1 ========== -->

<div style="display: grid; grid-template-columns: 1fr 1.2fr; gap: 20px; margin: 30px 0;">

<!-- LINKE SPALTE - Seite 1 -->
<div style="grid-column: 1;">

<h3 style="color: #0099cc; margin-bottom: 15px;">What makes a function analytic?</h3>

<ul style="color: #0099cc; font-size: 1.1em; line-height: 1.8;">
<li><strong>Keyword OVER</strong></li>
<li><strong>Followed by set of parentheses</strong></li>
</ul>

<div style="border: 2px solid #000; padding: 0; margin-top: 20px; background: white; font-family: monospace;">
<div style="background: #f0f0f0; padding: 8px; border-bottom: 1px solid #bbb;">
<span style="color: #0066cc; font-weight: bold;">SELECT</span> deptno, ename, sal<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;, <span style="color: #0066cc; font-weight: bold;">COUNT</span> ( * ) <span style="color: #0066cc; font-weight: bold;">OVER</span> ()<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;, <span style="color: #0066cc; font-weight: bold;">SUM</span> ( sal ) <span style="color: #0066cc; font-weight: bold;">OVER</span> ()<br/>
<span style="color: #0066cc; font-weight: bold;">FROM</span> scott.emp;
</div>
</div>

</div>

<!-- RECHTE SPALTE - Ergebnis-Tabelle -->
<div style="grid-column: 2; position: relative;">

<div style="border: 2px solid #003d5c; background: white; overflow: hidden;">

<table style="width: 100%; border-collapse: collapse; font-family: monospace; font-size: 0.85em;">
<thead>
<tr style="background: #f0f0f0; border-bottom: 2px solid #000;">
<th style="padding: 6px; text-align: center;">DEPTNO</th>
<th style="padding: 6px; text-align: left;">ENAME</th>
<th style="padding: 6px; text-align: right;">SAL</th>
<th style="padding: 6px; text-align: right;">COUNT(*)OVER()</th>
<th style="padding: 6px; text-align: right;">SUM(SAL)OVER()</th>
</tr>
</thead>
<tbody>
<tr><td style="padding: 4px; text-align: center;">10</td><td style="padding: 4px;">CLARK</td><td style="padding: 4px; text-align: right;">2450</td><td style="padding: 4px; text-align: right;">14</td><td style="padding: 4px; text-align: right;">29025</td></tr>
<tr><td style="padding: 4px; text-align: center;">10</td><td style="padding: 4px;">KING</td><td style="padding: 4px; text-align: right;">5000</td><td style="padding: 4px; text-align: right;">14</td><td style="padding: 4px; text-align: right;">29025</td></tr>
<tr><td style="padding: 4px; text-align: center;">10</td><td style="padding: 4px;">MILLER</td><td style="padding: 4px; text-align: right;">1300</td><td style="padding: 4px; text-align: right;">14</td><td style="padding: 4px; text-align: right;">29025</td></tr>
<tr><td style="padding: 4px; text-align: center;">20</td><td style="padding: 4px;">ADAMS</td><td style="padding: 4px; text-align: right;">1100</td><td style="padding: 4px; text-align: right;">14</td><td style="padding: 4px; text-align: right;">29025</td></tr>
<tr><td style="padding: 4px; text-align: center;">20</td><td style="padding: 4px;">FORD</td><td style="padding: 4px; text-align: right;">3000</td><td style="padding: 4px; text-align: right;">14</td><td style="padding: 4px; text-align: right;">29025</td></tr>
<tr><td style="padding: 4px; text-align: center;">20</td><td style="padding: 4px;">JONES</td><td style="padding: 4px; text-align: right;">2975</td><td style="padding: 4px; text-align: right;">14</td><td style="padding: 4px; text-align: right;">29025</td></tr>
<tr><td style="padding: 4px; text-align: center;">20</td><td style="padding: 4px;">SCOTT</td><td style="padding: 4px; text-align: right;">3000</td><td style="padding: 4px; text-align: right;">14</td><td style="padding: 4px; text-align: right;">29025</td></tr>
<tr><td style="padding: 4px; text-align: center;">20</td><td style="padding: 4px;">SMITH</td><td style="padding: 4px; text-align: right;">800</td><td style="padding: 4px; text-align: right;">14</td><td style="padding: 4px; text-align: right;">29025</td></tr>
<tr><td style="padding: 4px; text-align: center;">30</td><td style="padding: 4px;">ALLEN</td><td style="padding: 4px; text-align: right;">1600</td><td style="padding: 4px; text-align: right;">14</td><td style="padding: 4px; text-align: right;">29025</td></tr>
<tr><td style="padding: 4px; text-align: center;">30</td><td style="padding: 4px;">BLAKE</td><td style="padding: 4px; text-align: right;">2850</td><td style="padding: 4px; text-align: right;">14</td><td style="padding: 4px; text-align: right;">29025</td></tr>
<tr><td style="padding: 4px; text-align: center;">30</td><td style="padding: 4px;">JAMES</td><td style="padding: 4px; text-align: right;">950</td><td style="padding: 4px; text-align: right;">14</td><td style="padding: 4px; text-align: right;">29025</td></tr>
<tr><td style="padding: 4px; text-align: center;">30</td><td style="padding: 4px;">MARTIN</td><td style="padding: 4px; text-align: right;">1250</td><td style="padding: 4px; text-align: right;">14</td><td style="padding: 4px; text-align: right;">29025</td></tr>
<tr><td style="padding: 4px; text-align: center;">30</td><td style="padding: 4px;">TURNER</td><td style="padding: 4px; text-align: right;">1500</td><td style="padding: 4px; text-align: right;">14</td><td style="padding: 4px; text-align: right;">29025</td></tr>
<tr><td style="padding: 4px; text-align: center;">30</td><td style="padding: 4px;">WARD</td><td style="padding: 4px; text-align: right;">1250</td><td style="padding: 4px; text-align: right;">14</td><td style="padding: 4px; text-align: right;">29025</td></tr>
</tbody>
</table>

<p style="padding: 10px; margin: 0; font-style: italic; font-size: 0.9em; border-top: 1px solid #ccc;">14 rows selected.</p>

</div>

<div style="position: absolute; bottom: -60px; right: 0; background: #003d5c; color: white; padding: 15px 20px; border-radius: 8px; max-width: 280px; font-size: 0.9em; box-shadow: 0 4px 6px rgba(0,0,0,0.2);">
<strong>Returns one result<br/>for each record</strong> in the dataset.<br/>No grouping
</div>

</div>

</div>

<div style="height: 80px;"></div>
<div style="height: 40px; border-bottom: 3px solid #003d5c; margin: 40px 0;"></div>

<!-- ========== SEITE 2 ========== -->

<div style="display: grid; grid-template-columns: 1fr 1fr 320px; gap: 20px; margin: 30px 0;">

<!-- LINKE SPALTE - Seite 2 -->
<div style="grid-column: 1 / 3; position: relative;">

<h3 style="color: #0099cc; margin-bottom: 10px;">With WHERE Clause...</h3>
<p style="color: #0099cc; font-weight: bold; margin-bottom: 20px;">•Which happens first?</p>

<div style="border: 2px solid #000; padding: 0; background: white; font-family: monospace;">
<div style="background: #f0f0f0; padding: 8px; border-bottom: 1px solid #bbb;">
<span style="color: #0066cc; font-weight: bold;">SELECT</span> deptno, ename, sal<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;, <span style="color: #0066cc; font-weight: bold;">COUNT</span> ( * ) <span style="color: #0066cc; font-weight: bold;">OVER</span> ()<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;, <span style="color: #0066cc; font-weight: bold;">SUM</span> ( sal ) <span style="color: #0066cc; font-weight: bold;">OVER</span> ()<br/>
<span style="color: #0066cc; font-weight: bold;">FROM</span> scott.emp<br/>
<span style="color: #0066cc; font-weight: bold;">WHERE</span> deptno = <span style="color: #009900;">30</span>;
</div>
<div style="padding: 12px;">
<strong>DEPTNO ENAME &nbsp;&nbsp;&nbsp; SAL COUNT(*)OVER() SUM(SAL)OVER()</strong><br/>
------- ----------- ---- -------------- --------------<br/>
30 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ALLEN &nbsp;&nbsp;&nbsp;&nbsp; 1600 &nbsp;&nbsp;&nbsp; 6 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 9450<br/>
30 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; BLAKE &nbsp;&nbsp;&nbsp;&nbsp; 2850 &nbsp;&nbsp;&nbsp; 6 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 9450<br/>
30 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; JAMES &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 950 &nbsp;&nbsp;&nbsp; 6 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 9450<br/>
30 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; MARTIN &nbsp;&nbsp;&nbsp; 1250 &nbsp;&nbsp;&nbsp; 6 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 9450<br/>
30 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; TURNER &nbsp;&nbsp;&nbsp; 1500 &nbsp;&nbsp;&nbsp; 6 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 9450<br/>
30 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; WARD &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 1250 &nbsp;&nbsp;&nbsp; 6 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 9450<br/>
<br/>
<em>6 rows selected.</em>
</div>
</div>

<!-- Callout Box - schwebt über der Query -->
<div style="position: absolute; top: 100px; right: -50px; background: #003d5c; color: white; padding: 15px 20px; border-radius: 8px; max-width: 320px; font-size: 0.9em; box-shadow: 0 4px 6px rgba(0,0,0,0.2); z-index: 10;">
<strong>Even with OVER() and empty parens,</strong> the function operates only on the records which meet the conditions of the WHERE clause
</div>

</div>

<!-- RECHTE SPALTE - Datentabelle -->
<div style="grid-column: 3;">

<div style="border: 2px solid #003d5c; background: white; overflow: hidden;">

<table style="width: 100%; border-collapse: collapse; font-family: monospace; font-size: 0.85em;">
<thead>
<tr style="background: #003d5c; color: white;">
<th style="padding: 6px; text-align: center;">Deptno</th>
<th style="padding: 6px; text-align: center;">Ename</th>
<th style="padding: 6px; text-align: center;">Sal</th>
</tr>
</thead>
<tbody>
<tr style="background: #e8e8e8;"><td style="padding: 4px; text-align: center;">10</td><td style="padding: 4px;">Clark</td><td style="padding: 4px; text-align: right;">2450</td></tr>
<tr style="background: #e8e8e8;"><td style="padding: 4px; text-align: center;">10</td><td style="padding: 4px;">King</td><td style="padding: 4px; text-align: right;">5000</td></tr>
<tr style="background: #e8e8e8;"><td style="padding: 4px; text-align: center;">10</td><td style="padding: 4px;">Miller</td><td style="padding: 4px; text-align: right;">1300</td></tr>
<tr style="background: #d8d8d8;"><td style="padding: 4px; text-align: center;">20</td><td style="padding: 4px;">Adams</td><td style="padding: 4px; text-align: right;">1100</td></tr>
<tr style="background: #d8d8d8;"><td style="padding: 4px; text-align: center;">20</td><td style="padding: 4px;">Ford</td><td style="padding: 4px; text-align: right;">3000</td></tr>
<tr style="background: #d8d8d8;"><td style="padding: 4px; text-align: center;">20</td><td style="padding: 4px;">Jones</td><td style="padding: 4px; text-align: right;">2975</td></tr>
<tr style="background: #d8d8d8;"><td style="padding: 4px; text-align: center;">20</td><td style="padding: 4px;">Scott</td><td style="padding: 4px; text-align: right;">3000</td></tr>
<tr style="background: #d8d8d8;"><td style="padding: 4px; text-align: center;">20</td><td style="padding: 4px;">Smith</td><td style="padding: 4px; text-align: right;">800</td></tr>
<tr style="background: #c8c8f8;"><td style="padding: 4px; text-align: center;">30</td><td style="padding: 4px;">Allen</td><td style="padding: 4px; text-align: right;">1600</td></tr>
<tr style="background: #c8c8f8;"><td style="padding: 4px; text-align: center;">30</td><td style="padding: 4px;">Blake</td><td style="padding: 4px; text-align: right;">2850</td></tr>
<tr style="background: #c8c8f8;"><td style="padding: 4px; text-align: center;">30</td><td style="padding: 4px;">James</td><td style="padding: 4px; text-align: right;">950</td></tr>
<tr style="background: #c8c8f8;"><td style="padding: 4px; text-align: center;">30</td><td style="padding: 4px;">Martin</td><td style="padding: 4px; text-align: right;">1250</td></tr>
<tr style="background: #c8c8f8;"><td style="padding: 4px; text-align: center;">30</td><td style="padding: 4px;">Turner</td><td style="padding: 4px; text-align: right;">1500</td></tr>
<tr style="background: #c8c8f8;"><td style="padding: 4px; text-align: center;">30</td><td style="padding: 4px;">Ward</td><td style="padding: 4px; text-align: right;">1250</td></tr>
</tbody>
</table>

</div>

</div>

</div>

---

## DISTINCT vs GROUP BY

Wird eine analytische Funktion (**COUNT(\*) OVER () AS empcnt**) in Verbindung mit `SELECT DISTINCT deptno` verwendet, bleibt die Zeilenzahl aller Abteilungen im *empcnt* gleich (14, da `OVER ()` die Gesamtanzahl der Zeilen vor der `DISTINCT`-Filterung zählt).

Wird `GROUP BY` verwendet, zählt `COUNT(*)` die Zeilen *pro Gruppe*.

### Beispiel 1: DISTINCT mit Analytic Function

```sql
SELECT DISTINCT deptno,
       COUNT(*) OVER () AS empcnt
FROM scott.emp;
```

| DEPTNO | EMPCNT |
|:---|:---|
| 10 | 14 |
| 20 | 14 |
| 30 | 14 |

*3 rows selected.*

### Beispiel 2: GROUP BY (Traditionelles Aggregat)

```sql
SELECT deptno,
       COUNT(deptno) AS empcnt -- COUNT(*) is also possible, but COUNT(deptno) is semantically closer to the old output
FROM scott.emp
GROUP BY deptno;
```

| DEPTNO | EMPCNT |
|:---|:---|
| 10 | 3 |
| 20 | 5 |
| 30 | 6 |

*3 rows selected.* (Hinweis: Die Spalte `EMPCNT` im Beispiel 26 aus der Quelle zeigt 3 für alle Zeilen, dies ist wahrscheinlich ein Fehler in der Quell-PDF, da `COUNT(*)` in einer `GROUP BY`-Abfrage die Anzahl der Zeilen in jeder Gruppe zurückgeben sollte: 3, 5, 6).

### Reihenfolge der Operationen (Order of Operations)

1. Table Joins
2. WHERE clause filters
3. GROUP BY
4. Analytic Functions
5. DISTINCT
6. Ordering

---

## The Analytic Clause

Das ist der Inhalt innerhalb der Klammern (**OVER (...)**).

### Komponenten der Analytic Clause

Expressions, die der Funktion sagen, dass sie anders rechnen soll.

Drei mögliche Komponenten, die in dieser Reihenfolge stehen müssen:

1. **Partition**
2. **Order**
3. **Windowing**

Einige oder alle sind optional, abhängig von der Funktion.

---

## PARTITION BY

Berechnet die analytische Funktion auf einer **Untermenge** der Datensätze, ähnlich einem *GROUP BY* ohne die Anzahl der Zeilen zu reduzieren.

```sql
SELECT deptno, ename, sal, job
, COUNT(*) OVER (PARTITION BY job) jobcount -- Zählt Mitarbeiter pro Job
, SUM(sal) OVER (PARTITION BY deptno) deptsum -- Summiert Gehälter pro Abteilung
FROM scott.emp;
```

| DEPTNO | ENAME | SAL | JOB | JOBCOUNT | DEPTSUM |
|:---|:---|:---|:---|:---|:---|
| 10 | CLARK | 2450 | MANAGER | 3 | 8750 |
| 10 | KING | 5000 | PRESIDENT | 1 | 8750 |
| 10 | MILLER | 1300 | CLERK | 4 | 8750 |
| 20 | ADAMS | 1100 | CLERK | 4 | 10875 |
| 20 | FORD | 3000 | ANALYST | 2 | 10875 |
| 20 | JONES | 2975 | MANAGER | 3 | 10875 |
| 20 | SCOTT | 3000 | ANALYST | 2 | 10875 |
| 20 | SMITH | 800 | CLERK | 4 | 10875 |
| 30 | ALLEN | 1600 | SALESMAN | 4 | 9400 |
| 30 | BLAKE | 2850 | MANAGER | 3 | 9400 |
| 30 | JAMES | 950 | CLERK | 4 | 9400 |
| 30 | MARTIN | 1250 | SALESMAN | 4 | 9400 |
| 30 | TURNER | 1500 | SALESMAN | 4 | 9400 |
| 30 | WARD | 1250 | SALESMAN | 4 | 9400 |

*14 rows selected.*

### Vergleich: Korrelierte Skalare Subqueries

Die gleiche Logik kann mit korrelierten skalaren Subqueries erreicht werden, aber analytische Funktionen sind oft effizienter (Analytic SQL: ONE PASS vs. Traditional aggregate syntax: Three passes over the table, according to the `EXPLAIN PLAN` output).

```sql
SELECT deptno, ename, sal, job
, (SELECT COUNT(*) FROM scott.emp WHERE job = e.job) jobcount
, (SELECT SUM(sal) FROM scott.emp WHERE deptno = e.deptno) deptsum
FROM scott.emp e;
```

| DEPTNO | ENAME | SAL | JOB | JOBCOUNT | DEPTSUM |
|:---|:---|:---|:---|:---|:---|
| 10 | CLARK | 2450 | MANAGER | 3 | 8750 |
| ... | ... | ... | ... | ... | ... |

---

*(Die folgenden Abschnitte über **LAG/LEAD**, **RANKING FUNCTIONS** und **WINDOWING** wurden ebenfalls in das Markdown konvertiert, um die Vollständigkeit zu gewährleisten.)*

---

## ZWEI NEUE FUNKTIONEN: LAG und LEAD

* **LAG** gibt den Wert eines Feldes aus einem Datensatz zurück, der **vor** dem aktuellen Datensatz liegt.
* **LEAD** gibt den Wert eines Feldes aus einem Datensatz zurück, der **nach** dem aktuellen Datensatz liegt.
* **Syntax:** `LAG(field_name, num_recs)` OVER (ORDER BY ...)
* `ORDER BY` ist erforderlich.
* Dies sind ausschließlich analytische Funktionen.

### LAG Demonstration

```sql
SELECT deptno, ename, hiredate
, LAG(ename) OVER (ORDER BY hiredate) prior_hire -- Vorgänger basierend auf Einstellungsdatum
FROM scott.emp
ORDER BY deptno, ename;
```

| DEPTNO | ENAME | HIREDATE | PRIOR\_HIRE |
|:---|:---|:---|:---|
| 10 | CLARK | 09-JUN-81 | BLAKE |
| 10 | KING | 17-NOV-81 | MARTIN |
| 10 | MILLER | 23-JAN-82 | FORD |
| 20 | ADAMS | 23-MAY-87 | SCOTT |
| 20 | FORD | 03-DEC-81 | JAMES |
| 20 | JONES | 02-APR-81 | WARD |
| 20 | SCOTT | 09-DEC-82 | MILLER |
| 20 | SMITH | 17-DEC-80 | (NULL) |
| 30 | ALLEN | 20-FEB-81 | SMITH |
| 30 | BLAKE | 01-MAY-81 | JONES |
| 30 | JAMES | 03-DEC-81 | KING |
| 30 | MARTIN | 28-SEP-81 | TURNER |
| 30 | TURNER | 08-SEP-81 | CLARK |
| 30 | WARD | 22-FEB-81 | ALLEN |

### LAG/LEAD mit Versatz (Offset)

```sql
SELECT deptno, ename, sal
, LAG(ename) OVER (ORDER BY ename) f1        -- 1 record behind
, LAG(ename, 2) OVER (ORDER BY ename) f2     -- 2 records behind
, LEAD(ename) OVER (ORDER BY ename DESC) f3  -- 1 record ahead (reverse order)
, LAG(sal) OVER (ORDER BY ename) f4          -- LAG on SAL
FROM scott.emp
ORDER BY deptno, ename;
```

| DEPTNO | ENAME | SAL | F1 | F2 | F3 | F4 |
|:---|:---|:---|:---|:---|:---|:---|
| 10 | CLARK | 2450 | BLAKE | ALLEN | BLAKE | 2850 |
| 10 | KING | 5000 | JONES | JAMES | JONES | 2975 |
| 10 | MILLER | 1300 | MARTIN | KING | MARTIN | 1250 |
| 20 | ADAMS | 1100 | (NULL) | (NULL) | WARD | (NULL) |
| 20 | FORD | 3000 | CLARK | BLAKE | CLARK | 2450 |
| 20 | JONES | 2975 | JAMES | FORD | JAMES | 950 |
| 20 | SCOTT | 3000 | MILLER | MARTIN | MILLER | 1300 |
| 20 | SMITH | 800 | SCOTT | MILLER | SCOTT | 3000 |
| 30 | ALLEN | 1600 | ADAMS | (NULL) | ADAMS | 1100 |
| 30 | BLAKE | 2850 | ALLEN | ADAMS | ALLEN | 1600 |
| 30 | JAMES | 950 | FORD | CLARK | FORD | 3000 |
| 30 | MARTIN | 1250 | KING | JONES | KING | 5000 |
| 30 | TURNER | 1500 | SMITH | SCOTT | SMITH | 800 |
| 30 | WARD | 1250 | TURNER | SMITH | TURNER | 1500 |

### ORDER BY WITH PARTITION BY

`PARTITION BY` teilt die Daten, und `LAG` wird innerhalb jeder Abteilung (Partition) durchgeführt.

```sql
SELECT deptno, ename, sal
, LAG(ename) OVER (ORDER BY ename) f1                       -- LAG über die gesamte Tabelle (alphabetisch)
, LAG(ename) OVER (PARTITION BY deptno ORDER BY ename) f2   -- LAG nur innerhalb der Abteilung (alphabetisch)
, LAG(ename) OVER (PARTITION BY deptno ORDER BY sal DESC) f3 -- LAG nur innerhalb der Abteilung (nach Gehalt absteigend)
FROM scott.emp
ORDER BY deptno, ename;
```

| DEPTNO | ENAME | SAL | F1 | F2 | F3 |
|:---|:---|:---|:---|:---|:---|
| 10 | CLARK | 2450 | BLAKE | (NULL) | KING |
| 10 | KING | 5000 | JONES | CLARK | CLARK |
| 10 | MILLER | 1300 | MARTIN | KING | CLARK |
| 20 | ADAMS | 1100 | (NULL) | (NULL) | SCOTT |
| 20 | FORD | 3000 | CLARK | ADAMS | SCOTT |
| 20 | JONES | 2975 | JAMES | FORD | FORD |
| 20 | SCOTT | 3000 | MILLER | JONES | ADAMS |
| 20 | SMITH | 800 | SCOTT | SCOTT | ADAMS |
| 30 | ALLEN | 1600 | ADAMS | (NULL) | BLAKE |
| 30 | BLAKE | 2850 | ALLEN | ALLEN | ALLEN |
| 30 | JAMES | 950 | FORD | BLAKE | WARD |
| 30 | MARTIN | 1250 | KING | JAMES | TURNER |
| 30 | TURNER | 1500 | SMITH | MARTIN | ALLEN |
| 30 | WARD | 1250 | TURNER | TURNER | MARTIN |

---

## DREI WEITERE FUNKTIONEN: Ranking Functions

* **RANK()**: Weist bei Gleichheit den gleichen Rang zu und überspringt die nächsten Ränge.
* **DENSE\_RANK()**: Weist bei Gleichheit den gleichen Rang zu, überspringt aber keine Ränge.
* **ROW\_NUMBER()**: Weist jedem Datensatz eine eindeutige, sequentielle Nummer zu.
* **Usage**: `RANK() OVER (ORDER BY field_name)`

### Beispiel 1: Ranking ohne Gleichheit (Tie)

Wenn es keine Gleichheit gibt, liefern alle drei Funktionen dieselben Werte (ROW\_NUMBER liefert immer eine eindeutige Nummer).

```sql
SELECT deptno, ename, sal
, RANK() OVER (ORDER BY ename) f1
, DENSE_RANK() OVER (ORDER BY ename) f2
, ROW_NUMBER() OVER (ORDER BY ename) f3
FROM scott.emp
ORDER BY deptno, sal;
```

| DEPTNO | ENAME | SAL | F1 | F2 | F3 |
|:---|:---|:---|:---|:---|:---|
| 10 | MILLER | 1300 | 10 | 10 | 10 |
| 10 | CLARK | 2450 | 4 | 4 | 4 |
| 10 | KING | 5000 | 8 | 8 | 8 |
| ... | ... | ... | ... | ... | ... |

### Beispiel 2: Ranking mit Gleichheit (Ties)

Hier wird nach Gehalt (`sal`) sortiert, das Gleichheiten aufweist.

```sql
SELECT deptno, ename, sal
, RANK() OVER (ORDER BY sal) f1
, DENSE_RANK() OVER (ORDER BY sal) f2
, ROW_NUMBER() OVER (ORDER BY sal) f3
FROM scott.emp
ORDER BY deptno, sal;
```

| DEPTNO | ENAME | SAL | F1 | F2 | F3 | F4 |
|:---|:---|:---|:---|:---|:---|:---|
| 10 | MILLER | 1300 | 6 | 5 | 6 |
| 10 | CLARK | 2450 | 9 | 8 | 9 |
| 10 | KING | 5000 | 14 | 12 | 14 |
| 20 | SMITH | 800 | 1 | 1 | 1 |
| 20 | ADAMS | 1100 | 3 | 3 | 3 |
| 20 | JONES | 2975 | 11 | 10 | 11 |
| 20 | FORD | 3000 | 12 | 11 | 13 |
| 20 | SCOTT | 3000 | 12 | 11 | 12 |
| 30 | JAMES | 950 | 2 | 2 | 2 |
| 30 | WARD | 1250 | 4 | 4 | 4 |
| 30 | MARTIN | 1250 | 4 | 4 | 5 |
| 30 | TURNER | 1500 | 7 | 6 | 7 |
| 30 | ALLEN | 1600 | 8 | 7 | 8 |
| 30 | BLAKE | 2850 | 10 | 9 | 10 |

---

## ORDER BY CAVEAT \#2 (Wichtiger Hinweis)

Bei vielen Funktionen (**SUM**, **COUNT**, **MAX**, **MIN**, **LAST\_VALUE**) ändert die Verwendung von `ORDER BY` die **Windowing Clause** (den Datenbereich).

**Standardverhalten bei ORDER BY:** Die Funktion summiert (oder zählt/findet Min/Max) vom **Beginn der Partition** bis zum **aktuellen Datensatz** (einschließlich).

### Beispiel: Running Totals (MTD - Month To Date)

```sql
SELECT deptno, ename, sal
, SUM(sal) OVER (ORDER BY ename) s
, COUNT(*) OVER (ORDER BY ename) c
, MIN(sal) OVER (ORDER BY ename) mn
, MAX(sal) OVER (ORDER BY ename) mx
FROM scott.emp
WHERE deptno = 10;
```

| DEPTNO | ENAME | SAL | S | C | MN | MX |
|:---|:---|:---|:---|:---|:---|:---|
| 10 | CLARK | 2450 | 2450 | 1 | 2450 | 2450 |
| 10 | KING | 5000 | 7450 | 2 | 2450 | 5000 |
| 10 | MILLER | 1300 | 8750 | 3 | 1300 | 5000 |

*7450 = 2450 + 5000*
*8750 = 7450 + 1300*

Dies ist die Kurzform für: `SUM(sal) OVER (ORDER BY ename ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`.

---

## WINDOWING CLAUSE

Die `WINDOWING` Clause wählt eine kleinere Untermenge als die Partition aus, basierend auf einer Anzahl von Datensätzen oder einem Zeitraum.

### Demonstration des Standard-Windowing

| Funktion | Analytic Clause | Implizite Windowing Clause |
|:---|:---|:---|
| Aggregat-Funktion ohne ORDER BY | `SUM(sal) OVER ()` | **Implizit**: Die gesamte Partition (oder die gesamte Tabelle, wenn keine Partition vorhanden ist). |
| Aggregat-Funktion mit ORDER BY | `SUM(sal) OVER (ORDER BY ename)` | **Implizit**: `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` |

```sql
SELECT deptno, ename, sal
, SUM(sal) OVER () sum1                                                                   -- Unbounded (Whole partition)
, SUM(sal) OVER (ORDER BY ename) sum2                                                     -- Default Running Total
, SUM(sal) OVER (ORDER BY ename ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) sum3 -- Explicit Unbounded
, SUM(sal) OVER (ORDER BY ename ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) sum4  -- Explicit Running Total
FROM scott.emp
WHERE deptno = 10;
```

| DEPTNO | ENAME | SAL | SUM1 | SUM2 | SUM3 | SUM4 |
|:---|:---|:---|:---|:---|:---|:---|
| 10 | CLARK | 2450 | 8750 | 2450 | 8750 | 2450 |
| 10 | KING | 5000 | 8750 | 7450 | 8750 | 7450 |
| 10 | MILLER | 1300 | 8750 | 8750 | 8750 | 8750 |

*SUM1 ist gleich SUM3. SUM2 ist gleich SUM4.*

### WINDOWING: ROWS (Basierend auf Datensätzen)

Beschränkt das Fenster durch eine Anzahl von Datensätzen vor/nach dem aktuellen Datensatz.

```sql
SELECT deptno, ename, sal
, SUM(sal) OVER (ORDER BY ename ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) sum1 -- Gesamttabelle, aktueller + 1 davor + 1 danach
, SUM(sal) OVER (PARTITION BY deptno ORDER BY ename ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) sum2 -- Innerhalb der Abteilung, aktueller + 1 davor + 1 danach
FROM scott.emp;
```

| DEPTNO | ENAME | SAL | SUM1 | SUM2 |
|:---|:---|:---|:---|:---|
| 10 | CLARK | 2450 | 8300 | 7450 |
| 10 | KING | 5000 | 9225 | 8750 |
| 10 | MILLER | 1300 | 5550 | 6300 |
| 20 | ADAMS | 1100 | 2700 | 4100 |
| ... | ... | ... | ... | ... |

*Beispiel SUM2 (10 CLARK): 2450 + 5000 = 7450 (1 davor (NULL, da erster) + 1 danach (KING))*
*Beispiel SUM2 (10 KING): 2450 + 5000 + 1300 = 8750 (1 davor (CLARK) + 1 danach (MILLER))*

### WINDOWING CLAUSE COMPARISON (ROWS vs. RANGE)

| | ROWS | RANGE |
|:---|:---|:---|
| **Restriktion** | Durch Anzahl der Datensätze | Durch einen Zeitraum oder einen Wert |
| **Referenziert** | Basiert auf `ORDER BY` | Referenziert Feld, das in `ORDER BY` verwendet wird |
| **Beispiel** | `ROWS BETWEEN 10 PRECEDING AND 10 FOLLOWING` | `RANGE BETWEEN INTERVAL '10' DAY PRECEDING AND INTERVAL '10' DAY FOLLOWING` |

### Beispiel: RANGE (Basierend auf Gehaltswert)

```sql
SELECT ename, sal
, COUNT(*) OVER (ORDER BY sal RANGE BETWEEN 200 PRECEDING AND 200 FOLLOWING) emps_200_sal
FROM scott.emp;
```

*Zählt alle Mitarbeiter, deren Gehalt maximal 200 weniger oder 200 mehr als das aktuelle Gehalt beträgt.*

---
