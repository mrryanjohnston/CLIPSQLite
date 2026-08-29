; ======================================================================
; Rules over rows.
;
; The point of a SQLite library for CLIPS is not to print a result set --
; the sqlite3 shell does that better.  It is that a row can become a fact,
; and facts are what rules match on.  This example loads a table into
; working memory and lets the rule engine draw the conclusions.
;
;   ./vendor/clips/clips -f2 examples/1-rules-over-sql.bat
; ======================================================================

(deftemplate part
  (slot id)
  (slot name)
  (slot mass)
  (slot stock))

(defrule reorder
  (part (name ?name) (stock ?stock&:(< ?stock 10)))
  =>
  (println "reorder " ?name ": only " ?stock " left"))

(defrule too-heavy-to-post
  (part (name ?name) (mass ?mass&:(> ?mass 20.0)))
  =>
  (println ?name " is " ?mass "kg: too heavy to post"))

; ----------------------------------------------------------------------
; A statement with no rows to give back -- a CREATE, an INSERT -- is still
; prepared, stepped once and finalized.  Nothing here is optional: the
; statement holds a read or write lock on the database until it is
; finalized, whether or not anyone reads a row from it.
; ----------------------------------------------------------------------

(deffunction run-sql (?db ?sql)
  (bind ?stmt (sqlite-prepare ?db ?sql))
  (if (not ?stmt)
   then
     (println "cannot prepare: " (sqlite-errmsg ?db))
     (return FALSE))
  (bind ?result (sqlite-step ?stmt))
  (sqlite-finalize ?stmt)
  (eq ?result SQLITE_DONE))

(deffunction load-parts ()
  ; :memory: is a database that lives as long as the connection and never
  ; touches the disk.  A path here instead would be a file, created if it is
  ; not already there.
  (bind ?db (sqlite-open :memory:))
  (if (not ?db)
   then
     (println "cannot open the database")
     (return FALSE))

  (run-sql ?db (str-cat "CREATE TABLE part ("
                        "id INTEGER PRIMARY KEY, "
                        "name TEXT, "
                        "mass REAL, "
                        "stock INTEGER)"))
  (run-sql ?db (str-cat "INSERT INTO part VALUES "
                        "(1,'bolt',0.05,400),"
                        "(2,'anvil',35.0,3),"
                        "(3,'girder',80.0,42),"
                        "(4,'washer',0.01,7)"))

  ; The column names are the slot names, which is why the query names them
  ; after the deftemplate's slots rather than SELECT *.
  (bind ?stmt (sqlite-prepare ?db "SELECT id, name, mass, stock FROM part ORDER BY id"))

  (bind ?loaded 0)
  (while (eq (sqlite-step ?stmt) SQLITE_ROW)
    (sqlite-row-to-fact ?stmt part)
    (bind ?loaded (+ ?loaded 1)))

  (sqlite-finalize ?stmt)
  (sqlite-close ?db)
  ?loaded)

; A top-level (bind ...) does not survive to the next command in CLIPS, so
; the whole run is one function.
(deffunction main ()
  (bind ?n (load-parts))
  (if ?n
   then
     (println "loaded " ?n " parts")
     (run)
     (println "done")))

(main)
(exit)
