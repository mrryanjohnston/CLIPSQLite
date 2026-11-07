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
  ?*oc-db3*  = FALSE
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
(expect "which sqlite-db-exists still counts as existing" TRUE (sqlite-db-exists ?*oc-db* main))
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
; the rest of the flag vocabulary
;
; Six more names are spelled through to SQLite.  Two of them can be seen
; from here: NOFOLLOW refuses a path that is a symbolic link, and SHAREDCACHE
; has two connections share one page cache -- which shows as the second being
; locked out of a table the first is writing, where a PRIVATECACHE connection
; to the same file reads it as it was.  The mutex flags and EXRESCODE change
; nothing this binding can observe, so for those the assertion is only that
; the open takes them.
; ------------------------------------------------------------

(system "ln -sf open-close.db tests/tmp/open-close-link.db")

(bind ?*oc-db* (sqlite-open "tests/tmp/open-close-link.db"))
(expect "a symbolic link opens by default" TRUE (pointerp ?*oc-db*))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))

(bind ?*oc-r* (sqlite-open "tests/tmp/open-close-link.db"
                           (create$ SQLITE_OPEN_READWRITE SQLITE_OPEN_NOFOLLOW)))
(expect "but not under SQLITE_OPEN_NOFOLLOW" FALSE ?*oc-r*)

(bind ?*oc-db* (sqlite-open ?*oc-path* (create$ SQLITE_OPEN_READWRITE SQLITE_OPEN_NOFOLLOW)))
(expect "which still opens the file the link pointed at" TRUE (pointerp ?*oc-db*))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))

; a table for one connection to hold a write lock on
(bind ?*oc-db* (sqlite-open ?*oc-path*))
(expect "a table to lock" (create$)
        (sqlite-query-to-multifield ?*oc-db* "CREATE TABLE oc_shared (a);"))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))

(bind ?*oc-db* (sqlite-open ?*oc-path* (create$ SQLITE_OPEN_READWRITE SQLITE_OPEN_SHAREDCACHE)))
(expect "a shared-cache connection opens" TRUE (pointerp ?*oc-db*))
(bind ?*oc-db2* (sqlite-open ?*oc-path* (create$ SQLITE_OPEN_READWRITE SQLITE_OPEN_SHAREDCACHE)))
(expect "and a second one sharing the cache" TRUE (pointerp ?*oc-db2*))
(bind ?*oc-db3* (sqlite-open ?*oc-path* (create$ SQLITE_OPEN_READWRITE SQLITE_OPEN_PRIVATECACHE)))
(expect "and a third with a cache of its own" TRUE (pointerp ?*oc-db3*))

(expect "the first starts writing" (create$)
        (sqlite-query-to-multifield ?*oc-db* "BEGIN IMMEDIATE;"))
(expect "a row" (create$)
        (sqlite-query-to-multifield ?*oc-db* "INSERT INTO oc_shared VALUES (1);"))

(bind ?*oc-r* (sqlite-query-to-multifield ?*oc-db2* "SELECT count(*) FROM oc_shared;"))
(expect "the connection sharing its cache cannot read the table meanwhile" (create$) ?*oc-r*)
(expect "because the table is locked"
        "database table is locked: oc_shared" (sqlite-errmsg ?*oc-db2*))
(expect "while the private-cache connection reads it as it was"
        (create$ 0) (sqlite-query-to-multifield ?*oc-db3* "SELECT count(*) FROM oc_shared;"))

(expect "rolling back" (create$) (sqlite-query-to-multifield ?*oc-db* "ROLLBACK;"))
(expect "closing the private-cache connection" TRUE (sqlite-close ?*oc-db3*))
(expect "and the shared ones" TRUE (sqlite-close ?*oc-db2*))
(expect "both of them" TRUE (sqlite-close ?*oc-db*))

(bind ?*oc-db* (sqlite-open :memory: (create$ SQLITE_OPEN_READWRITE SQLITE_OPEN_CREATE
                                              SQLITE_OPEN_NOMUTEX)))
(expect "SQLITE_OPEN_NOMUTEX is taken" TRUE (pointerp ?*oc-db*))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))
(bind ?*oc-db* (sqlite-open :memory: (create$ SQLITE_OPEN_READWRITE SQLITE_OPEN_CREATE
                                              SQLITE_OPEN_FULLMUTEX)))
(expect "so is SQLITE_OPEN_FULLMUTEX" TRUE (pointerp ?*oc-db*))
(expect "closing it" TRUE (sqlite-close ?*oc-db*))
(bind ?*oc-db* (sqlite-open :memory: (create$ SQLITE_OPEN_READWRITE SQLITE_OPEN_CREATE
                                              SQLITE_OPEN_EXRESCODE)))
(expect "and SQLITE_OPEN_EXRESCODE" TRUE (pointerp ?*oc-db*))
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
