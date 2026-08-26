; ============================================================
; CONNECTION-LEVEL STATE
;
; Everything here takes a connection and asks it about itself: which databases
; are attached, where they live, whether they are writable, how many rows the
; last statement touched.  The counters are the interesting half -- they are
; per-connection and change underneath the caller, so each one is read before
; and after the statement that is supposed to move it.
; ============================================================

(defglobal
  ?*cn-db*  = FALSE
  ?*cn-st*  = FALSE
  ?*cn-r*   = nothing
  ?*cn-tot* = 0)

(bind ?*cn-db* (sqlite-open "tests/tmp/connection.db"))
(expect "the connection opened" TRUE (pointerp ?*cn-db*))

; ------------------------------------------------------------
; which databases this connection has
;
; Every connection starts with two: "main" at index 0 and "temp" at index 1.
; ------------------------------------------------------------

(expect "database 0 is main" "main" (sqlite-db-name ?*cn-db* 0))
(expect "database 1 is temp" "temp" (sqlite-db-name ?*cn-db* 1))
(expect "there is no database 2 yet" FALSE (sqlite-db-name ?*cn-db* 2))
(expect "and no database at a wild index" FALSE (sqlite-db-name ?*cn-db* 9999))
(expect "a negative index is out of range too" FALSE (sqlite-db-name ?*cn-db* -1))

(expect "main exists" TRUE (sqlite-db-exists ?*cn-db* main))
(expect "a name nothing is attached under does not" FALSE (sqlite-db-exists ?*cn-db* aux))

; temp is the one name the two reads disagree about, and they are both right:
; index 1 is reserved for it from the start, but the database itself is not
; created until something is put in it, and until then it does not exist.
(expect "temp is named before it exists" "temp" (sqlite-db-name ?*cn-db* 1))
(expect "and does not exist yet" FALSE (sqlite-db-exists ?*cn-db* temp))

(bind ?*cn-st* (sqlite-prepare ?*cn-db* "CREATE TEMP TABLE tt (x);"))
(expect "creating a temp table" SQLITE_DONE (sqlite-step ?*cn-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*cn-st*))
(expect "brings the temp database into existence" TRUE (sqlite-db-exists ?*cn-db* temp))

; ATTACH adds a third, which every one of these reads should then see
(bind ?*cn-st* (sqlite-prepare ?*cn-db* "ATTACH DATABASE ':memory:' AS aux;"))
(expect "the ATTACH prepared" TRUE (pointerp ?*cn-st*))
(expect "and ran" SQLITE_DONE (sqlite-step ?*cn-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*cn-st*))

(expect "the attached database took index 2" "aux" (sqlite-db-name ?*cn-db* 2))
(expect "and exists under its name" TRUE (sqlite-db-exists ?*cn-db* aux))
(expect "an in-memory attachment has no filename" FALSE (sqlite-db-filename ?*cn-db* aux))

; ------------------------------------------------------------
; filenames
;
; sqlite3_db_filename answers an empty string for a database with no file,
; which the wrapper reports as FALSE rather than as "".
; ------------------------------------------------------------

(expect-true "main names the file it was opened on"
             (neq FALSE (str-index "connection.db" (sqlite-db-filename ?*cn-db* main))))
(expect "temp has no file until it is written to" FALSE (sqlite-db-filename ?*cn-db* temp))
(expect "a database that is not attached has no filename" FALSE (sqlite-db-filename ?*cn-db* nope))

; ------------------------------------------------------------
; readonly
;
; sqlite3_db_readonly answers -1 for a name nothing is attached under, which
; the wrapper flattens to FALSE -- the same answer a writable database gives.
; sqlite-db-exists is how the two are told apart, which is the reason it is a
; separate wrapper over the same call.
; ------------------------------------------------------------

(expect "main is writable" FALSE (sqlite-db-readonly ?*cn-db* main))
(expect "an unattached name also answers FALSE" FALSE (sqlite-db-readonly ?*cn-db* nope))
(expect "but only one of the two exists" TRUE (sqlite-db-exists ?*cn-db* main))
(expect "and the other does not" FALSE (sqlite-db-exists ?*cn-db* nope))

