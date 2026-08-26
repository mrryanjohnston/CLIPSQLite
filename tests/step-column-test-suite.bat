; ============================================================
; STEPPING AND READING COLUMNS
;
; sqlite-step returns SQLITE_ROW or SQLITE_DONE as symbols rather than as the
; integers SQLite uses, so a caller compares against a name; anything else is
; a refusal.  The column readers are only meaningful between a SQLITE_ROW and
; the next step, which is what separates sqlite-column-count from
; sqlite-data-count -- one describes the statement, the other the row that is
; currently under the cursor.
; ============================================================

(defglobal
  ?*sc-db* = FALSE
  ?*sc-st* = FALSE
  ?*sc-r*  = nothing
  ?*sc-n*  = 0)

(bind ?*sc-db* (sqlite-open :memory:))
(expect "the connection opened" TRUE (pointerp ?*sc-db*))

(bind ?*sc-st* (sqlite-prepare ?*sc-db*
  "CREATE TABLE t (i INTEGER, f REAL, t TEXT, b BLOB, n INTEGER);"))
(expect "the table is created" SQLITE_DONE (sqlite-step ?*sc-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*sc-st*))

(bind ?*sc-st* (sqlite-prepare ?*sc-db*
  "INSERT INTO t VALUES (7, 2.5, 'text', x'414243', NULL);"))
(expect "a row of every storage class goes in" SQLITE_DONE (sqlite-step ?*sc-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*sc-st*))

; ------------------------------------------------------------
; column-count describes the statement, data-count describes the row
; ------------------------------------------------------------

(bind ?*sc-st* (sqlite-prepare ?*sc-db* "SELECT i, f, t, b, n FROM t;"))
(expect "the query prepared" TRUE (pointerp ?*sc-st*))

(expect "the statement has five columns before it is stepped"
        5 (sqlite-column-count ?*sc-st*))
(expect "but there is no row under the cursor yet"
        0 (sqlite-data-count ?*sc-st*))

(expect "stepping produces a row" SQLITE_ROW (sqlite-step ?*sc-st*))
(expect "which has all five values" 5 (sqlite-data-count ?*sc-st*))
(expect "and the statement still has five columns" 5 (sqlite-column-count ?*sc-st*))

; ------------------------------------------------------------
; column names
; ------------------------------------------------------------

(expect "column 0 is named" "i" (sqlite-column-name ?*sc-st* 0))
(expect "column 4 is named" "n" (sqlite-column-name ?*sc-st* 4))
(bind ?*sc-r* (sqlite-column-name ?*sc-st* 5))
(expect "one past the last column has no name" FALSE ?*sc-r*)
(bind ?*sc-r* (sqlite-column-name ?*sc-st* -1))
(expect "and neither does a negative index" FALSE ?*sc-r*)

; ------------------------------------------------------------
; column types
;
; The type is the storage class of the value in this row, not the declared
; type of the table's column -- which is why the NULL in a column declared
; INTEGER reads as SQLITE_NULL.
; ------------------------------------------------------------

(expect "the integer column" SQLITE_INTEGER (sqlite-column-type ?*sc-st* 0))
(expect "the real column" SQLITE_FLOAT (sqlite-column-type ?*sc-st* 1))
(expect "the text column" SQLITE_TEXT (sqlite-column-type ?*sc-st* 2))
(expect "the blob column" SQLITE_BLOB (sqlite-column-type ?*sc-st* 3))
(expect "the NULL in an INTEGER column is a NULL, not an integer"
        SQLITE_NULL (sqlite-column-type ?*sc-st* 4))

; an index outside the row is not an error to SQLite: it is a NULL
(expect "a column index past the end reads as NULL"
        SQLITE_NULL (sqlite-column-type ?*sc-st* 99))

; ------------------------------------------------------------
; column values
; ------------------------------------------------------------

(expect "an integer comes back as an integer" 7 (sqlite-column ?*sc-st* 0))
(expect "with CLIPS's integer type" INTEGER (type (sqlite-column ?*sc-st* 0)))

(expect "a real comes back as a float" 2.5 (sqlite-column ?*sc-st* 1))
(expect "with CLIPS's float type" FLOAT (type (sqlite-column ?*sc-st* 1)))

(expect "text comes back as a string" "text" (sqlite-column ?*sc-st* 2))
(expect "with CLIPS's string type" STRING (type (sqlite-column ?*sc-st* 2)))

; NULL is the symbol nil, which is also what sqlite-bind takes for a NULL --
; the two wrappers agree on one spelling so a value can make the round trip
(expect "a NULL comes back as the symbol nil" nil (sqlite-column ?*sc-st* 4))
(expect "as a symbol, not the string \"nil\"" SYMBOL (type (sqlite-column ?*sc-st* 4)))

(expect "an index past the end reads as nil too" nil (sqlite-column ?*sc-st* 99))

