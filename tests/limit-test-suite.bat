; ============================================================
; PER-CONNECTION LIMITS
;
; sqlite-limit reads a limit with two arguments and sets it with three, and in
; both cases returns the value the limit had *before* the call -- so a set
; reports the old value, not the new one, and reading it back is a second
; call.  The limit is named either by its SQLITE_LIMIT_ symbol or by the
; integer SQLite gives that symbol, and the two spellings have to agree.
; ============================================================

(defglobal
  ?*lm-db*  = FALSE
  ?*lm-r*   = nothing
  ?*lm-old* = 0
  ?*lm-ids* = (create$ SQLITE_LIMIT_LENGTH
                       SQLITE_LIMIT_SQL_LENGTH
                       SQLITE_LIMIT_COLUMN
                       SQLITE_LIMIT_EXPR_DEPTH
                       SQLITE_LIMIT_COMPOUND_SELECT
                       SQLITE_LIMIT_VDBE_OP
                       SQLITE_LIMIT_FUNCTION_ARG
                       SQLITE_LIMIT_ATTACHED
                       SQLITE_LIMIT_LIKE_PATTERN_LENGTH
                       SQLITE_LIMIT_VARIABLE_NUMBER
                       SQLITE_LIMIT_TRIGGER_DEPTH
                       SQLITE_LIMIT_WORKER_THREADS))

(bind ?*lm-db* (sqlite-open :memory:))
(expect "the connection opened" TRUE (pointerp ?*lm-db*))

; ------------------------------------------------------------
; every limit answers, and the two spellings name the same one
;
; SQLite numbers the limits 0 through 11 in the order the SQLITE_LIMIT_ names
; are declared, so the nth symbol and the integer n-1 must read the same
; value.  Checking the pair is what would catch a name wired to the wrong
; constant, which reading either one alone would not.
; ------------------------------------------------------------

(defglobal ?*lm-mismatch* = none)
(loop-for-count (?i 1 (length$ ?*lm-ids*))
  (bind ?*lm-r* (sqlite-limit ?*lm-db* (nth$ ?i ?*lm-ids*)))
  (if (neq INTEGER (type ?*lm-r*))
   then (bind ?*lm-mismatch* (nth$ ?i ?*lm-ids*))
   else (if (neq ?*lm-r* (sqlite-limit ?*lm-db* (- ?i 1)))
         then (bind ?*lm-mismatch* (nth$ ?i ?*lm-ids*)))))

(expect "each limit name reads the same value as its integer id"
        none ?*lm-mismatch*)
(expect "there are twelve of them" 12 (length$ ?*lm-ids*))

; the integer range is exactly 0..11, and 11 is the last one that answers
(expect "id 0 is a limit" INTEGER (type (sqlite-limit ?*lm-db* 0)))
(expect "id 11 is a limit" INTEGER (type (sqlite-limit ?*lm-db* 11)))

; ------------------------------------------------------------
; setting returns the previous value
; ------------------------------------------------------------

(bind ?*lm-old* (sqlite-limit ?*lm-db* SQLITE_LIMIT_LENGTH))
(expect-true "the length limit starts positive" (> ?*lm-old* 0))

(expect "setting it reports the value it had"
        ?*lm-old* (sqlite-limit ?*lm-db* SQLITE_LIMIT_LENGTH (- ?*lm-old* 1)))
(expect "and reading it back gives the new one"
        (- ?*lm-old* 1) (sqlite-limit ?*lm-db* SQLITE_LIMIT_LENGTH))

; the same limit reached by its integer id sees the change
(expect "the integer id sees the same limit"
        (- ?*lm-old* 1) (sqlite-limit ?*lm-db* 0))
(expect "and setting through the integer id works too"
        (- ?*lm-old* 1) (sqlite-limit ?*lm-db* 0 (- ?*lm-old* 2)))
(expect "as the name confirms"
        (- ?*lm-old* 2) (sqlite-limit ?*lm-db* SQLITE_LIMIT_LENGTH))

