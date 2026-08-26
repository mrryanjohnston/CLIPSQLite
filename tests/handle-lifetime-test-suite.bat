; ============================================================
; HANDLE LIFETIME
;
; Every handle this binding hands out is an external address wrapping a
; pointer SQLite owns, and the three wrappers that give one back --
; sqlite-close, sqlite-finalize, sqlite-backup-finish -- empty the address in
; place rather than only freeing what it pointed at.  That is what makes a
; released handle safe: pointerp still says TRUE, so nothing else could tell
; the difference, and the emptied pointer is the only thing standing between a
; second use and a freed one.
;
; So this suite uses each handle once while it is live, releases it, and then
; walks every wrapper that takes that kind of handle.  The live use is there on
; purpose: a test that only checked the refusal would still pass if the
; wrapper had stopped working altogether.
; ============================================================

(defglobal
  ?*hl-db*  = FALSE
  ?*hl-st*  = FALSE
  ?*hl-b*   = FALSE
  ?*hl-db2* = FALSE
  ?*hl-r*   = nothing)

; ------------------------------------------------------------
; a closed connection
; ------------------------------------------------------------

(bind ?*hl-db* (sqlite-open :memory:))
(expect "the connection opened" TRUE (pointerp ?*hl-db*))
(expect "and answers while it is live" "main" (sqlite-db-name ?*hl-db* 0))

(expect "closing it" TRUE (sqlite-close ?*hl-db*))
(expect "the closed handle is still an external address" TRUE (pointerp ?*hl-db*))