; ------------------------------------------------------------
; row counters
; ------------------------------------------------------------

(bind ?*cn-st* (sqlite-prepare ?*cn-db* "CREATE TABLE t (a INTEGER PRIMARY KEY, b TEXT);"))
(expect "the CREATE ran" SQLITE_DONE (sqlite-step ?*cn-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*cn-st*))

(bind ?*cn-tot* (sqlite-total-changes ?*cn-db*))

(bind ?*cn-st* (sqlite-prepare ?*cn-db* "INSERT INTO t (b) VALUES ('one'), ('two'), ('three');"))
(expect "the INSERT ran" SQLITE_DONE (sqlite-step ?*cn-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*cn-st*))

(expect "changes counts the rows the last statement touched" 3 (sqlite-changes ?*cn-db*))
(expect "total-changes counts them against the connection's lifetime"
        (+ ?*cn-tot* 3) (sqlite-total-changes ?*cn-db*))
(expect "last-insert-rowid is the last of the three" 3 (sqlite-last-insert-rowid ?*cn-db*))

; a SELECT touches no rows, so changes keeps its previous answer
(bind ?*cn-st* (sqlite-prepare ?*cn-db* "SELECT count(*) FROM t;"))
(expect "the SELECT has a row" SQLITE_ROW (sqlite-step ?*cn-st*))
(expect "which counts the three inserted" 3 (sqlite-column ?*cn-st* 0))
(expect "finalizing it" TRUE (sqlite-finalize ?*cn-st*))
(expect "a SELECT does not move the change counter" 3 (sqlite-changes ?*cn-db*))

(bind ?*cn-st* (sqlite-prepare ?*cn-db* "DELETE FROM t WHERE b = 'two';"))
(expect "the DELETE ran" SQLITE_DONE (sqlite-step ?*cn-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*cn-st*))
(expect "and removed one row" 1 (sqlite-changes ?*cn-db*))
(expect "total-changes counts deletions too"
        (+ ?*cn-tot* 4) (sqlite-total-changes ?*cn-db*))
(expect "last-insert-rowid is unchanged by a delete" 3 (sqlite-last-insert-rowid ?*cn-db*))

; ------------------------------------------------------------
; errmsg
;
; The message belongs to the connection, not to the statement, so it is read
; after the call that failed and stays readable until the next one.
; ------------------------------------------------------------

(expect "a connection that has done nothing wrong says so"
        "not an error" (sqlite-errmsg ?*cn-db*))

(bind ?*cn-r* (sqlite-prepare ?*cn-db* "SELECT * FROM no_such_table;"))
(expect "preparing against a missing table is refused" FALSE ?*cn-r*)
(expect "and the connection says why" "no such table: no_such_table"
        (sqlite-errmsg ?*cn-db*))

(bind ?*cn-r* (sqlite-prepare ?*cn-db* "THIS IS NOT SQL"))
(expect "so is a statement that does not parse" FALSE ?*cn-r*)
(expect-true "and that message is a syntax error"
             (neq FALSE (str-index "syntax error" (sqlite-errmsg ?*cn-db*))))

; ------------------------------------------------------------
; busy timeout
;
; Nothing here contends for the file, so what is checked is that the wrapper
; accepts the values SQLite accepts -- including the zero and the negative
; that both mean "do not wait".
; ------------------------------------------------------------

(expect "a timeout is set" TRUE (sqlite-busy-timeout ?*cn-db* 250))
(expect "zero clears it" TRUE (sqlite-busy-timeout ?*cn-db* 0))
(expect "a negative timeout is accepted" TRUE (sqlite-busy-timeout ?*cn-db* -1))

; ------------------------------------------------------------
; sleep
;
; sqlite3_sleep returns the milliseconds it actually slept, which the platform
; may round up but never down.
; ------------------------------------------------------------

(expect-true "sleeping 10ms sleeps at least 10ms" (>= (sqlite-sleep 10) 10))
(expect-true "sleeping 0ms returns without error" (>= (sqlite-sleep 0) 0))

(expect "closing the connection" TRUE (sqlite-close ?*cn-db*))
