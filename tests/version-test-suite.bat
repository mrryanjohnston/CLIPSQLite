; ============================================================
; LIBRARY IDENTITY AND COMPILE OPTIONS
;
; These six take no connection and no statement, so they are the only
; wrappers that can be checked before anything is opened.  The versions
; themselves are whatever the linked libsqlite3 says, so what is asserted is
; that the three spellings agree with each other rather than any one value.
; ============================================================

(defglobal
  ?*ver-r* = nothing)

; ------------------------------------------------------------
; version
; ------------------------------------------------------------

(expect "libversion is a symbol, not a string" SYMBOL (type (sqlite-libversion)))
(expect "libversion-number is an integer" INTEGER (type (sqlite-libversion-number)))
(expect-true "libversion-number is at least 3.0.0" (>= (sqlite-libversion-number) 3000000))

; sqlite3_libversion_number() is (major*1000000 + minor*1000 + patch), so it
; and the dotted string are two spellings of one release.  Rebuilding one from
; the other is what would catch a wrapper answering from a stale constant
; rather than from the library it is linked against.
(defglobal ?*ver-n* = (sqlite-libversion-number))
(expect "libversion-number spells out the same release as libversion"
        (str-cat (sqlite-libversion))
        (str-cat (div ?*ver-n* 1000000) "."
                 (div (mod ?*ver-n* 1000000) 1000) "."
                 (mod ?*ver-n* 1000)))

; the source id is the release's date followed by its commit hash
(expect "sourceid is a symbol" SYMBOL (type (sqlite-sourceid)))
(expect-true "sourceid is not empty" (> (str-length (str-cat (sqlite-sourceid))) 0))

(expect "threadsafe answers a boolean" TRUE
        (or (eq TRUE (sqlite-threadsafe)) (eq FALSE (sqlite-threadsafe))))

; ------------------------------------------------------------
; compile options
;
; The option at a given index depends on how libsqlite3 was built, so the
; assertions are about the shape of the walk: every index below the end
; answers with a symbol, the first index past the end refuses, and any option
; the walk produced reports itself as used.
; ------------------------------------------------------------

(expect "compileoption-get 0 is a symbol" SYMBOL (type (sqlite-compileoption-get 0)))

(defglobal ?*ver-opts* = (create$))
(defglobal ?*ver-i* = 0)
(while (neq FALSE (sqlite-compileoption-get ?*ver-i*)) do
  (bind ?*ver-opts* (create$ ?*ver-opts* (sqlite-compileoption-get ?*ver-i*)))
  (bind ?*ver-i* (+ ?*ver-i* 1)))

(expect-true "the option walk found at least one option" (> (length$ ?*ver-opts*) 0))
(expect "one past the last option refuses" FALSE (sqlite-compileoption-get ?*ver-i*))
(expect "a wildly out-of-range index refuses" FALSE (sqlite-compileoption-get 100000))

; every option the library reported having been built with reports itself used
(defglobal ?*ver-all-used* = TRUE)
(progn$ (?o ?*ver-opts*)
  (if (neq TRUE (sqlite-compileoption-used ?o))
   then (bind ?*ver-all-used* ?o)))
(expect "every option compileoption-get returned reports itself as used"
        TRUE ?*ver-all-used*)

(expect "an option that was never set reports itself unused"
        FALSE (sqlite-compileoption-used NOT_A_REAL_COMPILE_OPTION))

; the option name is taken as text either way it is spelled
(expect "a string names an option as well as a symbol does"
        (sqlite-compileoption-used (nth$ 1 ?*ver-opts*))
        (sqlite-compileoption-used (str-cat (nth$ 1 ?*ver-opts*))))