(bind ?*hl-r* (sqlite-close ?*hl-db*))
(expect "close refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-db-name ?*hl-db* 0))
(expect "db-name refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-db-filename ?*hl-db* main))
(expect "db-filename refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-db-readonly ?*hl-db* main))
(expect "db-readonly refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-db-exists ?*hl-db* main))
(expect "db-exists refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-changes ?*hl-db*))
(expect "changes refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-total-changes ?*hl-db*))
(expect "total-changes refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-last-insert-rowid ?*hl-db*))
(expect "last-insert-rowid refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-errmsg ?*hl-db*))
(expect "errmsg refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-busy-timeout ?*hl-db* 10))
(expect "busy-timeout refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-limit ?*hl-db* SQLITE_LIMIT_LENGTH))
(expect "limit refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-prepare ?*hl-db* "SELECT 1;"))
(expect "prepare refuses it" FALSE ?*hl-r*)

; ------------------------------------------------------------
; a finalized statement
; ------------------------------------------------------------

(bind ?*hl-db* (sqlite-open :memory:))
(bind ?*hl-st* (sqlite-prepare ?*hl-db* "SELECT 1 AS a, :p AS b;"))
(expect "the statement prepared" TRUE (pointerp ?*hl-st*))
(expect "and answers while it is live" 2 (sqlite-column-count ?*hl-st*))

(expect "finalizing it" TRUE (sqlite-finalize ?*hl-st*))
(expect "the finalized handle is still an external address" TRUE (pointerp ?*hl-st*))

(bind ?*hl-r* (sqlite-finalize ?*hl-st*))
(expect "finalize refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-step ?*hl-st*))
(expect "step refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-reset ?*hl-st*))
(expect "reset refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-clear-bindings ?*hl-st*))
(expect "clear-bindings refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-sql ?*hl-st*))
(expect "sql refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-expanded-sql ?*hl-st*))
(expect "expanded-sql refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-column-count ?*hl-st*))
(expect "column-count refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-data-count ?*hl-st*))
(expect "data-count refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-column ?*hl-st* 0))
(expect "column refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-column-type ?*hl-st* 0))
(expect "column-type refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-column-name ?*hl-st* 0))
(expect "column-name refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-column-database-name ?*hl-st* 0))
(expect "column-database-name refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-column-table-name ?*hl-st* 0))
(expect "column-table-name refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-column-origin-name ?*hl-st* 0))
(expect "column-origin-name refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-bind ?*hl-st* 1 1))
(expect "bind refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-bind-parameter-count ?*hl-st*))
(expect "bind-parameter-count refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-bind-parameter-index ?*hl-st* ":p"))
(expect "bind-parameter-index refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-bind-parameter-name ?*hl-st* 1))
(expect "bind-parameter-name refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-stmt-explain ?*hl-st* 1))
(expect "stmt-explain refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-stmt-isexplain ?*hl-st*))
(expect "stmt-isexplain refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-row-to-multifield ?*hl-st*))
(expect "row-to-multifield refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-row-to-fact ?*hl-st* row-abc))
(expect "row-to-fact refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-row-to-instance ?*hl-st* ROW-ABC))
(expect "row-to-instance refuses it" FALSE ?*hl-r*)

; ------------------------------------------------------------
; a connection will not close under a live statement
;
; SQLite refuses the close rather than tearing the statement out from under
; the caller, and the wrapper passes that refusal through -- so a leaked
; statement shows up as a connection that will not close, which is what the
; memory check at the end of the run is really testing for.
; ------------------------------------------------------------

(bind ?*hl-st* (sqlite-prepare ?*hl-db* "SELECT 1;"))
(expect "a statement is open" TRUE (pointerp ?*hl-st*))
(bind ?*hl-r* (sqlite-close ?*hl-db*))
(expect "the connection will not close under it" FALSE ?*hl-r*)
(expect "and is still usable afterwards" "main" (sqlite-db-name ?*hl-db* 0))
(expect "finalizing the statement" TRUE (sqlite-finalize ?*hl-st*))
(expect "lets the connection close" TRUE (sqlite-close ?*hl-db*))

; ------------------------------------------------------------
; a finished backup
; ------------------------------------------------------------

(bind ?*hl-db* (sqlite-open :memory:))
(bind ?*hl-db2* (sqlite-open :memory:))
(bind ?*hl-b* (sqlite-backup-init ?*hl-db2* main ?*hl-db* main))
(expect "the backup handle is created" TRUE (pointerp ?*hl-b*))
(expect "and answers while it is live" INTEGER (type (sqlite-backup-pagecount ?*hl-b*)))

(expect "finishing it" TRUE (sqlite-backup-finish ?*hl-b*))
(expect "the finished handle is still an external address" TRUE (pointerp ?*hl-b*))

(bind ?*hl-r* (sqlite-backup-finish ?*hl-b*))
(expect "backup-finish refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-backup-step ?*hl-b* 1))
(expect "backup-step refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-backup-pagecount ?*hl-b*))
(expect "backup-pagecount refuses it" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-backup-remaining ?*hl-b*))
(expect "backup-remaining refuses it" FALSE ?*hl-r*)

(bind ?*hl-r* (sqlite-backup-init ?*hl-db2* main ?*hl-db* main))
(expect "a fresh backup handle can still be made from the same connections"
        TRUE (pointerp ?*hl-r*))
(expect "and finished" TRUE (sqlite-backup-finish ?*hl-r*))

; ------------------------------------------------------------
; a released handle is not a handle to something else
;
; The three release wrappers each check the pointer they were given, so
; handing a closed connection to a statement wrapper -- or the reverse -- is
; refused on the NULL rather than on the type, which is the only check the
; external address carries.
; ------------------------------------------------------------

(expect "closing the first connection" TRUE (sqlite-close ?*hl-db*))
(bind ?*hl-r* (sqlite-finalize ?*hl-db*))
(expect "finalize refuses a closed connection handle" FALSE ?*hl-r*)
(bind ?*hl-r* (sqlite-backup-finish ?*hl-db*))
(expect "and so does backup-finish" FALSE ?*hl-r*)
(expect "closing the second connection" TRUE (sqlite-close ?*hl-db2*))