; ------------------------------------------------------------
; blobs are read as text, which is only lossless without a zero byte
;
; A blob is handed to CLIPS as a NUL-terminated string, so it survives the
; trip exactly when it contains no zero -- and a blob that does contain one is
; silently cut at it.  That is a real limit on what this binding can carry
; back, and it is asserted rather than left to be discovered.
; ------------------------------------------------------------

(expect "a blob of printable bytes survives as a string"
        "ABC" (sqlite-column ?*sc-st* 3))
(expect "and keeps its length" 3 (str-length (sqlite-column ?*sc-st* 3)))

(expect "finalizing it" TRUE (sqlite-finalize ?*sc-st*))

(bind ?*sc-st* (sqlite-prepare ?*sc-db* "SELECT x'41004243' AS cut, zeroblob(4) AS empty;"))
(expect "stepping" SQLITE_ROW (sqlite-step ?*sc-st*))
(expect "a blob is still typed as a blob" SQLITE_BLOB (sqlite-column-type ?*sc-st* 0))
(expect "but an embedded zero byte cuts the value short"
        1 (str-length (sqlite-column ?*sc-st* 0)))
(expect "and a blob that starts with one comes back empty"
        0 (str-length (sqlite-column ?*sc-st* 1)))
(expect "finalizing it" TRUE (sqlite-finalize ?*sc-st*))

; ------------------------------------------------------------
; where a column came from
;
; These three answer only for a column that is a table column.  An expression
; has no origin, and asking for one is a refusal rather than an empty string.
; ------------------------------------------------------------

(bind ?*sc-st* (sqlite-prepare ?*sc-db* "SELECT i AS renamed, i + 1 AS computed FROM t;"))
(expect "the query prepared" TRUE (pointerp ?*sc-st*))

(expect "the column's database" "main" (sqlite-column-database-name ?*sc-st* 0))
(expect "the column's table" "t" (sqlite-column-table-name ?*sc-st* 0))
(expect "the column's name in that table" "i" (sqlite-column-origin-name ?*sc-st* 0))
(expect "which is not the name the query gave it"
        "renamed" (sqlite-column-name ?*sc-st* 0))

(bind ?*sc-r* (sqlite-column-database-name ?*sc-st* 1))
(expect "an expression has no database" FALSE ?*sc-r*)
(bind ?*sc-r* (sqlite-column-table-name ?*sc-st* 1))
(expect "no table" FALSE ?*sc-r*)
(bind ?*sc-r* (sqlite-column-origin-name ?*sc-st* 1))
(expect "and no origin" FALSE ?*sc-r*)
(expect "though the query still named it" "computed" (sqlite-column-name ?*sc-st* 1))

(bind ?*sc-r* (sqlite-column-table-name ?*sc-st* 99))
(expect "and an index past the end has none of the three" FALSE ?*sc-r*)

(expect "finalizing it" TRUE (sqlite-finalize ?*sc-st*))

; ------------------------------------------------------------
; walking a result
;
; The loop a caller actually writes: step until it stops answering
; SQLITE_ROW.  Afterwards the cursor is past the end, so data-count drops back
; to zero while column-count keeps describing the statement.
; ------------------------------------------------------------

(bind ?*sc-st* (sqlite-prepare ?*sc-db*
  "SELECT value FROM (SELECT 1 AS value UNION SELECT 2 UNION SELECT 3) ORDER BY value;"))
(bind ?*sc-n* 0)
(while (eq SQLITE_ROW (sqlite-step ?*sc-st*)) do
  (bind ?*sc-n* (+ ?*sc-n* (sqlite-column ?*sc-st* 0))))
(expect "the walk saw every row" 6 ?*sc-n*)
(expect "the cursor is past the end" 0 (sqlite-data-count ?*sc-st*))
(expect "though the statement still has its column" 1 (sqlite-column-count ?*sc-st*))

; stepping again after SQLITE_DONE restarts the statement rather than failing,
; which is sqlite3_step's documented behaviour for a v2-prepared statement
(expect "resetting it" TRUE (sqlite-reset ?*sc-st*))
(expect "and the first row comes round again" SQLITE_ROW (sqlite-step ?*sc-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*sc-st*))

; a statement that produces no rows at all
(bind ?*sc-st* (sqlite-prepare ?*sc-db* "SELECT i FROM t WHERE i = 999;"))
(expect "an empty result is done at once" SQLITE_DONE (sqlite-step ?*sc-st*))
(expect "with no row under the cursor" 0 (sqlite-data-count ?*sc-st*))
(expect "but the statement still has a column" 1 (sqlite-column-count ?*sc-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*sc-st*))

; a statement that produces no columns at all
(bind ?*sc-st* (sqlite-prepare ?*sc-db* "DELETE FROM t WHERE i = 999;"))
(expect "a DELETE has no columns" 0 (sqlite-column-count ?*sc-st*))
(expect "and is done at once" SQLITE_DONE (sqlite-step ?*sc-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*sc-st*))

(expect "closing the connection" TRUE (sqlite-close ?*sc-db*))
