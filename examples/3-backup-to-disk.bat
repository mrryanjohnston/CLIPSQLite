; ======================================================================
; Working in memory, and keeping the result.
;
; A :memory: database is fast and it is gone when the connection closes.
; The backup API is how a run keeps what it worked out: it copies one
; database into another, a few pages at a time, and neither of them has to
; be a file on disk -- so "save this" and "load that" are the same call
; with the arguments the other way round.
;
;   ./vendor/clips/clips -f2 examples/3-backup-to-disk.bat
; ======================================================================

(deftemplate sensor-summary
  (slot sensor)
  (slot readings)
  (slot warmest)
  (slot average))

(defrule report
  (sensor-summary (sensor ?s) (readings ?n) (warmest ?max) (average ?avg))
  =>
  (println "  " ?s ": " ?n " readings, warmest " ?max ", average " ?avg))

(defrule running-hot
  (declare (salience -10))
  (sensor-summary (sensor ?s) (average ?avg&:(> ?avg 50.0)))
  =>
  (println "  " ?s " is running hot"))

(deffunction run-sql (?db ?sql)
  (bind ?stmt (sqlite-prepare ?db ?sql))
  (if (not ?stmt)
   then
     (println "cannot prepare: " (sqlite-errmsg ?db))
     (return FALSE))
  (sqlite-step ?stmt)
  (sqlite-finalize ?stmt))

; ----------------------------------------------------------------------
; The work
; ----------------------------------------------------------------------

(deffunction fill (?db)
  (run-sql ?db "CREATE TABLE reading (sensor TEXT, minute INTEGER, celsius REAL)")

  ; One statement, stepped 400 times.  Preparing it once and resetting it
  ; is the difference between parsing the SQL once and parsing it 400
  ; times; inside a transaction it is also one fsync instead of 400.
  (run-sql ?db "BEGIN")
  (bind ?stmt (sqlite-prepare ?db "INSERT INTO reading VALUES (?, ?, ?)"))
  (loop-for-count (?i 1 200)
    (sqlite-bind ?stmt (create$ "boiler" ?i (+ 80.0 (mod ?i 7))))
    (sqlite-step ?stmt)
    (sqlite-reset ?stmt)
    (sqlite-bind ?stmt (create$ "intake" ?i (+ 11.0 (mod ?i 3))))
    (sqlite-step ?stmt)
    (sqlite-reset ?stmt))
  (sqlite-finalize ?stmt)
  (run-sql ?db "COMMIT")

  ; sqlite-changes counts the rows the last statement touched, and the
  ; last statement here was the COMMIT.  The running total since the
  ; connection opened is the number worth printing.
  (println "loaded " (sqlite-total-changes ?db) " readings"))

; The aggregate is the database's job, and the conclusion drawn from it is
; the rule engine's.  Each row of the summary becomes one fact.
(deffunction summarise (?db)
  (bind ?stmt (sqlite-prepare ?db
    "SELECT sensor,
            count(*)                AS readings,
            max(celsius)            AS warmest,
            round(avg(celsius), 2)  AS average
       FROM reading
      GROUP BY sensor
      ORDER BY sensor"))
  (while (eq (sqlite-step ?stmt) SQLITE_ROW)
    (sqlite-row-to-fact ?stmt sensor-summary))
  (sqlite-finalize ?stmt))

; ----------------------------------------------------------------------
; The copy
;
; init takes the destination first and the source second, each named by
; the schema being copied -- "main" unless something has been ATTACHed.
; step copies at most that many pages and answers SQLITE_OK while there is
; more to do, SQLITE_DONE when there is not.  pagecount and remaining only
; mean anything once the first step has read the source, which is the part
; of this sequence most often got wrong.
; ----------------------------------------------------------------------

(deffunction save-to (?src ?path)
  (bind ?dst (sqlite-open ?path))
  (if (not ?dst)
   then (println "cannot open " ?path) (return FALSE))

  (bind ?backup (sqlite-backup-init ?dst "main" ?src "main"))
  (if (not ?backup)
   then (println "cannot start the copy: " (sqlite-errmsg ?dst))
        (sqlite-close ?dst)
        (return FALSE))

  (bind ?result (sqlite-backup-step ?backup 8))
  (println "copying " (sqlite-backup-pagecount ?backup) " pages")

  (while (eq ?result SQLITE_OK)
    (bind ?result (sqlite-backup-step ?backup 8)))

  (bind ?left (sqlite-backup-remaining ?backup))
  (sqlite-backup-finish ?backup)
  (sqlite-close ?dst)

  (if (and (eq ?result SQLITE_DONE) (= ?left 0))
   then
     (println "saved to " ?path)
     TRUE
   else
     (println "the copy stopped early: " ?result)
     FALSE))

; What was saved is a database like any other.  Opening it READONLY is the
; honest way to say that this half of the example only reads.
(deffunction count-rows (?path)
  (bind ?db (sqlite-open ?path SQLITE_OPEN_READONLY))
  (if (not ?db) then (return FALSE))
  (bind ?stmt (sqlite-prepare ?db "SELECT count(*) FROM reading"))
  (sqlite-step ?stmt)
  (bind ?n (sqlite-column ?stmt 0))
  (sqlite-finalize ?stmt)
  (sqlite-close ?db)
  ?n)

(deffunction main ()
  (system "rm -rf examples/tmp && mkdir -p examples/tmp")
  (bind ?path "examples/tmp/readings.db")

  (bind ?db (sqlite-open :memory:))
  (if (not ?db) then (println "cannot open the database") (return FALSE))

  (fill ?db)
  (summarise ?db)
  (println)
  (run)
  (println)

  (save-to ?db ?path)
  (sqlite-close ?db)

  (println "the file holds " (count-rows ?path) " readings")
  (system "rm -rf examples/tmp"))

(main)
(exit)
