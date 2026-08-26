; ============================================================
; ARGUMENT-SHAPE GUARDS
;
; Every wrapper here is registered with an AddUDF restriction string, and CLIPS
; checks that string against literal arguments when it parses the call.  That
; check is not the one being tested: it happens before the wrapper runs, and it
; never fires for an argument that arrives through a variable.  What is tested
; is the wrapper's own guard, the one that has to catch the same mistake at
; run time -- so every wrong-shaped argument below goes through a defglobal.
;
; The [ARGACCES2] lines on stderr are the restriction string reporting the
; mismatch on its way past.  They are the exercise, not noise: each one is
; followed by the wrapper's own refusal, and a wrapper that printed the first
; without the second would be one running on an argument it never checked.
;
; The result is bound before it is asserted for the same reason.  A refused
; argument leaves CLIPS in an evaluation-error state, and raising that inside
; an (expect ...) aborts the expect itself -- the assertion would disappear
; from the count rather than fail.
; ============================================================

(defglobal
  ?*ag-str* = "not-a-handle"
  ?*ag-sym* = not-a-handle
  ?*ag-int* = 7
  ?*ag-flt* = 1.5
  ?*ag-mf*  = (create$ 1 2)
  ?*ag-r*   = nothing
  ?*ag-db*  = FALSE
  ?*ag-db2* = FALSE
  ?*ag-st*  = FALSE
  ?*ag-bk*  = FALSE)

(bind ?*ag-db* (sqlite-open :memory:))
(expect "the connection opened" TRUE (pointerp ?*ag-db*))
(bind ?*ag-st* (sqlite-prepare ?*ag-db* "SELECT 1 AS a, :p AS b;"))
(expect "the statement prepared" TRUE (pointerp ?*ag-st*))
(bind ?*ag-db2* (sqlite-open :memory:))
(expect "a second connection opened" TRUE (pointerp ?*ag-db2*))
(bind ?*ag-bk* (sqlite-backup-init ?*ag-db2* main ?*ag-db* main))
(expect "the backup handle was created" TRUE (pointerp ?*ag-bk*))

; ------------------------------------------------------------
; where a connection is expected
; ------------------------------------------------------------

(bind ?*ag-r* (sqlite-close ?*ag-str*))
(expect "close refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-close ?*ag-int*))
(expect "and an integer" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-changes ?*ag-sym*))
(expect "changes refuses a symbol" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-total-changes ?*ag-flt*))
(expect "total-changes refuses a float" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-last-insert-rowid ?*ag-mf*))
(expect "last-insert-rowid refuses a multifield" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-db-name ?*ag-str* 0))
(expect "db-name refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-db-filename ?*ag-str* main))
(expect "db-filename refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-db-readonly ?*ag-str* main))
(expect "db-readonly refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-db-exists ?*ag-str* main))
(expect "db-exists refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-errmsg ?*ag-str*))
(expect "errmsg refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-busy-timeout ?*ag-str* 10))
(expect "busy-timeout refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-prepare ?*ag-str* "SELECT 1;"))
(expect "prepare refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-limit ?*ag-str* SQLITE_LIMIT_LENGTH))
(expect "limit refuses a string" FALSE ?*ag-r*)

; ------------------------------------------------------------
; where a statement is expected
; ------------------------------------------------------------

(bind ?*ag-r* (sqlite-finalize ?*ag-str*))
(expect "finalize refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-step ?*ag-int*))
(expect "step refuses an integer" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-reset ?*ag-sym*))
(expect "reset refuses a symbol" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-clear-bindings ?*ag-flt*))
(expect "clear-bindings refuses a float" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-sql ?*ag-mf*))
(expect "sql refuses a multifield" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-expanded-sql ?*ag-str*))
(expect "expanded-sql refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-column-count ?*ag-str*))
(expect "column-count refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-data-count ?*ag-str*))
(expect "data-count refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-column ?*ag-str* 0))
(expect "column refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-column-type ?*ag-str* 0))
(expect "column-type refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-column-name ?*ag-str* 0))
(expect "column-name refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-column-database-name ?*ag-str* 0))
(expect "column-database-name refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-column-table-name ?*ag-str* 0))
(expect "column-table-name refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-column-origin-name ?*ag-str* 0))
(expect "column-origin-name refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-bind ?*ag-str* 1 1))
(expect "bind refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-bind-parameter-count ?*ag-str*))
(expect "bind-parameter-count refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-bind-parameter-index ?*ag-str* ":p"))
(expect "bind-parameter-index refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-bind-parameter-name ?*ag-str* 1))
(expect "bind-parameter-name refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-stmt-explain ?*ag-str* 1))
(expect "stmt-explain refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-stmt-isexplain ?*ag-str*))
(expect "stmt-isexplain refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-row-to-multifield ?*ag-str*))
(expect "row-to-multifield refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-row-to-fact ?*ag-str* row-abc))
(expect "row-to-fact refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-row-to-instance ?*ag-str* ROW-ABC))
(expect "row-to-instance refuses a string" FALSE ?*ag-r*)

; ------------------------------------------------------------
; where a backup handle is expected
; ------------------------------------------------------------

(bind ?*ag-r* (sqlite-backup-step ?*ag-str* 1))
(expect "backup-step refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-backup-pagecount ?*ag-str*))
(expect "backup-pagecount refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-backup-remaining ?*ag-int*))
(expect "backup-remaining refuses an integer" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-backup-finish ?*ag-mf*))
(expect "backup-finish refuses a multifield" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-backup-init ?*ag-str* main ?*ag-db* main))
(expect "backup-init refuses a string as the destination" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-backup-init ?*ag-db2* main ?*ag-str* main))
(expect "and as the source" FALSE ?*ag-r*)

; ------------------------------------------------------------
; where an index is expected
; ------------------------------------------------------------

(bind ?*ag-r* (sqlite-column ?*ag-st* ?*ag-str*))
(expect "column refuses a string index" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-column-type ?*ag-st* ?*ag-str*))
(expect "column-type refuses one" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-column-name ?*ag-st* ?*ag-flt*))
(expect "column-name refuses a float index" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-column-database-name ?*ag-st* ?*ag-str*))
(expect "column-database-name refuses a string index" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-column-table-name ?*ag-st* ?*ag-str*))
(expect "column-table-name refuses one" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-column-origin-name ?*ag-st* ?*ag-str*))
(expect "column-origin-name refuses one" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-bind-parameter-name ?*ag-st* ?*ag-str*))
(expect "bind-parameter-name refuses a string index" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-stmt-explain ?*ag-st* ?*ag-str*))
(expect "stmt-explain refuses a string mode" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-db-name ?*ag-db* ?*ag-str*))
(expect "db-name refuses a string index" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-backup-step ?*ag-bk* ?*ag-str*))
(expect "backup-step refuses a string page count" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-busy-timeout ?*ag-db* ?*ag-str*))
(expect "busy-timeout refuses a string number of milliseconds" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-limit ?*ag-db* SQLITE_LIMIT_LENGTH ?*ag-str*))
(expect "limit refuses a string as the value to set" FALSE ?*ag-r*)

; ------------------------------------------------------------
; where a name is expected
; ------------------------------------------------------------

(bind ?*ag-r* (sqlite-bind-parameter-index ?*ag-st* ?*ag-int*))
(expect "bind-parameter-index refuses an integer name" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-row-to-fact ?*ag-st* ?*ag-str*))
(expect "row-to-fact refuses a string template name" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-row-to-fact ?*ag-st* ?*ag-int*))
(expect "and an integer one" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-row-to-instance ?*ag-st* ?*ag-str*))
(expect "row-to-instance refuses a string class name" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-row-to-instance ?*ag-st* ROW-ABC ?*ag-int*))
(expect "and an integer instance name" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-row-to-instance ?*ag-st* ROW-ABC nil ?*ag-int*))
(expect "and an integer name-slot" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-backup-init ?*ag-db2* ?*ag-int* ?*ag-db* main))
(expect "backup-init refuses an integer database name" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-backup-init ?*ag-db2* main ?*ag-db* ?*ag-int*))
(expect "in either position" FALSE ?*ag-r*)

; ------------------------------------------------------------
; the wrappers that take no handle at all
; ------------------------------------------------------------

(bind ?*ag-r* (sqlite-compileoption-get ?*ag-str*))
(expect "compileoption-get refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-compileoption-get ?*ag-flt*))
(expect "and a float" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-compileoption-used ?*ag-int*))
(expect "compileoption-used refuses an integer" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-sleep ?*ag-str*))
(expect "sleep refuses a string" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-sleep ?*ag-flt*))
(expect "and a float" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-memory-highwater ?*ag-mf*))
(expect "memory-highwater refuses a multifield" FALSE ?*ag-r*)

