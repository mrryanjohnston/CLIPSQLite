; ============================================================
; BINDING
;
; sqlite-bind is the one wrapper that dispatches on the type of its own
; argument.  A multifield binds by position, an integer or a name picks one
; parameter, a fact or an instance binds by slot name, and a bare scalar binds
; parameter 1.  Six shapes through one entry point, so each is exercised here
; against the same three-parameter statement and read back through
; sqlite-expanded-sql, which is the only way to see what actually landed.
; ============================================================

(defglobal
  ?*bd-db* = FALSE
  ?*bd-st* = FALSE
  ?*bd-st2* = FALSE
  ?*bd-r*  = nothing
  ?*bd-f*  = FALSE
  ?*bd-i*  = FALSE)

(bind ?*bd-db* (sqlite-open :memory:))
(expect "the connection opened" TRUE (pointerp ?*bd-db*))

; ------------------------------------------------------------
; the parameters a statement has
; ------------------------------------------------------------

(bind ?*bd-st* (sqlite-prepare ?*bd-db* "SELECT ?, :named, @at;"))
(expect "the statement prepared" TRUE (pointerp ?*bd-st*))

(expect "it has three parameters" 3 (sqlite-bind-parameter-count ?*bd-st*))
(expect ":named is parameter 2" 2 (sqlite-bind-parameter-index ?*bd-st* ":named"))
(expect "@at is parameter 3" 3 (sqlite-bind-parameter-index ?*bd-st* "@at"))
(expect "a symbol names a parameter as well as a string does"
        2 (sqlite-bind-parameter-index ?*bd-st* :named))

(bind ?*bd-r* (sqlite-bind-parameter-index ?*bd-st* ":nothing"))
(expect "a parameter the statement does not have has no index" FALSE ?*bd-r*)
(bind ?*bd-r* (sqlite-bind-parameter-index ?*bd-st* named))
(expect "and the prefix is part of the name, not decoration" FALSE ?*bd-r*)

(expect "parameter 2 names itself" :named (sqlite-bind-parameter-name ?*bd-st* 2))
(expect "and parameter 3" @at (sqlite-bind-parameter-name ?*bd-st* 3))
(bind ?*bd-r* (sqlite-bind-parameter-name ?*bd-st* 1))
(expect "a bare ? has no name to give" FALSE ?*bd-r*)
(bind ?*bd-r* (sqlite-bind-parameter-name ?*bd-st* 99))
(expect "and neither has an index past the last parameter" FALSE ?*bd-r*)

(expect "finalizing it" TRUE (sqlite-finalize ?*bd-st*))

(bind ?*bd-st* (sqlite-prepare ?*bd-db* "SELECT 1;"))
(expect "a statement with no parameters has none"
        0 (sqlite-bind-parameter-count ?*bd-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*bd-st*))

; ------------------------------------------------------------
; the working statement for the rest of the suite
; ------------------------------------------------------------

(bind ?*bd-st* (sqlite-prepare ?*bd-db* "SELECT :a AS a, :b AS b, :c AS c;"))
(expect "the three-parameter statement prepared" TRUE (pointerp ?*bd-st*))

(deffunction bd-clear ()
  (sqlite-clear-bindings ?*bd-st*))

; ------------------------------------------------------------
; by position, from a multifield
; ------------------------------------------------------------

(expect "a multifield binds left to right"
        TRUE (sqlite-bind ?*bd-st* (create$ 1 2.5 "three")))