; ------------------------------------------------------------
; SQLite clamps rather than refuses
;
; A new value above the hard maximum compiled into the library is reduced to
; that maximum, and a negative value is not a set at all -- it is how the C
; API spells "just tell me the current value".  Both come back through the
; same return, so a caller who does not read it back cannot tell.
; ------------------------------------------------------------

(bind ?*lm-old* (sqlite-limit ?*lm-db* SQLITE_LIMIT_COLUMN))
(bind ?*lm-r* (sqlite-limit ?*lm-db* SQLITE_LIMIT_COLUMN -1))
(expect "a negative new value reports the current one" ?*lm-old* ?*lm-r*)
(expect "and leaves it where it was"
        ?*lm-old* (sqlite-limit ?*lm-db* SQLITE_LIMIT_COLUMN))

(bind ?*lm-r* (sqlite-limit ?*lm-db* SQLITE_LIMIT_COLUMN 2000000000))
(expect "an over-large new value reports the current one" ?*lm-old* ?*lm-r*)
(expect-true "and the limit is clamped, not taken literally"
             (< (sqlite-limit ?*lm-db* SQLITE_LIMIT_COLUMN) 2000000000))

; a lowered limit is not bookkeeping: it changes what the connection will
; compile, which is the only check here that the value reached SQLite at all
(expect "the parameter limit starts well above one" INTEGER
        (type (sqlite-limit ?*lm-db* SQLITE_LIMIT_VARIABLE_NUMBER 1)))
(expect "and reads back as one" 1 (sqlite-limit ?*lm-db* SQLITE_LIMIT_VARIABLE_NUMBER))
(bind ?*lm-r* (sqlite-prepare ?*lm-db* "SELECT ?1, ?2;"))
(expect "so a statement wanting two parameters no longer compiles" FALSE ?*lm-r*)
(expect-true "and the connection says which limit stopped it"
             (neq FALSE (str-index "variable number" (sqlite-errmsg ?*lm-db*))))

; ------------------------------------------------------------
; a name that is not a limit
; ------------------------------------------------------------

(bind ?*lm-r* (sqlite-limit ?*lm-db* SQLITE_LIMIT_NOT_A_LIMIT))
(expect "an unknown SQLITE_LIMIT_ name is refused" FALSE ?*lm-r*)

(bind ?*lm-r* (sqlite-limit ?*lm-db* "SQLITE_LIMIT_LENGTH"))
(expect "the name may be given as a string" INTEGER (type ?*lm-r*))

; ------------------------------------------------------------
; an integer that is not one of the twelve
;
; The id is accepted as an integer or as a name, and the two used to be
; distinguished by one condition that tested the type and the range together.
; An integer outside 0..11 failed that condition on its range and fell through
; to the chain of names below, where it was read as a lexeme -- so an
; out-of-range id was not the refusal it looked like.
; ------------------------------------------------------------

(bind ?*lm-r* (sqlite-limit ?*lm-db* 12))
(expect "an id one past the last limit is refused" FALSE ?*lm-r*)
(bind ?*lm-r* (sqlite-limit ?*lm-db* -1))
(expect "and so is a negative id" FALSE ?*lm-r*)
(bind ?*lm-r* (sqlite-limit ?*lm-db* 1000000))
(expect "and a wild one" FALSE ?*lm-r*)

; the refusal is the range, not the wrapper giving up: 11 still answers
(expect "while the last real id still answers"
        INTEGER (type (sqlite-limit ?*lm-db* 11)))

; ------------------------------------------------------------
; limits are per connection
; ------------------------------------------------------------

(defglobal ?*lm-db2* = FALSE)
(bind ?*lm-db2* (sqlite-open :memory:))
(expect "a second connection opened" TRUE (pointerp ?*lm-db2*))
(expect-true "and did not inherit the first one's altered limit"
             (> (sqlite-limit ?*lm-db2* SQLITE_LIMIT_VARIABLE_NUMBER) 1))
(expect "closing it" TRUE (sqlite-close ?*lm-db2*))

(expect "closing the connection" TRUE (sqlite-close ?*lm-db*))
