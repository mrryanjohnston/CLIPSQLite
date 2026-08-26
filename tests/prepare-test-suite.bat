; ============================================================
; STATEMENT LIFECYCLE
;
; prepare -> (bind) -> step -> reset -> finalize, plus the three readings of a
; statement's text.  The text readings are the part worth being careful about:
; sqlite-sql gives back what was compiled, with the parameters still in it,
; while sqlite-expanded-sql substitutes whatever is currently bound -- so the
; two answers differ exactly when something is bound, and that difference is
; how a caller tells which one they are looking at.
; ============================================================

(defglobal
  ?*pr-db* = FALSE
  ?*pr-st* = FALSE
  ?*pr-r*  = nothing)

(bind ?*pr-db* (sqlite-open :memory:))
(expect "the connection opened" TRUE (pointerp ?*pr-db*))

; ------------------------------------------------------------
; preparing
; ------------------------------------------------------------

(bind ?*pr-st* (sqlite-prepare ?*pr-db* "SELECT 1 AS a;"))
(expect "a statement prepares" TRUE (pointerp ?*pr-st*))
(expect "sqlite-sql gives back the text it was compiled from"
        "SELECT 1 AS a;" (sqlite-sql ?*pr-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*pr-st*))

; ------------------------------------------------------------
; only the first statement of the text is compiled
;
; sqlite3_prepare_v2 stops at the first statement and hands back a pointer to
; the rest, which this wrapper discards.  A caller who passes a script gets
; the first statement and no warning that the others were dropped, so this is
; asserted rather than assumed.
; ------------------------------------------------------------

(bind ?*pr-st* (sqlite-prepare ?*pr-db*
                 "CREATE TABLE t (a INTEGER, b TEXT); INSERT INTO t VALUES (1, 'x');"))
(expect "a two-statement script prepares" TRUE (pointerp ?*pr-st*))
(expect "and only the first statement is what compiled"
        "CREATE TABLE t (a INTEGER, b TEXT);" (sqlite-sql ?*pr-st*))
(expect "running it" SQLITE_DONE (sqlite-step ?*pr-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*pr-st*))

(bind ?*pr-st* (sqlite-prepare ?*pr-db* "SELECT count(*) FROM t;"))
(expect "the table exists" SQLITE_ROW (sqlite-step ?*pr-st*))
(expect "and the INSERT that followed it never ran" 0 (sqlite-column ?*pr-st* 0))
(expect "finalizing it" TRUE (sqlite-finalize ?*pr-st*))

; an empty statement compiles to nothing at all, which is a refusal here
(bind ?*pr-r* (sqlite-prepare ?*pr-db* ""))
(expect "empty text produces no statement" FALSE ?*pr-r*)

(bind ?*pr-r* (sqlite-prepare ?*pr-db* "-- nothing but a comment"))
(expect "and neither does a comment" FALSE ?*pr-r*)

(bind ?*pr-r* (sqlite-prepare ?*pr-db* "SELECT FROM;"))
(expect "text that does not parse is refused" FALSE ?*pr-r*)

; ------------------------------------------------------------
; the three readings of a statement's text
; ------------------------------------------------------------

(bind ?*pr-st* (sqlite-prepare ?*pr-db* "SELECT ?, :named;"))
(expect "the parameterised statement prepared" TRUE (pointerp ?*pr-st*))

(expect "sqlite-sql leaves the parameters as written"
        "SELECT ?, :named;" (sqlite-sql ?*pr-st*))
(expect "expanded-sql shows unbound parameters as NULL"
        "SELECT NULL, NULL;" (sqlite-expanded-sql ?*pr-st*))

(expect "binding the first parameter" TRUE (sqlite-bind ?*pr-st* 1 7))
(expect "binding the named one" TRUE (sqlite-bind ?*pr-st* ":named" "text"))

(expect "sqlite-sql is unmoved by binding"
        "SELECT ?, :named;" (sqlite-sql ?*pr-st*))
(expect "expanded-sql substitutes what is bound"
        "SELECT 7, 'text';" (sqlite-expanded-sql ?*pr-st*))

; ------------------------------------------------------------
; reset and clear-bindings are separate operations
;
; reset rewinds the statement and leaves the bindings alone; clear-bindings
; drops the bindings and leaves the cursor alone.  Doing one and expecting the
; other is the mistake this pair is here to catch.
; ------------------------------------------------------------

(expect "stepping it" SQLITE_ROW (sqlite-step ?*pr-st*))
(expect "resetting it" TRUE (sqlite-reset ?*pr-st*))
(expect "reset kept the bindings" "SELECT 7, 'text';" (sqlite-expanded-sql ?*pr-st*))
(expect "so the statement gives the same row again" SQLITE_ROW (sqlite-step ?*pr-st*))
(expect "resetting it again" TRUE (sqlite-reset ?*pr-st*))

(expect "clearing the bindings" TRUE (sqlite-clear-bindings ?*pr-st*))
(expect "drops them back to NULL" "SELECT NULL, NULL;" (sqlite-expanded-sql ?*pr-st*))

