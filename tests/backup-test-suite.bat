; ============================================================
; ONLINE BACKUP
;
; The backup API is a small state machine held in its own handle: init opens
; it against a (destination, source) pair, step copies pages, and finish
; closes it.  pagecount and remaining are only meaningful after the first
; step -- before it they are both zero, because the source has not been read
; yet -- which is the part of the sequence a caller most often gets wrong.
;
; sqlite-backup-step answers with SQLite's result-code names rather than the
; integers, so SQLITE_OK means "more to copy" and SQLITE_DONE means finished.
; ============================================================

(defglobal
  ?*bk-src*  = FALSE
  ?*bk-dst*  = FALSE
  ?*bk-b*    = FALSE
  ?*bk-st*   = FALSE
  ?*bk-r*    = nothing
  ?*bk-pages* = 0)

; ------------------------------------------------------------
; a source with enough pages that a one-page step does not finish it
; ------------------------------------------------------------

(bind ?*bk-src* (sqlite-open "tests/tmp/backup-src.db"))
(expect "the source opened" TRUE (pointerp ?*bk-src*))

(bind ?*bk-st* (sqlite-prepare ?*bk-src* "CREATE TABLE t (a INTEGER, b TEXT);"))
(expect "creating the table" SQLITE_DONE (sqlite-step ?*bk-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*bk-st*))

(bind ?*bk-st* (sqlite-prepare ?*bk-src*
  "INSERT INTO t SELECT value, hex(randomblob(400)) FROM generate_series(1, 200);"))
(if (neq FALSE ?*bk-st*)
 then
   (expect "filling it" SQLITE_DONE (sqlite-step ?*bk-st*))
   (expect "finalizing it" TRUE (sqlite-finalize ?*bk-st*))
 else
   ; generate_series is an optional module; without it the rows go in one at a
   ; time, which is slower but produces the same multi-page database
   (bind ?*bk-st* (sqlite-prepare ?*bk-src* "INSERT INTO t VALUES (?, hex(randomblob(400)));"))
   (expect "the fallback insert prepared" TRUE (pointerp ?*bk-st*))
   (loop-for-count (?i 1 200)
     (sqlite-bind ?*bk-st* 1 ?i)
     (sqlite-step ?*bk-st*)
     (sqlite-reset ?*bk-st*))
   (expect "finalizing it" TRUE (sqlite-finalize ?*bk-st*)))

(bind ?*bk-st* (sqlite-prepare ?*bk-src* "SELECT count(*) FROM t;"))
(expect "the source has a row" SQLITE_ROW (sqlite-step ?*bk-st*))
(expect "and 200 of them" 200 (sqlite-column ?*bk-st* 0))
(expect "finalizing it" TRUE (sqlite-finalize ?*bk-st*))

; ------------------------------------------------------------
; a backup, one page at a time
; ------------------------------------------------------------

(bind ?*bk-dst* (sqlite-open "tests/tmp/backup-dst.db"))
(expect "the destination opened" TRUE (pointerp ?*bk-dst*))

(bind ?*bk-b* (sqlite-backup-init ?*bk-dst* main ?*bk-src* main))
(expect "the backup handle is created" TRUE (pointerp ?*bk-b*))

(expect "before the first step nothing is known about the source"
        0 (sqlite-backup-pagecount ?*bk-b*))
(expect "nor about what is left" 0 (sqlite-backup-remaining ?*bk-b*))

(expect "one page copies, with more to come" SQLITE_OK (sqlite-backup-step ?*bk-b* 1))

(bind ?*bk-pages* (sqlite-backup-pagecount ?*bk-b*))
(expect-true "now the source's size is known" (> ?*bk-pages* 1))
(expect "and one page of it has been copied"
        (- ?*bk-pages* 1) (sqlite-backup-remaining ?*bk-b*))

(expect "a negative page count copies whatever is left" SQLITE_DONE
        (sqlite-backup-step ?*bk-b* -1))
(expect "leaving nothing remaining" 0 (sqlite-backup-remaining ?*bk-b*))
(expect "and the page count unchanged" ?*bk-pages* (sqlite-backup-pagecount ?*bk-b*))

(expect "finishing the backup" TRUE (sqlite-backup-finish ?*bk-b*))

