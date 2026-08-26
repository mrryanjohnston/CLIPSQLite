; ============================================================
; ALLOCATOR ACCOUNTING
;
; sqlite-memory-used and sqlite-memory-highwater read SQLite's own allocator
; counters, so they say nothing until something has been allocated.  This suite
; runs before any connection is opened and closes what it opens, which makes
; the zero at both ends meaningful: it is the baseline the whole run is
; measured against in tests/test.bat.
; ============================================================

(defglobal
  ?*mem-db*   = FALSE
  ?*mem-peak* = 0
  ?*mem-r*    = nothing
  ?*mem-str*  = "TRUE"
  ?*mem-sym*  = yes
  ?*mem-int*  = 1)

(expect "nothing is allocated before the first connection" 0 (sqlite-memory-used))

; ------------------------------------------------------------
; the counters follow a connection's lifetime
; ------------------------------------------------------------

(bind ?*mem-db* (sqlite-open :memory:))
(expect "the scratch connection opened" TRUE (pointerp ?*mem-db*))
(expect-true "an open connection has memory outstanding" (> (sqlite-memory-used) 0))

(bind ?*mem-peak* (sqlite-memory-highwater))
(expect-true "the highwater mark is at least what is outstanding now"
             (>= ?*mem-peak* (sqlite-memory-used)))

(expect "closing the connection releases it" TRUE (sqlite-close ?*mem-db*))
(expect "and the allocator is back to zero" 0 (sqlite-memory-used))

; the peak is a peak: it survives the free that took used back to zero
(expect-true "the highwater mark survives the connection that set it"
             (>= (sqlite-memory-highwater) ?*mem-peak*))

; ------------------------------------------------------------
; the reset argument
;
; sqlite3_memory_highwater(1) returns the mark as it stood and then resets it
; to whatever is currently outstanding -- zero here.  Passing FALSE, or passing
; nothing, must not reset it, which is the half that a wrapper defaulting the
; flag the wrong way round would break.
; ------------------------------------------------------------

(bind ?*mem-peak* (sqlite-memory-highwater))
(expect "reading with FALSE gives the same mark" ?*mem-peak* (sqlite-memory-highwater FALSE))
(expect "and leaves it standing" ?*mem-peak* (sqlite-memory-highwater))

(expect "reading with TRUE gives the mark as it stood" ?*mem-peak* (sqlite-memory-highwater TRUE))
(expect "and then the mark is back down to what is outstanding"
        (sqlite-memory-used) (sqlite-memory-highwater))

; ------------------------------------------------------------
; the reset argument is a boolean and nothing else
;
; "TRUE" the string and any other symbol are refused rather than treated as
; truthy, so a caller who quotes the flag is told, not silently ignored.
; ------------------------------------------------------------

(bind ?*mem-r* (sqlite-memory-highwater ?*mem-str*))
(expect "the string \"TRUE\" is not the symbol TRUE" FALSE ?*mem-r*)

(bind ?*mem-r* (sqlite-memory-highwater ?*mem-sym*))
(expect "some other symbol is refused" FALSE ?*mem-r*)

(bind ?*mem-r* (sqlite-memory-highwater ?*mem-int*))
(expect "and so is 1" FALSE ?*mem-r*)