; both are idempotent on a statement that has not been stepped
(expect "reset on an unstepped statement is fine" TRUE (sqlite-reset ?*pr-st*))
(expect "and so is clearing bindings twice" TRUE (sqlite-clear-bindings ?*pr-st*))

(expect "finalizing it" TRUE (sqlite-finalize ?*pr-st*))

; ------------------------------------------------------------
; reset reports the error the failing step swallowed
;
; sqlite3_step answers SQLITE_ERROR generically and sqlite3_reset returns the
; specific code, which is why a constraint violation reads as a step failure
; followed by a reset failure rather than as one error.
; ------------------------------------------------------------

(bind ?*pr-st* (sqlite-prepare ?*pr-db* "CREATE TABLE u (a INTEGER PRIMARY KEY);"))
(expect "creating a table with a primary key" SQLITE_DONE (sqlite-step ?*pr-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*pr-st*))

(bind ?*pr-st* (sqlite-prepare ?*pr-db* "INSERT INTO u VALUES (1);"))
(expect "the first insert succeeds" SQLITE_DONE (sqlite-step ?*pr-st*))
(expect "resetting it" TRUE (sqlite-reset ?*pr-st*))
(bind ?*pr-r* (sqlite-step ?*pr-st*))
(expect "the second violates the key and is refused" FALSE ?*pr-r*)
(bind ?*pr-r* (sqlite-reset ?*pr-st*))
(expect "and resetting it surfaces the same failure" FALSE ?*pr-r*)
(expect-true "which the connection describes as a constraint"
             (neq FALSE (str-index "UNIQUE constraint" (sqlite-errmsg ?*pr-db*))))
(expect "finalizing it" TRUE (sqlite-finalize ?*pr-st*))

; ------------------------------------------------------------
; EXPLAIN as a mode of an already-compiled statement
;
; sqlite3_stmt_explain recompiles the statement in place, so the same handle
; answers as a query, as an EXPLAIN, and as an EXPLAIN QUERY PLAN in turn.
; sqlite-stmt-isexplain reports which of the three it currently is, spelling
; the two explaining modes as the SQL keywords rather than as 1 and 2.
; ------------------------------------------------------------

(bind ?*pr-st* (sqlite-prepare ?*pr-db* "SELECT a FROM t;"))
(expect "a plain query is not an explain" FALSE (sqlite-stmt-isexplain ?*pr-st*))
(expect "one column comes back" 1 (sqlite-column-count ?*pr-st*))

(expect "switching it to EXPLAIN" TRUE (sqlite-stmt-explain ?*pr-st* 1))
(expect "which it now reports" "EXPLAIN" (sqlite-stmt-isexplain ?*pr-st*))
(expect-true "and the row shape changed with it" (> (sqlite-column-count ?*pr-st*) 1))
(expect "the explained statement runs" SQLITE_ROW (sqlite-step ?*pr-st*))
(expect "resetting it" TRUE (sqlite-reset ?*pr-st*))

(expect "switching it to EXPLAIN QUERY PLAN" TRUE (sqlite-stmt-explain ?*pr-st* 2))
(expect "which it reports as the full keyword"
        "EXPLAIN QUERY PLAN" (sqlite-stmt-isexplain ?*pr-st*))

(expect "switching it back" TRUE (sqlite-stmt-explain ?*pr-st* 0))
(expect "leaves it a plain statement again" FALSE (sqlite-stmt-isexplain ?*pr-st*))
(expect "with its original shape" 1 (sqlite-column-count ?*pr-st*))

(bind ?*pr-r* (sqlite-stmt-explain ?*pr-st* 3))
(expect "3 is not one of the three modes" FALSE ?*pr-r*)
(bind ?*pr-r* (sqlite-stmt-explain ?*pr-st* -1))
(expect "and neither is -1" FALSE ?*pr-r*)

(expect "finalizing it" TRUE (sqlite-finalize ?*pr-st*))

; ------------------------------------------------------------
; finalizing
; ------------------------------------------------------------

(bind ?*pr-st* (sqlite-prepare ?*pr-db* "SELECT 1;"))
(expect "finalize reports success" TRUE (sqlite-finalize ?*pr-st*))
(expect "the finalized handle still looks like a pointer" TRUE (pointerp ?*pr-st*))
(bind ?*pr-r* (sqlite-finalize ?*pr-st*))
(expect "finalizing it twice is refused, not repeated" FALSE ?*pr-r*)

; a statement left mid-row finalizes cleanly; the rows it did not produce are
; simply abandoned
(bind ?*pr-st* (sqlite-prepare ?*pr-db* "SELECT 1 UNION SELECT 2;"))
(expect "the first row comes back" SQLITE_ROW (sqlite-step ?*pr-st*))
(expect "finalizing before the last row is fine" TRUE (sqlite-finalize ?*pr-st*))

(expect "closing the connection" TRUE (sqlite-close ?*pr-db*))