; finish empties the handle in place, the way close and finalize do
(expect "the finished handle still looks like a pointer" TRUE (pointerp ?*bk-b*))
(bind ?*bk-r* (sqlite-backup-pagecount ?*bk-b*))
(expect "but it no longer answers" FALSE ?*bk-r*)
(bind ?*bk-r* (sqlite-backup-remaining ?*bk-b*))
(expect "on either count" FALSE ?*bk-r*)
(bind ?*bk-r* (sqlite-backup-step ?*bk-b* 1))
(expect "and cannot be stepped again" FALSE ?*bk-r*)
(bind ?*bk-r* (sqlite-backup-finish ?*bk-b*))
(expect "nor finished twice" FALSE ?*bk-r*)

; ------------------------------------------------------------
; the copy is a copy
; ------------------------------------------------------------

(bind ?*bk-st* (sqlite-prepare ?*bk-dst* "SELECT count(*) FROM t;"))
(expect "the destination has the table" SQLITE_ROW (sqlite-step ?*bk-st*))
(expect "with every row of the source" 200 (sqlite-column ?*bk-st* 0))
(expect "finalizing it" TRUE (sqlite-finalize ?*bk-st*))

; ------------------------------------------------------------
; a backup that copies everything in one step
; ------------------------------------------------------------

(bind ?*bk-b* (sqlite-backup-init ?*bk-dst* main ?*bk-src* main))
(expect "a second backup handle is created" TRUE (pointerp ?*bk-b*))
(expect "-1 copies the whole database at once" SQLITE_DONE (sqlite-backup-step ?*bk-b* -1))
(expect "with nothing left over" 0 (sqlite-backup-remaining ?*bk-b*))
(expect "finishing it" TRUE (sqlite-backup-finish ?*bk-b*))

; a page count of zero copies nothing and reports there is more to do
(bind ?*bk-b* (sqlite-backup-init ?*bk-dst* main ?*bk-src* main))
(expect "a third backup handle is created" TRUE (pointerp ?*bk-b*))
(expect "stepping zero pages is not an error" SQLITE_OK (sqlite-backup-step ?*bk-b* 0))
(expect-true "it still reads the source's size" (> (sqlite-backup-pagecount ?*bk-b*) 0))
(expect "but copies none of it"
        (sqlite-backup-pagecount ?*bk-b*) (sqlite-backup-remaining ?*bk-b*))
(expect "finishing it" TRUE (sqlite-backup-finish ?*bk-b*))

; ------------------------------------------------------------
; init refuses what it cannot back up
; ------------------------------------------------------------

(bind ?*bk-r* (sqlite-backup-init ?*bk-dst* main ?*bk-src* no-such-db))
(expect "a source database name nothing is attached under is refused" FALSE ?*bk-r*)

(bind ?*bk-r* (sqlite-backup-init ?*bk-dst* no-such-db ?*bk-src* main))
(expect "and so is a destination name" FALSE ?*bk-r*)

; a database cannot be backed up onto itself
(bind ?*bk-r* (sqlite-backup-init ?*bk-src* main ?*bk-src* main))
(expect "a connection cannot back itself up" FALSE ?*bk-r*)

; ------------------------------------------------------------
; a backup interrupted part of the way through
;
; finish is what releases the handle, whether or not the copy ran to
; SQLITE_DONE, and an abandoned backup leaves the destination usable rather
; than half-written -- the pages already copied are inside a transaction that
; finish rolls back.
; ------------------------------------------------------------

(bind ?*bk-b* (sqlite-backup-init ?*bk-dst* main ?*bk-src* main))
(expect "a backup handle is open" TRUE (pointerp ?*bk-b*))
(expect "one page copies" SQLITE_OK (sqlite-backup-step ?*bk-b* 1))
(expect-true "with the rest still to go" (> (sqlite-backup-remaining ?*bk-b*) 0))
(expect "finishing it part-way through is not an error"
        TRUE (sqlite-backup-finish ?*bk-b*))

(bind ?*bk-st* (sqlite-prepare ?*bk-dst* "SELECT count(*) FROM t;"))
(expect "and the destination is still readable" SQLITE_ROW (sqlite-step ?*bk-st*))
(expect "with the rows the completed backup left there"
        200 (sqlite-column ?*bk-st* 0))
(expect "finalizing it" TRUE (sqlite-finalize ?*bk-st*))

(expect "closing the destination" TRUE (sqlite-close ?*bk-dst*))
(expect "closing the source" TRUE (sqlite-close ?*bk-src*))