(expect "onto parameters 1, 2 and 3"
        "SELECT 1 AS a, 2.5 AS b, 'three' AS c;" (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(expect "a short multifield binds what it has"
        TRUE (sqlite-bind ?*bd-st* (create$ 9)))
(expect "and leaves the rest NULL"
        "SELECT 9 AS a, NULL AS b, NULL AS c;" (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(expect "an empty multifield binds nothing" TRUE (sqlite-bind ?*bd-st* (create$)))
(expect "and changes nothing"
        "SELECT NULL AS a, NULL AS b, NULL AS c;" (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

; the bind stops at the first failure, so the values before it stay put
(bind ?*bd-r* (sqlite-bind ?*bd-st* (create$ 1 2 3 4)))
(expect "a multifield longer than the parameter list is refused" FALSE ?*bd-r*)
(expect "after the three that fit had already been bound"
        "SELECT 1 AS a, 2 AS b, 3 AS c;" (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

; ------------------------------------------------------------
; by position, one parameter at a time
; ------------------------------------------------------------

(expect "an integer index picks a parameter" TRUE (sqlite-bind ?*bd-st* 2 "second"))
(expect "and binds only that one"
        "SELECT NULL AS a, 'second' AS b, NULL AS c;" (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(bind ?*bd-r* (sqlite-bind ?*bd-st* 0 "x"))
(expect "parameter 0 does not exist -- SQLite counts from 1" FALSE ?*bd-r*)
(bind ?*bd-r* (sqlite-bind ?*bd-st* -1 "x"))
(expect "and neither does a negative index" FALSE ?*bd-r*)
(bind ?*bd-r* (sqlite-bind ?*bd-st* 4 "x"))
(expect "an index past the last parameter is refused" FALSE ?*bd-r*)

; ------------------------------------------------------------
; by name
; ------------------------------------------------------------

(expect "a name picks a parameter" TRUE (sqlite-bind ?*bd-st* ":b" "by name"))
(expect "and binds only that one"
        "SELECT NULL AS a, 'by name' AS b, NULL AS c;" (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(expect "the name may be a symbol" TRUE (sqlite-bind ?*bd-st* :c 33))
(expect "with the same effect"
        "SELECT NULL AS a, NULL AS b, 33 AS c;" (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(bind ?*bd-r* (sqlite-bind ?*bd-st* ":nothing" 1))
(expect "a name the statement does not have is refused" FALSE ?*bd-r*)

; ------------------------------------------------------------
; a bare value binds parameter 1
;
; With two arguments there is nothing to say which parameter is meant, so the
; first one is.  Every scalar type reaches this path, which is also the only
; path a float can take -- a float is neither an index nor a name.
; ------------------------------------------------------------

(expect "one integer binds parameter 1" TRUE (sqlite-bind ?*bd-st* 42))
(expect "as an integer" "SELECT 42 AS a, NULL AS b, NULL AS c;"
        (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(expect "one float binds parameter 1" TRUE (sqlite-bind ?*bd-st* 2.5))
(expect "as a real" "SELECT 2.5 AS a, NULL AS b, NULL AS c;"
        (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(expect "one string binds parameter 1" TRUE (sqlite-bind ?*bd-st* "text"))
(expect "as text" "SELECT 'text' AS a, NULL AS b, NULL AS c;"
        (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(expect "one symbol binds parameter 1" TRUE (sqlite-bind ?*bd-st* a-symbol))
(expect "as text as well" "SELECT 'a-symbol' AS a, NULL AS b, NULL AS c;"
        (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

; ------------------------------------------------------------
; values that become NULL
;
; nil is the spelling of SQL NULL throughout this binding -- it is what
; sqlite-column gives back for a NULL, so it is what sqlite-bind takes for
; one.  The types with no SQL equivalent become NULL as well rather than being
; refused, which is worth pinning down: a caller who binds a multifield by
; mistake gets NULL, not an error.
; ------------------------------------------------------------

(expect "nil binds as NULL" TRUE (sqlite-bind ?*bd-st* 1 nil))
(expect "and reads back as NULL" "SELECT NULL AS a, NULL AS b, NULL AS c;"
        (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(expect "a multifield in the value position binds as NULL"
        TRUE (sqlite-bind ?*bd-st* 1 (create$ 1 2)))
(expect "not as its members" "SELECT NULL AS a, NULL AS b, NULL AS c;"
        (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(expect "an external address binds as NULL too"
        TRUE (sqlite-bind ?*bd-st* 1 ?*bd-db*))
(expect "rather than as the pointer" "SELECT NULL AS a, NULL AS b, NULL AS c;"
        (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

; ------------------------------------------------------------
; from a fact
;
; The slot names are taken as parameter names, so the template's slots are
; spelled with SQLite's prefixes.  A slot the statement has no parameter for
; is skipped rather than refused, which is what lets one template feed several
; statements that each use part of it.
; ------------------------------------------------------------

(bind ?*bd-f* (assert (bind-params (:a 11) (:b "twelve"))))
(expect "a fact binds by slot name" TRUE (sqlite-bind ?*bd-st* ?*bd-f*))
(expect "onto the parameters that match"
        "SELECT 11 AS a, 'twelve' AS b, NULL AS c;" (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(bind ?*bd-f* (assert (bind-unrelated (nothing-matches 1) (neither-does-this 2))))
(expect "a fact whose slots match nothing still succeeds"
        TRUE (sqlite-bind ?*bd-st* ?*bd-f*))
(expect "having bound nothing" "SELECT NULL AS a, NULL AS b, NULL AS c;"
        (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

; the prefix is not special-cased -- @ works the same way : does
(bind ?*bd-st2* (sqlite-prepare ?*bd-db* "SELECT @a AS a, @b AS b;"))
(bind ?*bd-f* (assert (bind-at-params (@a 1) (@b 2))))
(expect "an @-prefixed parameter binds from a fact the same way"
        TRUE (sqlite-bind ?*bd-st2* ?*bd-f*))
(expect "with the same result" "SELECT 1 AS a, 2 AS b;" (sqlite-expanded-sql ?*bd-st2*))
(expect "finalizing it" TRUE (sqlite-finalize ?*bd-st2*))

; ------------------------------------------------------------
; from an instance
;
; An instance is read through its class's slot list, and that list is where
; the optional third argument comes in: with inheritance on -- the default --
; a subclass offers its parents' slots too, and with it off only its own.
; ------------------------------------------------------------

(make-instance bd-sub of BIND-PARAMS-SUB (:a 1) (:b 2) (:c 3))
(bind ?*bd-i* (instance-address [bd-sub]))

(expect "an instance address binds by slot name" TRUE (sqlite-bind ?*bd-st* ?*bd-i*))
(expect "including the slots it inherits"
        "SELECT 1 AS a, 2 AS b, 3 AS c;" (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(expect "TRUE asks for the same thing explicitly"
        TRUE (sqlite-bind ?*bd-st* ?*bd-i* TRUE))
(expect "and gets it" "SELECT 1 AS a, 2 AS b, 3 AS c;" (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(expect "FALSE restricts the bind to the class's own slots"
        TRUE (sqlite-bind ?*bd-st* ?*bd-i* FALSE))
(expect "so the inherited ones are left alone"
        "SELECT NULL AS a, NULL AS b, 3 AS c;" (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

; anything other than FALSE in that position means inheritance, since the
; wrapper only looks for the one symbol
(expect "a third argument that is not FALSE leaves inheritance on"
        TRUE (sqlite-bind ?*bd-st* ?*bd-i* whatever))
(expect "as if it had been omitted"
        "SELECT 1 AS a, 2 AS b, 3 AS c;" (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

; ------------------------------------------------------------
; an instance may be named instead of addressed
;
; The two spellings mean the same instance and have to bind the same values,
; including through the inherit flag.  They did not: the lookup behind the
; name re-interned it with both LEXEME_BITS and INSTANCE_NAME_BIT set, found
; the plain symbol of that spelling first, and so missed every instance
; whatever it was called.
; ------------------------------------------------------------

(expect "an instance name binds like its address" TRUE (sqlite-bind ?*bd-st* [bd-sub]))
(expect "reaching the same slots"
        "SELECT 1 AS a, 2 AS b, 3 AS c;" (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(expect "and taking the inherit flag the same way"
        TRUE (sqlite-bind ?*bd-st* [bd-sub] FALSE))
(expect "down to the class's own slots"
        "SELECT NULL AS a, NULL AS b, 3 AS c;" (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(bind ?*bd-r* (sqlite-bind ?*bd-st* [no-such-instance]))
(expect "a name no instance answers to is refused" FALSE ?*bd-r*)

; make-instance hands back the name rather than the address, so a caller
; holding one in a variable is the usual way this path is reached
(defglobal ?*bd-n* = FALSE)
(bind ?*bd-n* (make-instance of BIND-PARAMS (:a 5) (:b "six")))
(expect "make-instance gives back a name" TRUE (instance-namep ?*bd-n*))
(expect "which binds like any other" TRUE (sqlite-bind ?*bd-st* ?*bd-n*))
(expect "reaching its slots" "SELECT 5 AS a, 'six' AS b, NULL AS c;"
        (sqlite-expanded-sql ?*bd-st*))
(bd-clear)

(expect "finalizing it" TRUE (sqlite-finalize ?*bd-st*))
(expect "closing the connection" TRUE (sqlite-close ?*bd-db*))
