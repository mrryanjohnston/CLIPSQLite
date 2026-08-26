; ============================================================
; OPENING AND CLOSING
;
; sqlite-open is the only wrapper with three optional shapes on one argument:
; the flag set may be omitted, given as one symbol, or given as a multifield.
; Each shape reaches a different branch, and the branches disagree about what
; the default is -- an omitted flag set means READWRITE|CREATE, while a flag
; set that names something the wrapper does not recognise means no flags at
; all.  That difference is what most of this suite is about.
; ============================================================

(defglobal
  ?*oc-db*   = FALSE
  ?*oc-db2*  = FALSE
  ?*oc-r*    = nothing
  ?*oc-path* = "tests/tmp/open-close.db")

; ------------------------------------------------------------
; the default flag set
; ------------------------------------------------------------

(bind ?*oc-db* (sqlite-open :memory:))
(expect "an in-memory database opens" TRUE (pointerp ?*oc-db*))
(expect "and closes" TRUE (sqlite-close ?*oc-db*))

; the path is read as text, so a symbol and a string name the same database
(bind ?*oc-db* (sqlite-open ":memory:"))
(expect "the path may be a string as well as a symbol" TRUE (pointerp ?*oc-db*))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))

; the default flags include CREATE, so a path that does not exist is made
(bind ?*oc-db* (sqlite-open ?*oc-path*))
(expect "a file database is created by default" TRUE (pointerp ?*oc-db*))
(expect "and reports the path it was opened on"
        TRUE (neq FALSE (str-index "open-close.db" (sqlite-db-filename ?*oc-db* main))))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))

; ------------------------------------------------------------
; an explicit flag set, spelled both ways
; ------------------------------------------------------------

(bind ?*oc-db* (sqlite-open ?*oc-path* SQLITE_OPEN_READONLY))
(expect "a single flag symbol opens the database" TRUE (pointerp ?*oc-db*))
(expect "and READONLY took effect" TRUE (sqlite-db-readonly ?*oc-db* main))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))

(bind ?*oc-db* (sqlite-open ?*oc-path* (create$ SQLITE_OPEN_READONLY)))
(expect "a one-element multifield means the same thing" TRUE (pointerp ?*oc-db*))
(expect "and READONLY still took effect" TRUE (sqlite-db-readonly ?*oc-db* main))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))

(bind ?*oc-db* (sqlite-open ?*oc-path* (create$ SQLITE_OPEN_READWRITE SQLITE_OPEN_CREATE)))
(expect "several flags are OR-ed together" TRUE (pointerp ?*oc-db*))
(expect "and the database is writable" FALSE (sqlite-db-readonly ?*oc-db* main))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))

; MEMORY overrides the path entirely: nothing is written to disk under it
(bind ?*oc-db* (sqlite-open "tests/tmp/never-created.db"
                            (create$ SQLITE_OPEN_READWRITE SQLITE_OPEN_CREATE SQLITE_OPEN_MEMORY)))
(expect "SQLITE_OPEN_MEMORY opens a private in-memory database" TRUE (pointerp ?*oc-db*))
(expect "which has no filename" FALSE (sqlite-db-filename ?*oc-db* main))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))

; ------------------------------------------------------------
; an empty multifield keeps the default
;
; The wrapper only drops the default flag set once it has a flag to put in its
; place, so (create$) is not a way to ask for no flags at all.
; ------------------------------------------------------------

(bind ?*oc-db* (sqlite-open :memory: (create$)))
(expect "an empty flag multifield leaves the default flags in place"
        TRUE (pointerp ?*oc-db*))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))

; ------------------------------------------------------------
; unrecognised flags
;
; A symbol the wrapper does not know contributes nothing, and since naming any
; flag replaces the default set, naming only unknown ones leaves no flags at
; all -- which SQLite refuses as a misuse rather than defaulting.
; ------------------------------------------------------------

(bind ?*oc-r* (sqlite-open :memory: SQLITE_OPEN_NOT_A_FLAG))
(expect "a flag set of nothing but unknown names is refused" FALSE ?*oc-r*)

(bind ?*oc-r* (sqlite-open :memory: (create$ SQLITE_OPEN_NOT_A_FLAG)))
(expect "the same in multifield form" FALSE ?*oc-r*)

; alongside a real flag the unknown name is simply dropped
(bind ?*oc-db* (sqlite-open :memory: (create$ SQLITE_OPEN_NOT_A_FLAG
                                              SQLITE_OPEN_READWRITE
                                              SQLITE_OPEN_CREATE)))
(expect "an unknown name next to real flags is ignored" TRUE (pointerp ?*oc-db*))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))

; a non-lexeme inside the multifield is skipped the same way
(bind ?*oc-db* (sqlite-open :memory: (create$ 42 SQLITE_OPEN_READWRITE SQLITE_OPEN_CREATE)))
(expect "a non-lexeme inside the flag multifield is skipped" TRUE (pointerp ?*oc-db*))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))

; ------------------------------------------------------------
; the VFS argument
; ------------------------------------------------------------

(bind ?*oc-db* (sqlite-open "file:oc-uri?mode=memory"
                            (create$ SQLITE_OPEN_READWRITE SQLITE_OPEN_CREATE SQLITE_OPEN_URI)
                            unix))
(expect "a named VFS is accepted" TRUE (pointerp ?*oc-db*))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))

(bind ?*oc-r* (sqlite-open :memory:
                           (create$ SQLITE_OPEN_READWRITE SQLITE_OPEN_CREATE)
                           no-such-vfs))
(expect "a VFS that does not exist is refused" FALSE ?*oc-r*)

; ------------------------------------------------------------
; opens that fail
; ------------------------------------------------------------

(bind ?*oc-r* (sqlite-open "tests/tmp/absent.db" SQLITE_OPEN_READONLY))
(expect "READONLY does not create a missing file" FALSE ?*oc-r*)

(bind ?*oc-r* (sqlite-open "tests/tmp/no/such/directory/x.db"))
(expect "a path whose directory does not exist is refused" FALSE ?*oc-r*)

; ------------------------------------------------------------
; closing
;
; A closed connection's external address is emptied in place, so the handle
; every caller is holding stops working at once rather than becoming a stale
; pointer that SQLite would answer from.
; ------------------------------------------------------------

(bind ?*oc-db* (sqlite-open :memory:))
(expect "close reports success" TRUE (sqlite-close ?*oc-db*))
(expect "the closed handle still looks like a pointer" TRUE (pointerp ?*oc-db*))

(bind ?*oc-r* (sqlite-close ?*oc-db*))
(expect "closing it a second time is refused, not repeated" FALSE ?*oc-r*)

; two connections to one file are independent handles
(bind ?*oc-db* (sqlite-open ?*oc-path*))
(bind ?*oc-db2* (sqlite-open ?*oc-path*))
(expect "a second connection to the same file opens" TRUE (pointerp ?*oc-db2*))
(expect "closing the first" TRUE (sqlite-close ?*oc-db*))
(expect "leaves the second usable" TRUE (sqlite-db-exists ?*oc-db2* main))
(expect "closing the second" TRUE (sqlite-close ?*oc-db2*))