; ------------------------------------------------------------
; sqlite-bind, whose second argument is deliberately unrestricted
;
; It is registered as taking anything, because it dispatches on the type
; itself.  So there is no shape it rejects out of hand -- what it rejects is a
; shape that does not name a parameter of *this* statement.
; ------------------------------------------------------------

(bind ?*ag-r* (sqlite-bind ?*ag-st* ?*ag-str* 1))
(expect "a name the statement does not have is refused" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-bind ?*ag-st* ?*ag-mf* 1))
(expect "a multifield in the index position binds by position instead"
        FALSE ?*ag-r*)

; ------------------------------------------------------------
; the two wrappers that used to dereference before they checked
;
; sqlite-open read its path straight out of theArg.lexemeValue->contents with
; no guard between the UDFNextArgument and the dereference, and sqlite-limit
; reached its chain of strcmps with whatever it had been handed.  Neither
; refused: both read the argument as a pointer it was not, and the process did
; not survive it.  These assertions are the reason the guards are there, so
; they belong in the same process as everything else -- a regression here
; should take the run down loudly rather than be reported from the side.
; ------------------------------------------------------------

(bind ?*ag-r* (sqlite-open ?*ag-int*))
(expect "open refuses an integer path" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-open ?*ag-flt*))
(expect "and a float one" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-open ?*ag-mf*))
(expect "and a multifield" FALSE ?*ag-r*)

(bind ?*ag-r* (sqlite-open :memory:
                           (create$ SQLITE_OPEN_READWRITE SQLITE_OPEN_CREATE)
                           ?*ag-int*))
(expect "open refuses an integer VFS name" FALSE ?*ag-r*)

(bind ?*ag-r* (sqlite-limit ?*ag-db* ?*ag-flt*))
(expect "limit refuses a float id" FALSE ?*ag-r*)
(bind ?*ag-r* (sqlite-limit ?*ag-db* ?*ag-mf*))
(expect "and a multifield id" FALSE ?*ag-r*)

(expect "finishing the backup" TRUE (sqlite-backup-finish ?*ag-bk*))
(expect "finalizing the statement" TRUE (sqlite-finalize ?*ag-st*))
(expect "closing the connections" TRUE (sqlite-close ?*ag-db*))
(expect "both of them" TRUE (sqlite-close ?*ag-db2*))
