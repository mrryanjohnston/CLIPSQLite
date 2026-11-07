; ======================================================================
; Every way of getting rows back.
;
; A SELECT can be read a cell at a time, a row at a time, or all at once,
; and each row can land as a multifield, a fact or an instance.  This
; example runs the same small table through every one of those, from the
; most manual to the least, so the trade-offs sit next to each other.
;
;   ./vendor/clips/clips -f2 examples/4-reading-results.bat
; ======================================================================

; Column names are slot names, so the deftemplate and the defclass are
; spelled after the table.  The defclass is uppercase because that is how
; sqlite-query-to-instances spells the class it infers from a table name,
; and its "name" column has to go somewhere: an instance's name is not a
; slot, so a column called name lands in _name.
(deftemplate planet
  (slot name)
  (slot mass)
  (slot moons))

(defclass PLANET
  (is-a USER)
  (slot _name)
  (slot mass)
  (slot moons))

(defrule moonless
  (planet (name ?name) (moons 0))
  =>
  (println "  " ?name " has no moons"))

(deffunction main ()
  (bind ?db (sqlite-open :memory:))
  (if (not ?db) then (println "cannot open the database") (return FALSE))

  ; A statement with nothing to give back still has to be prepared, stepped
  ; and finalized.  sqlite-query-to-multifield does all three and answers an
  ; empty multifield, which makes it the shortest way to run one.
  (sqlite-query-to-multifield ?db
    "CREATE TABLE planet (name TEXT, mass REAL, moons INTEGER)")
  (sqlite-query-to-multifield ?db
    (str-cat "INSERT INTO planet VALUES "
             "('Mercury', 0.055, 0), ('Venus', 0.815, 0), "
             "('Earth', 1.0, 1), ('Mars', 0.107, 2)"))

  ; --------------------------------------------------------------------
  ; 1. A cell at a time.
  ;
  ; sqlite-step moves to the next row; sqlite-column reads one cell of it
  ; by position.  This is the SQLite C API with the pointers taken out,
  ; and it is the only form that answers questions about the columns
  ; themselves: how many, what they are called, what type this cell is.
  ; --------------------------------------------------------------------

  (println "1. a cell at a time")
  (bind ?q (sqlite-prepare ?db "SELECT name, mass, moons FROM planet ORDER BY name"))
  (bind ?n (sqlite-column-count ?q))
  (bind ?header "")
  (loop-for-count (?i 0 (- ?n 1))
    (bind ?header (str-cat ?header "  " (sqlite-column-name ?q ?i))))
  (println ?header)
  (while (eq (sqlite-step ?q) SQLITE_ROW)
    (bind ?line "")
    (loop-for-count (?i 0 (- ?n 1))
      (bind ?line (str-cat ?line "  " (sqlite-column ?q ?i)
                           " (" (sqlite-column-type ?q ?i) ")")))
    (println ?line))
  (sqlite-finalize ?q)

  ; --------------------------------------------------------------------
  ; 2. A row at a time, as a multifield.
  ;
  ; The row under the cursor, in column order.  Positional, so it needs no
  ; deftemplate and drops nothing -- and a NULL arrives as the symbol nil.
  ; --------------------------------------------------------------------

  (println)
  (println "2. a row at a time, as a multifield")
  (bind ?q (sqlite-prepare ?db "SELECT name, moons FROM planet ORDER BY name"))
  (while (eq (sqlite-step ?q) SQLITE_ROW)
    (bind ?row (sqlite-row-to-multifield ?q))
    (println "  " (nth$ 1 ?row) " has " (nth$ 2 ?row) " moon(s)"))
  (sqlite-finalize ?q)

  ; --------------------------------------------------------------------
  ; 3. A row at a time, as a fact.
  ;
  ; Each column fills the slot with its name.  The facts are in working
  ; memory as soon as they are asserted, and the rule above fires on them
  ; when the engine runs.
  ; --------------------------------------------------------------------

  (println)
  (println "3. a row at a time, as a fact")
  (bind ?q (sqlite-prepare ?db "SELECT name, mass, moons FROM planet ORDER BY name"))
  (bind ?loaded 0)
  (while (eq (sqlite-step ?q) SQLITE_ROW)
    (sqlite-row-to-fact ?q planet)
    (bind ?loaded (+ ?loaded 1)))
  (sqlite-finalize ?q)
  (println "  asserted " ?loaded " facts")
  (run)

  ; --------------------------------------------------------------------
  ; 4. A row at a time, as an instance.
  ;
  ; The optional third argument is the instance's name, which here is the
  ; planet's own -- read out of the row with sqlite-column before the row
  ; is turned into the instance.
  ; --------------------------------------------------------------------

  (println)
  (println "4. a row at a time, as an instance")
  (bind ?q (sqlite-prepare ?db "SELECT name, mass, moons FROM planet ORDER BY name"))
  (while (eq (sqlite-step ?q) SQLITE_ROW)
    (bind ?i (sqlite-row-to-instance ?q PLANET (sym-cat (sqlite-column ?q 0))))
    (println "  " (instance-name ?i) " with mass " (send ?i get-mass)))
  (sqlite-finalize ?q)

  ; --------------------------------------------------------------------
  ; 5. The whole statement at once.
  ;
  ; sqlite-stmt-to-multifield, -to-facts and -to-instances walk every row
  ; the statement has left and answer a multifield of what they made.  The
  ; reason to prepare a statement rather than pass a query string is a
  ; binding: the value is filled in by SQLite, never spliced into the SQL.
  ; A walked statement is reset on the way out, so the same one can be
  ; bound again and walked again.
  ; --------------------------------------------------------------------

  (println)
  (println "5. the whole statement at once")
  (bind ?q (sqlite-prepare ?db
    "SELECT name, mass, moons FROM planet WHERE moons >= ? ORDER BY name"))

  ; TRUE puts the column names in front of the values
  (sqlite-bind ?q 1 1)
  (println "  with at least one moon: " (sqlite-stmt-to-multifield ?q TRUE))

  ; the same statement, bound again: every row this time.  These rows are
  ; already facts from step 3, and CLIPS does not assert a duplicate, so
  ; the answer names the facts that already hold them.
  (sqlite-bind ?q 1 0)
  (bind ?facts (sqlite-stmt-to-facts ?q planet))
  (println "  " (length$ ?facts) " facts answered, "
           (length$ (find-all-facts ((?p planet)) TRUE)) " in working memory")

  ; instances are not deduplicated, and the names are positional: the nth
  ; name goes to the nth row
  (bind ?instances (sqlite-stmt-to-instances ?q PLANET (create$ first second)))
  (println "  " (length$ ?instances) " instances, the first two named "
           (instance-name (nth$ 1 ?instances)) " and "
           (instance-name (nth$ 2 ?instances)))
  (sqlite-finalize ?q)

  ; --------------------------------------------------------------------
  ; 6. The whole query at once.
  ;
  ; sqlite-query-to-multifield, -to-facts and -to-instances prepare the
  ; SQL, walk it and finalize it in one call.  The deftemplate and the
  ; defclass are optional: left out, they are the table the columns come
  ; from -- planet, and PLANET.
  ; --------------------------------------------------------------------

  (println)
  (println "6. the whole query at once")
  (println "  heaviest: "
           (sqlite-query-to-multifield ?db
             "SELECT name FROM planet ORDER BY mass DESC LIMIT 1"))

  (bind ?facts (sqlite-query-to-facts ?db "SELECT name, mass, moons FROM planet"))
  (println "  " (length$ ?facts) " facts of the inferred deftemplate planet")

  ; the multifield form feeds the instance form: the names come from the
  ; table, and the class is inferred from it too
  (bind ?names (sqlite-query-to-multifield ?db "SELECT name FROM planet ORDER BY name"))
  (bind ?instances (sqlite-query-to-instances ?db
    "SELECT name, mass, moons FROM planet ORDER BY name" ?names))
  (println "  " (length$ ?instances) " instances of "
           (class (nth$ 1 ?instances)) ", named "
           (implode$ (create$ (instance-name (nth$ 1 ?instances))
                              (instance-name (nth$ 2 ?instances))
                              (instance-name (nth$ 3 ?instances))
                              (instance-name (nth$ 4 ?instances)))))

  (sqlite-close ?db))

(main)
(exit)
