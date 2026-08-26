; ======================================================================
; CLIPSQLite in-process test suite
;
; Every suite batched from here shares one CLIPS environment, one process and
; one assertion counter, and the run ends with a non-zero exit status if any
; assertion failed.
;
; Two rules hold throughout:
;
;   1. A call whose arguments are wrong for the wrapper goes through a
;      defglobal, never a literal.  CLIPS screens literal arguments against the
;      AddUDF restriction string at parse time, so a literal never reaches the
;      wrapper's own guard -- which is the thing being tested.
;
;   2. Such a call is bound to a global on a line of its own and asserted on
;      the next line.  A refused argument raises an [ARGACCES2] evaluation
;      error, and an error raised inside an (expect ...) aborts the expect
;      itself: the assertion would vanish from the count instead of failing.
;      The [ARGACCES2] lines on stderr are the exercise, not noise.
; ======================================================================

(defglobal
  ?*tests-ran*    = 0
  ?*tests-failed* = 0)

(deffunction expect (?msg ?expected ?actual)
  (bind ?*tests-ran* (+ ?*tests-ran* 1))
  (if (eq ?expected ?actual)
   then
     (print ".")
   else
     (bind ?*tests-failed* (+ ?*tests-failed* 1))
     (println crlf "FAILURE: " ?msg
             crlf "  expected=" ?expected
             crlf "  actual=" ?actual)))

; For values that are real but not fixed -- an elapsed time, a page count, a
; version number.  Asserting the exact value would make the suite a record of
; this machine rather than of the wrapper.
(deffunction expect-true (?msg ?actual)
  (expect ?msg TRUE (if ?actual then TRUE else FALSE)))

; A scratch directory for the suites that need a database on disk.  Removed
; first so a run that died before its own cleanup cannot seed the next one.
(system "rm -rf tests/tmp && mkdir -p tests/tmp")

(batch* tests/constructs.bat)

(println "CLIPSQLite test suite against SQLite " (sqlite-libversion))
(println)

(batch* tests/version-test-suite.bat)
(batch* tests/memory-test-suite.bat)
(batch* tests/open-close-test-suite.bat)
(batch* tests/connection-test-suite.bat)
(batch* tests/prepare-test-suite.bat)
(batch* tests/bind-test-suite.bat)
(batch* tests/step-column-test-suite.bat)
(batch* tests/row-mapping-test-suite.bat)
(batch* tests/limit-test-suite.bat)
(batch* tests/backup-test-suite.bat)
(batch* tests/handle-lifetime-test-suite.bat)
(batch* tests/arg-guard-test-suite.bat)

; ----------------------------------------------------------------------
; cleanup
;
; Every database the suites opened is closed by the suite that opened it, so
; SQLite's allocator should be back where it started.  A wrapper that leaked a
; connection or a statement shows up here and nowhere else.
; ----------------------------------------------------------------------

(println)
(expect "SQLite has no memory outstanding once every suite has cleaned up"
        0 (sqlite-memory-used))

(system "rm -rf tests/tmp")

(println)
(println "Tests run: " ?*tests-ran* "  Failures: " ?*tests-failed*)
(exit (if (> ?*tests-failed* 0) then 1 else 0))
